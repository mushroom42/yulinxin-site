#!/usr/bin/env bash
# Upload site/ to the S3 bucket behind CloudFront and invalidate the cache.
# Used by .github/workflows/deploy.yml; also works locally:
#
#   AWS_PROFILE=... ./scripts/deploy-s3.sh            # reads the stack outputs
#   S3_BUCKET=... CF_DISTRIBUTION_ID=... SITE_URL=... ./scripts/deploy-s3.sh
set -euo pipefail

STACK_NAME="${STACK_NAME:-yulinxin-site-cdn}"
STACK_REGION="${STACK_REGION:-us-east-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

output() {
  aws cloudformation describe-stacks --region "$STACK_REGION" --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

S3_BUCKET="${S3_BUCKET:-$(output BucketName)}"
CF_DISTRIBUTION_ID="${CF_DISTRIBUTION_ID:-$(output DistributionId)}"
SITE_URL="${SITE_URL:-$(output SiteUrl)}"
SITE_URL="${SITE_URL%/}"
echo "Bucket ${S3_BUCKET} · distribution ${CF_DISTRIBUTION_ID} · ${SITE_URL}"

BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
cp -R "$ROOT/site/." "$BUILD/"
sed -i.bak "s#__SITE_URL__#${SITE_URL}#g" "$BUILD/index.html" && rm "$BUILD/index.html.bak"
if grep -q "__SITE_URL__" "$BUILD/index.html"; then
  echo "error: __SITE_URL__ placeholder still present" >&2; exit 1
fi
find "$BUILD" -name '.DS_Store' -delete

# Assets: cache for a day. index.html: five minutes, so text edits show up quickly.
aws s3 sync "$BUILD" "s3://${S3_BUCKET}" --delete --only-show-errors \
  --exclude index.html --cache-control "public, max-age=86400"
aws s3 cp "$BUILD/index.html" "s3://${S3_BUCKET}/index.html" --only-show-errors \
  --content-type "text/html; charset=utf-8" --cache-control "public, max-age=300"

INV="$(aws cloudfront create-invalidation --distribution-id "$CF_DISTRIBUTION_ID" \
  --paths '/*' --query Invalidation.Id --output text)"
echo "Invalidation ${INV} started"
echo "Deployed: ${SITE_URL}"
