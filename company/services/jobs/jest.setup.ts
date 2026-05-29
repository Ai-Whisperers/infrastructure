import { PrismaClient } from '@prisma/client'
import { DeepMockProxy, mockDeep, mockReset } from 'jest-mock-extended'

// Mock Prisma Client
jest.mock('./src/db/prisma.service', () => ({
  PrismaService: jest.fn().mockImplementation(() => ({
    $connect: jest.fn(),
    $disconnect: jest.fn(),
    repository: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    workItem: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    healthCheck: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
    report: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
  })),
}))

// Mock environment variables
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test'
process.env.GITHUB_TOKEN = 'test-github-token'
process.env.GITHUB_ORG = 'test-org'
process.env.AZURE_DEVOPS_PAT = 'test-ado-pat'
process.env.AZURE_DEVOPS_ORG = 'test-ado-org'
process.env.AZURE_DEVOPS_PROJECT = 'test-project'
process.env.SLACK_WEBHOOK_URL = 'https://hooks.slack.com/test'
process.env.REDIS_URL = 'redis://localhost:6379'

// Mock external modules
jest.mock('@octokit/rest')
jest.mock('bull')
jest.mock('axios')

// Global test utilities
global.beforeEach(() => {
  jest.clearAllMocks()
})

global.afterEach(() => {
  jest.restoreAllMocks()
})