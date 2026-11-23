# Deploy Maekel Web for QA (free)

API stays on Render: `https://maekel-api.onrender.com`

## Primary host: GitHub Pages

| Item | Value |
|------|--------|
| URL | **https://zewdnehnathan.github.io/maekel/** |
| Branch | `gh-pages` |
| Cost | Free (public repo) |

Hash routes (`/#/home`) work without server rewrites.

### Build + deploy (Windows)

```powershell
cd C:\Users\hp\Documents\maekel
flutter build web --release --web-resources-cdn --base-href "/maekel/" --dart-define=API_BASE_URL=https://maekel-api.onrender.com
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-gh-pages.ps1
```

Then ensure Pages is on: repo **Settings → Pages → Deploy from branch `gh-pages` / (root)**.

## Other free options

| Host | Notes |
|------|--------|
| **Cloudflare Pages** | Fast CDN; use `--base-href "/"`; connect GitHub or `wrangler pages deploy build/web` |
| **Firebase Hosting** | Google account; `--base-href "/"` |
| **Render Static** | Same account as API; can sleep on free |
| Netlify | Blocked here when team credits are exceeded |

## Send to QA

Share **https://zewdnehnathan.github.io/maekel/**

- First API call may be slow if Render is asleep (~30–60s)
- OTP code: `123456`
- Open as `…/maekel/#/home` (hash routing)
