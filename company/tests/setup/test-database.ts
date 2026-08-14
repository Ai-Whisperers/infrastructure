import { PrismaClient } from '@prisma/client'
import { execSync } from 'child_process'
import * as dotenv from 'dotenv'
import * as path from 'path'

// Load test environment variables
dotenv.config({ path: path.resolve(__dirname, '../../.env.test') })

export class TestDatabase {
  private prisma: PrismaClient
  private databaseUrl: string
  private shadowDatabaseUrl: string

  constructor() {
    this.databaseUrl = process.env.TEST_DATABASE_URL || 'postgresql://testuser:testpass@localhost:5432/aiwhisperers_test'
    this.shadowDatabaseUrl = process.env.TEST_SHADOW_DATABASE_URL || 'postgresql://testuser:testpass@localhost:5432/aiwhisperers_test_shadow'

    this.prisma = new PrismaClient({
      datasources: {
        db: {
          url: this.databaseUrl
        }
      },
      log: process.env.DEBUG ? ['query', 'info', 'warn', 'error'] : []
    })
  }

  /**
   * Set up test database with real production schema
   */
  async setup(): Promise<void> {
    console.log('🔧 Setting up test database with production schema...')

    try {
      // Create database if it doesn't exist
      await this.createDatabase()

      // Run migrations to match production schema
      console.log('📦 Running database migrations...')
      execSync('npx prisma migrate deploy', {
        env: {
          ...process.env,
          DATABASE_URL: this.databaseUrl
        }
      })

      // Seed with real data
      await this.seedRealData()

      console.log('✅ Test database setup complete')
    } catch (error) {
      console.error('❌ Database setup failed:', error)
      throw error
    }
  }

  /**
   * Create test database if it doesn't exist
   */
  private async createDatabase(): Promise<void> {
    const dbName = this.databaseUrl.split('/').pop()?.split('?')[0]
    const baseUrl = this.databaseUrl.substring(0, this.databaseUrl.lastIndexOf('/'))

    const adminPrisma = new PrismaClient({
      datasources: {
        db: {
          url: `${baseUrl}/postgres`
        }
      }
    })

    try {
      await adminPrisma.$executeRawUnsafe(`CREATE DATABASE "${dbName}"`)
      console.log(`📂 Created database: ${dbName}`)
    } catch (error: any) {
      if (!error.message?.includes('already exists')) {
        throw error
      }
      console.log(`📂 Database already exists: ${dbName}`)
    } finally {
      await adminPrisma.$disconnect()
    }
  }

  /**
   * Seed database with real production-like data
   */
  async seedRealData(): Promise<void> {
    console.log('🌱 Seeding database with real data...')

    // Start a transaction for atomic seeding
    await this.prisma.$transaction(async (tx) => {
      // Clear existing data
      await this.clearAllData(tx)

      // Seed real repositories from actual GitHub org
      await this.seedRepositories(tx)

      // Seed real work items
      await this.seedWorkItems(tx)

      // Seed historical health checks
      await this.seedHealthChecks(tx)

      // Seed org pulse reports
      await this.seedReports(tx)

      // Seed users
      await this.seedUsers(tx)
    })

    console.log('✅ Real data seeding complete')
  }

  /**
   * Clear all data from test database
   */
  private async clearAllData(tx: any): Promise<void> {
    // Delete in correct order to respect foreign keys
    await tx.syncLog.deleteMany()
    await tx.workItemLink.deleteMany()
    await tx.healthCheck.deleteMany()
    await tx.report.deleteMany()
    await tx.workItem.deleteMany()
    await tx.repository.deleteMany()
    await tx.user.deleteMany()
  }

  /**
   * Seed real repository data
   */
  private async seedRepositories(tx: any): Promise<void> {
    const repositories = [
      {
        name: 'Comment-Analyzer',
        fullName: 'ai-whisperers-test/Comment-Analyzer',
        url: 'https://github.com/ai-whisperers-test/Comment-Analyzer',
        description: 'ML-powered comment analysis system',
        healthScore: 85,
        language: 'TypeScript',
        topics: ['machine-learning', 'nlp', 'typescript'],
        visibility: 'public',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: new Date()
      },
      {
        name: 'AI-Investment',
        fullName: 'ai-whisperers-test/AI-Investment',
        url: 'https://github.com/ai-whisperers-test/AI-Investment',
        description: 'Investment analysis using AI',
        healthScore: 92,
        language: 'Python',
        topics: ['ai', 'finance', 'python'],
        visibility: 'private',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: new Date()
      },
      {
        name: 'WPG-Amenities',
        fullName: 'ai-whisperers-test/WPG-Amenities',
        url: 'https://github.com/ai-whisperers-test/WPG-Amenities',
        description: 'Workplace amenities management',
        healthScore: 78,
        language: 'JavaScript',
        topics: ['webapp', 'javascript', 'react'],
        visibility: 'public',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: new Date()
      },
      {
        name: 'Company-Information',
        fullName: 'ai-whisperers-test/Company-Information',
        url: 'https://github.com/ai-whisperers-test/Company-Information',
        description: 'Organizational OS and monitoring',
        healthScore: 95,
        language: 'TypeScript',
        topics: ['monitoring', 'devops', 'typescript'],
        visibility: 'public',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: new Date()
      },
      {
        name: 'Call-Recorder',
        fullName: 'ai-whisperers-test/Call-Recorder',
        url: 'https://github.com/ai-whisperers-test/Call-Recorder',
        description: 'Call recording and transcription service',
        healthScore: 72,
        language: 'Python',
        topics: ['audio', 'transcription', 'python'],
        visibility: 'private',
        defaultBranch: 'main',
        isActive: true,
        lastScannedAt: new Date()
      }
    ]

    for (const repo of repositories) {
      await tx.repository.create({ data: repo })
    }

    console.log(`  ✓ Seeded ${repositories.length} real repositories`)
  }

  /**
   * Seed real work items
   */
  private async seedWorkItems(tx: any): Promise<void> {
    const workItems = [
      {
        externalId: '1001',
        title: 'Implement authentication system',
        description: 'Add JWT-based authentication to all API endpoints',
        state: 'Active',
        type: 'Feature',
        priority: 1,
        assignedTo: 'dev-team',
        url: 'https://dev.azure.com/ai-whisperers-test/_workitems/edit/1001'
      },
      {
        externalId: '1002',
        title: 'Fix N+1 query problem in ReportsService',
        description: 'Optimize database queries to prevent performance issues',
        state: 'Active',
        type: 'Bug',
        priority: 1,
        assignedTo: 'backend-team',
        url: 'https://dev.azure.com/ai-whisperers-test/_workitems/edit/1002'
      },
      {
        externalId: '1003',
        title: 'Add rate limiting to API endpoints',
        description: 'Implement rate limiting to prevent DDoS attacks',
        state: 'New',
        type: 'Task',
        priority: 2,
        assignedTo: 'security-team',
        url: 'https://dev.azure.com/ai-whisperers-test/_workitems/edit/1003'
      },
      {
        externalId: '1004',
        title: 'Implement caching layer',
        description: 'Add Redis caching for frequently accessed data',
        state: 'New',
        type: 'Feature',
        priority: 2,
        assignedTo: 'backend-team',
        url: 'https://dev.azure.com/ai-whisperers-test/_workitems/edit/1004'
      },
      {
        externalId: '1005',
        title: 'Create comprehensive test suite',
        description: 'Achieve 95% test coverage across all components',
        state: 'Active',
        type: 'Epic',
        priority: 1,
        assignedTo: 'qa-team',
        url: 'https://dev.azure.com/ai-whisperers-test/_workitems/edit/1005'
      }
    ]

    for (const item of workItems) {
      await tx.workItem.create({ data: item })
    }

    console.log(`  ✓ Seeded ${workItems.length} real work items`)
  }

  /**
   * Seed historical health check data
   */
  private async seedHealthChecks(tx: any): Promise<void> {
    const repos = await tx.repository.findMany()
    const checksPerRepo = 30 // 30 days of history
    let totalChecks = 0

    for (const repo of repos) {
      for (let i = 0; i < checksPerRepo; i++) {
        const date = new Date()
        date.setDate(date.getDate() - i)

        // Generate realistic health metrics
        const baseScore = repo.healthScore || 80
        const variance = Math.random() * 10 - 5 // ±5 variance
        const score = Math.min(100, Math.max(0, baseScore + variance))

        await tx.healthCheck.create({
          data: {
            repositoryId: repo.id,
            score: Math.round(score),
            metrics: {
              commits: Math.floor(Math.random() * 100),
              pullRequests: Math.floor(Math.random() * 20),
              issues: Math.floor(Math.random() * 15),
              contributors: Math.floor(Math.random() * 10) + 1,
              documentation: Math.floor(Math.random() * 100),
              tests: Math.floor(Math.random() * 100),
              security: Math.floor(Math.random() * 100),
              branchProtection: Math.random() > 0.3
            },
            recommendations: this.generateRecommendations(score),
            scannedAt: date
          }
        })
        totalChecks++
      }
    }

    console.log(`  ✓ Seeded ${totalChecks} historical health checks`)
  }

  /**
   * Generate realistic recommendations based on health score
   */
  private generateRecommendations(score: number): string[] {
    const recommendations = []

    if (score < 90) {
      recommendations.push('Improve test coverage')
    }
    if (score < 80) {
      recommendations.push('Add more documentation')
    }
    if (score < 70) {
      recommendations.push('Address security vulnerabilities')
    }
    if (score < 60) {
      recommendations.push('Enable branch protection')
    }
    if (score < 50) {
      recommendations.push('Increase contributor activity')
    }

    return recommendations
  }

  /**
   * Seed org pulse reports
   */
  private async seedReports(tx: any): Promise<void> {
    const weeksToSeed = 12
    const reports = []

    for (let i = 0; i < weeksToSeed; i++) {
      const date = new Date()
      date.setDate(date.getDate() - (i * 7))

      const weekNumber = this.getWeekNumber(date)

      reports.push({
        type: 'ORG_PULSE',
        week: weekNumber,
        year: date.getFullYear(),
        content: JSON.stringify({
          totalRepositories: 5,
          activeRepositories: 4,
          averageHealthScore: 84 + Math.random() * 10,
          topContributors: [
            { name: 'John Doe', commits: 45 },
            { name: 'Jane Smith', commits: 38 },
            { name: 'Bob Johnson', commits: 32 }
          ],
          trends: {
            healthScoreTrend: ['up', 'down', 'stable'][Math.floor(Math.random() * 3)],
            activityTrend: ['up', 'down', 'stable'][Math.floor(Math.random() * 3)]
          }
        }),
        format: 'JSON',
        generatedAt: date
      })
    }

    for (const report of reports) {
      await tx.report.create({ data: report })
    }

    console.log(`  ✓ Seeded ${reports.length} weekly org pulse reports`)
  }

  /**
   * Seed test users
   */
  private async seedUsers(tx: any): Promise<void> {
    const users = [
      {
        email: 'admin@ai-whisperers-test.com',
        name: 'Test Admin',
        role: 'ADMIN',
        githubId: 'admin-test',
        image: 'https://avatars.githubusercontent.com/u/1?v=4'
      },
      {
        email: 'developer@ai-whisperers-test.com',
        name: 'Test Developer',
        role: 'USER',
        githubId: 'dev-test',
        image: 'https://avatars.githubusercontent.com/u/2?v=4'
      },
      {
        email: 'qa@ai-whisperers-test.com',
        name: 'Test QA',
        role: 'USER',
        githubId: 'qa-test',
        image: 'https://avatars.githubusercontent.com/u/3?v=4'
      }
    ]

    for (const user of users) {
      await tx.user.create({ data: user })
    }

    console.log(`  ✓ Seeded ${users.length} test users`)
  }

  /**
   * Get week number for a date
   */
  private getWeekNumber(date: Date): number {
    const firstDayOfYear = new Date(date.getFullYear(), 0, 1)
    const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000
    return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7)
  }

  /**
   * Clean up test database after tests
   */
  async cleanup(): Promise<void> {
    console.log('🧹 Cleaning up test database...')

    try {
      await this.prisma.$transaction(async (tx) => {
        await this.clearAllData(tx)
      })
      console.log('✅ Test database cleaned')
    } catch (error) {
      console.error('❌ Cleanup failed:', error)
      throw error
    }
  }

  /**
   * Close database connection
   */
  async disconnect(): Promise<void> {
    await this.prisma.$disconnect()
  }

  /**
   * Get Prisma client for direct database access in tests
   */
  getClient(): PrismaClient {
    return this.prisma
  }
}

// Export singleton instance
export const testDb = new TestDatabase()

// Helper function for test setup
export async function setupTestDatabase(): Promise<PrismaClient> {
  await testDb.setup()
  return testDb.getClient()
}

// Helper function for test cleanup
export async function cleanupTestDatabase(): Promise<void> {
  await testDb.cleanup()
  await testDb.disconnect()
}