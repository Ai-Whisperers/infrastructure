import { Test, TestingModule } from '@nestjs/testing'
import { ConfigService } from '@nestjs/config'
import { GitHubService } from './github.service'
import { Octokit } from '@octokit/rest'
import { createMockRepository } from '../../../../tests/utils/test-factories'

jest.mock('@octokit/rest')

describe('GitHubService', () => {
  let service: GitHubService
  let mockOctokit: jest.Mocked<Octokit>

  beforeEach(async () => {
    mockOctokit = {
      repos: {
        listForOrg: jest.fn() as any,
        get: jest.fn() as any,
        listBranches: jest.fn() as any,
        getBranchProtection: jest.fn() as any,
      },
      pulls: {
        list: jest.fn() as any,
        get: jest.fn() as any,
        createReviewComment: jest.fn() as any,
      },
      issues: {
        listForRepo: jest.fn() as any,
        get: jest.fn() as any,
        createComment: jest.fn() as any,
      },
      search: {
        issuesAndPullRequests: jest.fn() as any,
      },
      rateLimit: {
        get: jest.fn().mockResolvedValue({
          data: {
            resources: {
              core: { limit: 5000, remaining: 4500, reset: Date.now() / 1000 + 3600 },
            },
          },
        }) as any,
      },
    } as any

    ;(Octokit as jest.MockedClass<typeof Octokit>).mockImplementation(() => mockOctokit)

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GitHubService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === 'GITHUB_TOKEN') return 'test-token'
              if (key === 'GITHUB_ORG') return 'Ai-Whisperers'
              return null
            }),
          },
        },
      ],
    }).compile()

    service = module.get<GitHubService>(GitHubService)
  })

  describe('listOrganizationRepos', () => {
    it('should fetch all repositories for the organization', async () => {
      const mockRepos = [createMockRepository(), createMockRepository()]
      ;(mockOctokit.repos.listForOrg as unknown as jest.Mock).mockResolvedValue({
        data: mockRepos,
        status: 200,
        headers: {},
        url: '',
      } as any)

      const result = await service.listOrganizationRepos()

      expect(mockOctokit.repos.listForOrg).toHaveBeenCalledWith({
        org: 'Ai-Whisperers',
        per_page: 100,
        sort: 'updated',
      })
      expect(result).toEqual(mockRepos)
    })

    it('should handle API errors gracefully', async () => {
      ;(mockOctokit.repos.listForOrg as unknown as jest.Mock).mockRejectedValue(new Error('API Error'))

      await expect(service.listOrganizationRepos()).rejects.toThrow('API Error')
    })
  })

})