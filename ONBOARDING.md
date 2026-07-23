# AgriLumina — Onboarding & Handoff

Agri marketplace MVP for rural DRC (Bugobe pilot context): sellers and buyers
find each other nearby, spend credits to unlock phone numbers, and talk on a
community forum. Phone-first, offline-tolerant, en/fr localized. See
`PRODUCT_BRIEF.md` for product intent.

## Current state (as of 2026-07-23)

Everything below is **merged to main and live on the hosted backend**. The
issue tracker is empty; there are no open PRs.

- **Flutter app** (`lib/`): Home · Discover · Forum · Credits · Profile.
  Listings sync to the backend keyed by an anonymous `device_id`; Discover
  shows real remote counterparts (30-day expiry, per-role offline cache,
  seed mocks only as last resort); contact unlock spends a local credit only
  after the server returns the phone. Forum has spam-filtered posting,
  replies, and report-spam. **All writes are offline-safe**: listings have a
  per-role sync queue, the forum has a FIFO outbox, and a connectivity
  listener flushes both on reconnect. All HTTP has timeouts (hangs degrade
  like offline).
- **Backend** (`supabase/`): Postgres + edge functions on hosted project
  `agrilumina` (ref `lpjkqqgiicswproumynn`, **rockbox37's Org — never the
  deft account**, region eu-west-3). Tables are RLS-closed to the API;
  public reads go through views/RPCs that never leak phones or device ids;
  all writes go through edge functions (`forum`, `listings`) where anti-spam
  and validation run. Layered forum anti-spam: rate limits, content-hash
  dedupe, heuristics + editable blocklist, auto-hide at 3 reports.
- **Admin** (`lib/admin/`, Flutter web): Supabase Auth login (signups
  disabled; admins = rows in the service-role-only `admin_users` table).
  Panes: Overview stats, Posts moderation queue, Listings (god-mode incl.
  phone/device id, expired flag, delete/ban), Blocklist, Bans, Alerts (six
  tunable trigger-generated rules).

## Run / develop

- App (web): `flutter run -d web-server --web-port 8087` or launch config
  `agrilumina-web` (`.claude/launch.json`).
- Admin dashboard (dev): launch config `agrilumina-admin` (port 8088,
  target `lib/admin/main_admin.dart`).
- Admin dashboard (real): open `admin-dashboard.local.html` from disk —
  regenerate + redeploy with `scripts/deploy-admin.sh`. Supabase refuses to
  serve HTML on `*.supabase.co` (anti-phishing), hence the launcher-file
  approach; assets come from the `admin-web` edge function.
- Local backend: `supabase start` / `supabase db reset` (Docker). Ports are
  shifted to **553xx** because another project holds the defaults on this
  machine. `supabase functions serve` for edge functions.
- Tests: `flutter analyze && flutter test` (163 tests). Edge-function unit
  tests: `deno test --allow-all supabase/functions/tests/`.
- Deploy backend: `supabase db push` (+ `supabase functions deploy <name>`,
  `supabase config push` for auth/api config).

## Credentials (all gitignored `.local` files, never in git)

- `supabase/.db-password.local` — hosted Postgres password (resettable in
  the Supabase dashboard).
- `supabase/.admin-credentials.local` — platform-admin login
  (dgeorge@deft.co). **Still the bootstrap value: change it after first
  login** (Supabase dashboard → Authentication → Users).
- The anon key in `lib/services/forum_api.dart` is a public client
  credential by design; enforcement is server-side.

## Gotchas learned the hard way

- `[auth.email] enable_signup = false` kills email **logins**, not just
  signups — use the global `[auth] enable_signup = false` only.
- Serve unversioned Flutter web artifacts with `no-cache`: Cloudflare fronts
  supabase.co and will cache `max-age` responses across deploys.
- Cross-origin `<base href>` makes Flutter's `history.replaceState` throw in
  a loop — the admin entrypoint disables URL history (conditional import in
  `lib/admin/url_strategy_*.dart`).
- CanvasKit is ~25MB if bundled; the admin build pulls it from Google's CDN
  to fit edge-function limits.
- Squash merges are the repo convention; SLizard reviews PRs (P0–P3
  findings; label false positives with `@slizard label <fp> fp <reason>`).

## Roadmap (agreed, not started)

1. **Pilot device builds** — Android release + internal distribution so real
   users can install; forces real-device GPS/offline/fr testing.
2. **Server-side credit ledger** — credits are currently on-device only;
   clearing app data resets them (bounded only by the 30/day contact rate
   limit). Prerequisite for real mobile-money payments.
3. **External hosting for the admin dashboard** — owner plans to take the
   repo private; a static host (Netlify/Cloudflare, owner's account) can
   replace the launcher file later.
4. Smaller: connectivity-listener already exists; consider listings alert
   coverage growth, pg_cron purge of ancient rows if volume ever matters.

## Repo oddities

- `ios/Podfile.lock` and platform plugin registrant files show as dirty on
  this machine (plugin adds regenerate them); intentionally uncommitted.
- `supabase/functions/admin-web/dist/` and `admin-dashboard.local.html` are
  build artifacts (gitignored), produced by `scripts/deploy-admin.sh`.
