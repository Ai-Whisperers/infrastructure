# Fix for Report Generation Issue

## Problem Summary
The web application at http://localhost:3000/reports is showing only 3 mock repositories and failing to generate reports because:
1. The backend API service (port 4000) is not running
2. GitHub authentication tokens are not configured
3. The application falls back to mock data when the API is unavailable

## Root Causes

### 1. Backend API Not Running
- The backend service at port 4000 failed to start
- Port 4000 is not listening for connections
- API endpoints are unreachable

### 2. Missing Configuration
The `.env` file contains placeholder values instead of actual tokens:
```
GITHUB_PAT=your_github_personal_access_token_here
GITHUB_TOKEN=your_github_personal_access_token_here
```

### 3. Dependency Issues
- The k6 package had versioning issues (already fixed to @grafana/k6)
- Backend service may have additional startup issues

## Solution Steps

### Step 1: Configure GitHub Authentication

1. **Create a GitHub Personal Access Token:**
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Click "Generate new token (classic)"
   - Select scopes:
     - `repo` (full control of private repositories)
     - `read:org` (read organization data)
   - Copy the generated token

2. **Update the .env file:**
   ```bash
   # Edit the .env file
   GITHUB_PAT=ghp_YOUR_ACTUAL_TOKEN_HERE
   GITHUB_TOKEN=ghp_YOUR_ACTUAL_TOKEN_HERE
   GITHUB_ORG=Ai-Whisperers  # Your organization name
   ```

### Step 2: Fix and Start Backend Service

1. **Check backend logs:**
   ```powershell
   cd services/jobs
   npm run dev
   ```

2. **If there are dependency issues:**
   ```powershell
   cd services/jobs
   npm install --legacy-peer-deps
   npx prisma generate
   npx prisma migrate dev
   ```

3. **Verify the backend is running:**
   - Check http://localhost:4000/health
   - Check http://localhost:4000/api

### Step 3: Restart All Services

1. **Stop all running services:**
   - Close all PowerShell windows running Node processes

2. **Start services with proper configuration:**
   ```powershell
   # From the root directory
   powershell -ExecutionPolicy Bypass -File ./start-dev.ps1
   ```

3. **Verify services are running:**
   - Dashboard: http://localhost:3000 ✅
   - Backend API: http://localhost:4000 ✅
   - Health Check: http://localhost:4000/health ✅

### Step 4: Test Report Generation

1. Navigate to http://localhost:3000/reports
2. You should now see your actual GitHub repositories
3. Select a repository and try generating a report

## Alternative: Manual Backend Start

If the automated script fails, manually start each service:

**Terminal 1 - Backend:**
```powershell
cd services/jobs
npm install --legacy-peer-deps
npx prisma generate
npx prisma migrate dev
npm run dev
```

**Terminal 2 - Frontend:**
```powershell
cd apps/dashboard
npm install --legacy-peer-deps
npm run dev
```

## Verification Checklist

- [ ] GitHub token is configured in .env
- [ ] Backend API responds at http://localhost:4000/health
- [ ] Dashboard shows real repositories (not mock data)
- [ ] Report generation works for selected repositories
- [ ] No errors in browser console or terminal logs

## Common Issues

### Issue: "Cannot connect to GitHub API"
**Solution:** Verify your GitHub token has the correct permissions

### Issue: "Database connection failed"
**Solution:** Run `npx prisma migrate dev` in services/jobs directory

### Issue: "Port 4000 already in use"
**Solution:** Kill existing process: `taskkill /F /IM node.exe` or find and kill specific process using port 4000

## Current Mock Data
The application is currently showing 3 mock repositories:
- AI-Investment
- Comment-Analyzer
- clockify-ADO-automated-report

These are hardcoded fallback data when the API is unavailable.

## Next Steps
After fixing the configuration:
1. The app will fetch your actual GitHub repositories from the Ai-Whisperers organization
2. Real-time data will be available for report generation
3. Full functionality will be restored

---
*Generated: September 26, 2025*