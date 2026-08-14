# AI-Whisperers File Synchronization System
param(
    [Parameter(Position=0)]
    [ValidateSet("status", "validate", "configure")]
    [string]$Action = "status",

    [switch]$DryRun
)

# Load path resolver utility
. "$PSScriptRoot\common\PathResolver.ps1"

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    SourcePath = Get-ProjectPath "documentation-templates"
    LogPath = ".\sync-logs"
    SyncableFiles = @(
        "README_TEMPLATE.md"
        "CONTRIBUTING_TEMPLATE.md"
        "ARCHITECTURE_TEMPLATE.md"
        "API_TEMPLATE.md"
        "DOCUMENTATION_STANDARDS.md"
    )
    ExcludeRepos = @("Company-Information")
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Get-AllRepositories {
    try {
        $repos = gh repo list $Config.Organization --json name,url --limit 100 | ConvertFrom-Json
        if (-not $repos) {
            Write-Host "No repositories found. Check authentication." -ForegroundColor Red
            return @()
        }
        
        # Filter out excluded repositories
        $filteredRepos = $repos | Where-Object { $_.name -notin $Config.ExcludeRepos }
        return $filteredRepos
    }
    catch {
        Write-Host "Failed to fetch repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Test-SourceFiles {
    Write-Host "Validating source template files..." -ForegroundColor Yellow
    
    $allValid = $true
    
    foreach ($fileName in $Config.SyncableFiles) {
        $sourcePath = Join-Path $Config.SourcePath $fileName
        
        if (Test-Path $sourcePath) {
            $size = (Get-Item $sourcePath).Length
            Write-Host "[OK] $fileName ($size bytes)" -ForegroundColor Green
        } else {
            Write-Host "[MISSING] $fileName - File not found" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    return $allValid
}

function Show-SyncStatus {
    Write-Header "AI-Whisperers File Sync Status"
    
    if (-not (Test-SourceFiles)) {
        Write-Host "Source file validation failed. Cannot check status." -ForegroundColor Red
        return
    }
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    Write-Host "Template files available for sync:" -ForegroundColor Cyan
    foreach ($file in $Config.SyncableFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Target repositories:" -ForegroundColor Cyan
    foreach ($repo in $repos) {
        Write-Host "  - $($repo.name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "File sync system is ready for implementation." -ForegroundColor Green
    Write-Host "Note: Full GitHub API integration requires additional development." -ForegroundColor Yellow
}

function Show-Configuration {
    Write-Header "File Sync Configuration"
    
    Write-Host "Current configuration:" -ForegroundColor Cyan
    Write-Host "  Organization: $($Config.Organization)" -ForegroundColor Gray
    Write-Host "  Source Path: $($Config.SourcePath)" -ForegroundColor Gray
    Write-Host "  Log Path: $($Config.LogPath)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Syncable Files:" -ForegroundColor Cyan
    foreach ($file in $Config.SyncableFiles) {
        Write-Host "    $file" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Excluded Repositories:" -ForegroundColor Cyan
    foreach ($repo in $Config.ExcludeRepos) {
        Write-Host "    $repo" -ForegroundColor Gray
    }
}

# Main execution
switch ($Action.ToLower()) {
    "status" {
        Show-SyncStatus
    }
    "validate" {
        Write-Header "Source File Validation"
        $valid = Test-SourceFiles
        if ($valid) {
            Write-Host "All source files are valid and ready for synchronization" -ForegroundColor Green
        } else {
            Write-Host "Source file validation failed" -ForegroundColor Red
        }
    }
    "configure" {
        Show-Configuration
    }
    default {
        Write-Error "Invalid action: $Action. Use: status, validate, or configure"
    }
}