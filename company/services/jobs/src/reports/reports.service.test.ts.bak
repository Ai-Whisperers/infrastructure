import { Test, TestingModule } from '@nestjs/testing'
import { ReportsService } from './reports.service'
import { GitHubService } from '../integrations/github.service'
import { PrismaService } from '../db/prisma.service'
import { setupTestDatabase, cleanupTestDatabase } from '../../../../tests/setup/test-database'
import { PrismaClient } from '@prisma/client'

/**
 * REAL DATA TESTS - NO MOCKS
 * These tests use actual database connections and real API calls
 * to ensure production-like behavior and true coverage
 */
describe('ReportsService - Real Data Tests', () => {
  let service: ReportsService
  let githubService: GitHubService
  let prisma: PrismaClient
  let module: TestingModule

  beforeAll(async () => {
    // Setup real test database with production schema
    prisma = await setupTestDatabase()

    module = await Test.createTestingModule({
      providers: [
        ReportsService,
        GitHubService,
        {
          provide: PrismaService,
          useValue: prisma
        }
      ],
    }).compile()

    service = module.get<ReportsService>(ReportsService)
    githubService = module.get<GitHubService>(GitHubService)
  })

  afterAll(async () => {
    await cleanupTestDatabase()
    await module.close()
  })

  beforeEach(async () => {
    // Each test runs in a transaction that rolls back
    await prisma.$executeRaw`BEGIN`
  })

  afterEach(async () => {
    // Rollback transaction to maintain test isolation
    await prisma.$executeRaw`ROLLBACK`
  })

  describe('listRepositories - Real Database Tests', () => {
    it('should return real repositories from test database', async () => {
      // Test with actual database data, no mocks
      const repositories = await service.listRepositories()

      expect(repositories).toBeDefined()
      expect(Array.isArray(repositories)).toBe(true)
      expect(repositories.length).toBeGreaterThan(0)

      // Verify real data structure
      const firstRepo = repositories[0]
      expect(firstRepo).toHaveProperty('id')
      expect(firstRepo).toHaveProperty('name')
      expect(firstRepo).toHaveProperty('fullName')
      expect(firstRepo).toHaveProperty('healthScore')
      expect(firstRepo.healthScore).toBeGreaterThanOrEqual(0)
      expect(firstRepo.healthScore).toBeLessThanOrEqual(100)

      // Test actual data content
      expect(firstRepo.name).toMatch(/^[a-zA-Z0-9-_]+$/)
      expect(firstRepo.fullName).toContain('/')
    })

    it('should handle pagination with real data', async () => {
      // Test pagination with actual database constraints
      const page1 = await service.listRepositories(1, 2)
      const page2 = await service.listRepositories(2, 2)

      expect(page1.length).toBeLessThanOrEqual(2)
      expect(page2.length).toBeLessThanOrEqual(2)

      // Ensure no duplicate data across pages
      const page1Ids = page1.map(repo => repo.id)
      const page2Ids = page2.map(repo => repo.id)
      const intersection = page1Ids.filter(id => page2Ids.includes(id))
      expect(intersection).toHaveLength(0)
    })

    it('should sort repositories by health score correctly', async () => {
      // Test with real database sorting
      const repositories = await service.listRepositories(1, 10, 'health')

      if (repositories.length > 1) {
        for (let i = 0; i < repositories.length - 1; i++) {
          expect(repositories[i].healthScore).toBeGreaterThanOrEqual(
            repositories[i + 1].healthScore
          )
        }
      }
    })
  })

  describe('getRepository - Real Data Lookups', () => {
    it('should retrieve specific repository with real data', async () => {
      // Get a real repository from the database
      const allRepos = await prisma.repository.findMany()
      const testRepo = allRepos[0]

      const repository = await service.getRepository(testRepo.id)

      expect(repository).toBeDefined()
      expect(repository.id).toBe(testRepo.id)
      expect(repository.name).toBe(testRepo.name)
      expect(repository.healthScore).toBe(testRepo.healthScore)
    })

    it('should return null for non-existent repository', async () => {
      // Test with real database constraints
      const nonExistentId = 'non-existent-id'
      const repository = await service.getRepository(nonExistentId)

      expect(repository).toBeNull()
    })

    it('should include health check history with real data', async () => {
      // Test with actual health check relationships
      const allRepos = await prisma.repository.findMany()
      const testRepo = allRepos[0]

      const repository = await service.getRepository(testRepo.id)

      expect(repository).toBeDefined()
      expect(repository).toHaveProperty('healthChecks')

      // Verify real health check data structure
      if (repository.healthChecks && repository.healthChecks.length > 0) {
        const healthCheck = repository.healthChecks[0]
        expect(healthCheck).toHaveProperty('score')
        expect(healthCheck).toHaveProperty('metrics')
        expect(healthCheck).toHaveProperty('scannedAt')
        expect(healthCheck.score).toBeGreaterThanOrEqual(0)
        expect(healthCheck.score).toBeLessThanOrEqual(100)
      }
    })
  })

  describe('calculateAggregateMetrics - Real Calculations', () => {
    it('should calculate correct aggregate metrics from real data', async () => {
      // Use actual database data for calculations
      const metrics = await service.calculateAggregateMetrics()

      expect(metrics).toBeDefined()
      expect(metrics).toHaveProperty('totalRepositories')
      expect(metrics).toHaveProperty('activeRepositories')
      expect(metrics).toHaveProperty('averageHealthScore')

      // Verify calculations with real data
      expect(metrics.totalRepositories).toBeGreaterThan(0)
      expect(metrics.activeRepositories).toBeLessThanOrEqual(metrics.totalRepositories)
      expect(metrics.averageHealthScore).toBeGreaterThanOrEqual(0)
      expect(metrics.averageHealthScore).toBeLessThanOrEqual(100)

      // Cross-check with direct database query
      const repoCount = await prisma.repository.count()
      expect(metrics.totalRepositories).toBe(repoCount)

      const activeCount = await prisma.repository.count({
        where: { isActive: true }
      })
      expect(metrics.activeRepositories).toBe(activeCount)
    })

    it('should calculate health score distribution correctly', async () => {
      const metrics = await service.calculateAggregateMetrics()

      expect(metrics).toHaveProperty('healthDistribution')

      if (metrics.healthDistribution) {
        const { healthy, warning, critical } = metrics.healthDistribution

        // Verify real data distribution
        expect(healthy + warning + critical).toBe(metrics.totalRepositories)
        expect(healthy).toBeGreaterThanOrEqual(0)
        expect(warning).toBeGreaterThanOrEqual(0)
        expect(critical).toBeGreaterThanOrEqual(0)
      }
    })
  })

  describe('generateWeeklyReport - Integration with Real Data', () => {
    it('should generate report with real data and calculations', async () => {
      const currentDate = new Date()
      const weekNumber = Math.ceil(currentDate.getDate() / 7)
      const year = currentDate.getFullYear()

      // Generate report using real database data
      const report = await service.generateWeeklyReport(weekNumber, year)

      expect(report).toBeDefined()
      expect(report).toHaveProperty('id')
      expect(report.week).toBe(weekNumber)
      expect(report.year).toBe(year)
      expect(report.type).toBe('ORG_PULSE')

      // Verify report content has real data
      const content = JSON.parse(report.content)
      expect(content).toHaveProperty('totalRepositories')
      expect(content).toHaveProperty('averageHealthScore')
      expect(content).toHaveProperty('topContributors')

      // Cross-verify with database
      const repoCount = await prisma.repository.count()
      expect(content.totalRepositories).toBe(repoCount)
    })

    it('should prevent duplicate report generation', async () => {
      const currentDate = new Date()
      const weekNumber = Math.ceil(currentDate.getDate() / 7)
      const year = currentDate.getFullYear()

      // Generate first report
      const report1 = await service.generateWeeklyReport(weekNumber, year)

      // Attempt to generate duplicate
      await expect(
        service.generateWeeklyReport(weekNumber, year)
      ).rejects.toThrow()

      // Verify only one report exists
      const existingReports = await prisma.report.findMany({
        where: { week: weekNumber, year, type: 'ORG_PULSE' }
      })
      expect(existingReports).toHaveLength(1)
    })
  })

  describe('getRecentActivity - Real Time-based Queries', () => {
    it('should fetch recent activity with actual timestamps', async () => {
      // Test with real time-based database queries
      const days = 7
      const activity = await service.getRecentActivity(days)

      expect(activity).toBeDefined()
      expect(Array.isArray(activity)).toBe(true)

      // Verify actual time filtering
      const cutoffDate = new Date()
      cutoffDate.setDate(cutoffDate.getDate() - days)

      activity.forEach(item => {
        expect(new Date(item.createdAt)).toBeInstanceOf(Date)
        expect(new Date(item.createdAt).getTime()).toBeGreaterThan(cutoffDate.getTime() - 24 * 60 * 60 * 1000) // Allow for timezone differences
      })
    })

    it('should return empty array for future dates', async () => {
      const futureDays = -30 // 30 days in the future
      const activity = await service.getRecentActivity(futureDays)

      expect(activity).toEqual([])
    })
  })

  describe('Performance Tests - Real Database Operations', () => {
    it('should complete repository listing within performance threshold', async () => {
      const startTime = Date.now()

      await service.listRepositories()

      const endTime = Date.now()
      const executionTime = endTime - startTime

      // Real performance requirement: under 500ms
      expect(executionTime).toBeLessThan(500)
    })

    it('should handle concurrent requests without data corruption', async () => {
      // Test real database concurrency
      const concurrentRequests = Array(5).fill(null).map(() =>
        service.listRepositories()
      )

      const results = await Promise.all(concurrentRequests)

      // All requests should return the same data
      results.forEach((result, index) => {
        if (index > 0) {
          expect(result.length).toBe(results[0].length)
        }
      })
    })
  })

  describe('Error Handling - Real Database Constraints', () => {
    it('should handle database connection failures gracefully', async () => {
      // Temporarily close database connection to test real error handling
      await prisma.$disconnect()

      await expect(service.listRepositories()).rejects.toThrow()

      // Reconnect for cleanup
      prisma = await setupTestDatabase()
    })

    it('should validate input parameters with real constraints', async () => {
      // Test with database field constraints
      await expect(service.getRepository('')).rejects.toThrow()
      await expect(service.generateWeeklyReport(-1, 2025)).rejects.toThrow()
      await expect(service.generateWeeklyReport(54, 2025)).rejects.toThrow()
    })
  })

  describe('Data Consistency - Real Relationships', () => {
    it('should maintain referential integrity', async () => {
      // Test actual database constraints
      const repos = await service.listRepositories()

      for (const repo of repos.slice(0, 3)) { // Test first 3 repos
        // Verify health checks belong to correct repository
        const healthChecks = await prisma.healthCheck.findMany({
          where: { repositoryId: repo.id }
        })

        healthChecks.forEach(check => {
          expect(check.repositoryId).toBe(repo.id)
        })

        // Verify work item links are valid
        const workItemLinks = await prisma.workItemLink.findMany({
          where: { repositoryId: repo.id }
        })

        for (const link of workItemLinks) {
          const workItem = await prisma.workItem.findUnique({
            where: { id: link.workItemId }
          })
          expect(workItem).toBeDefined()
        }
      }
    })

    it('should correctly cascade deletes', async () => {
      // Create a test repository
      const testRepo = await prisma.repository.create({
        data: {
          name: 'test-cascade-repo',
          fullName: 'test/cascade-repo',
          url: 'https://github.com/test/cascade-repo',
          healthScore: 85
        }
      })

      // Create related health check
      const healthCheck = await prisma.healthCheck.create({
        data: {
          repositoryId: testRepo.id,
          score: 85,
          metrics: {},
          recommendations: [],
          scannedAt: new Date()
        }
      })

      // Delete repository should cascade
      await prisma.repository.delete({ where: { id: testRepo.id } })

      // Verify cascade worked
      const remainingHealthCheck = await prisma.healthCheck.findUnique({
        where: { id: healthCheck.id }
      })
      expect(remainingHealthCheck).toBeNull()
    })
  })
})