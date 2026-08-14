<#
.SYNOPSIS
    Verifies environment variable setup and handshake across all services
.DESCRIPTION
    Checks that:
    1. ROOT .env exists and has required variables
    2. No redundant .env files exist in subdirectories
    3. All services can read from ROOT .env
    4. Port configuration is consistent
.EXAMPLE
    .\verify-env-setup.ps1
#>

[CmdletBinding()]
param()

# Import PathResolver
. "$PSScriptRoot\..\scripts\common\PathResolver.ps1"

$ProjectRoot = Get-ProjectRoot
Write-Host "📁 Project Root: $ProjectRoot" -ForegroundColor Cyan
Write-Host ""

# Test Results
$Tests = @()
$ErrorCount = 0
$WarningCount = 0

function Add-Test {
    param([string]$Name, [string]$Status, [string]$Message)

    $Color = switch ($Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
    }

    $Icon = switch ($Status) {
        "PASS" { "✅" }
        "WARN" { "⚠️" }
        "FAIL" { "❌" }
    }

    Write-Host "$Icon $Name" -ForegroundColor $Color
    if ($Message) {
        Write-Host "   $Message" -ForegroundColor Gray
    }

    $Tests += @{ Name = $Name; Status = $Status; Message = $Message }

    if ($Status -eq "FAIL") { $script:ErrorCount++ }
    if ($Status -eq "WARN") { $script:WarningCount++ }
}

Write-Host "🔍 Environment Configuration Verification" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host ""

# Test 1: ROOT .env exists
Write-Host "1. Checking ROOT .env file..." -ForegroundColor Cyan
$RootEnvPath = Join-Path $ProjectRoot ".env"
if (Test-Path $RootEnvPath) {
    Add-Test "ROOT .env exists" "PASS" "Found at: $RootEnvPath"
} else {
    Add-Test "ROOT .env exists" "FAIL" "Not found. Run: cp .env.example .env"
}
Write-Host ""

# Test 2: Check for redundant .env files
Write-Host "2. Checking for redundant .env files..." -ForegroundColor Cyan
$RedundantEnvFiles = @(
    "services\jobs\.env",
    "apps\dashboard\.env"
)

foreach ($file in $RedundantEnvFiles) {
    $fullPath = Join-Path $ProjectRoot $file
    if (Test-Path $fullPath) {
        Add-Test "No redundant .env at $file" "WARN" "Found redundant .env. Should use ROOT .env instead."
    } else {
        Add-Test "No redundant .env at $file" "PASS"
    }
}
Write-Host ""

# Test 3: Check ROOT .env has required variables
Write-Host "3. Checking required environment variables..." -ForegroundColor Cyan
if (Test-Path $RootEnvPath) {
    $EnvContent = Get-Content $RootEnvPath -Raw

    $RequiredVars = @(
        "GITHUB_TOKEN",
        "DATABASE_URL",
        "JOBS_PORT",
        "DASHBOARD_PORT"
    )

    foreach ($var in $RequiredVars) {
        if ($EnvContent -match "^$var=.+$" -or $EnvContent -match "`n$var=.+$") {
            # Check if it's not just the placeholder
            if ($EnvContent -match "$var=your_" -or $EnvContent -match "$var=file:") {
                if ($var -eq "DATABASE_URL" -and $EnvContent -match "DATABASE_URL=file:") {
                    Add-Test "$var is set" "PASS" "Using SQLite (development)"
                } else {
                    Add-Test "$var is set" "WARN" "Has placeholder value - update with real credentials"
                }
            } else {
                Add-Test "$var is set" "PASS"
            }
        } else {
            Add-Test "$var is set" "FAIL" "Variable missing or not configured"
        }
    }
} else {
    Add-Test "Required variables" "FAIL" "Cannot check - ROOT .env doesn't exist"
}
Write-Host ""

# Test 4: Port Configuration Consistency
Write-Host "4. Checking port configuration..." -ForegroundColor Cyan
if (Test-Path $RootEnvPath) {
    $EnvContent = Get-Content $RootEnvPath -Raw

    # Extract ports
    if ($EnvContent -match 'JOBS_PORT=(\d+)') {
        $JobsPort = $Matches[1]
        if ($JobsPort -eq "4000") {
            Add-Test "Jobs port is 4000" "PASS"
        } else {
            Add-Test "Jobs port is 4000" "WARN" "Found: $JobsPort (expected 4000)"
        }
    }

    if ($EnvContent -match 'DASHBOARD_PORT=(\d+)') {
        $DashboardPort = $Matches[1]
        if ($DashboardPort -eq "3001") {
            Add-Test "Dashboard port is 3001" "PASS"
        } else {
            Add-Test "Dashboard port is 3001" "WARN" "Found: $DashboardPort (expected 3001)"
        }
    }

    # Check URL consistency
    if ($EnvContent -match 'DASHBOARD_URL=(.+)') {
        $DashboardUrl = $Matches[1].Trim()
        if ($DashboardUrl -match "localhost:$DashboardPort") {
            Add-Test "DASHBOARD_URL matches port" "PASS"
        } else {
            Add-Test "DASHBOARD_URL matches port" "WARN" "URL doesn't match DASHBOARD_PORT"
        }
    }
}
Write-Host ""

# Test 5: Services can find ROOT .env
Write-Host "5. Checking service configurations..." -ForegroundColor Cyan

# Check jobs service app.module.ts
$AppModulePath = Join-Path $ProjectRoot "services\jobs\src\app.module.ts"
if (Test-Path $AppModulePath) {
    $AppModuleContent = Get-Content $AppModulePath -Raw
    if ($AppModuleContent -match '\.\.\/\.\.\/\.\.\/\.env') {
        Add-Test "Jobs service reads ROOT .env" "PASS" "ConfigModule configured correctly"
    } else {
        Add-Test "Jobs service reads ROOT .env" "FAIL" "app.module.ts not configured for ROOT .env"
    }
}

# Check dashboard api-server.js
$ApiServerPath = Join-Path $ProjectRoot "apps\dashboard\api-server.js"
if (Test-Path $ApiServerPath) {
    $ApiServerContent = Get-Content $ApiServerPath -Raw
    if ($ApiServerContent -match "dotenv.*\.\.\/\.\.\/\.env") {
        Add-Test "Dashboard reads ROOT .env" "PASS" "dotenv.config configured correctly"
    } else {
        Add-Test "Dashboard reads ROOT .env" "FAIL" "api-server.js not configured for ROOT .env"
    }
}
Write-Host ""

# Test 6: .gitignore properly configured
Write-Host "6. Checking .gitignore..." -ForegroundColor Cyan
$GitignorePath = Join-Path $ProjectRoot ".gitignore"
if (Test-Path $GitignorePath) {
    $GitignoreContent = Get-Content $GitignorePath -Raw

    if ($GitignoreContent -match '^\s*\.env\s*$' -or $GitignoreContent -match '\n\s*\.env\s*$') {
        Add-Test ".env is gitignored" "PASS"
    } else {
        Add-Test ".env is gitignored" "FAIL" ".env should be in .gitignore"
    }

    if ($GitignoreContent -match '!\.env\.example') {
        Add-Test ".env.example is NOT gitignored" "PASS"
    } else {
        Add-Test ".env.example is NOT gitignored" "WARN" "Should allow .env.example in git"
    }
}
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "📊 Summary" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "Total Tests: $($Tests.Count)" -ForegroundColor Cyan
Write-Host "Passed: $(($Tests | Where-Object { $_.Status -eq 'PASS' }).Count)" -ForegroundColor Green
Write-Host "Warnings: $WarningCount" -ForegroundColor Yellow
Write-Host "Failures: $ErrorCount" -ForegroundColor Red
Write-Host ""

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "✅ All checks passed! Environment setup is correct." -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "⚠️  Setup has warnings but no critical errors." -ForegroundColor Yellow
    Write-Host "   Review warnings and update configuration as needed." -ForegroundColor Gray
    exit 0
} else {
    Write-Host "❌ Setup has critical errors that must be fixed." -ForegroundColor Red
    Write-Host "   Fix the failures above before running services." -ForegroundColor Gray
    exit 1
}
