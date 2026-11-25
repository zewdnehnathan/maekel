# Maekel

Addis Ababa super-app — Flutter client + Fastify microservices (identity, market, food, ride, chat, games, events) behind a gateway.

## New developers — start here

**[docs/local-dev-setup.md](docs/local-dev-setup.md)** — install prerequisites, run Postgres + all backend services, then Flutter (web / Android / desktop).

## Quick links

| Doc | Purpose |
|-----|---------|
| [docs/local-dev-setup.md](docs/local-dev-setup.md) | Local backend + frontend setup |
| [backend/README.md](backend/README.md) | Backend services, ports, smoke curls |
| [docs/architecture.md](docs/architecture.md) · [PDF](docs/architecture.pdf) | System architecture (as-built) |
| [docs/qa-test-phones-and-roles.md](docs/qa-test-phones-and-roles.md) | QA phones, OTP, Staff roles |
| [docs/qa-step-by-step-guide.md](docs/qa-step-by-step-guide.md) | Guided QA runbook |
| [docs/how-to-deploy.md](docs/how-to-deploy.md) | Deploy API + web + APK yourself |
| [docs/deploy-web-qa.md](docs/deploy-web-qa.md) | Cloudflare / GitHub Pages web deploy |
| [docs/deploy-demo-render-neon.md](docs/deploy-demo-render-neon.md) | Render + Neon cloud API |

## Mock login (local or QA)

1. Enter a **9-digit** local phone (e.g. `911234567`) — prefix `+251`
2. OTP: **`123456`**
3. Bootstrap admin (if `ADMIN_PHONES` includes it): `999999999`

## Run (short)

```powershell
# Terminal A — API
cd backend
copy .env.example .env   # first time
npm install
npm run build -w @maekel/shared
npm run db:init          # first time — needs local Postgres
npm run dev:all          # gateway http://127.0.0.1:8080

# Terminal B — app
cd ..
flutter pub get
flutter run -d chrome
```
