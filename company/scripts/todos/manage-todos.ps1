# AI-Whisperers Todo Management Script
# Manages todos across all organization repositories

param(
    [string]$Action = "status",  # status, sync, report, push
    [string]$Repository = "",    # specific repository to target
    [int]$Days = 7,             # days to look back for status
    [switch]$Force,             # force push todos even if conflicts
    [switch]$Verbose            # verbose output
)

# Configuration
$script:Config = @{
    Organization = "Ai-Whisperers"
    TodosPath = "$PSScriptRoot\..\project-todos"
    Repositories = @{
        "web-platform" = @{
            File = "web-platform-todos.md"
            Label = "todo-sync"
            Technology = "React/Next.js"
        }
        "core-services" = @{
            File = "core-services-todos.md"
            Label = "todo-sync"
            Technology = "Python/Node.js"
        }
        "ml-models" = @{
            File = "ml-models-todos.md"
            Label = "todo-sync"
            Technology = "PyTorch/TensorFlow"
        }
        "documentation" = @{
            File = "documentation-todos.md"
            Label = "todo-sync"
            Technology = "Markdown/Docs"
        }
        "infrastructure" = @{
            File = "infrastructure-todos.md"
            Label = "todo-sync"
            Technology = "Docker/Kubernetes"
        }
        "Company-Information" = @{
            File = "company-information-todos.md"
            Label = "todo-sync"
            Technology = "Management"
        }
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] ${Level}: $Message" -ForegroundColor $color
}

function Test-GitHubCLI {
    try {
        $null = gh --version
        return $true
    }
    catch {
        Write-Log "GitHub CLI not found. Please install: winget install GitHub.cli" "ERROR"
        return $false
    }
}

function Test-GitHubAuth {
    try {
        $user = gh api user --jq .login 2>$null
        if ($user) {
            Write-Log "Authenticated as GitHub user: $user" "SUCCESS"
            return $true
        }
    }
    catch {}
    
    Write-Log "Not authenticated with GitHub. Run: gh auth login" "ERROR"
    return $false
}

function Get-TodoContent {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "Todo file not found: $FilePath" "ERROR"
        return $null
    }
    
    $content = Get-Content $FilePath -Raw
    $todos = @()
    
    # Parse markdown checkboxes
    $lines = $content -split "`n"
    $currentSection = "General"
    
    foreach ($line in $lines) {
        if ($line -match "^##\s+(.+)") {
            $currentSection = $matches[1].Trim()
        }
        elseif ($line -match "^-\s+\[([ x])\]\s+(.+)") {
            $completed = $matches[1] -eq "x"
            $task = $matches[2].Trim()
            
            $todos += @{
                Section = $currentSection
                Task = $task
                Completed = $completed
                Line = $line
            }
        }
    }
    
    return $todos
}

function Get-RepositoryTodoStatus {
    param([string]$RepoName)
    
    try {
        # Get issues with todo-sync label
        $issues = gh api "repos/$($script:Config.Organization)/$RepoName/issues" `
            --jq '.[] | select(.labels[]?.name == "todo-sync") | {number: .number, title: .title, state: .state, updated_at: .updated_at}' 2>$null
        
        if ($issues) {
            $issueData = $issues | ConvertFrom-Json
            return @{
                HasTodos = $true
                Issues = if ($issueData -is [array]) { $issueData } else { @($issueData) }
                LastUpdate = ($issueData | Sort-Object updated_at -Descending | Select-Object -First 1).updated_at
            }
        }
    }
    catch {
        Write-Log "Could not access repository: $RepoName" "WARN"
    }
    
    return @{
        HasTodos = $false
        Issues = @()
        LastUpdate = $null
    }
}

function Push-TodosToRepository {
    param([string]$RepoName, [array]$Todos)
    
    $repoConfig = $script:Config.Repositories[$RepoName]
    if (-not $repoConfig) {
        Write-Log "Unknown repository: $RepoName" "ERROR"
        return $false
    }
    
    # Build todo content for issue
    $issueBody = @"
# Todos for $RepoName

This issue contains todos synchronized from the Company-Information repository.

**Technology Stack:** $($repoConfig.Technology)
**Source File:** ``project-todos/$($repoConfig.File)``
**Last Sync:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

## Tasks

"@
    
    $completedCount = 0
    $totalCount = 0
    
    foreach ($section in ($Todos | Group-Object Section)) {
        $issueBody += "`n### $($section.Name)`n`n"
        
        foreach ($todo in $section.Group) {
            $checkbox = if ($todo.Completed) { "[x]" } else { "[ ]" }
            $issueBody += "- $checkbox $($todo.Task)`n"
            
            $totalCount++
            if ($todo.Completed) { $completedCount++ }
        }
    }
    
    $progress = if ($totalCount -gt 0) { [math]::Round(($completedCount / $totalCount) * 100) } else { 0 }
    $issueBody += "`n---`n**Progress:** $completedCount/$totalCount tasks completed ($progress%)"
    $issueBody += "`n**Auto-generated** by Company-Information todo management system"
    
    try {
        # Check for existing todo-sync issue
        $existingIssues = gh api "repos/$($script:Config.Organization)/$RepoName/issues" `
            --jq '.[] | select(.labels[]?.name == "todo-sync" and .state == "open") | .number' 2>$null
        
        $title = "Todo Sync - $(Get-Date -Format 'yyyy-MM-dd')"
        
        if ($existingIssues) {
            # Update existing issue
            $issueNumber = ($existingIssues | ConvertFrom-Json)[0]
            gh api "repos/$($script:Config.Organization)/$RepoName/issues/$issueNumber" `
                --method PATCH `
                --field title="$title" `
                --field body="$issueBody" >$null
            
            Write-Log "Updated todo issue #$issueNumber in $RepoName" "SUCCESS"
        }
        else {
            # Create new issue
            $result = gh api "repos/$($script:Config.Organization)/$RepoName/issues" `
                --method POST `
                --field title="$title" `
                --field body="$issueBody" `
                --field labels='["todo-sync","automated"]' 2>$null
            
            $issueNumber = ($result | ConvertFrom-Json).number
            Write-Log "Created todo issue #$issueNumber in $RepoName" "SUCCESS"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to create/update todo issue in $RepoName`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-TodoStatus {
    param([string]$TargetRepo = "")
    
    Write-Host "`n=== AI-Whisperers Todo Status ===" -ForegroundColor Cyan
    Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    $totalRepos = 0
    $activeRepos = 0
    $totalTodos = 0
    $completedTodos = 0
    
    foreach ($repo in $script:Config.Repositories.Keys) {
        if ($TargetRepo -and $repo -ne $TargetRepo) { continue }
        
        $totalRepos++
        $todoFile = Join-Path $script:Config.TodosPath $script:Config.Repositories[$repo].File
        
        Write-Host "`n📁 $repo" -ForegroundColor Yellow
        
        if (Test-Path $todoFile) {
            $todos = Get-TodoContent $todoFile
            if ($todos -and $todos.Count -gt 0) {
                $activeRepos++
                $repoCompleted = ($todos | Where-Object Completed).Count
                $repoTotal = $todos.Count
                $repoProgress = if ($repoTotal -gt 0) { [math]::Round(($repoCompleted / $repoTotal) * 100) } else { 0 }
                
                $totalTodos += $repoTotal
                $completedTodos += $repoCompleted
                
                Write-Host "   └── $repoTotal todos ($repoCompleted completed - $repoProgress%)" -ForegroundColor White
                
                # Show recent activity
                $repoStatus = Get-RepositoryTodoStatus $repo
                if ($repoStatus.HasTodos) {
                    $lastUpdate = if ($repoStatus.LastUpdate) { 
                        (Get-Date $repoStatus.LastUpdate).ToString('MM/dd HH:mm')
                    } else { "Unknown" }
                    Write-Host "   └── Last sync: $lastUpdate" -ForegroundColor Gray
                    Write-Host "   └── GitHub issues: $($repoStatus.Issues.Count)" -ForegroundColor Gray
                }
                else {
                    Write-Host "   └── Not yet synced to GitHub" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "   └── No todos found" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "   └── Todo file missing" -ForegroundColor Red
        }
    }
    
    # Summary
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total repositories: $totalRepos" -ForegroundColor White
    Write-Host "Active repositories: $activeRepos" -ForegroundColor White
    Write-Host "Total todos: $totalTodos" -ForegroundColor White
    Write-Host "Completed todos: $completedTodos" -ForegroundColor Green
    
    if ($totalTodos -gt 0) {
        $overallProgress = [math]::Round(($completedTodos / $totalTodos) * 100)
        Write-Host "Overall progress: $overallProgress%" -ForegroundColor $(if ($overallProgress -ge 75) { "Green" } elseif ($overallProgress -ge 50) { "Yellow" } else { "Red" })
    }
}

function Sync-AllTodos {
    Write-Host "`n=== Syncing Todos to GitHub ===" -ForegroundColor Cyan
    
    $successCount = 0
    $failCount = 0
    
    foreach ($repo in $script:Config.Repositories.Keys) {
        $todoFile = Join-Path $script:Config.TodosPath $script:Config.Repositories[$repo].File
        
        if (Test-Path $todoFile) {
            Write-Host "`nProcessing $repo..." -ForegroundColor Yellow
            
            $todos = Get-TodoContent $todoFile
            if ($todos -and $todos.Count -gt 0) {
                if (Push-TodosToRepository $repo $todos) {
                    $successCount++
                }
                else {
                    $failCount++
                }
            }
            else {
                Write-Log "No todos found in $repo, skipping" "WARN"
            }
        }
        else {
            Write-Log "Todo file not found for $repo" "WARN"
            $failCount++
        }
    }
    
    Write-Host "`n=== Sync Complete ===" -ForegroundColor Cyan
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
}

function Show-TodoReport {
    Write-Host "`n=== AI-Whisperers Todo Report ===" -ForegroundColor Cyan
    Write-Host "Report Period: Last $Days days" -ForegroundColor Gray
    Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    # Detailed breakdown by repository
    foreach ($repo in $script:Config.Repositories.Keys) {
        $todoFile = Join-Path $script:Config.TodosPath $script:Config.Repositories[$repo].File
        
        if (Test-Path $todoFile) {
            $todos = Get-TodoContent $todoFile
            if ($todos -and $todos.Count -gt 0) {
                Write-Host "`n📊 $repo Analysis" -ForegroundColor Yellow
                
                # Progress by section
                $sections = $todos | Group-Object Section
                foreach ($section in $sections) {
                    $sectionCompleted = ($section.Group | Where-Object Completed).Count
                    $sectionTotal = $section.Group.Count
                    $sectionProgress = if ($sectionTotal -gt 0) { [math]::Round(($sectionCompleted / $sectionTotal) * 100) } else { 0 }
                    
                    Write-Host "   $($section.Name): $sectionCompleted/$sectionTotal ($sectionProgress%)" -ForegroundColor White
                }
                
                # Show incomplete high priority items
                $highPriority = $todos | Where-Object { $_.Section -eq "High Priority" -and -not $_.Completed }
                if ($highPriority) {
                    Write-Host "   🔥 High Priority Items:" -ForegroundColor Red
                    $highPriority | ForEach-Object {
                        Write-Host "      - $($_.Task)" -ForegroundColor White
                    }
                }
            }
        }
    }
}

# Main execution
function Main {
    Write-Host "AI-Whisperers Todo Management System" -ForegroundColor Green
    
    # Verify prerequisites
    if (-not (Test-GitHubCLI)) { return }
    if (-not (Test-GitHubAuth)) { return }
    
    switch ($Action.ToLower()) {
        "status" { 
            Show-TodoStatus $Repository 
        }
        "sync" { 
            Sync-AllTodos 
        }
        "report" { 
            Show-TodoReport 
        }
        "push" {
            if ($Repository) {
                $todoFile = Join-Path $script:Config.TodosPath $script:Config.Repositories[$Repository].File
                if (Test-Path $todoFile) {
                    $todos = Get-TodoContent $todoFile
                    if ($todos) {
                        Push-TodosToRepository $Repository $todos
                    }
                }
            }
            else {
                Write-Log "Repository name required for push action" "ERROR"
            }
        }
        default { 
            Write-Host @"

Usage: manage-todos.ps1 [options]

Actions:
  -Action status     Show current todo status across all repositories (default)
  -Action sync       Sync all todos to GitHub issues
  -Action report     Generate detailed todo report
  -Action push       Push todos for specific repository

Options:
  -Repository name   Target specific repository
  -Days number       Days to look back for status (default: 7)
  -Force            Force operations even with conflicts
  -Verbose          Detailed output

Examples:
  .\manage-todos.ps1                              # Show status
  .\manage-todos.ps1 -Action sync                 # Sync all todos
  .\manage-todos.ps1 -Action report -Days 14      # 14-day report
  .\manage-todos.ps1 -Action push -Repository web-platform

"@ -ForegroundColor Gray
        }
    }
}

# Run the script
if ($MyInvocation.InvocationName -ne '.') {
    Main
}