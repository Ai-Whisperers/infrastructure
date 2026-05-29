/**
 * Workflow Runner - Orchestrates multi-agent workflows
 * Implements hybrid model orchestration: Sonnet (planning) → Haiku (execution) → Sonnet (review)
 */

import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import {
  Workflow,
  WorkflowAgent,
  WorkflowExecutionResult,
  AgentExecutionResult,
  WorkflowRegistry,
} from './types';
import { PluginLoader } from './plugin-loader';
import { AgentExecutor } from './agent-executor';

export class WorkflowRunner {
  private workflowRegistry: WorkflowRegistry = new Map();
  private pluginLoader: PluginLoader;
  private agentExecutor: AgentExecutor;
  private configPath: string;

  constructor(
    pluginLoader: PluginLoader,
    agentExecutor: AgentExecutor,
    configPath: string = './automation/orchestration/config',
  ) {
    this.pluginLoader = pluginLoader;
    this.agentExecutor = agentExecutor;
    this.configPath = configPath;
  }

  /**
   * Load workflows from configuration
   */
  async loadWorkflows(): Promise<void> {
    const workflowsConfig = this.loadConfig<{ workflows: Workflow[] }>(
      'workflows.json',
    );

    for (const workflow of workflowsConfig.workflows) {
      if (workflow.enabled) {
        this.workflowRegistry.set(workflow.id, workflow);
      }
    }

    console.log(
      `✓ Loaded ${this.workflowRegistry.size} workflows`,
    );
  }

  /**
   * Execute a workflow by ID
   */
  async executeWorkflow(
    workflowId: string,
    inputs?: Record<string, any>,
  ): Promise<WorkflowExecutionResult> {
    const workflow = this.workflowRegistry.get(workflowId);
    if (!workflow) {
      throw new Error(`Workflow not found: ${workflowId}`);
    }

    const startTime = new Date();
    console.log(`\n━━━ Workflow Started: ${workflow.name} ━━━`);
    console.log(`Description: ${workflow.description}`);
    console.log(`Agents: ${workflow.agents.length}\n`);

    try {
      // Execute workflow phases
      const agentResults = await this.executeWorkflowPhases(
        workflow,
        inputs,
      );

      // Generate outputs
      const outputs = await this.generateOutputs(
        workflow,
        agentResults,
        startTime,
      );

      const endTime = new Date();
      const duration = endTime.getTime() - startTime.getTime();

      const result: WorkflowExecutionResult = {
        workflowId: workflow.id,
        startTime,
        endTime,
        duration,
        success: agentResults.every((r) => r.success),
        agentResults,
        outputs,
      };

      console.log(
        `\n✓ Workflow Completed: ${workflow.name} (${duration}ms)`,
      );
      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

      return result;
    } catch (error) {
      const endTime = new Date();
      const duration = endTime.getTime() - startTime.getTime();

      console.error(
        `\n✗ Workflow Failed: ${workflow.name}`,
        error,
      );
      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

      return {
        workflowId: workflow.id,
        startTime,
        endTime,
        duration,
        success: false,
        agentResults: [],
        outputs: [],
        error: error as Error,
      };
    }
  }

  /**
   * Execute workflow phases with parallel and sequential execution
   */
  private async executeWorkflowPhases(
    workflow: Workflow,
    inputs?: Record<string, any>,
  ): Promise<AgentExecutionResult[]> {
    // Group agents by phase
    const phaseGroups = this.groupAgentsByPhase(workflow.agents);
    const allResults: AgentExecutionResult[] = [];
    const completedAgents = new Set<string>();
    const previousResults: Record<string, any> = {};

    // Execute each phase
    for (const [phase, workflowAgents] of phaseGroups) {
      console.log(`\n─── Phase: ${phase} ───`);

      // Separate parallel and sequential agents
      const parallelAgents = workflowAgents.filter((wa) => wa.parallel);
      const sequentialAgents = workflowAgents.filter((wa) => !wa.parallel);

      // Execute parallel agents
      if (parallelAgents.length > 0) {
        const agents = parallelAgents
          .map((wa) => this.pluginLoader.getAgent(wa.id))
          .filter((a) => a !== undefined);

        const results = await this.agentExecutor.executeParallel(
          agents,
          {
            workflowId: workflow.id,
            phase,
            inputs,
            previousResults,
            timestamp: new Date(),
          },
        );

        allResults.push(...results);
        results.forEach((r) => {
          completedAgents.add(r.agentId);
          if (r.success && r.output) {
            previousResults[r.agentId] = r.output;
          }
        });
      }

      // Execute sequential agents
      if (sequentialAgents.length > 0) {
        for (const workflowAgent of sequentialAgents) {
          // Check dependencies
          if (
            !this.agentExecutor.canExecute(
              workflowAgent.id,
              workflowAgent.depends_on,
              completedAgents,
            )
          ) {
            console.warn(
              `⚠ Skipping agent ${workflowAgent.id}: dependencies not met`,
            );
            continue;
          }

          const agent = this.pluginLoader.getAgent(workflowAgent.id);
          if (!agent) {
            console.warn(`⚠ Agent not found: ${workflowAgent.id}`);
            continue;
          }

          const result = await this.agentExecutor.executeAgent(agent, {
            workflowId: workflow.id,
            agentId: agent.id,
            phase,
            inputs,
            previousResults,
            timestamp: new Date(),
          });

          allResults.push(result);
          completedAgents.add(result.agentId);

          if (result.success && result.output) {
            previousResults[result.agentId] = result.output;
          }
        }
      }
    }

    return allResults;
  }

  /**
   * Group workflow agents by phase
   */
  private groupAgentsByPhase(
    agents: WorkflowAgent[],
  ): Map<string, WorkflowAgent[]> {
    const groups = new Map<string, WorkflowAgent[]>();

    for (const agent of agents) {
      const existing = groups.get(agent.phase) || [];
      existing.push(agent);
      groups.set(agent.phase, existing);
    }

    return groups;
  }

  /**
   * Generate workflow outputs
   */
  private async generateOutputs(
    workflow: Workflow,
    agentResults: AgentExecutionResult[],
    startTime: Date,
  ): Promise<Array<{ type: string; path: string; success: boolean }>> {
    const outputs: Array<{ type: string; path: string; success: boolean }> = [];

    for (const output of workflow.outputs) {
      try {
        const path = this.interpolatePath(output.path || '', startTime);

        switch (output.type) {
          case 'json':
            await this.writeJsonOutput(path, {
              workflow: workflow.id,
              timestamp: startTime.toISOString(),
              results: agentResults,
            });
            break;

          case 'markdown':
            await this.writeMarkdownOutput(path, workflow, agentResults);
            break;

          case 'log':
            await this.writeLogOutput(path, workflow, agentResults);
            break;

          default:
            console.warn(`Unknown output type: ${output.type}`);
            continue;
        }

        outputs.push({ type: output.type, path, success: true });
        console.log(`✓ Output generated: ${output.type} → ${path}`);
      } catch (error) {
        console.error(`✗ Failed to generate output: ${output.type}`, error);
        outputs.push({
          type: output.type,
          path: output.path || '',
          success: false,
        });
      }
    }

    return outputs;
  }

  /**
   * Write JSON output
   */
  private async writeJsonOutput(path: string, data: any): Promise<void> {
    const fullPath = join(process.cwd(), path);
    writeFileSync(fullPath, JSON.stringify(data, null, 2));
  }

  /**
   * Write Markdown output
   */
  private async writeMarkdownOutput(
    path: string,
    workflow: Workflow,
    results: AgentExecutionResult[],
  ): Promise<void> {
    const content = [
      `# ${workflow.name}`,
      ``,
      `**Generated:** ${new Date().toISOString()}`,
      `**Workflow:** ${workflow.id}`,
      ``,
      `## Results`,
      ``,
      ...results.map((r) => {
        const status = r.success ? '✓' : '✗';
        return `- ${status} **${r.agentId}** (${r.duration}ms)`;
      }),
      ``,
      `## Details`,
      ``,
      ...results.map((r) => {
        return [
          `### ${r.agentId}`,
          ``,
          `- **Status:** ${r.success ? 'Success' : 'Failed'}`,
          `- **Duration:** ${r.duration}ms`,
          `- **Phase:** ${r.metadata?.phase || 'N/A'}`,
          r.error ? `- **Error:** ${r.error.message}` : '',
          ``,
        ].join('\n');
      }),
    ].join('\n');

    const fullPath = join(process.cwd(), path);
    writeFileSync(fullPath, content);
  }

  /**
   * Write log output
   */
  private async writeLogOutput(
    path: string,
    workflow: Workflow,
    results: AgentExecutionResult[],
  ): Promise<void> {
    const logs = results.map((r) => {
      const timestamp = new Date().toISOString();
      const status = r.success ? 'SUCCESS' : 'FAILED';
      const error = r.error ? ` | Error: ${r.error.message}` : '';
      return `[${timestamp}] ${status} | ${r.agentId} | ${r.duration}ms${error}`;
    });

    const content = logs.join('\n') + '\n';
    const fullPath = join(process.cwd(), path);
    writeFileSync(fullPath, content);
  }

  /**
   * Interpolate variables in output paths
   */
  private interpolatePath(path: string, timestamp: Date): string {
    return path
      .replace('{date}', timestamp.toISOString().split('T')[0])
      .replace('{timestamp}', timestamp.getTime().toString())
      .replace('{datetime}', timestamp.toISOString().replace(/[:.]/g, '-'));
  }

  /**
   * Load configuration file
   */
  private loadConfig<T>(filename: string): T {
    const filePath = join(process.cwd(), this.configPath, filename);
    const content = readFileSync(filePath, 'utf-8');
    return JSON.parse(content) as T;
  }

  /**
   * Get all workflows
   */
  getAllWorkflows(): Workflow[] {
    return Array.from(this.workflowRegistry.values());
  }

  /**
   * Get workflow by ID
   */
  getWorkflow(workflowId: string): Workflow | undefined {
    return this.workflowRegistry.get(workflowId);
  }

  /**
   * Get runner statistics
   */
  getStats() {
    return {
      workflows: this.workflowRegistry.size,
      workflowIds: Array.from(this.workflowRegistry.keys()),
    };
  }
}
