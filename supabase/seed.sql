-- Local development seed only (loaded by `supabase db reset`, never deployed).
-- A couple of visible threads with replies so the public view has content.

with root1 as (
  insert into forum_posts (device_id, author_name, body, content_hash)
  values (
    '00000000-0000-4000-8000-000000000001',
    'Amani K.',
    'Maize prices at Bugobe market went up this week. Buyers are paying more for dried maize than fresh.',
    encode(sha256('seed-root-1'::bytea), 'hex')
  )
  returning id
)
insert into forum_posts (parent_id, device_id, author_name, body, content_hash)
select id,
       '00000000-0000-4000-8000-000000000002',
       'Chantal M.',
       'Thanks for sharing. Is that at the main market or the roadside stalls?',
       encode(sha256('seed-reply-1'::bytea), 'hex')
  from root1;

insert into forum_posts (device_id, author_name, body, content_hash)
values (
  '00000000-0000-4000-8000-000000000003',
  'Jean-Paul B.',
  'Looking for advice on storing cassava through the rainy season without losing quality.',
  encode(sha256('seed-root-2'::bytea), 'hex')
);
