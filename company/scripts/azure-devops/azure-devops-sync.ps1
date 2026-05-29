# AI-Whisperers Azure DevOps Integration
param(
    [Parameter(Position=0)]
    [ValidateSet("status", "configure", "test", "sync")]
    [string]$Action = "status",
    
    [string]$Organization = "your-devops-org",
    [string]$Project = "AI-Whisperers",
    [switch]$DryRun
)

# Configuration
$Config = @{
    DevOpsOrg = $Organization
    DevOpsProject = $Project
    GitHubOrg = "Ai-Whisperers"
    OutputPath = ".\azure-sync-logs"
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
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    }
    Write-Host ""
}

function Test-AzureCLI {
    try {
        # Test if Azure CLI is accessible
        $null = Get-Command az -ErrorAction Stop
        
        # Get version information
        $azVersion = az --version 2>$null
        if ($azVersion) {
            Write-Host "[OK] Azure CLI is installed" -ForegroundColor Green
            
            try {
                # Test authentication with proper error handling
                $accountJson = az account show 2>$null
                if ($LASTEXITCODE -eq 0 -and $accountJson) {
                    $account = $accountJson | ConvertFrom-Json -ErrorAction Stop
                    Write-Host "[OK] Azure CLI is authenticated as: $($account.user.name)" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "[WARNING] Azure CLI is not authenticated" -ForegroundColor Yellow
                    Write-Host "Run 'az login' to authenticate" -ForegroundColor Gray
                    return $false
                }
            }
            catch {
                Write-Host "[WARNING] Failed to verify Azure CLI authentication: $($_.Exception.Message)" -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "[ERROR] Azure CLI version check failed" -ForegroundColor Red
            return $false
        }
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-Host "[ERROR] Azure CLI is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Gray
        return $false
    }
    catch {
        Write-Host "[ERROR] Unexpected error testing Azure CLI: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Gray
        return $false
    }
}

function Test-DevOpsExtension {
    try {
        $extensionsJson = az extension list --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to list Azure CLI extensions" -ForegroundColor Red
            return $false
        }
        
        $extensions = $extensionsJson | ConvertFrom-Json -ErrorAction Stop
        $devopsExt = $extensions | Where-Object { $_.name -eq "azure-devops" }
        
        if ($devopsExt) {
            Write-Host "[OK] Azure DevOps extension is installed (version: $($devopsExt.version))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] Azure DevOps extension is not installed" -ForegroundColor Yellow
            Write-Host "Install with: az extension add --name azure-devops" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Failed to check Azure DevOps extension: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-DevOpsAccess {
    param(
        [string]$OrgName,
        [string]$ProjectName
    )
    
    try {
        # Test organization access
        Write-Host "Testing access to Azure DevOps organization: $OrgName" -ForegroundColor Gray
        
        $orgUrl = "https://dev.azure.com/$OrgName"
        $projects = az devops project list --organization $orgUrl --output json 2>$null
        
        if ($projects) {
            $projectList = $projects | ConvertFrom-Json
            Write-Host "[OK] Successfully connected to organization: $OrgName" -ForegroundColor Green
            Write-Host "Available projects: $($projectList.value.Count)" -ForegroundColor Gray
            
            # Test specific project access
            $targetProject = $projectList.value | Where-Object { $_.name -eq $ProjectName }
            if ($targetProject) {
                Write-Host "[OK] Project '$ProjectName' found and accessible" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[WARNING] Project '$ProjectName' not found" -ForegroundColor Yellow
                Write-Host "Available projects:" -ForegroundColor Gray
                foreach ($project in $projectList.value) {
                    Write-Host "  - $($project.name)" -ForegroundColor Gray
                }
                return $false
            }
        } else {
            Write-Host "[ERROR] Failed to access Azure DevOps organization: $OrgName" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Failed to test DevOps access: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-GitHubRepositories {
    try {
        # Test if GitHub CLI is available
        $null = Get-Command gh -ErrorAction Stop
        
        $reposJson = gh repo list $Config.GitHubOrg --json name,url --limit 100 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to fetch GitHub repositories. Check GitHub CLI authentication." -ForegroundColor Red
            Write-Host "Run 'gh auth login' to authenticate" -ForegroundColor Gray
            return @()
        }
        
        $repos = $reposJson | ConvertFrom-Json -ErrorAction Stop
        if ($repos -and $repos.Count -gt 0) {
            Write-Host "[OK] Found $($repos.Count) GitHub repositories" -ForegroundColor Green
            return $repos
        } else {
            Write-Host "[WARNING] No GitHub repositories found for organization: $($Config.GitHubOrg)" -ForegroundColor Yellow
            return @()
        }
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-Host "[ERROR] GitHub CLI (gh) is not installed" -ForegroundColor Red
        Write-Host "Install from: https://cli.github.com/" -ForegroundColor Gray
        return @()
    }
    catch {
        Write-Host "[ERROR] Failed to fetch GitHub repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Show-IntegrationStatus {
    Write-Header "Azure DevOps Integration Status"
    
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Azure DevOps Org: $($Config.DevOpsOrg)" -ForegroundColor Gray
    Write-Host "  Azure DevOps Project: $($Config.DevOpsProject)" -ForegroundColor Gray
    Write-Host "  GitHub Organization: $($Config.GitHubOrg)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Prerequisites Check:" -ForegroundColor Cyan
    
    $azCliOk = Test-AzureCLI
    $devopsExtOk = Test-DevOpsExtension
    
    if ($azCliOk -and $devopsExtOk) {
        $devopsAccess = Test-DevOpsAccess -OrgName $Config.DevOpsOrg -ProjectName $Config.DevOpsProject
        
        if ($devopsAccess) {
            Write-Host ""
            Write-Host "[OK] All prerequisites met!" -ForegroundColor Green
            Write-Host "Azure DevOps integration is ready for implementation." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[WARNING] DevOps access issues detected" -ForegroundColor Yellow
            Write-Host "Please verify organization and project names." -ForegroundColor Gray
        }
    } else {
        Write-Host ""
        Write-Host "[ERROR] Prerequisites not met" -ForegroundColor Red
        Write-Host "Please install and configure required tools." -ForegroundColor Gray
    }
    
    # GitHub status
    Write-Host ""
    Write-Host "GitHub Integration:" -ForegroundColor Cyan
    $repos = Get-GitHubRepositories
    
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Ensure Azure CLI and DevOps extension are properly configured" -ForegroundColor Gray
    Write-Host "2. Configure work item area paths for each repository" -ForegroundColor Gray
    Write-Host "3. Set up automated sync workflows" -ForegroundColor Gray
    Write-Host "4. Test bi-directional synchronization" -ForegroundColor Gray
}

function Show-SyncConfiguration {
    Write-Header "Azure DevOps Sync Configuration"
    
    Write-Host "Sync Configuration Template:" -ForegroundColor Cyan
    Write-Host ""
    
    $configTemplate = @"
# Azure DevOps Sync Configuration
# Customize this configuration for your organization

Azure DevOps Settings:
  Organization: $($Config.DevOpsOrg)
  Project: $($Config.DevOpsProject)
  Area Path: AI-Whisperers
  Iteration Path: Current

GitHub Settings:
  Organization: $($Config.GitHubOrg)
  Repositories: All (or specify list)

Sync Rules:
  GitHub Issues -> Azure Work Items (User Story)
  GitHub Pull Requests -> Azure Work Items (Task)
  Azure Work Items -> GitHub Issues (bidirectional)

Work Item Mapping:
  - Repository: Area Path
  - Priority: GitHub label -> DevOps Priority
  - Status: GitHub state -> DevOps State
  - Assignee: GitHub assignee -> DevOps assigned to
"@
    
    Write-Host $configTemplate -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Implementation Status:" -ForegroundColor Cyan
    Write-Host "  Configuration: Template created" -ForegroundColor Yellow
    Write-Host "  Authentication: Requires setup" -ForegroundColor Yellow  
    Write-Host "  Sync Logic: Needs implementation" -ForegroundColor Yellow
    Write-Host "  Testing: Pending" -ForegroundColor Yellow
}

function Test-Integration {
    Write-Header "Testing Azure DevOps Integration"
    
    Write-Host "Running integration tests..." -ForegroundColor Yellow
    
    # Test 1: Azure CLI functionality
    Write-Host ""
    Write-Host "Test 1: Azure CLI Connection" -ForegroundColor Cyan
    $azTest = Test-AzureCLI
    
    # Test 2: DevOps extension
    Write-Host ""
    Write-Host "Test 2: DevOps Extension" -ForegroundColor Cyan
    $extTest = Test-DevOpsExtension
    
    # Test 3: Organization access
    Write-Host ""
    Write-Host "Test 3: Organization Access" -ForegroundColor Cyan
    if ($azTest -and $extTest) {
        $accessTest = Test-DevOpsAccess -OrgName $Config.DevOpsOrg -ProjectName $Config.DevOpsProject
    } else {
        Write-Host "[SKIP] Skipping due to failed prerequisites" -ForegroundColor Yellow
        $accessTest = $false
    }
    
    # Test 4: GitHub connectivity
    Write-Host ""
    Write-Host "Test 4: GitHub Connectivity" -ForegroundColor Cyan
    $repos = Get-GitHubRepositories
    $githubTest = $repos.Count -gt 0
    
    # Summary
    Write-Host ""
    Write-Host "Test Summary:" -ForegroundColor Cyan
    Write-Host "  Azure CLI: $(if ($azTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($azTest) { 'Green' } else { 'Red' })
    Write-Host "  DevOps Extension: $(if ($extTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($extTest) { 'Green' } else { 'Red' })
    Write-Host "  Organization Access: $(if ($accessTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($accessTest) { 'Green' } else { 'Red' })
    Write-Host "  GitHub Connectivity: $(if ($githubTest) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($githubTest) { 'Green' } else { 'Red' })
    
    $overallStatus = $azTest -and $extTest -and $accessTest -and $githubTest
    Write-Host ""
    Write-Host "Overall Status: $(if ($overallStatus) { 'READY' } else { 'NOT READY' })" -ForegroundColor $(if ($overallStatus) { 'Green' } else { 'Red' })
    
    if (-not $overallStatus) {
        Write-Host ""
        Write-Host "Required Actions:" -ForegroundColor Yellow
        if (-not $azTest) { Write-Host "  - Install and authenticate Azure CLI" -ForegroundColor Gray }
        if (-not $extTest) { Write-Host "  - Install Azure DevOps extension" -ForegroundColor Gray }
        if (-not $accessTest) { Write-Host "  - Verify DevOps organization and project access" -ForegroundColor Gray }
        if (-not $githubTest) { Write-Host "  - Verify GitHub CLI authentication" -ForegroundColor Gray }
    }
}

function Start-Sync {
    Write-Header "Azure DevOps Synchronization"
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would perform the following sync operations:" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "1. Fetch GitHub issues from all repositories" -ForegroundColor Gray
        Write-Host "2. Query existing Azure DevOps work items" -ForegroundColor Gray
        Write-Host "3. Create new work items for GitHub issues" -ForegroundColor Gray
        Write-Host "4. Update existing work items with GitHub changes" -ForegroundColor Gray
        Write-Host "5. Sync status changes back to GitHub" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Note: Actual sync implementation requires additional development" -ForegroundColor Yellow
    } else {
        Write-Host "Sync implementation is not yet complete." -ForegroundColor Yellow
        Write-Host "Use --DryRun to see what would be synchronized." -ForegroundColor Gray
    }
}

# Main execution
switch ($Action.ToLower()) {
    "status" {
        Show-IntegrationStatus
    }
    "configure" {
        Show-SyncConfiguration
    }
    "test" {
        Test-Integration
    }
    "sync" {
        Start-Sync
    }
    default {
        Write-Error "Invalid action: $Action. Use: status, configure, test, or sync"
    }
}