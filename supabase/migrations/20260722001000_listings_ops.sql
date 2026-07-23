-- Listings operations round-out: read-side expiry, listings alert rules,
-- and listings metrics in the admin stats payload.

-- 1. Expiry: listings older than 30 days drop out of the public feed.
-- Re-publishing bumps updated_at (upsert), which refreshes the listing.
-- Admin table reads are unaffected — expired rows stay visible to admins.
create or replace function list_listings(
  p_role text,
  p_exclude_device uuid default null,
  p_lat double precision default null,
  p_lon double precision default null,
  p_radius_km double precision default 50,
  p_crop text default null
)
returns table (
  id uuid,
  role text,
  name text,
  crop text,
  quantity_hint text,
  lat double precision,
  lon double precision,
  location_text text,
  tagline text,
  updated_at timestamptz,
  distance_km double precision
)
language sql stable security definer set search_path = public
as $$
  with candidates as (
    select l.*,
           case
             when p_lat is null or p_lon is null then null
             else 2 * 6371 * asin(sqrt(
               power(sin(radians(l.lat - p_lat) / 2), 2) +
               cos(radians(p_lat)) * cos(radians(l.lat)) *
               power(sin(radians(l.lon - p_lon) / 2), 2)
             ))
           end as distance_km
      from listings l
     where l.role = p_role
       and l.updated_at > now() - interval '30 days'
       and (p_exclude_device is null or l.owner_device_id <> p_exclude_device)
       and (p_crop is null or l.crop = p_crop)
  )
  select c.id, c.role, c.name, c.crop, c.quantity_hint, c.lat, c.lon,
         c.location_text, c.tagline, c.updated_at, c.distance_km
    from candidates c
   where c.distance_km is null
      or p_radius_km is null
      or c.distance_km <= p_radius_km
   order by c.distance_km asc nulls last, c.updated_at desc
   limit 50
$$;

-- 2. Listings alert rules. Rule ids only enter via migrations (the dashboard
-- can only patch enabled/threshold), so the id enum check is retired instead
-- of being rewritten by every migration that adds a rule.
alter table admin_alert_rules drop constraint admin_alert_rules_id_check;

insert into admin_alert_rules (id, threshold) values
  ('listing_rate_spike', 10),
  ('contact_rate_spike', 20);

-- New listings per hour above threshold (re-upserts of an existing listing
-- update in place and do not count).
create function admin_alerts_on_listing_insert() returns trigger
language plpgsql as $$
declare
  r admin_alert_rules%rowtype;
  n bigint;
begin
  select * into r from admin_alert_rules
   where id = 'listing_rate_spike' and enabled and threshold is not null;
  if found then
    select count(*) into n from listings
     where created_at > now() - interval '1 hour';
    if n >= r.threshold and not exists (
         select 1 from admin_alerts
          where rule_id = 'listing_rate_spike' and not read
            and created_at > now() - interval '1 hour') then
      insert into admin_alerts (rule_id, detail)
      values ('listing_rate_spike',
              jsonb_build_object('count_last_hour', n,
                                 'threshold', r.threshold,
                                 'listing_id', new.id));
    end if;
  end if;
  return null;
end;
$$;

create trigger listings_admin_alerts
  after insert on listings
  for each row execute function admin_alerts_on_listing_insert();

-- Contact fetches per hour above threshold (possible scraping).
create function admin_alerts_on_contact_unlock() returns trigger
language plpgsql as $$
declare
  r admin_alert_rules%rowtype;
  n bigint;
begin
  select * into r from admin_alert_rules
   where id = 'contact_rate_spike' and enabled and threshold is not null;
  if found then
    select count(*) into n from contact_unlocks
     where created_at > now() - interval '1 hour';
    if n >= r.threshold and not exists (
         select 1 from admin_alerts
          where rule_id = 'contact_rate_spike' and not read
            and created_at > now() - interval '1 hour') then
      insert into admin_alerts (rule_id, detail)
      values ('contact_rate_spike',
              jsonb_build_object('count_last_hour', n,
                                 'threshold', r.threshold,
                                 'requester_device_id',
                                 new.requester_device_id));
    end if;
  end if;
  return null;
end;
$$;

create trigger contact_unlocks_admin_alerts
  after insert on contact_unlocks
  for each row execute function admin_alerts_on_contact_unlock();

-- 3. Listings metrics in the dashboard payload. Existing keys unchanged.
create or replace function admin_stats() returns jsonb
language plpgsql stable security definer set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'posts_by_status',
      (select coalesce(jsonb_object_agg(status, n), '{}'::jsonb)
         from (select status, count(*) n from forum_posts group by status) s),
    'posts_24h',
      (select count(*) from forum_posts
        where created_at > now() - interval '24 hours'),
    'posts_7d',
      (select count(*) from forum_posts
        where created_at > now() - interval '7 days'),
    'reports_24h',
      (select count(*) from forum_reports
        where created_at > now() - interval '24 hours'),
    'reports_7d',
      (select count(*) from forum_reports
        where created_at > now() - interval '7 days'),
    'active_devices_24h',
      (select count(distinct device_id) from forum_posts
        where created_at > now() - interval '24 hours'),
    'active_devices_7d',
      (select count(distinct device_id) from forum_posts
        where created_at > now() - interval '7 days'),
    'banned_devices', (select count(*) from forum_banned_devices),
    'unread_alerts', (select count(*) from admin_alerts where not read),
    'top_reported',
      (select coalesce(jsonb_agg(t), '[]'::jsonb) from (
         select id, author_name, left(body, 120) as snippet, status,
                report_count, created_at
           from forum_posts
          where report_count > 0
          order by report_count desc, created_at desc
          limit 10) t),
    'listings_by_role',
      (select coalesce(jsonb_object_agg(role, n), '{}'::jsonb)
         from (select role, count(*) n from listings group by role) s),
    'listings_active',
      (select count(*) from listings
        where updated_at > now() - interval '30 days'),
    'listings_24h',
      (select count(*) from listings
        where created_at > now() - interval '24 hours'),
    'listings_7d',
      (select count(*) from listings
        where created_at > now() - interval '7 days'),
    'contact_unlocks_24h',
      (select count(*) from contact_unlocks
        where created_at > now() - interval '24 hours'),
    'contact_unlocks_7d',
      (select count(*) from contact_unlocks
        where created_at > now() - interval '7 days')
  );
end;
$$;
