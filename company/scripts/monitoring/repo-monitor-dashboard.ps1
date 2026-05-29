# AI-Whisperers Repository Monitoring Dashboard
param(
    [Parameter(Position=0)]
    [ValidateSet("dashboard", "health", "activity", "issues", "summary")]
    [string]$View = "dashboard",
    
    [int]$Days = 7,
    [string]$Repository = "all",
    [switch]$Detailed,
    [switch]$VerboseLogging
)

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    OutputPath = ".\monitoring-reports"
    LogPath = ".\monitoring-logs"
    HealthThresholds = @{
        CommitsPerWeek = 3
        IssuesOpen = 10
        PRsOpen = 5
        LastActivityDays = 14
    }
}

# Initialize logging
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$logFile = Join-Path $Config.LogPath "repo-monitor-$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    
    # Write to console based on level
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "DEBUG" { if ($VerboseLogging) { Write-Host $logEntry -ForegroundColor Gray } }
        default { if ($VerboseLogging) { Write-Host $logEntry -ForegroundColor White } }
    }
    
    # Always write to log file
    try {
        $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Ensure output and log directories exist
try {
    if (-not (Test-Path $Config.OutputPath)) {
        New-Item -ItemType Directory -Path $Config.OutputPath -Force | Out-Null
        Write-Log "Created output directory: $($Config.OutputPath)" "DEBUG"
    }
    
    if (-not (Test-Path $Config.LogPath)) {
        New-Item -ItemType Directory -Path $Config.LogPath -Force | Out-Null
        Write-Log "Created log directory: $($Config.LogPath)" "DEBUG"
    }
    
    Write-Log "Starting repository monitoring - View: $View, Days: $Days, Repository: $Repository" "INFO"
}
catch {
    Write-Warning "Failed to create directories: $($_.Exception.Message)"
    exit 1
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Period: Last $Days days" -ForegroundColor Gray
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Get-AllRepositories {
    Write-Log "Fetching repositories from organization: $($Config.Organization)" "DEBUG"
    
    try {
        # Check GitHub CLI authentication first
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "GitHub CLI authentication failed" "ERROR"
            throw "GitHub CLI not authenticated. Run 'gh auth login' first."
        }
        
        Write-Log "GitHub CLI authentication verified" "DEBUG"
        
        # Fetch repositories
        $repos = gh repo list $Config.Organization --json name,url,description,isPrivate,pushedAt --limit 100 | ConvertFrom-Json
        
        if (-not $repos) {
            Write-Log "No repositories found in organization $($Config.Organization)" "WARN"
            Write-Host "No repositories found. Check organization name and access permissions." -ForegroundColor Yellow
            return @()
        }
        
        Write-Log "Successfully fetched $($repos.Count) repositories" "INFO"
        return $repos
    }
    catch {
        $errorMsg = "Failed to fetch repositories: $($_.Exception.Message)"
        Write-Log $errorMsg "ERROR"
        Write-Host $errorMsg -ForegroundColor Red
        return @()
    }
}

function Get-RepositoryActivity {
    param(
        [string]$RepoName,
        [int]$DaysBack = 7
    )
    
    Write-Log "Analyzing activity for repository: $RepoName" "DEBUG"
    $since = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    try {
        # Initialize result object
        $result = @{
            Repository = $RepoName
            Commits = 0
            OpenIssues = 0
            OpenPRs = 0
            Releases = 0
            LastActivity = $null
            Error = $null
        }
        
        # Get commits with error handling
        try {
            $commits = gh api "repos/$($Config.Organization)/$RepoName/commits" --field since=$since --jq '. | length' 2>$null
            $result.Commits = if ($commits) { [int]$commits } else { 0 }
            Write-Log "Commits for $RepoName (last $DaysBack days): $($result.Commits)" "DEBUG"
        }
        catch {
            Write-Log "Failed to fetch commits for $RepoName : $($_.Exception.Message)" "WARN"
        }
        
        # Get issues with error handling
        try {
            $issues = gh api "repos/$($Config.Organization)/$RepoName/issues" --field state=open --jq '. | length' 2>$null
            $result.OpenIssues = if ($issues) { [int]$issues } else { 0 }
            Write-Log "Open issues for $RepoName : $($result.OpenIssues)" "DEBUG"
        }
        catch {
            Write-Log "Failed to fetch issues for $RepoName : $($_.Exception.Message)" "WARN"
        }
        
        # Get pull requests with error handling  
        try {
            $prs = gh api "repos/$($Config.Organization)/$RepoName/pulls" --field state=open --jq '. | length' 2>$null
            $result.OpenPRs = if ($prs) { [int]$prs } else { 0 }
            Write-Log "Open PRs for $RepoName : $($result.OpenPRs)" "DEBUG"
        }
        catch {
            Write-Log "Failed to fetch PRs for $RepoName : $($_.Exception.Message)" "WARN"
        }
        
        # Get recent releases with error handling
        try {
            $releases = gh api "repos/$($Config.Organization)/$RepoName/releases" --jq '. | length' 2>$null
            $result.Releases = if ($releases) { [int]$releases } else { 0 }
            Write-Log "Releases for $RepoName : $($result.Releases)" "DEBUG"
        }
        catch {
            Write-Log "Failed to fetch releases for $RepoName : $($_.Exception.Message)" "WARN"
        }
        
        return $result
    }
    catch {
        $errorMsg = "Critical error analyzing $RepoName : $($_.Exception.Message)"
        Write-Log $errorMsg "ERROR"
        
        return @{
            Repository = $RepoName
            Commits = 0
            OpenIssues = 0
            OpenPRs = 0
            Releases = 0
            LastActivity = $null
            Error = $_.Exception.Message
        }
    }
}

function Get-RepositoryHealth {
    param($ActivityData)
    
    $healthScore = 100
    $issues = @()
    
    # Check commit activity
    if ($ActivityData.Commits -eq 0) {
        $healthScore -= 30
        $issues += "No commits in last $Days days"
    } elseif ($ActivityData.Commits -lt $Config.HealthThresholds.CommitsPerWeek) {
        $healthScore -= 15
        $issues += "Low commit activity"
    }
    
    # Check open issues
    if ($ActivityData.OpenIssues -gt $Config.HealthThresholds.IssuesOpen) {
        $healthScore -= 20
        $issues += "High number of open issues"
    }
    
    # Check open PRs
    if ($ActivityData.OpenPRs -gt $Config.HealthThresholds.PRsOpen) {
        $healthScore -= 15
        $issues += "High number of open PRs"
    }
    
    # Determine health level
    $healthLevel = if ($healthScore -ge 90) { "Excellent" }
                  elseif ($healthScore -ge 75) { "Good" }
                  elseif ($healthScore -ge 60) { "Fair" }
                  elseif ($healthScore -ge 40) { "Poor" }
                  else { "Critical" }
    
    return @{
        Score = $healthScore
        Level = $healthLevel
        Issues = $issues
        Color = switch ($healthLevel) {
            "Excellent" { "Green" }
            "Good" { "Cyan" }
            "Fair" { "Yellow" }
            "Poor" { "Magenta" }
            "Critical" { "Red" }
        }
    }
}

function Show-RepositoryDashboard {
    Write-Header "AI-Whisperers Repository Monitoring Dashboard"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    $filteredRepos = if ($Repository -ne "all") {
        $repos | Where-Object { $_.name -eq $Repository }
    } else {
        $repos
    }
    
    Write-Host "Repository Health Overview" -ForegroundColor Cyan
    Write-Host ("-" * 100) -ForegroundColor DarkGray
    Write-Host ""
    
    $format = "{0,-30} {1,-10} {2,-8} {3,-8} {4,-8} {5,-8} {6,-15}"
    Write-Host ($format -f "Repository", "Health", "Commits", "Issues", "PRs", "Rels", "Status") -ForegroundColor Yellow
    Write-Host ("-" * 100) -ForegroundColor DarkGray
    
    $allData = @()
    
    foreach ($repo in $filteredRepos) {
        Write-Host "Processing $($repo.name)..." -ForegroundColor Gray -NoNewline
        
        $activity = Get-RepositoryActivity -RepoName $repo.name -DaysBack $Days
        $health = Get-RepositoryHealth -ActivityData $activity
        $allData += @{ Repo = $repo; Activity = $activity; Health = $health }
        
        $repoName = if ($repo.name.Length -gt 29) { $repo.name.Substring(0, 29) } else { $repo.name }
        
        Write-Host "`r" -NoNewline
        Write-Host ($format -f 
            $repoName,
            $health.Level,
            $activity.Commits,
            $activity.OpenIssues,
            $activity.OpenPRs,
            $activity.Releases,
            $(if ($activity.Error) { "Error" } else { "OK" })
        ) -ForegroundColor $health.Color
        
        if ($Detailed -and $health.Issues.Count -gt 0) {
            foreach ($issue in $health.Issues) {
                Write-Host "    ! $issue" -ForegroundColor Yellow
            }
        }
    }
    
    # Summary statistics
    Write-Host ("-" * 100) -ForegroundColor DarkGray
    
    $totalCommits = ($allData | ForEach-Object { $_.Activity.Commits } | Measure-Object -Sum).Sum
    $totalIssues = ($allData | ForEach-Object { $_.Activity.OpenIssues } | Measure-Object -Sum).Sum
    $totalPRs = ($allData | ForEach-Object { $_.Activity.OpenPRs } | Measure-Object -Sum).Sum
    $avgHealth = ($allData | ForEach-Object { $_.Health.Score } | Measure-Object -Average).Average
    
    Write-Host ($format -f "TOTALS", "", $totalCommits, $totalIssues, $totalPRs, "", "") -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Organization Summary:" -ForegroundColor Cyan
    Write-Host "  Repositories monitored: $($allData.Count)" -ForegroundColor Gray
    Write-Host "  Total commits (last $Days days): $totalCommits" -ForegroundColor Gray
    Write-Host "  Total open issues: $totalIssues" -ForegroundColor Gray
    Write-Host "  Total open PRs: $totalPRs" -ForegroundColor Gray
    Write-Host "  Average health score: $([math]::Round($avgHealth, 1))%" -ForegroundColor Gray
    
    $healthDistribution = $allData | Group-Object { $_.Health.Level }
    Write-Host "  Health distribution:" -ForegroundColor Gray
    foreach ($group in $healthDistribution) {
        Write-Host "    $($group.Name): $($group.Count) repositories" -ForegroundColor Gray
    }
}

function Show-RepositoryHealth {
    Write-Header "AI-Whisperers Repository Health Analysis"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    $unhealthyRepos = @()
    
    foreach ($repo in $repos) {
        $activity = Get-RepositoryActivity -RepoName $repo.name -DaysBack $Days
        $health = Get-RepositoryHealth -ActivityData $activity
        
        if ($health.Score -lt 75) {  # Focus on repos that need attention
            $unhealthyRepos += @{
                Name = $repo.name
                Health = $health
                Activity = $activity
            }
        }
    }
    
    if ($unhealthyRepos.Count -eq 0) {
        Write-Host "All repositories are in good health!" -ForegroundColor Green
        return
    }
    
    Write-Host "Repositories requiring attention:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($repo in ($unhealthyRepos | Sort-Object { $_.Health.Score })) {
        Write-Host "$($repo.Name) - $($repo.Health.Level) ($($repo.Health.Score)%)" -ForegroundColor $repo.Health.Color
        
        foreach ($issue in $repo.Health.Issues) {
            Write-Host "  ! $issue" -ForegroundColor Yellow
        }
        
        Write-Host "  Activity: $($repo.Activity.Commits) commits, $($repo.Activity.OpenIssues) issues, $($repo.Activity.OpenPRs) PRs" -ForegroundColor Gray
        Write-Host ""
    }
}

function Show-ActivitySummary {
    Write-Header "AI-Whisperers Activity Summary"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    Write-Host "Most Active Repositories (by commits):" -ForegroundColor Cyan
    
    $activityData = @()
    foreach ($repo in $repos) {
        $activity = Get-RepositoryActivity -RepoName $repo.name -DaysBack $Days
        $activityData += $activity
    }
    
    $sortedByCommits = $activityData | Sort-Object Commits -Descending | Select-Object -First 10
    
    foreach ($repo in $sortedByCommits) {
        if ($repo.Commits -gt 0) {
            Write-Host "  $($repo.Repository): $($repo.Commits) commits" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "Repositories with most open issues:" -ForegroundColor Cyan
    
    $sortedByIssues = $activityData | Where-Object { $_.OpenIssues -gt 0 } | Sort-Object OpenIssues -Descending | Select-Object -First 5
    
    foreach ($repo in $sortedByIssues) {
        Write-Host "  $($repo.Repository): $($repo.OpenIssues) open issues" -ForegroundColor Yellow
    }
}

function Generate-MonitoringReport {
    Write-Header "Generating Monitoring Report"
    
    $repos = Get-AllRepositories
    $reportData = @()
    
    foreach ($repo in $repos) {
        $activity = Get-RepositoryActivity -RepoName $repo.name -DaysBack $Days
        $health = Get-RepositoryHealth -ActivityData $activity
        
        $reportData += [PSCustomObject]@{
            Repository = $repo.name
            HealthScore = $health.Score
            HealthLevel = $health.Level
            Commits = $activity.Commits
            OpenIssues = $activity.OpenIssues
            OpenPRs = $activity.OpenPRs
            Releases = $activity.Releases
            Issues = ($health.Issues -join "; ")
        }
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $csvPath = Join-Path $Config.OutputPath "monitoring-report-$timestamp.csv"
    
    $reportData | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "Report generated: $csvPath" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Report Summary:" -ForegroundColor Cyan
    Write-Host "  Repositories: $($reportData.Count)" -ForegroundColor Gray
    Write-Host "  Average health: $([math]::Round(($reportData | Measure-Object HealthScore -Average).Average, 1))%" -ForegroundColor Gray
    Write-Host "  Total commits: $(($reportData | Measure-Object Commits -Sum).Sum)" -ForegroundColor Gray
}

# Main execution
switch ($View.ToLower()) {
    "dashboard" {
        Show-RepositoryDashboard
    }
    "health" {
        Show-RepositoryHealth
    }
    "activity" {
        Show-ActivitySummary
    }
    "issues" {
        Write-Header "Repository Issues Overview"
        Write-Host "This feature will show detailed issue analysis." -ForegroundColor Yellow
        Write-Host "Implementation pending..." -ForegroundColor Gray
    }
    "summary" {
        Generate-MonitoringReport
    }
    default {
        Write-Error "Invalid view: $View. Use: dashboard, health, activity, issues, or summary"
    }
}