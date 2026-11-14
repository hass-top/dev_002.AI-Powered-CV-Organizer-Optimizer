# ==============================================================================
# pull-backend-image.ps1
#
# Pulls the latest modo-backend Docker image built by the CI pipeline
# (GitHub Actions -> GitHub Container Registry) to your local PC.
#
# Prerequisites:
#   - Docker Desktop installed and running on this PC
#   - Logged in to GHCR:  docker login ghcr.io -u <GITHUB_USERNAME>
#     (use a Personal Access Token with 'read:packages' scope as the password)
#
# Usage (run from this folder or any path):
#   pwsh -File pull-backend-image.ps1
# ==============================================================================

$ErrorActionPreference = 'Stop'

# ----------------------------- Configuration ---------------------------------
# GitHub Container Registry image (must match backend-ci.yml env.IMAGE_NAME)
$Registry   = "ghcr.io"
$Owner      = "hass-top"   # <-- REPLACE with your GitHub username/org
$Repo       = "dev_002.AI-Powered-CV-Organizer-Optimizer"
$Image      = "$Registry/$Owner/$Repo/backend-modo-backend"
$Tag        = "latest"

# Optional: override tag via parameter
param(
    [string]$TagOverride = $null
)

if ($TagOverride) { $Tag = $TagOverride }

$FullImage = "$Image:$Tag"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " modo-backend image puller" -ForegroundColor Cyan
Write-Host " Target image: $FullImage" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ----------------------------- Pre-checks ------------------------------------
Write-Host "`n[1/4] Checking Docker is running..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if (-not $dockerVersion) {
        throw "Docker daemon is not reachable. Start Docker Desktop and try again."
    }
    Write-Host "    Docker server version: $dockerVersion" -ForegroundColor Green
}
catch {
    Write-Host "    ERROR: $_" -ForegroundColor Red
    exit 1
}

# ----------------------------- Login check -----------------------------------
Write-Host "`n[2/4] Checking GHCR login..." -ForegroundColor Yellow
$authTest = docker pull "$Registry/$Owner/$Repo@placeholder" 2>&1
if ($authTest -match "denied|unauthorized|authentication required|no such host") {
    Write-Host "    Not logged in to $Registry. Please run:" -ForegroundColor Yellow
    Write-Host "      docker login $Registry -u $env:GITHUB_USERNAME" -ForegroundColor White
    Write-Host "    (use a PAT with read:packages as the password)" -ForegroundColor White
    exit 1
}
Write-Host "    Registry access OK." -ForegroundColor Green

# ----------------------------- Pull image ------------------------------------
Write-Host "`n[3/4] Pulling image $FullImage ..." -ForegroundColor Yellow
docker pull $FullImage
if ($LASTEXITCODE -ne 0) {
    Write-Host "    ERROR: docker pull failed." -ForegroundColor Red
    exit 1
}
Write-Host "    Pulled successfully." -ForegroundColor Green

# ----------------------------- Verify ----------------------------------------
Write-Host "`n[4/4] Verifying local image..." -ForegroundColor Yellow
$local = docker images --format '{{.Repository}}:{{.Tag}}' | Where-Object { $_ -eq $FullImage }
if ($local) {
    Write-Host "    Image found locally: $FullImage" -ForegroundColor Green
}
else {
    Write-Host "    WARNING: image not listed locally after pull." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host " Done. You can now run the backend with:" -ForegroundColor Cyan
Write-Host "   docker run -p 8080:8080 $FullImage" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
