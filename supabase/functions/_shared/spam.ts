// Automatic anti-spam pipeline: body normalization, duplicate hashing, and
// heuristic scoring. Pure functions — no I/O — so they are unit-testable.

/** Heuristic score at or above which a post is hidden pending review. */
export const HIDE_THRESHOLD = 5;
/** Heuristic score at or above which a post is marked spam outright. */
export const SPAM_THRESHOLD = 10;
/** Distinct devices posting the same normalized body in the duplicate window
 * before further copies are hidden as coordinated spam. */
export const CROSS_DEVICE_DUPLICATE_LIMIT = 3;
/** Window for duplicate-content detection. */
export const DUPLICATE_WINDOW_HOURS = 24;

/** Rate limits per device (all statuses count, so hidden spam still throttles). */
export const RATE_LIMITS = [
  { windowSeconds: 30, maxPosts: 1 },
  { windowSeconds: 60 * 60, maxPosts: 10 },
  { windowSeconds: 24 * 60 * 60, maxPosts: 30 },
] as const;

export const REPORT_RATE_LIMIT = { windowSeconds: 24 * 60 * 60, max: 20 };

/**
 * Canonical form used for duplicate detection and blocklist matching:
 * lowercase, diacritics stripped, punctuation removed, whitespace collapsed.
 */
export function normalizeBody(body: string): string {
  return body
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export async function contentHash(body: string): Promise<string> {
  const data = new TextEncoder().encode(normalizeBody(body));
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export interface BlocklistEntry {
  term: string;
  weight: number;
}

export interface ScoreContext {
  /** True when this device has never posted before. */
  isFirstPost: boolean;
  blocklist: BlocklistEntry[];
}

export interface ScoreResult {
  score: number;
  /** Rule labels that fired, for the audit trail / server logs only. */
  signals: string[];
}

const URL_RE = /(?:https?:\/\/|www\.)[^\s]+/gi;
/** 8+ digits, allowing separators — phone-like runs. */
const PHONE_RE = /(?:\d[\s\-.()]?){8,}/g;
const REPEATED_CHAR_RE = /(.)\1{5,}/;

export function scorePost(body: string, ctx: ScoreContext): ScoreResult {
  const signals: string[] = [];
  let score = 0;

  const urls = body.match(URL_RE) ?? [];
  if (urls.length > 0) {
    score += urls.length * 3;
    signals.push(`urls:${urls.length}`);
    if (urls.length > 2) {
      score += 4;
      signals.push("many_urls");
    }
    if (ctx.isFirstPost) {
      score += 2;
      signals.push("first_post_url");
    }
  }

  // Low weight: sharing a phone number is plausible in a marketplace forum.
  if (PHONE_RE.test(body)) {
    score += 2;
    signals.push("phone_run");
  }

  const letters = body.replace(/[^\p{L}]/gu, "");
  if (letters.length >= 20) {
    const upper = letters.replace(/[^\p{Lu}]/gu, "").length;
    if (upper / letters.length > 0.6) {
      score += 2;
      signals.push("caps");
    }
  }

  if (REPEATED_CHAR_RE.test(body)) {
    score += 1;
    signals.push("repeated_chars");
  }

  if (body.length > 1500) {
    score += 1;
    signals.push("very_long");
  }

  const normalized = normalizeBody(body);
  for (const entry of ctx.blocklist) {
    if (normalized.includes(entry.term)) {
      score += entry.weight;
      signals.push(`blocklist:${entry.term}`);
    }
  }

  return { score, signals };
}

export type PostStatus = "visible" | "hidden" | "spam";

export function statusForScore(score: number): PostStatus {
  if (score >= SPAM_THRESHOLD) return "spam";
  if (score >= HIDE_THRESHOLD) return "hidden";
  return "visible";
}
