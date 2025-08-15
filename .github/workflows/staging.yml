name: Deploy to Staging

on:
  push:
    branches: [main]

jobs:
  # Reuse your shared CI (lint/test/build/push images)
  ci:
    uses: ./.github/workflows/reusable-ci.yml

  # Deploy to staging after CI succeeds
  deploy-staging:
    needs: ci
    runs-on: ubuntu-latest
    env:
      DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: true

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8

      - name: Verify pnpm
        run: |
          echo "PNPM path: $(which pnpm)"
          pnpm --version

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Install psql client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Git diagnostics
        run: |
          echo "[debug] Git configuration:"
          git --version
          git remote -v
          git branch -a
          echo "[debug] Fetching all refs:"
          git fetch --no-tags --prune origin +refs/heads/*:refs/remotes/origin/*
          echo "[debug] Commit verification:"
          git show -s --oneline HEAD || echo "HEAD missing"
          git show -s --oneline origin/main || echo "origin/main missing"

      - name: Debug env and changed services
        run: |
          echo "Environment checks:"
          echo "STAGING_DB_URL set? $([[ -n "${STAGING_DB_URL:-}" ]] && echo yes || echo no)"
          echo "FLY_API_TOKEN set? $([[ -n "${FLY_API_TOKEN:-}" ]] && echo yes || echo no)"
          echo "GITHUB_BASE_REF=${GITHUB_BASE_REF:-}"
          echo "Branch=${GITHUB_REF_NAME}"
          
          echo "Computing changed services..."
          CHANGED_SERVICES=$(bash scripts/changed_services.sh "${GITHUB_BASE_REF:-$DEFAULT_BRANCH}")
          echo "$CHANGED_SERVICES" | tee /tmp/changed.txt
          echo "---- CHANGED SERVICES ----"
          cat /tmp/changed.txt || true
          echo "--------------------------"
        env:
          STAGING_DB_URL: ${{ secrets.STAGING_DB_URL }}
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

      - name: Check DB connectivity
        env:
          STAGING_DB_URL: ${{ secrets.STAGING_DB_URL }}
        run: |
          echo "[preflight] Testing DB connection..."
          psql "$STAGING_DB_URL" -Atc "select 'db_ok'" || { 
            echo "::error::DB connection failed. Check STAGING_DB_URL format.";
            exit 1;
          }

      - name: Run migrations
        env:
          STAGING_DB_URL: ${{ secrets.STAGING_DB_URL }}
        run: bash scripts/migrate_expand.sh "$STAGING_DB_URL"

      - name: Deploy changed services to staging
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
        run: |
          echo "Starting deployment..."
          bash -x scripts/deploy_changed_services.sh "staging" "staging"

      - name: Smoke tests
        run: bash scripts/smoke_tests.sh
