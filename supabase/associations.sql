-- Run in Supabase SQL editor (Dashboard → SQL) before using associations in the app.
-- Phase 1: personal ledger + user-created associations (single owner per association).

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.associations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_personal boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.association_members (
  id uuid primary key default gen_random_uuid(),
  association_id uuid not null references public.associations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  unique (association_id, user_id)
);

create index if not exists association_members_user_idx
  on public.association_members (user_id);

-- Financial tables: scope rows per association
alter table public.incomes
  add column if not exists association_id uuid references public.associations (id) on delete cascade;

alter table public.expenses
  add column if not exists association_id uuid references public.associations (id) on delete cascade;

alter table public.plans
  add column if not exists association_id uuid references public.associations (id) on delete cascade;

alter table public.budgets
  add column if not exists association_id uuid references public.associations (id) on delete cascade;

do $$
begin
  if to_regclass('public.loans') is not null then
    execute 'alter table public.loans add column if not exists association_id uuid references public.associations (id) on delete cascade';
    execute 'create index if not exists loans_association_idx on public.loans (association_id)';
  end if;
end $$;

create index if not exists incomes_association_idx on public.incomes (association_id);
create index if not exists expenses_association_idx on public.expenses (association_id);
create index if not exists plans_association_idx on public.plans (association_id);
create index if not exists budgets_association_idx on public.budgets (association_id);

-- Budgets: unique per association + category + period (replaces user-only uniqueness when present)
alter table public.budgets drop constraint if exists budgets_user_id_category_year_month_key;
alter table public.budgets drop constraint if exists budgets_user_category_period_key;
alter table public.budgets
  drop constraint if exists budgets_association_category_period_key;
alter table public.budgets
  add constraint budgets_association_category_period_key
  unique (association_id, category, year, month);

-- ---------------------------------------------------------------------------
-- RLS helpers
-- ---------------------------------------------------------------------------

create or replace function public.is_association_member(p_association_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.association_members m
    where m.association_id = p_association_id
      and m.user_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- RLS: associations + members
-- ---------------------------------------------------------------------------

alter table public.associations enable row level security;
alter table public.association_members enable row level security;

drop policy if exists "Members read associations" on public.associations;
create policy "Members read associations"
  on public.associations for select
  using (public.is_association_member(id));

drop policy if exists "Authenticated create associations" on public.associations;
create policy "Authenticated create associations"
  on public.associations for insert
  with check (auth.uid() is not null);

drop policy if exists "Owners update associations" on public.associations;
create policy "Owners update associations"
  on public.associations for update
  using (
    exists (
      select 1 from public.association_members m
      where m.association_id = id
        and m.user_id = auth.uid()
        and m.role in ('owner', 'admin')
    )
  );

drop policy if exists "Owners delete non-personal associations" on public.associations;
create policy "Owners delete non-personal associations"
  on public.associations for delete
  using (
    is_personal = false
    and exists (
      select 1 from public.association_members m
      where m.association_id = id
        and m.user_id = auth.uid()
        and m.role = 'owner'
    )
  );

drop policy if exists "Users read own memberships" on public.association_members;
create policy "Users read own memberships"
  on public.association_members for select
  using (user_id = auth.uid());

drop policy if exists "Users insert own memberships" on public.association_members;
create policy "Users insert own memberships"
  on public.association_members for insert
  with check (user_id = auth.uid());

drop policy if exists "Users delete own memberships" on public.association_members;
create policy "Users delete own memberships"
  on public.association_members for delete
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- RLS: financial tables (member of association + own user_id)
-- ---------------------------------------------------------------------------

drop policy if exists "Users can read own incomes" on public.incomes;
drop policy if exists "Users can insert own incomes" on public.incomes;
drop policy if exists "Users can update own incomes" on public.incomes;
drop policy if exists "Users can delete own incomes" on public.incomes;
drop policy if exists "Members read incomes" on public.incomes;
drop policy if exists "Members insert incomes" on public.incomes;
drop policy if exists "Members update incomes" on public.incomes;
drop policy if exists "Members delete incomes" on public.incomes;

create policy "Members read incomes"
  on public.incomes for select
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members insert incomes"
  on public.incomes for insert
  with check (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members update incomes"
  on public.incomes for update
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members delete incomes"
  on public.incomes for delete
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

drop policy if exists "Users can read own expenses" on public.expenses;
drop policy if exists "Users can insert own expenses" on public.expenses;
drop policy if exists "Users can update own expenses" on public.expenses;
drop policy if exists "Users can delete own expenses" on public.expenses;
drop policy if exists "Members read expenses" on public.expenses;
drop policy if exists "Members insert expenses" on public.expenses;
drop policy if exists "Members update expenses" on public.expenses;
drop policy if exists "Members delete expenses" on public.expenses;

create policy "Members read expenses"
  on public.expenses for select
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members insert expenses"
  on public.expenses for insert
  with check (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members update expenses"
  on public.expenses for update
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members delete expenses"
  on public.expenses for delete
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

drop policy if exists "Users can read own plans" on public.plans;
drop policy if exists "Users can insert own plans" on public.plans;
drop policy if exists "Users can update own plans" on public.plans;
drop policy if exists "Users can delete own plans" on public.plans;
drop policy if exists "Members read plans" on public.plans;
drop policy if exists "Members insert plans" on public.plans;
drop policy if exists "Members update plans" on public.plans;
drop policy if exists "Members delete plans" on public.plans;

create policy "Members read plans"
  on public.plans for select
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members insert plans"
  on public.plans for insert
  with check (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members update plans"
  on public.plans for update
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members delete plans"
  on public.plans for delete
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

do $$
begin
  if to_regclass('public.loans') is null then
    return;
  end if;
  execute 'drop policy if exists "Users can read own loans" on public.loans';
  execute 'drop policy if exists "Users can insert own loans" on public.loans';
  execute 'drop policy if exists "Users can update own loans" on public.loans';
  execute 'drop policy if exists "Users can delete own loans" on public.loans';
  execute 'drop policy if exists "Members read loans" on public.loans';
  execute 'drop policy if exists "Members insert loans" on public.loans';
  execute 'drop policy if exists "Members update loans" on public.loans';
  execute 'drop policy if exists "Members delete loans" on public.loans';
  execute $p$
    create policy "Members read loans"
      on public.loans for select
      using (
        user_id = auth.uid()
        and association_id is not null
        and public.is_association_member(association_id)
      )
  $p$;
  execute $p$
    create policy "Members insert loans"
      on public.loans for insert
      with check (
        user_id = auth.uid()
        and association_id is not null
        and public.is_association_member(association_id)
      )
  $p$;
  execute $p$
    create policy "Members update loans"
      on public.loans for update
      using (
        user_id = auth.uid()
        and association_id is not null
        and public.is_association_member(association_id)
      )
  $p$;
  execute $p$
    create policy "Members delete loans"
      on public.loans for delete
      using (
        user_id = auth.uid()
        and association_id is not null
        and public.is_association_member(association_id)
      )
  $p$;
end $$;

drop policy if exists "Users can read own budgets" on public.budgets;
drop policy if exists "Users can insert own budgets" on public.budgets;
drop policy if exists "Users can update own budgets" on public.budgets;
drop policy if exists "Users can delete own budgets" on public.budgets;
drop policy if exists "Members read budgets" on public.budgets;
drop policy if exists "Members insert budgets" on public.budgets;
drop policy if exists "Members update budgets" on public.budgets;
drop policy if exists "Members delete budgets" on public.budgets;

create policy "Members read budgets"
  on public.budgets for select
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members insert budgets"
  on public.budgets for insert
  with check (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members update budgets"
  on public.budgets for update
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

create policy "Members delete budgets"
  on public.budgets for delete
  using (
    user_id = auth.uid()
    and association_id is not null
    and public.is_association_member(association_id)
  );

-- ---------------------------------------------------------------------------
-- RPC: ensure personal association + backfill legacy rows
-- ---------------------------------------------------------------------------

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
    insert into public.associations (name, is_personal)
    values ('Personal', true)
    returning id into aid;

    insert into public.association_members (association_id, user_id, role)
    values (aid, uid, 'owner');
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

revoke all on function public.ensure_personal_association() from public;
grant execute on function public.ensure_personal_association() to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: create a new (non-personal) association
-- ---------------------------------------------------------------------------

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

  insert into public.associations (name, is_personal)
  values (trimmed, false)
  returning id into aid;

  insert into public.association_members (association_id, user_id, role)
  values (aid, uid, 'owner');

  return aid;
end;
$$;

revoke all on function public.create_association(text) from public;
grant execute on function public.create_association(text) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: delete a non-personal association (cascades financial data)
-- ---------------------------------------------------------------------------

create or replace function public.delete_association(p_association_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  is_pers boolean;
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  select a.is_personal
  into is_pers
  from public.associations a
  where a.id = p_association_id;

  if not found then
    raise exception 'Association not found';
  end if;

  if is_pers then
    raise exception 'Cannot delete personal ledger';
  end if;

  if not exists (
    select 1
    from public.association_members m
    where m.association_id = p_association_id
      and m.user_id = uid
      and m.role = 'owner'
  ) then
    raise exception 'Not allowed to delete this ledger';
  end if;

  delete from public.associations
  where id = p_association_id;
end;
$$;

revoke all on function public.delete_association(uuid) from public;
grant execute on function public.delete_association(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Update delete_account to remove associations
-- ---------------------------------------------------------------------------

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  delete from public.incomes where user_id = uid;
  delete from public.expenses where user_id = uid;
  delete from public.budgets where user_id = uid;
  delete from public.plans where user_id = uid;
  if to_regclass('public.loans') is not null then
    delete from public.loans where user_id = uid;
  end if;

  delete from public.associations a
  using public.association_members m
  where m.association_id = a.id
    and m.user_id = uid
    and not exists (
      select 1 from public.association_members m2
      where m2.association_id = a.id
        and m2.user_id <> uid
    );

  delete from public.association_members where user_id = uid;
  delete from public.profiles where id = uid;
  delete from auth.users where id = uid;
end;
$$;
