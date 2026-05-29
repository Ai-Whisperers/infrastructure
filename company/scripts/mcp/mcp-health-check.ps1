<#
.SYNOPSIS
    MCP Server Health Check and Monitoring Tool
.DESCRIPTION
    Performs health checks on all configured MCP (Model Context Protocol) servers
    including Azure DevOps, GitHub, PostgreSQL, and Filesystem services.
.PARAMETER Mode
    Operation mode: Check, Monitor, Report, or Continuous
.PARAMETER OutputFormat
    Format for output: Console, JSON, or HTML
.PARAMETER AlertThreshold
    Number of consecutive failures before alerting (default: 3)
.EXAMPLE
    .\mcp-health-check.ps1 -Mode Check
    .\mcp-health-check.ps1 -Mode Monitor -OutputFormat JSON
    .\mcp-health-check.ps1 -Mode Continuous -AlertThreshold 5
#>

param(
    [ValidateSet('Check', 'Monitor', 'Report', 'Continuous')]
    [string]$Mode = 'Check',

    [ValidateSet('Console', 'JSON', 'HTML')]
    [string]$OutputFormat = 'Console',

    [int]$AlertThreshold = 3,

    [switch]$Verbose
)

# Script configuration
$script:Config = @{
    ConfigFile = Join-Path (Split-Path $PSScriptRoot) 'config\mcp\mcp-config.json'
    LogDir = Join-Path $PSScriptRoot '..\logs\mcp-health'
    HealthHistoryFile = Join-Path $PSScriptRoot '..\logs\mcp-health-history.json'
    AlertLogFile = Join-Path $PSScriptRoot '..\logs\mcp-alerts.log'
    CheckInterval = 300  # 5 minutes for continuous mode
    RetryAttempts = 3
    RetryDelay = 5  # seconds
}

# Ensure log directory exists
if (!(Test-Path $script:Config.LogDir)) {
    New-Item -ItemType Directory -Path $script:Config.LogDir -Force | Out-Null
}

# Health check results storage
$script:HealthResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Services = @{}
    Summary = @{
        TotalServices = 0
        Healthy = 0
        Degraded = 0
        Unhealthy = 0
        Unknown = 0
    }
}

# Load MCP configuration
function Get-MCPConfiguration {
    try {
        if (!(Test-Path $script:Config.ConfigFile)) {
            Write-Error "MCP configuration file not found: $($script:Config.ConfigFile)"
            return $null
        }

        $configContent = Get-Content $script:Config.ConfigFile -Raw | ConvertFrom-Json
        return $configContent.mcpServers
    }
    catch {
        Write-Error "Failed to load MCP configuration: $_"
        return $null
    }
}

# Azure DevOps health check
function Test-AzureDevOpsMCP {
    param($ServiceConfig)

    $health = @{
        Service = 'Azure DevOps MCP'
        Status = 'Unknown'
        ResponseTime = 0
        Details = @{}
        Checks = @{}
    }

    try {
        $startTime = Get-Date

        # Check environment variables
        $envVars = @('AZURE_DEVOPS_PAT', 'AZURE_DEVOPS_ORG', 'AZURE_DEVOPS_PROJECT')
        $missingVars = @()

        foreach ($var in $envVars) {
            if (![Environment]::GetEnvironmentVariable($var)) {
                $missingVars += $var
            }
        }

        if ($missingVars.Count -gt 0) {
            $health.Status = 'Unhealthy'
            $health.Details.Error = "Missing environment variables: $($missingVars -join ', ')"
            $health.Checks.EnvironmentVariables = 'Failed'
            return $health
        }

        $health.Checks.EnvironmentVariables = 'Passed'

        # Test Azure DevOps API connectivity
        $pat = [Environment]::GetEnvironmentVariable('AZURE_DEVOPS_PAT')
        $org = [Environment]::GetEnvironmentVariable('AZURE_DEVOPS_ORG')
        $project = [Environment]::GetEnvironmentVariable('AZURE_DEVOPS_PROJECT')

        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
            'Content-Type' = 'application/json'
        }

        $uri = "https://dev.azure.com/$org/$project/_apis/wit/workitems?api-version=7.0&`$top=1"

        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 10
            $health.Checks.APIConnectivity = 'Passed'
            $health.Details.WorkItemCount = $response.count

            # Check MCP server process
            $mcpProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -like "*azure-devops/mcp*" }

            if ($mcpProcess) {
                $health.Checks.ProcessRunning = 'Passed'
                $health.Details.ProcessId = $mcpProcess.Id
                $health.Details.Memory = "$([Math]::Round($mcpProcess.WorkingSet64 / 1MB, 2)) MB"
            } else {
                $health.Checks.ProcessRunning = 'Warning'
                $health.Details.ProcessStatus = 'Not running or not detected'
            }

            $health.Status = 'Healthy'
        }
        catch {
            $health.Status = 'Degraded'
            $health.Checks.APIConnectivity = 'Failed'
            $health.Details.APIError = $_.Exception.Message
        }

        $health.ResponseTime = ((Get-Date) - $startTime).TotalMilliseconds
    }
    catch {
        $health.Status = 'Unhealthy'
        $health.Details.Error = $_.Exception.Message
    }

    return $health
}

# GitHub MCP health check
function Test-GitHubMCP {
    param($ServiceConfig)

    $health = @{
        Service = 'GitHub MCP'
        Status = 'Unknown'
        ResponseTime = 0
        Details = @{}
        Checks = @{}
    }

    try {
        $startTime = Get-Date

        # Check GitHub token
        $token = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN')
        if (!$token) {
            $health.Status = 'Unhealthy'
            $health.Details.Error = "Missing GITHUB_TOKEN environment variable"
            $health.Checks.EnvironmentVariables = 'Failed'
            return $health
        }

        $health.Checks.EnvironmentVariables = 'Passed'

        # Test GitHub API connectivity
        $headers = @{
            Authorization = "Bearer $token"
            Accept = 'application/vnd.github.v3+json'
        }

        try {
            $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get -TimeoutSec 10
            $health.Checks.APIConnectivity = 'Passed'
            $health.Details.AuthenticatedUser = $response.login
            $health.Details.RateLimit = (Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -Headers $headers).rate.remaining

            # Check MCP server module
            $modulePath = Join-Path $PSScriptRoot '..\mcp-servers\node_modules\@modelcontextprotocol\server-github'
            if (Test-Path $modulePath) {
                $health.Checks.ModuleInstalled = 'Passed'
                $packageJson = Get-Content (Join-Path $modulePath 'package.json') | ConvertFrom-Json
                $health.Details.ModuleVersion = $packageJson.version
            } else {
                $health.Checks.ModuleInstalled = 'Failed'
                $health.Details.ModuleStatus = 'Not installed'
            }

            $health.Status = if ($health.Checks.ModuleInstalled -eq 'Failed') { 'Degraded' } else { 'Healthy' }
        }
        catch {
            $health.Status = 'Degraded'
            $health.Checks.APIConnectivity = 'Failed'
            $health.Details.APIError = $_.Exception.Message
        }

        $health.ResponseTime = ((Get-Date) - $startTime).TotalMilliseconds
    }
    catch {
        $health.Status = 'Unhealthy'
        $health.Details.Error = $_.Exception.Message
    }

    return $health
}

# PostgreSQL MCP health check
function Test-PostgresMCP {
    param($ServiceConfig)

    $health = @{
        Service = 'PostgreSQL MCP'
        Status = 'Unknown'
        ResponseTime = 0
        Details = @{}
        Checks = @{}
    }

    try {
        $startTime = Get-Date

        # Check connection string
        $connectionString = [Environment]::GetEnvironmentVariable('POSTGRES_CONNECTION_STRING')
        if (!$connectionString) {
            $health.Status = 'Unhealthy'
            $health.Details.Error = "Missing POSTGRES_CONNECTION_STRING environment variable"
            $health.Checks.EnvironmentVariables = 'Failed'
            return $health
        }

        $health.Checks.EnvironmentVariables = 'Passed'

        # Parse connection string for basic validation
        if ($connectionString -match 'host=([^;]+).*port=([^;]+).*database=([^;]+)') {
            $health.Details.Host = $Matches[1]
            $health.Details.Port = $Matches[2]
            $health.Details.Database = $Matches[3]
            $health.Checks.ConnectionStringFormat = 'Passed'
        } else {
            $health.Checks.ConnectionStringFormat = 'Warning'
            $health.Details.ConnectionStringStatus = 'Non-standard format'
        }

        # Check MCP server module
        $modulePath = Join-Path $PSScriptRoot '..\mcp-servers\node_modules\@modelcontextprotocol\server-postgres'
        if (Test-Path $modulePath) {
            $health.Checks.ModuleInstalled = 'Passed'
            $packageJson = Get-Content (Join-Path $modulePath 'package.json') | ConvertFrom-Json
            $health.Details.ModuleVersion = $packageJson.version
        } else {
            $health.Checks.ModuleInstalled = 'Failed'
            $health.Details.ModuleStatus = 'Not installed'
        }

        # Test port connectivity if possible
        if ($health.Details.Host -and $health.Details.Port) {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $tcpClient.Connect($health.Details.Host, [int]$health.Details.Port)
                if ($tcpClient.Connected) {
                    $health.Checks.PortConnectivity = 'Passed'
                    $tcpClient.Close()
                }
            }
            catch {
                $health.Checks.PortConnectivity = 'Failed'
                $health.Details.ConnectivityError = $_.Exception.Message
            }
        }

        $health.Status = if ($health.Checks.ModuleInstalled -eq 'Failed' -or $health.Checks.PortConnectivity -eq 'Failed') {
            'Degraded'
        } else {
            'Healthy'
        }

        $health.ResponseTime = ((Get-Date) - $startTime).TotalMilliseconds
    }
    catch {
        $health.Status = 'Unhealthy'
        $health.Details.Error = $_.Exception.Message
    }

    return $health
}

# Filesystem MCP health check
function Test-FilesystemMCP {
    param($ServiceConfig)

    $health = @{
        Service = 'Filesystem MCP'
        Status = 'Unknown'
        ResponseTime = 0
        Details = @{}
        Checks = @{}
    }

    try {
        $startTime = Get-Date

        # Check environment variables
        $rootPath = [Environment]::GetEnvironmentVariable('FILESYSTEM_ROOT')
        $allowWrite = [Environment]::GetEnvironmentVariable('FILESYSTEM_ALLOW_WRITE')

        if (!$rootPath) {
            $health.Details.RootPath = 'Not configured (using default)'
            $health.Checks.EnvironmentVariables = 'Warning'
        } else {
            $health.Details.RootPath = $rootPath
            $health.Checks.EnvironmentVariables = 'Passed'

            # Verify root path exists and is accessible
            if (Test-Path $rootPath) {
                $health.Checks.RootPathExists = 'Passed'

                # Check permissions
                try {
                    $acl = Get-Acl $rootPath
                    $health.Checks.RootPathAccessible = 'Passed'
                    $health.Details.RootPathOwner = $acl.Owner
                } catch {
                    $health.Checks.RootPathAccessible = 'Failed'
                    $health.Details.AccessError = $_.Exception.Message
                }
            } else {
                $health.Checks.RootPathExists = 'Failed'
            }
        }

        $health.Details.WritePermissions = if ($allowWrite -eq 'true') { 'Enabled' } else { 'Disabled' }

        # Check MCP server module
        $modulePath = Join-Path $PSScriptRoot '..\mcp-servers\node_modules\@modelcontextprotocol\server-filesystem'
        if (Test-Path $modulePath) {
            $health.Checks.ModuleInstalled = 'Passed'
            $packageJson = Get-Content (Join-Path $modulePath 'package.json') | ConvertFrom-Json
            $health.Details.ModuleVersion = $packageJson.version
        } else {
            $health.Checks.ModuleInstalled = 'Failed'
            $health.Details.ModuleStatus = 'Not installed'
        }

        $failedChecks = @($health.Checks.Values | Where-Object { $_ -eq 'Failed' }).Count
        $health.Status = if ($failedChecks -gt 0) { 'Degraded' } else { 'Healthy' }

        $health.ResponseTime = ((Get-Date) - $startTime).TotalMilliseconds
    }
    catch {
        $health.Status = 'Unhealthy'
        $health.Details.Error = $_.Exception.Message
    }

    return $health
}

# Perform health checks on all services
function Invoke-MCPHealthChecks {
    $mcpConfig = Get-MCPConfiguration
    if (!$mcpConfig) {
        Write-Error "Failed to load MCP configuration"
        return $null
    }

    Write-Host "`n=== MCP Server Health Check ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $($script:HealthResults.Timestamp)" -ForegroundColor Gray
    Write-Host ""

    # Define health check functions for each service
    $healthCheckFunctions = @{
        'azure-devops' = 'Test-AzureDevOpsMCP'
        'github' = 'Test-GitHubMCP'
        'postgres' = 'Test-PostgresMCP'
        'filesystem' = 'Test-FilesystemMCP'
    }

    foreach ($serviceName in $mcpConfig.PSObject.Properties.Name) {
        $serviceConfig = $mcpConfig.$serviceName

        if ($healthCheckFunctions.ContainsKey($serviceName)) {
            Write-Host "Checking $serviceName..." -NoNewline

            $checkFunction = $healthCheckFunctions[$serviceName]
            $result = & $checkFunction -ServiceConfig $serviceConfig

            $script:HealthResults.Services[$serviceName] = $result
            $script:HealthResults.Summary.TotalServices++

            # Update summary based on status
            switch ($result.Status) {
                'Healthy' {
                    $script:HealthResults.Summary.Healthy++
                    Write-Host " [HEALTHY]" -ForegroundColor Green
                }
                'Degraded' {
                    $script:HealthResults.Summary.Degraded++
                    Write-Host " [DEGRADED]" -ForegroundColor Yellow
                }
                'Unhealthy' {
                    $script:HealthResults.Summary.Unhealthy++
                    Write-Host " [UNHEALTHY]" -ForegroundColor Red
                }
                default {
                    $script:HealthResults.Summary.Unknown++
                    Write-Host " [UNKNOWN]" -ForegroundColor Gray
                }
            }

            if ($Verbose) {
                Write-Host "  Response Time: $([Math]::Round($result.ResponseTime, 2))ms" -ForegroundColor Gray
                foreach ($check in $result.Checks.GetEnumerator()) {
                    $color = switch ($check.Value) {
                        'Passed' { 'Green' }
                        'Warning' { 'Yellow' }
                        'Failed' { 'Red' }
                        default { 'Gray' }
                    }
                    Write-Host "  - $($check.Key): $($check.Value)" -ForegroundColor $color
                }
            }
        }
    }

    return $script:HealthResults
}

# Generate health report
function New-HealthReport {
    param(
        [hashtable]$HealthData,
        [string]$Format = 'Console'
    )

    switch ($Format) {
        'JSON' {
            $HealthData | ConvertTo-Json -Depth 5
        }

        'HTML' {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>MCP Health Check Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #333; color: white; padding: 10px; }
        .summary { margin: 20px 0; padding: 10px; background: #f0f0f0; }
        .service { border: 1px solid #ddd; margin: 10px 0; padding: 10px; }
        .healthy { border-left: 5px solid green; }
        .degraded { border-left: 5px solid orange; }
        .unhealthy { border-left: 5px solid red; }
        .checks { margin-left: 20px; }
        .passed { color: green; }
        .warning { color: orange; }
        .failed { color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>MCP Server Health Check Report</h1>
        <p>Generated: $($HealthData.Timestamp)</p>
    </div>

    <div class="summary">
        <h2>Summary</h2>
        <p>Total Services: $($HealthData.Summary.TotalServices)</p>
        <p>Healthy: $($HealthData.Summary.Healthy) | Degraded: $($HealthData.Summary.Degraded) | Unhealthy: $($HealthData.Summary.Unhealthy)</p>
    </div>
"@

            foreach ($service in $HealthData.Services.GetEnumerator()) {
                $statusClass = $service.Value.Status.ToLower()
                $html += @"
    <div class="service $statusClass">
        <h3>$($service.Value.Service)</h3>
        <p><strong>Status:</strong> $($service.Value.Status)</p>
        <p><strong>Response Time:</strong> $([Math]::Round($service.Value.ResponseTime, 2))ms</p>
        <div class="checks">
            <h4>Checks:</h4>
            <ul>
"@
                foreach ($check in $service.Value.Checks.GetEnumerator()) {
                    $checkClass = $check.Value.ToLower()
                    $html += "                <li class='$checkClass'>$($check.Key): $($check.Value)</li>`n"
                }

                $html += @"
            </ul>
        </div>
    </div>
"@
            }

            $html += @"
</body>
</html>
"@
            return $html
        }

        default {
            # Console output
            Write-Host "`n=== Health Check Summary ===" -ForegroundColor Cyan
            Write-Host "Total Services: $($HealthData.Summary.TotalServices)"
            Write-Host "Healthy: $($HealthData.Summary.Healthy)" -ForegroundColor Green -NoNewline
            Write-Host " | Degraded: $($HealthData.Summary.Degraded)" -ForegroundColor Yellow -NoNewline
            Write-Host " | Unhealthy: $($HealthData.Summary.Unhealthy)" -ForegroundColor Red

            if ($HealthData.Summary.Degraded -gt 0 -or $HealthData.Summary.Unhealthy -gt 0) {
                Write-Host "`nServices requiring attention:" -ForegroundColor Yellow
                foreach ($service in $HealthData.Services.GetEnumerator()) {
                    if ($service.Value.Status -ne 'Healthy') {
                        Write-Host "  - $($service.Value.Service): $($service.Value.Status)" -ForegroundColor Red
                        if ($service.Value.Details.Error) {
                            Write-Host "    Error: $($service.Value.Details.Error)" -ForegroundColor Gray
                        }
                    }
                }
            }
        }
    }
}

# Save health history
function Save-HealthHistory {
    param([hashtable]$HealthData)

    $history = @()
    if (Test-Path $script:Config.HealthHistoryFile) {
        $history = Get-Content $script:Config.HealthHistoryFile -Raw | ConvertFrom-Json
    }

    $history += $HealthData

    # Keep only last 100 entries
    if ($history.Count -gt 100) {
        $history = $history[-100..-1]
    }

    $history | ConvertTo-Json -Depth 5 | Set-Content $script:Config.HealthHistoryFile
}

# Alert on health issues
function Send-HealthAlert {
    param(
        [hashtable]$HealthData,
        [string]$AlertType = 'Critical'
    )

    $alertMessage = @"
MCP Health Alert - $AlertType
Timestamp: $($HealthData.Timestamp)

Summary:
- Total Services: $($HealthData.Summary.TotalServices)
- Unhealthy: $($HealthData.Summary.Unhealthy)
- Degraded: $($HealthData.Summary.Degraded)

Affected Services:
"@

    foreach ($service in $HealthData.Services.GetEnumerator()) {
        if ($service.Value.Status -ne 'Healthy') {
            $alertMessage += "`n- $($service.Value.Service): $($service.Value.Status)"
            if ($service.Value.Details.Error) {
                $alertMessage += "`n  Error: $($service.Value.Details.Error)"
            }
        }
    }

    # Log alert
    Add-Content -Path $script:Config.AlertLogFile -Value $alertMessage
    Add-Content -Path $script:Config.AlertLogFile -Value ("-" * 50)

    # Display alert
    Write-Host "`n[ALERT] $AlertType" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host $alertMessage -ForegroundColor Red

    # Here you could add email notifications, webhook calls, etc.
}

# Continuous monitoring mode
function Start-ContinuousMonitoring {
    Write-Host "Starting continuous MCP health monitoring..." -ForegroundColor Green
    Write-Host "Check interval: $($script:Config.CheckInterval) seconds" -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop monitoring`n" -ForegroundColor Yellow

    $failureCount = @{}

    while ($true) {
        $healthData = Invoke-MCPHealthChecks

        if ($healthData) {
            # Track consecutive failures
            foreach ($service in $healthData.Services.GetEnumerator()) {
                if ($service.Value.Status -eq 'Unhealthy') {
                    if (!$failureCount.ContainsKey($service.Key)) {
                        $failureCount[$service.Key] = 0
                    }
                    $failureCount[$service.Key]++

                    if ($failureCount[$service.Key] -ge $AlertThreshold) {
                        Send-HealthAlert -HealthData $healthData -AlertType "Critical - $($service.Key)"
                        $failureCount[$service.Key] = 0  # Reset after alert
                    }
                } else {
                    $failureCount[$service.Key] = 0
                }
            }

            # Save history
            Save-HealthHistory -HealthData $healthData

            # Generate report based on format
            if ($OutputFormat -ne 'Console') {
                $report = New-HealthReport -HealthData $healthData -Format $OutputFormat
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $reportFile = Join-Path $script:Config.LogDir "health_report_$timestamp.$($OutputFormat.ToLower())"
                $report | Set-Content $reportFile
                Write-Host "Report saved to: $reportFile" -ForegroundColor Green
            } else {
                New-HealthReport -HealthData $healthData -Format Console
            }
        }

        Write-Host "`nNext check in $($script:Config.CheckInterval) seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $script:Config.CheckInterval
    }
}

# Main execution
try {
    switch ($Mode) {
        'Check' {
            $healthData = Invoke-MCPHealthChecks
            if ($healthData) {
                New-HealthReport -HealthData $healthData -Format $OutputFormat
                Save-HealthHistory -HealthData $healthData
            }
        }

        'Monitor' {
            # Single detailed check with all information
            $healthData = Invoke-MCPHealthChecks
            if ($healthData) {
                $report = New-HealthReport -HealthData $healthData -Format $OutputFormat
                if ($OutputFormat -ne 'Console') {
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    $reportFile = Join-Path $script:Config.LogDir "health_monitor_$timestamp.$($OutputFormat.ToLower())"
                    $report | Set-Content $reportFile
                    Write-Host "`nReport saved to: $reportFile" -ForegroundColor Green
                }
                Save-HealthHistory -HealthData $healthData
            }
        }

        'Report' {
            # Generate report from historical data
            if (Test-Path $script:Config.HealthHistoryFile) {
                $history = Get-Content $script:Config.HealthHistoryFile -Raw | ConvertFrom-Json
                Write-Host "`n=== Health History Report ===" -ForegroundColor Cyan
                Write-Host "Total records: $($history.Count)" -ForegroundColor Gray

                if ($history.Count -gt 0) {
                    $latest = $history[-1]
                    Write-Host "`nLatest check: $($latest.Timestamp)" -ForegroundColor Gray
                    New-HealthReport -HealthData $latest -Format $OutputFormat

                    # Trend analysis
                    Write-Host "`n=== Trend Analysis (Last 10 checks) ===" -ForegroundColor Cyan
                    $recentHistory = $history[-10..-1]
                    $serviceStatus = @{}

                    foreach ($record in $recentHistory) {
                        foreach ($service in $record.Services.PSObject.Properties) {
                            if (!$serviceStatus.ContainsKey($service.Name)) {
                                $serviceStatus[$service.Name] = @()
                            }
                            $serviceStatus[$service.Name] += $service.Value.Status
                        }
                    }

                    foreach ($service in $serviceStatus.GetEnumerator()) {
                        $healthyCount = ($service.Value | Where-Object { $_ -eq 'Healthy' }).Count
                        $percentage = [Math]::Round(($healthyCount / $service.Value.Count) * 100, 1)
                        Write-Host "$($service.Key): $percentage% healthy" -ForegroundColor $(if ($percentage -ge 80) { 'Green' } elseif ($percentage -ge 60) { 'Yellow' } else { 'Red' })
                    }
                }
            } else {
                Write-Warning "No health history found. Run checks first."
            }
        }

        'Continuous' {
            Start-ContinuousMonitoring
        }
    }

    Write-Host "`nHealth check completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Health check failed: $_"
    exit 1
}