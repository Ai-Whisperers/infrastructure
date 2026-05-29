# Environment Variable Handshake Documentation

**Status**: ✅ Complete
**Last Updated**: 2025-10-04
**Contract Version**: 1.0

---

## Overview

The Company-Information project uses a **unified environment variable contract** with a single source of truth at the ROOT level. All services, scripts, and configurations inherit from this central `.env` file.

## Architecture

```
┌─────────────────────────────────────┐
│      ROOT .env (Contract)           │ ← Single Source of Truth
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┬─────────────────┐
       │                │                 │
       ▼                ▼                 ▼
┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ Jobs Service │ │  Dashboard  │ │   Scripts    │
│  (NestJS)    │ │  (Express)  │ │(PowerShell)  │
│              │ │             │ │              │
│ ConfigModule │ │  dotenv     │ │PathResolver  │
│ reads        │ │  loads      │ │auto-detects  │
│ ../../../.env│ │ ../../.env  │ │PROJECT_ROOT  │
└──────────────┘ └─────────────┘ └──────────────┘
```

## File Structure

```
company-information/
├── .env                        # ✅ Active config (gitignored)
├── .env.example                # ✅ Template (committed)
├── .env.local                  # ✅ Local overrides (gitignored)
│
├── services/
│   └── jobs/
│       ├── ENV_README.md       # ✅ Service-specific instructions
│       ├── src/
│       │   └── app.module.ts   # ✅ Reads ROOT .env
│       └── .env.example.deprecated
│
├── apps/
│   └── dashboard/
│       └── api-server.js       # ✅ Loads ROOT .env
│
└── scripts/
    └── common/
        └── PathResolver.ps1    # ✅ Auto-detects PROJECT_ROOT
```

## Configuration Details

### 1. Jobs Service (NestJS)

**File**: `services/jobs/src/app.module.ts`

```typescript
ConfigModule.forRoot({
  isGlobal: true,
  envFilePath: [
    '../../../.env',        // ROOT .env (primary)
    '../../../.env.local',  // ROOT .env.local (overrides)
    '.env',                 // LOCAL .env (fallback, not recommended)
  ],
})
```

**Verification**:
```bash
cd services/jobs
node -e "require('dotenv').config({path:'../../.env'}); console.log('GITHUB_TOKEN:', process.env.GITHUB_TOKEN?.substring(0,8)+'...')"
```

### 2. Dashboard (Express)

**File**: `apps/dashboard/api-server.js`

```javascript
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const CONFIG = {
    organization: process.env.GITHUB_ORG || 'Ai-Whisperers',
    githubToken: process.env.GITHUB_TOKEN,
    jobsServiceUrl: process.env.JOBS_SERVICE_URL || 'http://localhost:4000'
};
```

**Verification**:
```bash
cd apps/dashboard
node -e "require('dotenv').config({path:'../../.env'}); console.log('DASHBOARD_PORT:', process.env.DASHBOARD_PORT)"
```

### 3. PowerShell Scripts

**File**: `scripts/common/PathResolver.ps1`

```powershell
function Get-ProjectRoot {
    # Automatically detects project root by traversing up from script location
    $current = $PSScriptRoot
    while ($current) {
        if (Test-Path (Join-Path $current ".git")) {
            return $current
        }
        $current = Split-Path $current -Parent
    }
}

function Get-EnvVariable {
    param([string]$Name)
    # Reads from ROOT .env if needed
    return [Environment]::GetEnvironmentVariable($Name) ?? (Get-DotEnvValue $Name)
}
```

**Verification**:
```powershell
.\scripts\verify-env-setup.ps1
```

---

## Environment Variable Contract

### Core System

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODE_ENV` | No | `development` | Environment name |
| `LOG_LEVEL` | No | `info` | Logging verbosity |
| `PROJECT_ROOT` | No | Auto-detected | Project root path |

### GitHub Integration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GITHUB_TOKEN` | **Yes** | - | Personal access token |
| `GITHUB_ORG` | No | `Ai-Whisperers` | Organization name |
| `GITHUB_CLIENT_ID` | No | - | OAuth app client ID |
| `GITHUB_CLIENT_SECRET` | No | - | OAuth app secret |

### Database

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | **Yes** | - | Prisma connection string |

**Development**: `file:./services/jobs/dev.db`
**Production**: `postgresql://user:pass@host:5432/dbname`

### Service Ports

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `JOBS_PORT` | No | `4000` | NestJS backend port |
| `DASHBOARD_PORT` | No | `3001` | Express frontend port |

### Service URLs (Auto-constructed)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `JOBS_SERVICE_URL` | No | `http://localhost:4000` | Backend API URL |
| `DASHBOARD_URL` | No | `http://localhost:3001` | Frontend URL |
| `FRONTEND_URL` | No | `http://localhost:3001` | For CORS config |

### Redis (Optional)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `REDIS_HOST` | No | `localhost` | Redis server host |
| `REDIS_PORT` | No | `6379` | Redis server port |
| `SKIP_REDIS_IN_TESTS` | No | `true` | Use mock queue in tests |

---

## Handshake Verification

### Automated Verification

```bash
# Run verification script
.\scripts\verify-env-setup.ps1
```

**Checks performed**:
1. ✅ ROOT .env exists
2. ✅ No redundant .env files in subdirectories
3. ✅ Required variables are set
4. ✅ Port configuration is consistent
5. ✅ Services configured to read ROOT .env
6. ✅ .gitignore properly configured

### Manual Verification

#### 1. Check ROOT .env exists
```bash
test -f .env && echo "✅ EXISTS" || echo "❌ MISSING"
```

#### 2. Verify Jobs Service reads ROOT
```bash
cd services/jobs
grep -A 5 "ConfigModule.forRoot" src/app.module.ts | grep "../../../.env"
```

#### 3. Verify Dashboard reads ROOT
```bash
grep "dotenv.*\.\.\/\.\.\/\.env" apps/dashboard/api-server.js
```

#### 4. Test actual handshake
```bash
# Start jobs service in one terminal
cd services/jobs
npm run dev

# Start dashboard in another terminal
cd apps/dashboard
node api-server.js

# Both should show same GITHUB_ORG value
```

---

## Migration from Old Setup

### Before (Fragmented)
```
company-information/
├── .env (hardcoded paths)
├── services/jobs/.env (different values)
├── apps/dashboard/.env (duplicate config)
└── scripts/ (hardcoded C:\Users\kyrian\...)
```

### After (Unified)
```
company-information/
├── .env (single source of truth, no hardcoded paths)
├── services/jobs/ (reads ROOT .env)
├── apps/dashboard/ (reads ROOT .env)
└── scripts/ (auto-detects paths)
```

### Migration Steps

1. **Backup existing .env files**:
   ```bash
   cp .env .env.backup
   cp services/jobs/.env services/jobs/.env.backup
   ```

2. **Remove redundant .env files**:
   ```bash
   rm services/jobs/.env
   rm apps/dashboard/.env
   ```

3. **Create ROOT .env from template**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

4. **Verify setup**:
   ```bash
   .\scripts\verify-env-setup.ps1
   ```

5. **Test services**:
   ```bash
   npm run dev
   ```

---

## Troubleshooting

### Problem: "Cannot find module 'dotenv'"

**Cause**: Missing dotenv dependency in dashboard

**Solution**:
```bash
npm install dotenv
```

### Problem: "Config validation error: GITHUB_TOKEN is required"

**Cause**: .env doesn't exist or variable not set

**Solution**:
```bash
# Check .env exists
ls -la .env

# Check variable is set
grep GITHUB_TOKEN .env

# If missing, copy from example
cp .env.example .env
# Then edit .env and set your token
```

### Problem: "Database not found"

**Cause**: DATABASE_URL points to wrong location

**Solution**:
```bash
# In ROOT .env, set:
DATABASE_URL=file:./services/jobs/dev.db

# Initialize database
cd services/jobs
npx prisma migrate deploy
```

### Problem: "Port 3001 already in use"

**Cause**: Another process using the port

**Solution**:
```bash
# Option 1: Kill the process
# On Windows:
netstat -ano | findstr :3001
taskkill /PID <PID> /F

# Option 2: Change port in .env
DASHBOARD_PORT=3002
```

### Problem: Services read different .env values

**Cause**: Cached .env files or wrong path

**Solution**:
```bash
# 1. Verify no redundant .env files
find . -name ".env" -type f

# 2. Clear Node module cache
npm run clean

# 3. Restart services
npm run dev
```

---

## Best Practices

### ✅ DO

- Use ROOT `.env` for all configuration
- Keep `.env.example` up to date
- Use `.env.local` for personal overrides
- Auto-detect PROJECT_ROOT in scripts
- Document new variables in .env.example
- Verify setup with `verify-env-setup.ps1`

### ❌ DON'T

- Create `.env` files in subdirectories
- Hardcode paths anywhere in code
- Commit `.env` to git
- Use absolute paths in configuration
- Duplicate environment variables
- Skip verification after changes

---

## Security Considerations

1. **Never commit .env**: Enforced by .gitignore
2. **Use placeholder values in .env.example**: Template only
3. **Rotate tokens regularly**: Update .env when tokens change
4. **Limit token scopes**: Only grant necessary permissions
5. **Use .env.local for sensitive overrides**: Personal credentials

---

## Change Log

### Version 1.0 (2025-10-04)

- ✅ Created unified ROOT .env.example as contract
- ✅ Updated Jobs Service to read ROOT .env
- ✅ Updated Dashboard to load ROOT .env
- ✅ Fixed all hardcoded paths in documentation
- ✅ Deprecated services/jobs/.env.example
- ✅ Updated .gitignore for proper exclusions
- ✅ Created verification script
- ✅ Updated README.md with env documentation
- ✅ Created ENV_HANDSHAKE.md (this document)

---

**Maintained by**: AI-Whisperers Platform Team
**Questions**: See README.md or create an issue
