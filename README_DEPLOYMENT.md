# Deployment & CI/CD Blueprint

This bundle contains ready-to-use GitHub Actions, Terraform stubs, SQL migrations, and scripts to deploy your 8 macro-services with preview/staging/prod pipelines.

## What’s inside
- **.github/workflows/**: PR previews, staging auto-deploy, prod canary with promotion, reusable CI.
- **infrastructure/terraform/**: Fly.io app stubs + Redpanda topics module.
- **db/migrations/**: Outbox and Domain Events tables (expand stage).
- **packages/shared-events/**: Example JSON Schema for `job.status_changed v1`.
- **scripts/**: Deploy, migrate, build/push images, checks, contract guard.

## Secrets required (GitHub → Settings → Secrets and variables → Actions)
- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_WEB_PROJECT_ID` (if using Vercel for web-portal)
- `FLY_API_TOKEN` (Fly.io deploy)
- `STAGING_DB_URL`, `PROD_DB_URL` (Postgres URLs)
- `ACTIONS_DEPLOY_KEY` (optional, for private registries)

## Usage
- Open a PR → CI runs + Preview deploys.
- Merge to `main` → staging deploy + expand migrations + smoke tests.
- Tag `vX.Y.Z` → prod canary + post-deploy checks → promotion on success.

> Replace `ORG` in templates with your GH org/user. Update regions, ports, and images to match your services.
# Triggered deployment on $(date)).
