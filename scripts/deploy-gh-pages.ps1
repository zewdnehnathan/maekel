$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$web = Join-Path $root "build\web"
$tmp = Join-Path $env:TEMP ("maekel-gh-pages-" + [guid]::NewGuid().ToString("N"))

if (-not (Test-Path $web)) {
  throw "Missing build/web. Run flutter build web first."
}

New-Item -ItemType Directory -Path $tmp | Out-Null
Copy-Item -Recurse -Force (Join-Path $web "*") $tmp

Set-Location $tmp
git init -b gh-pages
git config http.postBuffer 524288000
git config http.version HTTP/1.1
git add -A
git -c user.email="cursoragent@cursor.com" -c user.name="Cursor" commit -m "Deploy Maekel web QA"
git remote add origin "https://github.com/zewdnehnathan/maekel.git"
git push -f origin gh-pages

Write-Host "Pushed gh-pages."
