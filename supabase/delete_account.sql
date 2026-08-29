-- Run this in the Supabase SQL editor (Dashboard → SQL).
-- Deletes app data AND the row in auth.users for the signed-in user.

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
  delete from public.profiles where id = uid;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;

-- Allow users to delete their own profile row (client-side fallback).
drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile"
  on public.profiles
  for delete
  using (auth.uid() = id);
