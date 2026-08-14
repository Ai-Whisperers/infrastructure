import { Test, TestingModule } from '@nestjs/testing'
import { GitHubHealthScanner } from './github-health.scanner'
import { GitHubService } from '../integrations/github.service'
import { PrismaService } from '../db/prisma.service'
import { createMockRepository } from '../../../../tests/utils/test-factories'

describe('GitHubHealthScanner', () => {
  let scanner: GitHubHealthScanner
  let githubService: jest.Mocked<GitHubService>
  let prismaService: jest.Mocked<PrismaService>

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GitHubHealthScanner,
        {
          provide: GitHubService,
          useValue: {
            listOrganizationRepos: jest.fn(),
            getRepository: jest.fn(),
            getBranchProtection: jest.fn(),
            getPullRequests: jest.fn(),
            getRecentCommits: jest.fn(),
          },
        },
        {
          provide: PrismaService,
          useValue: {
            repository: {
              upsert: jest.fn(),
            },
            healthCheck: {
              create: jest.fn(),
            },
            syncLog: {
              create: jest.fn(),
            },
          },
        },
      ],
    }).compile()

    scanner = module.get<GitHubHealthScanner>(GitHubHealthScanner)
    githubService = module.get(GitHubService)
    prismaService = module.get(PrismaService)
  })

  describe('scanRepository', () => {
    it('should scan a repository and calculate health score', async () => {
      const mockRepoData = {
        name: 'test-repo',
        html_url: 'https://github.com/test/repo',
        description: 'Test repository',
        private: false,
        stargazers_count: 10,
        forks_count: 5,
        open_issues_count: 3,
        pushed_at: new Date().toISOString(),
        default_branch: 'main',
      }

      const mockProtection = {
        required_status_checks: {
          checks: [{ context: 'ci/test' }],
        },
      }

      const mockPRs = [
        { number: 1, title: 'PR 1', created_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString() },
      ]

      const mockCommits = [
        { sha: 'abc123', commit: { message: 'Test commit' } },
      ]

      const mockSavedRepo = {
        id: 1,
        name: 'test-repo',
        url: mockRepoData.html_url,
        healthScore: expect.any(Number),
      }

      githubService.getRepository = jest.fn().mockResolvedValue(mockRepoData as any)
      githubService.getBranchProtection = jest.fn().mockResolvedValue(mockProtection as any)
      githubService.getPullRequests = jest.fn().mockResolvedValue(mockPRs as any)
      githubService.getRecentCommits = jest.fn().mockResolvedValue(mockCommits as any)
      prismaService.repository.upsert = jest.fn().mockResolvedValue(mockSavedRepo as any)
      prismaService.healthCheck.create = jest.fn().mockResolvedValue({} as any)

      const result = await scanner.scanRepository('test-repo')

      expect(githubService.getRepository).toHaveBeenCalledWith('test-repo')
      expect(githubService.getBranchProtection).toHaveBeenCalledWith('test-repo', 'main')
      expect(githubService.getPullRequests).toHaveBeenCalledWith('test-repo')
      expect(githubService.getRecentCommits).toHaveBeenCalledWith('test-repo', 7)
      expect(prismaService.repository.upsert).toHaveBeenCalled()
      expect(prismaService.healthCheck.create).toHaveBeenCalled()
      expect(result).toBeDefined()
    })

    it('should handle repositories without branch protection', async () => {
      const mockRepoData = {
        name: 'test-repo',
        html_url: 'https://github.com/test/repo',
        description: 'Test repository',
        private: false,
        stargazers_count: 0,
        forks_count: 0,
        open_issues_count: 0,
        pushed_at: new Date().toISOString(),
        default_branch: 'main',
      }

      githubService.getRepository = jest.fn().mockResolvedValue(mockRepoData as any)
      githubService.getBranchProtection = jest.fn().mockResolvedValue(null)
      githubService.getPullRequests = jest.fn().mockResolvedValue([])
      githubService.getRecentCommits = jest.fn().mockResolvedValue([])
      prismaService.repository.upsert = jest.fn().mockResolvedValue({ id: 1 } as any)
      prismaService.healthCheck.create = jest.fn().mockResolvedValue({} as any)

      const result = await scanner.scanRepository('test-repo')

      expect(result).toBeDefined()
      expect(prismaService.repository.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { name: 'test-repo' },
          update: expect.objectContaining({
            hasProtection: 0,
          }),
        })
      )
    })
  })

  describe('scanAllRepositories', () => {
    it('should scan all repositories and log results', async () => {
      const mockRepos = [
        createMockRepository({ name: 'repo1' }),
        createMockRepository({ name: 'repo2' }),
      ]

      githubService.listOrganizationRepos = jest.fn().mockResolvedValue(mockRepos)
      githubService.getRepository = jest.fn().mockResolvedValue({
        name: 'repo1',
        html_url: 'https://github.com/test/repo1',
        description: 'Test',
        private: false,
        stargazers_count: 0,
        forks_count: 0,
        open_issues_count: 0,
        pushed_at: new Date().toISOString(),
        default_branch: 'main',
      })
      githubService.getBranchProtection = jest.fn().mockResolvedValue(null)
      githubService.getPullRequests = jest.fn().mockResolvedValue([])
      githubService.getRecentCommits = jest.fn().mockResolvedValue([])
      prismaService.repository.upsert = jest.fn().mockResolvedValue({ id: 1 } as any)
      prismaService.healthCheck.create = jest.fn().mockResolvedValue({} as any)
      prismaService.syncLog.create = jest.fn().mockResolvedValue({} as any)

      await scanner.scanAllRepositories()

      expect(githubService.listOrganizationRepos).toHaveBeenCalled()
      expect(prismaService.syncLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            syncType: 'GITHUB_SCAN',
            status: 'COMPLETED',
            itemsProcessed: 2,
            itemsFailed: 0,
          }),
        })
      )
    })

    it('should handle scan failures gracefully', async () => {
      githubService.listOrganizationRepos = jest.fn().mockRejectedValue(new Error('API Error'))
      prismaService.syncLog.create = jest.fn().mockResolvedValue({} as any)

      await scanner.scanAllRepositories()

      expect(prismaService.syncLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            syncType: 'GITHUB_SCAN',
            status: 'FAILED',
            errorMessage: 'API Error',
          }),
        })
      )
    })
  })
})
