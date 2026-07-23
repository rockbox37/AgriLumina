#!/bin/bash
# Builds the admin dashboard (Flutter web) and deploys it as the `admin-web`
# edge function on the hosted Supabase project. The build output is a deploy
# artifact only — supabase/functions/admin-web/dist is gitignored.
#
# Dashboard URL after deploy:
#   https://lpjkqqgiicswproumynn.supabase.co/functions/v1/admin-web/
set -euo pipefail
cd "$(dirname "$0")/.."

# CanvasKit comes from Google's CDN instead of being bundled: the wasm
# variants are ~25MB, which would blow the edge-function bundle limit.
ENGINE_REV=$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["engineRevision"])')

flutter build web --release \
  --target lib/admin/main_admin.dart \
  --base-href "/functions/v1/admin-web/" \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL="https://www.gstatic.com/flutter-canvaskit/${ENGINE_REV}/" \
  --output supabase/functions/admin-web/dist

rm -rf supabase/functions/admin-web/dist/canvaskit

supabase functions deploy admin-web

# Supabase refuses to serve text/html on *.supabase.co (anti-phishing), so
# the entry point is a local launcher file: the same index.html with an
# absolute <base>, opened from disk. Everything else loads from the function.
sed 's|<base href="/functions/v1/admin-web/">|<base href="https://lpjkqqgiicswproumynn.supabase.co/functions/v1/admin-web/">|' \
  supabase/functions/admin-web/dist/index.html > admin-dashboard.local.html

echo
echo "Launcher written to admin-dashboard.local.html — open it in a browser."
