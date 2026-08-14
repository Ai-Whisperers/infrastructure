# Excalibur Command Handler
# Magic command: "claude pull excalibur"
# Fetches GitHub organization data and updates all todos

param(
    [string]$Action = "sync",
    [switch]$DryRun,
    [switch]$Verbose
)

# Load path resolver utility
. "$PSScriptRoot\common\PathResolver.ps1"

# Configuration
$OrganizationName = "Ai-Whisperers"
$TodosDirectory = Get-ProjectPath "project-todos"
$LogFile = Get-ProjectPath "logs\excalibur-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Ensure logs directory exists
Ensure-DirectoryExists (Get-ProjectPath "logs") -Silent

function Write-ExcaliburLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Output $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
    
    if ($Verbose) {
        switch ($Level) {
            "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
            "WARN" { Write-Host $LogEntry -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
            default { Write-Host $LogEntry -ForegroundColor White }
        }
    }
}

function Test-Prerequisites {
    Write-ExcaliburLog "Checking prerequisites..."
    
    # Check if GitHub CLI is installed
    try {
        $ghVersion = gh --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "GitHub CLI not found"
        }
        Write-ExcaliburLog "GitHub CLI found: $($ghVersion[0])" "SUCCESS"
    }
    catch {
        Write-ExcaliburLog "GitHub CLI is not installed or not in PATH" "ERROR"
        return $false
    }
    
    # Check if authenticated with GitHub
    try {
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Not authenticated with GitHub"
        }
        Write-ExcaliburLog "GitHub authentication verified" "SUCCESS"
    }
    catch {
        Write-ExcaliburLog "Not authenticated with GitHub. Run 'gh auth login'" "ERROR"
        return $false
    }
    
    return $true
}

function Get-OrganizationRepositories {
    Write-ExcaliburLog "Fetching repositories from $OrganizationName organization..."
    
    try {
        $repos = gh repo list $OrganizationName --json name,description,pushedAt,url,isPrivate,hasIssuesEnabled --limit 100 | ConvertFrom-Json
        Write-ExcaliburLog "Found $($repos.Count) repositories" "SUCCESS"
        return $repos
    }
    catch {
        Write-ExcaliburLog "Failed to fetch repositories: $_" "ERROR"
        return @()
    }
}

function Get-RepositoryDetails {
    param([object]$Repository)
    
    Write-ExcaliburLog "Fetching details for $($Repository.name)..."
    
    try {
        # Get issues
        $issues = @()
        if ($Repository.hasIssuesEnabled) {
            $issues = gh issue list --repo "$OrganizationName/$($Repository.name)" --json number,title,state,labels,createdAt --limit 50 | ConvertFrom-Json
        }
        
        # Get pull requests
        $prs = gh pr list --repo "$OrganizationName/$($Repository.name)" --json number,title,state,createdAt --limit 20 | ConvertFrom-Json
        
        # Get recent commits
        $commits = gh api "repos/$OrganizationName/$($Repository.name)/commits" --jq '.[0:5] | .[] | {sha: .sha[0:7], message: .commit.message, date: .commit.author.date, author: .commit.author.name}' | ConvertFrom-Json
        
        return @{
            Repository = $Repository
            Issues = $issues
            PullRequests = $prs
            RecentCommits = $commits
        }
    }
    catch {
        Write-ExcaliburLog "Failed to fetch details for $($Repository.name): $_" "WARN"
        return @{
            Repository = $Repository
            Issues = @()
            PullRequests = @()
            RecentCommits = @()
        }
    }
}

function Update-RepositoryTodos {
    param([object]$RepoDetails)
    
    $repoName = $RepoDetails.Repository.name
    $todoFile = "$TodosDirectory\$($repoName.ToLower())-todos.md"
    
    Write-ExcaliburLog "Updating todos for $repoName..."
    
    # Generate updated todo content based on repository analysis
    $updatedContent = Generate-TodoContent -RepoDetails $RepoDetails
    
    if ($DryRun) {
        Write-ExcaliburLog "DRY RUN: Would update $todoFile" "INFO"
        return
    }
    
    try {
        # Backup existing file if it exists
        if (Test-Path $todoFile) {
            $backupFile = "$todoFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $todoFile $backupFile
            Write-ExcaliburLog "Backed up existing file to $backupFile"
        }
        
        # Write updated content
        Set-Content -Path $todoFile -Value $updatedContent -Encoding UTF8
        Write-ExcaliburLog "Updated $todoFile" "SUCCESS"
        
        # If repository has todos in its own repo, sync them there too
        Sync-RepositoryTodos -RepoName $repoName -TodoContent $updatedContent
    }
    catch {
        Write-ExcaliburLog "Failed to update todos for ${repoName}: $($_.Exception.Message)" "ERROR"
    }
}

function Generate-TodoContent {
    param([object]$RepoDetails)
    
    $repo = $RepoDetails.Repository
    $issues = $RepoDetails.Issues
    $prs = $RepoDetails.PullRequests
    $commits = $RepoDetails.RecentCommits
    
    $content = @"
# $($repo.name) Todo List

## Repository Status
- **Last Updated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Description**: $($repo.description)
- **Last Push**: $($repo.pushedAt)
- **Open Issues**: $($issues.Count)
- **Open PRs**: $($prs.Count)

## Current Issues (From GitHub)
"@

    if ($issues.Count -gt 0) {
        foreach ($issue in $issues) {
            $labels = ($issue.labels | ForEach-Object { $_.name }) -join ", "
            $content += @"

### Issue #$($issue.number): $($issue.title)
- **Status**: $($issue.state)
- **Labels**: $labels
- **Created**: $($issue.createdAt)
- [ ] Address issue: $($issue.title)
"@
        }
    } else {
        $content += "`n- No open issues found"
    }
    
    $content += @"

## Active Pull Requests
"@

    if ($prs.Count -gt 0) {
        foreach ($pr in $prs) {
            $content += @"

### PR #$($pr.number): $($pr.title)
- **Status**: $($pr.state)
- **Created**: $($pr.createdAt)
- [ ] Review and merge: $($pr.title)
"@
        }
    } else {
        $content += "`n- No open pull requests"
    }
    
    $content += @"

## Recent Activity
"@

    if ($commits.Count -gt 0) {
        foreach ($commit in $commits) {
            $content += @"

- **$($commit.sha)**: $($commit.message.Split("`n")[0]) by $($commit.author) on $($commit.date)
"@
        }
    }
    
    # Add repository-specific todo templates based on repository name
    $content += Get-RepositorySpecificTodos -RepoName $repo.name
    
    return $content
}

function Get-RepositorySpecificTodos {
    param([string]$RepoName)
    
    $specificTodos = switch ($RepoName.ToLower()) {
        "ai-investment" {
            @"

## High Priority Development Tasks
- [ ] Complete security audit and penetration testing
- [ ] Implement comprehensive API rate limiting
- [ ] Add real-time portfolio performance dashboard
- [ ] Optimize database queries for better performance
- [ ] Implement automated trading signal generation
- [ ] Add comprehensive error boundary handling

## Medium Priority Tasks
- [ ] Increase test coverage to 90%+
- [ ] Add end-to-end testing for trading workflows
- [ ] Implement caching strategy with Redis
- [ ] Add social trading features
- [ ] Create investment recommendations engine
"@
        }
        "comment-analizer" {
            @"

## High Priority Enhancement Tasks
- [ ] Add support for additional file formats (CSV, JSON, XML)
- [ ] Implement batch processing for multiple files
- [ ] Add custom analysis prompt templates
- [ ] Improve error handling for malformed input data
- [ ] Expand language support (Portuguese, French)
- [ ] Optimize memory usage for large datasets

## Medium Priority Tasks
- [ ] Redesign UI with modern Streamlit components
- [ ] Add data visualization charts and graphs
- [ ] Implement export to multiple formats
- [ ] Add direct social media API integration
- [ ] Create sentiment trend analysis over time
"@
        }
        "wpg-amenities" {
            @"

## Core Development Tasks
- [ ] Complete basic web application framework setup
- [ ] Implement database schema for local businesses
- [ ] Create user registration and authentication system
- [ ] Add business listing creation and management
- [ ] Implement search and filtering functionality
- [ ] Add geolocation and mapping integration

## User Experience Tasks
- [ ] Design responsive mobile-first interface
- [ ] Add advanced search with filters
- [ ] Implement user reviews and rating system
- [ ] Create personalized recommendations
"@
        }
        default {
            @"

## General Development Tasks
- [ ] Update documentation and README
- [ ] Add or improve test coverage
- [ ] Review and update dependencies
- [ ] Implement CI/CD pipeline improvements
- [ ] Add security scanning and vulnerability checks
- [ ] Optimize performance and resource usage
"@
        }
    }
    
    return $specificTodos
}

function Sync-RepositoryTodos {
    param([string]$RepoName, [string]$TodoContent)
    
    Write-ExcaliburLog "Syncing todos to $RepoName repository..."
    
    try {
        # Check if repository has a TODO.md or similar file
        $repoTodoFiles = @("TODO.md", "TODOS.md", ".github/TODO.md", "docs/TODO.md")
        $targetTodoFile = $null
        
        foreach ($file in $repoTodoFiles) {
            try {
                gh api "repos/$OrganizationName/$RepoName/contents/$file" | Out-Null
                $targetTodoFile = $file
                break
            }
            catch {
                # File doesn't exist, continue checking
                continue
            }
        }
        
        if (-not $targetTodoFile) {
            # Create TODO.md in the repository
            $targetTodoFile = "TODO.md"
        }
        
        if ($DryRun) {
            Write-ExcaliburLog "DRY RUN: Would sync todos to $RepoName/$targetTodoFile"
            return
        }
        
        # Create a temporary file with the content
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $TodoContent -Encoding UTF8
        
        # Try to update or create the file in the repository
        try {
            # Check if file exists first
            $existingFile = gh api "repos/$OrganizationName/$RepoName/contents/$targetTodoFile" 2>$null | ConvertFrom-Json
            
            # File exists, update it
            $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TodoContent))
            $updatePayload = @{
                message = "🤖 Update todos via Excalibur command`n`nGenerated with Claude Code"
                content = $encodedContent
                sha = $existingFile.sha
            } | ConvertTo-Json
            
            $updatePayload | gh api "repos/$OrganizationName/$RepoName/contents/$targetTodoFile" -X PUT --input -
            Write-ExcaliburLog "Updated $targetTodoFile in $RepoName repository" "SUCCESS"
        }
        catch {
            # File doesn't exist, create it
            $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TodoContent))
            $createPayload = @{
                message = "🤖 Create todos via Excalibur command`n`nGenerated with Claude Code"
                content = $encodedContent
            } | ConvertTo-Json
            
            $createPayload | gh api "repos/$OrganizationName/$RepoName/contents/$targetTodoFile" -X PUT --input -
            Write-ExcaliburLog "Created $targetTodoFile in $RepoName repository" "SUCCESS"
        }
        
        # Clean up temp file
        Remove-Item $tempFile -Force
    }
    catch {
        Write-ExcaliburLog "Failed to sync todos to ${RepoName} repository: $($_.Exception.Message)" "WARN"
    }
}

function Invoke-ExcaliburCommand {
    Write-ExcaliburLog "🗡️ Excalibur command initiated!" "SUCCESS"
    Write-ExcaliburLog "Fetching GitHub organization data and updating todos..."
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-ExcaliburLog "Prerequisites not met. Aborting." "ERROR"
        return
    }
    
    # Get all repositories
    $repositories = Get-OrganizationRepositories
    if ($repositories.Count -eq 0) {
        Write-ExcaliburLog "No repositories found. Aborting." "ERROR"
        return
    }
    
    # Process each repository
    foreach ($repo in $repositories) {
        Write-ExcaliburLog "Processing $($repo.name)..."
        
        $repoDetails = Get-RepositoryDetails -Repository $repo
        Update-RepositoryTodos -RepoDetails $repoDetails
    }
    
    # Generate summary report
    $summaryFile = "$TodosDirectory\excalibur-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    Generate-SummaryReport -Repositories $repositories -OutputFile $summaryFile
    
    Write-ExcaliburLog "🗡️ Excalibur command completed! Summary: $summaryFile" "SUCCESS"
}

function Generate-SummaryReport {
    param([array]$Repositories, [string]$OutputFile)
    
    $summary = @"
# Excalibur Command Execution Summary

**Execution Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Organization**: $OrganizationName
**Repositories Processed**: $($Repositories.Count)

## Repository Status Overview

"@

    foreach ($repo in $Repositories | Sort-Object name) {
        $lastPush = if ($repo.pushedAt) { [DateTime]::Parse($repo.pushedAt).ToString("yyyy-MM-dd") } else { "Unknown" }
        $issueStatus = if ($repo.hasIssuesEnabled) { "Issues enabled" } else { "Issues disabled" }
        $summary += "- **$($repo.name)**: Last push $lastPush, $issueStatus`n"
    }
    
    $summary += @"

## Actions Taken
- Fetched current repository status from GitHub API
- Updated local todo files in $TodosDirectory
- Synchronized todos to respective repositories (where applicable)
- Generated this summary report

## Log File
Full execution log: $LogFile

---
*Generated by Excalibur command - Claude Code Integration*
"@

    Set-Content -Path $OutputFile -Value $summary -Encoding UTF8
    Write-ExcaliburLog "Summary report generated: $OutputFile"
}

# Main execution
switch ($Action.ToLower()) {
    "sync" { Invoke-ExcaliburCommand }
    "test" { Test-Prerequisites }
    "help" {
        Write-Output @"
Excalibur Command - GitHub Organization Todo Synchronization

Usage: .\excalibur-command.ps1 [-Action] [-DryRun] [-Verbose]

Actions:
  sync    - Fetch GitHub data and update todos (default)
  test    - Test prerequisites and connectivity
  help    - Show this help message

Options:
  -DryRun    - Show what would be done without making changes
  -Verbose   - Show detailed output during execution

Magic Command: "claude pull excalibur"
This will trigger a full sync of all repositories in the organization.
"@
    }
    default {
        Write-ExcaliburLog "Unknown action: $Action. Use 'help' for usage information." "ERROR"
    }
}