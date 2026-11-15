#!/usr/bin/env bash
# Render cv/cv-fr.html (public copy: no phone, email or address) to site/cv/Yulin_XIN_CV_FR.pdf.
#   SITE_URL=https://example.com ./scripts/build-cv.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE_URL="${SITE_URL:?set SITE_URL}"; SITE_URL="${SITE_URL%/}"
HOST="${SITE_URL#https://}"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
sed -e "s#__SITE_URL__#${SITE_URL}#g" -e "s#__SITE_HOST__#${HOST}#g" "$ROOT/cv/cv-fr.html" > "$TMP/cv.html"
mkdir -p "$ROOT/site/cv"
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$ROOT/site/cv/Yulin_XIN_CV_FR.pdf" "file://$TMP/cv.html" 2>/dev/null
echo "Wrote site/cv/Yulin_XIN_CV_FR.pdf"
