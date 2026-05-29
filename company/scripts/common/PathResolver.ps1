# PathResolver.ps1
# Common path resolution utility for all PowerShell scripts
# Usage: . "$PSScriptRoot\common\PathResolver.ps1"

<#
.SYNOPSIS
    Provides cross-platform, portable path resolution for the Company-Information project.

.DESCRIPTION
    This utility eliminates hardcoded paths by providing dynamic path resolution
    based on script location. All paths are resolved relative to the project root.

.EXAMPLE
    . "$PSScriptRoot\common\PathResolver.ps1"
    $projectRoot = Get-ProjectRoot
    $todosPath = Get-ProjectPath "project-todos"
#>

function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Returns the absolute path to the project root directory.

    .DESCRIPTION
        Calculates the project root by navigating up from the scripts directory.
        Handles being called from scripts/ or scripts/common/.

    .OUTPUTS
        String - Absolute path to project root
    #>

    # Get the scripts directory
    $scriptsDir = $PSScriptRoot

    # If we're in scripts/common, go up two levels
    if ($scriptsDir -match 'scripts[\\\/]common$') {
        return Split-Path (Split-Path $scriptsDir -Parent) -Parent
    }
    # If we're in scripts, go up one level
    elseif ($scriptsDir -match 'scripts$') {
        return Split-Path $scriptsDir -Parent
    }
    # Otherwise, assume we're already at or near root
    else {
        return $scriptsDir
    }
}

function Get-ProjectPath {
    <#
    .SYNOPSIS
        Returns an absolute path relative to the project root.

    .DESCRIPTION
        Combines the project root with a relative path, ensuring cross-platform compatibility.

    .PARAMETER RelativePath
        The relative path from project root (e.g., "project-todos", "logs")

    .OUTPUTS
        String - Absolute path

    .EXAMPLE
        Get-ProjectPath "project-todos"
        # Returns: C:\path\to\Company-Information\project-todos

    .EXAMPLE
        Get-ProjectPath "logs\excalibur.log"
        # Returns: C:\path\to\Company-Information\logs\excalibur.log
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$RelativePath
    )

    $root = Get-ProjectRoot
    return Join-Path $root $RelativePath
}

function Ensure-DirectoryExists {
    <#
    .SYNOPSIS
        Ensures a directory exists, creating it if necessary.

    .DESCRIPTION
        Checks if a directory exists and creates it (including parent directories) if not.

    .PARAMETER Path
        The directory path to ensure exists

    .PARAMETER Silent
        Suppress console output

    .OUTPUTS
        Boolean - True if directory exists or was created successfully

    .EXAMPLE
        Ensure-DirectoryExists (Get-ProjectPath "logs")
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [switch]$Silent
    )

    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            if (-not $Silent) {
                Write-Host "Created directory: $Path" -ForegroundColor Green
            }
            return $true
        }
        catch {
            Write-Error "Failed to create directory ${Path}: $_"
            return $false
        }
    }

    return $true
}

function Get-EnvironmentVariable {
    <#
    .SYNOPSIS
        Gets an environment variable with a fallback default value.

    .DESCRIPTION
        Attempts to get an environment variable, returning a default if not found.
        Useful for configuration that can be overridden via environment variables.

    .PARAMETER Name
        The environment variable name

    .PARAMETER Default
        The default value if the environment variable is not set

    .OUTPUTS
        String - The environment variable value or default

    .EXAMPLE
        $apiUrl = Get-EnvironmentVariable "API_BASE_URL" "http://localhost:4000"
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [string]$Default = $null
    )

    $value = [System.Environment]::GetEnvironmentVariable($Name)

    if ([string]::IsNullOrEmpty($value)) {
        return $Default
    }

    return $value
}

function Get-ScriptRelativePath {
    <#
    .SYNOPSIS
        Returns a path relative to the calling script's location.

    .DESCRIPTION
        Useful for scripts that need to reference files relative to themselves,
        not relative to the project root.

    .PARAMETER RelativePath
        The relative path from the calling script's directory

    .PARAMETER ScriptPath
        The calling script's $PSScriptRoot value

    .OUTPUTS
        String - Absolute path

    .EXAMPLE
        $configPath = Get-ScriptRelativePath "config.json" $PSScriptRoot
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$RelativePath,

        [Parameter(Mandatory=$true)]
        [string]$ScriptPath
    )

    return Join-Path $ScriptPath $RelativePath
}

# Export module members (optional, for advanced usage)
Export-ModuleMember -Function @(
    'Get-ProjectRoot',
    'Get-ProjectPath',
    'Ensure-DirectoryExists',
    'Get-EnvironmentVariable',
    'Get-ScriptRelativePath'
)

# Display helpful message when dot-sourced
if ($MyInvocation.InvocationName -eq '.') {
    Write-Verbose "PathResolver loaded. Project root: $(Get-ProjectRoot)"
}
