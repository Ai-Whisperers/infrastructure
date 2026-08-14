/**
 * Plugin Loader - Dynamic loading of orchestration plugins
 * Implements progressive disclosure pattern from agents repo
 */

import { readFileSync } from 'fs';
import { join } from 'path';
import {
  Plugin,
  Agent,
  PluginRegistry,
  AgentRegistry,
  PluginLoadResult,
} from './types';

export class PluginLoader {
  private pluginRegistry: PluginRegistry = new Map();
  private agentRegistry: AgentRegistry = new Map();
  private configPath: string;

  constructor(configPath: string = './automation/orchestration/config') {
    this.configPath = configPath;
  }

  /**
   * Load all plugins from configuration
   * Implements lazy loading - only loads metadata initially
   */
  async loadPlugins(): Promise<PluginLoadResult[]> {
    const pluginsConfig = this.loadConfig<{ plugins: Plugin[] }>('plugins.json');
    const agentsConfig = this.loadConfig<{ agents: Agent[] }>('agents.json');

    const results: PluginLoadResult[] = [];

    for (const plugin of pluginsConfig.plugins) {
      if (!plugin.enabled) {
        continue;
      }

      try {
        const pluginAgents = agentsConfig.agents.filter((agent) =>
          plugin.agents.includes(agent.id),
        );

        // Register plugin
        this.pluginRegistry.set(plugin.id, plugin);

        // Register agents for this plugin
        for (const agent of pluginAgents) {
          if (agent.enabled) {
            this.agentRegistry.set(agent.id, agent);
          }
        }

        results.push({
          pluginId: plugin.id,
          loaded: true,
          agents: pluginAgents,
        });

        console.log(
          `✓ Plugin loaded: ${plugin.name} (${pluginAgents.length} agents)`,
        );
      } catch (error) {
        results.push({
          pluginId: plugin.id,
          loaded: false,
          agents: [],
          error: error as Error,
        });

        console.error(`✗ Failed to load plugin: ${plugin.name}`, error);
      }
    }

    return results;
  }

  /**
   * Load a specific plugin on demand
   */
  async loadPlugin(pluginId: string): Promise<PluginLoadResult> {
    const pluginsConfig = this.loadConfig<{ plugins: Plugin[] }>('plugins.json');
    const plugin = pluginsConfig.plugins.find((p) => p.id === pluginId);

    if (!plugin) {
      throw new Error(`Plugin not found: ${pluginId}`);
    }

    if (this.pluginRegistry.has(pluginId)) {
      return {
        pluginId,
        loaded: true,
        agents: this.getPluginAgents(pluginId),
      };
    }

    const agentsConfig = this.loadConfig<{ agents: Agent[] }>('agents.json');
    const pluginAgents = agentsConfig.agents.filter((agent) =>
      plugin.agents.includes(agent.id),
    );

    this.pluginRegistry.set(pluginId, plugin);

    for (const agent of pluginAgents) {
      if (agent.enabled) {
        this.agentRegistry.set(agent.id, agent);
      }
    }

    return {
      pluginId,
      loaded: true,
      agents: pluginAgents,
    };
  }

  /**
   * Get agent by ID
   */
  getAgent(agentId: string): Agent | undefined {
    return this.agentRegistry.get(agentId);
  }

  /**
   * Get all loaded agents
   */
  getAllAgents(): Agent[] {
    return Array.from(this.agentRegistry.values());
  }

  /**
   * Get agents for a specific plugin
   */
  getPluginAgents(pluginId: string): Agent[] {
    const plugin = this.pluginRegistry.get(pluginId);
    if (!plugin) return [];

    return plugin.agents
      .map((agentId) => this.agentRegistry.get(agentId))
      .filter((agent): agent is Agent => agent !== undefined);
  }

  /**
   * Get all loaded plugins
   */
  getAllPlugins(): Plugin[] {
    return Array.from(this.pluginRegistry.values());
  }

  /**
   * Unload a plugin and its agents
   */
  unloadPlugin(pluginId: string): boolean {
    const plugin = this.pluginRegistry.get(pluginId);
    if (!plugin) return false;

    // Remove agents
    for (const agentId of plugin.agents) {
      this.agentRegistry.delete(agentId);
    }

    // Remove plugin
    this.pluginRegistry.delete(pluginId);

    console.log(`✓ Plugin unloaded: ${plugin.name}`);
    return true;
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
   * Get registry statistics
   */
  getStats() {
    return {
      plugins: this.pluginRegistry.size,
      agents: this.agentRegistry.size,
      categories: new Set(
        Array.from(this.agentRegistry.values()).map((a) => a.category),
      ).size,
    };
  }
}
