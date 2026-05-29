/**
 * Core type definitions for the orchestration system
 */

export interface Agent {
  id: string;
  name: string;
  category: string;
  description: string;
  service: string;
  capabilities: string[];
  model: 'haiku' | 'sonnet' | 'opus';
  priority: 'low' | 'medium' | 'high' | 'critical';
  enabled: boolean;
}

export interface WorkflowAgent {
  id: string;
  phase: string;
  parallel?: boolean;
  depends_on?: string[];
  timeout: string;
  condition?: string;
}

export interface WorkflowTrigger {
  type: 'schedule' | 'event' | 'manual';
  cron?: string;
  event?: string;
  command?: string;
  timezone?: string;
}

export interface WorkflowOutput {
  type: 'markdown' | 'json' | 'html' | 'log' | 'github_comment';
  path?: string;
  target?: string;
}

export interface Workflow {
  id: string;
  name: string;
  description: string;
  trigger: WorkflowTrigger;
  agents: WorkflowAgent[];
  outputs: WorkflowOutput[];
  enabled: boolean;
}

export interface Plugin {
  id: string;
  name: string;
  version: string;
  description: string;
  agents: string[];
  dependencies: string[];
  category: string;
  enabled: boolean;
}

export interface AgentExecutionContext {
  workflowId: string;
  agentId: string;
  phase: string;
  inputs?: Record<string, any>;
  previousResults?: Record<string, any>;
  timestamp: Date;
}

export interface AgentExecutionResult {
  agentId: string;
  success: boolean;
  duration: number;
  output?: any;
  error?: Error;
  metadata?: Record<string, any>;
}

export interface WorkflowExecutionResult {
  workflowId: string;
  startTime: Date;
  endTime: Date;
  duration: number;
  success: boolean;
  agentResults: AgentExecutionResult[];
  outputs: Array<{
    type: string;
    path: string;
    success: boolean;
  }>;
  error?: Error;
}

export interface PluginLoadResult {
  pluginId: string;
  loaded: boolean;
  agents: Agent[];
  error?: Error;
}

export type AgentRegistry = Map<string, Agent>;
export type WorkflowRegistry = Map<string, Workflow>;
export type PluginRegistry = Map<string, Plugin>;
