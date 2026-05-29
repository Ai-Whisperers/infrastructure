# Project TODOs Directory

This directory contains TODO lists for all AI-Whisperers organization repositories, synchronized via the Excalibur command.

## Purpose

The Excalibur sync command (`claude pull excalibur`) fetches live data from GitHub and generates/updates TODO files for each repository in the organization.

## Structure

Each repository has its own TODO file:
- `{repository-name}-todos.md` - Standard naming pattern
- Example: `ai-investment-todos.md`, `comment-analizer-todos.md`

## How It Works

1. **Manual Sync**: Run `claude pull excalibur` in Claude Code
2. **Automatic Updates**: The excalibur-command.ps1 script:
   - Fetches repository data from GitHub API
   - Retrieves open issues and PRs
   - Generates/updates TODO markdown files
   - Optionally syncs back to each repository's TODO.md

## File Format

Each TODO file contains:
- Repository metadata (description, last push, etc.)
- Current open issues from GitHub
- Active pull requests
- Recent commit activity
- Priority tasks based on repository type

## Synchronization

- **Local**: Files stored in this directory for quick reference
- **Remote**: Can be pushed to individual repositories via excalibur script
- **Workflow**: GitHub Actions workflow monitors changes and syncs

## Usage

### View TODOs
```powershell
# List all repository TODOs
& scripts\todo-manager.ps1 -Action list

# View specific repository status
& scripts\todo-manager.ps1 -Action status -Repository "AI-Investment"
```

### Generate Report
```powershell
# Create comprehensive TODO report
& scripts\todo-manager.ps1 -Action report
```

### Sync with GitHub
```powershell
# Dry run (preview changes)
& scripts\excalibur-command.ps1 -Action sync -DryRun -Verbose

# Actual sync
& scripts\excalibur-command.ps1 -Action sync -Verbose
```

## Automation

The `.github/workflows/todo-sync.yml` workflow automatically:
- Triggers on changes to files in this directory
- Syncs updated TODOs to respective repositories
- Creates commits with proper attribution

## Integration with Dashboard

The dashboard at `apps/dashboard` displays TODO information:
- Visual TODO tracking per project
- Priority indicators
- Completion status
- Real-time updates via API

## Notes

- TODOs are generated from live GitHub data
- Manual edits may be overwritten on next sync
- For custom TODOs, add them directly to the repository's TODO.md
- Excalibur command requires `GITHUB_TOKEN` environment variable

---

*Last Updated: 2025-10-01*
*Maintained by: AI-Whisperers Org OS*
