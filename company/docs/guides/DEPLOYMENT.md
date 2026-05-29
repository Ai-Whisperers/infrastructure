# Production Deployment Guide

**Last Updated**: 2025-10-04
**Version**: 1.0.0
**Status**: Production Ready

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Database Configuration](#database-configuration)
4. [Service Deployment](#service-deployment)
5. [Health Monitoring](#health-monitoring)
6. [Error Tracking](#error-tracking)
7. [Scaling & Performance](#scaling--performance)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Node.js**: >= 18.0.0
- **npm**: >= 9.0.0
- **Database**: PostgreSQL 14+ (or SQLite for development)
- **Redis**: 6.0+ (optional, for job queues)
- **OS**: Linux (Ubuntu 20.04+ recommended), Windows Server 2019+, macOS

### Required Accounts

- GitHub Personal Access Token (scopes: `repo`, `read:org`, `workflow`)
- Azure DevOps Personal Access Token (optional)
- SMTP credentials (for notifications, optional)

---

## Environment Setup

### 1. Clone and Install

```bash
git clone https://github.com/Ai-Whisperers/Company-Information.git
cd Company-Information
npm install
```

### 2. Configure Environment Variables

```bash
# Copy template
cp .env.example .env

# Edit with production values
nano .env  # or your preferred editor
```

### Required Production Variables

```bash
# Environment
NODE_ENV=production
LOG_LEVEL=info
ENABLE_FILE_LOGGING=true

# GitHub
GITHUB_TOKEN=ghp_your_production_token
GITHUB_ORG=Ai-Whisperers

# Database (PostgreSQL)
DATABASE_URL=postgresql://username:password@db-host:5432/orgos_production

# Services
JOBS_PORT=4000
DASHBOARD_PORT=3001

# Redis (if using job queues)
REDIS_HOST=redis.example.com
REDIS_PORT=6379

# Security
JOBS_API_KEY=generate_secure_api_key_minimum_32_characters

# Optional: Error Tracking
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
```

---

## Database Configuration

### Option A: PostgreSQL (Recommended for Production)

#### 1. Install PostgreSQL

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 2. Create Database

```bash
sudo -u postgres psql

CREATE DATABASE orgos_production;
CREATE USER orgos_user WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE orgos_production TO orgos_user;
\q
```

#### 3. Update .env

```bash
DATABASE_URL=postgresql://orgos_user:secure_password@localhost:5432/orgos_production
```

#### 4. Run Migrations

```bash
cd services/jobs
npx prisma migrate deploy
npx prisma generate
```

### Option B: SQLite (Development Only)

```bash
DATABASE_URL=file:./services/jobs/prisma/dev.db

cd services/jobs
npx prisma migrate deploy
npx prisma generate
```

---

## Service Deployment

### Method 1: PM2 (Recommended)

#### Install PM2

```bash
npm install -g pm2
```

#### Create PM2 Ecosystem File

```bash
# ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'org-os-jobs',
      cwd: './services/jobs',
      script: 'npm',
      args: 'run start:prod',
      env: {
        NODE_ENV: 'production',
      },
      instances: 2,
      exec_mode: 'cluster',
      max_memory_restart: '512M',
      error_file: './logs/jobs-error.log',
      out_file: './logs/jobs-out.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    },
    {
      name: 'org-os-dashboard',
      cwd: './apps/dashboard',
      script: 'api-server.js',
      env: {
        NODE_ENV: 'production',
      },
      instances: 1,
      max_memory_restart: '256M',
      error_file: './logs/dashboard-error.log',
      out_file: './logs/dashboard-out.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    },
  ],
};
```

#### Deploy with PM2

```bash
# Build jobs service
cd services/jobs
npm run build
cd ../..

# Start all services
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
```

#### PM2 Commands

```bash
# View status
pm2 status

# View logs
pm2 logs

# Restart services
pm2 restart all

# Stop services
pm2 stop all

# Monitor resources
pm2 monit
```

### Method 2: Docker

#### Build Images

```bash
# Jobs Service
cd services/jobs
docker build -t org-os-jobs:latest .

# Dashboard
cd ../../apps/dashboard
docker build -t org-os-dashboard:latest .
```

#### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: orgos_production
      POSTGRES_USER: orgos_user
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U orgos_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  jobs:
    image: org-os-jobs:latest
    depends_on:
      - postgres
      - redis
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://orgos_user:secure_password@postgres:5432/orgos_production
      REDIS_HOST: redis
      REDIS_PORT: 6379
    ports:
      - "4000:4000"
    volumes:
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  dashboard:
    image: org-os-dashboard:latest
    depends_on:
      - jobs
    environment:
      NODE_ENV: production
      JOBS_SERVICE_URL: http://jobs:4000
    ports:
      - "3001:3001"
    volumes:
      - ./project-todos:/app/project-todos
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
```

#### Deploy with Docker Compose

```bash
docker-compose up -d
docker-compose logs -f
```

### Method 3: Systemd (Linux)

#### Create Service Files

```bash
# /etc/systemd/system/org-os-jobs.service
[Unit]
Description=AI-Whisperers Org OS Jobs Service
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/company-information/services/jobs
ExecStart=/usr/bin/npm run start:prod
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/systemd/system/org-os-dashboard.service
[Unit]
Description=AI-Whisperers Org OS Dashboard
After=network.target org-os-jobs.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/company-information/apps/dashboard
ExecStart=/usr/bin/node api-server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

#### Enable and Start

```bash
sudo systemctl daemon-reload
sudo systemctl enable org-os-jobs org-os-dashboard
sudo systemctl start org-os-jobs org-os-dashboard
sudo systemctl status org-os-jobs org-os-dashboard
```

---

## Health Monitoring

### Health Check Endpoints

#### Jobs Service

```bash
curl http://localhost:4000/health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-04T12:00:00.000Z",
  "service": "org-os-jobs",
  "version": "0.1.0",
  "uptime": 3600,
  "checks": {
    "database": true,
    "databaseError": null,
    "memory": true,
    "memoryUsage": {
      "rss": 125,
      "heapTotal": 80,
      "heapUsed": 45,
      "external": 2
    },
    "environment": "production",
    "nodeVersion": "v18.17.0"
  }
}
```

#### Dashboard

```bash
curl http://localhost:3001/health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-04T12:00:00.000Z",
  "service": "org-os-dashboard",
  "version": "1.0.0",
  "uptime": 3600,
  "checks": {
    "dashboard": true,
    "jobsService": true,
    "filesystem": true
  },
  "memoryUsage": {
    "rss": 65,
    "heapUsed": 35
  }
}
```

### Monitoring Setup

#### Option A: Uptime Robot

1. Sign up at https://uptimerobot.com
2. Add monitors for:
   - `http://your-domain.com:4000/health` (Jobs Service)
   - `http://your-domain.com:3001/health` (Dashboard)
3. Configure alerts via email/Slack/SMS

#### Option B: Custom Health Check Script

```bash
#!/bin/bash
# health-check.sh

JOBS_URL="http://localhost:4000/health"
DASHBOARD_URL="http://localhost:3001/health"

check_service() {
  local url=$1
  local name=$2

  response=$(curl -s -o /dev/null -w "%{http_code}" "$url")

  if [ "$response" != "200" ]; then
    echo "ALERT: $name is unhealthy (HTTP $response)" | mail -s "Service Alert" admin@example.com
    exit 1
  fi
}

check_service "$JOBS_URL" "Jobs Service"
check_service "$DASHBOARD_URL" "Dashboard"

echo "All services healthy"
```

Add to crontab:
```bash
*/5 * * * * /path/to/health-check.sh
```

---

## Error Tracking

### Built-in Logging

Logs are written to `services/jobs/logs/` in production when `ENABLE_FILE_LOGGING=true`.

**Log Files**:
- `YYYY-MM-DD.log` - All logs
- `YYYY-MM-DD-errors.log` - Errors only

### Optional: Sentry Integration

#### 1. Create Sentry Project

https://sentry.io → Create Project → Node.js

#### 2. Add Sentry DSN to .env

```bash
SENTRY_DSN=https://your-key@sentry.io/project-id
```

#### 3. Install Sentry SDK

```bash
cd services/jobs
npm install @sentry/node
```

#### 4. Initialize in main.ts

```typescript
import * as Sentry from '@sentry/node';

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 0.1,
  });
}
```

---

## Scaling & Performance

### Horizontal Scaling

#### Jobs Service

- Run multiple instances behind a load balancer
- Use Redis for shared job queue
- Configure clustering in PM2 (already in ecosystem.config.js)

#### Database

- Use read replicas for heavy read workloads
- Enable connection pooling in Prisma:

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10
```

### Vertical Scaling

**Minimum Requirements**:
- CPU: 2 cores
- RAM: 2GB
- Disk: 20GB SSD

**Recommended for Production**:
- CPU: 4+ cores
- RAM: 8GB
- Disk: 50GB SSD

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
pm2 logs org-os-jobs --lines 50

# Check environment
printenv | grep -E "(NODE_ENV|DATABASE_URL|GITHUB_TOKEN)"

# Test database connection
cd services/jobs
npx prisma db pull
```

### Database Connection Errors

```bash
# Test PostgreSQL connection
psql -h localhost -U orgos_user -d orgos_production

# Check Prisma client
cd services/jobs
rm -rf node_modules/.prisma
npx prisma generate
```

### High Memory Usage

```bash
# Check memory stats
pm2 monit

# Restart services
pm2 restart all

# Reduce instances if needed
pm2 scale org-os-jobs 1
```

### Port Already in Use

```bash
# Find process using port
lsof -i :4000
# or
netstat -tulpn | grep 4000

# Kill process
kill -9 <PID>
```

---

## Security Checklist

- [ ] Use strong passwords for database
- [ ] Rotate GITHUB_TOKEN regularly
- [ ] Enable firewall rules (only expose 80/443/3001/4000)
- [ ] Use HTTPS with SSL certificates (Let's Encrypt recommended)
- [ ] Set up fail2ban for SSH protection
- [ ] Regular security updates: `apt update && apt upgrade`
- [ ] Backup database daily
- [ ] Monitor logs for suspicious activity
- [ ] Use environment variables, never hardcode credentials

---

## Backup Strategy

### Database Backup

```bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgres"
mkdir -p $BACKUP_DIR

pg_dump -h localhost -U orgos_user orgos_production > "$BACKUP_DIR/backup_$DATE.sql"

# Keep only last 7 days
find $BACKUP_DIR -type f -mtime +7 -delete
```

Add to crontab:
```bash
0 2 * * * /path/to/backup.sh
```

---

**Deployment Support**: Create an issue at https://github.com/Ai-Whisperers/Company-Information/issues

**Status Page**: http://your-domain.com:3001/health
