# AI-Whisperers Repository Health Monitoring Deployment
param(
    [ValidateSet("setup", "deploy", "test", "schedule", "status")]
    [string]$Action = "status",
    [switch]$VerboseLogging
)

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    MonitoringPath = ".\monitoring-system"
    LogPath = ".\monitoring-logs"
    ReportsPath = ".\monitoring-reports"
    ScheduleTime = "09:00"  # 9 AM daily
    AlertThresholds = @{
        HealthScore = 70
        IssuesOpen = 5
        PRsStale = 3
        DaysInactive = 7
    }
}

# Initialize logging
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$logFile = Join-Path $Config.LogPath "monitoring-deploy-$timestamp.log"

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
        if (-not (Test-Path $Config.LogPath)) {
            New-Item -ItemType Directory -Path $Config.LogPath -Force | Out-Null
        }
        $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Setup-MonitoringEnvironment {
    Write-Header "Setting Up Monitoring Environment"
    Write-Log "Starting monitoring environment setup" "INFO"
    
    $setupSuccess = $true
    
    try {
        # Create required directories
        $directories = @($Config.MonitoringPath, $Config.LogPath, $Config.ReportsPath)
        
        foreach ($dir in $directories) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Host "[CREATED] Directory: $dir" -ForegroundColor Green
                Write-Log "Created directory: $dir" "INFO"
            } else {
                Write-Host "[EXISTS] Directory: $dir" -ForegroundColor Gray
                Write-Log "Directory already exists: $dir" "DEBUG"
            }
        }
        
        # Test GitHub CLI access
        Write-Host ""
        Write-Host "Testing GitHub CLI access..." -ForegroundColor Yellow
        try {
            $authStatus = gh auth status 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] GitHub CLI is authenticated" -ForegroundColor Green
                Write-Log "GitHub CLI authentication verified" "INFO"
            } else {
                Write-Host "[ERROR] GitHub CLI authentication failed" -ForegroundColor Red
                Write-Log "GitHub CLI authentication failed" "ERROR"
                $setupSuccess = $false
            }
        } catch {
            Write-Host "[ERROR] GitHub CLI not available" -ForegroundColor Red
            Write-Log "GitHub CLI not available: $($_.Exception.Message)" "ERROR"
            $setupSuccess = $false
        }
        
        # Test repository access
        Write-Host ""
        Write-Host "Testing repository access..." -ForegroundColor Yellow
        try {
            $repos = gh repo list $Config.Organization --json name --limit 5 | ConvertFrom-Json
            if ($repos.Count -gt 0) {
                Write-Host "[OK] Can access $($repos.Count) repositories" -ForegroundColor Green
                Write-Log "Repository access verified: $($repos.Count) repositories" "INFO"
            } else {
                Write-Host "[ERROR] No repositories accessible" -ForegroundColor Red
                Write-Log "No repositories accessible" "ERROR"
                $setupSuccess = $false
            }
        } catch {
            Write-Host "[ERROR] Repository access failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Log "Repository access failed: $($_.Exception.Message)" "ERROR"
            $setupSuccess = $false
        }
        
        # Create monitoring configuration file
        Write-Host ""
        Write-Host "Creating monitoring configuration..." -ForegroundColor Yellow
        $configFile = Join-Path $Config.MonitoringPath "monitoring-config.json"
        
        $monitoringConfig = @{
            organization = $Config.Organization
            lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            alertThresholds = $Config.AlertThresholds
            reportSchedule = @{
                enabled = $true
                frequency = "daily"
                time = $Config.ScheduleTime
            }
            notifications = @{
                enabled = $true
                methods = @("console", "file", "github-issue")
            }
        } | ConvertTo-Json -Depth 3
        
        $monitoringConfig | Out-File -FilePath $configFile -Encoding UTF8
        Write-Host "[CREATED] Configuration file: $configFile" -ForegroundColor Green
        Write-Log "Created monitoring configuration file" "INFO"
        
        if ($setupSuccess) {
            Write-Host ""
            Write-Host "✅ Monitoring environment setup completed successfully!" -ForegroundColor Green
            Write-Log "Monitoring environment setup completed successfully" "INFO"
        } else {
            Write-Host ""
            Write-Host "⚠️ Monitoring environment setup completed with errors!" -ForegroundColor Yellow
            Write-Log "Monitoring environment setup completed with errors" "WARN"
        }
        
        return $setupSuccess
        
    } catch {
        Write-Host "[ERROR] Failed to setup monitoring environment: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Failed to setup monitoring environment: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Deploy-MonitoringSystem {
    Write-Header "Deploying Monitoring System"
    Write-Log "Starting monitoring system deployment" "INFO"
    
    # Create monitoring dashboard script
    $dashboardScript = Join-Path $Config.MonitoringPath "daily-monitoring.ps1"
    
    $dashboardContent = @"
# AI-Whisperers Daily Monitoring Dashboard
param([switch]`$Automated)

`$Config = @{
    Organization = "$($Config.Organization)"
    ReportsPath = "$($Config.ReportsPath)"
    LogPath = "$($Config.LogPath)"
}

Write-Host "=== AI-Whisperers Daily Monitoring ===" -ForegroundColor Cyan
Write-Host "Time: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
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
Write-Host "✅ Daily monitoring completed!" -ForegroundColor Green
Write-Host "Reports available in: `$(`$Config.ReportsPath)" -ForegroundColor Gray
"@
    
    try {
        $dashboardContent | Out-File -FilePath $dashboardScript -Encoding UTF8
        Write-Host "[CREATED] Daily monitoring script: $dashboardScript" -ForegroundColor Green
        Write-Log "Created daily monitoring script" "INFO"
        
        # Create monitoring wrapper
        $wrapperScript = Join-Path $Config.MonitoringPath "run-monitoring.bat"
        $wrapperContent = @"
@echo off
cd /d "%~dp0\.."
powershell -ExecutionPolicy Bypass -File ".\monitoring-system\daily-monitoring.ps1" -Automated
"@
        
        $wrapperContent | Out-File -FilePath $wrapperScript -Encoding ASCII
        Write-Host "[CREATED] Monitoring wrapper: $wrapperScript" -ForegroundColor Green
        Write-Log "Created monitoring wrapper script" "INFO"
        
        # Test deployment
        Write-Host ""
        Write-Host "Testing deployment..." -ForegroundColor Yellow
        if (Test-Path $dashboardScript) {
            Write-Host "[OK] Dashboard script deployed successfully" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Dashboard script deployment failed" -ForegroundColor Red
            return $false
        }
        
        Write-Host ""
        Write-Host "✅ Monitoring system deployed successfully!" -ForegroundColor Green
        Write-Log "Monitoring system deployed successfully" "INFO"
        return $true
        
    } catch {
        Write-Host "[ERROR] Failed to deploy monitoring system: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Failed to deploy monitoring system: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-MonitoringSystem {
    Write-Header "Testing Monitoring System"
    Write-Log "Starting monitoring system test" "INFO"
    
    $testsPassed = 0
    $totalTests = 5
    
    # Test 1: Environment setup
    Write-Host "Test 1: Environment Setup" -ForegroundColor Cyan
    if ((Test-Path $Config.MonitoringPath) -and (Test-Path $Config.LogPath) -and (Test-Path $Config.ReportsPath)) {
        Write-Host "  ✅ PASS - All directories exist" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ❌ FAIL - Missing directories" -ForegroundColor Red
    }
    
    # Test 2: Configuration file
    Write-Host ""
    Write-Host "Test 2: Configuration File" -ForegroundColor Cyan
    $configFile = Join-Path $Config.MonitoringPath "monitoring-config.json"
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile | ConvertFrom-Json
            Write-Host "  ✅ PASS - Configuration file is valid" -ForegroundColor Green
            $testsPassed++
        } catch {
            Write-Host "  ❌ FAIL - Configuration file is invalid JSON" -ForegroundColor Red
        }
    } else {
        Write-Host "  ❌ FAIL - Configuration file missing" -ForegroundColor Red
    }
    
    # Test 3: Dashboard script
    Write-Host ""
    Write-Host "Test 3: Dashboard Script" -ForegroundColor Cyan
    $dashboardScript = Join-Path $script:Config.MonitoringPath "daily-monitoring.ps1"
    if (Test-Path $dashboardScript) {
        Write-Host "  ✅ PASS - Dashboard script exists" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ❌ FAIL - Dashboard script missing" -ForegroundColor Red
    }
    
    # Test 4: GitHub CLI access
    Write-Host ""
    Write-Host "Test 4: GitHub CLI Access" -ForegroundColor Cyan
    try {
        gh auth status 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ PASS - GitHub CLI authenticated" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "  ❌ FAIL - GitHub CLI not authenticated" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ FAIL - GitHub CLI not available" -ForegroundColor Red
    }
    
    # Test 5: Repository access
    Write-Host ""
    Write-Host "Test 5: Repository Access" -ForegroundColor Cyan
    try {
        $repos = gh repo list $Config.Organization --json name --limit 3 | ConvertFrom-Json
        if ($repos.Count -gt 0) {
            Write-Host "  ✅ PASS - Can access repositories" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "  ❌ FAIL - No repositories accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ FAIL - Repository access failed" -ForegroundColor Red
    }
    
    # Summary
    Write-Host ""
    Write-Host "Test Summary:" -ForegroundColor Cyan
    Write-Host "  Tests passed: $testsPassed/$totalTests" -ForegroundColor Gray
    Write-Host "  Success rate: $([math]::Round(($testsPassed / $totalTests) * 100, 1))%" -ForegroundColor Gray
    
    if ($testsPassed -eq $totalTests) {
        Write-Host "  Overall Status: ✅ All tests passed - System ready!" -ForegroundColor Green
        Write-Log "All monitoring system tests passed" "INFO"
        return $true
    } else {
        Write-Host "  Overall Status: ⚠️ Some tests failed - Check configuration" -ForegroundColor Yellow
        Write-Log "Some monitoring system tests failed: $testsPassed/$totalTests" "WARN"
        return $false
    }
}

function Schedule-Monitoring {
    Write-Header "Scheduling Monitoring System"
    Write-Log "Starting monitoring system scheduling" "INFO"
    
    try {
        # Create scheduled task command
        $scriptPath = Join-Path (Get-Location) $Config.MonitoringPath "run-monitoring.bat"
        $taskName = "AI-Whisperers-Monitoring"
        
        Write-Host "Creating Windows scheduled task..." -ForegroundColor Yellow
        Write-Host "  Task Name: $taskName" -ForegroundColor Gray
        Write-Host "  Schedule: Daily at $($Config.ScheduleTime)" -ForegroundColor Gray
        Write-Host "  Script: $scriptPath" -ForegroundColor Gray
        Write-Host ""
        
        # Check if task already exists
        $existingTask = schtasks /query /tn $taskName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[INFO] Task already exists. Updating..." -ForegroundColor Yellow
            schtasks /delete /tn $taskName /f 2>$null | Out-Null
        }
        
        # Create the scheduled task
        $createResult = schtasks /create /tn $taskName /tr "`"$scriptPath`"" /sc daily /st $($Config.ScheduleTime) /f 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Monitoring will run daily at $($Config.ScheduleTime)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "To manually run monitoring:" -ForegroundColor Cyan
            Write-Host "  schtasks /run /tn $taskName" -ForegroundColor Gray
            Write-Host ""
            Write-Host "To disable scheduled monitoring:" -ForegroundColor Cyan
            Write-Host "  schtasks /delete /tn $taskName" -ForegroundColor Gray
            
            Write-Log "Scheduled task created successfully" "INFO"
            return $true
        } else {
            Write-Host "❌ Failed to create scheduled task" -ForegroundColor Red
            Write-Host "Error: $createResult" -ForegroundColor Red
            Write-Log "Failed to create scheduled task: $createResult" "ERROR"
            return $false
        }
        
    } catch {
        Write-Host "❌ Error scheduling monitoring: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Error scheduling monitoring: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-MonitoringStatus {
    Write-Header "Monitoring System Status"
    
    # Check environment
    Write-Host "Environment Status:" -ForegroundColor Cyan
    $directories = @(
        @{Name = "Monitoring System"; Path = $Config.MonitoringPath}
        @{Name = "Logs"; Path = $Config.LogPath}
        @{Name = "Reports"; Path = $Config.ReportsPath}
    )
    
    foreach ($dir in $directories) {
        if (Test-Path $dir.Path) {
            $itemCount = (Get-ChildItem $dir.Path -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-Host "  ✅ $($dir.Name): $($dir.Path) ($itemCount items)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $($dir.Name): $($dir.Path) (missing)" -ForegroundColor Red
        }
    }
    
    # Check configuration
    Write-Host ""
    Write-Host "Configuration Status:" -ForegroundColor Cyan
    $configFile = Join-Path $Config.MonitoringPath "monitoring-config.json"
    if (Test-Path $configFile) {
        Write-Host "  ✅ Configuration file exists" -ForegroundColor Green
        try {
            $config = Get-Content $configFile | ConvertFrom-Json
            Write-Host "    Organization: $($config.organization)" -ForegroundColor Gray
            Write-Host "    Last Updated: $($config.lastUpdated)" -ForegroundColor Gray
        } catch {
            Write-Host "  ⚠️ Configuration file has issues" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ❌ Configuration file missing" -ForegroundColor Red
    }
    
    # Check scheduled task
    Write-Host ""
    Write-Host "Scheduled Task Status:" -ForegroundColor Cyan
    $taskName = "AI-Whisperers-Monitoring"
    $taskExists = schtasks /query /tn $taskName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Scheduled task exists: $taskName" -ForegroundColor Green
        Write-Host "  ℹ️ Next run: Use 'schtasks /query /tn $taskName /fo list' for details" -ForegroundColor Cyan
    } else {
        Write-Host "  ❌ Scheduled task not configured" -ForegroundColor Red
        Write-Host "  ℹ️ Run with 'schedule' action to set up automatic monitoring" -ForegroundColor Cyan
    }
    
    # Check GitHub access
    Write-Host ""
    Write-Host "GitHub Access Status:" -ForegroundColor Cyan
    try {
        gh auth status 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ GitHub CLI authenticated" -ForegroundColor Green
            
            # Check repository access
            $repos = gh repo list $Config.Organization --json name --limit 5 | ConvertFrom-Json
            Write-Host "  ✅ Can access $($repos.Count) repositories" -ForegroundColor Green
        } else {
            Write-Host "  ❌ GitHub CLI not authenticated" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ GitHub CLI not available" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Quick Actions:" -ForegroundColor Cyan
    Write-Host "  Setup:    .\deploy-monitoring.ps1 setup" -ForegroundColor Gray
    Write-Host "  Deploy:   .\deploy-monitoring.ps1 deploy" -ForegroundColor Gray
    Write-Host "  Test:     .\deploy-monitoring.ps1 test" -ForegroundColor Gray
    Write-Host "  Schedule: .\deploy-monitoring.ps1 schedule" -ForegroundColor Gray
}

# Initialize logging
Write-Log "Starting monitoring deployment - Action: $Action" "INFO"

# Main execution
switch ($Action.ToLower()) {
    "setup" {
        Setup-MonitoringEnvironment
    }
    "deploy" {
        if (Deploy-MonitoringSystem) {
            Write-Host ""
            Write-Host "💡 Next step: Run 'schedule' action to enable automatic monitoring" -ForegroundColor Cyan
        }
    }
    "test" {
        Test-MonitoringSystem
    }
    "schedule" {
        Schedule-Monitoring
    }
    "status" {
        Show-MonitoringStatus
    }
    default {
        Write-Error "Invalid action: $Action. Use: setup, deploy, test, schedule, or status"
    }
}

Write-Log "Monitoring deployment completed - Action: $Action" "INFO"