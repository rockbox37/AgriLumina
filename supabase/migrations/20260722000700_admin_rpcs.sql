-- Admin RPCs, callable via PostgREST with an admin JWT.

-- Atomic moderation verb: approve / hide / spam / soft-delete. Keeps status
-- and hidden_reason consistent; the existing forum_posts_after_status_change
-- trigger maintains parent reply_count.
create function admin_set_post_status(p_post_id uuid, p_status text)
returns forum_posts
language plpgsql security definer set search_path = public
as $$
declare
  v_post forum_posts;
begin
  if not is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_status not in ('visible', 'hidden', 'spam', 'deleted') then
    raise exception 'invalid status %', p_status using errcode = '22023';
  end if;
  update forum_posts
     set status = p_status,
         hidden_reason = case when p_status = 'visible' then null
                              else 'admin' end
   where id = p_post_id
   returning * into v_post;
  if not found then
    raise exception 'post % not found', p_post_id using errcode = 'P0002';
  end if;
  return v_post;
end;
$$;

-- One-round-trip dashboard payload.
create function admin_stats() returns jsonb
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
          limit 10) t)
  );
end;
$$;

revoke execute on function admin_set_post_status(uuid, text) from public, anon;
revoke execute on function admin_stats() from public, anon;
grant execute on function admin_set_post_status(uuid, text) to authenticated;
grant execute on function admin_stats() to authenticated;
