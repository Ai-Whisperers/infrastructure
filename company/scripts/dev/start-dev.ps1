# Company-Information Org OS - Development Startup Script
# This script starts all services needed for local development

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " AI-Whisperers Org OS - Development Setup " -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check if dependencies are installed
Write-Host "Checking dependencies..." -ForegroundColor Yellow

if (-not (Test-Path "node_modules")) {
    Write-Host "Installing root dependencies..." -ForegroundColor Yellow
    npm install --legacy-peer-deps
}

if (-not (Test-Path "apps/dashboard/node_modules")) {
    Write-Host "Installing dashboard dependencies..." -ForegroundColor Yellow
    Set-Location apps/dashboard
    npm install --legacy-peer-deps
    Set-Location ../..
}

if (-not (Test-Path "services/jobs/node_modules")) {
    Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
    Set-Location services/jobs
    npm install --legacy-peer-deps
    Set-Location ../..
}

# Check if database exists
if (-not (Test-Path "services/jobs/dev.db")) {
    Write-Host "Setting up database..." -ForegroundColor Yellow
    Set-Location services/jobs
    npx prisma generate
    npx prisma migrate dev --name init
    Set-Location ../..
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Green
Write-Host ""

# Start services in separate PowerShell windows
Write-Host "Starting Dashboard on http://localhost:3000" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd apps/dashboard; npm run dev"

Start-Sleep -Seconds 2

Write-Host "Starting Backend API on http://localhost:4000" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/jobs; npm run dev"

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "           Services Starting Up            " -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Dashboard:    http://localhost:3000" -ForegroundColor White
Write-Host "Backend API:  http://localhost:4000" -ForegroundColor White
Write-Host "API Docs:     http://localhost:4000/api" -ForegroundColor White
Write-Host "Health Check: http://localhost:4000/health" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop watching this script" -ForegroundColor Gray
Write-Host "Close the PowerShell windows to stop services" -ForegroundColor Gray