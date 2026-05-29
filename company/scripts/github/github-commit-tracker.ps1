# GitHub Commit Tracker for Ai-Whisperers Organization
# Run this daily to get a summary of recent commits across all repositories

param(
    [int]$Days = 1
)

Write-Host "=== AI-Whisperers Daily Commit Summary ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Looking back $Days day(s)" -ForegroundColor Gray
Write-Host ""

# Get all repositories in the organization
$repos = gh repo list Ai-Whisperers --json name,url --limit 100 | ConvertFrom-Json

if (-not $repos) {
    Write-Host "No repositories found or authentication required. Run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

$totalCommits = 0
$activeRepos = @()

foreach ($repo in $repos) {
    $repoName = $repo.name
    $since = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    try {
        # Get commits from the last N days
        $commits = gh api "repos/Ai-Whisperers/$repoName/commits" --field since=$since --jq '. | length' 2>$null
        
        if ($commits -and $commits -gt 0) {
            $totalCommits += $commits
            $activeRepos += @{
                Name = $repoName
                Commits = $commits
                URL = $repo.url
            }
            
            Write-Host "📁 $repoName" -ForegroundColor Green
            Write-Host "   └── $commits commit$(if($commits -ne 1){'s'}) in last $Days day$(if($Days -ne 1){'s'})" -ForegroundColor White
            
            # Get latest commit details
            $latestCommit = gh api "repos/Ai-Whisperers/$repoName/commits" --field per_page=1 --jq '.[0] | {message: .commit.message, author: .commit.author.name, date: .commit.author.date, url: .html_url}' 2>$null | ConvertFrom-Json
            
            if ($latestCommit) {
                $commitDate = [DateTime]::Parse($latestCommit.date).ToString("MM/dd HH:mm")
                $message = ($latestCommit.message -split "`n")[0]  # First line only
                if ($message.Length -gt 60) { $message = $message.Substring(0, 57) + "..." }
                
                Write-Host "   └── Latest: $message" -ForegroundColor Gray
                Write-Host "       by $($latestCommit.author) on $commitDate" -ForegroundColor Gray
            }
            Write-Host ""
        }
    }
    catch {
        Write-Host "⚠️  Could not fetch commits for $repoName" -ForegroundColor Yellow
    }
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total commits across all repositories: $totalCommits" -ForegroundColor White
Write-Host "Active repositories: $($activeRepos.Count)" -ForegroundColor White

if ($activeRepos.Count -eq 0) {
    Write-Host "No commits found in the last $Days day$(if($Days -ne 1){'s'})" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray