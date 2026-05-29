# AI-Whisperers Orchestration & Automation Platform

> Simple, non-overengineered multi-agent orchestration system inspired by [wshobson/agents](https://github.com/wshobson/agents)

## Overview

This orchestration platform provides intelligent automation for the AI-Whisperers organization through a plugin-based, multi-agent architecture. It seamlessly integrates with existing NestJS services while providing a clean abstraction for complex workflow automation.

### Key Features

- **Plugin-Based Architecture:** Modular agents loaded only when needed
- **Multi-Agent Workflows:** Orchestrate complex tasks across specialized agents
- **Progressive Disclosure:** Metadata → Instructions → Resources (minimize context)
- **Hybrid Model Strategy:** Haiku for execution, Sonnet for planning/review
- **NestJS Integration:** Direct integration with existing services
- **Type-Safe:** Full TypeScript with comprehensive type definitions
- **Future-Ready:** Clear evolution path to full MCP server (see roadmap)

## Architecture

```
automation/
├── orchestration/
│   ├── config/              # JSON-based configurations
│   │   ├── agents.json      # Agent definitions (6 agents)
│   │   ├── workflows.json   # Workflow orchestrations (4 workflows)
│   │   └── plugins.json     # Plugin registry (4 plugins)
│   ├── core/                # Core orchestration engine
│   │   ├── types.ts         # Type definitions
│   │   ├── plugin-loader.ts # Dynamic plugin loading
│   │   ├── agent-executor.ts# Agent execution engine
│   │   ├── workflow-runner.ts# Workflow orchestration
│   │   └── orchestrator.ts  # Main coordinator
│   ├── agents/              # Agent implementations
│   │   ├── repository-health/
│   │   ├── documentation-sync/
│   │   ├── ado-integration/
│   │   └── slack-notifier/
│   ├── workflows/           # Workflow implementations
│   │   ├── weekly-org-pulse.ts
│   │   └── compliance-audit.ts
│   └── index.ts            # Public API
├── MCP_EVOLUTION_ROADMAP.md # Future MCP server roadmap
└── README.md               # This file
```

## Quick Start

### Installation

```bash
# Already installed with root project
cd Company-Information
npm install
```

### Initialize the Orchestrator

```typescript
import { orchestrator } from './automation/orchestration';

// Initialize system (loads plugins, agents, workflows)
await orchestrator.initialize();

// Run a workflow
const result = await orchestrator.runWorkflow('weekly-org-pulse', {
  includeArchived: false,
  minActivityDays: 7,
});

console.log('Workflow completed:', result.success);
```

### Register NestJS Services

```typescript
// In your NestJS module
import { orchestrator } from './automation/orchestration';
import { GitHubService } from './services/integrations/github.service';

// Register services for agent use
orchestrator.registerService('github.service', githubService);
orchestrator.registerService('slack.service', slackService);
orchestrator.registerService('ado-github-linker.service', adoLinkerService);
```

## Available Components

### Plugins (4)

| Plugin | Agents | Category | Purpose |
|--------|--------|----------|---------|
| **repository-operations** | 3 | Core | Repository management & health |
| **integration-sync** | 1 | Integration | External system sync |
| **reporting-analytics** | 1 | Analytics | Report generation |
| **communication-hub** | 1 | Communication | Multi-channel notifications |

### Agents (6)

| Agent ID | Model | Priority | Capabilities |
|----------|-------|----------|--------------|
| `repository-health-scanner` | Haiku | High | Health scores, stale PRs, activity |
| `ado-github-linker` | Haiku | Critical | Work item linking, drift detection |
| `documentation-guardian` | Sonnet | Medium | Template validation, coverage |
| `org-pulse-reporter` | Sonnet | Medium | Activity aggregation, trends |
| `slack-notifier` | Haiku | Low | Alert routing, digests |
| `todo-excavator` | Haiku | Low | Code scanning, TODO sync |

### Workflows (4)

| Workflow ID | Trigger | Agents | Purpose |
|-------------|---------|--------|---------|
| `weekly-org-pulse` | Schedule (Mon 9AM) | 4 | Weekly health report |
| `pr-quality-gate` | PR opened | 3 | PR validation |
| `ado-sync-cycle` | Schedule (6h) | 2 | ADO-GitHub sync |
| `compliance-audit` | Manual | 5 | Full compliance audit |

## Usage Examples

### Run Weekly Org Pulse

```typescript
import { runWeeklyOrgPulse } from './automation/orchestration/workflows/weekly-org-pulse';

await runWeeklyOrgPulse();
```

### Run Compliance Audit

```typescript
import { runComplianceAudit } from './automation/orchestration/workflows/compliance-audit';

await runComplianceAudit({
  repositories: ['Company-Information', 'Comment-Analyzer'],
  skipHealthCheck: false,
  skipDocsCheck: false,
  skipAdoCheck: false,
});
```

### Execute Individual Agent

```typescript
import { orchestrator } from './automation/orchestration';

const result = await orchestrator.runAgent('repository-health-scanner', {
  repository: 'Company-Information',
});

console.log('Health score:', result.output.healthScore);
```

### Create Custom Workflow

```typescript
import { Workflow } from './automation/orchestration/core/types';

const customWorkflow: Workflow = {
  id: 'custom-audit',
  name: 'Custom Repository Audit',
  description: 'Audit specific repositories',
  trigger: { type: 'manual' },
  agents: [
    {
      id: 'repository-health-scanner',
      phase: 'scan',
      timeout: '5m',
    },
    {
      id: 'documentation-guardian',
      phase: 'validate',
      depends_on: ['repository-health-scanner'],
      timeout: '3m',
    },
  ],
  outputs: [
    { type: 'json', path: 'data/reports/custom-audit.json' },
  ],
  enabled: true,
};

// Add to workflows.json or run directly
```

## Configuration

### Agent Definition

```json
{
  "id": "my-custom-agent",
  "name": "My Custom Agent",
  "category": "custom",
  "description": "Does something useful",
  "service": "my-service.service",
  "capabilities": ["capability-1", "capability-2"],
  "model": "haiku",
  "priority": "medium",
  "enabled": true
}
```

### Workflow Definition

```json
{
  "id": "my-workflow",
  "name": "My Workflow",
  "description": "Automated workflow",
  "trigger": {
    "type": "schedule",
    "cron": "0 9 * * 1",
    "timezone": "UTC"
  },
  "agents": [
    {
      "id": "agent-1",
      "phase": "collection",
      "parallel": true,
      "timeout": "5m"
    }
  ],
  "outputs": [
    { "type": "markdown", "path": "data/reports/output.md" }
  ],
  "enabled": true
}
```

## Integration with Existing Services

The orchestration system integrates seamlessly with existing NestJS services:

```typescript
// services/jobs/src/orchestration/orchestration.module.ts
import { Module } from '@nestjs/common';
import { orchestrator } from '../../../automation/orchestration';
import { GitHubService } from '../integrations/github.service';
import { SlackService } from '../integrations/slack.service';

@Module({
  providers: [
    {
      provide: 'ORCHESTRATOR',
      useFactory: async (
        githubService: GitHubService,
        slackService: SlackService,
      ) => {
        orchestrator.registerService('github.service', githubService);
        orchestrator.registerService('slack.service', slackService);
        await orchestrator.initialize();
        return orchestrator;
      },
      inject: [GitHubService, SlackService],
    },
  ],
  exports: ['ORCHESTRATOR'],
})
export class OrchestrationModule {}
```

## Claude Code Integration

Add orchestration commands to `.claude/commands/`:

```markdown
<!-- .claude/commands/run-compliance-audit.md -->
# Compliance Audit Command

Execute full compliance audit across all repositories.

## Script
```bash
npx ts-node automation/orchestration/workflows/compliance-audit.ts
```
``'

## Performance Considerations

### Token Optimization
- **Lazy Loading:** Plugins loaded only when needed
- **Metadata First:** Only essential data in initial load
- **Progressive Disclosure:** Full context loaded on-demand

### Execution Patterns
- **Parallel Execution:** Independent agents run concurrently
- **Sequential Execution:** Dependent agents run in order
- **Timeout Management:** Per-agent timeouts prevent hanging

### Scalability
- **Current:** Single-process execution
- **Future (Phase 4):** Distributed worker pool (see MCP roadmap)

## Monitoring & Observability

```typescript
// Get system statistics
const stats = orchestrator.getStats();
console.log(stats);
// {
//   plugins: 4,
//   agents: 6,
//   workflows: 4,
//   categories: 6,
//   services: 5
// }

// Health check
const health = await orchestrator.healthCheck();
console.log(health.status); // 'healthy' | 'degraded' | 'unhealthy'
```

## Troubleshooting

### Common Issues

**Orchestrator not initializing**
```bash
# Check configuration files
ls automation/orchestration/config/
# Should see: agents.json, workflows.json, plugins.json
```

**Agent execution failing**
```typescript
// Verify service registration
orchestrator.getStats().services
// Should list all registered services
```

**Workflow not found**
```typescript
// List available workflows
orchestrator.getWorkflows().map(w => w.id)
```

## Development

### Adding a New Agent

1. Add agent definition to `config/agents.json`
2. Add to appropriate plugin in `config/plugins.json`
3. Implement service methods for agent capabilities
4. Register service with orchestrator
5. Test agent execution

### Adding a New Workflow

1. Define workflow in `config/workflows.json`
2. Create workflow TypeScript file in `workflows/`
3. Test workflow execution
4. Add Claude command if needed

### Running Tests

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# Test specific workflow
npx ts-node automation/orchestration/workflows/weekly-org-pulse.ts
```

## Roadmap

See [MCP_EVOLUTION_ROADMAP.md](./MCP_EVOLUTION_ROADMAP.md) for the strategic evolution plan:

- **Phase 1:** MCP Protocol Foundation (2-3 weeks)
- **Phase 2:** Advanced Context Management (3-4 weeks)
- **Phase 3:** Real-Time Streaming & Events (4-5 weeks)
- **Phase 4:** Distributed Agent Execution (6-8 weeks)
- **Phase 5:** Advanced Features (8-10 weeks)

**Total Timeline:** 6-8 months to full MCP server

## Design Principles

1. **Simple Over Complex:** Prefer straightforward solutions
2. **Integrate Don't Duplicate:** Use existing services
3. **Progressive Enhancement:** Start simple, evolve to complex
4. **Type Safety:** Comprehensive TypeScript types
5. **Modularity:** Plugins, agents, workflows all composable
6. **Observability:** Rich logging and statistics

## Contributing

When adding new features:

1. Follow existing patterns (plugin → agent → workflow)
2. Update configuration files (JSON-driven)
3. Maintain backward compatibility
4. Add comprehensive types
5. Document in README
6. Consider MCP evolution path

## License

MIT License - see root LICENSE file

## Related Documentation

- [MCP Evolution Roadmap](./MCP_EVOLUTION_ROADMAP.md)
- [wshobson/agents (inspiration)](https://github.com/wshobson/agents)
- [Root Project README](../README.md)
- [NestJS Services](../services/jobs/README.md)

---

**Maintained By:** AI-Whisperers Platform Team
**Version:** 1.0.0
**Last Updated:** 2025-10-24
