# AI-Whisperers Repository Dependency Tracker
param(
    [Parameter(Position=0)]
    [ValidateSet("analyze", "graph", "validate", "report")]
    [string]$Action = "analyze",
    
    [string]$Repository = "all",
    [switch]$Detailed
)

# Configuration
$Config = @{
    Organization = "Ai-Whisperers"
    OutputPath = ".\dependency-reports"
    # Define known dependency patterns
    DependencyPatterns = @{
        "package.json" = @{
            Pattern = '"([^"]+)":\s*"([^"]+)"'
            Type = "npm"
        }
        "requirements.txt" = @{
            Pattern = "^([a-zA-Z0-9\-_]+)([>=<~!].*)?$"
            Type = "pip"
        }
        "Cargo.toml" = @{
            Pattern = '([a-zA-Z0-9\-_]+)\s*=\s*"([^"]+)"'
            Type = "cargo"
        }
        "go.mod" = @{
            Pattern = "^\s*([^\s]+)\s+v?([^\s]+).*$"
            Type = "go"
        }
    }
    # Define internal service dependencies
    InternalServices = @{
        "Comment-Analyzer" = @{
            Provides = @("AI Analysis", "Streamlit UI")
            ConsumesFrom = @("OpenAI API")
            Port = 8501
        }
        "AI-Investment" = @{
            Provides = @("Investment API", "Trading Signals", "Web UI")
            ConsumesFrom = @("TwelveData API", "MarketAux API")
            Port = 8000
        }
        "clockify-ADO-automated-report" = @{
            Provides = @("Time Tracking Automation", "Report Generation")
            ConsumesFrom = @("Clockify API", "Azure DevOps API")
            Port = 0
        }
        "AI-Whisperers-website-and-courses" = @{
            Provides = @("Educational Platform", "Course Management")
            ConsumesFrom = @("TBD")
            Port = 3000
        }
        "WPG-Amenities" = @{
            Provides = @("Local Services Discovery", "Winnipeg Data")
            ConsumesFrom = @()
            Port = 8080
        }
        "AI-Whisperers" = @{
            Provides = @("Organizational Standards", "Templates")
            ConsumesFrom = @()
            Port = 0
        }
    }
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
        $repos = gh repo list $Config.Organization --json name,url,description --limit 100 | ConvertFrom-Json
        if (-not $repos) {
            Write-Host "No repositories found. Check authentication." -ForegroundColor Red
            return @()
        }
        return $repos
    }
    catch {
        Write-Host "Failed to fetch repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-RepositoryFiles {
    param(
        [string]$RepoName,
        [string[]]$FilePatterns
    )
    
    $files = @()
    foreach ($pattern in $FilePatterns) {
        try {
            $result = gh api "repos/$($Config.Organization)/$RepoName/contents" --jq ".[] | select(.name | test(\"$pattern\")) | .name" 2>$null
            if ($result) {
                $files += $result
            }
        }
        catch {
            # File not found or access denied - continue
        }
    }
    return $files
}

function Get-FileContent {
    param(
        [string]$RepoName,
        [string]$FileName
    )
    
    try {
        $content = gh api "repos/$($Config.Organization)/$RepoName/contents/$FileName" --jq '.content' 2>$null
        if ($content) {
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content))
            return $decoded
        }
    }
    catch {
        Write-Host "Failed to get content for $FileName in $RepoName" -ForegroundColor Yellow
    }
    return $null
}

function Parse-Dependencies {
    param(
        [string]$RepoName,
        [string]$FileName,
        [string]$Content
    )
    
    $dependencies = @()
    $fileType = $Config.DependencyPatterns.Keys | Where-Object { $FileName -match $_ } | Select-Object -First 1
    
    if ($fileType) {
        $pattern = $Config.DependencyPatterns[$fileType]
        $matches = [regex]::Matches($Content, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        foreach ($match in $matches) {
            if ($match.Groups.Count -ge 2) {
                $dependencies += @{
                    Repository = $RepoName
                    File = $FileName
                    Type = $pattern.Type
                    Package = $match.Groups[1].Value
                    Version = if ($match.Groups.Count -ge 3) { $match.Groups[2].Value } else { "latest" }
                }
            }
        }
    }
    
    return $dependencies
}

function Analyze-RepositoryDependencies {
    Write-Header "Repository Dependency Analysis"
    
    $repos = Get-AllRepositories
    if ($repos.Count -eq 0) { return }
    
    $filteredRepos = if ($Repository -ne "all") {
        $repos | Where-Object { $_.name -eq $Repository }
    } else {
        $repos
    }
    
    $allDependencies = @()
    $dependencyFiles = @("package\.json", "requirements\.txt", "Cargo\.toml", "go\.mod", ".*\.csproj")
    
    Write-Host "Scanning repositories for dependency files..." -ForegroundColor Yellow
    
    foreach ($repo in $filteredRepos) {
        Write-Host "Analyzing $($repo.name)..." -ForegroundColor Gray
        
        $files = Get-RepositoryFiles -RepoName $repo.name -FilePatterns $dependencyFiles
        
        foreach ($file in $files) {
            $content = Get-FileContent -RepoName $repo.name -FileName $file
            if ($content) {
                $deps = Parse-Dependencies -RepoName $repo.name -FileName $file -Content $content
                $allDependencies += $deps
            }
        }
    }
    
    # Group dependencies by type and package
    Write-Host ""
    Write-Host "Dependency Summary:" -ForegroundColor Cyan
    
    $groupedByType = $allDependencies | Group-Object Type
    foreach ($typeGroup in $groupedByType) {
        Write-Host "  $($typeGroup.Name) Dependencies:" -ForegroundColor Yellow
        
        $packageGroups = $typeGroup.Group | Group-Object Package | Sort-Object Count -Descending
        foreach ($packageGroup in $packageGroups | Select-Object -First 10) {
            $versions = $packageGroup.Group | Select-Object -ExpandProperty Version -Unique
            $repos = $packageGroup.Group | Select-Object -ExpandProperty Repository -Unique
            Write-Host "    $($packageGroup.Name): $($versions -join ', ') (used in $($repos.Count) repos)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Check for version conflicts
    Write-Host "Version Conflict Analysis:" -ForegroundColor Cyan
    $conflicts = $allDependencies | Group-Object Package | Where-Object { 
        $_.Group | Select-Object -ExpandProperty Version -Unique | Measure-Object | Select-Object -ExpandProperty Count
    } -gt 1
    
    if ($conflicts.Count -gt 0) {
        foreach ($conflict in $conflicts) {
            Write-Host "  [WARNING] $($conflict.Name) has multiple versions:" -ForegroundColor Yellow
            $conflict.Group | ForEach-Object {
                Write-Host "    $($_.Repository): $($_.Version)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  [OK] No version conflicts detected" -ForegroundColor Green
    }
    
    return $allDependencies
}

function Show-DependencyGraph {
    Write-Header "Repository Dependency Graph"
    
    Write-Host "Internal Service Dependencies:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($service in $Config.InternalServices.Keys) {
        $serviceInfo = $Config.InternalServices[$service]
        Write-Host "$service" -ForegroundColor Yellow
        Write-Host "  Provides: $($serviceInfo.Provides -join ', ')" -ForegroundColor Gray
        
        if ($serviceInfo.ConsumesFrom.Count -gt 0) {
            Write-Host "  Depends on: $($serviceInfo.ConsumesFrom -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "  Depends on: None (leaf service)" -ForegroundColor Green
        }
        
        if ($serviceInfo.Port -gt 0) {
            Write-Host "  Port: $($serviceInfo.Port)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # ASCII dependency graph
    Write-Host "Dependency Flow:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  OpenAI API -----> Comment-Analyzer" -ForegroundColor Green
    Write-Host ""
    Write-Host "  TwelveData API ---->" -ForegroundColor Cyan
    Write-Host "  MarketAux API  ----> AI-Investment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Clockify API   ---->" -ForegroundColor Magenta
    Write-Host "  Azure DevOps API -> clockify-ADO-automated-report" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  AI-Whisperers-website-and-courses (planning)" -ForegroundColor Blue
    Write-Host "  WPG-Amenities (assessment)" -ForegroundColor DarkYellow
    Write-Host "  AI-Whisperers (standards - independent)" -ForegroundColor DarkGreen
}

function Validate-Dependencies {
    Write-Header "Dependency Validation"
    
    $issues = @()
    
    # Check for common security vulnerabilities in known packages
    $vulnerablePackages = @(
        @{ Name = "lodash"; Versions = @("< 4.17.19"); Severity = "High" }
        @{ Name = "axios"; Versions = @("< 0.21.1"); Severity = "Medium" }
        @{ Name = "flask"; Versions = @("< 1.1.4"); Severity = "High" }
    )
    
    Write-Host "Checking for known vulnerable packages..." -ForegroundColor Yellow
    
    $dependencies = Analyze-RepositoryDependencies
    
    foreach ($vuln in $vulnerablePackages) {
        $affected = $dependencies | Where-Object { 
            $_.Package -eq $vuln.Name -and $_.Version -match $vuln.Versions[0] 
        }
        
        if ($affected) {
            $issues += "[$($vuln.Severity)] $($vuln.Name) vulnerability detected in: $($affected.Repository -join ', ')"
        }
    }
    
    # Check for outdated major versions
    Write-Host "Checking for potentially outdated packages..." -ForegroundColor Yellow
    
    $oldVersions = $dependencies | Where-Object { 
        $_.Version -match "^[0-2]\." -and $_.Type -eq "npm"
    }
    
    foreach ($old in $oldVersions) {
        $issues += "[INFO] Potentially outdated package: $($old.Package) v$($old.Version) in $($old.Repository)"
    }
    
    # Report issues
    if ($issues.Count -gt 0) {
        Write-Host ""
        Write-Host "Issues Found:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "  $issue" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [OK] No major dependency issues detected" -ForegroundColor Green
    }
}

function Generate-DependencyReport {
    Write-Header "Generating Dependency Report"
    
    $dependencies = Analyze-RepositoryDependencies
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    
    # Generate CSV report
    $csvPath = Join-Path $Config.OutputPath "dependency-report-$timestamp.csv"
    $dependencies | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "CSV report generated: $csvPath" -ForegroundColor Green
    
    # Generate summary report
    $summaryPath = Join-Path $Config.OutputPath "dependency-summary-$timestamp.txt"
    
    $summary = @"
AI-Whisperers Dependency Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

SUMMARY:
- Total dependencies analyzed: $($dependencies.Count)
- Repositories scanned: $(($dependencies | Select-Object Repository -Unique).Count)
- Dependency types: $(($dependencies | Select-Object Type -Unique) -join ', ')

TOP DEPENDENCIES:
$($dependencies | Group-Object Package | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { "- $($_.Name): used in $($_.Count) places" } | Out-String)

REPOSITORIES BY DEPENDENCY COUNT:
$($dependencies | Group-Object Repository | Sort-Object Count -Descending | ForEach-Object { "- $($_.Name): $($_.Count) dependencies" } | Out-String)
"@
    
    $summary | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Host "Summary report generated: $summaryPath" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Report Summary:" -ForegroundColor Cyan
    Write-Host "  Dependencies analyzed: $($dependencies.Count)" -ForegroundColor Gray
    Write-Host "  Repositories: $(($dependencies | Select-Object Repository -Unique).Count)" -ForegroundColor Gray
    Write-Host "  Types: $(($dependencies | Select-Object Type -Unique) -join ', ')" -ForegroundColor Gray
}

# Main execution
switch ($Action.ToLower()) {
    "analyze" {
        Analyze-RepositoryDependencies | Out-Null
    }
    "graph" {
        Show-DependencyGraph
    }
    "validate" {
        Validate-Dependencies
    }
    "report" {
        Generate-DependencyReport
    }
    default {
        Write-Error "Invalid action: $Action. Use: analyze, graph, validate, or report"
    }
}