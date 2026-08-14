/**
 * Unit tests for AgentExecutor
 */

import { AgentExecutor } from '../agent-executor';
import { Agent, AgentExecutionContext } from '../types';

describe('AgentExecutor', () => {
  let agentExecutor: AgentExecutor;
  let mockService: any;
  let mockAgent: Agent;

  beforeEach(() => {
    agentExecutor = new AgentExecutor();

    // Create mock service
    mockService = {
      calculateHealthScore: jest.fn().mockResolvedValue({ score: 85 }),
      detectStalePRs: jest.fn().mockResolvedValue({ stalePRs: [], count: 0 }),
      trackActivity: jest.fn().mockResolvedValue({ commits: 10, prs: 5 }),
    };

    // Register mock service
    agentExecutor.registerService('test.service', mockService);

    // Create mock agent
    mockAgent = {
      id: 'test-agent',
      name: 'Test Agent',
      category: 'test',
      description: 'Test agent for unit tests',
      service: 'test.service',
      capabilities: ['health-score-calculation', 'stale-pr-detection'],
      model: 'haiku',
      priority: 'medium',
      enabled: true,
    };
  });

  describe('registerService', () => {
    it('should register a service', () => {
      const newService = { method: jest.fn() };
      agentExecutor.registerService('new.service', newService);

      const stats = agentExecutor.getStats();
      expect(stats.services).toContain('new.service');
    });

    it('should increment service count', () => {
      const statsBefore = agentExecutor.getStats();
      agentExecutor.registerService('another.service', {});
      const statsAfter = agentExecutor.getStats();

      expect(statsAfter.registeredServices).toBe(statsBefore.registeredServices + 1);
    });
  });

  describe('executeAgent', () => {
    let context: AgentExecutionContext;

    beforeEach(() => {
      context = {
        workflowId: 'test-workflow',
        agentId: 'test-agent',
        phase: 'test-phase',
        inputs: {},
        timestamp: new Date(),
      };
    });

    it('should execute agent successfully', async () => {
      const result = await agentExecutor.executeAgent(mockAgent, context);

      expect(result.success).toBe(true);
      expect(result.agentId).toBe('test-agent');
      expect(result.duration).toBeGreaterThanOrEqual(0);
      expect(result.output).toBeDefined();
    });

    it('should call service methods for capabilities', async () => {
      await agentExecutor.executeAgent(mockAgent, context);

      expect(mockService.calculateHealthScore).toHaveBeenCalled();
      expect(mockService.detectStalePRs).toHaveBeenCalled();
    });

    it('should pass context to service methods', async () => {
      const inputs = { repository: 'test-repo' };
      const previousResults = { 'prev-agent': { data: 'test' } };

      await agentExecutor.executeAgent(mockAgent, {
        ...context,
        inputs,
        previousResults,
      });

      expect(mockService.calculateHealthScore).toHaveBeenCalledWith(
        inputs,
        previousResults,
      );
    });

    it('should return error result when service not found', async () => {
      const invalidAgent = { ...mockAgent, service: 'non.existent.service' };
      const result = await agentExecutor.executeAgent(invalidAgent, context);

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
      expect(result.error?.message).toContain('Service not found');
    });

    it('should handle service method errors gracefully', async () => {
      mockService.calculateHealthScore.mockRejectedValue(new Error('Service error'));

      const result = await agentExecutor.executeAgent(mockAgent, context);

      // Should not throw, but return error result
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });

    it('should include metadata in result', async () => {
      const result = await agentExecutor.executeAgent(mockAgent, context);

      expect(result.metadata).toMatchObject({
        phase: 'test-phase',
        model: 'haiku',
        priority: 'medium',
      });
    });

    it('should measure execution duration', async () => {
      // Add delay to service
      mockService.calculateHealthScore.mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve({ score: 85 }), 50)),
      );

      const result = await agentExecutor.executeAgent(mockAgent, context);

      expect(result.duration).toBeGreaterThanOrEqual(50);
    });
  });

  describe('executeParallel', () => {
    let agents: Agent[];
    let context: Omit<AgentExecutionContext, 'agentId'>;

    beforeEach(() => {
      agents = [
        mockAgent,
        { ...mockAgent, id: 'test-agent-2', capabilities: ['stale-pr-detection'] },
        { ...mockAgent, id: 'test-agent-3', capabilities: ['health-score-calculation'] },
      ];

      context = {
        workflowId: 'test-workflow',
        phase: 'parallel-phase',
        inputs: {},
        timestamp: new Date(),
      };
    });

    it('should execute multiple agents in parallel', async () => {
      const results = await agentExecutor.executeParallel(agents, context);

      expect(results.length).toBe(3);
      results.forEach((result, index) => {
        expect(result.agentId).toBe(agents[index].id);
      });
    });

    it('should execute faster than sequential', async () => {
      // Add delay to simulate work
      mockService.calculateHealthScore.mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve({ score: 85 }), 100)),
      );

      const startTime = Date.now();
      await agentExecutor.executeParallel(agents, context);
      const parallelDuration = Date.now() - startTime;

      // Parallel should be faster than 3 * 100ms (sequential would be ~300ms)
      expect(parallelDuration).toBeLessThan(250);
    });

    it('should return results for all agents even if some fail', async () => {
      mockService.calculateHealthScore.mockRejectedValue(new Error('Error'));

      const results = await agentExecutor.executeParallel(agents, context);

      expect(results.length).toBe(3);
      expect(results.some((r) => r.success)).toBe(true);
      expect(results.some((r) => !r.success)).toBe(true);
    });
  });

  describe('executeSequential', () => {
    let agents: Agent[];
    let context: Omit<AgentExecutionContext, 'agentId'>;

    beforeEach(() => {
      agents = [
        mockAgent,
        { ...mockAgent, id: 'test-agent-2', capabilities: ['stale-pr-detection'] },
      ];

      context = {
        workflowId: 'test-workflow',
        phase: 'sequential-phase',
        inputs: {},
        timestamp: new Date(),
      };
    });

    it('should execute agents in sequence', async () => {
      const executionOrder: string[] = [];

      mockService.calculateHealthScore.mockImplementation(async () => {
        executionOrder.push('agent-1');
        return { score: 85 };
      });

      mockService.detectStalePRs.mockImplementation(async () => {
        executionOrder.push('agent-2');
        return { count: 0 };
      });

      await agentExecutor.executeSequential(agents, context);

      expect(executionOrder).toEqual(['agent-1', 'agent-2']);
    });

    it('should pass previous results to next agent', async () => {
      await agentExecutor.executeSequential(agents, context);

      // Second call should have previous results
      const secondCallArgs = mockService.detectStalePRs.mock.calls[0];
      expect(secondCallArgs[1]).toBeDefined();
      expect(secondCallArgs[1]['test-agent']).toBeDefined();
    });

    it('should continue execution even if one agent fails', async () => {
      mockService.calculateHealthScore.mockRejectedValue(new Error('Error'));

      const results = await agentExecutor.executeSequential(agents, context);

      expect(results.length).toBe(2);
      expect(results[0].success).toBe(false);
      expect(results[1].success).toBe(true);
    });
  });

  describe('canExecute', () => {
    let completedAgents: Set<string>;

    beforeEach(() => {
      completedAgents = new Set(['agent-1', 'agent-2']);
    });

    it('should return true when no dependencies', () => {
      const result = agentExecutor.canExecute('agent-3', [], completedAgents);

      expect(result).toBe(true);
    });

    it('should return true when all dependencies met', () => {
      const result = agentExecutor.canExecute(
        'agent-3',
        ['agent-1', 'agent-2'],
        completedAgents,
      );

      expect(result).toBe(true);
    });

    it('should return false when dependencies not met', () => {
      const result = agentExecutor.canExecute(
        'agent-3',
        ['agent-1', 'agent-4'],
        completedAgents,
      );

      expect(result).toBe(false);
    });

    it('should return false when no dependencies completed', () => {
      const result = agentExecutor.canExecute(
        'agent-3',
        ['agent-5', 'agent-6'],
        completedAgents,
      );

      expect(result).toBe(false);
    });
  });

  describe('getStats', () => {
    it('should return executor statistics', () => {
      const stats = agentExecutor.getStats();

      expect(stats).toMatchObject({
        registeredServices: expect.any(Number),
        services: expect.any(Array),
      });
    });

    it('should list registered services', () => {
      agentExecutor.registerService('service-1', {});
      agentExecutor.registerService('service-2', {});

      const stats = agentExecutor.getStats();

      expect(stats.services).toContain('service-1');
      expect(stats.services).toContain('service-2');
    });
  });

  describe('capability mapping', () => {
    it('should handle unknown capabilities gracefully', async () => {
      const agentWithUnknown = {
        ...mockAgent,
        capabilities: ['unknown-capability'],
      };

      const context: AgentExecutionContext = {
        workflowId: 'test',
        agentId: 'test',
        phase: 'test',
        timestamp: new Date(),
      };

      const result = await agentExecutor.executeAgent(agentWithUnknown, context);

      // Should not throw, just skip unknown capabilities
      expect(result.success).toBe(true);
    });

    it('should collect results from multiple capabilities', async () => {
      mockService.calculateHealthScore.mockResolvedValue({ score: 85 });
      mockService.detectStalePRs.mockResolvedValue({ count: 3 });

      const context: AgentExecutionContext = {
        workflowId: 'test',
        agentId: 'test',
        phase: 'test',
        timestamp: new Date(),
      };

      const result = await agentExecutor.executeAgent(mockAgent, context);

      expect(result.output).toBeDefined();
      expect(result.output['health-score-calculation']).toEqual({ score: 85 });
      expect(result.output['stale-pr-detection']).toEqual({ count: 3 });
    });
  });
});
