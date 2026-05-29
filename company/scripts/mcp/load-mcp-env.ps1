<#
.SYNOPSIS
    Load MCP environment variables from .env.mcp file
.DESCRIPTION
    Loads environment variables from the .env.mcp file for MCP server configuration.
    Can load into current session or set permanently for the user.
.PARAMETER Permanent
    If specified, sets environment variables permanently for the current user
.PARAMETER Validate
    If specified, validates that critical variables are not using placeholder values
.EXAMPLE
    .\load-mcp-env.ps1
    .\load-mcp-env.ps1 -Permanent
    .\load-mcp-env.ps1 -Validate
#>

param(
    [switch]$Permanent,
    [switch]$Validate
)

# Configuration
$envFile = Join-Path (Split-Path $PSScriptRoot) ".env.mcp"

if (!(Test-Path $envFile)) {
    Write-Error "Environment file not found: $envFile"
    exit 1
}

Write-Host "Loading MCP environment variables from: $envFile" -ForegroundColor Green

$variables = @{}
$criticalVars = @('GITHUB_TOKEN', 'AZURE_DEVOPS_PAT', 'POSTGRES_CONNECTION_STRING')
$placeholderPatterns = @('your_', 'your-', 'placeholder', 'example', 'secret_', '[user]', '[password]')

# Parse .env.mcp file
$content = Get-Content $envFile
foreach ($line in $content) {
    # Skip comments and empty lines
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    # Parse KEY=VALUE
    if ($line -match '^([^=]+)=(.*)$') {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        $variables[$key] = $value
    }
}

# Load variables
$loadedCount = 0
$skippedCount = 0
$warningCount = 0

foreach ($var in $variables.GetEnumerator()) {
    $isPlaceholder = $false

    # Check for placeholder values
    foreach ($pattern in $placeholderPatterns) {
        if ($var.Value -like "*$pattern*") {
            $isPlaceholder = $true
            break
        }
    }

    if ($isPlaceholder) {
        if ($Validate) {
            if ($var.Key -in $criticalVars) {
                Write-Warning "Critical variable '$($var.Key)' contains placeholder value"
                $warningCount++
            } else {
                Write-Host "  Skipping '$($var.Key)' - contains placeholder" -ForegroundColor Yellow
            }
            $skippedCount++
            continue
        } else {
            Write-Host "  Warning: '$($var.Key)' contains placeholder value" -ForegroundColor Yellow
            $warningCount++
        }
    }

    if ($Permanent) {
        # Set permanently for user
        [Environment]::SetEnvironmentVariable($var.Key, $var.Value, [EnvironmentVariableTarget]::User)
        Write-Host "  Set permanently: $($var.Key)" -ForegroundColor Green
    } else {
        # Set for current session
        Set-Item -Path "env:$($var.Key)" -Value $var.Value
        Write-Host "  Set for session: $($var.Key)" -ForegroundColor Cyan
    }
    $loadedCount++
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Loaded: $loadedCount variables" -ForegroundColor Green
if ($skippedCount -gt 0) {
    Write-Host "Skipped: $skippedCount placeholder variables" -ForegroundColor Yellow
}
if ($warningCount -gt 0) {
    Write-Host "Warnings: $warningCount variables need configuration" -ForegroundColor Yellow
}

if ($Permanent) {
    Write-Host "`nEnvironment variables set permanently for user." -ForegroundColor Green
    Write-Host "Restart your PowerShell session to use them." -ForegroundColor Yellow
} else {
    Write-Host "`nEnvironment variables loaded for current session only." -ForegroundColor Cyan
}

# Validation mode
if ($Validate) {
    $missingCritical = @()
    foreach ($critical in $criticalVars) {
        if ($critical -notin $variables.Keys) {
            $missingCritical += $critical
        }
    }

    if ($missingCritical.Count -gt 0) {
        Write-Error "Missing critical variables: $($missingCritical -join ', ')"
        exit 1
    }

    if ($warningCount -gt 0) {
        Write-Warning "$warningCount critical variables contain placeholder values"
        Write-Host "`nTo configure properly:" -ForegroundColor Yellow
        Write-Host "1. Edit .env.mcp file" -ForegroundColor Gray
        Write-Host "2. Replace placeholder values with actual credentials" -ForegroundColor Gray
        Write-Host "3. Run: .\load-mcp-env.ps1 -Permanent" -ForegroundColor Gray
        exit 1
    }

    Write-Host "`nAll critical variables are configured!" -ForegroundColor Green
}