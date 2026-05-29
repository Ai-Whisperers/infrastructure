import { createMockRepository, createMockGitHubPullRequest, createMockGitHubIssue } from '../utils/test-factories'

export class MockGitHubAPI {
  private repositories = Array(10).fill(null).map(() => createMockRepository())
  private pullRequests = new Map<string, any[]>()
  private issues = new Map<string, any[]>()
  private rateLimit = { limit: 5000, remaining: 4500, reset: Date.now() / 1000 + 3600 }

  constructor() {
    // Initialize with mock data
    this.repositories.forEach(repo => {
      this.pullRequests.set(repo.name, Array(5).fill(null).map(() => createMockGitHubPullRequest()))
      this.issues.set(repo.name, Array(3).fill(null).map(() => createMockGitHubIssue()))
    })
  }

  async listRepositories(org: string, options: any = {}) {
    const { page = 1, per_page = 100 } = options
    const start = (page - 1) * per_page
    const end = start + per_page
    const repos = this.repositories.slice(start, end)

    return {
      data: repos,
      headers: {
        link: repos.length === per_page ? `<url>; rel="next"` : undefined
      }
    }
  }

  async getRepository(owner: string, repo: string) {
    const repository = this.repositories.find(r => r.name === repo)
    if (!repository) {
      throw { status: 404, message: 'Repository not found' }
    }
    return { data: repository }
  }

  async listPullRequests(owner: string, repo: string, options: any = {}) {
    const prs = this.pullRequests.get(repo) || []
    const { state = 'all' } = options

    const filtered = state === 'all'
      ? prs
      : prs.filter(pr => pr.state === state)

    return { data: filtered }
  }

  async getPullRequest(owner: string, repo: string, number: number) {
    const prs = this.pullRequests.get(repo) || []
    const pr = prs.find(p => p.number === number)

    if (!pr) {
      throw { status: 404, message: 'Pull request not found' }
    }
    return { data: pr }
  }

  async createPullRequestComment(owner: string, repo: string, number: number, body: string) {
    return {
      data: {
        id: Math.random() * 1000000,
        body,
        created_at: new Date().toISOString(),
        user: { login: 'bot' }
      }
    }
  }

  async listIssues(owner: string, repo: string, options: any = {}) {
    const issues = this.issues.get(repo) || []
    const { state = 'all' } = options

    const filtered = state === 'all'
      ? issues
      : issues.filter(issue => issue.state === state)

    return { data: filtered }
  }

  async createIssueComment(owner: string, repo: string, number: number, body: string) {
    return {
      data: {
        id: Math.random() * 1000000,
        body,
        created_at: new Date().toISOString(),
        user: { login: 'bot' }
      }
    }
  }

  async searchIssuesAndPullRequests(query: string) {
    const allPRs = Array.from(this.pullRequests.values()).flat()
    const allIssues = Array.from(this.issues.values()).flat()
    const allItems = [...allPRs, ...allIssues]

    // Simple mock search - just return some items
    const results = allItems.slice(0, 10)

    return {
      data: {
        total_count: results.length,
        items: results
      }
    }
  }

  async getBranchProtection(owner: string, repo: string, branch: string) {
    // Randomly return protection or not
    if (Math.random() > 0.7) {
      throw { status: 404, message: 'Branch protection not found' }
    }

    return {
      data: {
        required_status_checks: {
          strict: true,
          contexts: ['ci/test', 'security/scan']
        },
        enforce_admins: true,
        required_pull_request_reviews: {
          required_approving_review_count: 2
        }
      }
    }
  }

  async getRateLimit() {
    return {
      data: {
        resources: {
          core: this.rateLimit,
          search: { ...this.rateLimit },
          graphql: { ...this.rateLimit }
        }
      }
    }
  }

  // Utility methods for testing
  setRateLimit(remaining: number) {
    this.rateLimit.remaining = remaining
  }

  addRepository(repo: any) {
    this.repositories.push(repo)
  }

  addPullRequest(repo: string, pr: any) {
    if (!this.pullRequests.has(repo)) {
      this.pullRequests.set(repo, [])
    }
    this.pullRequests.get(repo)!.push(pr)
  }

  addIssue(repo: string, issue: any) {
    if (!this.issues.has(repo)) {
      this.issues.set(repo, [])
    }
    this.issues.get(repo)!.push(issue)
  }

  reset() {
    this.repositories = Array(10).fill(null).map(() => createMockRepository())
    this.pullRequests.clear()
    this.issues.clear()
    this.rateLimit = { limit: 5000, remaining: 4500, reset: Date.now() / 1000 + 3600 }
  }
}