# Deploy Maekel Flutter web to Cloudflare Pages AND GitHub Pages.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$env:Path = "C:\Users\hp\flutter\bin;" + $env:Path
$api = "https://maekel-api.onrender.com"

Write-Host "==> Cloudflare Pages (base-href /)"
flutter build web --release --web-resources-cdn --base-href "/" --dart-define="API_BASE_URL=$api"
Copy-Item (Join-Path $root "web\_redirects") (Join-Path $root "build\web\_redirects") -Force
npx --yes wrangler@4 pages deploy build/web --project-name maekel --branch main --commit-dirty=true

Write-Host "==> GitHub Pages (base-href /maekel/)"
flutter build web --release --web-resources-cdn --base-href "/maekel/" --dart-define="API_BASE_URL=$api"
powershell -ExecutionPolicy Bypass -File (Join-Path $root "scripts\deploy-gh-pages.ps1")

Write-Host ""
Write-Host "Cloudflare: https://maekel.pages.dev/"
Write-Host "GitHub:     https://zewdnehnathan.github.io/maekel/"
