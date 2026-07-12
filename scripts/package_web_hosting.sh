#!/usr/bin/env bash
# Build Flutter web under /app and use home.html as the site root (landing page).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_OUT="$ROOT/build/web"
APP_OUT="$WEB_OUT/app"

cd "$ROOT"
flutter pub get
flutter build web --release --base-href=/app/

rm -rf "$APP_OUT"
mkdir -p "$APP_OUT"

for f in main.dart.js flutter.js flutter_bootstrap.js flutter_service_worker.js version.json; do
  mv "$WEB_OUT/$f" "$APP_OUT/"
done

mv "$WEB_OUT/assets" "$APP_OUT/"
mv "$WEB_OUT/canvaskit" "$APP_OUT/"
mv "$WEB_OUT/index.html" "$APP_OUT/index.html"
mv "$WEB_OUT/manifest.json" "$APP_OUT/manifest.json"

cp -R "$ROOT/web/icons" "$APP_OUT/icons"
cp "$ROOT/web/favicon.png" "$APP_OUT/favicon.png"

cp "$ROOT/web/home.html" "$WEB_OUT/index.html"
cp -R "$ROOT/web/js" "$WEB_OUT/js"
cp -R "$ROOT/web/css" "$WEB_OUT/css"
cp "$ROOT/web/privacy.html" "$WEB_OUT/privacy.html"
cp "$ROOT/web/terms.html" "$WEB_OUT/terms.html"

echo "Packaged landing page at / and Flutter app at /app/"
