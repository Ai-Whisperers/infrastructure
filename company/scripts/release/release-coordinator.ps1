# AI-Whisperers Release Coordination System
param(
    [Parameter(Position=0)]
    [ValidateSet("status", "plan", "prepare", "execute", "rollback")]
    [string]$Action = "status",
    
    [string]$Version = "",
    [string]$Repository = "all",
    [switch]$DryRun
)

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    OutputPath = ".\release-reports"
    # Define release order based on dependencies
    ReleaseOrder = @(
        "AI-Investment",                      # Production investment platform
        "Comment-Analyzer",                   # Production analysis tool
        "clockify-ADO-automated-report",      # Production automation tool
        "AI-Whisperers-website-and-courses", # Strategic platform
        "AI-Whisperers",                      # Standards and templates
        "WPG-Amenities"                       # Assessment project
    )
    # Pre-release validation requirements
    ValidationRequirements = @{
        "AI-Investment" = @{
            RequiredTests = @("unit", "integration", "api", "frontend")
            RequiredChecks = @("lint", "typecheck", "security", "build")
            MinHealthScore = 90
            MaxOpenIssues = 2
        }
        "Comment-Analyzer" = @{
            RequiredTests = @("unit", "integration")
            RequiredChecks = @("lint", "security", "ai-api-test")
            MinHealthScore = 85
            MaxOpenIssues = 3
        }
        "clockify-ADO-automated-report" = @{
            RequiredTests = @("unit", "integration", "cli")
            RequiredChecks = @("lint", "architecture-validation", "api-test")
            MinHealthScore = 85
            MaxOpenIssues = 3
        }
        "AI-Whisperers-website-and-courses" = @{
            RequiredTests = @("unit", "e2e")
            RequiredChecks = @("lint", "typecheck", "build")
            MinHealthScore = 80
            MaxOpenIssues = 5
        }
        "AI-Whisperers" = @{
            RequiredTests = @("template-validation")
            RequiredChecks = @("standards-compliance", "format")
            MinHealthScore = 95
            MaxOpenIssues = 1
        }
        "WPG-Amenities" = @{
            RequiredTests = @("unit")
            RequiredChecks = @("lint", "basic-functionality")
            MinHealthScore = 70
            MaxOpenIssues = 10
        }
    }
}

# Ensure output directory exists
if (-not (Test-Path $Config.OutputPath)) {
    New-Item -ItemType Directory -Path $Config.OutputPath -Force | Out-Null
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    }
    Write-Host ""
}

function Get-AllRepositories {
    try {
        $repos = gh repo list $Config.Organization --json name,url,description --limit 100 | ConvertFrom-Json
        if (-not $repos) {
            Write-Host "No repositories found. Check authentication." -ForegroundColor Red
            return @()
        }
        return $repos
    }
    catch {
        Write-Host "Failed to fetch repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-RepositoryHealth {
    param([string]$RepoName)
    
    try {
        # Get recent activity
        $since = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $commits = gh api "repos/$($Config.Organization)/$RepoName/commits" --field since=$since --jq '. | length' 2>$null
        if (-not $commits) { $commits = 0 }
        
        $issues = gh api "repos/$($Config.Organization)/$RepoName/issues" --field state=open --jq '. | length' 2>$null
        if (-not $issues) { $issues = 0 }
        
        $prs = gh api "repos/$($Config.Organization)/$RepoName/pulls" --field state=open --jq '. | length' 2>$null
        if (-not $prs) { $prs = 0 }
        
        # Calculate health score
        $healthScore = 100
        if ([int]$commits -eq 0) { $healthScore -= 20 }
        if ([int]$issues -gt 5) { $healthScore -= 15 }
        if ([int]$prs -gt 3) { $healthScore -= 10 }
        
        return @{
            Repository = $RepoName
            HealthScore = $healthScore
            Commits = [int]$commits
            OpenIssues = [int]$issues
            OpenPRs = [int]$prs
            Status = if ($healthScore -ge 90) { "Ready" } elseif ($healthScore -ge 70) { "Warning" } else { "Not Ready" }
        }
    }
    catch {
        return @{
            Repository = $RepoName
            HealthScore = 0
            Status = "Error"
            Error = $_.Exception.Message
        }
    }
}

function Get-LatestRelease {
    param([string]$RepoName)
    
    try {
        $release = gh api "repos/$($Config.Organization)/$RepoName/releases/latest" 2>$null | ConvertFrom-Json
        if ($release) {
            return @{
                Version = $release.tag_name
                Date = [DateTime]::Parse($release.published_at)
                Draft = $release.draft
                Prerelease = $release.prerelease
            }
        }
    }
    catch {
        # No releases found
    }
    
    return @{
        Version = "None"
        Date = [DateTime]::MinValue
        Draft = $false
        Prerelease = $false
    }
}

function Show-ReleaseStatus {
    Write-Header "AI-Whisperers Release Status"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    Write-Host "Repository Release Readiness:" -ForegroundColor Cyan
    Write-Host ("-" * 90) -ForegroundColor DarkGray
    Write-Host ""
    
    $format = "{0,-20} {1,-12} {2,-15} {3,-10} {4,-10} {5,-15}"
    Write-Host ($format -f "Repository", "Status", "Latest Release", "Health", "Issues", "PRs") -ForegroundColor Yellow
    Write-Host ("-" * 90) -ForegroundColor DarkGray
    
    $releaseData = @()
    
    foreach ($repo in $repos) {
        if ($Repository -ne "all" -and $repo.name -ne $Repository) { continue }
        
        $health = Get-RepositoryHealth -RepoName $repo.name
        $release = Get-LatestRelease -RepoName $repo.name
        
        $releaseData += @{
            Repo = $repo.name
            Health = $health
            Release = $release
        }
        
        $statusColor = switch ($health.Status) {
            "Ready" { "Green" }
            "Warning" { "Yellow" }
            "Not Ready" { "Red" }
            default { "Gray" }
        }
        
        Write-Host ($format -f 
            $repo.name,
            $health.Status,
            $release.Version,
            "$($health.HealthScore)%",
            $health.OpenIssues,
            $health.OpenPRs
        ) -ForegroundColor $statusColor
    }
    
    Write-Host ("-" * 90) -ForegroundColor DarkGray
    
    # Summary
    $readyCount = ($releaseData | Where-Object { $_.Health.Status -eq "Ready" }).Count
    $totalCount = $releaseData.Count
    
    Write-Host ""
    Write-Host "Release Readiness Summary:" -ForegroundColor Cyan
    Write-Host "  Ready for release: $readyCount/$totalCount repositories" -ForegroundColor Gray
    Write-Host "  Average health score: $([math]::Round(($releaseData | ForEach-Object { $_.Health.HealthScore } | Measure-Object -Average).Average, 1))%" -ForegroundColor Gray
    
    if ($readyCount -eq $totalCount) {
        Write-Host "  [OK] All repositories are ready for release!" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Some repositories need attention before release" -ForegroundColor Yellow
        $notReady = $releaseData | Where-Object { $_.Health.Status -ne "Ready" }
        foreach ($repo in $notReady) {
            Write-Host "    - $($repo.Repo.name): $($repo.Health.Status)" -ForegroundColor Gray
        }
    }
}

function Create-ReleasePlan {
    Write-Header "Release Plan Creation"
    
    if (-not $Version) {
        Write-Host "Version number required for release planning. Use -Version parameter." -ForegroundColor Red
        return
    }
    
    Write-Host "Creating release plan for version: $Version" -ForegroundColor Yellow
    Write-Host ""
    
    $repos = Get-AllRepositories
    $releaseableRepos = $repos | Where-Object { $_.name -in $Config.ReleaseOrder }
    
    Write-Host "Planned Release Order:" -ForegroundColor Cyan
    
    $step = 1
    foreach ($repoName in $Config.ReleaseOrder) {
        $repo = $releaseableRepos | Where-Object { $_.name -eq $repoName }
        if ($repo) {
            $health = Get-RepositoryHealth -RepoName $repo.name
            $requirements = $Config.ValidationRequirements[$repo.name]
            
            Write-Host "Step ${step}: $($repo.name)" -ForegroundColor Yellow
            Write-Host "  Current health: $($health.HealthScore)% ($($health.Status))" -ForegroundColor Gray
            Write-Host "  Required health: $($requirements.MinHealthScore)%" -ForegroundColor Gray
            Write-Host "  Max open issues: $($requirements.MaxOpenIssues) (current: $($health.OpenIssues))" -ForegroundColor Gray
            Write-Host "  Required tests: $($requirements.RequiredTests -join ', ')" -ForegroundColor Gray
            Write-Host "  Required checks: $($requirements.RequiredChecks -join ', ')" -ForegroundColor Gray
            
            $canRelease = $health.HealthScore -ge $requirements.MinHealthScore -and $health.OpenIssues -le $requirements.MaxOpenIssues
            Write-Host "  Release ready: $(if ($canRelease) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($canRelease) { "Green" } else { "Red" })
            Write-Host ""
            
            $step++
        }
    }
    
    # Generate release checklist
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $checklistPath = Join-Path $Config.OutputPath "release-checklist-v$Version-$timestamp.md"
    
    $checklist = @"
# Release Checklist - Version $Version
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Pre-Release Validation

$($Config.ReleaseOrder | ForEach-Object {
$repoName = $_
$requirements = $Config.ValidationRequirements[$repoName]
@"

### $repoName
- [ ] Health score >= $($requirements.MinHealthScore)%
- [ ] Open issues <= $($requirements.MaxOpenIssues)
- [ ] All required tests passing: $($requirements.RequiredTests -join ', ')
- [ ] All required checks passing: $($requirements.RequiredChecks -join ', ')
- [ ] Dependencies up to date
- [ ] Documentation updated
- [ ] Version tagged: v$Version

"@
})

## Release Execution Order

1. **AI-Investment** - Production investment platform (highest priority)
2. **Comment-Analyzer** - Production analysis tool
3. **clockify-ADO-automated-report** - Production automation tool
4. **AI-Whisperers-website-and-courses** - Strategic platform development
5. **AI-Whisperers** - Standards and templates (organizational)
6. **WPG-Amenities** - Assessment project (lowest priority)

## Post-Release Verification

- [ ] All services responding correctly
- [ ] Health checks passing
- [ ] Monitoring dashboards green
- [ ] User acceptance testing complete
- [ ] Release notes published
- [ ] Team notified

## Rollback Plan

If issues are discovered:
1. Stop deployment process immediately
2. Revert to previous version using: ``.\release-coordinator.ps1 rollback -Version [previous-version]``
3. Verify all services are stable
4. Investigate and fix issues
5. Plan next release attempt
"@
    
    $checklist | Out-File -FilePath $checklistPath -Encoding UTF8
    Write-Host "Release checklist created: $checklistPath" -ForegroundColor Green
}

function Prepare-Release {
    Write-Header "Release Preparation"
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would perform the following preparation steps:" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "1. Validate all repository health scores" -ForegroundColor Gray
        Write-Host "2. Run pre-release tests on all repositories" -ForegroundColor Gray
        Write-Host "3. Create release branches where needed" -ForegroundColor Gray
        Write-Host "4. Update version numbers in package files" -ForegroundColor Gray
        Write-Host "5. Generate release notes from commit history" -ForegroundColor Gray
        Write-Host "6. Create draft releases in GitHub" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Note: Full implementation requires additional development" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Release preparation is not yet fully implemented." -ForegroundColor Yellow
    Write-Host "Use --DryRun to see what would be prepared." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Manual preparation steps:" -ForegroundColor Cyan
    Write-Host "1. Run: ./repo-monitor-dashboard.ps1 health" -ForegroundColor Gray
    Write-Host "2. Run: ./dependency-tracker.ps1 validate" -ForegroundColor Gray
    Write-Host "3. Ensure all tests are passing in each repository" -ForegroundColor Gray
    Write-Host "4. Review and merge any pending critical PRs" -ForegroundColor Gray
}

function Execute-Release {
    Write-Header "Release Execution"
    
    if (-not $Version) {
        Write-Host "Version number required for release execution. Use -Version parameter." -ForegroundColor Red
        return
    }
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would execute release for version $Version in this order:" -ForegroundColor Magenta
        Write-Host ""
        
        $step = 1
        foreach ($repo in $Config.ReleaseOrder) {
            Write-Host "Step ${step}: Release $repo v$Version" -ForegroundColor Gray
            Write-Host "  - Create release tag" -ForegroundColor DarkGray
            Write-Host "  - Trigger CI/CD pipeline" -ForegroundColor DarkGray
            Write-Host "  - Wait for deployment confirmation" -ForegroundColor DarkGray
            Write-Host "  - Verify health checks" -ForegroundColor DarkGray
            $step++
        }
        
        Write-Host ""
        Write-Host "Note: Actual release execution requires additional development" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Automated release execution is not yet implemented." -ForegroundColor Yellow
    Write-Host "Use --DryRun to see the planned execution order." -ForegroundColor Gray
}

function Rollback-Release {
    Write-Header "Release Rollback"
    
    if (-not $Version) {
        Write-Host "Version number required for rollback. Use -Version parameter." -ForegroundColor Red
        return
    }
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would rollback to version $Version in reverse order:" -ForegroundColor Magenta
        Write-Host ""
        
        $step = 1
        $reverseOrder = $Config.ReleaseOrder | Sort-Object { $Config.ReleaseOrder.IndexOf($_) } -Descending
        
        foreach ($repo in $reverseOrder) {
            Write-Host "Step ${step}: Rollback $repo to v$Version" -ForegroundColor Gray
            Write-Host "  - Revert to previous release tag" -ForegroundColor DarkGray
            Write-Host "  - Trigger rollback deployment" -ForegroundColor DarkGray
            Write-Host "  - Verify service stability" -ForegroundColor DarkGray
            $step++
        }
        
        Write-Host ""
        Write-Host "Note: Automated rollback requires additional development" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Automated rollback is not yet implemented." -ForegroundColor Yellow
    Write-Host "Use --DryRun to see the planned rollback order." -ForegroundColor Gray
}

# Main execution
switch ($Action.ToLower()) {
    "status" {
        Show-ReleaseStatus
    }
    "plan" {
        Create-ReleasePlan
    }
    "prepare" {
        Prepare-Release
    }
    "execute" {
        Execute-Release
    }
    "rollback" {
        Rollback-Release
    }
    default {
        Write-Error "Invalid action: $Action. Use: status, plan, prepare, execute, or rollback"
    }
}