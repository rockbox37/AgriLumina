// Listings write API (issue #24). All mutations flow through here (service
// role) so the anonymous device_id acts as an owner secret; public reads go
// through the list_listings RPC, which never exposes phone or device ids.
//
//   POST   /listings/upsert        {device_id, role, name, crop, quantity_hint,
//                                   lat, lon, location_text, tagline, phone}
//   DELETE /listings/:role         {device_id}
//   POST   /listings/contact       {device_id, listing_id}

import { corsHeaders, json } from "../_shared/cors.ts";
import { cleanText, isUuid } from "../_shared/validation.ts";
import { Db, isBannedDevice, serviceClient } from "../_shared/db.ts";

/** Contact fetches allowed per device per 24h (anti-scraping). */
const CONTACT_DAILY_LIMIT = 30;

const ROLES = ["seller", "buyer"] as const;
type Role = (typeof ROLES)[number];

function isRole(value: unknown): value is Role {
  return typeof value === "string" && ROLES.includes(value as Role);
}

async function readJson(req: Request): Promise<Record<string, unknown> | null> {
  try {
    const body = await req.json();
    return typeof body === "object" && body !== null ? body : null;
  } catch {
    return null;
  }
}

interface UpsertInput {
  deviceId: string;
  role: Role;
  name: string;
  crop: string;
  quantityHint: string;
  lat: number;
  lon: number;
  locationText: string;
  tagline: string;
  phone: string;
}

function parseUpsert(
  raw: Record<string, unknown>,
): { ok: true; value: UpsertInput } | { ok: false; error: string } {
  if (!isUuid(raw.device_id)) return { ok: false, error: "invalid_device_id" };
  if (!isRole(raw.role)) return { ok: false, error: "invalid_role" };
  const text = (v: unknown) => typeof v === "string" ? cleanText(v) : null;
  const name = text(raw.name);
  const crop = text(raw.crop);
  const quantityHint = text(raw.quantity_hint) ?? "";
  const locationText = text(raw.location_text) ?? "";
  const tagline = text(raw.tagline) ?? "";
  const phone = text(raw.phone);
  const lat = typeof raw.lat === "number" && Number.isFinite(raw.lat)
    ? raw.lat
    : null;
  const lon = typeof raw.lon === "number" && Number.isFinite(raw.lon)
    ? raw.lon
    : null;
  if (!name || name.length > 40) return { ok: false, error: "invalid_name" };
  if (!crop || crop.length > 40) return { ok: false, error: "invalid_crop" };
  if (quantityHint.length > 120) {
    return { ok: false, error: "invalid_quantity_hint" };
  }
  if (locationText.length > 80) return { ok: false, error: "invalid_location" };
  if (tagline.length > 100) return { ok: false, error: "invalid_tagline" };
  if (!phone || phone.length < 5 || phone.length > 25) {
    return { ok: false, error: "invalid_phone" };
  }
  if (lat === null || lat < -90 || lat > 90) {
    return { ok: false, error: "invalid_lat" };
  }
  if (lon === null || lon < -180 || lon > 180) {
    return { ok: false, error: "invalid_lon" };
  }
  return {
    ok: true,
    value: {
      deviceId: (raw.device_id as string).toLowerCase(),
      role: raw.role as Role,
      name,
      crop,
      quantityHint,
      lat,
      lon,
      locationText,
      tagline,
      phone,
    },
  };
}

async function upsertListing(db: Db, req: Request): Promise<Response> {
  const raw = await readJson(req);
  if (!raw) return json({ error: "invalid_json" }, 400);
  const parsed = parseUpsert(raw);
  if (!parsed.ok) return json({ error: parsed.error }, 400);
  const input = parsed.value;

  if (await isBannedDevice(db, input.deviceId)) {
    return json({ error: "forbidden" }, 403);
  }

  const { data, error } = await db
    .from("listings")
    .upsert(
      {
        owner_device_id: input.deviceId,
        role: input.role,
        name: input.name,
        crop: input.crop,
        quantity_hint: input.quantityHint,
        lat: input.lat,
        lon: input.lon,
        location_text: input.locationText,
        tagline: input.tagline,
        phone: input.phone,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "owner_device_id,role" },
    )
    .select("id, updated_at")
    .single();
  if (error) throw error;
  return json({ id: data.id, updated_at: data.updated_at });
}

async function deleteListing(
  db: Db,
  req: Request,
  role: Role,
): Promise<Response> {
  const raw = await readJson(req);
  if (!raw) return json({ error: "invalid_json" }, 400);
  if (!isUuid(raw.device_id)) return json({ error: "invalid_device_id" }, 400);

  const { error } = await db
    .from("listings")
    .delete()
    .eq("owner_device_id", (raw.device_id as string).toLowerCase())
    .eq("role", role);
  if (error) throw error;
  // Idempotent: deleting a non-existent listing is a success.
  return json({ ok: true });
}

async function fetchContact(db: Db, req: Request): Promise<Response> {
  const raw = await readJson(req);
  if (!raw) return json({ error: "invalid_json" }, 400);
  if (!isUuid(raw.device_id)) return json({ error: "invalid_device_id" }, 400);
  if (!isUuid(raw.listing_id)) return json({ error: "invalid_listing_id" }, 400);
  const deviceId = (raw.device_id as string).toLowerCase();
  const listingId = (raw.listing_id as string).toLowerCase();

  if (await isBannedDevice(db, deviceId)) {
    return json({ error: "forbidden" }, 403);
  }

  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { count, error: countError } = await db
    .from("contact_unlocks")
    .select("id", { count: "exact", head: true })
    .eq("requester_device_id", deviceId)
    .gte("created_at", since);
  if (countError) throw countError;
  if ((count ?? 0) >= CONTACT_DAILY_LIMIT) {
    return json({ error: "rate_limited" }, 429);
  }

  const { data: listing, error } = await db
    .from("listings")
    .select("id, phone")
    .eq("id", listingId)
    .maybeSingle();
  if (error) throw error;
  if (!listing) return json({ error: "not_found" }, 404);

  const { error: logError } = await db
    .from("contact_unlocks")
    .insert({ listing_id: listingId, requester_device_id: deviceId });
  if (logError) throw logError;

  return json({ phone: listing.phone });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const segments = new URL(req.url).pathname.split("/").filter(Boolean);
  const route = segments.slice(1); // drop the "listings" prefix

  try {
    const db = serviceClient();
    if (req.method === "POST" && route.length === 1 && route[0] === "upsert") {
      return await upsertListing(db, req);
    }
    if (req.method === "POST" && route.length === 1 && route[0] === "contact") {
      return await fetchContact(db, req);
    }
    if (req.method === "DELETE" && route.length === 1 && isRole(route[0])) {
      return await deleteListing(db, req, route[0]);
    }
    return json({ error: "not_found" }, 404);
  } catch (error) {
    console.error("listings function error:", error);
    return json({ error: "internal" }, 500);
  }
});
