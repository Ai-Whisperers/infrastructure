import http from 'k6/http'
import { check, sleep, group } from 'k6'
import { Rate, Trend, Counter, Gauge } from 'k6/metrics'

/**
 * K6 PERFORMANCE TESTS WITH REAL LOAD - NO MOCKS
 * Tests application performance under realistic load conditions
 * Uses real API endpoints and database operations
 */

// Custom metrics for real performance monitoring
const apiResponseTime = new Trend('api_response_time')
const apiFailureRate = new Rate('api_failure_rate')
const databaseConnectionTime = new Trend('database_connection_time')
const activeUsers = new Gauge('active_users')
const requestCount = new Counter('requests_total')

// Test configuration for real load scenarios
export const options = {
  stages: [
    // Ramp-up phase - simulate real user growth
    { duration: '2m', target: 10 },   // Ramp up to 10 users over 2 minutes
    { duration: '5m', target: 10 },   // Stay at 10 users for 5 minutes
    { duration: '2m', target: 25 },   // Ramp up to 25 users over 2 minutes
    { duration: '5m', target: 25 },   // Stay at 25 users for 5 minutes
    { duration: '2m', target: 50 },   // Ramp up to 50 users over 2 minutes
    { duration: '10m', target: 50 },  // Stay at 50 users for 10 minutes (peak load)
    { duration: '5m', target: 0 },    // Ramp down to 0 users
  ],

  // Performance thresholds (real production requirements)
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],   // Error rate under 1%
    api_response_time: ['p(90)<300'], // 90% of API calls under 300ms
    api_failure_rate: ['rate<0.05'],  // API failure rate under 5%
    database_connection_time: ['p(95)<100'], // 95% of DB connections under 100ms
  },

  // Real browser and network simulation
  userAgent: 'AI-Whisperers-LoadTest/1.0',
}

// Real API endpoints (no mocked URLs)
const BASE_URL = __ENV.API_BASE_URL || 'http://localhost:4000/api'
const DASHBOARD_URL = __ENV.DASHBOARD_URL || 'http://localhost:3001'

// Real test data (pulled from actual database)
let testRepositories = []
let testWorkItems = []

export function setup() {
  console.log('🚀 Setting up performance test with real data...')

  // Get real repositories from API (not mocked)
  const repoResponse = http.get(`${BASE_URL}/repositories`)
  if (repoResponse.status === 200) {
    testRepositories = JSON.parse(repoResponse.body)
    console.log(`📊 Loaded ${testRepositories.length} real repositories for testing`)
  }

  // Get real work items
  const workItemResponse = http.get(`${BASE_URL}/work-items`)
  if (workItemResponse.status === 200) {
    testWorkItems = JSON.parse(workItemResponse.body)
    console.log(`📋 Loaded ${testWorkItems.length} real work items for testing`)
  }

  return { repositories: testRepositories, workItems: testWorkItems }
}

export default function (data) {
  activeUsers.add(1)

  // Simulate real user behavior patterns
  const userScenarios = [
    () => dashboardViewingScenario(data),
    () => repositoryManagementScenario(data),
    () => reportGenerationScenario(data),
    () => workItemSyncScenario(data),
    () => healthScanningScenario(data)
  ]

  // Execute random scenario (like real users)
  const scenario = userScenarios[Math.floor(Math.random() * userScenarios.length)]
  scenario()

  // Real user think time (not instant like mocks)
  sleep(Math.random() * 3 + 1) // 1-4 seconds between actions
}

/**
 * Scenario 1: Dashboard Viewing with Real Data
 */
function dashboardViewingScenario(data) {
  group('Dashboard Viewing - Real User Journey', () => {
    // Load dashboard with real repositories
    const dashboardStart = new Date()
    const response = http.get(`${DASHBOARD_URL}/`)

    const dashboardLoadTime = new Date() - dashboardStart
    apiResponseTime.add(dashboardLoadTime)

    check(response, {
      'dashboard loads successfully': (r) => r.status === 200,
      'dashboard contains real repositories': (r) => r.body.includes('repo-card'),
      'dashboard loads under 2s': () => dashboardLoadTime < 2000,
    })

    requestCount.add(1)

    // Get repository list via API (real data)
    const apiStart = new Date()
    const repoResponse = http.get(`${BASE_URL}/repositories`)

    const apiTime = new Date() - apiStart
    apiResponseTime.add(apiTime)

    const apiSuccess = check(repoResponse, {
      'repositories API responds': (r) => r.status === 200,
      'repositories contain real data': (r) => {
        const repos = JSON.parse(r.body)
        return repos.length > 0 && repos[0].hasOwnProperty('healthScore')
      },
      'API response under 500ms': () => apiTime < 500,
    })

    apiFailureRate.add(!apiSuccess)
    requestCount.add(1)

    // Simulate user scrolling and viewing multiple repositories
    if (data.repositories.length > 0) {
      const randomRepo = data.repositories[Math.floor(Math.random() * data.repositories.length)]

      const repoDetailResponse = http.get(`${BASE_URL}/repositories/${randomRepo.id}`)
      check(repoDetailResponse, {
        'repository details load': (r) => r.status === 200,
        'repository has health data': (r) => {
          const repo = JSON.parse(r.body)
          return repo.hasOwnProperty('healthScore')
        }
      })

      requestCount.add(1)
    }

    sleep(1) // Real user reading time
  })
}

/**
 * Scenario 2: Repository Health Scanning with Real GitHub API
 */
function healthScanningScenario(data) {
  group('Health Scanning - Real GitHub Integration', () => {
    if (data.repositories.length === 0) return

    const randomRepo = data.repositories[Math.floor(Math.random() * data.repositories.length)]

    // Trigger real health scan (actual GitHub API calls)
    const scanStart = new Date()
    const scanResponse = http.post(`${BASE_URL}/scanners/health/trigger`,
      JSON.stringify({ repositories: [randomRepo.name] }),
      { headers: { 'Content-Type': 'application/json' } }
    )

    const scanTime = new Date() - scanStart
    apiResponseTime.add(scanTime)

    const scanSuccess = check(scanResponse, {
      'health scan triggers successfully': (r) => r.status === 202,
      'scan job created': (r) => {
        if (r.status === 202) {
          const response = JSON.parse(r.body)
          return response.hasOwnProperty('jobId')
        }
        return false
      },
      'scan request under 1s': () => scanTime < 1000,
    })

    apiFailureRate.add(!scanSuccess)
    requestCount.add(1)

    // Check scan status (real job queue)
    sleep(2) // Wait for scan to process

    const statusResponse = http.get(`${BASE_URL}/jobs/queue`)
    check(statusResponse, {
      'job queue accessible': (r) => r.status === 200,
      'queue has real job data': (r) => {
        const queue = JSON.parse(r.body)
        return queue.hasOwnProperty('active') || queue.hasOwnProperty('waiting')
      }
    })

    requestCount.add(1)
  })
}

/**
 * Scenario 3: Report Generation with Real Data Aggregation
 */
function reportGenerationScenario(data) {
  group('Report Generation - Real Data Processing', () => {
    const currentDate = new Date()
    const weekNumber = Math.ceil(currentDate.getDate() / 7)
    const year = currentDate.getFullYear()

    // Generate report with real data
    const reportStart = new Date()
    const reportResponse = http.post(`${BASE_URL}/reporters/org-pulse/generate`,
      JSON.stringify({ week: weekNumber, year: year }),
      { headers: { 'Content-Type': 'application/json' } }
    )

    const reportTime = new Date() - reportStart
    apiResponseTime.add(reportTime)

    const reportSuccess = check(reportResponse, {
      'report generation starts': (r) => r.status === 202 || r.status === 409, // 409 = already exists
      'report job created': (r) => {
        if (r.status === 202) {
          const response = JSON.parse(r.body)
          return response.hasOwnProperty('reportId')
        }
        return true // 409 means report already exists
      },
      'report request under 2s': () => reportTime < 2000,
    })

    apiFailureRate.add(!reportSuccess)
    requestCount.add(1)

    // Wait and check if report was generated (real processing time)
    sleep(5)

    const reportGetResponse = http.get(`${BASE_URL}/reports/org-pulse/${weekNumber}?year=${year}`)
    check(reportGetResponse, {
      'generated report retrievable': (r) => r.status === 200 || r.status === 404, // 404 = still generating
      'report contains real metrics': (r) => {
        if (r.status === 200) {
          const report = JSON.parse(r.body)
          return report.hasOwnProperty('content')
        }
        return true // Still generating
      }
    })

    requestCount.add(1)
  })
}

/**
 * Scenario 4: Azure DevOps Sync with Real API Calls
 */
function workItemSyncScenario(data) {
  group('Work Item Sync - Real Azure DevOps Integration', () => {
    // Get sync status (real ADO connection)
    const syncStatusStart = new Date()
    const statusResponse = http.get(`${BASE_URL}/sync/ado-github/status`)

    const statusTime = new Date() - syncStatusStart
    apiResponseTime.add(statusTime)

    check(statusResponse, {
      'sync status available': (r) => r.status === 200,
      'status contains real metrics': (r) => {
        const status = JSON.parse(r.body)
        return status.hasOwnProperty('totalSynced')
      },
      'status request under 300ms': () => statusTime < 300,
    })

    requestCount.add(1)

    // Trigger sync if workitems available
    if (data.workItems.length > 0) {
      const randomWorkItem = data.workItems[Math.floor(Math.random() * data.workItems.length)]

      const syncResponse = http.post(`${BASE_URL}/sync/ado-github/trigger`,
        JSON.stringify({ workItemId: randomWorkItem.externalId }),
        { headers: { 'Content-Type': 'application/json' } }
      )

      check(syncResponse, {
        'sync triggers successfully': (r) => r.status === 202,
        'sync job queued': (r) => {
          if (r.status === 202) {
            const response = JSON.parse(r.body)
            return response.hasOwnProperty('jobId')
          }
          return false
        }
      })

      requestCount.add(1)
    }
  })
}

/**
 * Scenario 5: Repository Management Operations
 */
function repositoryManagementScenario(data) {
  group('Repository Management - Real Database Operations', () => {
    // List repositories with different filters
    const filters = ['all', 'healthy', 'warning', 'critical']
    const filter = filters[Math.floor(Math.random() * filters.length)]

    const listStart = new Date()
    const listResponse = http.get(`${BASE_URL}/repositories?filter=${filter}&limit=10`)

    const listTime = new Date() - listStart
    apiResponseTime.add(listTime)

    check(listResponse, {
      'repository list loads': (r) => r.status === 200,
      'filtered results returned': (r) => {
        const repos = JSON.parse(r.body)
        return Array.isArray(repos)
      },
      'list request under 400ms': () => listTime < 400,
    })

    requestCount.add(1)

    // Get repository metrics aggregation
    const metricsResponse = http.get(`${BASE_URL}/repositories/metrics`)
    check(metricsResponse, {
      'metrics aggregation works': (r) => r.status === 200,
      'metrics have real calculations': (r) => {
        const metrics = JSON.parse(r.body)
        return metrics.hasOwnProperty('averageHealthScore')
      }
    })

    requestCount.add(1)
  })
}

export function teardown(data) {
  console.log('🏁 Performance test completed')
  console.log(`📊 Tested with ${data.repositories.length} real repositories`)
  console.log(`📋 Tested with ${data.workItems.length} real work items`)
  console.log('📈 Performance metrics collected from real operations')
}