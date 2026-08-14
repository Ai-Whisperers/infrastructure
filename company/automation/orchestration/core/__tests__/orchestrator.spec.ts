/**
 * Unit tests for Orchestrator
 */

import { Orchestrator } from '../orchestrator';

describe('Orchestrator', () => {
  let orchestrator: Orchestrator;

  beforeEach(() => {
    orchestrator = new Orchestrator('./automation/orchestration/config');
  });

  describe('initialize', () => {
    it('should initialize successfully', async () => {
      await orchestrator.initialize();

      const stats = orchestrator.getStats();
      expect(stats.plugins).toBeGreaterThan(0);
      expect(stats.agents).toBeGreaterThan(0);
      expect(stats.workflows).toBeGreaterThan(0);
    });

    it('should not reinitialize if already initialized', async () => {
      await orchestrator.initialize();
      const statsBefore = orchestrator.getStats();

      await orchestrator.initialize();
      const statsAfter = orchestrator.getStats();

      expect(statsAfter).toEqual(statsBefore);
    });

    it('should load plugins during initialization', async () => {
      await orchestrator.initialize();

      const plugins = orchestrator.getPlugins();
      expect(plugins.length).toBeGreaterThan(0);
    });

    it('should load agents during initialization', async () => {
      await orchestrator.initialize();

      const agents = orchestrator.getAgents();
      expect(agents.length).toBeGreaterThan(0);
    });

    it('should load workflows during initialization', async () => {
      await orchestrator.initialize();

      const workflows = orchestrator.getWorkflows();
      expect(workflows.length).toBeGreaterThan(0);
    });
  });

  describe('registerService', () => {
    it('should register a service', () => {
      const mockService = {
        method: jest.fn().mockResolvedValue({}),
      };

      orchestrator.registerService('test.service', mockService);

      const stats = orchestrator.getStats();
      expect(stats.services).toContain('test.service');
    });

    it('should allow registering multiple services', () => {
      orchestrator.registerService('service-1', {});
      orchestrator.registerService('service-2', {});
      orchestrator.registerService('service-3', {});

      const stats = orchestrator.getStats();
      expect(stats.registeredServices).toBeGreaterThanOrEqual(3);
    });
  });

  describe('runWorkflow', () => {
    beforeEach(() => {
      // Register mock services
      const mockService = {
        calculateHealthScore: jest.fn().mockResolvedValue({ score: 85 }),
        detectStalePRs: jest.fn().mockResolvedValue({ stalePRs: [] }),
        trackActivity: jest.fn().mockResolvedValue({ commits: 10 }),
        linkWorkItems: jest.fn().mockResolvedValue({ linked: 5 }),
        validateTemplates: jest.fn().mockResolvedValue({ valid: true }),
        aggregateActivity: jest.fn().mockResolvedValue({ total: 100 }),
        routeAlert: jest.fn().mockResolvedValue({ sent: true }),
        scanCode: jest.fn().mockResolvedValue({ todos: [] }),
      };

      orchestrator.registerService('github.service', mockService);
      orchestrator.registerService('ado-github-linker.service', mockService);
      orchestrator.registerService('docs-check.scanner', mockService);
      orchestrator.registerService('org-pulse.reporter', mockService);
      orchestrator.registerService('slack.service', mockService);
      orchestrator.registerService('todo-scanner.service', mockService);
    });

    it('should initialize automatically if not initialized', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      expect(result).toBeDefined();
      expect(result.workflowId).toBe('weekly-org-pulse');
    });

    it('should execute workflow successfully', async () => {
      await orchestrator.initialize();
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      expect(result.success).toBe(true);
      expect(result.agentResults).toBeDefined();
    });

    it('should pass inputs to workflow', async () => {
      const inputs = {
        includeArchived: false,
        minActivityDays: 7,
      };

      const result = await orchestrator.runWorkflow('weekly-org-pulse', inputs);

      expect(result.success).toBe(true);
    });

    it('should return execution result with timing', async () => {
      const result = await orchestrator.runWorkflow('weekly-org-pulse');

      expect(result).toMatchObject({
        workflowId: expect.any(String),
        startTime: expect.any(Date),
        endTime: expect.any(Date),
        duration: expect.any(Number),
        success: expect.any(Boolean),
        agentResults: expect.any(Array),
        outputs: expect.any(Array),
      });
    });
  });

  describe('runAgent', () => {
    beforeEach(() => {
      const mockService = {
        calculateHealthScore: jest.fn().mockResolvedValue({ score: 85 }),
      };

      orchestrator.registerService('github.service', mockService);
    });

    it('should execute individual agent', async () => {
      const result = await orchestrator.runAgent('repository-health-scanner', {
        repository: 'test-repo',
      });

      expect(result).toBeDefined();
      expect(result.agentId).toBe('repository-health-scanner');
    });

    it('should initialize if not initialized', async () => {
      const result = await orchestrator.runAgent('repository-health-scanner');

      expect(result).toBeDefined();
    });

    it('should throw error for non-existent agent', async () => {
      await orchestrator.initialize();

      await expect(
        orchestrator.runAgent('non-existent-agent'),
      ).rejects.toThrow('Agent not found');
    });
  });

  describe('loadPlugin', () => {
    it('should load a specific plugin', async () => {
      await orchestrator.loadPlugin('repository-operations');

      const plugins = orchestrator.getPlugins();
      const loadedPlugin = plugins.find((p) => p.id === 'repository-operations');

      expect(loadedPlugin).toBeDefined();
    });
  });

  describe('unloadPlugin', () => {
    it('should unload a plugin', async () => {
      await orchestrator.initialize();
      const pluginsBefore = orchestrator.getPlugins().length;

      const result = orchestrator.unloadPlugin('repository-operations');

      expect(result).toBe(true);
      const pluginsAfter = orchestrator.getPlugins().length;
      expect(pluginsAfter).toBe(pluginsBefore - 1);
    });

    it('should return false for non-existent plugin', async () => {
      await orchestrator.initialize();

      const result = orchestrator.unloadPlugin('non-existent-plugin');

      expect(result).toBe(false);
    });
  });

  describe('getWorkflows', () => {
    it('should return all workflows', async () => {
      await orchestrator.initialize();
      const workflows = orchestrator.getWorkflows();

      expect(workflows.length).toBeGreaterThan(0);
      workflows.forEach((workflow) => {
        expect(workflow.id).toBeDefined();
        expect(workflow.name).toBeDefined();
      });
    });
  });

  describe('getAgents', () => {
    it('should return all agents', async () => {
      await orchestrator.initialize();
      const agents = orchestrator.getAgents();

      expect(agents.length).toBeGreaterThan(0);
      agents.forEach((agent) => {
        expect(agent.id).toBeDefined();
        expect(agent.name).toBeDefined();
        expect(agent.capabilities).toBeDefined();
      });
    });
  });

  describe('getPlugins', () => {
    it('should return all plugins', async () => {
      await orchestrator.initialize();
      const plugins = orchestrator.getPlugins();

      expect(plugins.length).toBeGreaterThan(0);
      plugins.forEach((plugin) => {
        expect(plugin.id).toBeDefined();
        expect(plugin.name).toBeDefined();
      });
    });
  });

  describe('getStats', () => {
    it('should return statistics', async () => {
      await orchestrator.initialize();
      const stats = orchestrator.getStats();

      expect(stats).toMatchObject({
        plugins: expect.any(Number),
        agents: expect.any(Number),
        workflows: expect.any(Number),
        categories: expect.any(Number),
      });
    });

    it('should include service statistics', () => {
      orchestrator.registerService('test-service', {});
      const stats = orchestrator.getStats();

      expect(stats.services).toContain('test-service');
      expect(stats.registeredServices).toBeGreaterThanOrEqual(1);
    });
  });

  describe('healthCheck', () => {
    it('should return unhealthy before initialization', async () => {
      const health = await orchestrator.healthCheck();

      expect(health.status).toBe('unhealthy');
      expect(health.initialized).toBe(false);
    });

    it('should return healthy after initialization', async () => {
      await orchestrator.initialize();
      const health = await orchestrator.healthCheck();

      expect(health.status).toBe('healthy');
      expect(health.initialized).toBe(true);
    });

    it('should include stats in health check', async () => {
      await orchestrator.initialize();
      const health = await orchestrator.healthCheck();

      expect(health.stats).toBeDefined();
      expect(health.stats.plugins).toBeGreaterThan(0);
      expect(health.stats.agents).toBeGreaterThan(0);
    });

    it('should return degraded if no agents loaded', async () => {
      // Create orchestrator with empty config
      const emptyOrchestrator = new Orchestrator('./automation/orchestration/config');

      // Mock to return empty arrays
      const originalInit = emptyOrchestrator.initialize.bind(emptyOrchestrator);
      emptyOrchestrator.initialize = jest.fn(async () => {
        // Don't load anything
      });

      await emptyOrchestrator.initialize();
      emptyOrchestrator['initialized'] = true;

      const health = await emptyOrchestrator.healthCheck();

      expect(health.status).toBe('degraded');
    });
  });

  describe('integration scenarios', () => {
    beforeEach(() => {
      const mockService = {
        calculateHealthScore: jest.fn().mockResolvedValue({ score: 85 }),
        detectStalePRs: jest.fn().mockResolvedValue({ stalePRs: [] }),
        trackActivity: jest.fn().mockResolvedValue({ commits: 10 }),
        linkWorkItems: jest.fn().mockResolvedValue({ linked: 5 }),
        validateTemplates: jest.fn().mockResolvedValue({ valid: true }),
        aggregateActivity: jest.fn().mockResolvedValue({ total: 100 }),
        routeAlert: jest.fn().mockResolvedValue({ sent: true }),
        scanCode: jest.fn().mockResolvedValue({ todos: [] }),
      };

      orchestrator.registerService('github.service', mockService);
      orchestrator.registerService('ado-github-linker.service', mockService);
      orchestrator.registerService('docs-check.scanner', mockService);
      orchestrator.registerService('org-pulse.reporter', mockService);
      orchestrator.registerService('slack.service', mockService);
      orchestrator.registerService('todo-scanner.service', mockService);
    });

    it('should handle complete workflow lifecycle', async () => {
      // Initialize
      await orchestrator.initialize();

      // Check health
      const health = await orchestrator.healthCheck();
      expect(health.status).toBe('healthy');

      // Run workflow
      const result = await orchestrator.runWorkflow('weekly-org-pulse');
      expect(result.success).toBe(true);

      // Verify stats
      const stats = orchestrator.getStats();
      expect(stats.workflows).toBeGreaterThan(0);
    });

    it('should support multiple concurrent workflows', async () => {
      await orchestrator.initialize();

      const workflows = ['weekly-org-pulse', 'compliance-audit'];
      const results = await Promise.all(
        workflows.map((id) => orchestrator.runWorkflow(id)),
      );

      expect(results.length).toBe(2);
      results.forEach((result) => {
        expect(result).toBeDefined();
        expect(result.workflowId).toBeDefined();
      });
    });

    it('should maintain state across multiple operations', async () => {
      await orchestrator.initialize();

      // Load plugin
      await orchestrator.loadPlugin('repository-operations');

      // Run workflow
      await orchestrator.runWorkflow('weekly-org-pulse');

      // Unload plugin
      orchestrator.unloadPlugin('communication-hub');

      // Stats should reflect all operations
      const stats = orchestrator.getStats();
      expect(stats).toBeDefined();
    });
  });
});
