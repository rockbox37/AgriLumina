-- Platform admins. Rows are inserted only via service role / SQL (see the
-- bootstrap procedure in the PR description) — there is deliberately no
-- client-reachable path that can mint an admin.

create table admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table admin_users enable row level security;
revoke all on admin_users from anon, authenticated;

-- Gate for all admin RLS policies and RPCs. SECURITY DEFINER so it can read
-- admin_users despite the revoke; (select auth.uid()) lets the planner cache
-- the result once per statement.
create function is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  )
$$;

revoke execute on function is_admin() from public, anon;
grant execute on function is_admin() to authenticated;
