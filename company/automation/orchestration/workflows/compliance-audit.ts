/**
 * Compliance Audit Workflow
 * Full repository audit for compliance, documentation, and health
 */

import { orchestrator } from '../core/orchestrator';

export async function runComplianceAudit(options?: {
  repositories?: string[];
  skipHealthCheck?: boolean;
  skipDocsCheck?: boolean;
  skipAdoCheck?: boolean;
}): Promise<void> {
  console.log('🔍 Starting Compliance Audit Workflow...\n');

  const inputs = {
    repositories: options?.repositories || [],
    checks: {
      health: !options?.skipHealthCheck,
      documentation: !options?.skipDocsCheck,
      adoSync: !options?.skipAdoCheck,
    },
  };

  try {
    const result = await orchestrator.runWorkflow('compliance-audit', inputs);

    if (result.success) {
      console.log('\n✅ Compliance Audit completed successfully!');
      console.log(`   Duration: ${(result.duration / 1000).toFixed(2)}s`);
      console.log(`   Agents executed: ${result.agentResults.length}`);

      // Analyze results
      const failedAgents = result.agentResults.filter((r) => !r.success);
      if (failedAgents.length > 0) {
        console.log(`\n⚠ ${failedAgents.length} agent(s) had issues:`);
        failedAgents.forEach((agent) => {
          console.log(`   - ${agent.agentId}: ${agent.error?.message}`);
        });
      }

      // Log outputs
      console.log('\n📊 Generated Reports:');
      result.outputs.forEach((output) => {
        const status = output.success ? '✓' : '✗';
        console.log(`   ${status} ${output.type}: ${output.path}`);
      });
    } else {
      console.error('\n❌ Compliance Audit failed!');
      console.error(`   Error: ${result.error?.message}`);
    }
  } catch (error) {
    console.error('❌ Workflow execution error:', error);
    throw error;
  }
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const skipHealth = args.includes('--skip-health');
  const skipDocs = args.includes('--skip-docs');
  const skipAdo = args.includes('--skip-ado');

  runComplianceAudit({
    skipHealthCheck: skipHealth,
    skipDocsCheck: skipDocs,
    skipAdoCheck: skipAdo,
  })
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Fatal error:', error);
      process.exit(1);
    });
}
