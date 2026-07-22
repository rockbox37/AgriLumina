-- Admin god-mode access to the forum tables via PostgREST: grants let the
-- authenticated role through, RLS policies restrict every row to admins.
-- The anon role gains nothing; non-admin authenticated JWTs see zero rows.

-- Global-recency indexes used by admin_stats() and the rate-spike triggers.
create index forum_posts_created_idx on forum_posts (created_at desc);
create index forum_reports_created_idx on forum_reports (created_at desc);

grant select on forum_posts, forum_reports, forum_blocklist, forum_banned_devices
  to authenticated;

create policy admin_read on forum_posts
  for select to authenticated using (is_admin());
create policy admin_read on forum_reports
  for select to authenticated using (is_admin());
create policy admin_read on forum_blocklist
  for select to authenticated using (is_admin());
create policy admin_read on forum_banned_devices
  for select to authenticated using (is_admin());

-- Blocklist: full CRUD (identity column needs sequence usage for inserts).
grant insert, update, delete on forum_blocklist to authenticated;
grant usage on sequence forum_blocklist_id_seq to authenticated;
create policy admin_insert on forum_blocklist
  for insert to authenticated with check (is_admin());
create policy admin_update on forum_blocklist
  for update to authenticated using (is_admin()) with check (is_admin());
create policy admin_delete on forum_blocklist
  for delete to authenticated using (is_admin());

-- Banned devices: full CRUD.
grant insert, update, delete on forum_banned_devices to authenticated;
create policy admin_insert on forum_banned_devices
  for insert to authenticated with check (is_admin());
create policy admin_update on forum_banned_devices
  for update to authenticated using (is_admin()) with check (is_admin());
create policy admin_delete on forum_banned_devices
  for delete to authenticated using (is_admin());

-- Deliberately NO write grants on forum_posts / forum_reports: moderation
-- status changes go through admin_set_post_status() so status and
-- hidden_reason change together and counters/hashes stay protected; reports
-- are read-only evidence.
