# Migration Guide: main → feats-n-optimization

This guide helps you migrate from the `main` branch to the `feats-n-optimization` branch (v0.1.0).

## Overview

The `feats-n-optimization` branch introduces a major architectural overhaul with improved testing, automation, and organization. This migration guide ensures a smooth transition.

---

## Pre-Migration Checklist

Before migrating, ensure you have:

- [ ] **Backups**: Create a full backup of your current setup
- [ ] **Clean Working Directory**: Commit or stash all local changes
- [ ] **Node.js 18+**: Verify with `node --version`
- [ ] **npm 9+**: Verify with `npm --version`
- [ ] **Git**: Latest version recommended
- [ ] **GitHub CLI** (optional): For enhanced workflows - `gh --version`

---

## Step 1: Update Your Local Repository

### Pull the Latest Changes

```bash
# Ensure you're on main and up-to-date
git checkout main
git pull origin main

# Create a backup branch (optional but recommended)
git checkout -b backup-main-$(date +%Y%m%d)
git checkout main

# Fetch the feats-n-optimization branch
git fetch origin feats-n-optimization

# Switch to the new branch
git checkout feats-n-optimization
git pull origin feats-n-optimization
```

---

## Step 2: Environment Configuration

### Update Environment Variables

The new structure requires updated environment variables.

#### Create/Update `.env` File

```bash
# Copy the example file
cp .env.example .env

# Edit with your actual values
# Important: Update FILESYSTEM_ROOT to your actual project path
```

#### Required Environment Variables

```env
# GitHub Integration
GITHUB_TOKEN=your_github_personal_access_token
GITHUB_ORG=Ai-Whisperers
GITHUB_CLIENT_ID=your_oauth_app_client_id
GITHUB_CLIENT_SECRET=your_oauth_app_secret

# Azure DevOps (if used)
AZURE_DEVOPS_PAT=your_azure_devops_pat
AZURE_DEVOPS_ORG=your_org_name
AZURE_DEVOPS_PROJECT=your_project_name

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/orgos_db

# Redis (for job queues)
REDIS_HOST=localhost
REDIS_PORT=6379

# Port Configuration
DASHBOARD_PORT=3001
JOBS_PORT=4000

# Dashboard
DASHBOARD_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:4000
NEXTAUTH_URL=http://localhost:3001
NEXTAUTH_SECRET=generate_a_random_32_character_string

# File System (auto-detected by scripts now)
FILESYSTEM_ROOT=/path/to/your/project/root
FILESYSTEM_ALLOW_WRITE=true
```

---

## Step 3: Install Dependencies

The new structure uses npm workspaces for managing the monorepo.

```bash
# Install all dependencies (root + workspaces)
npm install

# Verify installation
npm run typecheck
```

### If You Encounter Issues

```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
rm -rf apps/*/node_modules
rm -rf services/*/node_modules
npm install
```

---

## Step 4: Database Setup

The new architecture uses Prisma ORM with PostgreSQL.

### Option A: PostgreSQL (Recommended for Production)

```bash
# Start PostgreSQL (Docker example)
docker run --name orgos-postgres \
  -e POSTGRES_USER=orgos \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=orgos_db \
  -p 5432:5432 \
  -d postgres:14

# Run migrations
cd services/jobs
npx prisma migrate deploy
npx prisma generate

# Seed database (optional)
npm run seed
```

### Option B: SQLite (Development Only)

```bash
# Update services/jobs/prisma/schema.prisma
# Change provider to "sqlite"
# Then run migrations
cd services/jobs
npx prisma migrate deploy
npx prisma generate
```

---

## Step 5: Start Services

The new architecture has two main services:

### Development Mode

```bash
# Option 1: Start both services together
npm run dev

# Option 2: Start individually
npm run dev:dashboard  # Port 3001 (Express server)
npm run dev:jobs       # Port 4000 (NestJS backend)

# Option 3: Use the batch scripts (Windows)
.\start-dev.bat
# or (PowerShell)
.\start-dev.ps1
```

### Verify Services Are Running

- **Dashboard**: http://localhost:3001
- **Backend API**: http://localhost:4000
- **API Docs**: http://localhost:4000/api (Swagger)
- **Health Check**: http://localhost:4000/health

---

## Step 6: Script Migration

All PowerShell scripts now use dynamic path resolution.

### What Changed

**Before:**
```powershell
$ProjectRoot = "C:\Users\kyrian\Documents\Company-Information"
```

**After:**
```powershell
. "$PSScriptRoot\common\PathResolver.ps1"
$ProjectRoot = Get-ProjectRoot
```

### No Action Required

If you've been using the scripts as-is, they now work from any location automatically.

### If You Have Custom Scripts

Update them to use PathResolver:

```powershell
# At the top of your script
. "$PSScriptRoot\common\PathResolver.ps1"

# Then use the utilities
$todosPath = Get-ProjectPath "project-todos"
$logsPath = Get-ProjectPath "logs"
Ensure-DirectoryExists $logsPath
```

---

## Step 7: GitHub Actions Workflows

New workflows have been added. Update your repository settings if needed.

### Required Secrets

Add these to your repository secrets (Settings → Secrets):

- `GITHUB_TOKEN` - Automatically provided by GitHub Actions
- `CODECOV_TOKEN` - For code coverage (optional)
- `AZURE_DEVOPS_PAT` - If using Azure DevOps sync

### Workflows Overview

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test-suite.yml` | Push to main/develop | Run all tests |
| `file-sync.yml` | Manual/Schedule | Sync files across repos |
| `todo-sync.yml` | Changes to project-todos/ | Sync TODOs to repos |
| `repo-status.yml` | Schedule (weekly) | Generate status reports |
| `azure-devops-sync.yml` | Manual | Sync with Azure DevOps |

---

## Step 8: Verify Migration

Run these commands to verify everything works:

### 1. Health Checks

```bash
# Check dashboard health
curl http://localhost:3001

# Check backend health
curl http://localhost:4000/health

# Should return: {"status":"ok","timestamp":"..."}
```

### 2. Run Tests

```bash
# Unit tests
npm run test:unit

# Integration tests (requires DB)
npm run test:integration

# E2E tests (requires services running)
npm run test:e2e

# All tests with coverage
npm run test:coverage
```

### 3. Test PowerShell Scripts

```powershell
# Test path resolution
& scripts\quick-mcp-test.ps1

# Test excalibur command (dry run)
& scripts\excalibur-command.ps1 -Action sync -DryRun -Verbose

# Generate TODO report
& scripts\todo-manager.ps1 -Action report
```

---

## Step 9: Update Your Workflows

If you have custom workflows or integrations:

### Update File Paths

- `documentation-templates/` → Still in root (unchanged)
- `project-todos/` → Now exists (was deleted, now restored)
- Scripts can now be run from anywhere (portable)

### Update API Endpoints

The backend API has moved from file-based to NestJS service:

**Old:**
```
Direct file access
```

**New:**
```
http://localhost:4000/api/health
http://localhost:4000/api/repos
http://localhost:4000/api/reports/{id}
```

See API documentation at http://localhost:4000/api for full endpoint list.

---

## Troubleshooting

### Issue: "Cannot find module"

**Solution:**
```bash
npm install
cd apps/dashboard && npm install
cd ../..
cd services/jobs && npm install
```

### Issue: "Port already in use"

**Solution:**
```bash
# Find process using port
# Windows:
netstat -ano | findstr :3001
# Linux/Mac:
lsof -i :3001

# Kill process or change port in .env
DASHBOARD_PORT=3002 npm run dev:dashboard
```

### Issue: "Database connection failed"

**Solution:**
```bash
# Check DATABASE_URL in .env
# Ensure PostgreSQL is running
docker ps | grep postgres

# Test connection
cd services/jobs
npx prisma db push
```

### Issue: "Scripts fail with path errors"

**Solution:**
```powershell
# Ensure PathResolver exists
ls scripts\common\PathResolver.ps1

# Run script with verbose output
& scripts\excalibur-command.ps1 -Verbose

# Check environment variable
$env:FILESYSTEM_ROOT
```

### Issue: "GitHub Actions failing"

**Solution:**
1. Check repository secrets are set
2. Verify workflow permissions (Settings → Actions → General)
3. Review workflow logs for specific errors
4. Ensure branch protection rules allow workflows

---

## Rolling Back

If you need to roll back to main:

```bash
# Switch back to main
git checkout main

# If you made commits on feats-n-optimization you want to keep
git checkout -b feats-n-optimization-backup
git checkout main

# Restore old configuration
# (Your old .env and node_modules will need reinstallation)
npm install
```

---

## Post-Migration Tasks

After successful migration:

### 1. Update Documentation

- Review and update any custom documentation
- Update team onboarding guides
- Update deployment documentation

### 2. Configure CI/CD

- Enable new GitHub Actions workflows
- Set up code coverage reporting
- Configure deployment pipelines

### 3. Team Communication

- Notify team members of the migration
- Share this migration guide
- Schedule knowledge sharing session

### 4. Monitoring

- Set up error tracking (Sentry, etc.)
- Configure log aggregation
- Set up performance monitoring

---

## What's New?

### Major Features

✅ **Monorepo Structure** - Clean separation of dashboard and services
✅ **Modern Tech Stack** - Next.js 14, NestJS 10, Prisma, TypeScript
✅ **Comprehensive Testing** - Unit, integration, E2E, performance tests
✅ **CI/CD Automation** - GitHub Actions workflows for everything
✅ **Portable Scripts** - No more hardcoded paths!
✅ **Database Integration** - Prisma ORM with PostgreSQL/SQLite support
✅ **API Documentation** - Interactive Swagger docs

### Breaking Changes

⚠️ None! All changes are additive or improvements.

---

## Getting Help

If you encounter issues during migration:

1. **Check the Logs**: Look at service logs for specific errors
2. **Review Documentation**: Check README.md and docs/ folder
3. **GitHub Issues**: Search existing issues or create a new one
4. **Team Chat**: Ask in your team's communication channel

---

## Migration Checklist

Use this checklist to track your progress:

- [ ] Backed up current setup
- [ ] Pulled feats-n-optimization branch
- [ ] Created/updated .env file
- [ ] Installed dependencies (`npm install`)
- [ ] Set up database (PostgreSQL or SQLite)
- [ ] Ran migrations (`npx prisma migrate deploy`)
- [ ] Started services (`npm run dev`)
- [ ] Verified dashboard (http://localhost:3001)
- [ ] Verified API (http://localhost:4000)
- [ ] Ran tests (`npm test`)
- [ ] Tested PowerShell scripts
- [ ] Updated GitHub secrets (if applicable)
- [ ] Verified GitHub Actions workflows
- [ ] Updated team documentation
- [ ] Notified team members

---

**Migration completed successfully? Welcome to the new AI-Whisperers Org OS!** 🎉

For questions or issues, create a GitHub issue or contact the development team.

---

*Last Updated: 2025-10-01*
*Version: 0.1.0*
