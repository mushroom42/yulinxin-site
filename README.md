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

Language is chosen in this order: `?lang=zh|en|fr` in the URL, the visitor's last choice, then the browser language.

## Deploy (phase 1: Amplify Hosting)

Requires the AWS CLI with a profile for the personal account.

```sh
# once: create the Amplify app and branch
aws cloudformation deploy \
  --stack-name yulinxin-site-amplify \
  --template-file infra/amplify/template.yaml

# every release
./scripts/deploy-amplify.sh
```

The site is served at the `SiteUrl` output (`https://main.<id>.amplifyapp.com`).

## Roadmap

- Phase 2: S3 (private) + CloudFront (OAC) + ACM + Route 53, deployed by GitHub Actions through OIDC, all defined as code.
- Own domain.

## Preview locally

Open `site/index.html` in a browser. The `__SITE_URL__` placeholders only affect metadata.

---

© 2026 Yulin Xin. The text and images on the site are not licensed for reuse.
