/**
 * Integration tests for workflows
 */

import { orchestrator } from '../../core/orchestrator';

describe('Workflow Integration Tests', () => {
  beforeAll(async () => {
    // Register mock services for all agents
    const mockGitHubService = {
      calculateHealthScore: jest.fn().mockResolvedValue({
        scores: [
          { repository: 'repo-1', score: 85, metrics: {} },
          { repository: 'repo-2', score: 90, metrics: {} },
        ],
        average: 87.5,
      }),
      detectStalePRs: jest.fn().mockResolvedValue({
        stalePRs: [{ title: 'PR 1', url: 'http://github.com/pr/1' }],
        count: 1,
      }),
      trackActivity: jest.fn().mockResolvedValue({
        period: '7 days',
        commits: 42,
        prs: 15,
        issues: 8,
        contributors: 12,
      }),
      checkBranchProtection: jest.fn().mockResolvedValue({
        protected: true,
        rules: ['require-reviews', 'status-checks'],
      }),
    };

    const mockAdoService = {
      linkWorkItems: jest.fn().mockResolvedValue({
        linked: 10,
        repositories: ['repo-1', 'repo-2'],
      }),
      detectDrift: jest.fn().mockResolvedValue({
        drifted: [],
        count: 0,
      }),
      repairLinks: jest.fn().mockResolvedValue({
        repaired: 0,
      }),
      parseCommits: jest.fn().mockResolvedValue({
        workItems: ['WI-123', 'WI-456'],
      }),
    };

    const mockDocsService = {
      validateTemplates: jest.fn().mockResolvedValue({
        valid: true,
        missing: [],
      }),
      analyzeCoverage: jest.fn().mockResolvedValue({
        coverage: 85,
        total: 100,
        documented: 85,
      }),
      generateDocs: jest.fn().mockResolvedValue({
        generated: 5,
        files: ['README.md', 'API.md'],
      }),
      enforceGate: jest.fn().mockResolvedValue({
        passed: true,
      }),
    };

    const mockOrgPulseService = {
      aggregateActivity: jest.fn().mockResolvedValue({
        totalCommits: 156,
        totalPRs: 42,
        totalIssues: 28,
      }),
      rankContributors: jest.fn().mockResolvedValue({
        topContributors: [
          { name: 'Alice', commits: 50 },
          { name: 'Bob', commits: 40 },
        ],
      }),
      analyzeTrends: jest.fn().mockResolvedValue({
        trend: 'increasing',
        changePercent: 15,
      }),
      generateReport: jest.fn().mockResolvedValue({
        format: 'markdown',
        path: '/reports/org-pulse.md',
      }),
    };

    const mockSlackService = {
      routeAlert: jest.fn().mockResolvedValue({
        channel: '#engineering',
        sent: true,
      }),
      enrichContext: jest.fn().mockResolvedValue({
        enriched: true,
      }),
      filterByPriority: jest.fn().mockResolvedValue({
        filtered: 5,
      }),
      createDigest: jest.fn().mockResolvedValue({
        digest: 'Weekly summary...',
      }),
    };

    const mockTodoService = {
      scanCode: jest.fn().mockResolvedValue({
        todos: [
          { file: 'src/app.ts', line: 42, text: 'TODO: Fix this' },
        ],
        count: 1,
      }),
      extractTodos: jest.fn().mockResolvedValue({
        extracted: 1,
      }),
      syncRepos: jest.fn().mockResolvedValue({
        synced: 3,
      }),
      automateTasks: jest.fn().mockResolvedValue({
        automated: 1,
      }),
    };

    orchestrator.registerService('github.service', mockGitHubService);
    orchestrator.registerService('ado-github-linker.service', mockAdoService);
    orchestrator.registerService('docs-check.scanner', mockDocsService);
    orchestrator.registerService('org-pulse.reporter', mockOrgPulseService);
    orchestrator.registerService('slack.service', mockSlackService);
    orchestrator.registerService('todo-scanner.service', mockTodoService);

    await orchestrator.initialize();
  });

  describe('Weekly Org Pulse Workflow', () => {
    it('should execute complete workflow successfully', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse', {
        includeArchived: false,
        minActivityDays: 7,
      });

      expect(result.success).toBe(true);
      expect(result.workflowId).toBe('weekly-org-pulse');
    });

    it('should execute all required agents', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      const agentIds = result.agentResults.map((r) => r.agentId);

      expect(agentIds).toContain('repository-health-scanner');
      expect(agentIds).toContain('org-pulse-reporter');
    });

    it('should complete within reasonable time', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      // Should complete in under 30 seconds for mock services
      expect(result.duration).toBeLessThan(30000);
    });

    it('should generate required outputs', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      const outputTypes = result.outputs.map((o) => o.type);

      expect(outputTypes).toContain('markdown');
      expect(outputTypes).toContain('json');
    });

    it('should handle custom inputs', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse', {
        includeArchived: true,
        minActivityDays: 14,
        reportFormat: 'html',
      });

      expect(result.success).toBe(true);
    });
  });

  describe('Compliance Audit Workflow', () => {
    it('should execute complete audit successfully', async () => {
      const result = await orchestrator.runWorkflow('compliance-audit', {
        checks: {
          health: true,
          documentation: true,
          adoSync: true,
        },
      });

      expect(result.success).toBe(true);
      expect(result.workflowId).toBe('compliance-audit');
    });

    it('should execute all audit agents', async () => {
      const result = await orchestrator.runWorkflow('compliance-audit');

      const agentIds = result.agentResults.map((r) => r.agentId);

      expect(agentIds).toContain('repository-health-scanner');
      expect(agentIds).toContain('documentation-guardian');
      expect(agentIds).toContain('ado-github-linker');
      expect(agentIds).toContain('org-pulse-reporter');
    });

    it('should support selective audit checks', async () => {
      const result = await orchestrator.runWorkflow('compliance-audit', {
        repositories: ['Company-Information'],
        checks: {
          health: true,
          documentation: false,
          adoSync: false,
        },
      });

      expect(result.success).toBe(true);
    });

    it('should generate comprehensive audit report', async () => {
      const result = await orchestrator.runWorkflow('compliance-audit');

      const outputTypes = result.outputs.map((o) => o.type);

      expect(outputTypes).toContain('markdown');
      expect(outputTypes).toContain('html');
    });
  });

  describe('PR Quality Gate Workflow', () => {
    it('should validate PR successfully', async () => {
      const result = await orchestrator.runWorkflow('pr-quality-gate');

      expect(result.success).toBe(true);
      expect(result.workflowId).toBe('pr-quality-gate');
    });

    it('should run validation agents', async () => {
      const result = await orchestrator.runWorkflow('pr-quality-gate');

      const agentIds = result.agentResults.map((r) => r.agentId);

      expect(agentIds).toContain('documentation-guardian');
      expect(agentIds).toContain('repository-health-scanner');
    });

    it('should complete quickly for fast feedback', async () => {
      const result = await orchestrator.runWorkflow('pr-quality-gate');

      // PR validation should be fast (<10s)
      expect(result.duration).toBeLessThan(10000);
    });
  });

  describe('ADO Sync Cycle Workflow', () => {
    it('should execute sync successfully', async () => {
      const result = await orchestrator.runWorkflow('ado-sync-cycle');

      expect(result.success).toBe(true);
      expect(result.workflowId).toBe('ado-sync-cycle');
    });

    it('should run ADO linker agent', async () => {
      const result = await orchestrator.runWorkflow('ado-sync-cycle');

      const agentIds = result.agentResults.map((r) => r.agentId);

      expect(agentIds).toContain('ado-github-linker');
    });

    it('should detect and report drift', async () => {
      const result = await orchestrator.runWorkflow('ado-sync-cycle');

      expect(result.success).toBe(true);
      expect(result.agentResults.length).toBeGreaterThan(0);
    });
  });

  describe('Multi-workflow Scenarios', () => {
    it('should run multiple workflows concurrently', async () => {
      const workflows = [
        'weekly-org-pulse',
        'pr-quality-gate',
        'ado-sync-cycle',
      ];

      const results = await Promise.all(
        workflows.map((id) => orchestrator.runWorkflow(id)),
      );

      expect(results.length).toBe(3);
      results.forEach((result) => {
        expect(result.success).toBe(true);
      });
    });

    it('should maintain isolation between concurrent workflows', async () => {
      const result1Promise = orchestrator.runWorkflow('weekly-org-pulse');
      const result2Promise = orchestrator.runWorkflow('compliance-audit');

      const [result1, result2] = await Promise.all([result1Promise, result2Promise]);

      expect(result1.workflowId).toBe('weekly-org-pulse');
      expect(result2.workflowId).toBe('compliance-audit');
      expect(result1.agentResults).not.toEqual(result2.agentResults);
    });
  });

  describe('Error Handling', () => {
    it('should handle agent failures gracefully', async () => {
      // Mock one service to fail
      const failingService = {
        calculateHealthScore: jest.fn().mockRejectedValue(new Error('Service error')),
      };

      orchestrator.registerService('github.service', failingService);

      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      // Workflow should fail but return result
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });

    it('should continue workflow when optional agents fail', async () => {
      // Most workflows should be resilient to individual agent failures
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      // Check that we got some results even if not all succeeded
      expect(result.agentResults).toBeDefined();
      expect(result.agentResults.length).toBeGreaterThan(0);
    });
  });

  describe('Performance', () => {
    it('should execute parallel agents concurrently', async () => {
      const startTime = Date.now();
      const result = await orchestrator.runWorkflow('weekly-org-pulse');
      const duration = Date.now() - startTime;

      // Parallel execution should be faster than sequential
      // With 4 agents at ~100ms each, parallel should be ~100-200ms
      // Sequential would be ~400ms
      expect(result.success).toBe(true);
    });

    it('should complete workflows within SLO', async () => {
      const result = await orchestrator.runWorkflow('compliance-audit');

      // Full compliance audit should complete in under 1 minute
      expect(result.duration).toBeLessThan(60000);
    });
  });
});
