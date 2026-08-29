-- Tracks money you lent (given) and money you borrowed (received).

create table if not exists public.loans (
  loan_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  association_id uuid references public.associations (id) on delete cascade,
  person_name text not null,
  direction text not null check (direction in ('given', 'received')),
  principal double precision not null check (principal > 0),
  repaid_amount double precision not null default 0
    check (repaid_amount >= 0 and repaid_amount <= principal),
  due_date date,
  notes text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists loans_user_idx on public.loans (user_id);
create index if not exists loans_association_idx on public.loans (association_id);

alter table public.loans enable row level security;

drop policy if exists "Users can read own loans" on public.loans;
create policy "Users can read own loans"
  on public.loans for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own loans" on public.loans;
create policy "Users can insert own loans"
  on public.loans for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own loans" on public.loans;
create policy "Users can update own loans"
  on public.loans for update
  using (auth.uid() = user_id);

drop policy if exists "Users can delete own loans" on public.loans;
create policy "Users can delete own loans"
  on public.loans for delete
  using (auth.uid() = user_id);

-- Association member policies (no-op if helper functions are not installed yet).
do $$
begin
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'can_read_financial_row'
  ) then
    drop policy if exists "Members read loans" on public.loans;
    drop policy if exists "Members insert loans" on public.loans;
    drop policy if exists "Members update loans" on public.loans;
    drop policy if exists "Members delete loans" on public.loans;

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
  end if;
end $$;
