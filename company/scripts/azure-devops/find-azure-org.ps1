# Find Azure DevOps Organizations
# Get PAT from environment variable - set this before running the script
$pat = $env:AZURE_DEVOPS_PAT
if (-not $pat) {
    Write-Host "ERROR: AZURE_DEVOPS_PAT environment variable not set" -ForegroundColor Red
    Write-Host "Please set it using: `$env:AZURE_DEVOPS_PAT = 'your-token-here'" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nDiscovering Azure DevOps Organizations..." -ForegroundColor Cyan

# Create authorization header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
    'Content-Type' = 'application/json'
}

# Try common organization names
$possibleOrgs = @(
    "AI-Whisperers",
    "AIWhisperers",
    "ai-whisperers",
    "aiwhisperers",
    "aiwhisperer",
    "kyrianWVDP",
    "kyrianweiss"
)

Write-Host "Testing possible organization names..." -ForegroundColor Yellow

foreach ($org in $possibleOrgs) {
    try {
        $uri = "https://dev.azure.com/$org/_apis/projects?api-version=7.0"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 5 -ErrorAction Stop

        Write-Host "`n✅ Found organization: $org" -ForegroundColor Green
        Write-Host "   Projects count: $($response.count)" -ForegroundColor Gray

        foreach ($project in $response.value) {
            Write-Host "   - $($project.name)" -ForegroundColor Cyan
        }

        # Update the .env.mcp file suggestion
        Write-Host "`nUse these values in your .env.mcp:" -ForegroundColor Yellow
        Write-Host "AZURE_DEVOPS_ORG=$org" -ForegroundColor Green
        if ($response.value.Count -gt 0) {
            Write-Host "AZURE_DEVOPS_PROJECT=$($response.value[0].name)" -ForegroundColor Green
        }
        break
    } catch {
        Write-Host "  Checking $org... Not found" -ForegroundColor DarkGray
    }
}

# Alternative: Try to get user profile to find organizations
Write-Host "`nAttempting to get user profile..." -ForegroundColor Cyan
try {
    # Azure DevOps uses a different endpoint for user profile
    $profileUri = "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?api-version=7.0"
    $profile = Invoke-RestMethod -Uri $profileUri -Headers $headers -Method Get -TimeoutSec 10

    Write-Host "User Display Name: $($profile.displayName)" -ForegroundColor Yellow
    Write-Host "User Email: $($profile.emailAddress)" -ForegroundColor Yellow
} catch {
    Write-Host "Could not retrieve user profile" -ForegroundColor Red
}