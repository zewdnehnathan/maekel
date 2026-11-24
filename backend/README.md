# Maekel Backend (MVP)

TypeScript Fastify microservices with **Postgres DB-per-service**, behind a local gateway.

**New developer full setup (backend + Flutter):** [docs/local-dev-setup.md](../docs/local-dev-setup.md)

## Services

| Service | Port | Database |
|---------|------|----------|
| gateway | 8080 | — |
| identity-service | 3001 | `maekel_identity` |
| market-service | 3002 | `maekel_market` |
| food-service | 3003 | `maekel_food` |
| ride-service | 3004 | `maekel_ride` |
| chat-service | 3005 | `maekel_chat` |
| games-service | 3006 | `maekel_games` |
| events-service | 3007 | `maekel_events` |

Public entry: `http://127.0.0.1:8080`

## Setup

1. Local Postgres running (default user/password `postgres` / `postgres`)
2. Copy env:

```powershell
copy .env.example .env
```

3. Create DBs (already done if you followed agent setup):

```powershell
npm run db:init
```

4. Install + run:

```powershell
cd backend
npm install
npm run build -w @maekel/shared
npm run dev:all
```

## Auth (mock OTP)

```http
POST /v1/auth/otp/request
{ "phone": "911234567" }

POST /v1/auth/otp/verify
{ "phone": "911234567", "code": "123456" }
```

Use returned `accessToken` as `Authorization: Bearer …`.

## Smoke checks

```powershell
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/v1/food/merchants
curl http://127.0.0.1:8080/v1/market/categories
curl http://127.0.0.1:8080/v1/ride/places
```

## Demo / QA cloud deploy

See [docs/deploy-demo-render-neon.md](../docs/deploy-demo-render-neon.md) for **Render + Neon** (free-tier friendly).
