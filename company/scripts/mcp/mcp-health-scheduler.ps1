<#
.SYNOPSIS
    MCP Health Check Scheduler
.DESCRIPTION
    Creates and manages scheduled tasks for automated MCP server health checks.
    Can create Windows Task Scheduler tasks or run as a background service.
.PARAMETER Action
    Action to perform: Create, Remove, Status, or Run
.PARAMETER Schedule
    Schedule type: Hourly, Daily, Weekly, or Custom
.PARAMETER CustomInterval
    Custom interval in minutes (for Custom schedule type)
.EXAMPLE
    .\mcp-health-scheduler.ps1 -Action Create -Schedule Hourly
    .\mcp-health-scheduler.ps1 -Action Status
    .\mcp-health-scheduler.ps1 -Action Remove
#>

param(
    [ValidateSet('Create', 'Remove', 'Status', 'Run')]
    [string]$Action = 'Status',

    [ValidateSet('Hourly', 'Daily', 'Weekly', 'Custom')]
    [string]$Schedule = 'Hourly',

    [int]$CustomInterval = 30,

    [switch]$EmailAlerts,
    [string]$EmailTo = '',
    [string]$EmailFrom = '',
    [string]$SmtpServer = ''
)

# Configuration
$script:Config = @{
    TaskName = 'AI-Whisperers MCP Health Check'
    TaskDescription = 'Automated health monitoring for MCP (Model Context Protocol) servers'
    ScriptPath = Join-Path $PSScriptRoot 'mcp-health-check.ps1'
    LogPath = Join-Path $PSScriptRoot '..\logs\mcp-scheduler.log'
}

# Ensure running as administrator for task scheduler operations
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Create scheduled task
function New-MCPHealthTask {
    if (!(Test-Administrator)) {
        Write-Warning "Creating scheduled tasks requires administrator privileges. Please run as administrator."
        return
    }

    Write-Host "Creating scheduled task: $($script:Config.TaskName)" -ForegroundColor Green

    # Create task action
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($script:Config.ScriptPath)`" -Mode Monitor -OutputFormat JSON"

    # Create trigger based on schedule
    $trigger = switch ($Schedule) {
        'Hourly' {
            New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365)
        }
        'Daily' {
            New-ScheduledTaskTrigger -Daily -At "09:00"
        }
        'Weekly' {
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"
        }
        'Custom' {
            New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $CustomInterval) -RepetitionDuration (New-TimeSpan -Days 365)
        }
    }

    # Create task settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -RestartCount 3

    # Create task principal (run whether user is logged in or not)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType ServiceAccount -RunLevel Highest

    # Register the task
    try {
        $task = Register-ScheduledTask `
            -TaskName $script:Config.TaskName `
            -Description $script:Config.TaskDescription `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Force

        Write-Host "Scheduled task created successfully!" -ForegroundColor Green
        Write-Host "Schedule: $Schedule" -ForegroundColor Gray
        if ($Schedule -eq 'Custom') {
            Write-Host "Interval: Every $CustomInterval minutes" -ForegroundColor Gray
        }

        # Configure email alerts if requested
        if ($EmailAlerts) {
            Set-EmailAlertConfig
        }

        # Run initial health check
        Write-Host "`nRunning initial health check..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName $script:Config.TaskName
    }
    catch {
        Write-Error "Failed to create scheduled task: $_"
    }
}

# Remove scheduled task
function Remove-MCPHealthTask {
    if (!(Test-Administrator)) {
        Write-Warning "Removing scheduled tasks requires administrator privileges. Please run as administrator."
        return
    }

    try {
        $task = Get-ScheduledTask -TaskName $script:Config.TaskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $script:Config.TaskName -Confirm:$false
            Write-Host "Scheduled task '$($script:Config.TaskName)' removed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Scheduled task '$($script:Config.TaskName)' not found"
        }
    }
    catch {
        Write-Error "Failed to remove scheduled task: $_"
    }
}

# Get task status
function Get-MCPHealthTaskStatus {
    try {
        $task = Get-ScheduledTask -TaskName $script:Config.TaskName -ErrorAction SilentlyContinue

        if (!$task) {
            Write-Host "Scheduled task not found: $($script:Config.TaskName)" -ForegroundColor Yellow
            Write-Host "Run with -Action Create to set up automated health checks" -ForegroundColor Gray
            return
        }

        Write-Host "`n=== MCP Health Check Task Status ===" -ForegroundColor Cyan
        Write-Host "Task Name: $($task.TaskName)"
        Write-Host "State: $($task.State)" -ForegroundColor $(if ($task.State -eq 'Ready') { 'Green' } else { 'Yellow' })
        Write-Host "Description: $($task.Description)"

        # Get task info
        $taskInfo = Get-ScheduledTaskInfo -TaskName $script:Config.TaskName
        Write-Host "`nLast Run Time: $($taskInfo.LastRunTime)"
        Write-Host "Last Result: 0x$($taskInfo.LastTaskResult.ToString('X'))" -ForegroundColor $(if ($taskInfo.LastTaskResult -eq 0) { 'Green' } else { 'Red' })
        Write-Host "Next Run Time: $($taskInfo.NextRunTime)"

        # Get recent run history
        $history = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201} -MaxEvents 10 -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -like "*$($script:Config.TaskName)*" } |
            Select-Object TimeCreated, Id, Message -First 5

        if ($history) {
            Write-Host "`n=== Recent Run History ===" -ForegroundColor Cyan
            foreach ($event in $history) {
                $status = if ($event.Id -eq 200) { 'Started' } else { 'Completed' }
                Write-Host "$($event.TimeCreated): $status" -ForegroundColor Gray
            }
        }

        # Check for recent health reports
        $reportsPath = Join-Path (Split-Path $script:Config.ScriptPath) '..\logs\mcp-health'
        if (Test-Path $reportsPath) {
            $recentReports = Get-ChildItem -Path $reportsPath -Filter "health_monitor_*.json" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 5

            if ($recentReports) {
                Write-Host "`n=== Recent Health Reports ===" -ForegroundColor Cyan
                foreach ($report in $recentReports) {
                    Write-Host "$($report.LastWriteTime): $($report.Name)" -ForegroundColor Gray
                }

                # Analyze latest report
                $latestReport = Get-Content $recentReports[0].FullName | ConvertFrom-Json
                Write-Host "`n=== Latest Health Status ===" -ForegroundColor Cyan
                Write-Host "Timestamp: $($latestReport.Timestamp)"
                Write-Host "Healthy Services: $($latestReport.Summary.Healthy)/$($latestReport.Summary.TotalServices)" -ForegroundColor Green
                if ($latestReport.Summary.Degraded -gt 0) {
                    Write-Host "Degraded Services: $($latestReport.Summary.Degraded)" -ForegroundColor Yellow
                }
                if ($latestReport.Summary.Unhealthy -gt 0) {
                    Write-Host "Unhealthy Services: $($latestReport.Summary.Unhealthy)" -ForegroundColor Red
                }
            }
        }
    }
    catch {
        Write-Error "Failed to get task status: $_"
    }
}

# Configure email alerts
function Set-EmailAlertConfig {
    if (!$EmailTo -or !$EmailFrom -or !$SmtpServer) {
        Write-Warning "Email configuration incomplete. Please provide -EmailTo, -EmailFrom, and -SmtpServer parameters"
        return
    }

    $emailConfig = @{
        To = $EmailTo
        From = $EmailFrom
        SmtpServer = $SmtpServer
        Enabled = $true
    }

    $configPath = Join-Path (Split-Path $script:Config.ScriptPath) '..\config\mcp-email-alerts.json'
    $configDir = Split-Path $configPath

    if (!(Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $emailConfig | ConvertTo-Json | Set-Content $configPath
    Write-Host "Email alert configuration saved" -ForegroundColor Green
}

# Run health check as background job
function Start-BackgroundHealthCheck {
    Write-Host "Starting background health check service..." -ForegroundColor Green

    $job = Start-Job -ScriptBlock {
        param($ScriptPath, $Interval)

        while ($true) {
            & $ScriptPath -Mode Check -OutputFormat JSON
            Start-Sleep -Seconds ($Interval * 60)
        }
    } -ArgumentList $script:Config.ScriptPath, $(if ($Schedule -eq 'Custom') { $CustomInterval } else { 60 })

    Write-Host "Background job started with ID: $($job.Id)" -ForegroundColor Green
    Write-Host "Use 'Get-Job $($job.Id)' to check status" -ForegroundColor Gray
    Write-Host "Use 'Stop-Job $($job.Id)' to stop the service" -ForegroundColor Gray

    # Monitor job for first few iterations
    $iterations = 0
    while ($iterations -lt 3 -and $job.State -eq 'Running') {
        Start-Sleep -Seconds 10
        $output = Receive-Job -Job $job -Keep
        if ($output) {
            Write-Host "`nHealth check output:" -ForegroundColor Cyan
            Write-Host $output
        }
        $iterations++
    }

    return $job
}

# Create PowerShell profile function for easy access
function Add-ProfileFunction {
    $profileFunction = @'

# MCP Health Check Quick Commands
function Check-MCPHealth {
    & "$PSScriptRoot\..\scripts\mcp-health-check.ps1" -Mode Check
}

function Monitor-MCPHealth {
    & "$PSScriptRoot\..\scripts\mcp-health-check.ps1" -Mode Continuous
}

function Get-MCPHealthReport {
    & "$PSScriptRoot\..\scripts\mcp-health-check.ps1" -Mode Report
}

Set-Alias -Name mcphealth -Value Check-MCPHealth
Set-Alias -Name mcpmon -Value Monitor-MCPHealth
Set-Alias -Name mcpreport -Value Get-MCPHealthReport

'@

    $profilePath = $PROFILE.CurrentUserAllHosts
    if (!(Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    if ((Get-Content $profilePath -Raw) -notmatch 'MCP Health Check Quick Commands') {
        Add-Content -Path $profilePath -Value $profileFunction
        Write-Host "PowerShell profile updated with MCP health check commands" -ForegroundColor Green
        Write-Host "Reload your PowerShell session to use: mcphealth, mcpmon, mcpreport" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "`n=== MCP Health Check Scheduler ===" -ForegroundColor Cyan

switch ($Action) {
    'Create' {
        New-MCPHealthTask
        Add-ProfileFunction
    }

    'Remove' {
        Remove-MCPHealthTask
    }

    'Status' {
        Get-MCPHealthTaskStatus
    }

    'Run' {
        Write-Host "Running MCP health check..." -ForegroundColor Green
        & $script:Config.ScriptPath -Mode Monitor -OutputFormat JSON

        # Save to log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $script:Config.LogPath -Value "$timestamp - Manual health check executed"
    }

    default {
        Write-Warning "Invalid action. Use: Create, Remove, Status, or Run"
    }
}

Write-Host "`nScheduler operation completed" -ForegroundColor Green