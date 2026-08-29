-- Member usernames for family (and other shared) ledgers.
-- Used to show who added each transaction.

create or replace function public.list_association_member_names(p_association_id uuid)
returns table (user_id uuid, username text)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  if p_association_id is null
     or not public.is_association_member(p_association_id) then
    raise exception 'Not a member of this ledger';
  end if;

  return query
  select m.user_id, coalesce(p.username, '')::text
  from public.association_members m
  left join public.profiles p on p.id = m.user_id
  where m.association_id = p_association_id;
end;
$$;

revoke all on function public.list_association_member_names(uuid) from public;
grant execute on function public.list_association_member_names(uuid) to authenticated;
