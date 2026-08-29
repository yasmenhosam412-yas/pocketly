-- Family ledgers: every member can add their own income/expenses.
-- Run after associations.sql and association_treasurer_rls.sql.

alter table public.associations
  add column if not exists ledger_kind text not null default 'shared'
  check (ledger_kind in ('personal', 'family', 'shared'));

update public.associations
set ledger_kind = 'personal'
where is_personal = true
  and ledger_kind is distinct from 'personal';

create or replace function public.is_family_association(p_association_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select a.ledger_kind = 'family' from public.associations a where a.id = p_association_id),
    false
  );
$$;

-- Personal = owner only (self). Family = any member. Shared/gom3eya = owner only.
create or replace function public.can_write_financial_row(p_association_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    p_association_id is not null
    and public.is_association_member(p_association_id)
    and (
      public.is_personal_association(p_association_id)
      or public.is_family_association(p_association_id)
      or public.is_association_owner(p_association_id)
    );
$$;

create or replace function public.create_family_association(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  aid uuid;
  trimmed text := trim(coalesce(p_name, ''));
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  if trimmed = '' then
    raise exception 'Association name is required';
  end if;

  insert into public.associations (name, is_personal, ledger_kind)
  values (trimmed, false, 'family')
  returning id into aid;

  insert into public.association_members (association_id, user_id, role)
  values (aid, uid, 'owner');

  return aid;
end;
$$;

revoke all on function public.create_family_association(text) from public;
grant execute on function public.create_family_association(text) to authenticated;

revoke all on function public.is_family_association(uuid) from public;
grant execute on function public.is_family_association(uuid) to authenticated;

-- Family budgets are one row per category for the whole household.
drop policy if exists "Members update budgets" on public.budgets;
create policy "Members update budgets"
  on public.budgets for update
  using (
    public.can_write_financial_row(association_id)
    and (
      user_id = auth.uid()
      or public.is_family_association(association_id)
    )
  );

drop policy if exists "Members delete budgets" on public.budgets;
create policy "Members delete budgets"
  on public.budgets for delete
  using (
    public.can_write_financial_row(association_id)
    and (
      user_id = auth.uid()
      or public.is_family_association(association_id)
    )
  );

-- Keep gom3eya/shared creates distinct from family.
create or replace function public.create_association(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  aid uuid;
  trimmed text := trim(coalesce(p_name, ''));
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  if trimmed = '' then
    raise exception 'Association name is required';
  end if;

  insert into public.associations (name, is_personal, ledger_kind)
  values (trimmed, false, 'shared')
  returning id into aid;

  insert into public.association_members (association_id, user_id, role)
  values (aid, uid, 'owner');

  return aid;
end;
$$;

create or replace function public.ensure_personal_association()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  aid uuid;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  select a.id into aid
  from public.associations a
  join public.association_members m on m.association_id = a.id
  where m.user_id = uid
    and a.is_personal = true
  limit 1;

  if aid is null then
    insert into public.associations (name, is_personal, ledger_kind)
    values ('Personal', true, 'personal')
    returning id into aid;

    insert into public.association_members (association_id, user_id, role)
    values (aid, uid, 'owner');
  else
    update public.associations
    set ledger_kind = 'personal'
    where id = aid and ledger_kind is distinct from 'personal';
  end if;

  update public.incomes set association_id = aid
  where user_id = uid and association_id is null;
  update public.expenses set association_id = aid
  where user_id = uid and association_id is null;
  update public.plans set association_id = aid
  where user_id = uid and association_id is null;
  update public.budgets set association_id = aid
  where user_id = uid and association_id is null;
  if to_regclass('public.loans') is not null then
    update public.loans set association_id = aid
    where user_id = uid and association_id is null;
  end if;

  return aid;
end;
$$;
