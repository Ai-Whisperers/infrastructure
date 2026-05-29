# GitHub Tracking Scripts

This directory contains PowerShell scripts for monitoring Ai-Whisperers organization activity.

## Prerequisites

1. **GitHub CLI**: Install and authenticate
   ```bash
   winget install GitHub.cli
   gh auth login
   ```

2. **PowerShell**: Scripts are written for PowerShell (Windows/Linux/macOS)

## Scripts

### 1. github-commit-tracker.ps1
Daily commit summary across all repositories.

**Usage:**
```powershell
# Get commits from last 1 day (default)
.\github-commit-tracker.ps1

# Get commits from last 3 days
.\github-commit-tracker.ps1 -Days 3
```

**Features:**
- Lists all repositories with recent commits
- Shows commit counts and latest commit details
- Displays author and timestamp information
- Provides summary statistics

### 2. new-repo-monitor.ps1
Monitors for new repositories in the organization.

**Usage:**
```powershell
# Check for new repos in last 7 days (default)
.\new-repo-monitor.ps1

# Check for new repos in last 30 days
.\new-repo-monitor.ps1 -Days 30
```

**Features:**
- Identifies newly created repositories
- Shows creation dates and privacy settings
- Checks for empty repositories needing setup
- Alerts for repositories missing README files

### 3. weekly-activity-report.ps1
Comprehensive weekly activity report.

**Usage:**
```powershell
# Generate 7-day report (default)
.\weekly-activity-report.ps1

# Generate 14-day report
.\weekly-activity-report.ps1 -Days 14
```

**Features:**
- Commit, PR, and issue activity across all repos
- Top contributors ranking
- Repository activity ranking
- Organization-wide statistics
- Stars and forks tracking

## Automation Setup

### Windows Task Scheduler

Create scheduled tasks to run these scripts automatically:

1. **Daily Commit Summary** (run daily at 9 AM):
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\github-commit-tracker.ps1"
   ```

2. **Weekly Activity Report** (run Mondays at 8 AM):
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\weekly-activity-report.ps1"
   ```

3. **New Repository Check** (run daily at 10 AM):
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\new-repo-monitor.ps1"
   ```

   Replace `%PROJECT_ROOT%` with your actual project root path.

### PowerShell Profile Integration

Add to your PowerShell profile (`$PROFILE`) for quick access:

```powershell
# Set your project root path
$ProjectRoot = "YOUR_PROJECT_ROOT_PATH_HERE"

# GitHub tracking aliases
function Get-DailyCommits {
    & "$ProjectRoot\scripts\github-commit-tracker.ps1" @args
}

function Get-NewRepos {
    & "$ProjectRoot\scripts\new-repo-monitor.ps1" @args
}

function Get-WeeklyReport {
    & "$ProjectRoot\scripts\weekly-activity-report.ps1" @args
}

Set-Alias -Name commits -Value Get-DailyCommits
Set-Alias -Name newrepos -Value Get-NewRepos
Set-Alias -Name weeklyreport -Value Get-WeeklyReport
```

Then use simple commands:
```powershell
commits
newrepos -Days 14
weeklyreport
```

## Output Examples

### Daily Commits
```
=== AI-Whisperers Daily Commit Summary ===
📁 web-platform
   └── 3 commits in last 1 day
   └── Latest: feat: Add user authentication flow
       by John Doe on 09/08 14:30

📁 core-services  
   └── 1 commit in last 1 day
   └── Latest: fix: Resolve database connection timeout
       by Jane Smith on 09/08 16:45

=== Summary ===
Total commits: 4
Active repositories: 2
```

### New Repositories
```
=== AI-Whisperers New Repository Monitor ===
🆕 Found 1 new repository:

📁 mobile-app
   └── Created: 2025-09-01 10:30
   └── Privacy: 🔒 Private
   └── Description: React Native mobile application
   └── URL: https://github.com/Ai-Whisperers/mobile-app
```

## Troubleshooting

1. **Authentication Error**: Run `gh auth login` to authenticate
2. **Permission Denied**: Run `Set-ExecutionPolicy RemoteSigned` in PowerShell as admin
3. **Rate Limiting**: Scripts respect GitHub API rate limits automatically
4. **Empty Output**: Check if repositories exist and you have access permissions

## Customization

All scripts accept parameters and can be modified for:
- Different time periods
- Custom output formats
- Additional repository metrics
- Integration with other tools (Slack, email, etc.)