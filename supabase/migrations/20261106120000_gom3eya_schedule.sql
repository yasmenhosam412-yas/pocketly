-- Association start/end dates, per-person payment and collection dates,
-- and a turn that can be shared by two people.
-- Safe to re-run. Apply on databases that already have association_gom3eya.sql.

alter table public.associations
  add column if not exists starts_on date,
  add column if not exists ends_on date;

alter table public.associations
  drop constraint if exists associations_gom3eya_dates_check;

alter table public.associations
  add constraint associations_gom3eya_dates_check
  check (starts_on is null or ends_on is null or ends_on >= starts_on);

alter table public.association_turn_slots
  add column if not exists payment_on date,
  add column if not exists collection_on date,
  add column if not exists co_holder_name text,
  add column if not exists co_payment_on date,
  add column if not exists co_collection_on date;

create or replace function public.get_association_hub(p_association_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  assoc jsonb;
  slots jsonb;
  members jsonb;
  payments jsonb;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_association_member(p_association_id) then
    raise exception 'Not a member of this association';
  end if;

  select jsonb_build_object(
    'id', a.id,
    'name', a.name,
    'is_personal', a.is_personal,
    'payout_amount', a.payout_amount,
    'installment_amount', a.installment_amount,
    'member_slots', a.member_slots,
    'current_turn_index', a.current_turn_index,
    'collection_day', a.collection_day,
    'gom3eya_ended_at', a.gom3eya_ended_at,
    'starts_on', a.starts_on,
    'ends_on', a.ends_on
  )
  into assoc
  from public.associations a
  where a.id = p_association_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', s.id,
        'slot_index', s.slot_index,
        'holder_name', s.holder_name,
        'user_id', s.user_id,
        'received_at', s.received_at,
        'payment_on', s.payment_on,
        'collection_on', s.collection_on,
        'co_holder_name', s.co_holder_name,
        'co_payment_on', s.co_payment_on,
        'co_collection_on', s.co_collection_on
      )
      order by s.slot_index
    ),
    '[]'::jsonb
  )
  into slots
  from public.association_turn_slots s
  where s.association_id = p_association_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_id', m.user_id,
        'role', m.role,
        'username', coalesce(p.username, '')
      )
      order by m.joined_at
    ),
    '[]'::jsonb
  )
  into members
  from public.association_members m
  left join public.profiles p on p.id = m.user_id
  where m.association_id = p_association_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', pay.id,
        'payer_name', pay.payer_name,
        'turn_slot_id', pay.turn_slot_id,
        'amount', pay.amount,
        'paid_at', pay.paid_at,
        'note', pay.note
      )
      order by pay.paid_at desc, pay.created_at desc
    ),
    '[]'::jsonb
  )
  into payments
  from public.association_installment_payments pay
  where pay.association_id = p_association_id;

  return jsonb_build_object(
    'association', assoc,
    'slots', slots,
    'members', members,
    'payments', payments,
    'is_owner', public.is_association_owner(p_association_id)
  );
end;
$$;

revoke all on function public.get_association_hub(uuid) from public;
grant execute on function public.get_association_hub(uuid) to authenticated;

drop function if exists public.save_association_gom3eya(uuid, numeric, numeric, int, jsonb);

create or replace function public.save_association_gom3eya(
  p_association_id uuid,
  p_payout_amount numeric,
  p_installment_amount numeric,
  p_collection_day int,
  p_slots jsonb,
  p_starts_on date default null,
  p_ends_on date default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  slot_count int := 0;
  elem jsonb;
  idx int;
  name text;
  slot_id uuid;
  pay_on date;
  collect_on date;
  co_name text;
  co_pay_on date;
  co_collect_on date;
  updated boolean;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_association_owner(p_association_id) then
    raise exception 'Only the association owner can edit settings';
  end if;

  if not public.is_gom3eya_active(p_association_id) then
    raise exception 'This gom3eya has already ended';
  end if;

  if exists (
    select 1 from public.associations a
    where a.id = p_association_id and a.is_personal = true
  ) then
    raise exception 'Cannot configure personal ledger as gom3eya';
  end if;

  if p_collection_day is not null
     and (p_collection_day < 1 or p_collection_day > 31) then
    raise exception 'Collection day must be between 1 and 31';
  end if;

  if p_starts_on is not null
     and p_ends_on is not null
     and p_ends_on < p_starts_on then
    raise exception 'End date must be on or after the start date';
  end if;

  for elem in select * from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb))
  loop
    if trim(coalesce(elem->>'holder_name', '')) <> '' then
      slot_count := slot_count + 1;
    end if;
  end loop;

  update public.associations
  set
    payout_amount = nullif(p_payout_amount, 0),
    installment_amount = nullif(p_installment_amount, 0),
    collection_day = p_collection_day,
    starts_on = p_starts_on,
    ends_on = p_ends_on,
    member_slots = slot_count,
    current_turn_index = least(
      current_turn_index,
      greatest(slot_count - 1, 0)
    )
  where id = p_association_id;

  update public.association_turn_slots
  set slot_index = slot_index + 100000
  where association_id = p_association_id;

  for elem in select * from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb))
  loop
    idx := (elem->>'slot_index')::int;
    name := trim(coalesce(elem->>'holder_name', ''));
    if name = '' then
      continue;
    end if;

    pay_on := nullif(elem->>'payment_on', '')::date;
    collect_on := nullif(elem->>'collection_on', '')::date;
    co_name := nullif(trim(coalesce(elem->>'co_holder_name', '')), '');
    if co_name is null then
      co_pay_on := null;
      co_collect_on := null;
    else
      co_pay_on := nullif(elem->>'co_payment_on', '')::date;
      co_collect_on := nullif(elem->>'co_collection_on', '')::date;
    end if;

    slot_id := null;
    if coalesce(elem->>'id', '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      slot_id := (elem->>'id')::uuid;
    end if;

    updated := false;
    if slot_id is not null then
      update public.association_turn_slots
      set
        slot_index = idx,
        holder_name = name,
        payment_on = pay_on,
        collection_on = collect_on,
        co_holder_name = co_name,
        co_payment_on = co_pay_on,
        co_collection_on = co_collect_on
      where id = slot_id
        and association_id = p_association_id;
      updated := found;
    end if;

    if not updated then
      insert into public.association_turn_slots (
        association_id,
        slot_index,
        holder_name,
        payment_on,
        collection_on,
        co_holder_name,
        co_payment_on,
        co_collection_on
      ) values (
        p_association_id,
        idx,
        name,
        pay_on,
        collect_on,
        co_name,
        co_pay_on,
        co_collect_on
      );
    end if;
  end loop;

  delete from public.association_turn_slots
  where association_id = p_association_id
    and slot_index >= 100000;

  update public.associations
  set member_slots = (
    select count(*)::int
    from public.association_turn_slots s
    where s.association_id = p_association_id
  )
  where id = p_association_id;
end;
$$;

revoke all on function public.save_association_gom3eya(uuid, numeric, numeric, int, jsonb, date, date) from public;
grant execute on function public.save_association_gom3eya(uuid, numeric, numeric, int, jsonb, date, date) to authenticated;
