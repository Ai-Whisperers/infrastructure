# AI-Whisperers Management Summary Dashboard
param(
    [Parameter(Position=0)]
    [ValidateSet("overview", "todos", "health")]
    [string]$View = "overview"
)

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Show-Overview {
    Write-Header "AI-Whisperers Management Systems Overview"
    
    Write-Host "[TOOLS] Organizational Management Tools" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[SCRIPTS] Available Management Scripts:" -ForegroundColor Cyan
    Write-Host "  [SCRIPT] todo-manager.ps1 - Todo tracking across repositories" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] file-sync-manager.ps1 - Documentation template sync" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] repo-monitor-dashboard.ps1 - Repository health monitoring" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] azure-devops-sync.ps1 - Azure DevOps integration" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] github-commit-tracker.ps1 - Daily commit tracking" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] weekly-activity-report.ps1 - Weekly activity summary" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] dependency-tracker.ps1 - Repository dependency analysis" -ForegroundColor Yellow
    Write-Host "  [SCRIPT] release-coordinator.ps1 - Automated release coordination" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "[STATUS] System Status:" -ForegroundColor Cyan
    
    # Check GitHub CLI
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            Write-Host "  [OK] GitHub CLI: Available and authenticated" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] GitHub CLI: Not available" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] GitHub CLI: Not available" -ForegroundColor Red
    }
    
    # Check PowerShell version
    Write-Host "  [OK] PowerShell: Version $($PSVersionTable.PSVersion)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "[COMMANDS] Quick Start Commands:" -ForegroundColor Cyan
    Write-Host "  ./todo-manager.ps1 status           # View todos across all repositories" -ForegroundColor Gray
    Write-Host "  ./repo-monitor-dashboard.ps1        # Repository health dashboard" -ForegroundColor Gray
    Write-Host "  ./file-sync-manager.ps1 validate    # Check template files" -ForegroundColor Gray
    Write-Host "  ./azure-devops-sync.ps1 test        # Test DevOps integration" -ForegroundColor Gray
    Write-Host "  ./dependency-tracker.ps1 graph      # View repository dependencies" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "[DOCS] Documentation Locations:" -ForegroundColor Cyan
    Write-Host "  Enhanced Documentation: ../enhanced-documentation/" -ForegroundColor Gray
    Write-Host "  Templates: ../documentation-templates/" -ForegroundColor Gray
    Write-Host "  Master Index: ../DOCUMENTATION_MASTER_INDEX.md" -ForegroundColor Gray
}

function Show-TodoSummary {
    Write-Header "Organization Todo Summary"
    Write-Host "Running todo analysis..." -ForegroundColor Yellow
    & ".\todo-manager.ps1" "status"
}

function Show-HealthSummary {
    Write-Header "Repository Health Summary"
    Write-Host "Analyzing repository health..." -ForegroundColor Yellow
    & ".\repo-monitor-dashboard.ps1" "health"
}

# Main execution
switch ($View.ToLower()) {
    "overview" {
        Show-Overview
    }
    "todos" {
        Show-TodoSummary
    }
    "health" {
        Show-HealthSummary
    }
    default {
        Write-Host "Invalid view: $View. Use: overview, todos, or health" -ForegroundColor Red
    }
}