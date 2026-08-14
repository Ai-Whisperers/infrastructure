# AI-Whisperers Todo Management System
param(
    [Parameter(Position=0)]
    [ValidateSet("list", "status", "report")]
    [string]$Action = "status",

    [string]$Repository = "all"
)

# Load path resolver utility
. "$PSScriptRoot\common\PathResolver.ps1"

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    OutputPath = ".\todo-reports"
}

# Ensure output directory exists
if (-not (Test-Path $Config.OutputPath)) {
    New-Item -ItemType Directory -Path $Config.OutputPath -Force | Out-Null
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
}

function Get-AllRepositories {
    try {
        $repos = gh repo list $Config.Organization --json name,url --limit 100 | ConvertFrom-Json
        if (-not $repos) {
            Write-Error "No repositories found. Run 'gh auth login' first."
            return @()
        }
        return $repos
    }
    catch {
        Write-Error "Failed to fetch repositories: $($_.Exception.Message)"
        return @()
    }
}

function Get-LocalTodoFile {
    param([string]$RepoName)

    $todoPath = Get-ProjectPath "project-todos\$RepoName-TODO.md"
    if (Test-Path $todoPath) {
        return Get-Content $todoPath -Raw
    }

    # Check for company-information-todos.md specifically
    if ($RepoName -eq "Company-Information") {
        $companyTodoPath = Get-ProjectPath "project-todos\company-information-todos.md"
        if (Test-Path $companyTodoPath) {
            return Get-Content $companyTodoPath -Raw
        }
    }

    return $null
}

function Parse-TodoContent {
    param(
        [string]$Content,
        [string]$Repository
    )
    
    if (-not $Content) {
        return @{
            Repository = $Repository
            Todos = @()
            TotalCount = 0
            CompletedCount = 0
        }
    }
    
    $todos = @()
    $currentPriority = "Medium"
    $lines = $Content -split "`n"
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        
        # Check for priority headers
        if ($line -match "## (High|Medium|Low) Priority") {
            $currentPriority = $Matches[1]
            continue
        }
        
        # Check for todo items
        if ($line -match "^- \[([ x])\] (.+)$") {
            $isCompleted = $Matches[1] -eq "x"
            $description = $Matches[2].Trim()
            
            $todos += @{
                Repository = $Repository
                Description = $description
                Priority = $currentPriority
                Completed = $isCompleted
            }
        }
    }
    
    $completedCount = ($todos | Where-Object { $_.Completed }).Count
    
    return @{
        Repository = $Repository
        Todos = $todos
        TotalCount = $todos.Count
        CompletedCount = $completedCount
    }
}

function Show-TodoStatus {
    Write-Header "AI-Whisperers Todo Status Dashboard"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    Write-Host "Repository Status Overview" -ForegroundColor Cyan
    Write-Host ("-" * 80) -ForegroundColor DarkGray
    Write-Host ""
    
    $format = "{0,-35} {1,8} {2,8} {3,8} {4,8}"
    Write-Host ($format -f "Repository", "Total", "Done", "Open", "Progress") -ForegroundColor Yellow
    Write-Host ("-" * 80) -ForegroundColor DarkGray
    
    $orgTotal = 0
    $orgCompleted = 0
    
    foreach ($repo in $repos) {
        $todoContent = Get-LocalTodoFile -RepoName $repo.name
        $repoTodos = Parse-TodoContent -Content $todoContent -Repository $repo.name
        
        if ($repoTodos.TotalCount -gt 0) {
            $progress = if ($repoTodos.TotalCount -gt 0) { 
                [math]::Round(($repoTodos.CompletedCount / $repoTodos.TotalCount) * 100) 
            } else { 0 }
            
            $progressColor = if ($progress -eq 100) { "Green" } 
                            elseif ($progress -gt 75) { "Yellow" } 
                            elseif ($progress -gt 50) { "Cyan" } 
                            else { "Red" }
            
            $repoName = if ($repo.name.Length -gt 34) { $repo.name.Substring(0, 34) } else { $repo.name }
            
            Write-Host ($format -f 
                $repoName,
                $repoTodos.TotalCount,
                $repoTodos.CompletedCount,
                ($repoTodos.TotalCount - $repoTodos.CompletedCount),
                "$progress%"
            ) -ForegroundColor $progressColor
            
            $orgTotal += $repoTodos.TotalCount
            $orgCompleted += $repoTodos.CompletedCount
        } else {
            $repoName = if ($repo.name.Length -gt 34) { $repo.name.Substring(0, 34) } else { $repo.name }
            Write-Host ($format -f $repoName, 0, 0, 0, "N/A") -ForegroundColor DarkGray
        }
    }
    
    Write-Host ("-" * 80) -ForegroundColor DarkGray
    $orgProgress = if ($orgTotal -gt 0) { [math]::Round(($orgCompleted / $orgTotal) * 100) } else { 0 }
    Write-Host ($format -f "ORGANIZATION TOTAL", $orgTotal, $orgCompleted, ($orgTotal - $orgCompleted), "$orgProgress%") -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Total todos found: $orgTotal" -ForegroundColor Gray
    Write-Host "  Completed: $orgCompleted" -ForegroundColor Green
    Write-Host "  Remaining: $($orgTotal - $orgCompleted)" -ForegroundColor Yellow
    Write-Host "  Overall progress: $orgProgress%" -ForegroundColor $(if ($orgProgress -gt 75) { "Green" } else { "Yellow" })
}

function Show-TodoList {
    Write-Header "AI-Whisperers Todo List"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    foreach ($repo in $repos) {
        $todoContent = Get-LocalTodoFile -RepoName $repo.name
        $repoTodos = Parse-TodoContent -Content $todoContent -Repository $repo.name
        
        if ($repoTodos.TotalCount -gt 0) {
            Write-Host ""
            Write-Host "=== $($repo.name) ===" -ForegroundColor Yellow
            Write-Host "($($repoTodos.TotalCount) todos, $($repoTodos.CompletedCount) completed)" -ForegroundColor Gray
            Write-Host ""
            
            $priorityGroups = $repoTodos.Todos | Group-Object Priority
            
            foreach ($group in ($priorityGroups | Sort-Object { 
                switch ($_.Name) { 
                    "High" { 1 } 
                    "Medium" { 2 } 
                    "Low" { 3 } 
                    default { 4 } 
                }
            })) {
                $priorityColor = switch ($group.Name) {
                    "High" { "Red" }
                    "Medium" { "Yellow" }
                    "Low" { "Green" }
                    default { "Gray" }
                }
                
                Write-Host "$($group.Name) Priority:" -ForegroundColor $priorityColor
                
                foreach ($todo in $group.Group) {
                    $status = if ($todo.Completed) { "[DONE]" } else { "[TODO]" }
                    $color = if ($todo.Completed) { "Green" } else { "White" }
                    Write-Host "  $status $($todo.Description)" -ForegroundColor $color
                }
                Write-Host ""
            }
        }
    }
}

function Generate-TodoReport {
    Write-Header "Generating Todo Report"
    
    $repos = Get-AllRepositories
    $reportData = @()
    
    foreach ($repo in $repos) {
        $todoContent = Get-LocalTodoFile -RepoName $repo.name
        $repoTodos = Parse-TodoContent -Content $todoContent -Repository $repo.name
        
        if ($repoTodos.TotalCount -gt 0) {
            foreach ($todo in $repoTodos.Todos) {
                $reportData += [PSCustomObject]@{
                    Repository = $todo.Repository
                    Priority = $todo.Priority
                    Description = $todo.Description
                    Completed = $todo.Completed
                    Status = if ($todo.Completed) { "Done" } else { "Open" }
                }
            }
        }
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $csvPath = Join-Path $Config.OutputPath "todo-report-$timestamp.csv"
    
    if ($reportData.Count -gt 0) {
        $reportData | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Report generated: $csvPath" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "Report Summary:" -ForegroundColor Cyan
        Write-Host "  Total todos: $($reportData.Count)" -ForegroundColor Gray
        Write-Host "  Completed: $(($reportData | Where-Object {$_.Completed}).Count)" -ForegroundColor Green
        Write-Host "  Open: $(($reportData | Where-Object {-not $_.Completed}).Count)" -ForegroundColor Yellow
    } else {
        Write-Host "No todos found to generate report" -ForegroundColor Yellow
    }
}

# Main execution
switch ($Action.ToLower()) {
    "status" { Show-TodoStatus }
    "list" { Show-TodoList }
    "report" { Generate-TodoReport }
    default { Write-Error "Invalid action: $Action. Use: status, list, or report" }
}