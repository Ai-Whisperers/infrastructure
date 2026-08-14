# AI-Whisperers File Synchronization Script
# Synchronizes shared files across organization repositories

param(
    [string]$Action = "status",     # status, sync, validate, backup
    [string]$ConfigFile = "sync-config.json",
    [string]$Repository = "",       # target specific repository
    [string]$FilePattern = "",      # target specific file pattern
    [switch]$DryRun,               # preview changes without executing
    [switch]$Force,                # force sync even with conflicts
    [switch]$CreatePR,             # create PR instead of direct push
    [switch]$Verbose               # detailed output
)

# Configuration and Global Variables
$script:Config = $null
$script:BackupBranch = "file-sync-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$script:SyncResults = @{
    Success = @()
    Failed = @()
    Conflicts = @()
    Skipped = @()
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "DEBUG" { if ($Verbose) { "Cyan" } else { return } }
        default { "White" }
    }
    Write-Host "[$timestamp] ${Level}: $Message" -ForegroundColor $color
}

function Load-SyncConfig {
    param([string]$ConfigPath)
    
    $configFullPath = if (Test-Path $ConfigPath) {
        $ConfigPath
    } elseif (Test-Path "$PSScriptRoot\..\$ConfigPath") {
        "$PSScriptRoot\..\$ConfigPath"
    } else {
        Write-Log "Config file not found: $ConfigPath" "ERROR"
        return $null
    }
    
    try {
        $content = Get-Content $configFullPath -Raw | ConvertFrom-Json
        Write-Log "Loaded configuration from: $configFullPath" "SUCCESS"
        return $content
    }
    catch {
        Write-Log "Failed to parse config file: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Test-Prerequisites {
    # Check GitHub CLI
    try {
        $null = gh --version
        Write-Log "GitHub CLI found" "DEBUG"
    }
    catch {
        Write-Log "GitHub CLI not found. Install: winget install GitHub.cli" "ERROR"
        return $false
    }
    
    # Check authentication
    try {
        $user = gh api user --jq .login 2>$null
        if ($user) {
            Write-Log "Authenticated as GitHub user: $user" "DEBUG"
        } else {
            Write-Log "Not authenticated with GitHub. Run: gh auth login" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "GitHub authentication failed" "ERROR"
        return $false
    }
    
    # Check git
    try {
        $null = git --version
        Write-Log "Git found" "DEBUG"
    }
    catch {
        Write-Log "Git not found. Please install Git" "ERROR"
        return $false
    }
    
    return $true
}

function Get-RepositoryInfo {
    param([string]$RepoName)
    
    try {
        $repoInfo = gh api "repos/$($script:Config.organization)/$RepoName" | ConvertFrom-Json
        return @{
            Name = $repoInfo.name
            DefaultBranch = $repoInfo.default_branch
            Private = $repoInfo.private
            Exists = $true
            LastUpdate = $repoInfo.updated_at
            CloneUrl = $repoInfo.clone_url
        }
    }
    catch {
        Write-Log "Repository not found or not accessible: $RepoName" "WARN"
        return @{
            Name = $RepoName
            Exists = $false
        }
    }
}

function Get-FileContentFromSource {
    param(
        [string]$FilePath,
        [hashtable]$Transformations = @{}
    )
    
    $fullPath = if (Test-Path $FilePath) {
        $FilePath
    } elseif (Test-Path "$PSScriptRoot\..\$FilePath") {
        "$PSScriptRoot\..\$FilePath"
    } else {
        Write-Log "Source file not found: $FilePath" "ERROR"
        return $null
    }
    
    try {
        $content = Get-Content $fullPath -Raw -Encoding UTF8
        
        # Apply transformations if specified
        if ($Transformations.Count -gt 0) {
            $content = Apply-ContentTransformations $content $Transformations
        }
        
        return $content
    }
    catch {
        Write-Log "Failed to read source file: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Apply-ContentTransformations {
    param([string]$Content, [hashtable]$Transformations)
    
    foreach ($transform in $Transformations.GetEnumerator()) {
        switch ($transform.Key) {
            "repository-specific-sections" {
                # This would implement repository-specific content filtering
                Write-Log "Applying repository-specific transformations" "DEBUG"
                # Implementation would depend on specific transformation rules
            }
            "placeholder-replacement" {
                foreach ($replacement in $transform.Value.GetEnumerator()) {
                    $Content = $Content -replace $replacement.Key, $replacement.Value
                }
            }
            "line-filtering" {
                $lines = $Content -split "`n"
                $filteredLines = $lines | Where-Object { $_ -notmatch $transform.Value.excludePattern }
                $Content = $filteredLines -join "`n"
            }
        }
    }
    
    return $Content
}

function Get-RemoteFileContent {
    param([string]$RepoName, [string]$FilePath, [string]$Branch = "main")
    
    try {
        $content = gh api "repos/$($script:Config.organization)/$RepoName/contents/$FilePath" `
            --jq .content | base64 -d 2>$null
        return $content
    }
    catch {
        Write-Log "Remote file not found: $RepoName/$FilePath" "DEBUG"
        return $null
    }
}

function Compare-FileContent {
    param([string]$SourceContent, [string]$TargetContent)
    
    if ($null -eq $TargetContent) {
        return @{
            HasChanges = $true
            IsNew = $true
            ConflictType = "none"
        }
    }
    
    $sourceHash = Get-StringHash $SourceContent
    $targetHash = Get-StringHash $TargetContent
    
    return @{
        HasChanges = $sourceHash -ne $targetHash
        IsNew = $false
        ConflictType = if ($sourceHash -ne $targetHash) { "content-different" } else { "none" }
        SourceHash = $sourceHash
        TargetHash = $targetHash
    }
}

function Get-StringHash {
    param([string]$InputString)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))
    return [System.Convert]::ToBase64String($hash)
}

function Sync-FileToRepository {
    param(
        [string]$RepoName,
        [string]$SourceFile,
        [string]$TargetPath,
        [hashtable]$SyncRule,
        [hashtable]$RepoConfig
    )
    
    Write-Log "Syncing $SourceFile to $RepoName/$TargetPath" "DEBUG"
    
    # Get repository info
    $repoInfo = Get-RepositoryInfo $RepoName
    if (-not $repoInfo.Exists) {
        $script:SyncResults.Failed += @{
            Repository = $RepoName
            File = $SourceFile
            Error = "Repository not found"
        }
        return $false
    }
    
    # Get source content
    $transformations = if ($SyncRule.transformations) { $SyncRule.transformations } else { @{} }
    $sourceContent = Get-FileContentFromSource $SourceFile $transformations
    if ($null -eq $sourceContent) {
        $script:SyncResults.Failed += @{
            Repository = $RepoName
            File = $SourceFile
            Error = "Failed to read source file"
        }
        return $false
    }
    
    # Get target content for comparison
    $targetContent = Get-RemoteFileContent $RepoName $TargetPath $repoInfo.DefaultBranch
    
    # Compare content
    $comparison = Compare-FileContent $sourceContent $targetContent
    
    if (-not $comparison.HasChanges) {
        Write-Log "No changes needed for $RepoName/$TargetPath" "DEBUG"
        $script:SyncResults.Skipped += @{
            Repository = $RepoName
            File = $TargetPath
            Reason = "No changes"
        }
        return $true
    }
    
    # Handle sync mode
    $syncMode = if ($SyncRule.syncMode) { $SyncRule.syncMode } else { "replace" }
    
    switch ($syncMode) {
        "replace" {
            $finalContent = $sourceContent
        }
        "merge-append" {
            if ($targetContent) {
                $finalContent = $targetContent + "`n`n# === Synced from Company-Information ===`n" + $sourceContent
            } else {
                $finalContent = $sourceContent
            }
        }
        "merge-prepend" {
            if ($targetContent) {
                $finalContent = "# === Synced from Company-Information ===`n" + $sourceContent + "`n`n" + $targetContent
            } else {
                $finalContent = $sourceContent
            }
        }
        default {
            $finalContent = $sourceContent
        }
    }
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would sync $SourceFile to $RepoName/$TargetPath" "SUCCESS"
        return $true
    }
    
    # Perform the actual sync
    try {
        # Create or update file
        $commitMessage = "file-sync: Update $TargetPath from Company-Information`n`nAuto-generated by file synchronization system"
        
        if ($comparison.IsNew) {
            # Create new file
            $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($finalContent))
            gh api "repos/$($script:Config.organization)/$RepoName/contents/$TargetPath" `
                --method PUT `
                --field message="$commitMessage" `
                --field content="$encodedContent" `
                --field branch="$($repoInfo.DefaultBranch)" >$null
            
            Write-Log "Created $TargetPath in $RepoName" "SUCCESS"
        } else {
            # Update existing file
            $fileInfo = gh api "repos/$($script:Config.organization)/$RepoName/contents/$TargetPath" | ConvertFrom-Json
            $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($finalContent))
            
            gh api "repos/$($script:Config.organization)/$RepoName/contents/$TargetPath" `
                --method PUT `
                --field message="$commitMessage" `
                --field content="$encodedContent" `
                --field sha="$($fileInfo.sha)" `
                --field branch="$($repoInfo.DefaultBranch)" >$null
                
            Write-Log "Updated $TargetPath in $RepoName" "SUCCESS"
        }
        
        $script:SyncResults.Success += @{
            Repository = $RepoName
            File = $TargetPath
            Action = if ($comparison.IsNew) { "created" } else { "updated" }
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to sync $TargetPath to $RepoName`: $($_.Exception.Message)" "ERROR"
        $script:SyncResults.Failed += @{
            Repository = $RepoName
            File = $TargetPath
            Error = $_.Exception.Message
        }
        return $false
    }
}

function Process-SyncRules {
    param([hashtable]$FilterRepo = @{}, [string]$FilterFile = "")
    
    Write-Log "Processing sync rules..." "INFO"
    
    foreach ($ruleEntry in $script:Config.syncRules.PSObject.Properties) {
        $ruleName = $ruleEntry.Name
        $rule = $ruleEntry.Value
        
        # Skip disabled rules
        if ($rule.enabled -eq $false) {
            Write-Log "Skipping disabled rule: $ruleName" "DEBUG"
            continue
        }
        
        # Apply file filter if specified
        if ($FilterFile -and $ruleName -notlike "*$FilterFile*") {
            continue
        }
        
        Write-Log "Processing rule: $ruleName" "INFO"
        
        # Handle different source types
        if ($rule.sourceFile) {
            # Single file sync
            foreach ($target in $rule.targets) {
                # Apply repository filter
                if ($FilterRepo.Count -gt 0 -and $FilterRepo.ContainsKey($target.repository)) {
                    if (-not $FilterRepo[$target.repository]) { continue }
                }
                
                # Handle wildcard repository targets
                if ($target.repository -eq "*") {
                    foreach ($repo in $script:Config.repositories.PSObject.Properties) {
                        if ($repo.Name -eq "Company-Information") { continue }
                        Sync-FileToRepository $repo.Name $rule.sourceFile $target.targetPath $target $script:Config.repositories.$($repo.Name)
                    }
                } else {
                    Sync-FileToRepository $target.repository $rule.sourceFile $target.targetPath $target $script:Config.repositories.$($target.repository)
                }
            }
        }
        elseif ($rule.sourcePattern) {
            # Pattern-based sync (multiple files)
            $sourceFiles = Get-ChildItem -Path "$PSScriptRoot\.." -Filter $rule.sourcePattern -Recurse
            foreach ($sourceFile in $sourceFiles) {
                foreach ($target in $rule.targets) {
                    if ($FilterRepo.Count -gt 0 -and $FilterRepo.ContainsKey($target.repository)) {
                        if (-not $FilterRepo[$target.repository]) { continue }
                    }
                    
                    $relativePath = $sourceFile.FullName.Replace("$PSScriptRoot\..\", "").Replace("\", "/")
                    $targetPath = Join-Path $target.targetPath $sourceFile.Name
                    
                    if ($target.repository -eq "*") {
                        foreach ($repo in $script:Config.repositories.PSObject.Properties) {
                            if ($repo.Name -eq "Company-Information") { continue }
                            Sync-FileToRepository $repo.Name $relativePath $targetPath $target $script:Config.repositories.$($repo.Name)
                        }
                    } else {
                        Sync-FileToRepository $target.repository $relativePath $targetPath $target $script:Config.repositories.$($target.repository)
                    }
                }
            }
        }
        elseif ($rule.sourceFiles) {
            # Multiple specific files
            foreach ($sourceFile in $rule.sourceFiles) {
                foreach ($target in $rule.targets) {
                    if ($FilterRepo.Count -gt 0 -and $FilterRepo.ContainsKey($target.repository)) {
                        if (-not $FilterRepo[$target.repository]) { continue }
                    }
                    
                    $targetPath = $target.targetPath -replace "\{\{sourceFile\}\}", $sourceFile
                    
                    if ($target.repository -eq "*") {
                        foreach ($repo in $script:Config.repositories.PSObject.Properties) {
                            if ($repo.Name -eq "Company-Information") { continue }
                            Sync-FileToRepository $repo.Name $sourceFile $targetPath $target $script:Config.repositories.$($repo.Name)
                        }
                    } else {
                        Sync-FileToRepository $target.repository $sourceFile $targetPath $target $script:Config.repositories.$($target.repository)
                    }
                }
            }
        }
    }
}

function Show-SyncStatus {
    Write-Host "`n=== File Synchronization Status ===" -ForegroundColor Cyan
    Write-Host "Configuration: $ConfigFile" -ForegroundColor Gray
    Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    if (-not $script:Config) {
        Write-Host "No configuration loaded" -ForegroundColor Red
        return
    }
    
    # Show enabled sync rules
    Write-Host "`n📋 Sync Rules:" -ForegroundColor Yellow
    foreach ($ruleEntry in $script:Config.syncRules.PSObject.Properties) {
        $rule = $ruleEntry.Value
        $status = if ($rule.enabled -ne $false) { "✅" } else { "❌" }
        $description = if ($rule.description) { $rule.description } else { "No description" }
        Write-Host "   $status $($ruleEntry.Name): $description" -ForegroundColor White
    }
    
    # Show repository configuration
    Write-Host "`n🏛️ Target Repositories:" -ForegroundColor Yellow
    foreach ($repoEntry in $script:Config.repositories.PSObject.Properties) {
        $repo = $repoEntry.Value
        $protection = if ($repo.protected) { "🔒" } else { "🔓"  }
        $prRequired = if ($repo.requiresPR) { "(PR Required)" } else { "(Direct Push)" }
        Write-Host "   $protection $($repoEntry.Name) $prRequired" -ForegroundColor White
    }
    
    # Show last sync results if available
    if ($script:SyncResults.Success.Count -gt 0 -or $script:SyncResults.Failed.Count -gt 0) {
        Write-Host "`n📊 Last Sync Results:" -ForegroundColor Yellow
        Write-Host "   ✅ Success: $($script:SyncResults.Success.Count)" -ForegroundColor Green
        Write-Host "   ❌ Failed: $($script:SyncResults.Failed.Count)" -ForegroundColor Red
        Write-Host "   ⚠️ Conflicts: $($script:SyncResults.Conflicts.Count)" -ForegroundColor Yellow
        Write-Host "   ⏭️ Skipped: $($script:SyncResults.Skipped.Count)" -ForegroundColor Gray
    }
}

function Show-SyncSummary {
    Write-Host "`n=== Sync Summary ===" -ForegroundColor Cyan
    
    if ($script:SyncResults.Success.Count -gt 0) {
        Write-Host "`n✅ Successful Syncs:" -ForegroundColor Green
        foreach ($success in $script:SyncResults.Success) {
            Write-Host "   - $($success.Repository)/$($success.File) ($($success.Action))" -ForegroundColor White
        }
    }
    
    if ($script:SyncResults.Failed.Count -gt 0) {
        Write-Host "`n❌ Failed Syncs:" -ForegroundColor Red
        foreach ($failure in $script:SyncResults.Failed) {
            Write-Host "   - $($failure.Repository)/$($failure.File): $($failure.Error)" -ForegroundColor White
        }
    }
    
    if ($script:SyncResults.Conflicts.Count -gt 0) {
        Write-Host "`n⚠️ Conflicts:" -ForegroundColor Yellow
        foreach ($conflict in $script:SyncResults.Conflicts) {
            Write-Host "   - $($conflict.Repository)/$($conflict.File): $($conflict.Reason)" -ForegroundColor White
        }
    }
    
    if ($script:SyncResults.Skipped.Count -gt 0) {
        Write-Host "`n⏭️ Skipped:" -ForegroundColor Gray
        foreach ($skipped in $script:SyncResults.Skipped) {
            Write-Host "   - $($skipped.Repository)/$($skipped.File): $($skipped.Reason)" -ForegroundColor White
        }
    }
    
    $total = $script:SyncResults.Success.Count + $script:SyncResults.Failed.Count + $script:SyncResults.Conflicts.Count + $script:SyncResults.Skipped.Count
    if ($total -gt 0) {
        $successRate = [math]::Round(($script:SyncResults.Success.Count / $total) * 100)
        Write-Host "`n📈 Success Rate: $successRate% ($($script:SyncResults.Success.Count)/$total)" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 75) { "Yellow" } else { "Red" })
    }
}

function Validate-SyncConfiguration {
    Write-Host "`n=== Validating Sync Configuration ===" -ForegroundColor Cyan
    
    $issues = @()
    
    # Validate source files exist
    foreach ($ruleEntry in $script:Config.syncRules.PSObject.Properties) {
        $rule = $ruleEntry.Value
        if ($rule.enabled -eq $false) { continue }
        
        if ($rule.sourceFile) {
            $sourcePath = if (Test-Path $rule.sourceFile) { $rule.sourceFile } else { "$PSScriptRoot\..\$($rule.sourceFile)" }
            if (-not (Test-Path $sourcePath)) {
                $issues += "Missing source file for rule '$($ruleEntry.Name)': $($rule.sourceFile)"
            }
        }
    }
    
    # Validate target repositories exist
    foreach ($repoEntry in $script:Config.repositories.PSObject.Properties) {
        if ($repoEntry.Name -eq "Company-Information") { continue }
        
        $repoInfo = Get-RepositoryInfo $repoEntry.Name
        if (-not $repoInfo.Exists) {
            $issues += "Target repository not found: $($repoEntry.Name)"
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "✅ Configuration validation passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Configuration validation failed:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "   - $issue" -ForegroundColor White
        }
    }
    
    return $issues.Count -eq 0
}

# Main execution
function Main {
    Write-Host "AI-Whisperers File Synchronization System" -ForegroundColor Green
    
    # Load configuration
    $script:Config = Load-SyncConfig $ConfigFile
    if (-not $script:Config) { return }
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) { return }
    
    # Build filters
    $repoFilter = @{}
    if ($Repository) {
        $repoFilter[$Repository] = $true
    }
    
    switch ($Action.ToLower()) {
        "status" {
            Show-SyncStatus
        }
        "sync" {
            if ($DryRun) {
                Write-Log "DRY RUN MODE - No changes will be made" "WARN"
            }
            Process-SyncRules $repoFilter $FilePattern
            Show-SyncSummary
        }
        "validate" {
            $valid = Validate-SyncConfiguration
            exit $(if ($valid) { 0 } else { 1 })
        }
        "backup" {
            Write-Log "Backup functionality not implemented yet" "WARN"
        }
        default {
            Write-Host @"

Usage: file-sync.ps1 [options]

Actions:
  -Action status     Show current sync configuration and status (default)
  -Action sync       Synchronize files to target repositories
  -Action validate   Validate sync configuration
  -Action backup     Create backup of current state

Options:
  -ConfigFile path   Path to sync configuration file (default: sync-config.json)
  -Repository name   Target specific repository
  -FilePattern name  Target files matching pattern
  -DryRun           Preview changes without executing
  -Force            Force sync even with conflicts
  -CreatePR         Create pull request instead of direct push
  -Verbose          Detailed output

Examples:
  .\file-sync.ps1                                    # Show status
  .\file-sync.ps1 -Action sync                       # Sync all files
  .\file-sync.ps1 -Action sync -DryRun              # Preview sync
  .\file-sync.ps1 -Action sync -Repository web-platform
  .\file-sync.ps1 -Action validate                  # Validate config

"@ -ForegroundColor Gray
        }
    }
}

# Run the script
if ($MyInvocation.InvocationName -ne '.') {
    Main
}