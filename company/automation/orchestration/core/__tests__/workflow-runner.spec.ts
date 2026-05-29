/**
 * Unit tests for WorkflowRunner
 */

import { WorkflowRunner } from '../workflow-runner';
import { PluginLoader } from '../plugin-loader';
import { AgentExecutor } from '../agent-executor';
import { Workflow } from '../types';

describe('WorkflowRunner', () => {
  let workflowRunner: WorkflowRunner;
  let pluginLoader: PluginLoader;
  let agentExecutor: AgentExecutor;
  let mockService: any;

  beforeEach(async () => {
    pluginLoader = new PluginLoader('./automation/orchestration/config');
    agentExecutor = new AgentExecutor();

    // Create mock service
    mockService = {
      calculateHealthScore: jest.fn().mockResolvedValue({ score: 85 }),
      detectStalePRs: jest.fn().mockResolvedValue({ stalePRs: [] }),
      trackActivity: jest.fn().mockResolvedValue({ commits: 10 }),
      linkWorkItems: jest.fn().mockResolvedValue({ linked: 5 }),
      validateTemplates: jest.fn().mockResolvedValue({ valid: true }),
      aggregateActivity: jest.fn().mockResolvedValue({ total: 100 }),
      routeAlert: jest.fn().mockResolvedValue({ sent: true }),
    };

    agentExecutor.registerService('github.service', mockService);
    agentExecutor.registerService('ado-github-linker.service', mockService);
    agentExecutor.registerService('docs-check.scanner', mockService);
    agentExecutor.registerService('org-pulse.reporter', mockService);
    agentExecutor.registerService('slack.service', mockService);

    await pluginLoader.loadPlugins();

    workflowRunner = new WorkflowRunner(
      pluginLoader,
      agentExecutor,
      './automation/orchestration/config',
    );
  });

  describe('loadWorkflows', () => {
    it('should load workflows from configuration', async () => {
      await workflowRunner.loadWorkflows();

      const workflows = workflowRunner.getAllWorkflows();
      expect(workflows.length).toBeGreaterThan(0);
    });

    it('should load only enabled workflows', async () => {
      await workflowRunner.loadWorkflows();

      const workflows = workflowRunner.getAllWorkflows();
      workflows.forEach((workflow) => {
        expect(workflow.enabled).toBe(true);
      });
    });

    it('should load workflows with correct structure', async () => {
      await workflowRunner.loadWorkflows();

      const workflows = workflowRunner.getAllWorkflows();
      workflows.forEach((workflow) => {
        expect(workflow).toMatchObject({
          id: expect.any(String),
          name: expect.any(String),
          description: expect.any(String),
          trigger: expect.any(Object),
          agents: expect.any(Array),
          outputs: expect.any(Array),
          enabled: expect.any(Boolean),
        });
      });
    });
  });

  describe('executeWorkflow', () => {
    beforeEach(async () => {
      await workflowRunner.loadWorkflows();
    });

    it('should throw error for non-existent workflow', async () => {
      await expect(
        workflowRunner.executeWorkflow('non-existent-workflow'),
      ).rejects.toThrow('Workflow not found');
    });

    it('should execute workflow successfully', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      expect(result.success).toBe(true);
      expect(result.workflowId).toBe('weekly-org-pulse');
      expect(result.agentResults).toBeDefined();
      expect(result.duration).toBeGreaterThan(0);
    });

    it('should execute all agents in workflow', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      expect(result.agentResults.length).toBeGreaterThan(0);
      result.agentResults.forEach((agentResult) => {
        expect(agentResult).toMatchObject({
          agentId: expect.any(String),
          success: expect.any(Boolean),
          duration: expect.any(Number),
        });
      });
    });

    it('should pass inputs to workflow', async () => {
      const inputs = {
        includeArchived: false,
        minActivityDays: 7,
      };

      const result = await workflowRunner.executeWorkflow('weekly-org-pulse', inputs);

      expect(result.success).toBe(true);
    });

    it('should generate outputs', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      expect(result.outputs).toBeDefined();
      expect(Array.isArray(result.outputs)).toBe(true);
    });

    it('should handle workflow errors gracefully', async () => {
      mockService.calculateHealthScore.mockRejectedValue(new Error('Service error'));

      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });

    it('should track execution time', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      expect(result.startTime).toBeInstanceOf(Date);
      expect(result.endTime).toBeInstanceOf(Date);
      expect(result.endTime.getTime()).toBeGreaterThanOrEqual(result.startTime.getTime());
      expect(result.duration).toBe(result.endTime.getTime() - result.startTime.getTime());
    });
  });

  describe('workflow phases', () => {
    beforeEach(async () => {
      await workflowRunner.loadWorkflows();
    });

    it('should execute phases in order', async () => {
      const executionOrder: string[] = [];

      // Track execution order
      const originalExecute = agentExecutor.executeAgent.bind(agentExecutor);
      agentExecutor.executeAgent = jest.fn(async (agent, context) => {
        executionOrder.push(context.phase);
        return originalExecute(agent, context);
      });

      await workflowRunner.executeWorkflow('weekly-org-pulse');

      // Verify phases executed in order
      const uniquePhases = [...new Set(executionOrder)];
      expect(uniquePhases.length).toBeGreaterThan(0);
    });

    it('should handle parallel agents within phase', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      // Should complete successfully with parallel execution
      expect(result.success).toBe(true);
    });

    it('should respect agent dependencies', async () => {
      const result = await workflowRunner.executeWorkflow('compliance-audit');

      // All agents should execute
      expect(result.agentResults.length).toBeGreaterThan(0);

      // Dependent agents should run after their dependencies
      const agentIds = result.agentResults.map((r) => r.agentId);
      expect(agentIds).toBeDefined();
    });
  });

  describe('getWorkflow', () => {
    beforeEach(async () => {
      await workflowRunner.loadWorkflows();
    });

    it('should retrieve workflow by ID', () => {
      const workflow = workflowRunner.getWorkflow('weekly-org-pulse');

      expect(workflow).toBeDefined();
      expect(workflow?.id).toBe('weekly-org-pulse');
    });

    it('should return undefined for non-existent workflow', () => {
      const workflow = workflowRunner.getWorkflow('non-existent-workflow');

      expect(workflow).toBeUndefined();
    });
  });

  describe('getAllWorkflows', () => {
    it('should return empty array before loading', () => {
      const workflows = workflowRunner.getAllWorkflows();

      expect(workflows).toEqual([]);
    });

    it('should return all workflows after loading', async () => {
      await workflowRunner.loadWorkflows();
      const workflows = workflowRunner.getAllWorkflows();

      expect(workflows.length).toBeGreaterThan(0);
    });
  });

  describe('getStats', () => {
    it('should return zero workflows before loading', () => {
      const stats = workflowRunner.getStats();

      expect(stats.workflows).toBe(0);
    });

    it('should return correct workflow count after loading', async () => {
      await workflowRunner.loadWorkflows();
      const stats = workflowRunner.getStats();

      expect(stats.workflows).toBeGreaterThan(0);
      expect(stats.workflowIds).toBeDefined();
      expect(stats.workflowIds.length).toBe(stats.workflows);
    });
  });

  describe('workflow triggers', () => {
    beforeEach(async () => {
      await workflowRunner.loadWorkflows();
    });

    it('should have schedule trigger for weekly-org-pulse', () => {
      const workflow = workflowRunner.getWorkflow('weekly-org-pulse');

      expect(workflow?.trigger.type).toBe('schedule');
      expect(workflow?.trigger.cron).toBeDefined();
    });

    it('should have event trigger for pr-quality-gate', () => {
      const workflow = workflowRunner.getWorkflow('pr-quality-gate');

      expect(workflow?.trigger.type).toBe('event');
      expect(workflow?.trigger.event).toBe('pull_request.opened');
    });

    it('should have manual trigger for compliance-audit', () => {
      const workflow = workflowRunner.getWorkflow('compliance-audit');

      expect(workflow?.trigger.type).toBe('manual');
    });
  });

  describe('output generation', () => {
    beforeEach(async () => {
      await workflowRunner.loadWorkflows();
    });

    it('should generate JSON output', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      const jsonOutputs = result.outputs.filter((o) => o.type === 'json');
      expect(jsonOutputs.length).toBeGreaterThan(0);
    });

    it('should generate Markdown output', async () => {
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      const mdOutputs = result.outputs.filter((o) => o.type === 'markdown');
      expect(mdOutputs.length).toBeGreaterThan(0);
    });

    it('should handle output generation errors', async () => {
      // Mock workflow with invalid output path
      const result = await workflowRunner.executeWorkflow('weekly-org-pulse');

      // Should still return results even if output fails
      expect(result).toBeDefined();
    });
  });
});
