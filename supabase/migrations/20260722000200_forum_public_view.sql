-- Lock the base tables away from the API entirely; the only public surface is
-- the forum_public_posts view (reads) and the `forum` edge function (writes,
-- service role).

alter table forum_posts enable row level security;
alter table forum_reports enable row level security;
alter table forum_blocklist enable row level security;
alter table forum_banned_devices enable row level security;

revoke all on forum_posts, forum_reports, forum_blocklist, forum_banned_devices
  from anon, authenticated;

-- Security-definer view: exposes only visible posts and only public columns.
-- No device_id, report_count, spam_score, or moderation fields.
create view forum_public_posts
  with (security_invoker = off) as
  select id, parent_id, author_name, body, created_at, reply_count,
         last_activity_at
    from forum_posts
   where status = 'visible';

grant select on forum_public_posts to anon, authenticated;
