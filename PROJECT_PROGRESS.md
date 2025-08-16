# 🚀 Project Progress Log

This file is a running "memory" of our setup process. Update it each time we make changes so we never lose track, even if the chat resets.

---

## ✅ Current Repo Layout
- **apps/**  
  - `api-gateway/`  
  - `assets-warranty/`  
  - `billing-payments/`  
  - `communications-audit/`  
  - `customer-property/`  
  - `identity-access/`  
  - `inventory-parts/`  
  - `technicians-dispatch/`  
  - `web-portal/`  

- **scripts/**  
  - `pnpm_ensure.sh`  
  - `deploy_changed_services.sh`  
  - `changed_services.sh`  
  - `build_and_push_images.sh`  
  - `migrate_expand.sh`  

- **.github/workflows/**  
  - `pr.yml` → Pull request CI/CD (preview deploys)  
  - `staging.yml` → Staging deploy workflow  
  - `reusable-ci.yml` → Shared CI steps

---

## 🔧 CI/CD Setup
- **pnpm problem**: Runner was not finding `pnpm`. Fixed by:
  - Adding `pnpm/action-setup@v4`
  - Adding `scripts/pnpm_ensure.sh`
  - Verifying with `pnpm -v`  

- **Dockerfiles**: Only `api-gateway` had one. Added templates for other services (to be replaced with real app code later).

- **Workflows**:  
  - `pr.yml` runs CI + preview deploy (Fly + Vercel)  
  - `staging.yml` runs migrations + staging deploy  

---

## ⚠️ Known Issues
1. **DB URL format**  
   - Wrong format was causing errors:  
     ```
     could not translate host name "username@db.xxx.supabase.co"
     ```
   - Correct format:  
     ```
     postgresql://postgres:[PASSWORD]@db.liroeqeiykaewyfujfli.supabase.co:5432/postgres
     ```
   - Needs secrets updated with proper URL (`STAGING_DB_URL`).

2. **Git merge base error**  


→ Cause: workflows comparing against `origin/main` but missing remote refs in CI.  
→ Fix pending: add `fetch-depth: 0` in checkout.

3. **Staging workflow validation**  
- Initially failed due to missing `jobs:` or `on:` definitions.  
- Fixed by restructuring staging.yml.

---

## 🎯 Next Steps
1. Fix **`STAGING_DB_URL` secret** with proper password & encoding.  
2. Add minimal Dockerfiles for all services (if not already).  
3. Verify staging workflow with `fetch-depth: 0`.  
4. Once staging passes, add health checks & PR summary links.  
5. Begin coding service logic into apps/ (replacing placeholders).

---

## 📝 Notes
- We can defer DB migration issues until after app scaffold is stable.  
- Everything is structured for **CI/CD-first development** (infra before code).  
- This log will keep us aligned across multiple chats.

---

