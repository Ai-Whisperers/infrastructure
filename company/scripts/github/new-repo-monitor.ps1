# New Repository Monitor for Ai-Whisperers Organization
# Checks for new repositories created in the last N days

param(
    [int]$Days = 7
)

Write-Host "=== AI-Whisperers New Repository Monitor ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Checking for repositories created in the last $Days day(s)" -ForegroundColor Gray
Write-Host ""

# Get all repositories with creation dates
$repos = gh repo list Ai-Whisperers --json name,url,createdAt,description,isPrivate --limit 100 | ConvertFrom-Json

if (-not $repos) {
    Write-Host "No repositories found or authentication required. Run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

$cutoffDate = (Get-Date).AddDays(-$Days)
$newRepos = @()

foreach ($repo in $repos) {
    $createdDate = [DateTime]::Parse($repo.createdAt)
    
    if ($createdDate -ge $cutoffDate) {
        $newRepos += $repo
    }
}

if ($newRepos.Count -eq 0) {
    Write-Host "🔍 No new repositories found in the last $Days day(s)" -ForegroundColor Yellow
} else {
    Write-Host "🆕 Found $($newRepos.Count) new repositor$(if($newRepos.Count -ne 1){'ies'}):" -ForegroundColor Green
    Write-Host ""
    
    foreach ($repo in $newRepos) {
        $createdDate = [DateTime]::Parse($repo.createdAt).ToString("yyyy-MM-dd HH:mm")
        $privacy = if ($repo.isPrivate) { "🔒 Private" } else { "🌍 Public" }
        
        Write-Host "📁 $($repo.name)" -ForegroundColor Green
        Write-Host "   └── Created: $createdDate" -ForegroundColor White
        Write-Host "   └── Privacy: $privacy" -ForegroundColor White
        
        if ($repo.description) {
            $description = $repo.description
            if ($description.Length -gt 80) { $description = $description.Substring(0, 77) + "..." }
            Write-Host "   └── Description: $description" -ForegroundColor Gray
        }
        
        Write-Host "   └── URL: $($repo.url)" -ForegroundColor Blue
        Write-Host ""
    }
}

# Also check for repositories that might need initial setup
Write-Host "=== Repository Status Check ===" -ForegroundColor Cyan

foreach ($repo in $newRepos) {
    $repoName = $repo.name
    try {
        # Check if repo has any commits
        $commits = gh api "repos/Ai-Whisperers/$repoName/commits" --jq '. | length' 2>$null
        
        if (-not $commits -or $commits -eq 0) {
            Write-Host "⚠️  $repoName appears to be empty (no commits)" -ForegroundColor Yellow
        }
        
        # Check for README
        $readme = gh api "repos/Ai-Whisperers/$repoName/readme" 2>$null
        if (-not $readme) {
            Write-Host "📝 $repoName might need a README file" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host "⚠️  Could not check status for $repoName" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray