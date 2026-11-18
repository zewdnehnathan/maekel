# Deploy Maekel Web for QA (free)

## Free host options

| Host | Cost | Notes |
|------|------|--------|
| **Netlify Drop** | Free | Fastest: drag `build/web` in browser, get a URL |
| **Cloudflare Pages** | Free | Fast CDN; connect GitHub or CLI |
| **Firebase Hosting** | Free Spark | Google account |
| **GitHub Pages** | Free on **public** repos | Private repos need a paid plan |
| **Render Static** | Free | Can sleep like the API |

**Recommended for QA today:** Netlify Drop.

API stays on Render: `https://maekel-api.onrender.com`

## Build (local)

```powershell
cd C:\Users\hp\Documents\maekel
flutter build web --release --web-resources-cdn --base-href "/" --dart-define=API_BASE_URL=https://maekel-api.onrender.com
```

Output: `build/web`

## Deploy (Netlify Drop — no CLI)

1. Open https://app.netlify.com/drop  
2. Drag the folder `C:\Users\hp\Documents\maekel\build\web` onto the page  
3. Copy the `*.netlify.app` URL and send it to QA

## Send to QA

Share the HTTPS URL. Note:

- First API call may be slow if Render is asleep (~30–60s)
- OTP code: `123456`
- iPhone: open in Safari; “Add to Home Screen” optional
- Location/GPS prompts differ from native Android
