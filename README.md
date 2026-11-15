# yulinxin-site

Personal website of Yulin Xin (辛禹林), full-stack engineer in Paris.
Single static page in 中文 / English / Français, no build step.

## Structure

```
site/                    what gets deployed
  index.html             the page (CSS and JS inline)
  favicon.svg
  og.jpg                 social preview image
infra/amplify/           phase 1: AWS Amplify Hosting (CloudFormation)
scripts/deploy-amplify.sh
```

`index.html` contains the placeholder `__SITE_URL__` (canonical, hreflang, Open Graph).
The deploy script replaces it with the real URL; the file in the repo keeps the placeholder.

Language is chosen in this order: `?lang=zh|en|fr` in the URL, the visitor's last choice, then the browser language (Chinese browsers get Chinese, everyone else French). Without JavaScript the page shows French.

The downloadable CV (`site/cv/Yulin_XIN_CV_FR.pdf`) is built from `cv/cv-fr.html`, a public copy with no phone number, email or address:

```sh
SITE_URL=https://main.d1c1ojhjlmez2q.amplifyapp.com ./scripts/build-cv.sh
```

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

- Phase 2: S3 (private) + CloudFront (OAC) + ACM + Route 53, deployed by GitHub Actions through OIDC, all defined as code.
- Own domain.

## Preview locally

Open `site/index.html` in a browser. The `__SITE_URL__` placeholders only affect metadata.

---

© 2026 Yulin Xin. The text and images on the site are not licensed for reuse.
