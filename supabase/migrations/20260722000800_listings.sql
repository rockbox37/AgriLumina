-- Remote listings: the "find each other" sync slice (issue #24). One listing
-- per (device, role). Same trust model as the forum: base tables closed to
-- the API, writes via the `listings` edge function (service role), public
-- reads via the list_listings RPC which never exposes phone or device ids.

create table listings (
  id uuid primary key default gen_random_uuid(),
  -- Anonymous device identity; owner secret, never in public payloads.
  owner_device_id uuid not null,
  role text not null check (role in ('seller', 'buyer')),
  name text not null check (char_length(name) between 1 and 40),
  crop text not null check (char_length(crop) between 1 and 40),
  quantity_hint text not null check (char_length(quantity_hint) <= 120),
  lat double precision not null check (lat between -90 and 90),
  lon double precision not null check (lon between -180 and 180),
  location_text text not null default '' check (char_length(location_text) <= 80),
  tagline text not null default '' check (char_length(tagline) <= 100),
  -- Stored server-side; returned only by the contact endpoint.
  phone text not null check (char_length(phone) between 5 and 25),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_device_id, role)
);

create index listings_role_updated_idx on listings (role, updated_at desc);

-- Log of contact fetches: rate limiting now, admin stats later.
create table contact_unlocks (
  id bigint generated always as identity primary key,
  listing_id uuid not null references listings (id) on delete cascade,
  requester_device_id uuid not null,
  created_at timestamptz not null default now()
);

create index contact_unlocks_requester_idx
  on contact_unlocks (requester_device_id, created_at desc);

alter table listings enable row level security;
alter table contact_unlocks enable row level security;
revoke all on listings, contact_unlocks from anon, authenticated;

-- Admin god-mode (same pattern as the forum tables): read everything
-- including phone, delete for moderation.
grant select, delete on listings to authenticated;
create policy admin_read on listings
  for select to authenticated using (is_admin());
create policy admin_delete on listings
  for delete to authenticated using (is_admin());
grant select on contact_unlocks to authenticated;
create policy admin_read on contact_unlocks
  for select to authenticated using (is_admin());

-- Public read surface. Excludes the caller's own listings (they are shown
-- from local state in the app) and never returns phone or device ids.
-- With a position: filters to p_radius_km and orders by distance.
-- Without: distance_km is null and rows order by recency.
create function list_listings(
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

revoke execute on function
  list_listings(text, uuid, double precision, double precision, double precision, text)
  from public;
grant execute on function
  list_listings(text, uuid, double precision, double precision, double precision, text)
  to anon, authenticated;
