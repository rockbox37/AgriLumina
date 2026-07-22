-- Integrity + moderation triggers. These live in the database (not the edge
-- function) so counters and report-based auto-hide hold regardless of caller.

-- Auto-hide threshold: distinct reporters required to hide a visible post.
create function forum_report_threshold() returns integer
language sql immutable as $$ select 3 $$;

-- Replies must target a visible root post (depth 1, no replying into
-- hidden/deleted threads).
create function forum_check_parent() returns trigger
language plpgsql as $$
declare
  parent forum_posts%rowtype;
begin
  if new.parent_id is null then
    return new;
  end if;
  select * into parent from forum_posts where id = new.parent_id;
  if not found or parent.parent_id is not null then
    raise exception 'parent must be a root post' using errcode = '23514';
  end if;
  if parent.status <> 'visible' then
    raise exception 'parent post is not visible' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger forum_posts_check_parent
  before insert on forum_posts
  for each row execute function forum_check_parent();

-- Maintain the parent's reply_count / last_activity_at as replies arrive.
create function forum_after_reply_insert() returns trigger
language plpgsql as $$
begin
  if new.parent_id is not null and new.status = 'visible' then
    update forum_posts
      set reply_count = reply_count + 1,
          last_activity_at = new.created_at
      where id = new.parent_id;
  end if;
  return null;
end;
$$;

create trigger forum_posts_after_reply_insert
  after insert on forum_posts
  for each row execute function forum_after_reply_insert();

-- Keep reply_count in sync when a reply's visibility changes
-- (hidden/spam/deleted <-> visible).
create function forum_after_reply_status_change() returns trigger
language plpgsql as $$
begin
  if new.parent_id is null then
    return null;
  end if;
  if old.status = 'visible' and new.status <> 'visible' then
    update forum_posts set reply_count = greatest(reply_count - 1, 0)
      where id = new.parent_id;
  elsif old.status <> 'visible' and new.status = 'visible' then
    update forum_posts set reply_count = reply_count + 1
      where id = new.parent_id;
  end if;
  return null;
end;
$$;

create trigger forum_posts_after_status_change
  after update of status on forum_posts
  for each row execute function forum_after_reply_status_change();

-- Count distinct reporters and auto-hide once the threshold is reached.
create function forum_after_report_insert() returns trigger
language plpgsql as $$
begin
  update forum_posts set report_count = report_count + 1
    where id = new.post_id;
  update forum_posts
    set status = 'hidden', hidden_reason = 'reports'
    where id = new.post_id
      and status = 'visible'
      and report_count >= forum_report_threshold();
  return null;
end;
$$;

create trigger forum_reports_after_insert
  after insert on forum_reports
  for each row execute function forum_after_report_insert();
