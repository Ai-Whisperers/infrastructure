# AI-Whisperers Daily Monitoring Dashboard
param([switch]$Automated)

$Config = @{
    Organization = "Ai-Whisperers"
    ReportsPath = ".\monitoring-reports"
    LogPath = ".\monitoring-logs"
}

Write-Host "=== AI-Whisperers Daily Monitoring ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Run repository health dashboard
Write-Host "Running repository health analysis..." -ForegroundColor Yellow
& ".\repo-monitor-dashboard.ps1" health

Write-Host ""
Write-Host "Running organization activity summary..." -ForegroundColor Yellow
& ".\repo-monitor-dashboard.ps1" activity

# Generate daily report
Write-Host ""
Write-Host "Generating daily monitoring report..." -ForegroundColor Yellow
& ".\repo-monitor-dashboard.ps1" summary

Write-Host ""
Write-Host "âœ… Daily monitoring completed!" -ForegroundColor Green
Write-Host "Reports available in: $($Config.ReportsPath)" -ForegroundColor Gray
