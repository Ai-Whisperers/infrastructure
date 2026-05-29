<#
.SYNOPSIS
    Test MCP Setup and Configuration
.DESCRIPTION
    Validates MCP server setup including modules, environment variables, and basic connectivity
.EXAMPLE
    .\test-mcp-setup.ps1
#>

Write-Host "`n=== MCP Setup Test ===" -ForegroundColor Cyan
Write-Host "Testing MCP configuration and setup..." -ForegroundColor Gray
Write-Host ""

# Load environment variables from .env.mcp
$envFile = Join-Path (Split-Path $PSScriptRoot) ".env.mcp"
if (Test-Path $envFile) {
    Write-Host "Loading environment from .env.mcp..." -ForegroundColor Yellow
    $content = Get-Content $envFile
    foreach ($line in $content) {
        if ($line -match '^([^#][^=]+)=(.*)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
    Write-Host "Environment variables loaded for this session" -ForegroundColor Green
}

# Test 1: Check Node.js installation
Write-Host "`n[1/5] Checking Node.js installation..." -NoNewline
try {
    $nodeVersion = node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK ($nodeVersion)" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "  Node.js is required. Install from: https://nodejs.org/" -ForegroundColor Yellow
    }
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "  Node.js not found. Install from: https://nodejs.org/" -ForegroundColor Yellow
}

# Test 2: Check MCP modules installation
Write-Host "[2/5] Checking MCP modules installation..."
$modulesPath = Join-Path $PSScriptRoot "..\mcp-servers\node_modules"
$modules = @{
    "GitHub" = "@modelcontextprotocol\server-github"
    "PostgreSQL" = "@modelcontextprotocol\server-postgres"
    "Filesystem" = "@modelcontextprotocol\server-filesystem"
}

$allModulesInstalled = $true
foreach ($module in $modules.GetEnumerator()) {
    $modulePath = Join-Path $modulesPath $module.Value
    if (Test-Path $modulePath) {
        Write-Host "  [OK] $($module.Key) MCP module installed" -ForegroundColor Green
    } else {
        Write-Host "  [X] $($module.Key) MCP module NOT installed" -ForegroundColor Red
        $allModulesInstalled = $false
    }
}

if (!$allModulesInstalled) {
    Write-Host "`n  To install missing modules, run:" -ForegroundColor Yellow
    Write-Host "    cd mcp-servers" -ForegroundColor Gray
    Write-Host "    npm install" -ForegroundColor Gray
}

# Test 3: Check environment variables
Write-Host "`n[3/5] Checking environment variables..."
$envVars = @{
    "GitHub" = @("GITHUB_TOKEN")
    "Azure DevOps" = @("AZURE_DEVOPS_PAT", "AZURE_DEVOPS_ORG", "AZURE_DEVOPS_PROJECT")
    "PostgreSQL" = @("POSTGRES_CONNECTION_STRING")
    "Filesystem" = @("FILESYSTEM_ROOT")
}

$configuredCount = 0
$totalRequired = 0

foreach ($service in $envVars.GetEnumerator()) {
    Write-Host "  $($service.Key):" -ForegroundColor Cyan
    foreach ($var in $service.Value) {
        $totalRequired++
        $value = [Environment]::GetEnvironmentVariable($var)
        if ($value) {
            # Check if it's a placeholder
            if ($value -like "*your*" -or $value -like "*placeholder*" -or $value -like "*[user]*") {
                Write-Host "    [!] $var = [PLACEHOLDER]" -ForegroundColor Yellow
            } else {
                Write-Host "    [OK] $var = [CONFIGURED]" -ForegroundColor Green
                $configuredCount++
            }
        } else {
            Write-Host "    [X] $var = [NOT SET]" -ForegroundColor Red
        }
    }
}

# Test 4: Check file system permissions
Write-Host "`n[4/5] Checking file system permissions..."
$fsRoot = [Environment]::GetEnvironmentVariable("FILESYSTEM_ROOT")
if (!$fsRoot) {
    $fsRoot = $PSScriptRoot
}

if (Test-Path $fsRoot) {
    try {
        $testFile = Join-Path $fsRoot ".mcp-test-$([Guid]::NewGuid()).tmp"
        New-Item -ItemType File -Path $testFile -Force | Out-Null
        Remove-Item $testFile -Force
        Write-Host "  OK Write permissions for: $fsRoot" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING Read-only access for: $fsRoot" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR Filesystem root not accessible: $fsRoot" -ForegroundColor Red
}

# Test 5: Test basic connectivity (if credentials are configured)
Write-Host "`n[5/5] Testing service connectivity..."

# GitHub API test
$githubToken = [Environment]::GetEnvironmentVariable("GITHUB_TOKEN")
if ($githubToken -and $githubToken -notlike "*your*") {
    Write-Host "  Testing GitHub API..." -NoNewline
    try {
        $headers = @{ Authorization = "Bearer $githubToken" }
        $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        Write-Host " OK (User: $($response.login))" -ForegroundColor Green
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
    }
} else {
    Write-Host "  GitHub API: Skipped (token not configured)" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Node.js: " -NoNewline
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "Installed" -ForegroundColor Green
} else {
    Write-Host "Not Installed" -ForegroundColor Red
}

Write-Host "MCP Modules: " -NoNewline
if ($allModulesInstalled) {
    Write-Host "All Installed" -ForegroundColor Green
} else {
    Write-Host "Some Missing" -ForegroundColor Yellow
}

Write-Host "Environment Variables: " -NoNewline
if ($configuredCount -eq $totalRequired) {
    Write-Host "All Configured" -ForegroundColor Green
} elseif ($configuredCount -gt 0) {
    Write-Host "$configuredCount/$totalRequired Configured" -ForegroundColor Yellow
} else {
    Write-Host "None Configured" -ForegroundColor Red
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
if ($configuredCount -lt $totalRequired) {
    Write-Host "1. Edit .env.mcp file with your actual credentials" -ForegroundColor Yellow
    Write-Host "2. Run: .\scripts\load-mcp-env.ps1 -Permanent" -ForegroundColor Yellow
    Write-Host "3. Restart PowerShell session" -ForegroundColor Yellow
}
Write-Host "4. Run health check: .\scripts\mcp-health-check.ps1 -Mode Check" -ForegroundColor Gray
Write-Host "5. Set up monitoring: .\scripts\mcp-health-scheduler.ps1 -Action Create" -ForegroundColor Gray

Write-Host "`nSetup test completed!" -ForegroundColor Green