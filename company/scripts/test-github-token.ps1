# Test GitHub Token
# Get token from environment variable - set this before running the script
$token = $env:GITHUB_TOKEN
if (-not $token) {
    Write-Host "ERROR: GITHUB_TOKEN environment variable not set" -ForegroundColor Red
    Write-Host "Please set it using: `$env:GITHUB_TOKEN = 'your-token-here'" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nTesting GitHub API Connection..." -ForegroundColor Cyan

$headers = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github.v3+json"
}

try {
    # Test user endpoint
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get -TimeoutSec 10

    Write-Host "`n✅ GitHub Authentication Successful!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Gray
    Write-Host "User: $($user.login)" -ForegroundColor Yellow
    Write-Host "Name: $($user.name)" -ForegroundColor Yellow
    Write-Host "Email: $($user.email)" -ForegroundColor Yellow
    Write-Host "Public Repos: $($user.public_repos)" -ForegroundColor Yellow
    Write-Host "Created: $($user.created_at)" -ForegroundColor Yellow

    # Check rate limit
    $rateLimit = Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -Headers $headers -Method Get
    Write-Host "`nAPI Rate Limit:" -ForegroundColor Cyan
    Write-Host "  Remaining: $($rateLimit.rate.remaining)/$($rateLimit.rate.limit)" -ForegroundColor Gray

    # List organizations
    $orgs = Invoke-RestMethod -Uri "https://api.github.com/user/orgs" -Headers $headers -Method Get
    if ($orgs.Count -gt 0) {
        Write-Host "`nOrganizations:" -ForegroundColor Cyan
        foreach ($org in $orgs) {
            Write-Host "  - $($org.login)" -ForegroundColor Gray
        }
    }

    # Set environment variable for current session
    [Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $token, "Process")
    Write-Host "`n✅ GitHub token has been set for current session" -ForegroundColor Green

} catch {
    Write-Host "`n❌ GitHub Authentication Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "`nThe token appears to be invalid or expired." -ForegroundColor Yellow
        Write-Host "Please generate a new token at: https://github.com/settings/tokens" -ForegroundColor Yellow
    }
}