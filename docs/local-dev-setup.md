# Local development setup (new developers)

How to run **Maekel** on your machine: Postgres + backend microservices/gateway, then the Flutter app.

---

## What you are running

```text
Flutter app  →  http://127.0.0.1:8080 (gateway)
                      │
        ┌─────────────┼─────────────┬──────────────┐
        ▼             ▼             ▼              ▼
   identity:3001  market:3002   food:3003     ride:3004
   chat:3005      games:3006    events:3007
```

| Piece | Role |
|-------|------|
| **Gateway** (`:8080`) | Single HTTP entry; proxies `/v1/*` to services |
| **identity** | Auth (OTP), JWT, roles / Staff |
| **market / food / ride / chat / games / events** | Domain APIs + own Postgres DB |
| **Flutter** | Web / Android / iOS / desktop client |

Repo layout:

```text
maekel/
  lib/                 # Flutter app
  backend/
    apps/              # gateway + microservices
    packages/shared/   # shared Fastify helpers
    .env.example
  docs/                # this guide + QA / architecture
```

---

## Prerequisites

Install before anything else:

| Tool | Suggested | Notes |
|------|-----------|--------|
| **Git** | latest | Clone the repo |
| **Node.js** | **20 LTS** (18+ OK) | Backend monorepo (`npm` workspaces) |
| **PostgreSQL** | **14+** (18 used in scripts) | Local server; default `postgres` / `postgres` |
| **Flutter SDK** | **3.14+** (matches `pubspec.yaml`) | [Install Flutter](https://docs.flutter.dev/get-started/install) |
| **Android Studio** / Xcode | as needed | Emulator / simulator for mobile |
| **Chrome** | optional | Fastest Flutter web loop |

Check:

```powershell
node -v
npm -v
psql --version
flutter doctor
```

On Windows, if `psql` is not on `PATH`, add something like:

`C:\Program Files\PostgreSQL\18\bin`

> `backend/scripts/init-dbs.ps1` currently looks for `psql` at  
> `C:\Program Files\PostgreSQL\18\bin\psql.exe`.  
> If your install path/version differs, edit that path or create the databases by hand (see below).

---

## 1. Clone

```powershell
git clone <YOUR_REPO_URL> maekel
cd maekel
```

---

## 2. Backend setup

### 2.1 Environment file

```powershell
cd backend
copy .env.example .env
```

Defaults in `.env` are fine for local work:

- Postgres: `localhost:5432`, user/password `postgres` / `postgres`
- `MOCK_OTP_CODE=123456`
- `ADMIN_PHONES=+251999999999` (bootstrap Staff admin)
- Service URLs on `127.0.0.1:3001`–`3007`, gateway `8080`
- `PUBLIC_API_BASE=http://127.0.0.1:8080` (used in market/food/events image URLs)

Ensure `.env` includes games + events (if missing from an old copy):

```env
PUBLIC_API_BASE=http://127.0.0.1:8080
GAMES_PORT=3006
EVENTS_PORT=3007
GAMES_URL=http://127.0.0.1:3006
EVENTS_URL=http://127.0.0.1:3007
```

### 2.2 Create databases

**Option A — script (Windows):**

```powershell
cd backend
npm run db:init
```

**Option B — SQL (any OS):**

```sql
CREATE DATABASE maekel_identity;
CREATE DATABASE maekel_market;
CREATE DATABASE maekel_food;
CREATE DATABASE maekel_ride;
CREATE DATABASE maekel_chat;
CREATE DATABASE maekel_games;
CREATE DATABASE maekel_events;
```

Each service owns **one** database (DB-per-service). Migrations run automatically when a service starts.

### 2.3 Install & build shared package

```powershell
cd backend
npm install
npm run build -w @maekel/shared
```

### 2.4 Start all services + gateway

```powershell
cd backend
npm run dev:all
```

This starts (via `concurrently`):

| Process | Port |
|---------|------|
| identity-service | 3001 |
| market-service | 3002 |
| food-service | 3003 |
| ride-service | 3004 |
| chat-service | 3005 |
| games-service | 3006 |
| events-service | 3007 |
| gateway | **8080** |

Leave this terminal open. Logs are prefixed by service name.

**Single service only** (optional):

```powershell
npm run dev:gateway
npm run dev:identity
# … same pattern for market, food, ride, chat, games, events
```

### 2.5 Smoke-test the API

```powershell
curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/v1/market/categories
curl http://127.0.0.1:8080/v1/ride/places
curl http://127.0.0.1:8080/v1/food/merchants
```

**Mock auth:**

```http
POST http://127.0.0.1:8080/v1/auth/otp/request
Content-Type: application/json

{ "phone": "911234567" }
```

```http
POST http://127.0.0.1:8080/v1/auth/otp/verify
Content-Type: application/json

{ "phone": "911234567", "code": "123456" }
```

Use the returned `accessToken` as `Authorization: Bearer <token>`.

Bootstrap admin (from `ADMIN_PHONES`): local phone **`999999999`**, OTP **`123456`**.

---

## 3. Frontend (Flutter) setup

### 3.1 Dependencies

From the **repo root** (not `backend/`):

```powershell
cd ..   # if you are still in backend/
flutter pub get
```

### 3.2 How the app finds the API

`lib/core/constants/app_constants.dart`:

| Target | Default API base |
|--------|------------------|
| Chrome / Windows / iOS simulator | `http://127.0.0.1:8080` |
| Android emulator | `http://10.0.2.2:8080` (host loopback) |
| Override | `--dart-define=API_BASE_URL=...` |

Gateway must be running before you log in against a real backend.

### 3.3 Run the app

**Web (recommended first):**

```powershell
flutter run -d chrome
```

**Android emulator:**

```powershell
flutter run -d emulator-5554
# or: flutter devices   then pick the id
```

**Windows desktop:**

```powershell
flutter run -d windows
```

**Point at a remote API** (e.g. Render QA):

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://maekel-api.onrender.com
```

**Release APK (local gateway):**

```powershell
flutter build apk --release
# APK: build\app\outputs\flutter-apk\app-release.apk
```

**Release APK (Render):**

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://maekel-api.onrender.com
```

### 3.4 First login in the app

1. Enter a **9-digit** local number (e.g. `911234567`) — UI shows `+251`.
2. OTP: **`123456`** (mock).
3. You land on Home (Ride, Market, Food, Games, Events, …).

Languages: open the language picker (en / am / ti / om / aa / so / sw / zh). Preference is stored on device.

---

## 4. Typical daily workflow

**Terminal A — backend:**

```powershell
cd backend
npm run dev:all
```

**Terminal B — Flutter:**

```powershell
flutter run -d chrome
```

Change Dart → hot reload. Change a backend service → that process restarts (tsx watch). After shared package changes:

```powershell
cd backend
npm run build -w @maekel/shared
```

then restart `dev:all` if needed.

---

## 5. Architecture cheat sheet

- **Gateway** does not own a DB; it only proxies.
- Services use **`@maekel/shared`** for Fastify bootstrap, JWT, Postgres pool, migrations.
- Auth is **mock OTP** locally (`MOCK_OTP_CODE`); not production SMS.
- Roles: defaults on every user + Staff grants; bootstrap phones from `ADMIN_PHONES`. After a Staff grant, user must **sign out and OTP again** so the JWT refreshes.

More detail: [architecture.md](./architecture.md) · QA phones/roles: [qa-test-phones-and-roles.md](./qa-test-phones-and-roles.md).

---

## 6. Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Flutter login fails / network error | Is gateway up? `curl http://127.0.0.1:8080/healthz` |
| Android can’t reach API | Use emulator (not a physical device without USB reverse); base URL is `10.0.2.2:8080` |
| Physical Android device | Use machine LAN IP, e.g. `--dart-define=API_BASE_URL=http://192.168.x.x:8080`, and allow firewall on 8080 |
| `db:init` fails | Fix `psql` path in `backend/scripts/init-dbs.ps1`, or create DBs manually |
| Port already in use | Stop other Node/Postgres apps on 3001–3007 / 8080 |
| Service crashes on boot | Postgres running? Correct password in `.env`? DB exists? |
| Blank TextFields after language change | Known for some locales; Material fallbacks are wired — try hot restart |
| Fonts slow on first web load | `google_fonts` fetches at runtime; needs network once |
| Stale JWT / missing Staff | Sign out → OTP again after role grant |

---

## 7. Optional: cloud API while developing UI

You can skip local backend and aim Flutter at the shared QA API:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://maekel-api.onrender.com
```

Note: free Render may **cold-start** (~30–60s) after idle. Deploy notes: [deploy-demo-render-neon.md](./deploy-demo-render-neon.md) · web QA hosts: [deploy-web-qa.md](./deploy-web-qa.md).

---

## 8. Quick checklist

- [ ] Postgres running; 7 `maekel_*` databases created  
- [ ] `backend/.env` present (from `.env.example`)  
- [ ] `npm install` + `npm run build -w @maekel/shared` in `backend/`  
- [ ] `npm run dev:all` — gateway answers on `:8080`  
- [ ] `flutter pub get` at repo root  
- [ ] `flutter run -d chrome` — OTP `123456` works  

You’re ready to develop.
