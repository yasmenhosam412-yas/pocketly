-- Unique usernames (case-insensitive). Run via supabase db push.

-- Keep the first profile for each name; suffix later duplicates.
update public.profiles p
set username = trim(p.username) || '_' || substr(replace(p.id::text, '-', ''), 1, 6)
where p.id in (
  select id
  from (
    select id,
      row_number() over (
        partition by lower(trim(username))
        order by id
      ) as rn
    from public.profiles
    where username is not null
      and trim(username) <> ''
  ) d
  where rn > 1
);

create unique index if not exists profiles_username_lower_uidx
  on public.profiles (lower(trim(username)))
  where trim(coalesce(username, '')) <> '';

create or replace function public.normalize_profile_username()
returns trigger
language plpgsql
as $$
begin
  new.username := trim(coalesce(new.username, ''));
  return new;
end;
$$;

drop trigger if exists profiles_normalize_username on public.profiles;
create trigger profiles_normalize_username
before insert or update of username on public.profiles
for each row
execute function public.normalize_profile_username();

create or replace function public.is_username_taken(p_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where trim(coalesce(p.username, '')) <> ''
      and lower(trim(p.username)) = lower(trim(coalesce(p_username, '')))
      and (auth.uid() is null or p.id <> auth.uid())
  );
$$;

revoke all on function public.is_username_taken(text) from public;
grant execute on function public.is_username_taken(text) to anon, authenticated;
