# AI-Whisperers Org OS - Comprehensive Functionalities Report

## Executive Summary

**Project Name:** AI-Whisperers Organizational Operating System (Company-Information)
**Version:** 0.1.0 (MVP)
**Architecture:** Monorepo with microservices architecture
**Technology Stack:** Next.js, NestJS, PostgreSQL, Redis, TypeScript
**Status:** Active Development - MVP Phase

## Core Purpose

The AI-Whisperers Org OS is a centralized control plane designed to manage and monitor the organization's entire repository ecosystem. It provides automated health monitoring, cross-platform synchronization, and documentation governance for all AI-Whisperers projects.

## System Architecture

### Components Overview

```
┌─────────────────────────────────┐
│    Next.js Dashboard (3000)     │ ← User Interface Layer
└────────────┬────────────────────┘
             │ REST API
┌────────────▼────────────────────┐
│   NestJS Jobs Service (4000)    │ ← Business Logic Layer
└────────────┬────────────────────┘
             │
    ┌────────┴────────┐
    ▼                 ▼
┌─────────┐     ┌──────────┐
│ Postgres│     │  Redis   │ ← Data Layer
└─────────┘     └──────────┘
```

### Technology Stack Details

#### Frontend (Dashboard)
- **Framework:** Next.js 14.1.0
- **Authentication:** NextAuth v5 with GitHub OAuth
- **UI Libraries:**
  - TailwindCSS for styling
  - Recharts for data visualization
  - Lucide React for icons
  - SWR for data fetching
- **Language:** TypeScript

#### Backend (Jobs Service)
- **Framework:** NestJS 10.3.0
- **ORM:** Prisma 5.8.1
- **Queue System:** Bull with Redis
- **API Documentation:** Swagger
- **Scheduled Tasks:** @nestjs/schedule
- **External Integrations:**
  - Octokit for GitHub API
  - Azure DevOps REST API
  - Slack Webhooks

#### Infrastructure
- **Database:** PostgreSQL
- **Cache/Queue:** Redis
- **Deployment Targets:**
  - Dashboard: Vercel
  - Jobs Service: Docker containers

## Major Functionalities

### 1. Organization Health Monitoring (Org Pulse)

**Purpose:** Automated weekly health assessment of all repositories

**Features:**
- Repository activity metrics tracking
- Contributor activity analysis
- Stale PR detection
- Branch protection validation
- Health score calculation (0-100 scale)
- Historical trend analysis

**Technical Implementation:**
- Located in: `services/jobs/src/reporters/org-pulse.reporter.ts`
- Schedule: Weekly (Mondays 9 AM)
- Output formats: Markdown, HTML
- Storage: PostgreSQL with historical archiving

**Metrics Tracked:**
- Commit frequency
- PR turnaround time
- Issue resolution rate
- Documentation coverage
- Test coverage trends
- Security vulnerability status

### 2. Azure DevOps ↔ GitHub Synchronization

**Purpose:** Bidirectional work item linking between Azure DevOps and GitHub

**Features:**
- Automatic work item ID detection in commits/PRs
- Cross-platform link creation
- Drift detection with <10 minute SLO
- Automatic repair mode for broken links
- Conflict resolution strategies

**Technical Implementation:**
- Located in: `services/jobs/src/sync/ado-github-linker.service.ts`
- Schedule: Every 6 hours
- Pattern matching: #123, WI123, AB#123 formats
- State synchronization: Real-time webhook support

**Supported Patterns:**
- GitHub Issues → ADO Work Items
- ADO Work Items → GitHub Issues
- PR descriptions → Work Item links
- Commit messages → Work Item associations

### 3. Documentation Gate

**Purpose:** Enforce documentation standards across all repositories

**Features:**
- CI/CD documentation checks
- Template-based document generation
- Label-triggered PR automation
- Policy enforcement engine
- Documentation coverage reporting

**Technical Implementation:**
- Located in: `services/jobs/src/scanners/docs-check.scanner.ts`
- Trigger: On every PR via GitHub Actions
- Templates: Stored in `templates/` directory
- Policies: Configurable per repository

**Required Documentation:**
- README.md with minimum sections
- API documentation for public endpoints
- Architecture documentation for major changes
- Migration guides for breaking changes
- Security documentation for sensitive features

### 4. Repository Health Scanner

**Purpose:** Continuous health monitoring of all organization repositories

**Features:**
- Daily automated scans
- Security vulnerability detection
- Dependency analysis
- License compliance checking
- Code quality metrics

**Technical Implementation:**
- Located in: `services/jobs/src/scanners/github-health.scanner.ts`
- Schedule: Daily at 2 AM
- Integration: GitHub API v4 (GraphQL)
- Alerting: Slack notifications for critical issues

### 5. PowerShell Automation Scripts

**Legacy Tools (Being Migrated):**

#### Azure DevOps Sync (`azure-devops-sync.ps1`)
- Manual synchronization fallback
- Bulk import/export capabilities
- Data migration utilities

#### Dashboard Generator (`dashboard.ps1`)
- Static HTML report generation
- Custom metric calculations
- Email report distribution

#### Dependency Tracker (`dependency-tracker.ps1`)
- Cross-repository dependency mapping
- Version conflict detection
- Update recommendation engine

#### Excalibur Command (`excalibur-command.ps1`)
- Unified CLI for all operations
- Batch processing capabilities
- Emergency response automation

#### File Sync Manager (`file-sync.ps1`, `file-sync-advanced.ps1`)
- Cross-repository file synchronization
- Template distribution
- Configuration propagation

#### Release Coordinator (`release-coordinator.ps1`)
- Multi-repository release orchestration
- Changelog generation
- Version bumping automation

#### Repository Monitor (`repo-monitor-dashboard.ps1`)
- Real-time activity monitoring
- Alert threshold management
- Performance metrics tracking

#### Todo Manager (`manage-todos.ps1`, `todo-manager.ps1`)
- Cross-repository task tracking
- Sprint planning integration
- Burndown chart generation

#### MCP Health Check System (`mcp-health-check.ps1`, `mcp-health-scheduler.ps1`)
- Model Context Protocol validation
- Service connectivity testing
- Automated health reporting

## API Endpoints

### Dashboard API (Port 3000)
- `GET /api/health` - System health check
- `GET /api/repos` - List all repositories with health scores
- `GET /api/reports/:id` - Retrieve specific report
- `GET /api/stats` - Organization-wide statistics
- `POST /api/auth/signin` - GitHub OAuth authentication

### Jobs Service API (Port 4000)
- `GET /api/health` - Service health status
- `POST /api/scanners/health/trigger` - Manual health scan
- `POST /api/scanners/docs/check` - Documentation validation
- `POST /api/sync/ado-github/trigger` - Manual ADO sync
- `GET /api/sync/ado-github/status` - Sync status and metrics
- `POST /api/reporters/org-pulse/generate` - Generate weekly report
- `GET /api/reports/org-pulse/:week` - Retrieve weekly report
- `GET /api/jobs/queue` - View job queue status
- `POST /api/notifications/test` - Test notification channels

## Automation Workflows

### GitHub Actions

#### Documentation Check (`docs-check.yml`)
- Trigger: On PR open/update
- Validates documentation completeness
- Suggests missing documentation
- Auto-generates templates when labeled

#### Scheduled Tasks (`schedule.yml`)
- Weekly Org Pulse generation
- Daily health scans
- Periodic ADO synchronization
- Stale PR notifications

## Data Models

### Core Entities

1. **Repository**
   - ID, name, URL
   - Health score (0-100)
   - Last scan timestamp
   - Configuration overrides

2. **HealthReport**
   - Repository reference
   - Timestamp
   - Metrics JSON
   - Recommendations

3. **WorkItemLink**
   - GitHub issue/PR reference
   - ADO work item ID
   - Link status
   - Last sync timestamp

4. **OrgPulseReport**
   - Week number/year
   - Aggregate metrics
   - Top contributors
   - Trend analysis

## Performance Metrics

### Target SLOs
- Dashboard load time: <1.5s (P95)
- API response time: <500ms (P95)
- Weekly scan completion: <8 minutes
- ADO sync lag: <10 minutes
- Report generation: <15 minutes
- Health scan per repo: <30 seconds

### Current Performance
- Active repositories monitored: 10+
- Daily API calls: ~5,000
- Weekly report size: ~50KB
- Database size: <100MB
- Redis cache hit ratio: >90%

## Security Features

### Authentication & Authorization
- GitHub OAuth 2.0 integration
- JWT-based session management
- Role-based access control (RBAC)
- API key authentication for CI/CD

### Data Protection
- Environment variable encryption
- Secure credential storage
- Rate limiting on all endpoints
- Audit logging for sensitive operations

### Compliance
- GDPR-compliant data handling
- Automated PII detection
- Data retention policies
- Right to deletion support

## Integration Points

### External Services
1. **GitHub**
   - Repository management
   - Issue/PR tracking
   - Actions workflows
   - OAuth provider

2. **Azure DevOps**
   - Work item management
   - Pipeline integration
   - Board synchronization

3. **Slack**
   - Alert notifications
   - Report distribution
   - Interactive commands

4. **Vercel**
   - Dashboard hosting
   - Edge functions
   - Analytics

## Deployment Configuration

### Environment Variables Required
- `GITHUB_TOKEN` - GitHub API access
- `GITHUB_ORG` - Organization name
- `AZURE_DEVOPS_PAT` - ADO personal access token
- `AZURE_DEVOPS_ORG` - ADO organization
- `AZURE_DEVOPS_PROJECT` - ADO project name
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `NEXTAUTH_SECRET` - Session encryption key
- `GITHUB_CLIENT_ID` - OAuth app ID
- `GITHUB_CLIENT_SECRET` - OAuth app secret
- `SLACK_WEBHOOK_URL` - Slack notifications (optional)

### Deployment Commands
```bash
# Development
npm run dev

# Production Build
npm run build

# Production Deployment
npm run deploy:dashboard  # Vercel deployment
npm run deploy:jobs       # Docker deployment

# Database Management
npx prisma migrate deploy
npx prisma generate
```

## Future Roadmap

### Planned Enhancements
1. **AI-Powered Insights**
   - Predictive health scoring
   - Anomaly detection
   - Automated remediation suggestions

2. **Extended Integrations**
   - Jira synchronization
   - GitLab support
   - Confluence documentation sync

3. **Advanced Analytics**
   - Custom dashboards
   - Trend forecasting
   - Team productivity metrics

4. **Governance Features**
   - Policy as code
   - Compliance automation
   - Security scanning integration

## Support & Maintenance

### Monitoring
- Health endpoint monitoring
- Error tracking with Sentry (planned)
- Performance monitoring with DataDog (planned)
- Uptime monitoring via external service

### Backup Strategy
- Daily database backups
- Report archival to S3 (planned)
- Configuration version control
- Disaster recovery procedures

### Documentation
- API documentation via Swagger
- User guides in `/docs`
- Architecture decision records
- Troubleshooting guides

## Conclusion

The AI-Whisperers Org OS represents a comprehensive solution for managing a modern software development organization's repository ecosystem. By combining automated monitoring, cross-platform synchronization, and intelligent reporting, it provides the visibility and control necessary for effective organizational governance.

The system's modular architecture, extensive automation capabilities, and focus on developer experience make it a critical component of the AI-Whisperers technology infrastructure. With ongoing development focused on AI-powered insights and extended integrations, the platform is well-positioned to scale with organizational growth.

---
*Report Generated: September 25, 2025*
*Version: 0.1.0-MVP*
*Classification: Internal Use*