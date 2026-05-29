import { Test, TestingModule } from '@nestjs/testing'
import { INestApplication } from '@nestjs/common'
import * as request from 'supertest'
import { Response } from 'supertest'
import { AppModule } from './app.module'

describe('AppController (Integration)', () => {
  let app: INestApplication

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile()

    app = moduleFixture.createNestApplication()
    await app.init()
  })

  afterAll(async () => {
    await app.close()
  })

  describe('/api/health (GET)', () => {
    it('should return health status', () => {
      return request(app.getHttpServer())
        .get('/api/health')
        .expect(200)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('status', 'healthy')
          expect(res.body).toHaveProperty('timestamp')
          expect(res.body).toHaveProperty('uptime')
          expect(res.body).toHaveProperty('version')
        })
    })
  })

  describe('/api/scanners/health/trigger (POST)', () => {
    it('should require authentication', () => {
      return request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .expect(401)
    })

    it('should trigger health scan with valid auth', () => {
      return request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .set('Authorization', 'Bearer test-token')
        .send({ repositories: ['test-repo'] })
        .expect(202)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('jobId')
          expect(res.body).toHaveProperty('status', 'queued')
        })
    })

    it('should validate request body', () => {
      return request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .set('Authorization', 'Bearer test-token')
        .send({ invalid: 'data' })
        .expect(400)
    })
  })

  describe('/api/sync/ado-github/trigger (POST)', () => {
    it('should trigger ADO-GitHub sync', () => {
      return request(app.getHttpServer())
        .post('/api/sync/ado-github/trigger')
        .set('Authorization', 'Bearer test-token')
        .send({
          repository: 'test-repo',
          pullRequestNumber: 123
        })
        .expect(202)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('jobId')
          expect(res.body).toHaveProperty('status')
        })
    })

    it('should handle rate limiting', async () => {
      // Simulate multiple rapid requests
      const requests = Array(10).fill(null).map(() =>
        request(app.getHttpServer())
          .post('/api/sync/ado-github/trigger')
          .set('Authorization', 'Bearer test-token')
          .send({ repository: 'test-repo' })
      )

      const responses = await Promise.all(requests)
      const rateLimited = responses.some(r => r.status === 429)

      expect(rateLimited).toBe(true)
    })
  })

  describe('/api/sync/ado-github/status (GET)', () => {
    it('should return sync status and metrics', () => {
      return request(app.getHttpServer())
        .get('/api/sync/ado-github/status')
        .set('Authorization', 'Bearer test-token')
        .expect(200)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('lastSync')
          expect(res.body).toHaveProperty('totalSynced')
          expect(res.body).toHaveProperty('pendingSync')
          expect(res.body).toHaveProperty('failedSync')
          expect(res.body).toHaveProperty('averageSyncTime')
        })
    })
  })

  describe('/api/reporters/org-pulse/generate (POST)', () => {
    it('should generate weekly org pulse report', () => {
      return request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .set('Authorization', 'Bearer test-token')
        .send({ week: 35, year: 2025 })
        .expect(202)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('reportId')
          expect(res.body).toHaveProperty('status', 'generating')
        })
    })

    it('should prevent duplicate report generation', async () => {
      const reportParams = { week: 36, year: 2025 }

      // First request should succeed
      await request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .set('Authorization', 'Bearer test-token')
        .send(reportParams)
        .expect(202)

      // Second request should return conflict
      await request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .set('Authorization', 'Bearer test-token')
        .send(reportParams)
        .expect(409)
    })
  })

  describe('/api/reports/org-pulse/:week (GET)', () => {
    it('should retrieve weekly report', async () => {
      // Generate a report first
      const generateRes = await request(app.getHttpServer())
        .post('/api/reporters/org-pulse/generate')
        .set('Authorization', 'Bearer test-token')
        .send({ week: 37, year: 2025 })
        .expect(202)

      // Wait for generation
      await new Promise(resolve => setTimeout(resolve, 2000))

      // Retrieve the report
      return request(app.getHttpServer())
        .get('/api/reports/org-pulse/37?year=2025')
        .set('Authorization', 'Bearer test-token')
        .expect(200)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('week', 37)
          expect(res.body).toHaveProperty('year', 2025)
          expect(res.body).toHaveProperty('content')
          expect(res.body).toHaveProperty('generatedAt')
        })
    })

    it('should return 404 for non-existent report', () => {
      return request(app.getHttpServer())
        .get('/api/reports/org-pulse/99?year=2025')
        .set('Authorization', 'Bearer test-token')
        .expect(404)
    })
  })

  describe('/api/scanners/docs/check (POST)', () => {
    it('should validate documentation', () => {
      return request(app.getHttpServer())
        .post('/api/scanners/docs/check')
        .set('Authorization', 'Bearer test-token')
        .send({
          repository: 'test-repo',
          pullRequestNumber: 456,
          files: ['README.md', 'docs/API.md']
        })
        .expect(200)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('passed')
          expect(res.body).toHaveProperty('violations')
          expect(res.body).toHaveProperty('suggestions')
        })
    })

    it('should detect missing documentation', () => {
      return request(app.getHttpServer())
        .post('/api/scanners/docs/check')
        .set('Authorization', 'Bearer test-token')
        .send({
          repository: 'test-repo',
          pullRequestNumber: 789,
          files: []
        })
        .expect(200)
        .expect((res: Response) => {
          expect(res.body.passed).toBe(false)
          expect(res.body.violations).toContain('Missing README.md')
        })
    })
  })

  describe('/api/jobs/queue (GET)', () => {
    it('should return job queue status', () => {
      return request(app.getHttpServer())
        .get('/api/jobs/queue')
        .set('Authorization', 'Bearer test-token')
        .expect(200)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('waiting')
          expect(res.body).toHaveProperty('active')
          expect(res.body).toHaveProperty('completed')
          expect(res.body).toHaveProperty('failed')
          expect(res.body).toHaveProperty('delayed')
        })
    })
  })

  describe('/api/notifications/test (POST)', () => {
    it('should send test notification', () => {
      return request(app.getHttpServer())
        .post('/api/notifications/test')
        .set('Authorization', 'Bearer test-token')
        .send({
          channel: 'slack',
          message: 'Test notification from integration tests'
        })
        .expect(200)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('sent', true)
          expect(res.body).toHaveProperty('channel', 'slack')
        })
    })

    it('should validate notification channel', () => {
      return request(app.getHttpServer())
        .post('/api/notifications/test')
        .set('Authorization', 'Bearer test-token')
        .send({
          channel: 'invalid-channel',
          message: 'Test'
        })
        .expect(400)
    })
  })

  describe('Error Handling', () => {
    it('should handle 404 for unknown routes', () => {
      return request(app.getHttpServer())
        .get('/api/non-existent')
        .expect(404)
    })

    it('should handle malformed JSON', () => {
      return request(app.getHttpServer())
        .post('/api/scanners/health/trigger')
        .set('Authorization', 'Bearer test-token')
        .set('Content-Type', 'application/json')
        .send('{ invalid json')
        .expect(400)
    })

    it('should handle server errors gracefully', () => {
      // Force an internal error by sending invalid data type
      return request(app.getHttpServer())
        .post('/api/sync/ado-github/trigger')
        .set('Authorization', 'Bearer test-token')
        .send({
          repository: 123, // Should be string
          pullRequestNumber: 'abc' // Should be number
        })
        .expect(400)
        .expect((res: Response) => {
          expect(res.body).toHaveProperty('error')
          expect(res.body).toHaveProperty('message')
        })
    })
  })
})