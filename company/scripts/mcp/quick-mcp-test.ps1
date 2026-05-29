# Quick MCP Test with configured GitHub token
Write-Host "`n=== Quick MCP Configuration Test ===" -ForegroundColor Cyan

# Load path resolver utility
. "$PSScriptRoot\common\PathResolver.ps1"

# Check if GitHub token is set in environment
if (-not $env:GITHUB_TOKEN) {
    Write-Host "ERROR: GITHUB_TOKEN environment variable not set" -ForegroundColor Red
    Write-Host "Please set it using: `$env:GITHUB_TOKEN = 'your-token-here'" -ForegroundColor Yellow
    exit 1
}

# Also set some reasonable defaults for filesystem
$env:FILESYSTEM_ROOT = Get-ProjectRoot
$env:FILESYSTEM_ALLOW_WRITE = "false"

Write-Host "`nEnvironment variables configured for session:" -ForegroundColor Green
Write-Host "  GITHUB_TOKEN: [SET]" -ForegroundColor Green
Write-Host "  FILESYSTEM_ROOT: $env:FILESYSTEM_ROOT" -ForegroundColor Green
Write-Host "  FILESYSTEM_ALLOW_WRITE: $env:FILESYSTEM_ALLOW_WRITE" -ForegroundColor Green

# Now run the health check
Write-Host "`nRunning health check..." -ForegroundColor Yellow
& "$PSScriptRoot\mcp-health-check.ps1" -Mode Check