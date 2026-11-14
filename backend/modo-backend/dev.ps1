
$ErrorActionPreference = "Stop"

Write-Host "`n=== CareerForge Development Environment ===" -ForegroundColor Cyan

# 1. Check Podman
Write-Host "`n[1/4] Checking Podman..." -ForegroundColor Yellow

if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    throw "Podman is not installed or not available in PATH."
}

# 2. Start Podman machine if needed
Write-Host "`n[2/4] Starting Podman..." -ForegroundColor Yellow

if ($LASTEXITCODE -ne 0) {
    podman machine start

    if ($LASTEXITCODE -ne 0) {
        throw "Could not start Podman machine."
    }
}

# 3. Start PostgreSQL
Write-Host "`n[3/4] Starting PostgreSQL..." -ForegroundColor Yellow

podman compose up -d

if ($LASTEXITCODE -ne 0) {
    throw "Could not start PostgreSQL."
}

# Wait for PostgreSQL readiness
Write-Host "Waiting for PostgreSQL..." -ForegroundColor Yellow

$ready = $false

for ($i = 0; $i -lt 30; $i++) {
    podman exec modo-postgres pg_isready -U modo_user -d modo_db *> $null

    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $ready) {
    throw "PostgreSQL did not become ready in time."
}

# 4. Start Spring Boot
Write-Host "`n[4/4] Starting Spring Boot..." -ForegroundColor Green

try {
    .\mvnw.cmd spring-boot:run
}
finally {
    Write-Host "`nStopping PostgreSQL..." -ForegroundColor Yellow
    podman compose stop
}

Write-Host "`nDevelopment environment stopped." -ForegroundColor Cyan
