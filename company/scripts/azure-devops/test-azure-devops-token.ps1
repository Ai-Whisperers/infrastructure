# Test Azure DevOps Token
# Get PAT from environment variable - set this before running the script
$pat = $env:AZURE_DEVOPS_PAT
if (-not $pat) {
    Write-Host "ERROR: AZURE_DEVOPS_PAT environment variable not set" -ForegroundColor Red
    Write-Host "Please set it using: `$env:AZURE_DEVOPS_PAT = 'your-token-here'" -ForegroundColor Yellow
    exit 1
}
$org = "AI-Whisperers"
$project = "Company-Information"

Write-Host "`nTesting Azure DevOps API Connection..." -ForegroundColor Cyan

# Create authorization header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    'Content-Type' = 'application/json'
}

try {
    # Test connection with projects endpoint
    $uri = "https://dev.azure.com/$org/_apis/projects?api-version=7.0"
    $projects = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 10

    Write-Host "`n✅ Azure DevOps Authentication Successful!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Gray
    Write-Host "Organization: $org" -ForegroundColor Yellow
    Write-Host "Projects Found: $($projects.count)" -ForegroundColor Yellow

    # List projects
    if ($projects.count -gt 0) {
        Write-Host "`nProjects:" -ForegroundColor Cyan
        foreach ($proj in $projects.value) {
            Write-Host "  - $($proj.name)" -ForegroundColor Gray
            if ($proj.description) {
                Write-Host "    $($proj.description)" -ForegroundColor DarkGray
            }
        }
    }

    # Try to get work items from the specific project
    $wiUri = "https://dev.azure.com/$org/$project/_apis/wit/workitems?api-version=7.0&`$top=5"
    try {
        $workItems = Invoke-RestMethod -Uri $wiUri -Headers $headers -Method Get -TimeoutSec 10 -ErrorAction SilentlyContinue
        Write-Host "`nWork Items Access: ✅ Verified" -ForegroundColor Green
    } catch {
        Write-Host "`nWork Items Access: Project may not exist or no work items" -ForegroundColor Yellow
    }

    # Set environment variables for current session
    [Environment]::SetEnvironmentVariable("AZURE_DEVOPS_PAT", $pat, "Process")
    [Environment]::SetEnvironmentVariable("AZURE_DEVOPS_ORG", $org, "Process")
    [Environment]::SetEnvironmentVariable("AZURE_DEVOPS_PROJECT", $project, "Process")
    [Environment]::SetEnvironmentVariable("AZURE_DEVOPS_BASE_URL", "https://dev.azure.com/$org", "Process")

    Write-Host "`n✅ Azure DevOps environment variables set for current session" -ForegroundColor Green

} catch {
    Write-Host "`n❌ Azure DevOps Authentication Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "`nThe PAT appears to be invalid or expired." -ForegroundColor Yellow
        Write-Host "Please generate a new token at: https://dev.azure.com/$org/_usersSettings/tokens" -ForegroundColor Yellow
    } elseif ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "`nOrganization '$org' not found or you don't have access." -ForegroundColor Yellow
        Write-Host "Check the organization name and your permissions." -ForegroundColor Yellow
    }
}