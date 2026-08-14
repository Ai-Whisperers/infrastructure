/**
 * Agent Executor - Executes individual agents with context management
 * Integrates with existing NestJS services
 */

import {
  Agent,
  AgentExecutionContext,
  AgentExecutionResult,
} from './types';

export class AgentExecutor {
  private serviceRegistry: Map<string, any> = new Map();

  /**
   * Register a NestJS service for agent execution
   */
  registerService(serviceName: string, serviceInstance: any): void {
    this.serviceRegistry.set(serviceName, serviceInstance);
    console.log(`✓ Service registered: ${serviceName}`);
  }

  /**
   * Execute an agent with given context
   */
  async executeAgent(
    agent: Agent,
    context: AgentExecutionContext,
  ): Promise<AgentExecutionResult> {
    const startTime = Date.now();

    console.log(
      `→ Executing agent: ${agent.name} (${context.phase} phase)`,
    );

    try {
      // Get the service instance
      const service = this.serviceRegistry.get(agent.service);
      if (!service) {
        throw new Error(`Service not found: ${agent.service}`);
      }

      // Execute based on agent capabilities
      const output = await this.executeAgentCapabilities(
        agent,
        service,
        context,
      );

      const duration = Date.now() - startTime;

      const result: AgentExecutionResult = {
        agentId: agent.id,
        success: true,
        duration,
        output,
        metadata: {
          phase: context.phase,
          model: agent.model,
          priority: agent.priority,
        },
      };

      console.log(`✓ Agent completed: ${agent.name} (${duration}ms)`);

      return result;
    } catch (error) {
      const duration = Date.now() - startTime;

      const result: AgentExecutionResult = {
        agentId: agent.id,
        success: false,
        duration,
        error: error as Error,
        metadata: {
          phase: context.phase,
          model: agent.model,
          priority: agent.priority,
        },
      };

      console.error(`✗ Agent failed: ${agent.name}`, error);

      return result;
    }
  }

  /**
   * Execute agent capabilities through service methods
   */
  private async executeAgentCapabilities(
    agent: Agent,
    service: any,
    context: AgentExecutionContext,
  ): Promise<any> {
    // Map agent capabilities to service methods
    const capabilityMap: Record<string, string> = {
      'health-score-calculation': 'calculateHealthScore',
      'stale-pr-detection': 'detectStalePRs',
      'branch-protection-check': 'checkBranchProtection',
      'activity-tracking': 'trackActivity',
      'work-item-linking': 'linkWorkItems',
      'drift-detection': 'detectDrift',
      'automatic-repair': 'repairLinks',
      'pr-commit-parsing': 'parseCommits',
      'template-validation': 'validateTemplates',
      'coverage-analysis': 'analyzeCoverage',
      'auto-generation': 'generateDocs',
      'ci-gate-enforcement': 'enforceGate',
      'activity-aggregation': 'aggregateActivity',
      'contributor-ranking': 'rankContributors',
      'trend-analysis': 'analyzeTrends',
      'multi-format-output': 'generateReport',
      'alert-routing': 'routeAlert',
      'context-enrichment': 'enrichContext',
      'priority-filtering': 'filterByPriority',
      'digest-creation': 'createDigest',
      'code-scanning': 'scanCode',
      'todo-extraction': 'extractTodos',
      'cross-repo-sync': 'syncRepos',
      'tracking-automation': 'automateTasks',
    };

    const results: Record<string, any> = {};

    // Execute each capability
    for (const capability of agent.capabilities) {
      const methodName = capabilityMap[capability];

      if (methodName && typeof service[methodName] === 'function') {
        try {
          results[capability] = await service[methodName](
            context.inputs,
            context.previousResults,
          );
        } catch (error) {
          console.warn(
            `Warning: Capability '${capability}' failed:`,
            error,
          );
          results[capability] = { error: (error as Error).message };
        }
      } else {
        console.warn(
          `Warning: No method found for capability '${capability}'`,
        );
      }
    }

    return results;
  }

  /**
   * Execute multiple agents in parallel
   */
  async executeParallel(
    agents: Agent[],
    context: Omit<AgentExecutionContext, 'agentId'>,
  ): Promise<AgentExecutionResult[]> {
    console.log(`→ Executing ${agents.length} agents in parallel...`);

    const promises = agents.map((agent) =>
      this.executeAgent(agent, { ...context, agentId: agent.id }),
    );

    return Promise.all(promises);
  }

  /**
   * Execute agents sequentially with dependency management
   */
  async executeSequential(
    agents: Agent[],
    context: Omit<AgentExecutionContext, 'agentId'>,
  ): Promise<AgentExecutionResult[]> {
    console.log(`→ Executing ${agents.length} agents sequentially...`);

    const results: AgentExecutionResult[] = [];
    const previousResults: Record<string, any> = {};

    for (const agent of agents) {
      const result = await this.executeAgent(agent, {
        ...context,
        agentId: agent.id,
        previousResults,
      });

      results.push(result);

      // Store result for next agent
      if (result.success && result.output) {
        previousResults[agent.id] = result.output;
      }
    }

    return results;
  }

  /**
   * Check if an agent can execute (dependencies met)
   */
  canExecute(
    agentId: string,
    dependsOn: string[] = [],
    completedAgents: Set<string>,
  ): boolean {
    if (dependsOn.length === 0) return true;

    return dependsOn.every((dep) => completedAgents.has(dep));
  }

  /**
   * Get executor statistics
   */
  getStats() {
    return {
      registeredServices: this.serviceRegistry.size,
      services: Array.from(this.serviceRegistry.keys()),
    };
  }
}
