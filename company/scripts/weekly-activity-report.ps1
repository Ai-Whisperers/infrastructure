# Weekly Activity Report for Ai-Whisperers Organization
# Generates a comprehensive weekly summary of all activity

param(
    [int]$Days = 7
)

Write-Host "=== AI-Whisperers Weekly Activity Report ===" -ForegroundColor Cyan
Write-Host "Report Period: $(Get-Date).AddDays(-$Days).ToString('yyyy-MM-dd') to $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get all repositories
$repos = gh repo list Ai-Whisperers --json name,url,updatedAt,stargazerCount,forkCount --limit 100 | ConvertFrom-Json

if (-not $repos) {
    Write-Host "No repositories found or authentication required. Run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

$since = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
$totalCommits = 0
$totalPRs = 0
$totalIssues = 0
$activeRepos = @()
$topContributors = @{}

Write-Host "📊 COMMIT ACTIVITY" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

foreach ($repo in $repos) {
    $repoName = $repo.name
    
    try {
        # Get commits
        $commits = gh api "repos/Ai-Whisperers/$repoName/commits" --field since=$since --jq '. | length' 2>$null
        
        # Get PRs
        $prs = gh api "repos/Ai-Whisperers/$repoName/pulls" --field state=all --field since=$since --jq '. | length' 2>$null
        
        # Get Issues
        $issues = gh api "repos/Ai-Whisperers/$repoName/issues" --field state=all --field since=$since --jq '. | length' 2>$null
        
        if ($commits -and $commits -gt 0) {
            $totalCommits += $commits
            $totalPRs += if ($prs) { $prs } else { 0 }
            $totalIssues += if ($issues) { $issues } else { 0 }
            
            $activeRepos += @{
                Name = $repoName
                Commits = $commits
                PRs = if ($prs) { $prs } else { 0 }
                Issues = if ($issues) { $issues } else { 0 }
                Stars = $repo.stargazerCount
                Forks = $repo.forkCount
                URL = $repo.url
            }
            
            Write-Host "📁 $repoName" -ForegroundColor White
            Write-Host "   ├── Commits: $commits" -ForegroundColor Gray
            Write-Host "   ├── Pull Requests: $(if ($prs) { $prs } else { 0 })" -ForegroundColor Gray
            Write-Host "   ├── Issues: $(if ($issues) { $issues } else { 0 })" -ForegroundColor Gray
            Write-Host "   └── ⭐ $($repo.stargazerCount) stars, 🍴 $($repo.forkCount) forks" -ForegroundColor Gray
            
            # Get top contributors for this repo
            $contributors = gh api "repos/Ai-Whisperers/$repoName/commits" --field since=$since --jq '.[].commit.author.name' 2>$null
            if ($contributors) {
                $contributors | ForEach-Object {
                    if ($topContributors.ContainsKey($_)) {
                        $topContributors[$_]++
                    } else {
                        $topContributors[$_] = 1
                    }
                }
            }
            Write-Host ""
        }
    }
    catch {
        # Silent fail for repos we can't access
    }
}

Write-Host ""
Write-Host "📈 TOP CONTRIBUTORS" -ForegroundColor Green  
Write-Host "==================" -ForegroundColor Green

if ($topContributors.Count -gt 0) {
    $sortedContributors = $topContributors.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
    
    foreach ($contributor in $sortedContributors) {
        $commits = $contributor.Value
        Write-Host "👤 $($contributor.Key): $commits commit$(if($commits -ne 1){'s'})" -ForegroundColor White
    }
} else {
    Write-Host "No contributor data available" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 REPOSITORY SUMMARY" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

# Sort repos by activity
$sortedRepos = $activeRepos | Sort-Object Commits -Descending

Write-Host "Most Active Repositories:" -ForegroundColor White
foreach ($repo in $sortedRepos | Select-Object -First 5) {
    Write-Host "  • $($repo.Name): $($repo.Commits) commits" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 OVERALL STATISTICS" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

Write-Host "Total Commits: $totalCommits" -ForegroundColor White
Write-Host "Total Pull Requests: $totalPRs" -ForegroundColor White  
Write-Host "Total Issues: $totalIssues" -ForegroundColor White
Write-Host "Active Repositories: $($activeRepos.Count)" -ForegroundColor White
Write-Host "Total Repositories: $($repos.Count)" -ForegroundColor White

$totalStars = ($repos | Measure-Object -Property stargazerCount -Sum).Sum
$totalForks = ($repos | Measure-Object -Property forkCount -Sum).Sum

Write-Host "Organization Stars: $totalStars ⭐" -ForegroundColor White
Write-Host "Organization Forks: $totalForks 🍴" -ForegroundColor White

# Calculate daily average
$dailyAvg = [math]::Round($totalCommits / $Days, 1)
Write-Host "Daily Commit Average: $dailyAvg" -ForegroundColor White

Write-Host ""
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray