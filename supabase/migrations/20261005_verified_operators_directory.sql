-- Public "Operators" directory (app/operators on the website) needs to
-- discover WHICH operators are verified, not just resolve already-known
-- ids to names. The existing get_public_profiles_by_ids RPC (not in this
-- migration history — applied directly to the project's Supabase instance
-- before this repo's migrations began) only does the latter: given a list
-- of ids, it returns their public-safe fields. There's no equivalent for
-- "list everyone matching X", and per README.md, a direct
-- `.from("profiles").select(...)` for other users' rows is expected to be
-- blocked or nulled out by RLS for a non-admin caller.
--
-- This mirrors that same safe approach for the one new case the directory
-- needs: enumerate approved operator accounts, exposing only non-sensitive
-- public fields (id, full_name) — nothing from profiles that isn't already
-- surfaced elsewhere (email, verification documents, etc. stay hidden).
--
-- NOT APPLIED AUTOMATICALLY. This session has no database credentials for
-- your Supabase project — review this and run it yourself (SQL editor or
-- `supabase db push` / your migration tool of choice) before /operators
-- will show anyone.

create or replace function public.get_verified_operators()
returns table (id uuid, full_name text)
language sql
security definer
set search_path = public
as $$
  select id, full_name
  from profiles
  where user_type = 'operator'
    and verification_status = 'approved'
    and coalesce(is_admin, false) = false
  order by full_name;
$$;

grant execute on function public.get_verified_operators() to anon, authenticated;
