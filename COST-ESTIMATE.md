# AgriLumina — Infrastructure Cost Estimate

**Currency:** USD  
**As of:** July 2026  
**Nature of numbers:** Order-of-magnitude planning estimates, not vendor quotes. Re-check [Supabase pricing](https://supabase.com/pricing) when you change plans or add services.

Related epic (find-each-other sync):

- [#24 Backend: listings table + upsert/delete/list + contact endpoint](https://github.com/rockbox37/AgriLumina/issues/24)
- [#25 Flutter: device_id + publish/clear sync to remote listings](https://github.com/rockbox37/AgriLumina/issues/25)
- [#26 Flutter: Discover remote fetch + unlock fetches contact phone](https://github.com/rockbox37/AgriLumina/issues/26)

---

## Purpose

Track expected **backend / infra** spend as AgriLumina moves from local-only MVP toward shared listings sync. Keep this file honest and short: update when a service is added, a free-tier limit is hit, or a new bill appears.

**Product context (cost-relevant):** usable anywhere; intermittent rural networks; Bugobe is seed geography only. V1 stack default: **Supabase** (Postgres + REST + anon key). Out of v1: auth OTP, payments, realtime, chat, server credits, push.

---

## How to update this doc

1. When you add a service, fill its stub row (replace `$TBD` / `N/A`) and bump **As of**.
2. When a scenario changes (pilot size, image uploads, paid plan), edit the scenario table and note why in **Notes / changelog**.
3. Prefer measured usage (Supabase dashboard) over guesses once the project is live.
4. Do not treat Free as “production forever” — pausing and egress caps matter for a user-facing app.

---

## Current state (local-only)

| Item | Monthly | Notes |
|------|--------:|-------|
| Backend / hosted DB | **~$0** | No remote sync yet; Flutter app runs against local/mock data |
| Auth / Storage / Push / Maps / Payments | **$0** | Not in use |
| **Total** | **~$0** | |

---

## Planned v1 — Supabase (Free vs paid)

Assumptions for v1: one Supabase project; listings + contact via REST; no Auth OTP, Realtime, Storage images, or Edge Workers in the first sync slice. Limits below are Free-tier ballparks as of July 2026 — confirm on the pricing page before planning spend.

### Free tier (typical ceiling)

| Resource | Free (approx.) | When cost / friction kicks in |
|----------|----------------|-------------------------------|
| API requests | Unlimited (fair use) | Rarely the bill driver; watch egress and DB size instead |
| Database size | ~500 MB / project | Writes can fail past quota → Pro (~8 GB included, then ~$0.125/GB) |
| Egress (uncached) | ~5 GB / month | Overages or need for room → Pro (~250 GB included, then ~$0.09/GB) |
| Cached egress | ~5 GB / month | Same story if CDN/storage traffic grows |
| File storage | ~1 GB | Not needed for lean v1 text listings; blocks uploads if used later |
| Auth MAU | ~50k | N/A for v1 (no Auth OTP); relevant if Auth is added later |
| Active projects | 2 | Extra projects → paid org / Pro |
| Inactivity pause | ~1 week with no traffic | Free projects pause — awkward for any real pilot; Pro does not pause |
| Backups / SLA | None / community | Pro adds daily backups (short retention) |

### Paid threshold (order of magnitude)

| Plan | Ballpark | Why you might move |
|------|----------|--------------------|
| Free | **$0 / mo** | Solo demo, 2-device test, short experiments |
| Pro (org + compute) | **~$25–35 / mo** starting | Avoid pause, need backups, or outgrow 500 MB / 5 GB egress. Exact total depends on compute credits and add-ons — check current Pro packaging. |

Lean v1 (rows of listings + light Discover polling) should fit **Free** for demo and early pilot **if** traffic stays light and someone resumes a paused project. A standing pilot that must stay up 24/7 is the usual reason to budget Pro.

---

## Scenarios

| Scenario | Users / traffic (rough) | Likely plan | Monthly (USD) | Comment |
|----------|-------------------------|-------------|----------------:|---------|
| Solo demo / 2-device test | 1–2 devices, occasional sync | Free | **~$0** | Watch project pause after idle weeks |
| Small pilot | ~50–200 users, light Discover + publish | Free if always-on not required; else Pro | **~$0** or **~$25–35** | Text listings + contact unlocks; no images |
| Growth caution line | Hundreds+ MAU, frequent geo/list fetches, or media | Pro + watch overages | **$35+** (open-ended) | Egress, row growth, and scrape-like clients drive this — not API “request count” alone |

These are planning bands, not quotes.

---

## Cost drivers to watch

- **List / Discover scrape patterns** — clients that refetch large result sets often burn egress and DB IO.
- **Contact unlock traffic** — fine at pilot scale; abusive bulk unlock/scrape needs rate limits (product + backend), not just more budget.
- **Geo / nearby queries** — naive full-table scans grow with row count; index and bound radius early.
- **Row growth** — listings, unlocks, device IDs; prune stale rows so you stay under Free DB size.
- **Egress** — biggest Free cliff for chatty mobile clients on flaky networks (retries). Prefer compact payloads and caching.
- **Free project pause** — operational cost (downtime), not a line item, but it ends Free as a “set and forget” host.

---

## Future line items (stubs)

Fill in when the feature is actually added. Until then: `$TBD` or `N/A`.

| Service | In v1? | Est. monthly | One-time / annual | Notes |
|---------|--------|-------------:|-------------------|-------|
| Supabase Auth (OTP / phone) | No | `$TBD` | — | Free includes large MAU; SMS/OTP provider fees are separate |
| Supabase Realtime | No | `$TBD` | — | Connection + message quotas; not needed for poll-based Discover |
| Storage / listing images | No | `$TBD` | — | Free ~1 GB; images dominate egress if enabled |
| Push (FCM) | No | `N/A` → `$TBD` | — | FCM itself usually $0; infra/ops time still real |
| Maps (SDK / tiles) | No | `$TBD` | — | Vendor free tiers then per-request; keep out of first sync |
| Payments | No | `$TBD` | — | Processor fees % + fixed; credits stay client/stub in v1 |
| Custom Workers / Edge Functions | No | `$TBD` | — | Free invocation quota exists; only budget when you ship them |
| Custom domain / DNS | Optional | `$TBD` | domain ~$10–20/yr typical | App can ship without a marketing domain |
| Apple Developer Program | Store distribute | — | **~$99 / yr** | Needed for App Store, not for local MVP |
| Google Play developer | Store distribute | — | **~$25 one-time** | Needed for Play Store, not for local MVP |

---

## Notes / changelog

| Date | Change |
|------|--------|
| 2026-07-18 | Initial living estimate for sync epic (#24–#26); local-only ≈ $0; v1 Supabase Free vs Pro thresholds sketched. |

