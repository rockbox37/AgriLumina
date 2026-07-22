const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// deno-lint-ignore no-control-regex
const CONTROL_CHARS_RE = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g;

export const AUTHOR_NAME_MAX = 40;
export const BODY_MIN = 2;
export const BODY_MAX = 2000;
export const REASON_MAX = 200;

export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID_RE.test(value);
}

/** Strips control characters (except newline/tab/CR) and trims. */
export function cleanText(value: string): string {
  return value.replace(CONTROL_CHARS_RE, "").trim();
}

export interface PostInput {
  deviceId: string;
  authorName: string;
  body: string;
  parentId: string | null;
}

export function parsePostInput(
  raw: Record<string, unknown>,
): { ok: true; value: PostInput } | { ok: false; error: string } {
  if (!isUuid(raw.device_id)) return { ok: false, error: "invalid_device_id" };
  if (raw.parent_id != null && !isUuid(raw.parent_id)) {
    return { ok: false, error: "invalid_parent_id" };
  }
  if (typeof raw.author_name !== "string" || typeof raw.body !== "string") {
    return { ok: false, error: "invalid_body" };
  }
  const authorName = cleanText(raw.author_name);
  const body = cleanText(raw.body);
  if (authorName.length < 1 || authorName.length > AUTHOR_NAME_MAX) {
    return { ok: false, error: "invalid_author_name" };
  }
  if (body.length < BODY_MIN || body.length > BODY_MAX) {
    return { ok: false, error: "invalid_body" };
  }
  return {
    ok: true,
    value: {
      deviceId: raw.device_id.toLowerCase(),
      authorName,
      body,
      parentId: raw.parent_id ? (raw.parent_id as string).toLowerCase() : null,
    },
  };
}

export interface ReportInput {
  deviceId: string;
  postId: string;
  reason: string | null;
}

export function parseReportInput(
  raw: Record<string, unknown>,
): { ok: true; value: ReportInput } | { ok: false; error: string } {
  if (!isUuid(raw.device_id)) return { ok: false, error: "invalid_device_id" };
  if (!isUuid(raw.post_id)) return { ok: false, error: "invalid_post_id" };
  let reason: string | null = null;
  if (raw.reason != null) {
    if (typeof raw.reason !== "string") {
      return { ok: false, error: "invalid_reason" };
    }
    reason = cleanText(raw.reason).slice(0, REASON_MAX) || null;
  }
  return {
    ok: true,
    value: {
      deviceId: raw.device_id.toLowerCase(),
      postId: raw.post_id.toLowerCase(),
      reason,
    },
  };
}
