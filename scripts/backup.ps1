param(
  [string]$OutputDir = "./backups"
)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resolvedOutputDir = Resolve-Path $OutputDir -ErrorAction SilentlyContinue
if (-not $resolvedOutputDir) {
  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
  $resolvedOutputDir = Resolve-Path $OutputDir
}

$backupFile = Join-Path $resolvedOutputDir.Path "fbr_leads_$timestamp.sql"
$env:PGPASSWORD = $env:POSTGRES_PASSWORD

pg_dump \
  --host localhost \
  --port 5432 \
  --username $env:POSTGRES_USER \
  --dbname $env:POSTGRES_DB \
  --format plain \
  --file $backupFile

if ($LASTEXITCODE -ne 0) {
  throw "Backup failed with exit code $LASTEXITCODE"
}

Write-Output "Backup written to $backupFile"
