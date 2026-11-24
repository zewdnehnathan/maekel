# How to deploy Maekel yourself

Current live targets:

| Piece | URL / path |
|-------|------------|
| **API (Render)** | https://maekel-api.onrender.com |
| **Web (preferred)** | https://maekel.pages.dev/ |
| **Web (backup)** | https://zewdnehnathan.github.io/maekel/ |
| **Release APK** | `releases/maekel-qa.apk` (also `build/app/outputs/flutter-apk/app-release.apk`) |

Mock OTP for QA: `123456`

---

## Prerequisites

- GitHub access to this repo (`zewdnehnathan/maekel`)
- Flutter SDK on PATH
- Node.js 22+ (backend / wrangler)
- For web: Cloudflare account + `npx wrangler login` once
- For API: [Render](https://dashboard.render.com) service already linked to this repo (or create from `render.yaml`)
- For first-time API DB: Neon Postgres (see [deploy-demo-render-neon.md](./deploy-demo-render-neon.md))

From the repo root on Windows:

```powershell
cd C:\Users\hp\Documents\maekel
```

---

## 1. Deploy the backend (API)

Render builds from **GitHub `main`**.

```powershell
git add -A
git status
git commit -m "Your change description"
git push origin main
```

Then in [Render Dashboard](https://dashboard.render.com) → **maekel-api** → watch the deploy until **Live**.

### Smoke test

```powershell
curl.exe https://maekel-api.onrender.com/healthz
curl.exe https://maekel-api.onrender.com/
```

Expect HTTP 200. Free plan sleeps after idle — first request can take 30–60s.

### Important env vars (Render → Environment)

Already set by blueprint / earlier setup for this project:

- `PUBLIC_API_BASE=https://maekel-api.onrender.com` (image URLs for market/food/events)
- `POSTGRES_*` + `POSTGRES_SSL=true` (Neon)
- `MOCK_OTP_CODE=123456`
- `ADMIN_PHONES` (E.164, comma-separated)
- Internal `*_URL` pointing at `127.0.0.1:3001`–`3007`

Do **not** commit `backend/.env`. Full Neon + Render first-time setup: [deploy-demo-render-neon.md](./deploy-demo-render-neon.md).

---

## 2. Deploy the frontend (web)

One-shot (Cloudflare Pages **and** GitHub Pages):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-web.ps1
```

That script:

1. Builds Flutter web against `https://maekel-api.onrender.com`
2. Deploys to Cloudflare project `maekel` → https://maekel.pages.dev/
3. Rebuilds with `/maekel/` base href and force-pushes `gh-pages` → https://zewdnehnathan.github.io/maekel/

### Cloudflare only

```powershell
flutter build web --release --web-resources-cdn --base-href "/" --dart-define=API_BASE_URL=https://maekel-api.onrender.com
Copy-Item .\web\_redirects .\build\web\_redirects -Force
npx --yes wrangler@4 pages deploy build/web --project-name maekel --branch main --commit-dirty=true
```

### GitHub Pages only

```powershell
flutter build web --release --web-resources-cdn --base-href "/maekel/" --dart-define=API_BASE_URL=https://maekel-api.onrender.com
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-gh-pages.ps1
```

More detail: [deploy-web-qa.md](./deploy-web-qa.md).

---

## 3. Build / refresh the release APK

Points the Android app at the live Render API:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://maekel-api.onrender.com
```

Output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Copy into the easy-to-share folder (optional):

```powershell
New-Item -ItemType Directory -Force -Path .\releases | Out-Null
Copy-Item .\build\app\outputs\flutter-apk\app-release.apk .\releases\maekel-qa.apk -Force
```

Install on a phone (USB debugging or sideload). Allow “install unknown apps” if prompted.

For a **local** backend instead of Render, omit `--dart-define` (emulator uses `10.0.2.2:8080`).

---

## Recommended order each release

1. Commit + `git push origin main` → wait for Render **Live**
2. Hit `/healthz` once (wake cold start)
3. Run `.\scripts\deploy-web.ps1`
4. Build APK and copy to `releases\maekel-qa.apk`
5. Share **https://maekel.pages.dev/** + APK with QA (OTP `123456`)

---

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| API timeout / blank app | Wait for cold start; open `/healthz` then retry |
| Images 404 after upload | Confirm `PUBLIC_API_BASE` is the public Render URL |
| Wrangler auth error | `npx wrangler login` |
| Render OOM / crash loop | Upgrade `maekel-api` to Starter plan |
| Web blank first paint | Wait 2–5s or hard-refresh; try `/#/auth` |
| APK talks to localhost | Rebuild with `--dart-define=API_BASE_URL=https://maekel-api.onrender.com` |

---

## Related docs

- Local stack: [local-dev-setup.md](./local-dev-setup.md)
- Render + Neon first setup: [deploy-demo-render-neon.md](./deploy-demo-render-neon.md)
- Web hosts: [deploy-web-qa.md](./deploy-web-qa.md)
