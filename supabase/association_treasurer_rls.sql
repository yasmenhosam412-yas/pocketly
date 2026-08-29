-- Treasurer mode: one manager (owner) records all income/expense/plans/budgets
-- for a shared ledger; members can view only.
-- Run after associations.sql and association_invites.sql.

create or replace function public.is_association_owner(p_association_id uuid)
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
      and m.role = 'owner'
  );
$$;

create or replace function public.is_personal_association(p_association_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select a.is_personal from public.associations a where a.id = p_association_id),
    true
  );
$$;

-- Helper: can read a financial row
create or replace function public.can_read_financial_row(
  p_association_id uuid,
  p_row_user_id uuid
)
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
      and p_row_user_id = auth.uid()
      or not public.is_personal_association(p_association_id)
    );
$$;

-- Helper: can write a financial row
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
      (
        public.is_personal_association(p_association_id)
      )
      or (
        not public.is_personal_association(p_association_id)
        and public.is_association_owner(p_association_id)
      )
    );
$$;

-- INCOMES
drop policy if exists "Members read incomes" on public.incomes;
drop policy if exists "Members insert incomes" on public.incomes;
drop policy if exists "Members update incomes" on public.incomes;
drop policy if exists "Members delete incomes" on public.incomes;

create policy "Members read incomes"
  on public.incomes for select
  using (public.can_read_financial_row(association_id, user_id));

create policy "Members insert incomes"
  on public.incomes for insert
  with check (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members update incomes"
  on public.incomes for update
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members delete incomes"
  on public.incomes for delete
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

-- EXPENSES
drop policy if exists "Members read expenses" on public.expenses;
drop policy if exists "Members insert expenses" on public.expenses;
drop policy if exists "Members update expenses" on public.expenses;
drop policy if exists "Members delete expenses" on public.expenses;

create policy "Members read expenses"
  on public.expenses for select
  using (public.can_read_financial_row(association_id, user_id));

create policy "Members insert expenses"
  on public.expenses for insert
  with check (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members update expenses"
  on public.expenses for update
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members delete expenses"
  on public.expenses for delete
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

-- PLANS
drop policy if exists "Members read plans" on public.plans;
drop policy if exists "Members insert plans" on public.plans;
drop policy if exists "Members update plans" on public.plans;
drop policy if exists "Members delete plans" on public.plans;

create policy "Members read plans"
  on public.plans for select
  using (public.can_read_financial_row(association_id, user_id));

create policy "Members insert plans"
  on public.plans for insert
  with check (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members update plans"
  on public.plans for update
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members delete plans"
  on public.plans for delete
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

-- LOANS (run supabase/loans.sql first)
do $$
begin
  if to_regclass('public.loans') is null then
    return;
  end if;
  execute 'drop policy if exists "Members read loans" on public.loans';
  execute 'drop policy if exists "Members insert loans" on public.loans';
  execute 'drop policy if exists "Members update loans" on public.loans';
  execute 'drop policy if exists "Members delete loans" on public.loans';
  execute $p$
    create policy "Members read loans"
      on public.loans for select
      using (public.can_read_financial_row(association_id, user_id))
  $p$;
  execute $p$
    create policy "Members insert loans"
      on public.loans for insert
      with check (
        user_id = auth.uid()
        and public.can_write_financial_row(association_id)
      )
  $p$;
  execute $p$
    create policy "Members update loans"
      on public.loans for update
      using (
        user_id = auth.uid()
        and public.can_write_financial_row(association_id)
      )
  $p$;
  execute $p$
    create policy "Members delete loans"
      on public.loans for delete
      using (
        user_id = auth.uid()
        and public.can_write_financial_row(association_id)
      )
  $p$;
end $$;

-- BUDGETS
drop policy if exists "Members read budgets" on public.budgets;
drop policy if exists "Members insert budgets" on public.budgets;
drop policy if exists "Members update budgets" on public.budgets;
drop policy if exists "Members delete budgets" on public.budgets;

create policy "Members read budgets"
  on public.budgets for select
  using (public.can_read_financial_row(association_id, user_id));

create policy "Members insert budgets"
  on public.budgets for insert
  with check (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members update budgets"
  on public.budgets for update
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );

create policy "Members delete budgets"
  on public.budgets for delete
  using (
    user_id = auth.uid()
    and public.can_write_financial_row(association_id)
  );
