# Deploy Maekel Web for QA (free)

API stays on Render: `https://maekel-api.onrender.com`

## Live URLs

| Host | URL |
|------|-----|
| **Cloudflare Pages (preferred)** | **https://maekel.pages.dev/** |
| **GitHub Pages (backup)** | **https://zewdnehnathan.github.io/maekel/** |

Both use hash routes (`/#/home`). Prefer Cloudflare — root path, faster CDN. GitHub is kept as a free backup.

If the first paint looks blank, wait ~2–5s for Flutter/CanvasKit or hard-refresh. Open with `/#/auth` if needed.

## One-shot deploy (both hosts)

```powershell
cd C:\Users\hp\Documents\maekel
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-web.ps1
```

Requires: Flutter SDK, `npx wrangler` logged in (`npx wrangler login`), `gh` push access.

## Cloudflare only

```powershell
flutter build web --release --web-resources-cdn --base-href "/" --dart-define=API_BASE_URL=https://maekel-api.onrender.com
npx wrangler pages deploy build/web --project-name maekel --branch main --commit-dirty=true
```

## GitHub Pages only

```powershell
flutter build web --release --web-resources-cdn --base-href "/maekel/" --dart-define=API_BASE_URL=https://maekel-api.onrender.com
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-gh-pages.ps1
```

Pages source: branch `gh-pages` / (root).

## Send to QA

Share **https://maekel.pages.dev/** (or the GitHub URL as backup).

- First API call may be slow if Render is asleep (~30–60s)
- OTP code: `123456`
