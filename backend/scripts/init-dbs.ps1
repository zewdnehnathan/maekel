$ErrorActionPreference = "Stop"
$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
if (-not (Test-Path $psql)) {
  throw "psql not found at $psql"
}

$env:PGPASSWORD = if ($env:POSTGRES_PASSWORD) { $env:POSTGRES_PASSWORD } else { "postgres" }
$user = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$hostName = if ($env:POSTGRES_HOST) { $env:POSTGRES_HOST } else { "localhost" }

$dbs = @(
  "maekel_identity",
  "maekel_market",
  "maekel_food",
  "maekel_ride",
  "maekel_chat",
  "maekel_games",
  "maekel_events"
)

foreach ($db in $dbs) {
  $sql = "SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec"
  $sql | & $psql -U $user -h $hostName -v ON_ERROR_STOP=1
  Write-Host "Ensured database $db"
}

Write-Host "Done."
