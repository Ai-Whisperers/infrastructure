# Changelog

All notable changes to the AI-Whisperers Org OS project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **PathResolver Utility**: Created `scripts/common/PathResolver.ps1` for cross-platform path resolution
  - Eliminates all hardcoded paths in PowerShell scripts
  - Provides functions: `Get-ProjectRoot`, `Get-ProjectPath`, `Ensure-DirectoryExists`
  - Supports environment variable fallbacks

- **Project TODOs Directory**: Restored `project-todos/` structure
  - Added comprehensive README explaining sync workflow
  - Integration with Excalibur command
  - GitHub Actions workflow support

- **Documentation**
  - Added CHANGELOG.md (this file)
  - Added MIGRATION.md for upgrade guidance
  - Enhanced project-todos/README.md with usage examples

### Changed
- **All PowerShell Scripts**: Converted from hardcoded paths to dynamic resolution
  - `scripts/excalibur-command.ps1` - Uses PathResolver
  - `scripts/todo-manager.ps1` - Uses PathResolver
  - `scripts/file-sync-manager.ps1` - Uses PathResolver
  - `scripts/file-sync-advanced.ps1` - Uses PathResolver
  - `scripts/quick-mcp-test.ps1` - Uses Get-ProjectRoot
  - `scripts/full-mcp-test.ps1` - Uses Get-ProjectRoot

- **Configuration Files**
  - `.env.example` - Updated FILESYSTEM_ROOT with placeholder instead of hardcoded path
  - `apps/dashboard/api-server.js` - Fixed excaliburScript and todosDir paths

### Fixed
- **Critical Path Issues**
  - Removed 15 hardcoded path instances (C:\Users\kyrian\Documents\...)
  - All scripts now portable across different machines and platforms
  - Dashboard API server now uses relative paths

- **Project Structure**
  - Restored missing `project-todos/` directory with proper documentation
  - Created `logs/` directory for automated log storage
  - Fixed dashboard todosDir reference

### Security
- **CVE-2025-54798 Mitigation**: Added npm override to fix `tmp` package vulnerability (≤ 0.2.3 → ^0.2.4)
  - Low severity symlink vulnerability in dev dependency
  - Affects: @nestjs/cli → inquirer → external-editor → tmp
  - Added `"overrides": { "tmp": "^0.2.4" }` in package.json
  - Documented in new SECURITY.md file
  - Clean install required to fully apply the override
- **npm Dependencies**: Audited and documented vulnerabilities
  - 5 low severity issues in dev dependencies (@nestjs/cli, tmp, inquirer)
  - Breaking change fix available but deferred (would require @nestjs/cli@11.0.10)
  - Issues only affect development, not production runtime

### Deprecated
- Hardcoded path patterns in scripts (fully removed)
- Direct path references without PathResolver utility

### Technical Debt Addressed
- ✅ All hardcoded paths eliminated
- ✅ Project-todos directory restored
- ✅ Dashboard API paths fixed
- ⚠️ npm vulnerabilities documented (low severity, dev-only)
- ⏳ Excalibur sync still uses simulation in dashboard.js (TODO: implement actual API call)

## Version History

### [0.1.0] - 2025-10-01 (Pre-release)

This represents the state of the `feats-n-optimization` branch with all critical fixes applied.

**Major Changes from main:**
- Complete monorepo restructuring
- Added Next.js dashboard application
- Added NestJS jobs service
- Comprehensive test infrastructure
- GitHub Actions CI/CD workflows
- Database schema with Prisma ORM
- Docker support for local development

---

## Upgrade Notes

See [MIGRATION.md](./MIGRATION.md) for detailed upgrade instructions from main branch.

## Breaking Changes

None in this release. All changes are additions or improvements to existing functionality.

## Contributors

- AI-Whisperers Development Team
- Claude Code (Automated fixes and optimizations)

---

*For more details on specific commits, use `git log` or view the PR diff.*
