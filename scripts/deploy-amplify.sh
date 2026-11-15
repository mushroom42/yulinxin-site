#!/usr/bin/env bash
# Deploy site/ to the Amplify app created by infra/amplify/template.yaml.
#
#   AWS_PROFILE=site-deploy ./scripts/deploy-amplify.sh
#
# Steps: read stack outputs -> fill __SITE_URL__ -> zip -> create-deployment
#        -> upload zip -> start-deployment -> wait for the job.
set -euo pipefail

STACK_NAME="${STACK_NAME:-yulinxin-site-amplify}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

output() {
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

APP_ID="$(output AppId)"
BRANCH="$(output BranchName)"
SITE_URL="${SITE_URL:-$(output SiteUrl)}"
SITE_URL="${SITE_URL%/}"
echo "App ${APP_ID} · branch ${BRANCH} · ${SITE_URL}"

BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
mkdir -p "$BUILD/out"
cp -R "$ROOT/site/." "$BUILD/out/"
sed -i.bak "s#__SITE_URL__#${SITE_URL}#g" "$BUILD/out/index.html" && rm "$BUILD/out/index.html.bak"
if grep -q "__SITE_URL__" "$BUILD/out/index.html"; then
  echo "error: __SITE_URL__ placeholder still present" >&2; exit 1
fi
(cd "$BUILD/out" && zip -qr "$BUILD/site.zip" .)

read -r JOB_ID UPLOAD_URL < <(aws amplify create-deployment --app-id "$APP_ID" --branch-name "$BRANCH" \
  --query '[jobId, zipUploadUrl]' --output text)
curl -fsS -X PUT -H "Content-Type: application/zip" --upload-file "$BUILD/site.zip" "$UPLOAD_URL"
aws amplify start-deployment --app-id "$APP_ID" --branch-name "$BRANCH" --job-id "$JOB_ID" >/dev/null
echo "Started job ${JOB_ID}"

for _ in $(seq 1 60); do
  STATUS="$(aws amplify get-job --app-id "$APP_ID" --branch-name "$BRANCH" --job-id "$JOB_ID" \
    --query 'job.summary.status' --output text)"
  case "$STATUS" in
    SUCCEED) echo "Deployed: ${SITE_URL}"; exit 0 ;;
    FAILED|CANCELLED) echo "Deployment ${STATUS}" >&2; exit 1 ;;
  esac
  sleep 5
done
echo "Timed out waiting for job ${JOB_ID}" >&2
exit 1
