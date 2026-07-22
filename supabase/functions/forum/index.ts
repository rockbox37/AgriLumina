// Forum write API. All mutations flow through here (service role) so the
// anti-spam pipeline runs atomically before anything is inserted; public
// reads go straight to PostgREST via the forum_public_posts view.
//
//   POST   /forum/posts        {device_id, author_name, body, parent_id?}
//   POST   /forum/reports      {device_id, post_id, reason?}
//   DELETE /forum/posts/:id    {device_id}

import { corsHeaders, json } from "../_shared/cors.ts";
import { parsePostInput, parseReportInput } from "../_shared/validation.ts";
import {
  contentHash,
  CROSS_DEVICE_DUPLICATE_LIMIT,
  DUPLICATE_WINDOW_HOURS,
  RATE_LIMITS,
  REPORT_RATE_LIMIT,
  scorePost,
  statusForScore,
} from "../_shared/spam.ts";
import {
  activeBlocklist,
  countRecentPosts,
  countRecentReports,
  Db,
  duplicateInfo,
  hasAnyPost,
  isBannedDevice,
  serviceClient,
} from "../_shared/db.ts";

async function readJson(req: Request): Promise<Record<string, unknown> | null> {
  try {
    const body = await req.json();
    return typeof body === "object" && body !== null ? body : null;
  } catch {
    return null;
  }
}

async function createPost(db: Db, req: Request): Promise<Response> {
  const raw = await readJson(req);
  if (!raw) return json({ error: "invalid_json" }, 400);
  const parsed = parsePostInput(raw);
  if (!parsed.ok) return json({ error: parsed.error }, 400);
  const input = parsed.value;

  if (await isBannedDevice(db, input.deviceId)) {
    return json({ error: "forbidden" }, 403);
  }

  for (const limit of RATE_LIMITS) {
    const recent = await countRecentPosts(db, input.deviceId, limit.windowSeconds);
    if (recent >= limit.maxPosts) {
      return json(
        { error: "rate_limited", retry_after_seconds: limit.windowSeconds },
        429,
        { "Retry-After": String(limit.windowSeconds) },
      );
    }
  }

  const hash = await contentHash(input.body);
  const dup = await duplicateInfo(
    db,
    input.deviceId,
    hash,
    DUPLICATE_WINDOW_HOURS * 3600,
  );
  if (dup.sameDevice) return json({ error: "duplicate" }, 409);

  const blocklist = await activeBlocklist(db);
  const isFirstPost = !(await hasAnyPost(db, input.deviceId));
  const { score, signals } = scorePost(input.body, { isFirstPost, blocklist });

  let status = statusForScore(score);
  // Same content from several devices inside the window: coordinated spam.
  if (
    status === "visible" && dup.totalInWindow >= CROSS_DEVICE_DUPLICATE_LIMIT
  ) {
    status = "hidden";
    signals.push("cross_device_duplicate");
  }

  const { data, error } = await db
    .from("forum_posts")
    .insert({
      parent_id: input.parentId,
      device_id: input.deviceId,
      author_name: input.authorName,
      body: input.body,
      status,
      hidden_reason: status === "visible" ? null : "auto_heuristic",
      spam_score: score,
      content_hash: hash,
    })
    .select("id, created_at")
    .single();
  if (error) {
    // Trigger rejects replies to missing/hidden/non-root parents (23514).
    if (error.code === "23514" || error.code === "23503") {
      return json({ error: "invalid_parent" }, 400);
    }
    throw error;
  }

  if (status !== "visible") {
    console.log(
      `post ${data.id} auto-${status} score=${score} signals=${signals.join(",")}`,
    );
  }
  return json(
    {
      id: data.id,
      created_at: data.created_at,
      // Single opaque value for anything not visible: no oracle telling
      // spammers which rule fired.
      status: status === "visible" ? "visible" : "pending_review",
    },
    201,
  );
}

async function createReport(db: Db, req: Request): Promise<Response> {
  const raw = await readJson(req);
  if (!raw) return json({ error: "invalid_json" }, 400);
  const parsed = parseReportInput(raw);
  if (!parsed.ok) return json({ error: parsed.error }, 400);
  const input = parsed.value;

  const reports = await countRecentReports(
    db,
    input.deviceId,
    REPORT_RATE_LIMIT.windowSeconds,
  );
  if (reports >= REPORT_RATE_LIMIT.max) {
    return json({ error: "rate_limited" }, 429);
  }

  const { data: post, error: postError } = await db
    .from("forum_posts")
    .select("id, device_id")
    .eq("id", input.postId)
    .maybeSingle();
  if (postError) throw postError;
  if (!post) return json({ error: "not_found" }, 404);
  if (post.device_id === input.deviceId) {
    return json({ error: "cannot_report_own_post" }, 400);
  }

  // Idempotent: a repeat report from the same device is a no-op success.
  const { error } = await db
    .from("forum_reports")
    .upsert(
      {
        post_id: input.postId,
        reporter_device_id: input.deviceId,
        reason: input.reason,
      },
      { onConflict: "post_id,reporter_device_id", ignoreDuplicates: true },
    );
  if (error) throw error;
  return json({ ok: true });
}

async function deletePost(
  db: Db,
  req: Request,
  postId: string,
): Promise<Response> {
  const raw = await readJson(req);
  if (!raw) return json({ error: "invalid_json" }, 400);
  const deviceId = typeof raw.device_id === "string"
    ? raw.device_id.toLowerCase()
    : "";

  const { data: post, error: postError } = await db
    .from("forum_posts")
    .select("id, device_id, status")
    .eq("id", postId)
    .maybeSingle();
  if (postError) throw postError;
  if (!post) return json({ error: "not_found" }, 404);
  if (!deviceId || post.device_id !== deviceId) {
    return json({ error: "forbidden" }, 403);
  }

  if (post.status !== "deleted") {
    const { error } = await db
      .from("forum_posts")
      .update({ status: "deleted" })
      .eq("id", postId);
    if (error) throw error;
  }
  return json({ ok: true });
}

const UUID_PATH_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Path relative to the function mount: /forum/<...>
  const segments = new URL(req.url).pathname.split("/").filter(Boolean);
  const route = segments.slice(1); // drop the "forum" prefix

  try {
    const db = serviceClient();
    if (req.method === "POST" && route.length === 1 && route[0] === "posts") {
      return await createPost(db, req);
    }
    if (req.method === "POST" && route.length === 1 && route[0] === "reports") {
      return await createReport(db, req);
    }
    if (
      req.method === "DELETE" && route.length === 2 && route[0] === "posts" &&
      UUID_PATH_RE.test(route[1])
    ) {
      return await deletePost(db, req, route[1].toLowerCase());
    }
    return json({ error: "not_found" }, 404);
  } catch (error) {
    console.error("forum function error:", error);
    return json({ error: "internal" }, 500);
  }
});
