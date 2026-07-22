import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { BlocklistEntry } from "./spam.ts";

export type Db = SupabaseClient;

export function serviceClient(): Db {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

let blocklistCache: { entries: BlocklistEntry[]; fetchedAt: number } | null =
  null;
const BLOCKLIST_TTL_MS = 60_000;

export async function activeBlocklist(db: Db): Promise<BlocklistEntry[]> {
  const now = Date.now();
  if (blocklistCache && now - blocklistCache.fetchedAt < BLOCKLIST_TTL_MS) {
    return blocklistCache.entries;
  }
  const { data, error } = await db
    .from("forum_blocklist")
    .select("term, weight")
    .eq("active", true);
  if (error) throw error;
  blocklistCache = { entries: data ?? [], fetchedAt: now };
  return blocklistCache.entries;
}

export async function isBannedDevice(
  db: Db,
  deviceId: string,
): Promise<boolean> {
  const { count, error } = await db
    .from("forum_banned_devices")
    .select("device_id", { count: "exact", head: true })
    .eq("device_id", deviceId);
  if (error) throw error;
  return (count ?? 0) > 0;
}

function sinceIso(seconds: number): string {
  return new Date(Date.now() - seconds * 1000).toISOString();
}

/** Posts by this device within the window, any status. */
export async function countRecentPosts(
  db: Db,
  deviceId: string,
  windowSeconds: number,
): Promise<number> {
  const { count, error } = await db
    .from("forum_posts")
    .select("id", { count: "exact", head: true })
    .eq("device_id", deviceId)
    .gte("created_at", sinceIso(windowSeconds));
  if (error) throw error;
  return count ?? 0;
}

export async function hasAnyPost(db: Db, deviceId: string): Promise<boolean> {
  const { count, error } = await db
    .from("forum_posts")
    .select("id", { count: "exact", head: true })
    .eq("device_id", deviceId);
  if (error) throw error;
  return (count ?? 0) > 0;
}

export interface DuplicateInfo {
  sameDevice: boolean;
  totalInWindow: number;
}

export async function duplicateInfo(
  db: Db,
  deviceId: string,
  hash: string,
  windowSeconds: number,
): Promise<DuplicateInfo> {
  const { data, error } = await db
    .from("forum_posts")
    .select("device_id")
    .eq("content_hash", hash)
    .gte("created_at", sinceIso(windowSeconds));
  if (error) throw error;
  const rows = data ?? [];
  return {
    sameDevice: rows.some((r) => r.device_id === deviceId),
    totalInWindow: rows.length,
  };
}

export async function countRecentReports(
  db: Db,
  reporterDeviceId: string,
  windowSeconds: number,
): Promise<number> {
  const { count, error } = await db
    .from("forum_reports")
    .select("id", { count: "exact", head: true })
    .eq("reporter_device_id", reporterDeviceId)
    .gte("created_at", sinceIso(windowSeconds));
  if (error) throw error;
  return count ?? 0;
}
