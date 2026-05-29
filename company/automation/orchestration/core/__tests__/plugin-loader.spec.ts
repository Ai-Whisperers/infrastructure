/**
 * Unit tests for PluginLoader
 */

import { PluginLoader } from '../plugin-loader';
import { Agent, Plugin } from '../types';

describe('PluginLoader', () => {
  let pluginLoader: PluginLoader;

  beforeEach(() => {
    pluginLoader = new PluginLoader('./automation/orchestration/config');
  });

  describe('loadPlugins', () => {
    it('should load all enabled plugins', async () => {
      const results = await pluginLoader.loadPlugins();

      expect(results.length).toBeGreaterThan(0);
      expect(results.every((r) => r.loaded)).toBe(true);
    });

    it('should load all agents for each plugin', async () => {
      const results = await pluginLoader.loadPlugins();

      results.forEach((result) => {
        expect(result.pluginId).toBeDefined();
        expect(result.agents).toBeDefined();
        expect(Array.isArray(result.agents)).toBe(true);
      });
    });

    it('should skip disabled plugins', async () => {
      await pluginLoader.loadPlugins();
      const plugins = pluginLoader.getAllPlugins();

      // All loaded plugins should be enabled
      plugins.forEach((plugin) => {
        expect(plugin.enabled).toBe(true);
      });
    });

    it('should register agents in agent registry', async () => {
      await pluginLoader.loadPlugins();
      const agents = pluginLoader.getAllAgents();

      expect(agents.length).toBeGreaterThan(0);
      agents.forEach((agent) => {
        expect(agent.id).toBeDefined();
        expect(agent.name).toBeDefined();
        expect(agent.capabilities).toBeDefined();
      });
    });
  });

  describe('loadPlugin', () => {
    it('should load a specific plugin by ID', async () => {
      const result = await pluginLoader.loadPlugin('repository-operations');

      expect(result.loaded).toBe(true);
      expect(result.pluginId).toBe('repository-operations');
      expect(result.agents.length).toBeGreaterThan(0);
    });

    it('should throw error for non-existent plugin', async () => {
      await expect(
        pluginLoader.loadPlugin('non-existent-plugin'),
      ).rejects.toThrow('Plugin not found');
    });

    it('should return cached result if plugin already loaded', async () => {
      await pluginLoader.loadPlugin('repository-operations');
      const result = await pluginLoader.loadPlugin('repository-operations');

      expect(result.loaded).toBe(true);
    });
  });

  describe('getAgent', () => {
    beforeEach(async () => {
      await pluginLoader.loadPlugins();
    });

    it('should retrieve agent by ID', () => {
      const agent = pluginLoader.getAgent('repository-health-scanner');

      expect(agent).toBeDefined();
      expect(agent?.id).toBe('repository-health-scanner');
      expect(agent?.category).toBe('monitoring');
    });

    it('should return undefined for non-existent agent', () => {
      const agent = pluginLoader.getAgent('non-existent-agent');

      expect(agent).toBeUndefined();
    });

    it('should return agents with correct structure', () => {
      const agent = pluginLoader.getAgent('repository-health-scanner');

      expect(agent).toMatchObject({
        id: expect.any(String),
        name: expect.any(String),
        category: expect.any(String),
        description: expect.any(String),
        service: expect.any(String),
        capabilities: expect.any(Array),
        model: expect.stringMatching(/haiku|sonnet|opus/),
        priority: expect.stringMatching(/low|medium|high|critical/),
        enabled: expect.any(Boolean),
      });
    });
  });

  describe('getAllAgents', () => {
    it('should return all loaded agents', async () => {
      await pluginLoader.loadPlugins();
      const agents = pluginLoader.getAllAgents();

      expect(agents.length).toBeGreaterThan(0);
      expect(agents.every((a) => a.enabled)).toBe(true);
    });

    it('should return empty array before loading', () => {
      const agents = pluginLoader.getAllAgents();

      expect(agents).toEqual([]);
    });
  });

  describe('getPluginAgents', () => {
    beforeEach(async () => {
      await pluginLoader.loadPlugins();
    });

    it('should return agents for a specific plugin', () => {
      const agents = pluginLoader.getPluginAgents('repository-operations');

      expect(agents.length).toBeGreaterThan(0);
      agents.forEach((agent) => {
        expect(['repository-health-scanner', 'documentation-guardian', 'todo-excavator']).toContain(agent.id);
      });
    });

    it('should return empty array for non-existent plugin', () => {
      const agents = pluginLoader.getPluginAgents('non-existent-plugin');

      expect(agents).toEqual([]);
    });
  });

  describe('getAllPlugins', () => {
    it('should return all loaded plugins', async () => {
      await pluginLoader.loadPlugins();
      const plugins = pluginLoader.getAllPlugins();

      expect(plugins.length).toBeGreaterThan(0);
      plugins.forEach((plugin) => {
        expect(plugin).toMatchObject({
          id: expect.any(String),
          name: expect.any(String),
          version: expect.any(String),
          description: expect.any(String),
          agents: expect.any(Array),
          dependencies: expect.any(Array),
          category: expect.any(String),
          enabled: expect.any(Boolean),
        });
      });
    });
  });

  describe('unloadPlugin', () => {
    beforeEach(async () => {
      await pluginLoader.loadPlugins();
    });

    it('should unload a plugin and its agents', () => {
      const pluginsBefore = pluginLoader.getAllPlugins().length;
      const result = pluginLoader.unloadPlugin('repository-operations');

      expect(result).toBe(true);
      const pluginsAfter = pluginLoader.getAllPlugins().length;
      expect(pluginsAfter).toBe(pluginsBefore - 1);
    });

    it('should return false for non-existent plugin', () => {
      const result = pluginLoader.unloadPlugin('non-existent-plugin');

      expect(result).toBe(false);
    });

    it('should remove plugin agents from registry', () => {
      const agentsBefore = pluginLoader.getAllAgents().length;
      pluginLoader.unloadPlugin('repository-operations');
      const agentsAfter = pluginLoader.getAllAgents().length;

      expect(agentsAfter).toBeLessThan(agentsBefore);
    });
  });

  describe('getStats', () => {
    it('should return correct statistics', async () => {
      await pluginLoader.loadPlugins();
      const stats = pluginLoader.getStats();

      expect(stats).toMatchObject({
        plugins: expect.any(Number),
        agents: expect.any(Number),
        categories: expect.any(Number),
      });

      expect(stats.plugins).toBeGreaterThan(0);
      expect(stats.agents).toBeGreaterThan(0);
      expect(stats.categories).toBeGreaterThan(0);
    });

    it('should return zero stats before loading', () => {
      const stats = pluginLoader.getStats();

      expect(stats).toMatchObject({
        plugins: 0,
        agents: 0,
        categories: 0,
      });
    });
  });

  describe('agent model distribution', () => {
    beforeEach(async () => {
      await pluginLoader.loadPlugins();
    });

    it('should have both Haiku and Sonnet models', () => {
      const agents = pluginLoader.getAllAgents();
      const models = agents.map((a) => a.model);

      expect(models).toContain('haiku');
      expect(models).toContain('sonnet');
    });

    it('should use Haiku for execution-focused agents', () => {
      const healthScanner = pluginLoader.getAgent('repository-health-scanner');
      const adoLinker = pluginLoader.getAgent('ado-github-linker');

      expect(healthScanner?.model).toBe('haiku');
      expect(adoLinker?.model).toBe('haiku');
    });

    it('should use Sonnet for complex planning agents', () => {
      const docsGuardian = pluginLoader.getAgent('documentation-guardian');
      const orgPulse = pluginLoader.getAgent('org-pulse-reporter');

      expect(docsGuardian?.model).toBe('sonnet');
      expect(orgPulse?.model).toBe('sonnet');
    });
  });

  describe('agent priority levels', () => {
    beforeEach(async () => {
      await pluginLoader.loadPlugins();
    });

    it('should have critical priority for ADO linker', () => {
      const adoLinker = pluginLoader.getAgent('ado-github-linker');

      expect(adoLinker?.priority).toBe('critical');
    });

    it('should have high priority for health scanner', () => {
      const healthScanner = pluginLoader.getAgent('repository-health-scanner');

      expect(healthScanner?.priority).toBe('high');
    });

    it('should have appropriate priority distribution', () => {
      const agents = pluginLoader.getAllAgents();
      const priorities = agents.map((a) => a.priority);

      expect(priorities).toContain('critical');
      expect(priorities).toContain('high');
      expect(priorities).toContain('medium');
      expect(priorities).toContain('low');
    });
  });
});
