-- Forum: public posts (threads + single-level replies) with anti-spam metadata.
-- All tables are private to the API; writes go through the `forum` edge function
-- (service role) and public reads through the forum_public_posts view.

create table forum_posts (
  id uuid primary key default gen_random_uuid(),
  -- null = thread root; non-null = reply to a root post (depth 1, trigger-enforced)
  parent_id uuid references forum_posts (id),
  -- Anonymous device identity; acts as the author's secret. Never exposed publicly.
  device_id uuid not null,
  author_name text not null check (char_length(author_name) between 1 and 40),
  body text not null check (char_length(body) between 2 and 2000),
  status text not null default 'visible'
    check (status in ('visible', 'hidden', 'spam', 'deleted')),
  hidden_reason text
    check (hidden_reason in ('auto_heuristic', 'reports', 'admin')),
  spam_score integer not null default 0,
  -- sha256 of the normalized body, for duplicate detection
  content_hash text not null,
  -- Distinct reporters, maintained by trigger on forum_reports
  report_count integer not null default 0,
  -- Visible replies, maintained by trigger; only meaningful on roots
  reply_count integer not null default 0,
  created_at timestamptz not null default now(),
  -- Thread sort key; bumped when a visible reply arrives
  last_activity_at timestamptz not null default now()
);

create index forum_posts_thread_list_idx
  on forum_posts (status, last_activity_at desc) where parent_id is null;
create index forum_posts_replies_idx
  on forum_posts (parent_id, created_at) where parent_id is not null;
create index forum_posts_device_idx on forum_posts (device_id, created_at desc);
create index forum_posts_hash_idx on forum_posts (content_hash, created_at desc);

create table forum_reports (
  id bigint generated always as identity primary key,
  post_id uuid not null references forum_posts (id) on delete cascade,
  reporter_device_id uuid not null,
  reason text check (char_length(reason) <= 200),
  created_at timestamptz not null default now(),
  unique (post_id, reporter_device_id)
);

create index forum_reports_reporter_idx
  on forum_reports (reporter_device_id, created_at desc);

-- Terms matched (as substrings) against the normalized post body.
-- Editable server-side (and later via the admin dashboard) without redeploys.
create table forum_blocklist (
  id bigint generated always as identity primary key,
  term text not null unique,
  weight integer not null default 3,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Devices barred from posting; a future admin lever, enforced today.
create table forum_banned_devices (
  device_id uuid primary key,
  reason text,
  created_at timestamptz not null default now()
);
