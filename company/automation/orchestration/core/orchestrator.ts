/**
 * Main Orchestrator - Entry point for the orchestration system
 * Coordinates plugin loading, agent execution, and workflow running
 */

import { PluginLoader } from './plugin-loader';
import { AgentExecutor } from './agent-executor';
import { WorkflowRunner } from './workflow-runner';
import { WorkflowExecutionResult } from './types';

export class Orchestrator {
  private pluginLoader: PluginLoader;
  private agentExecutor: AgentExecutor;
  private workflowRunner: WorkflowRunner;
  private initialized: boolean = false;

  constructor(configPath?: string) {
    this.pluginLoader = new PluginLoader(configPath);
    this.agentExecutor = new AgentExecutor();
    this.workflowRunner = new WorkflowRunner(
      this.pluginLoader,
      this.agentExecutor,
      configPath,
    );
  }

  /**
   * Initialize the orchestration system
   */
  async initialize(): Promise<void> {
    if (this.initialized) {
      console.log('⚠ Orchestrator already initialized');
      return;
    }

    console.log('\n━━━ Initializing Orchestration System ━━━\n');

    // Load plugins and agents
    const pluginResults = await this.pluginLoader.loadPlugins();
    const successfulPlugins = pluginResults.filter((r) => r.loaded);

    console.log(
      `✓ Loaded ${successfulPlugins.length}/${pluginResults.length} plugins`,
    );

    // Load workflows
    await this.workflowRunner.loadWorkflows();

    this.initialized = true;

    // Print statistics
    const stats = this.getStats();
    console.log('\n📊 System Statistics:');
    console.log(`   Plugins: ${stats.plugins}`);
    console.log(`   Agents: ${stats.agents}`);
    console.log(`   Workflows: ${stats.workflows}`);
    console.log(`   Services: ${stats.services}`);
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  /**
   * Register a NestJS service for use by agents
   */
  registerService(serviceName: string, serviceInstance: any): void {
    this.agentExecutor.registerService(serviceName, serviceInstance);
  }

  /**
   * Execute a workflow
   */
  async runWorkflow(
    workflowId: string,
    inputs?: Record<string, any>,
  ): Promise<WorkflowExecutionResult> {
    if (!this.initialized) {
      await this.initialize();
    }

    return this.workflowRunner.executeWorkflow(workflowId, inputs);
  }

  /**
   * Execute a specific agent
   */
  async runAgent(
    agentId: string,
    inputs?: Record<string, any>,
  ): Promise<any> {
    if (!this.initialized) {
      await this.initialize();
    }

    const agent = this.pluginLoader.getAgent(agentId);
    if (!agent) {
      throw new Error(`Agent not found: ${agentId}`);
    }

    const result = await this.agentExecutor.executeAgent(agent, {
      workflowId: 'manual',
      agentId,
      phase: 'manual',
      inputs,
      timestamp: new Date(),
    });

    return result;
  }

  /**
   * Load a specific plugin
   */
  async loadPlugin(pluginId: string): Promise<void> {
    await this.pluginLoader.loadPlugin(pluginId);
  }

  /**
   * Unload a plugin
   */
  unloadPlugin(pluginId: string): boolean {
    return this.pluginLoader.unloadPlugin(pluginId);
  }

  /**
   * Get all available workflows
   */
  getWorkflows() {
    return this.workflowRunner.getAllWorkflows();
  }

  /**
   * Get all available agents
   */
  getAgents() {
    return this.pluginLoader.getAllAgents();
  }

  /**
   * Get all loaded plugins
   */
  getPlugins() {
    return this.pluginLoader.getAllPlugins();
  }

  /**
   * Get orchestrator statistics
   */
  getStats() {
    const pluginStats = this.pluginLoader.getStats();
    const executorStats = this.agentExecutor.getStats();
    const workflowStats = this.workflowRunner.getStats();

    return {
      ...pluginStats,
      ...executorStats,
      ...workflowStats,
    };
  }

  /**
   * Health check
   */
  async healthCheck(): Promise<{
    status: 'healthy' | 'degraded' | 'unhealthy';
    initialized: boolean;
    stats: ReturnType<typeof this.getStats>;
  }> {
    const stats = this.getStats();

    let status: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';

    if (!this.initialized) {
      status = 'unhealthy';
    } else if (stats.agents === 0 || stats.workflows === 0) {
      status = 'degraded';
    }

    return {
      status,
      initialized: this.initialized,
      stats,
    };
  }
}

// Export singleton instance
export const orchestrator = new Orchestrator();
