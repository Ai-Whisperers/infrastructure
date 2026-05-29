# AI-Whisperers Org OS - Comprehensive Testing Plan

## Executive Summary

This document outlines the comprehensive testing strategy for the AI-Whisperers Organizational Operating System (Org OS) based on the Product Requirements Document. The plan covers unit testing, integration testing, end-to-end testing, and performance testing for all critical components.

## Test Strategy Overview

### Testing Objectives
- Ensure 80%+ code coverage for critical business logic
- Validate all external API integrations
- Verify data integrity across synchronization operations
- Confirm performance meets defined SLOs
- Validate security and authentication mechanisms
- Ensure documentation compliance features work correctly

### Testing Scope
- **In Scope**: All MVP features, core APIs, critical workflows, external integrations
- **Out of Scope**: Future roadmap items, experimental features, third-party service internals

### Testing Levels
1. **Unit Tests** - Individual component/function testing
2. **Integration Tests** - Module and API interaction testing
3. **End-to-End Tests** - Complete user workflow testing
4. **Performance Tests** - Load and response time testing
5. **Security Tests** - Authentication and authorization validation

## Test Environment Requirements

### Development Environment
```yaml
Database: SQLite (in-memory for tests)
Node Version: 18.x or higher
Package Manager: npm 9.x
Test Framework: Jest
Test Runner: Jest with coverage reporting
Mocking: Jest mocks for external APIs
```

### CI/CD Environment
```yaml
Platform: GitHub Actions
Database: PostgreSQL 14+ (test instance)
Redis: Redis 6+ (test instance)
Coverage Tool: Jest Coverage + Codecov
Test Reporting: GitHub Actions test summaries
```

## 1. Unit Testing Plan

### 1.1 Frontend Components (Dashboard)

#### RepoCard Component Tests
**File**: `apps/dashboard/app/components/RepoCard.test.tsx`
```typescript
describe('RepoCard Component', () => {
  // Test health score display (0-100)
  // Test color coding based on health ranges
  // Test repository name and URL rendering
  // Test last scan timestamp display
  // Test loading state
  // Test error state
  // Test click interactions
});
```

#### StatsCard Component Tests
**File**: `apps/dashboard/app/components/StatsCard.test.tsx`
```typescript
describe('StatsCard Component', () => {
  // Test metric value display
  // Test trend indicator (up/down/neutral)
  // Test percentage change calculation
  // Test title and description rendering
  // Test responsive layout
});
```

#### HealthIndicator Component Tests
**File**: `apps/dashboard/app/components/HealthIndicator.test.tsx`
```typescript
describe('HealthIndicator Component', () => {
  // Test status colors (healthy/warning/critical)
  // Test tooltip information
  // Test accessibility attributes
  // Test animation states
});
```

### 1.2 Backend Services (Jobs Service)

#### GitHubService Tests
**File**: `services/jobs/src/integrations/github.service.spec.ts`
```typescript
describe('GitHubService', () => {
  describe('getRepositories', () => {
    // Test successful repository fetch
    // Test pagination handling
    // Test rate limit handling
    // Test error responses
    // Test data transformation
  });

  describe('getRepositoryHealth', () => {
    // Test health metrics calculation
    // Test branch protection checks
    // Test PR/Issue statistics
    // Test contributor activity metrics
  });

  describe('createWorkItemLink', () => {
    // Test PR comment creation
    // Test issue comment creation
    // Test link format validation
  });
});
```

#### AzureDevOpsService Tests
**File**: `services/jobs/src/integrations/azure-devops.service.spec.ts`
```typescript
describe('AzureDevOpsService', () => {
  describe('getWorkItem', () => {
    // Test work item retrieval
    // Test authentication
    // Test error handling
    // Test field mapping
  });

  describe('updateWorkItem', () => {
    // Test work item updates
    // Test field validation
    // Test optimistic locking
    // Test batch operations
  });

  describe('createLink', () => {
    // Test link creation
    // Test duplicate detection
    // Test link type validation
  });
});
```

#### GitHubHealthScanner Tests
**File**: `services/jobs/src/scanners/github-health.scanner.spec.ts`
```typescript
describe('GitHubHealthScanner', () => {
  describe('scanRepository', () => {
    // Test health score calculation algorithm
    // Test metric collection
    // Test database persistence
    // Test error recovery
  });

  describe('calculateHealthScore', () => {
    // Test score formula
    // Test weight distribution
    // Test edge cases (0% and 100%)
    // Test missing metrics handling
  });

  describe('scheduledScan', () => {
    // Test cron scheduling
    // Test batch processing
    // Test concurrent scan limits
    // Test failure isolation
  });
});
```

#### OrgPulseReporter Tests
**File**: `services/jobs/src/reporters/org-pulse.reporter.spec.ts`
```typescript
describe('OrgPulseReporter', () => {
  describe('generateWeeklyReport', () => {
    // Test data aggregation
    // Test markdown generation
    // Test HTML generation
    // Test file system operations
  });

  describe('calculateTrends', () => {
    // Test week-over-week calculations
    // Test trend identification
    // Test statistical analysis
  });

  describe('distributeReport', () => {
    // Test Slack notification
    // Test email distribution
    // Test report archival
  });
});
```

#### ADOGitHubLinker Tests
**File**: `services/jobs/src/sync/ado-github-linker.service.spec.ts`
```typescript
describe('ADOGitHubLinker', () => {
  describe('extractWorkItemIds', () => {
    // Test pattern matching (#123, WI123, AB#123)
    // Test multiple IDs in single text
    // Test edge cases and invalid formats
  });

  describe('syncPullRequest', () => {
    // Test PR to work item linking
    // Test bidirectional updates
    // Test conflict resolution
    // Test retry logic
  });

  describe('detectDrift', () => {
    // Test drift detection algorithm
    // Test threshold validation
    // Test repair mode activation
  });
});
```

### 1.3 Database Layer Tests

#### Prisma Service Tests
**File**: `services/jobs/src/db/prisma.service.spec.ts`
```typescript
describe('PrismaService', () => {
  // Test connection lifecycle
  // Test transaction handling
  // Test error recovery
  // Test connection pooling
});
```

#### Repository Model Tests
**File**: `services/jobs/src/models/repository.model.spec.ts`
```typescript
describe('Repository Model', () => {
  // Test CRUD operations
  // Test unique constraints
  // Test data validation
  // Test relationships
});
```

## 2. Integration Testing Plan

### 2.1 API Endpoint Tests

#### Dashboard API Tests
**File**: `apps/dashboard/api/dashboard.integration.spec.ts`
```typescript
describe('Dashboard API Integration', () => {
  describe('GET /api/repos', () => {
    // Test authentication required
    // Test response pagination
    // Test sorting and filtering
    // Test cache headers
  });

  describe('GET /api/reports/:id', () => {
    // Test report retrieval
    // Test authorization checks
    // Test 404 handling
  });

  describe('GET /api/stats', () => {
    // Test aggregation queries
    // Test real-time calculations
    // Test response format
  });
});
```

#### Jobs Service API Tests
**File**: `services/jobs/src/api/jobs.integration.spec.ts`
```typescript
describe('Jobs Service API Integration', () => {
  describe('POST /api/scanners/health/trigger', () => {
    // Test manual scan trigger
    // Test job queue creation
    // Test duplicate prevention
    // Test rate limiting
  });

  describe('POST /api/sync/ado-github/trigger', () => {
    // Test sync job creation
    // Test parameter validation
    // Test auth requirements
  });

  describe('GET /api/reports/org-pulse/:week', () => {
    // Test report retrieval
    // Test week validation
    // Test caching
  });
});
```

### 2.2 External Service Integration Tests

#### GitHub API Integration Tests
**File**: `services/jobs/src/integrations/github.integration.spec.ts`
```typescript
describe('GitHub API Integration', () => {
  // Test with mock GitHub API server
  // Test rate limit handling
  // Test pagination
  // Test error scenarios
  // Test webhook reception
});
```

#### Azure DevOps API Integration Tests
**File**: `services/jobs/src/integrations/azure-devops.integration.spec.ts`
```typescript
describe('Azure DevOps API Integration', () => {
  // Test with mock ADO server
  // Test authentication flow
  // Test work item operations
  // Test batch operations
});
```

### 2.3 Database Integration Tests

#### Migration Tests
**File**: `services/jobs/prisma/migrations.integration.spec.ts`
```typescript
describe('Database Migrations', () => {
  // Test forward migration
  // Test rollback scenarios
  // Test data integrity
  // Test schema validation
});
```

#### Transaction Tests
**File**: `services/jobs/src/db/transactions.integration.spec.ts`
```typescript
describe('Database Transactions', () => {
  // Test ACID compliance
  // Test rollback on error
  // Test deadlock handling
  // Test connection pool behavior
});
```

## 3. End-to-End Testing Plan

### 3.1 Critical User Workflows

#### Weekly Org Pulse Generation
**File**: `e2e/workflows/org-pulse.e2e.spec.ts`
```typescript
describe('Weekly Org Pulse E2E', () => {
  // Test scheduled trigger
  // Test data collection from all repos
  // Test report generation
  // Test Slack notification
  // Test dashboard update
});
```

#### Repository Health Scan
**File**: `e2e/workflows/health-scan.e2e.spec.ts`
```typescript
describe('Repository Health Scan E2E', () => {
  // Test manual scan trigger
  // Test GitHub API data fetch
  // Test score calculation
  // Test database update
  // Test dashboard refresh
});
```

#### ADO-GitHub Synchronization
**File**: `e2e/workflows/ado-sync.e2e.spec.ts`
```typescript
describe('ADO-GitHub Sync E2E', () => {
  // Test PR creation with work item ID
  // Test automatic link creation
  // Test bidirectional update
  // Test conflict resolution
  // Test notification
});
```

#### Documentation Gate
**File**: `e2e/workflows/docs-gate.e2e.spec.ts`
```typescript
describe('Documentation Gate E2E', () => {
  // Test PR creation trigger
  // Test documentation check
  // Test status update
  // Test auto-generation on label
  // Test merge blocking
});
```

### 3.2 Authentication Flow Tests

#### GitHub OAuth Flow
**File**: `e2e/auth/github-oauth.e2e.spec.ts`
```typescript
describe('GitHub OAuth E2E', () => {
  // Test login redirect
  // Test callback handling
  // Test session creation
  // Test token refresh
  // Test logout
});
```

## 4. Performance Testing Plan

### 4.1 Load Testing Scenarios

#### API Load Tests
```yaml
Tool: k6 or Artillery
Scenarios:
  - Concurrent Users: 100
  - Request Rate: 1000 req/min
  - Duration: 30 minutes

Endpoints:
  - GET /api/repos (60% traffic)
  - GET /api/stats (20% traffic)
  - GET /api/reports/:id (20% traffic)

Success Criteria:
  - P95 Response Time: <500ms
  - Error Rate: <1%
  - Throughput: >1000 req/min
```

#### Background Job Performance
```yaml
Scenarios:
  - Concurrent repo scans: 10
  - Queue depth: 1000 jobs
  - Processing time target: <30s per repo

Metrics:
  - Job completion rate
  - Queue latency
  - Memory usage
  - CPU utilization
```

### 4.2 Database Performance Tests

#### Query Performance
```sql
-- Test complex aggregation queries
-- Test concurrent write operations
-- Test index effectiveness
-- Test connection pool limits
```

### 4.3 Frontend Performance Tests

#### Page Load Tests
```yaml
Metrics:
  - First Contentful Paint: <1.5s
  - Time to Interactive: <3s
  - Lighthouse Score: >85

Pages:
  - Dashboard homepage
  - Repository details
  - Reports view
```

## 5. Security Testing Plan

### 5.1 Authentication Tests
- Test invalid tokens
- Test expired sessions
- Test role-based access
- Test CSRF protection

### 5.2 Authorization Tests
- Test resource access control
- Test API rate limiting
- Test data isolation
- Test privilege escalation

### 5.3 Input Validation Tests
- Test SQL injection prevention
- Test XSS protection
- Test command injection prevention
- Test path traversal prevention

### 5.4 Data Security Tests
- Test encryption at rest
- Test encryption in transit
- Test sensitive data masking
- Test audit logging

## 6. Test Data Management

### 6.1 Test Data Sets

#### Repository Test Data
```json
{
  "healthy_repo": { "health_score": 95, "issues": 2, "prs": 5 },
  "warning_repo": { "health_score": 65, "issues": 15, "prs": 8 },
  "critical_repo": { "health_score": 35, "issues": 50, "prs": 20 }
}
```

#### Work Item Test Data
```json
{
  "bug": { "type": "Bug", "state": "Active", "priority": 1 },
  "feature": { "type": "Feature", "state": "New", "priority": 2 },
  "task": { "type": "Task", "state": "Closed", "priority": 3 }
}
```

### 6.2 Mock External Services

#### GitHub API Mock
```javascript
// Mock responses for:
// - Repository list
// - Repository details
// - Pull requests
// - Issues
// - Contributors
```

#### Azure DevOps API Mock
```javascript
// Mock responses for:
// - Work items
// - Work item updates
// - Links
// - Projects
```

## 7. Test Automation & CI/CD

### 7.1 CI Pipeline Configuration

```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm run test:unit
      - run: npm run coverage

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
      redis:
        image: redis:6
    steps:
      - run: npm run test:integration

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - run: npm run test:e2e
```

### 7.2 Test Reporting

#### Coverage Requirements
- Overall: 80% minimum
- Critical paths: 95% minimum
- New code: 90% minimum

#### Test Reports
- Jest HTML reporter
- Coverage reports to Codecov
- Test results in PR comments
- Failed test notifications to Slack

## 8. Test Schedule & Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Set up test infrastructure
- [ ] Configure Jest for both apps
- [ ] Create test database setup
- [ ] Implement mock services

### Phase 2: Unit Tests (Week 3-4)
- [ ] Complete service unit tests
- [ ] Complete component unit tests
- [ ] Achieve 70% coverage

### Phase 3: Integration Tests (Week 5-6)
- [ ] API endpoint tests
- [ ] External service tests
- [ ] Database integration tests

### Phase 4: E2E Tests (Week 7-8)
- [ ] Critical workflow tests
- [ ] Authentication flow tests
- [ ] Performance baseline tests

### Phase 5: Performance & Security (Week 9-10)
- [ ] Load testing
- [ ] Security scanning
- [ ] Penetration testing

## 9. Risk Mitigation

### Testing Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| External API rate limits | High | Use mocks, implement caching |
| Test data drift | Medium | Automated test data generation |
| Flaky tests | Medium | Retry logic, better assertions |
| Long test runtime | Low | Parallel execution, test splitting |

## 10. Success Criteria

### Quality Gates
- All tests passing in CI
- Code coverage >80%
- No critical security vulnerabilities
- Performance SLOs met
- Zero P1 bugs in production

### Deliverables
- Automated test suite
- Test documentation
- Coverage reports
- Performance benchmarks
- Security audit report

## Appendix A: Testing Tools & Libraries

### Required Dependencies
```json
{
  "devDependencies": {
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^6.0.0",
    "@types/jest": "^29.0.0",
    "jest": "^29.0.0",
    "jest-environment-jsdom": "^29.0.0",
    "supertest": "^6.3.0",
    "nock": "^13.0.0",
    "faker": "^6.0.0",
    "@faker-js/faker": "^8.0.0"
  }
}
```

### Testing Commands
```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test suite
npm run test:unit
npm run test:integration
npm run test:e2e

# Watch mode
npm run test:watch

# Generate coverage report
npm run coverage:report
```

## Appendix B: Test Case Template

```typescript
describe('[Component/Service Name]', () => {
  let sut: SystemUnderTest;

  beforeEach(() => {
    // Setup
  });

  afterEach(() => {
    // Cleanup
  });

  describe('[Method/Feature Name]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      // Act
      // Assert
    });

    it('should handle [error case]', () => {
      // Test error scenarios
    });
  });
});
```

---

*Testing Plan Version: 1.0.0*
*Last Updated: September 2025*
*Owner: QA Team*
*Review Cycle: Sprint Planning*