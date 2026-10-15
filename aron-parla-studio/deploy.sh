#!/usr/bin/env bash
# ARON PARLA STUDIO deploy — same pattern as farfield/deploy.sh: stage a clean copy
# and deploy with cwd = the staged folder, because the Netlify CLI treats its cwd
# as the project base (deploying from the repo root bakes the ROOT _headers —
# old tailwind CSP, no Turnstile — over aron-parla-studio/_headers).
# The repo copy always keeps the literal __TOKENS__; substitution happens on the stage.
#
# The form is provisioned (Parla prod), so every deploy must pass the values:
#   SUPABASE_URL=... FORM_KEY=... TURNSTILE_SITE_KEY=... bash aron-parla-studio/deploy.sh
# A deploy without them would put the literal __TOKENS__ back on the live form;
# set ALLOW_PLACEHOLDERS=1 only if that is really what you want.
set -euo pipefail

if [[ -z "${SUPABASE_URL:-}" && "${ALLOW_PLACEHOLDERS:-}" != "1" ]]; then
  echo "refusing to deploy: SUPABASE_URL/FORM_KEY/TURNSTILE_SITE_KEY not set (would break the live form)" >&2
  exit 1
fi

SITE_ID="c80e8600-d226-46ec-b8a5-9a8d1f9db797"
SRC="$(cd "$(dirname "$0")" && pwd)"
STAGE="$(mktemp -d /tmp/aron-parla-studio-deploy.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT

rsync -a \
  --exclude 'README.md' \
  --exclude 'deploy.sh' \
  --exclude '.netlify' \
  --exclude '.DS_Store' \
  "$SRC/" "$STAGE/"

if [[ -n "${SUPABASE_URL:-}" ]]; then
  sed -i '' \
    -e "s|__SUPABASE_URL__|${SUPABASE_URL}|g" \
    -e "s|__FORM_KEY__|${FORM_KEY:?FORM_KEY required when SUPABASE_URL is set}|g" \
    -e "s|__TURNSTILE_SITE_KEY__|${TURNSTILE_SITE_KEY:?TURNSTILE_SITE_KEY required when SUPABASE_URL is set}|g" \
    "$STAGE/index.html"
  echo "form tokens substituted"
fi

cd "$STAGE"
netlify deploy --dir=. --prod --site="$SITE_ID"
