# AI-Whisperers Advanced File Synchronization System
param(
    [Parameter(Position=0)]
    [ValidateSet("sync", "status", "validate", "test")]
    [string]$Action = "status",

    [string]$Repository = "all",
    [string]$SourceFile = "",
    [switch]$DryRun,
    [switch]$VerboseLogging
)

# Load path resolver utility
. "$PSScriptRoot\common\PathResolver.ps1"

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    SourcePath = Get-ProjectPath "documentation-templates"
    LogPath = ".\sync-logs"
    SyncableFiles = @(
        @{ Name = "README_TEMPLATE.md"; Target = "docs/templates/README_TEMPLATE.md" }
        @{ Name = "CONTRIBUTING_TEMPLATE.md"; Target = "docs/templates/CONTRIBUTING_TEMPLATE.md" }
        @{ Name = "ARCHITECTURE_TEMPLATE.md"; Target = "docs/templates/ARCHITECTURE_TEMPLATE.md" }
        @{ Name = "API_TEMPLATE.md"; Target = "docs/templates/API_TEMPLATE.md" }
        @{ Name = "DOCUMENTATION_STANDARDS.md"; Target = "docs/DOCUMENTATION_STANDARDS.md" }
    )
    ExcludeRepos = @("Company-Information")
}

# Initialize logging
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$logFile = Join-Path $Config.LogPath "file-sync-$timestamp.log"

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
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    }
    Write-Host ""
}

function Get-AllRepositories {
    Write-Log "Fetching repositories from organization: $($Config.Organization)" "DEBUG"
    
    try {
        # Check GitHub CLI authentication first
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "GitHub CLI authentication failed" "ERROR"
            throw "GitHub CLI not authenticated. Run 'gh auth login' first."
        }
        
        Write-Log "GitHub CLI authentication verified" "DEBUG"
        
        # Fetch repositories
        $repos = gh repo list $Config.Organization --json name,url --limit 100 | ConvertFrom-Json
        
        if (-not $repos) {
            Write-Log "No repositories found in organization $($Config.Organization)" "WARN"
            return @()
        }
        
        # Filter out excluded repositories
        $filteredRepos = $repos | Where-Object { $_.name -notin $Config.ExcludeRepos }
        Write-Log "Successfully fetched $($filteredRepos.Count) repositories (filtered)" "INFO"
        return $filteredRepos
    }
    catch {
        $errorMsg = "Failed to fetch repositories: $($_.Exception.Message)"
        Write-Log $errorMsg "ERROR"
        Write-Host $errorMsg -ForegroundColor Red
        return @()
    }
}

function Test-SourceFiles {
    Write-Host "Validating source template files..." -ForegroundColor Yellow
    Write-Log "Validating source template files" "INFO"
    
    $allValid = $true
    
    foreach ($fileInfo in $Config.SyncableFiles) {
        $sourcePath = Join-Path $Config.SourcePath $fileInfo.Name
        
        if (Test-Path $sourcePath) {
            $size = (Get-Item $sourcePath).Length
            Write-Host "[OK] $($fileInfo.Name) ($size bytes)" -ForegroundColor Green
            Write-Log "Source file valid: $($fileInfo.Name) ($size bytes)" "DEBUG"
        } else {
            Write-Host "[MISSING] $($fileInfo.Name) - File not found" -ForegroundColor Red
            Write-Log "Source file missing: $($fileInfo.Name)" "ERROR"
            $allValid = $false
        }
    }
    
    return $allValid
}

function Sync-FileToRepository {
    param(
        [string]$RepoName,
        [object]$FileInfo,
        [string]$SourceContent
    )
    
    Write-Log "Syncing $($FileInfo.Name) to $RepoName" "INFO"
    
    try {
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would sync $($FileInfo.Name) to $RepoName/$($FileInfo.Target)" -ForegroundColor Cyan
            return $true
        }
        
        # Check if repository exists
        $repoExists = gh repo view "$($Config.Organization)/$RepoName" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Repository $RepoName not found or not accessible" "ERROR"
            return $false
        }
        
        # Get repository default branch
        $repoInfo = gh api "repos/$($Config.Organization)/$RepoName" | ConvertFrom-Json
        $defaultBranch = $repoInfo.default_branch
        Write-Log "Repository $RepoName default branch: $defaultBranch" "DEBUG"
        
        # Check if target file exists
        $targetExists = $false
        $currentSha = ""
        
        try {
            $fileInfo = gh api "repos/$($Config.Organization)/$RepoName/contents/$($FileInfo.Target)" 2>$null | ConvertFrom-Json
            $targetExists = $true
            $currentSha = $fileInfo.sha
            $currentContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($fileInfo.content))
            
            # Compare content to avoid unnecessary updates
            if ($SourceContent -eq $currentContent) {
                Write-Host "  [NO CHANGE] $($FileInfo.Name) already up to date in $RepoName" -ForegroundColor Green
                Write-Log "File $($FileInfo.Name) already up to date in $RepoName" "INFO"
                return $true
            }
        }
        catch {
            Write-Log "Target file $($FileInfo.Target) does not exist in $RepoName" "DEBUG"
        }
        
        # Encode content for GitHub API
        $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($SourceContent))
        
        # Create commit message
        $commitMessage = if ($targetExists) {
            "docs: Update $($FileInfo.Target) from Company-Information

Auto-synced from documentation templates.
Source: $($FileInfo.Name)

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
        } else {
            "docs: Add $($FileInfo.Target) from Company-Information

Auto-synced from documentation templates.
Source: $($FileInfo.Name)

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
        }
        
        # Create API request body
        $body = @{
            message = $commitMessage
            content = $encodedContent
            branch = $defaultBranch
        }
        
        if ($targetExists) {
            $body.sha = $currentSha
        }
        
        $bodyJson = $body | ConvertTo-Json -Depth 3
        
        # Make the API call
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            $bodyJson | Out-File -FilePath $tempFile -Encoding UTF8
            
            if ($targetExists) {
                gh api "repos/$($Config.Organization)/$RepoName/contents/$($FileInfo.Target)" --method PUT --input $tempFile | Out-Null
                Write-Host "  [UPDATED] $($FileInfo.Name) in $RepoName" -ForegroundColor Yellow
                Write-Log "Updated $($FileInfo.Name) in $RepoName" "INFO"
            } else {
                gh api "repos/$($Config.Organization)/$RepoName/contents/$($FileInfo.Target)" --method PUT --input $tempFile | Out-Null
                Write-Host "  [CREATED] $($FileInfo.Name) in $RepoName" -ForegroundColor Green
                Write-Log "Created $($FileInfo.Name) in $RepoName" "INFO"
            }
        }
        finally {
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
        }
        
        return $true
    }
    catch {
        $errorMsg = "Failed to sync $($FileInfo.Name) to $RepoName : $($_.Exception.Message)"
        Write-Log $errorMsg "ERROR"
        Write-Host "  [ERROR] $errorMsg" -ForegroundColor Red
        return $false
    }
}

function Start-FileSync {
    Write-Header "AI-Whisperers File Synchronization"
    
    # Validate source files first
    if (-not (Test-SourceFiles)) {
        Write-Host "Source file validation failed. Cannot proceed with sync." -ForegroundColor Red
        Write-Log "Source file validation failed" "ERROR"
        return
    }
    
    # Get target repositories
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { 
        Write-Log "No repositories available for sync" "ERROR"
        return 
    }
    
    # Filter repositories if specific repository requested
    $filteredRepos = if ($Repository -ne "all") {
        $repos | Where-Object { $_.name -eq $Repository }
    } else {
        $repos
    }
    
    if ($filteredRepos.Count -eq 0) {
        Write-Host "No matching repositories found for: $Repository" -ForegroundColor Yellow
        return
    }
    
    # Filter files if specific file requested
    $filesToSync = if ($SourceFile) {
        $Config.SyncableFiles | Where-Object { $_.Name -eq $SourceFile }
    } else {
        $Config.SyncableFiles
    }
    
    if ($filesToSync.Count -eq 0) {
        Write-Host "No matching files found for: $SourceFile" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Sync Plan:" -ForegroundColor Cyan
    Write-Host "  Repositories: $($filteredRepos.Count)" -ForegroundColor Gray
    Write-Host "  Files: $($filesToSync.Count)" -ForegroundColor Gray
    Write-Host "  Total operations: $($filteredRepos.Count * $filesToSync.Count)" -ForegroundColor Gray
    Write-Host ""
    
    $successCount = 0
    $totalOperations = $filteredRepos.Count * $filesToSync.Count
    
    # Perform sync operations
    foreach ($repo in $filteredRepos) {
        Write-Host "Syncing to repository: $($repo.name)" -ForegroundColor Yellow
        
        foreach ($fileInfo in $filesToSync) {
            # Read source file content
            $sourcePath = Join-Path $Config.SourcePath $fileInfo.Name
            $sourceContent = Get-Content $sourcePath -Raw -Encoding UTF8
            
            # Sync file
            if (Sync-FileToRepository -RepoName $repo.name -FileInfo $fileInfo -SourceContent $sourceContent) {
                $successCount++
            }
        }
        Write-Host ""
    }
    
    # Summary
    Write-Host "Sync Summary:" -ForegroundColor Cyan
    Write-Host "  Successful operations: $successCount/$totalOperations" -ForegroundColor Gray
    Write-Host "  Success rate: $([math]::Round(($successCount / $totalOperations) * 100, 1))%" -ForegroundColor Gray
    
    if ($successCount -eq $totalOperations) {
        Write-Host "  Status: All operations completed successfully!" -ForegroundColor Green
        Write-Log "File sync completed successfully: $successCount/$totalOperations operations" "INFO"
    } else {
        Write-Host "  Status: Some operations failed. Check logs for details." -ForegroundColor Yellow
        Write-Log "File sync completed with errors: $successCount/$totalOperations operations" "WARN"
    }
}

function Show-SyncStatus {
    Write-Header "File Synchronization Status"
    
    if (-not (Test-SourceFiles)) {
        Write-Host "Source file validation failed." -ForegroundColor Red
        return
    }
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    Write-Host "Synchronization Configuration:" -ForegroundColor Cyan
    Write-Host "  Source Path: $($Config.SourcePath)" -ForegroundColor Gray
    Write-Host "  Target Repositories: $($repos.Count)" -ForegroundColor Gray
    Write-Host "  Syncable Files: $($Config.SyncableFiles.Count)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Files ready for sync:" -ForegroundColor Cyan
    foreach ($fileInfo in $Config.SyncableFiles) {
        Write-Host "  - $($fileInfo.Name) → $($fileInfo.Target)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Target repositories:" -ForegroundColor Cyan
    foreach ($repo in $repos) {
        Write-Host "  - $($repo.name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  Run with 'sync' action to perform synchronization" -ForegroundColor Gray
    Write-Host "  Use -DryRun to preview changes without making them" -ForegroundColor Gray
}

function Test-SyncSystem {
    Write-Header "File Synchronization System Test"
    
    $testsPassed = 0
    $totalTests = 4
    
    # Test 1: Source file validation
    Write-Host "Test 1: Source File Validation" -ForegroundColor Cyan
    if (Test-SourceFiles) {
        Write-Host "  ✅ PASS - All source files are valid" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ❌ FAIL - Source file validation failed" -ForegroundColor Red
    }
    
    # Test 2: GitHub CLI authentication
    Write-Host ""
    Write-Host "Test 2: GitHub CLI Authentication" -ForegroundColor Cyan
    try {
        gh auth status 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ PASS - GitHub CLI is authenticated" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "  ❌ FAIL - GitHub CLI authentication failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ FAIL - GitHub CLI not available" -ForegroundColor Red
    }
    
    # Test 3: Repository access
    Write-Host ""
    Write-Host "Test 3: Repository Access" -ForegroundColor Cyan
    $repos = Get-AllRepositories
    if ($repos.Count -gt 0) {
        Write-Host "  ✅ PASS - Can access $($repos.Count) repositories" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ❌ FAIL - Cannot access repositories" -ForegroundColor Red
    }
    
    # Test 4: Log directory creation
    Write-Host ""
    Write-Host "Test 4: Log Directory Creation" -ForegroundColor Cyan
    try {
        if (-not (Test-Path $Config.LogPath)) {
            New-Item -ItemType Directory -Path $Config.LogPath -Force | Out-Null
        }
        Write-Host "  ✅ PASS - Log directory is accessible" -ForegroundColor Green
        $testsPassed++
    } catch {
        Write-Host "  ❌ FAIL - Cannot create log directory" -ForegroundColor Red
    }
    
    # Summary
    Write-Host ""
    Write-Host "Test Summary:" -ForegroundColor Cyan
    Write-Host "  Tests passed: $testsPassed/$totalTests" -ForegroundColor Gray
    Write-Host "  Success rate: $([math]::Round(($testsPassed / $totalTests) * 100, 1))%" -ForegroundColor Gray
    
    if ($testsPassed -eq $totalTests) {
        Write-Host "  Overall Status: ✅ All tests passed - System ready!" -ForegroundColor Green
    } else {
        Write-Host "  Overall Status: ⚠️ Some tests failed - Check configuration" -ForegroundColor Yellow
    }
}

# Initialize
Write-Log "Starting file sync system - Action: $Action" "INFO"

# Main execution
switch ($Action.ToLower()) {
    "sync" {
        Start-FileSync
    }
    "status" {
        Show-SyncStatus
    }
    "validate" {
        Write-Header "Source File Validation"
        if (Test-SourceFiles) {
            Write-Host "All source files are valid and ready for synchronization" -ForegroundColor Green
        } else {
            Write-Host "Source file validation failed" -ForegroundColor Red
        }
    }
    "test" {
        Test-SyncSystem
    }
    default {
        Write-Error "Invalid action: $Action. Use: sync, status, validate, or test"
    }
}

Write-Log "File sync system completed - Action: $Action" "INFO"