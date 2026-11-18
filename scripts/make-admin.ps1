# Bootstrap / document Maekel platform admin phone.
# Usage:
#   .\scripts\make-admin.ps1
#   .\scripts\make-admin.ps1 -Phone 999999999
# Then sign out and OTP as that number (code 123456).

param(
  [string]$Phone = "999999999"
)

$ErrorActionPreference = "Stop"
$digits = ($Phone -replace '\D', '')
if ($digits.Length -eq 9) { $digits = "251$digits" }
if (-not $digits.StartsWith("251") -or $digits.Length -lt 12) {
  throw "Expected Ethiopian local 9 digits or 251… E.164 digits. Got: $Phone"
}
$e164 = "+$digits"

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root "backend\.env"
$example = Join-Path $root "backend\.env.example"
$render = Join-Path $root "render.yaml"

foreach ($path in @($envFile, $example)) {
  if (-not (Test-Path $path)) { continue }
  $content = Get-Content $path -Raw
  if ($content -match '(?m)^ADMIN_PHONES=') {
    $content = $content -replace '(?m)^ADMIN_PHONES=.*', "ADMIN_PHONES=$e164"
  } else {
    $content = $content.TrimEnd() + "`r`nADMIN_PHONES=$e164`r`n"
  }
  Set-Content -Path $path -Value $content -NoNewline
  Write-Host "Updated $path"
}

if (Test-Path $render) {
  $ry = Get-Content $render -Raw
  $ry = $ry -replace '(?ms)(- key: ADMIN_PHONES\s+value: )"[^"]*"', "`$1`"$e164`""
  Set-Content -Path $render -Value $ry -NoNewline
  Write-Host "Updated $render"
}

Write-Host ""
Write-Host "Admin phone set to $e164"
Write-Host "1) Redeploy API (or restart local backend)"
Write-Host "2) Sign out in the app"
Write-Host "3) Login with local digits $($digits.Substring(3)) and OTP 123456"
Write-Host "4) Home should show Market ops + Staff"
