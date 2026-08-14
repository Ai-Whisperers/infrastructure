import { Test, TestingModule } from '@nestjs/testing'
import { INestApplication } from '@nestjs/common'
import * as request from 'supertest'
import { AppModule } from '../../services/jobs/src/app.module'
import { setupTestDatabase, cleanupTestDatabase } from '../setup/test-database'
import { PrismaClient } from '@prisma/client'
import { Octokit } from '@octokit/rest'
import axios from 'axios'

/**
 * INTEGRATION TESTS WITH REAL APIS - NO MOCKS
 * Tests actual API integrations with real external services
 * GitHub Test Organization: ai-whisperers-test
 * Azure DevOps Test Project: TestProject
 */

describe('API Integration Tests - Real External Services', () => {
  let app: INestApplication
  let prisma: PrismaClient
  let githubClient: Octokit
  let testRepositoryId: string

  beforeAll(async () => {
    // Setup real test database and external service clients
    prisma = await setupTestDatabase()

    // Real GitHub client (no mocks)
    githubClient = new Octokit({
      auth: process.env.GITHUB_TOKEN
    })

    // Verify GitHub test organization exists
    try {
      await githubClient.orgs.get({ org: process.env.GITHUB_ORG! })
    } catch (error) {
      throw new Error(`GitHub test organization not accessible: ${process.env.GITHUB_ORG}`)
    }

    // Create NestJS app with real dependencies
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile()

    app = moduleFixture.createNestApplication()

    // Apply same middleware as production
    app.setGlobalPrefix('api')

    await app.init()

    // Get a real test repository
    const repos = await prisma.repository.findMany()
    testRepositoryId = repos[0]?.id
    if (!testRepositoryId) {
      throw new Error('No test repositories found. Run database seeding first.')
    }
  })

  afterAll(async () => {
    await app.close()
    await cleanupTestDatabase()
  })

  describe('Health Check Endpoints - Real Service Status', () => {
    it('should return real application health status', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/health')
        .expect(200)

      expect(response.body).toHaveProperty('status', 'healthy')
      expect(response.body).toHaveProperty('timestamp')
      expect(response.body).toHaveProperty('uptime')
      expect(response.body).toHaveProperty('version')

      // Verify timestamp is recent (within last 5 seconds)
      const timestamp = new Date(response.body.timestamp).getTime()
      const now = Date.now()
      expect(now - timestamp).toBeLessThan(5000)

      // Verify uptime is a positive number
      expect(response.body.uptime).toBeGreaterThan(0)
    })

    it('should verify database connectivity in health check', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/health')
        .expect(200)

      expect(response.body.database).toBe('connected')
    })

    it('should verify external service connectivity', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/health/services')
        .expect(200)

      // Test real GitHub API connectivity
      expect(response.body.github).toBe('connected')

      // Test real Azure DevOps connectivity
      expect(response.body.azureDevOps).toBe('connected')

      // Test Redis connectivity
      expect(response.body.redis).toBe('connected')
    })
  })

  describe('Repository Endpoints - Real Database Operations', () => {
    it('should list repositories from real database', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/repositories')
        .expect(200)

      expect(Array.isArray(response.body)).toBe(true)
      expect(response.body.length).toBeGreaterThan(0)

      const repository = response.body[0]
      expect(repository).toHaveProperty('id')
      expect(repository).toHaveProperty('name')
      expect(repository).toHaveProperty('healthScore')
      expect(repository.healthScore).toBeGreaterThanOrEqual(0)
      expect(repository.healthScore).toBeLessThanOrEqual(100)
    })

    it('should get specific repository with real health history', async () => {
      const response = await request(app.getHttpServer())
        .get(`/api/repositories/${testRepositoryId}`)
        .expect(200)

      expect(response.body).toHaveProperty('id', testRepositoryId)
      expect(response.body).toHaveProperty('name')
      expect(response.body).toHaveProperty('healthChecks')

      // Verify real health check data
      if (response.body.healthChecks.length > 0) {
        const healthCheck = response.body.healthChecks[0]
        expect(healthCheck).toHaveProperty('score')
        expect(healthCheck).toHaveProperty('scannedAt')
        expect(healthCheck).toHaveProperty('metrics')
        expect(new Date(healthCheck.scannedAt)).toBeInstanceOf(Date)
      }
    })

    it('should return 404 for non-existent repository', async () => {
      await request(app.getHttpServer())
        .get('/api/repositories/non-existent-id')
        .expect(404)
    })

    it('should handle pagination correctly', async () => {
      const page1 = await request(app.getHttpServer())
        .get('/api/repositories?page=1&limit=2')
        .expect(200)

      const page2 = await request(app.getHttpServer())
        .get('/api/repositories?page=2&limit=2')
        .expect(200)

      expect(page1.body.length).toBeLessThanOrEqual(2)
      expect(page2.body.length).toBeLessThanOrEqual(2)

      // Ensure no duplicates between pages
      const page1Ids = page1.body.map((r: any) => r.id)
      const page2Ids = page2.body.map((r: any) => r.id)
      const intersection = page1Ids.filter((id: string) => page2Ids.includes(id))
      expect(intersection).toHaveLength(0)
    })
  })

  describe('Health Scanner Endpoints - Real GitHub API Integration', () => {
    it('should trigger health scan with real GitHub API calls', async () => {
      // Get real repository from database
      const repos = await prisma.repository.findMany({ take: 1 })
      const testRepo = repos[0]

      const response = await request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .send({
          repositories: [testRepo.name]
        })
        .expect(202)

      expect(response.body).toHaveProperty('jobId')
      expect(response.body).toHaveProperty('status', 'queued')

      // Wait for real scan to complete (may take several seconds)
      await new Promise(resolve => setTimeout(resolve, 5000))

      // Verify scan results were saved to database
      const updatedRepo = await prisma.repository.findUnique({
        where: { id: testRepo.id },
        include: {
          healthChecks: {
            orderBy: { scannedAt: 'desc' },
            take: 1
          }
        }
      })

      expect(updatedRepo?.healthChecks[0]).toBeDefined()
      const latestCheck = updatedRepo!.healthChecks[0]
      expect(new Date(latestCheck.scannedAt).getTime()).toBeGreaterThan(Date.now() - 60000)
    })

    it('should respect GitHub API rate limits', async () => {
      const repos = await prisma.repository.findMany()

      // Trigger multiple scans to test rate limiting
      const responses = await Promise.allSettled(
        repos.slice(0, 5).map(repo =>
          request(app.getHttpServer())
            .post('/api/scanners/health/trigger')
            .send({ repositories: [repo.name] })
        )
      )

      // Some requests should be rate limited or queued
      const rateLimitedCount = responses.filter(
        result => result.status === 'fulfilled' &&
        (result.value.status === 429 || result.value.body.status === 'rate_limited')
      ).length

      expect(rateLimitedCount).toBeGreaterThan(0)
    })

    it('should handle repository not found in GitHub', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .send({
          repositories: ['non-existent-repository']
        })
        .expect(400)

      expect(response.body).toHaveProperty('error')
      expect(response.body.error).toContain('not found')
    })
  })

  describe('Azure DevOps Sync Endpoints - Real ADO Integration', () => {
    it('should sync work items with real Azure DevOps API', async () => {
      // Create a real work item first
      const workItemData = {
        title: 'Test Integration Work Item',
        description: 'Created by integration test',
        type: 'Task',
        state: 'New'
      }

      // Use real Azure DevOps API to create work item
      const adoResponse = await axios.post(
        `https://dev.azure.com/${process.env.AZURE_DEVOPS_ORG}/${process.env.AZURE_DEVOPS_PROJECT}/_apis/wit/workitems/$Task?api-version=6.0`,
        [
          { op: 'add', path: '/fields/System.Title', value: workItemData.title },
          { op: 'add', path: '/fields/System.Description', value: workItemData.description }
        ],
        {
          headers: {
            'Authorization': `Basic ${Buffer.from(`:${process.env.AZURE_DEVOPS_PAT}`).toString('base64')}`,
            'Content-Type': 'application/json-patch+json'
          }
        }
      )

      const workItemId = adoResponse.data.id.toString()

      // Trigger sync via API
      const response = await request(app.getHttpServer())
        .post('/api/sync/ado-github/trigger')
        .send({
          workItemId: workItemId,
          repositoryName: 'Comment-Analyzer'
        })
        .expect(202)

      expect(response.body).toHaveProperty('jobId')

      // Wait for sync to complete
      await new Promise(resolve => setTimeout(resolve, 3000))

      // Verify work item was synced to database
      const syncedWorkItem = await prisma.workItem.findFirst({
        where: { externalId: workItemId }
      })

      expect(syncedWorkItem).toBeDefined()
      expect(syncedWorkItem?.title).toBe(workItemData.title)

      // Cleanup - delete test work item
      await axios.delete(
        `https://dev.azure.com/${process.env.AZURE_DEVOPS_ORG}/${process.env.AZURE_DEVOPS_PROJECT}/_apis/wit/workitems/${workItemId}?api-version=6.0`,
        {
          headers: {
            'Authorization': `Basic ${Buffer.from(`:${process.env.AZURE_DEVOPS_PAT}`).toString('base64')}`
          }
        }
      )
    })

    it('should get sync status with real metrics', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/sync/ado-github/status')
        .expect(200)

      expect(response.body).toHaveProperty('lastSync')
      expect(response.body).toHaveProperty('totalSynced')
      expect(response.body).toHaveProperty('pendingSync')
      expect(response.body).toHaveProperty('failedSync')

      // Verify realistic values
      expect(response.body.totalSynced).toBeGreaterThanOrEqual(0)
      expect(response.body.pendingSync).toBeGreaterThanOrEqual(0)
      expect(response.body.failedSync).toBeGreaterThanOrEqual(0)
    })
  })

  describe('Reports Endpoints - Real Data Generation', () => {
    it('should generate org pulse report with real data', async () => {
      const currentDate = new Date()
      const weekNumber = Math.ceil(currentDate.getDate() / 7)
      const year = currentDate.getFullYear()

      const response = await request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .send({
          week: weekNumber,
          year: year
        })
        .expect(202)

      expect(response.body).toHaveProperty('reportId')

      // Wait for report generation
      await new Promise(resolve => setTimeout(resolve, 5000))

      // Verify report was generated with real data
      const report = await prisma.report.findFirst({
        where: {
          week: weekNumber,
          year: year,
          type: 'ORG_PULSE'
        }
      })

      expect(report).toBeDefined()
      expect(report?.content).toBeDefined()

      const content = JSON.parse(report!.content)
      expect(content).toHaveProperty('totalRepositories')
      expect(content).toHaveProperty('averageHealthScore')
      expect(content.totalRepositories).toBeGreaterThan(0)
    })

    it('should retrieve existing report', async () => {
      // Get an existing report from database
      const existingReport = await prisma.report.findFirst({
        where: { type: 'ORG_PULSE' }
      })

      if (existingReport) {
        const response = await request(app.getHttpServer())
          .get(`/api/reports/org-pulse/${existingReport.week}?year=${existingReport.year}`)
          .expect(200)

        expect(response.body).toHaveProperty('id', existingReport.id)
        expect(response.body).toHaveProperty('week', existingReport.week)
        expect(response.body).toHaveProperty('content')
      }
    })

    it('should prevent duplicate report generation', async () => {
      const currentDate = new Date()
      const weekNumber = Math.ceil(currentDate.getDate() / 7) + 1 // Next week
      const year = currentDate.getFullYear()

      // Generate first report
      await request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .send({ week: weekNumber, year })
        .expect(202)

      // Attempt duplicate generation
      await request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .send({ week: weekNumber, year })
        .expect(409)
    })
  })

  describe('Documentation Scanner - Real File Analysis', () => {
    it('should validate documentation with real repository files', async () => {
      // Use real repository with actual files
      const repos = await prisma.repository.findMany({ take: 1 })
      const testRepo = repos[0]

      const response = await request(app.getHttpServer())
        .post('/api/scanners/docs/check')
        .send({
          repository: testRepo.name,
          pullRequestNumber: 1,
          files: ['README.md', 'package.json', 'src/index.ts']
        })
        .expect(200)

      expect(response.body).toHaveProperty('passed')
      expect(response.body).toHaveProperty('violations')
      expect(response.body).toHaveProperty('suggestions')

      // Verify real file analysis
      expect(Array.isArray(response.body.violations)).toBe(true)
      expect(Array.isArray(response.body.suggestions)).toBe(true)
    })
  })

  describe('Queue Management - Real Job Processing', () => {
    it('should show real job queue status', async () => {
      const response = await request(app.getHttpServer())
        .get('/api/jobs/queue')
        .expect(200)

      expect(response.body).toHaveProperty('waiting')
      expect(response.body).toHaveProperty('active')
      expect(response.body).toHaveProperty('completed')
      expect(response.body).toHaveProperty('failed')

      // Verify realistic queue metrics
      expect(typeof response.body.waiting).toBe('number')
      expect(typeof response.body.active).toBe('number')
      expect(typeof response.body.completed).toBe('number')
      expect(typeof response.body.failed).toBe('number')
    })
  })

  describe('Notification System - Real Slack Integration', () => {
    it('should send test notification to real Slack webhook', async () => {
      const response = await request(app.getHttpServer())
        .post('/api/notifications/test')
        .send({
          channel: 'slack',
          message: 'Integration test notification'
        })
        .expect(200)

      expect(response.body).toHaveProperty('sent', true)
      expect(response.body).toHaveProperty('channel', 'slack')
      expect(response.body).toHaveProperty('timestamp')
    })

    it('should handle webhook failures gracefully', async () => {
      // Use invalid webhook URL to test error handling
      const response = await request(app.getHttpServer())
        .post('/api/notifications/test')
        .send({
          channel: 'invalid-webhook',
          message: 'Test message'
        })
        .expect(400)

      expect(response.body).toHaveProperty('error')
    })
  })

  describe('Performance Tests - Real Load Conditions', () => {
    it('should handle concurrent repository requests', async () => {
      const concurrentRequests = Array(10).fill(null).map(() =>
        request(app.getHttpServer()).get('/api/repositories')
      )

      const startTime = Date.now()
      const responses = await Promise.all(concurrentRequests)
      const endTime = Date.now()

      // All requests should succeed
      responses.forEach(response => {
        expect(response.status).toBe(200)
      })

      // Should complete within reasonable time
      const totalTime = endTime - startTime
      expect(totalTime).toBeLessThan(5000) // 5 seconds for 10 concurrent requests
    })

    it('should maintain database connection pool under load', async () => {
      // Generate load on database
      const dbRequests = Array(20).fill(null).map(() =>
        prisma.repository.count()
      )

      const results = await Promise.all(dbRequests)

      // All requests should return same count
      results.forEach(count => {
        expect(count).toBe(results[0])
      })
    })
  })

  describe('Error Handling - Real Error Scenarios', () => {
    it('should handle GitHub API failures gracefully', async () => {
      // Use invalid GitHub token temporarily
      const originalToken = process.env.GITHUB_TOKEN
      process.env.GITHUB_TOKEN = 'invalid-token'

      const response = await request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .send({ repositories: ['test-repo'] })
        .expect(401)

      expect(response.body).toHaveProperty('error')

      // Restore valid token
      process.env.GITHUB_TOKEN = originalToken
    })

    it('should handle database connection failures', async () => {
      // Temporarily close database connection
      await prisma.$disconnect()

      const response = await request(app.getHttpServer())
        .get('/api/repositories')
        .expect(500)

      expect(response.body).toHaveProperty('error')

      // Reconnect database
      prisma = await setupTestDatabase()
    })

    it('should validate request payloads', async () => {
      // Send invalid payload
      const response = await request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .send({
          invalid: 'payload'
        })
        .expect(400)

      expect(response.body).toHaveProperty('error')
      expect(response.body.error).toContain('validation')
    })
  })
})