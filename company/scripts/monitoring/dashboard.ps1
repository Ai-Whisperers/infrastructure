# AI-Whisperers Management Dashboard Script
# Provides comprehensive status and management overview

param(
    [string]$Mode = "interactive",  # interactive, summary, export
    [string]$ExportFormat = "html", # html, json, markdown
    [string]$OutputPath = "",       # output file path
    [int]$RefreshInterval = 30,     # seconds for interactive mode
    [switch]$ShowDetails,           # show detailed information
    [switch]$Quiet                  # suppress interactive output
)

# Import required modules and configuration
$script:Config = $null
$script:DashboardData = @{
    Timestamp = Get-Date
    TodoStatus = @{}
    SyncStatus = @{}
    RepositoryHealth = @{}
    SystemMetrics = @{}
    Issues = @()
    Recommendations = @()
}

function Import-Configurations {
    # Load sync configuration
    $syncConfigPath = "$PSScriptRoot\..\sync-config.json"
    if (Test-Path $syncConfigPath) {
        try {
            $script:Config = Get-Content $syncConfigPath | ConvertFrom-Json
            Write-Log "Loaded sync configuration" "DEBUG"
        }
        catch {
            Write-Log "Failed to load sync configuration" "WARN"
        }
    }
    
    # Load other configurations as needed
    return $true
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if ($Quiet -and $Level -ne "ERROR") { return }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "DEBUG" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Test-SystemPrerequisites {
    $issues = @()
    
    # Check GitHub CLI
    try {
        $null = gh --version
    }
    catch {
        $issues += "GitHub CLI not installed or not accessible"
    }
    
    # Check GitHub authentication
    try {
        $user = gh api user --jq .login 2>$null
        if (-not $user) {
            $issues += "GitHub CLI not authenticated"
        }
    }
    catch {
        $issues += "GitHub authentication failed"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell version too old (minimum 5.0 required)"
    }
    
    # Check required directories
    $requiredPaths = @(
        "$PSScriptRoot\..\project-todos",
        "$PSScriptRoot\..\scripts",
        "$PSScriptRoot\..\.github\workflows"
    )
    
    foreach ($path in $requiredPaths) {
        if (-not (Test-Path $path)) {
            $issues += "Required directory missing: $path"
        }
    }
    
    $script:DashboardData.Issues += $issues
    return $issues.Count -eq 0
}

function Get-TodoSummary {
    Write-Log "Gathering todo summary..." "DEBUG"
    
    $todoPath = "$PSScriptRoot\..\project-todos"
    $todoFiles = Get-ChildItem "$todoPath\*-todos.md" -ErrorAction SilentlyContinue
    
    $summary = @{
        TotalRepositories = 0
        TotalTodos = 0
        CompletedTodos = 0
        HighPriorityTodos = 0
        Repositories = @{}
        LastUpdate = $null
    }
    
    foreach ($file in $todoFiles) {
        $repoName = $file.BaseName -replace "-todos$", ""
        $summary.TotalRepositories++
        
        try {
            $content = Get-Content $file.FullName -Raw
            $todos = @()
            $lines = $content -split "`n"
            $currentSection = "General"
            $repoTodos = 0
            $repoCompleted = 0
            $repoHighPriority = 0
            
            foreach ($line in $lines) {
                if ($line -match "^##\s+(.+)") {
                    $currentSection = $matches[1].Trim()
                }
                elseif ($line -match "^-\s+\[([ x])\]\s+(.+)") {
                    $completed = $matches[1] -eq "x"
                    $task = $matches[2].Trim()
                    
                    $repoTodos++
                    if ($completed) { $repoCompleted++ }
                    if ($currentSection -eq "High Priority") { $repoHighPriority++ }
                }
            }
            
            $progress = if ($repoTodos -gt 0) { [math]::Round(($repoCompleted / $repoTodos) * 100) } else { 0 }
            
            $summary.Repositories[$repoName] = @{
                TotalTodos = $repoTodos
                CompletedTodos = $repoCompleted
                HighPriorityTodos = $repoHighPriority
                Progress = $progress
                LastModified = $file.LastWriteTime
            }
            
            $summary.TotalTodos += $repoTodos
            $summary.CompletedTodos += $repoCompleted
            $summary.HighPriorityTodos += $repoHighPriority
            
            if ($null -eq $summary.LastUpdate -or $file.LastWriteTime -gt $summary.LastUpdate) {
                $summary.LastUpdate = $file.LastWriteTime
            }
        }
        catch {
            Write-Log "Error processing todo file: $($file.Name)" "WARN"
        }
    }
    
    $script:DashboardData.TodoStatus = $summary
}

function Get-SyncStatus {
    Write-Log "Checking sync status..." "DEBUG"
    
    $status = @{
        ConfigurationValid = $false
        LastSyncAttempt = $null
        SuccessfulSyncs = 0
        FailedSyncs = 0
        PendingSyncs = 0
        ConfiguredRules = 0
        EnabledRules = 0
        Repositories = @{}
    }
    
    if ($script:Config) {
        $status.ConfigurationValid = $true
        
        # Count sync rules
        foreach ($ruleEntry in $script:Config.syncRules.PSObject.Properties) {
            $status.ConfiguredRules++
            if ($ruleEntry.Value.enabled -ne $false) {
                $status.EnabledRules++
            }
        }
        
        # Check repository sync status
        foreach ($repoEntry in $script:Config.repositories.PSObject.Properties) {
            if ($repoEntry.Name -eq "Company-Information") { continue }
            
            try {
                # Get recent commits for file-sync
                $commits = gh api "repos/$($script:Config.organization)/$($repoEntry.Name)/commits" `
                    --jq '.[] | select(.commit.message | contains("file-sync:")) | {date: .commit.author.date, message: .commit.message}' `
                    2>$null | ConvertFrom-Json
                
                if ($commits) {
                    $latestSync = if ($commits -is [array]) { $commits[0] } else { $commits }
                    $status.Repositories[$repoEntry.Name] = @{
                        LastSync = $latestSync.date
                        LastSyncMessage = $latestSync.message
                        Status = "Synced"
                    }
                    $status.SuccessfulSyncs++
                } else {
                    $status.Repositories[$repoEntry.Name] = @{
                        LastSync = $null
                        LastSyncMessage = "No sync commits found"
                        Status = "Pending"
                    }
                    $status.PendingSyncs++
                }
            }
            catch {
                $status.Repositories[$repoEntry.Name] = @{
                    LastSync = $null
                    LastSyncMessage = "Error checking status"
                    Status = "Error"
                }
                $status.FailedSyncs++
            }
        }
    }
    
    $script:DashboardData.SyncStatus = $status
}

function Get-RepositoryHealth {
    Write-Log "Assessing repository health..." "DEBUG"
    
    if (-not $script:Config) {
        $script:DashboardData.RepositoryHealth = @{ Error = "No configuration available" }
        return
    }
    
    $health = @{
        TotalRepositories = 0
        HealthyRepositories = 0
        RepositoryDetails = @{}
    }
    
    foreach ($repoEntry in $script:Config.repositories.PSObject.Properties) {
        if ($repoEntry.Name -eq "Company-Information") { continue }
        
        $repoName = $repoEntry.Name
        $health.TotalRepositories++
        
        try {
            # Get basic repository info
            $repoInfo = gh api "repos/$($script:Config.organization)/$repoName" | ConvertFrom-Json
            
            # Get recent activity
            $commits = gh api "repos/$($script:Config.organization)/$repoName/commits" `
                --jq 'length' 2>$null
            
            # Get issues count
            $openIssues = $repoInfo.open_issues_count
            
            # Calculate health score
            $healthScore = 100
            $issues = @()
            
            # Check for recent activity (last 30 days)
            $lastPush = [DateTime]$repoInfo.pushed_at
            $daysSinceLastPush = (Get-Date) - $lastPush | Select-Object -ExpandProperty TotalDays
            
            if ($daysSinceLastPush -gt 30) {
                $healthScore -= 20
                $issues += "No activity in $([math]::Round($daysSinceLastPush)) days"
            }
            
            # Check for excessive open issues
            if ($openIssues -gt 20) {
                $healthScore -= 15
                $issues += "$openIssues open issues"
            }
            
            # Check if repository has README
            try {
                $null = gh api "repos/$($script:Config.organization)/$repoName/contents/README.md" 2>$null
            }
            catch {
                $healthScore -= 10
                $issues += "Missing README.md"
            }
            
            # Check if repository has CLAUDE.md
            try {
                $null = gh api "repos/$($script:Config.organization)/$repoName/contents/CLAUDE.md" 2>$null
            }
            catch {
                $healthScore -= 5
                $issues += "Missing CLAUDE.md"
            }
            
            $status = if ($healthScore -ge 90) { "Excellent" } 
                     elseif ($healthScore -ge 75) { "Good" }
                     elseif ($healthScore -ge 60) { "Fair" }
                     else { "Poor" }
            
            if ($healthScore -ge 75) {
                $health.HealthyRepositories++
            }
            
            $health.RepositoryDetails[$repoName] = @{
                HealthScore = $healthScore
                Status = $status
                Issues = $issues
                LastPush = $lastPush
                OpenIssues = $openIssues
                Private = $repoInfo.private
                Stars = $repoInfo.stargazers_count
                Forks = $repoInfo.forks_count
            }
        }
        catch {
            $health.RepositoryDetails[$repoName] = @{
                HealthScore = 0
                Status = "Error"
                Issues = @("Failed to retrieve repository information")
                LastPush = $null
                OpenIssues = 0
                Private = $true
                Stars = 0
                Forks = 0
            }
            Write-Log "Failed to assess health for $repoName" "WARN"
        }
    }
    
    $script:DashboardData.RepositoryHealth = $health
}

function Get-SystemMetrics {
    Write-Log "Collecting system metrics..." "DEBUG"
    
    $metrics = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        GitHubCLIVersion = "Unknown"
        WorkflowsCount = 0
        ScriptsCount = 0
        ConfigurationFiles = 0
        SystemHealth = "Good"
    }
    
    try {
        $ghVersion = gh --version | Select-String "gh version" | ForEach-Object { $_.ToString().Split()[2] }
        $metrics.GitHubCLIVersion = $ghVersion
    }
    catch {
        $metrics.SystemHealth = "Warning"
    }
    
    # Count workflows
    $workflowPath = "$PSScriptRoot\..\.github\workflows"
    if (Test-Path $workflowPath) {
        $metrics.WorkflowsCount = (Get-ChildItem "$workflowPath\*.yml" -ErrorAction SilentlyContinue).Count
    }
    
    # Count scripts
    $scriptsPath = "$PSScriptRoot"
    if (Test-Path $scriptsPath) {
        $metrics.ScriptsCount = (Get-ChildItem "$scriptsPath\*.ps1" -ErrorAction SilentlyContinue).Count
    }
    
    # Count configuration files
    $configFiles = @("sync-config.json", "CLAUDE.md", ".gitignore")
    foreach ($file in $configFiles) {
        if (Test-Path "$PSScriptRoot\..\$file") {
            $metrics.ConfigurationFiles++
        }
    }
    
    $script:DashboardData.SystemMetrics = $metrics
}

function Generate-Recommendations {
    Write-Log "Generating recommendations..." "DEBUG"
    
    $recommendations = @()
    
    # Todo-based recommendations
    if ($script:DashboardData.TodoStatus.HighPriorityTodos -gt 0) {
        $recommendations += @{
            Type = "Action"
            Priority = "High"
            Title = "High Priority Todos Need Attention"
            Description = "$($script:DashboardData.TodoStatus.HighPriorityTodos) high priority todos are pending across repositories"
            Action = "Review and prioritize high priority todos in project-todos directory"
        }
    }
    
    # Sync-based recommendations
    if ($script:DashboardData.SyncStatus.FailedSyncs -gt 0) {
        $recommendations += @{
            Type = "Warning"
            Priority = "High"
            Title = "File Sync Failures Detected"
            Description = "$($script:DashboardData.SyncStatus.FailedSyncs) repositories have sync failures"
            Action = "Run scripts/file-sync.ps1 -Action status to investigate"
        }
    }
    
    # Repository health recommendations
    foreach ($repo in $script:DashboardData.RepositoryHealth.RepositoryDetails.GetEnumerator()) {
        if ($repo.Value.HealthScore -lt 75) {
            $recommendations += @{
                Type = "Improvement"
                Priority = "Medium"
                Title = "Repository Health Issues"
                Description = "$($repo.Key) has health score of $($repo.Value.HealthScore)%"
                Action = "Address issues: $($repo.Value.Issues -join ', ')"
            }
        }
    }
    
    # Progress-based recommendations
    $overallProgress = if ($script:DashboardData.TodoStatus.TotalTodos -gt 0) {
        [math]::Round(($script:DashboardData.TodoStatus.CompletedTodos / $script:DashboardData.TodoStatus.TotalTodos) * 100)
    } else { 100 }
    
    if ($overallProgress -lt 50) {
        $recommendations += @{
            Type = "Action"
            Priority = "Medium"
            Title = "Overall Project Progress Low"
            Description = "Only $overallProgress% of todos are completed across all repositories"
            Action = "Focus on completing pending tasks, especially high priority ones"
        }
    }
    
    $script:DashboardData.Recommendations = $recommendations
}

function Show-InteractiveDashboard {
    while ($true) {
        Clear-Host
        
        # Header
        Write-Host "🚀 AI-Whisperers Management Dashboard" -ForegroundColor Green
        Write-Host "=" * 50 -ForegroundColor Gray
        Write-Host "Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
        Write-Host ""
        
        # Quick Status Overview
        Write-Host "📊 Quick Overview:" -ForegroundColor Cyan
        $overallProgress = if ($script:DashboardData.TodoStatus.TotalTodos -gt 0) {
            [math]::Round(($script:DashboardData.TodoStatus.CompletedTodos / $script:DashboardData.TodoStatus.TotalTodos) * 100)
        } else { 100 }
        
        Write-Host "   Todos: $($script:DashboardData.TodoStatus.CompletedTodos)/$($script:DashboardData.TodoStatus.TotalTodos) completed ($overallProgress%)" -ForegroundColor White
        Write-Host "   Repositories: $($script:DashboardData.RepositoryHealth.HealthyRepositories)/$($script:DashboardData.RepositoryHealth.TotalRepositories) healthy" -ForegroundColor White
        Write-Host "   Sync Rules: $($script:DashboardData.SyncStatus.EnabledRules)/$($script:DashboardData.SyncStatus.ConfiguredRules) enabled" -ForegroundColor White
        Write-Host ""
        
        # Todo Summary
        Write-Host "✅ Todo Status:" -ForegroundColor Yellow
        foreach ($repo in $script:DashboardData.TodoStatus.Repositories.GetEnumerator()) {
            $status = $repo.Value
            $progressBar = "█" * [math]::Floor($status.Progress / 10) + "░" * (10 - [math]::Floor($status.Progress / 10))
            $color = if ($status.Progress -ge 75) { "Green" } elseif ($status.Progress -ge 50) { "Yellow" } else { "Red" }
            Write-Host "   $($repo.Key): [$progressBar] $($status.Progress)% ($($status.CompletedTodos)/$($status.TotalTodos))" -ForegroundColor $color
        }
        Write-Host ""
        
        # Repository Health
        Write-Host "🏥 Repository Health:" -ForegroundColor Yellow
        foreach ($repo in $script:DashboardData.RepositoryHealth.RepositoryDetails.GetEnumerator()) {
            $health = $repo.Value
            $icon = switch ($health.Status) {
                "Excellent" { "🟢" }
                "Good" { "🟡" }
                "Fair" { "🟠" }
                "Poor" { "🔴" }
                "Error" { "❌" }
            }
            Write-Host "   $icon $($repo.Key): $($health.Status) ($($health.HealthScore)%)" -ForegroundColor White
        }
        Write-Host ""
        
        # High Priority Recommendations
        if ($script:DashboardData.Recommendations.Count -gt 0) {
            Write-Host "💡 Top Recommendations:" -ForegroundColor Yellow
            $topRecommendations = $script:DashboardData.Recommendations | Where-Object { $_.Priority -eq "High" } | Select-Object -First 3
            foreach ($rec in $topRecommendations) {
                $icon = switch ($rec.Type) {
                    "Action" { "🎯" }
                    "Warning" { "⚠️" }
                    "Improvement" { "📈" }
                }
                Write-Host "   $icon $($rec.Title)" -ForegroundColor White
            }
            Write-Host ""
        }
        
        # Interactive Options
        Write-Host "Options: [R]efresh | [D]etails | [T]odos | [S]ync | [Q]uit" -ForegroundColor Cyan
        Write-Host "Auto-refresh in $RefreshInterval seconds (press any key to interrupt)" -ForegroundColor Gray
        
        # Wait for input or timeout
        $timeout = $RefreshInterval * 1000
        $key = $null
        
        $startTime = Get-Date
        while (((Get-Date) - $startTime).TotalMilliseconds -lt $timeout) {
            if ($host.UI.RawUI.KeyAvailable) {
                $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                break
            }
            Start-Sleep -Milliseconds 100
        }
        
        if ($key) {
            switch ($key.Character.ToString().ToUpper()) {
                "R" { 
                    Write-Host "Refreshing..." -ForegroundColor Green
                    Collect-AllData
                }
                "D" { Show-DetailedReport }
                "T" { Show-TodoDetails }
                "S" { Show-SyncDetails }
                "Q" { return }
                default { 
                    Write-Host "Refreshing..." -ForegroundColor Green
                    Collect-AllData
                }
            }
        } else {
            # Auto-refresh
            Collect-AllData
        }
    }
}

function Show-DetailedReport {
    Clear-Host
    Write-Host "📋 Detailed System Report" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    # System Information
    Write-Host "🖥️ System Information:" -ForegroundColor Cyan
    foreach ($metric in $script:DashboardData.SystemMetrics.GetEnumerator()) {
        Write-Host "   $($metric.Key): $($metric.Value)" -ForegroundColor White
    }
    Write-Host ""
    
    # Detailed Repository Health
    Write-Host "🏥 Repository Health Details:" -ForegroundColor Cyan
    foreach ($repo in $script:DashboardData.RepositoryHealth.RepositoryDetails.GetEnumerator()) {
        $health = $repo.Value
        Write-Host "   📁 $($repo.Key):" -ForegroundColor Yellow
        Write-Host "      Health Score: $($health.HealthScore)%" -ForegroundColor White
        Write-Host "      Status: $($health.Status)" -ForegroundColor White
        Write-Host "      Last Push: $($health.LastPush)" -ForegroundColor White
        Write-Host "      Open Issues: $($health.OpenIssues)" -ForegroundColor White
        if ($health.Issues.Count -gt 0) {
            Write-Host "      Issues:" -ForegroundColor Red
            foreach ($issue in $health.Issues) {
                Write-Host "        - $issue" -ForegroundColor White
            }
        }
        Write-Host ""
    }
    
    # All Recommendations
    if ($script:DashboardData.Recommendations.Count -gt 0) {
        Write-Host "💡 All Recommendations:" -ForegroundColor Cyan
        foreach ($rec in $script:DashboardData.Recommendations) {
            $icon = switch ($rec.Type) {
                "Action" { "🎯" }
                "Warning" { "⚠️" }
                "Improvement" { "📈" }
            }
            Write-Host "   $icon [$($rec.Priority)] $($rec.Title)" -ForegroundColor Yellow
            Write-Host "      $($rec.Description)" -ForegroundColor White
            Write-Host "      Action: $($rec.Action)" -ForegroundColor Green
            Write-Host ""
        }
    }
    
    Write-Host "Press any key to return to main dashboard..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-TodoDetails {
    Clear-Host
    Write-Host "✅ Todo Management Details" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📊 Summary:" -ForegroundColor Cyan
    Write-Host "   Total Repositories: $($script:DashboardData.TodoStatus.TotalRepositories)" -ForegroundColor White
    Write-Host "   Total Todos: $($script:DashboardData.TodoStatus.TotalTodos)" -ForegroundColor White
    Write-Host "   Completed Todos: $($script:DashboardData.TodoStatus.CompletedTodos)" -ForegroundColor White
    Write-Host "   High Priority Todos: $($script:DashboardData.TodoStatus.HighPriorityTodos)" -ForegroundColor White
    Write-Host "   Last Update: $($script:DashboardData.TodoStatus.LastUpdate)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📁 Repository Details:" -ForegroundColor Cyan
    foreach ($repo in $script:DashboardData.TodoStatus.Repositories.GetEnumerator()) {
        $todo = $repo.Value
        Write-Host "   $($repo.Key):" -ForegroundColor Yellow
        Write-Host "      Progress: $($todo.Progress)% ($($todo.CompletedTodos)/$($todo.TotalTodos))" -ForegroundColor White
        Write-Host "      High Priority: $($todo.HighPriorityTodos)" -ForegroundColor White
        Write-Host "      Last Modified: $($todo.LastModified)" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "🔧 Available Actions:" -ForegroundColor Cyan
    Write-Host "   Run: scripts/manage-todos.ps1 -Action status" -ForegroundColor Green
    Write-Host "   Run: scripts/manage-todos.ps1 -Action sync" -ForegroundColor Green
    Write-Host "   Run: scripts/manage-todos.ps1 -Action report" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Press any key to return to main dashboard..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SyncDetails {
    Clear-Host
    Write-Host "🔄 File Synchronization Details" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📊 Sync Status:" -ForegroundColor Cyan
    Write-Host "   Configuration Valid: $($script:DashboardData.SyncStatus.ConfigurationValid)" -ForegroundColor White
    Write-Host "   Configured Rules: $($script:DashboardData.SyncStatus.ConfiguredRules)" -ForegroundColor White
    Write-Host "   Enabled Rules: $($script:DashboardData.SyncStatus.EnabledRules)" -ForegroundColor White
    Write-Host "   Successful Syncs: $($script:DashboardData.SyncStatus.SuccessfulSyncs)" -ForegroundColor White
    Write-Host "   Failed Syncs: $($script:DashboardData.SyncStatus.FailedSyncs)" -ForegroundColor White
    Write-Host "   Pending Syncs: $($script:DashboardData.SyncStatus.PendingSyncs)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📁 Repository Sync Status:" -ForegroundColor Cyan
    foreach ($repo in $script:DashboardData.SyncStatus.Repositories.GetEnumerator()) {
        $sync = $repo.Value
        $icon = switch ($sync.Status) {
            "Synced" { "✅" }
            "Pending" { "⏳" }
            "Error" { "❌" }
        }
        Write-Host "   $icon $($repo.Key): $($sync.Status)" -ForegroundColor White
        if ($sync.LastSync) {
            Write-Host "      Last Sync: $($sync.LastSync)" -ForegroundColor Gray
        }
        if ($sync.LastSyncMessage) {
            Write-Host "      Message: $($sync.LastSyncMessage)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "🔧 Available Actions:" -ForegroundColor Cyan
    Write-Host "   Run: scripts/file-sync.ps1 -Action status" -ForegroundColor Green
    Write-Host "   Run: scripts/file-sync.ps1 -Action sync" -ForegroundColor Green
    Write-Host "   Run: scripts/file-sync.ps1 -Action validate" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Press any key to return to main dashboard..." -ForegroundColor Gray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-DashboardData {
    param([string]$Format, [string]$Path)
    
    if (-not $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $Path = "$PSScriptRoot\..\dashboard-export-$timestamp.$Format"
    }
    
    switch ($Format.ToLower()) {
        "json" {
            $script:DashboardData | ConvertTo-Json -Depth 10 | Out-File $Path -Encoding UTF8
        }
        "html" {
            Export-ToHTML $Path
        }
        "markdown" {
            Export-ToMarkdown $Path
        }
    }
    
    Write-Log "Dashboard data exported to: $Path" "SUCCESS"
}

function Export-ToHTML {
    param([string]$Path)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>AI-Whisperers Dashboard</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 20px; margin-bottom: 30px; }
        .section { margin-bottom: 30px; }
        .section h2 { color: #2980b9; border-left: 4px solid #3498db; padding-left: 10px; }
        .metric { display: inline-block; background: #ecf0f1; padding: 10px 15px; margin: 5px; border-radius: 5px; }
        .progress-bar { width: 100%; height: 20px; background: #ecf0f1; border-radius: 10px; overflow: hidden; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #e74c3c, #f39c12, #f1c40f, #2ecc71); transition: width 0.3s ease; }
        .status-good { color: #27ae60; }
        .status-warning { color: #f39c12; }
        .status-error { color: #e74c3c; }
        .repo-card { border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
        .recommendation { background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .timestamp { color: #7f8c8d; font-style: italic; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 AI-Whisperers Management Dashboard</h1>
            <p class="timestamp">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')</p>
        </div>
        
        <div class="section">
            <h2>📊 Overview</h2>
            <div class="metric">Total Todos: $($script:DashboardData.TodoStatus.TotalTodos)</div>
            <div class="metric">Completed: $($script:DashboardData.TodoStatus.CompletedTodos)</div>
            <div class="metric">Repositories: $($script:DashboardData.TodoStatus.TotalRepositories)</div>
            <div class="metric">Sync Rules: $($script:DashboardData.SyncStatus.EnabledRules)</div>
        </div>
        
        <div class="section">
            <h2>✅ Todo Progress</h2>
"@
    
    foreach ($repo in $script:DashboardData.TodoStatus.Repositories.GetEnumerator()) {
        $progress = $repo.Value.Progress
        $html += @"
            <div class="repo-card">
                <h3>$($repo.Key)</h3>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: $progress%"></div>
                </div>
                <p>Progress: $progress% ($($repo.Value.CompletedTodos)/$($repo.Value.TotalTodos))</p>
                <p>High Priority: $($repo.Value.HighPriorityTodos)</p>
            </div>
"@
    }
    
    $html += @"
        </div>
        
        <div class="section">
            <h2>🏥 Repository Health</h2>
            <table>
                <thead>
                    <tr><th>Repository</th><th>Health Score</th><th>Status</th><th>Last Push</th><th>Issues</th></tr>
                </thead>
                <tbody>
"@
    
    foreach ($repo in $script:DashboardData.RepositoryHealth.RepositoryDetails.GetEnumerator()) {
        $health = $repo.Value
        $statusClass = switch ($health.Status) {
            "Excellent" { "status-good" }
            "Good" { "status-good" }
            "Fair" { "status-warning" }
            default { "status-error" }
        }
        
        $html += @"
                    <tr>
                        <td>$($repo.Key)</td>
                        <td>$($health.HealthScore)%</td>
                        <td class="$statusClass">$($health.Status)</td>
                        <td>$($health.LastPush)</td>
                        <td>$($health.OpenIssues)</td>
                    </tr>
"@
    }
    
    $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>💡 Recommendations</h2>
"@
    
    foreach ($rec in $script:DashboardData.Recommendations) {
        $html += @"
            <div class="recommendation">
                <strong>[$($rec.Priority)] $($rec.Title)</strong>
                <p>$($rec.Description)</p>
                <p><em>Action: $($rec.Action)</em></p>
            </div>
"@
    }
    
    $html += @"
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File $Path -Encoding UTF8
}

function Export-ToMarkdown {
    param([string]$Path)
    
    $markdown = @"
# 🚀 AI-Whisperers Management Dashboard

*Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')*

## 📊 Overview

- **Total Todos:** $($script:DashboardData.TodoStatus.TotalTodos)
- **Completed Todos:** $($script:DashboardData.TodoStatus.CompletedTodos)
- **Repositories:** $($script:DashboardData.TodoStatus.TotalRepositories)
- **Active Sync Rules:** $($script:DashboardData.SyncStatus.EnabledRules)/$($script:DashboardData.SyncStatus.ConfiguredRules)

## ✅ Todo Progress

"@
    
    foreach ($repo in $script:DashboardData.TodoStatus.Repositories.GetEnumerator()) {
        $progress = $repo.Value.Progress
        $progressBar = "█" * [math]::Floor($progress / 10) + "░" * (10 - [math]::Floor($progress / 10))
        $markdown += @"
### $($repo.Key)
- Progress: [$progressBar] $progress% ($($repo.Value.CompletedTodos)/$($repo.Value.TotalTodos))
- High Priority Todos: $($repo.Value.HighPriorityTodos)

"@
    }
    
    $markdown += @"
## 🏥 Repository Health

| Repository | Health Score | Status | Last Push | Open Issues |
|------------|-------------|--------|-----------|-------------|
"@
    
    foreach ($repo in $script:DashboardData.RepositoryHealth.RepositoryDetails.GetEnumerator()) {
        $health = $repo.Value
        $markdown += "| $($repo.Key) | $($health.HealthScore)% | $($health.Status) | $($health.LastPush) | $($health.OpenIssues) |`n"
    }
    
    $markdown += @"

## 💡 Recommendations

"@
    
    foreach ($rec in $script:DashboardData.Recommendations) {
        $icon = switch ($rec.Type) {
            "Action" { "🎯" }
            "Warning" { "⚠️" }
            "Improvement" { "📈" }
        }
        $markdown += @"
### $icon [$($rec.Priority)] $($rec.Title)

$($rec.Description)

**Action:** $($rec.Action)

"@
    }
    
    $markdown | Out-File $Path -Encoding UTF8
}

function Collect-AllData {
    Write-Log "Collecting dashboard data..." "DEBUG"
    
    Get-TodoSummary
    Get-SyncStatus
    Get-RepositoryHealth
    Get-SystemMetrics
    Generate-Recommendations
    
    $script:DashboardData.Timestamp = Get-Date
}

# Main execution
function Main {
    Write-Log "Starting AI-Whisperers Management Dashboard" "SUCCESS"
    
    # Initialize
    if (-not (Import-Configurations)) {
        Write-Log "Failed to load configurations" "ERROR"
        return
    }
    
    if (-not (Test-SystemPrerequisites)) {
        Write-Log "System prerequisites not met" "ERROR"
        return
    }
    
    # Collect initial data
    Collect-AllData
    
    switch ($Mode.ToLower()) {
        "interactive" {
            Show-InteractiveDashboard
        }
        "summary" {
            Write-Host "🚀 AI-Whisperers Dashboard Summary" -ForegroundColor Green
            Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Todos: $($script:DashboardData.TodoStatus.CompletedTodos)/$($script:DashboardData.TodoStatus.TotalTodos) completed" -ForegroundColor White
            Write-Host "Repositories: $($script:DashboardData.RepositoryHealth.HealthyRepositories)/$($script:DashboardData.RepositoryHealth.TotalRepositories) healthy" -ForegroundColor White
            Write-Host "Sync Rules: $($script:DashboardData.SyncStatus.EnabledRules)/$($script:DashboardData.SyncStatus.ConfiguredRules) enabled" -ForegroundColor White
            
            if ($script:DashboardData.Recommendations.Count -gt 0) {
                Write-Host "`nTop Recommendations:" -ForegroundColor Yellow
                $topRecommendations = $script:DashboardData.Recommendations | Where-Object { $_.Priority -eq "High" } | Select-Object -First 3
                foreach ($rec in $topRecommendations) {
                    Write-Host "- $($rec.Title)" -ForegroundColor White
                }
            }
        }
        "export" {
            Export-DashboardData $ExportFormat $OutputPath
        }
        default {
            Write-Host @"
Usage: dashboard.ps1 [options]

Modes:
  -Mode interactive  Launch interactive dashboard (default)
  -Mode summary      Show summary information
  -Mode export       Export dashboard data

Export Options:
  -ExportFormat html|json|markdown   Export format (default: html)
  -OutputPath path                   Output file path

Interactive Options:
  -RefreshInterval seconds           Auto-refresh interval (default: 30)
  -ShowDetails                       Show detailed information
  -Quiet                            Suppress non-essential output

Examples:
  .\dashboard.ps1                              # Interactive mode
  .\dashboard.ps1 -Mode summary                # Quick summary
  .\dashboard.ps1 -Mode export -ExportFormat html
  .\dashboard.ps1 -RefreshInterval 60          # 60-second refresh

"@ -ForegroundColor Gray
        }
    }
}

# Run the script
if ($MyInvocation.InvocationName -ne '.') {
    Main
}