# Orchestration Integration Guide

## Integrating the Orchestration System with Existing Services

This guide shows how to integrate the new orchestration platform with your existing NestJS services in the `services/jobs/` directory.

## Step 1: Create Orchestration Module

Create `services/jobs/src/orchestration/orchestration.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { orchestrator } from '../../../../automation/orchestration';
import { IntegrationsModule } from '../integrations/integrations.module';
import { ReportersModule } from '../reporters/reporters.module';
import { ScannersModule } from '../scanners/scanners.module';
import { GitHubService } from '../integrations/github.service';
import { SlackService } from '../integrations/slack.service';
import { AzureDevOpsService } from '../integrations/azure-devops.service';
import { TodoScannerService } from '../integrations/todo-scanner.service';
import { AdoGithubLinkerService } from '../sync/ado-github-linker.service';
import { OrgPulseReporter } from '../reporters/org-pulse.reporter';
import { GithubHealthScanner } from '../scanners/github-health.scanner';
import { DocsCheckScanner } from '../scanners/docs-check.scanner';

@Module({
  imports: [IntegrationsModule, ReportersModule, ScannersModule],
  providers: [
    {
      provide: 'ORCHESTRATOR',
      useFactory: async (
        githubService: GitHubService,
        slackService: SlackService,
        azureDevOpsService: AzureDevOpsService,
        todoScannerService: TodoScannerService,
        adoGithubLinker: AdoGithubLinkerService,
        orgPulseReporter: OrgPulseReporter,
        githubHealthScanner: GithubHealthScanner,
        docsCheckScanner: DocsCheckScanner,
      ) => {
        // Register all services
        orchestrator.registerService('github.service', githubService);
        orchestrator.registerService('slack.service', slackService);
        orchestrator.registerService('azure-devops.service', azureDevOpsService);
        orchestrator.registerService('todo-scanner.service', todoScannerService);
        orchestrator.registerService('ado-github-linker.service', adoGithubLinker);
        orchestrator.registerService('org-pulse.reporter', orgPulseReporter);
        orchestrator.registerService('github-health.scanner', githubHealthScanner);
        orchestrator.registerService('docs-check.scanner', docsCheckScanner);

        // Initialize orchestrator
        await orchestrator.initialize();

        return orchestrator;
      },
      inject: [
        GitHubService,
        SlackService,
        AzureDevOpsService,
        TodoScannerService,
        AdoGithubLinkerService,
        OrgPulseReporter,
        GithubHealthScanner,
        DocsCheckScanner,
      ],
    },
  ],
  exports: ['ORCHESTRATOR'],
})
export class OrchestrationModule {}
```

## Step 2: Update App Module

Add to `services/jobs/src/app.module.ts`:

```typescript
import { OrchestrationModule } from './orchestration/orchestration.module';

@Module({
  imports: [
    // ... existing imports
    OrchestrationModule,
  ],
  // ...
})
export class AppModule {}
```

## Step 3: Create Orchestration Controller

Create `services/jobs/src/orchestration/orchestration.controller.ts`:

```typescript
import { Controller, Post, Get, Body, Param, Inject } from '@nestjs/common';
import { Orchestrator } from '../../../../automation/orchestration';

@Controller('api/orchestration')
export class OrchestrationController {
  constructor(@Inject('ORCHESTRATOR') private orchestrator: Orchestrator) {}

  @Get('workflows')
  async listWorkflows() {
    return {
      workflows: this.orchestrator.getWorkflows().map((w) => ({
        id: w.id,
        name: w.name,
        description: w.description,
        enabled: w.enabled,
      })),
    };
  }

  @Get('agents')
  async listAgents() {
    return {
      agents: this.orchestrator.getAgents().map((a) => ({
        id: a.id,
        name: a.name,
        category: a.category,
        capabilities: a.capabilities,
      })),
    };
  }

  @Get('plugins')
  async listPlugins() {
    return {
      plugins: this.orchestrator.getPlugins(),
    };
  }

  @Post('workflows/:workflowId/execute')
  async executeWorkflow(
    @Param('workflowId') workflowId: string,
    @Body() inputs: Record<string, any>,
  ) {
    const result = await this.orchestrator.runWorkflow(workflowId, inputs);

    return {
      success: result.success,
      duration: result.duration,
      agentResults: result.agentResults.map((r) => ({
        agentId: r.agentId,
        success: r.success,
        duration: r.duration,
      })),
      outputs: result.outputs,
    };
  }

  @Post('agents/:agentId/execute')
  async executeAgent(
    @Param('agentId') agentId: string,
    @Body() inputs: Record<string, any>,
  ) {
    const result = await this.orchestrator.runAgent(agentId, inputs);
    return result;
  }

  @Get('health')
  async healthCheck() {
    return await this.orchestrator.healthCheck();
  }

  @Get('stats')
  async getStats() {
    return this.orchestrator.getStats();
  }
}
```

## Step 4: Adapt Existing Services

### Example: GitHub Service

Update `services/jobs/src/integrations/github.service.ts`:

```typescript
@Injectable()
export class GitHubService {
  // ... existing methods

  // Add methods for agent capabilities
  async calculateHealthScore(inputs?: any, previousResults?: any) {
    const repos = await this.getRepositories();
    const scores = await Promise.all(
      repos.map(async (repo) => {
        // Calculate health metrics
        const activity = await this.getRecentActivity(repo.name);
        const prs = await this.getPullRequests(repo.name);
        const issues = await this.getIssues(repo.name);

        return {
          repository: repo.name,
          score: this.computeScore({ activity, prs, issues }),
          metrics: { activity, openPRs: prs.length, openIssues: issues.length },
        };
      }),
    );

    return { scores, average: this.average(scores.map((s) => s.score)) };
  }

  async detectStalePRs(inputs?: any, previousResults?: any) {
    const repos = inputs?.repositories || await this.getRepositoryNames();
    const stalePRs = [];

    for (const repo of repos) {
      const prs = await this.getPullRequests(repo);
      const stale = prs.filter((pr) => this.isStale(pr));
      stalePRs.push(...stale.map((pr) => ({ ...pr, repository: repo })));
    }

    return { stalePRs, count: stalePRs.length };
  }

  async trackActivity(inputs?: any, previousResults?: any) {
    const days = inputs?.days || 7;
    const activity = await this.getActivitySince(new Date(Date.now() - days * 86400000));

    return {
      period: `${days} days`,
      commits: activity.commits,
      prs: activity.pullRequests,
      issues: activity.issues,
      contributors: activity.uniqueContributors,
    };
  }

  private computeScore(metrics: any): number {
    // Implement scoring logic
    return Math.min(100, (metrics.activity * 0.5 + (100 - metrics.openPRs * 2)));
  }

  private isStale(pr: any): boolean {
    const daysSinceUpdate = (Date.now() - new Date(pr.updated_at).getTime()) / 86400000;
    return daysSinceUpdate > 14;
  }
}
```

## Step 5: Add Claude Commands

Create `.claude/commands/run-org-pulse.md`:

```markdown
# Run Org Pulse

Execute the weekly organization pulse workflow.

## Script
```bash
npx ts-node automation/orchestration/workflows/weekly-org-pulse.ts
```

## API Call
```bash
curl -X POST http://localhost:4000/api/orchestration/workflows/weekly-org-pulse/execute \
  -H "Content-Type: application/json" \
  -d '{"includeArchived": false, "minActivityDays": 7}'
```
``'

Update `.claude/settings.json`:

```json
{
  "commands": {
    "excalibur-sync": ".claude/commands/excalibur-sync.md",
    "weekly-health": ".claude/commands/weekly-health.md",
    "ado-sync": ".claude/commands/ado-sync.md",
    "docs-coverage": ".claude/commands/docs-coverage.md",
    "run-org-pulse": ".claude/commands/run-org-pulse.md",
    "compliance-audit": ".claude/commands/compliance-audit.md"
  }
}
```

## Step 6: Testing

### Test Orchestrator Initialization

```bash
cd services/jobs
npm run start:dev
```

Check logs for:
```
━━━ Initializing Orchestration System ━━━
✓ Loaded 4/4 plugins
✓ Loaded 4 workflows
📊 System Statistics:
   Plugins: 4
   Agents: 6
   Workflows: 4
   Services: 8
```

### Test API Endpoints

```bash
# List workflows
curl http://localhost:4000/api/orchestration/workflows

# List agents
curl http://localhost:4000/api/orchestration/agents

# Health check
curl http://localhost:4000/api/orchestration/health

# Execute workflow
curl -X POST http://localhost:4000/api/orchestration/workflows/weekly-org-pulse/execute \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Test Direct Execution

```bash
# Run workflow directly
npx ts-node automation/orchestration/workflows/weekly-org-pulse.ts

# Run compliance audit
npx ts-node automation/orchestration/workflows/compliance-audit.ts
```

## Step 7: Dashboard Integration

Update `apps/dashboard/dashboard.js`:

```javascript
// Add orchestration section
async function loadOrchestrationStatus() {
  const response = await fetch('http://localhost:4000/api/orchestration/health');
  const health = await response.json();

  document.getElementById('orchestration-status').innerHTML = `
    <div class="status ${health.status}">
      <h3>Orchestration System</h3>
      <p>Status: ${health.status}</p>
      <p>Plugins: ${health.stats.plugins}</p>
      <p>Agents: ${health.stats.agents}</p>
      <p>Workflows: ${health.stats.workflows}</p>
    </div>
  `;
}

// Add workflow execution
async function executeWorkflow(workflowId) {
  const response = await fetch(
    `http://localhost:4000/api/orchestration/workflows/${workflowId}/execute`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }
  );
  const result = await response.json();

  alert(`Workflow ${result.success ? 'succeeded' : 'failed'} in ${result.duration}ms`);
  return result;
}
```

## Troubleshooting

### Service Registration Fails

Check that service is properly injected:
```typescript
// Verify in orchestration.module.ts
inject: [GitHubService, SlackService, ...],
```

### Agent Execution Fails

Verify capability mapping in `agent-executor.ts`:
```typescript
const capabilityMap: Record<string, string> = {
  'health-score-calculation': 'calculateHealthScore',
  // Add your capability mappings
};
```

### Workflow Not Found

Check `config/workflows.json` for correct workflow definition and `enabled: true`.

## Next Steps

1. ✅ Services integrated
2. ✅ Controller created
3. ✅ Claude commands added
4. ✅ Dashboard updated
5. 📋 Monitor production usage
6. 📋 Plan MCP server migration (see MCP_EVOLUTION_ROADMAP.md)

---

**Last Updated:** 2025-10-24
