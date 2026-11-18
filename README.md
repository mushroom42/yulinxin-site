# yulinxin-site

Personal website of Yulin Xin (辛禹林), full-stack engineer in Paris.
Single static page in 中文 / English / Français, no build step.

## Structure

```
site/                    what gets deployed
  index.html             the page (CSS and JS inline)
  favicon.svg
  og.jpg                 social preview image
infra/s3-cloudfront/     phase 2: S3 + CloudFront + ACM + Route 53 + GitHub OIDC role
infra/amplify/           phase 1: AWS Amplify Hosting (kept until phase 2 is live)
scripts/deploy-s3.sh     upload + invalidate (used by CI, also runs locally)
scripts/deploy-amplify.sh
.github/workflows/deploy.yml
```

`index.html` contains the placeholder `__SITE_URL__` (canonical, hreflang, Open Graph).
The deploy script replaces it with the real URL; the file in the repo keeps the placeholder.

Language is chosen in this order: `?lang=zh|en|fr` in the URL, the visitor's last choice, then the browser language (Chinese browsers get Chinese, everyone else French). Without JavaScript the page shows French.

The downloadable CV (`site/cv/Yulin_XIN_CV_FR.pdf`) is built from `cv/cv-fr.html`, a public copy with no phone number, email or address:

```sh
SITE_URL=https://yulinxin.dev ./scripts/build-cv.sh
```

## Deploy (phase 2: S3 + CloudFront at yulinxin.dev)

```
GitHub push to main ──OIDC──▶ IAM role (upload + invalidate only)
                                   │
browser ──▶ CloudFront (TLS from ACM, security headers, www → apex) ──OAC──▶ private S3 bucket
             ▲
Cloudflare DNS (DNS only, not proxied): CNAME @ and www → CloudFront
```

The domain is registered at Cloudflare Registrar, which requires Cloudflare's nameservers, so DNS stays on Cloudflare and the records are added there by hand. (With a Route 53 hosted zone, pass `HostedZoneId=...` and the stack validates the certificate and creates the records itself.) One stack, in `us-east-1` because CloudFront only takes ACM certificates from there:

```sh
aws cloudformation deploy --region us-east-1 \
  --stack-name yulinxin-site-cdn \
  --template-file infra/s3-cloudfront/template.yaml \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides DomainName=yulinxin.dev
```

While it waits on the certificate, add its two validation CNAMEs in Cloudflare (DNS only, keep them for renewals):

```sh
ARN=$(aws acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[?DomainName=='yulinxin.dev'].CertificateArn | [0]" --output text)
aws acm describe-certificate --region us-east-1 --certificate-arn "$ARN" \
  --query "Certificate.DomainValidationOptions[].ResourceRecord" --output table
```

When the stack is done, point the domain at the `DistributionDomain` output in Cloudflare: CNAME `@` and CNAME `www`, both DNS only (grey cloud). CloudFront is the CDN; proxying through Cloudflare as well would put two CDNs and two TLS hops in front of the site.

Then copy the stack outputs into repository variables (Settings → Secrets and variables → Actions → Variables): `AWS_DEPLOY_ROLE_ARN`, `S3_BUCKET`, `CF_DISTRIBUTION_ID`, `SITE_URL`. Every push to `main` that touches `site/` deploys. No AWS keys are stored in GitHub: the workflow gets one-hour credentials through OIDC, and the role only trusts the `main` branch of this repository.

## Deploy (phase 1: Amplify Hosting)

Requires the AWS CLI. Deploys use the `site-deploy` profile, which assumes the `siteDeploy` role from the `yulin` profile; if the session has expired, run `aws login --profile yulin` first.

```sh
# once: create the Amplify app and branch
aws cloudformation deploy \
  --stack-name yulinxin-site-amplify \
  --template-file infra/amplify/template.yaml

# every release
AWS_PROFILE=site-deploy ./scripts/deploy-amplify.sh
```

The site is served at the `SiteUrl` output (`https://main.<id>.amplifyapp.com`).

## Roadmap

- Retire the Amplify app once yulinxin.dev is live.

## Preview locally

Open `site/index.html` in a browser. The `__SITE_URL__` placeholders only affect metadata.

---

© 2026 Yulin Xin. The text and images on the site are not licensed for reuse.
