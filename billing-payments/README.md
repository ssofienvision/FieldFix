# billing-payments

Minimal service template with:
- Express HTTP server (`/health`, `/info`)
- OpenTelemetry (OTLP HTTP exporter)
- Dockerfile + Fly.io `fly.toml`

## Env Vars
- `PORT` (default 3000)
- `SERVICE_NAME` (default `billing-payments`)
- `OTEL_EXPORTER_OTLP_ENDPOINT` (default `http://localhost:4318/v1/traces`)
- `SERVICE_VERSION` (optional)

## Run locally
```bash
npm install
npm run dev
```
