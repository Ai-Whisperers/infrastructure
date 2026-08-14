import { faker } from '@faker-js/faker'

export const createMockRepository = (overrides = {}) => ({
  id: faker.string.uuid(),
  name: faker.lorem.word() + '-repo',
  fullName: `test-org/${faker.lorem.word()}-repo`,
  url: faker.internet.url(),
  description: faker.lorem.sentence(),
  healthScore: faker.number.int({ min: 0, max: 100 }),
  lastScannedAt: faker.date.recent(),
  isActive: true,
  defaultBranch: 'main',
  language: faker.helpers.arrayElement(['TypeScript', 'JavaScript', 'Python']),
  topics: faker.lorem.words(3).split(' '),
  visibility: 'public',
  createdAt: faker.date.past(),
  updatedAt: faker.date.recent(),
  ...overrides,
})

export const createMockWorkItem = (overrides = {}) => ({
  id: faker.number.int({ min: 1000, max: 9999 }),
  title: faker.lorem.sentence(),
  description: faker.lorem.paragraph(),
  state: faker.helpers.arrayElement(['New', 'Active', 'Resolved', 'Closed']),
  type: faker.helpers.arrayElement(['Bug', 'Feature', 'Task', 'Epic']),
  priority: faker.number.int({ min: 1, max: 4 }),
  assignedTo: faker.person.fullName(),
  createdDate: faker.date.past(),
  modifiedDate: faker.date.recent(),
  url: faker.internet.url(),
  ...overrides,
})

export const createMockHealthCheck = (overrides = {}) => ({
  id: faker.string.uuid(),
  repositoryId: faker.string.uuid(),
  score: faker.number.int({ min: 0, max: 100 }),
  metrics: {
    commits: faker.number.int({ min: 0, max: 100 }),
    pullRequests: faker.number.int({ min: 0, max: 50 }),
    issues: faker.number.int({ min: 0, max: 30 }),
    contributors: faker.number.int({ min: 1, max: 20 }),
    documentation: faker.number.int({ min: 0, max: 100 }),
    tests: faker.number.int({ min: 0, max: 100 }),
    security: faker.number.int({ min: 0, max: 100 }),
  },
  recommendations: faker.lorem.sentences(3).split('. '),
  scannedAt: faker.date.recent(),
  ...overrides,
})

export const createMockOrgPulseReport = (overrides = {}) => ({
  id: faker.string.uuid(),
  week: faker.number.int({ min: 1, max: 52 }),
  year: new Date().getFullYear(),
  totalRepositories: faker.number.int({ min: 5, max: 20 }),
  activeRepositories: faker.number.int({ min: 3, max: 15 }),
  averageHealthScore: faker.number.int({ min: 60, max: 95 }),
  topContributors: Array.from({ length: 5 }, () => ({
    name: faker.person.fullName(),
    commits: faker.number.int({ min: 10, max: 100 }),
    avatar: faker.image.avatar(),
  })),
  trends: {
    healthScoreTrend: faker.helpers.arrayElement(['up', 'down', 'stable']),
    activityTrend: faker.helpers.arrayElement(['up', 'down', 'stable']),
    issueResolutionTrend: faker.helpers.arrayElement(['up', 'down', 'stable']),
  },
  criticalIssues: Array.from({ length: 3 }, () => ({
    repository: faker.lorem.word(),
    issue: faker.lorem.sentence(),
    severity: faker.helpers.arrayElement(['high', 'critical']),
  })),
  generatedAt: faker.date.recent(),
  ...overrides,
})

export const createMockGitHubPullRequest = (overrides = {}) => ({
  id: faker.number.int({ min: 1, max: 1000 }),
  number: faker.number.int({ min: 1, max: 500 }),
  title: faker.lorem.sentence(),
  body: faker.lorem.paragraph(),
  state: faker.helpers.arrayElement(['open', 'closed', 'merged']),
  user: {
    login: faker.internet.userName(),
    avatar_url: faker.image.avatar(),
  },
  created_at: faker.date.past().toISOString(),
  updated_at: faker.date.recent().toISOString(),
  html_url: faker.internet.url(),
  draft: faker.datatype.boolean(),
  labels: faker.lorem.words(2).split(' ').map(word => ({ name: word })),
  ...overrides,
})

export const createMockGitHubIssue = (overrides = {}) => ({
  id: faker.number.int({ min: 1, max: 1000 }),
  number: faker.number.int({ min: 1, max: 500 }),
  title: faker.lorem.sentence(),
  body: faker.lorem.paragraph(),
  state: faker.helpers.arrayElement(['open', 'closed']),
  user: {
    login: faker.internet.userName(),
    avatar_url: faker.image.avatar(),
  },
  created_at: faker.date.past().toISOString(),
  updated_at: faker.date.recent().toISOString(),
  html_url: faker.internet.url(),
  labels: faker.lorem.words(3).split(' ').map(word => ({ name: word })),
  assignees: Array.from({ length: faker.number.int({ min: 0, max: 2 }) }, () => ({
    login: faker.internet.userName(),
  })),
  ...overrides,
})

export const createMockSlackMessage = (overrides = {}) => ({
  text: faker.lorem.sentence(),
  channel: '#' + faker.lorem.word(),
  username: 'AI-Whisperers Bot',
  icon_emoji: ':robot_face:',
  attachments: [
    {
      color: faker.helpers.arrayElement(['good', 'warning', 'danger']),
      title: faker.lorem.sentence(),
      text: faker.lorem.paragraph(),
      fields: Array.from({ length: 3 }, () => ({
        title: faker.lorem.word(),
        value: faker.lorem.sentence(),
        short: faker.datatype.boolean(),
      })),
      footer: 'AI-Whisperers Org OS',
      ts: Math.floor(Date.now() / 1000),
    },
  ],
  ...overrides,
})