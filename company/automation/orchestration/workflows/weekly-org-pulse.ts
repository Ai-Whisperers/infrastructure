/**
 * Weekly Org Pulse Workflow
 * Implements multi-agent orchestration for comprehensive organizational health reporting
 */

import { orchestrator } from '../core/orchestrator';

export async function runWeeklyOrgPulse(): Promise<void> {
  console.log('🎯 Starting Weekly Org Pulse Workflow...\n');

  try {
    const result = await orchestrator.runWorkflow('weekly-org-pulse', {
      // Optional inputs
      includeArchived: false,
      minActivityDays: 7,
      reportFormat: 'markdown',
    });

    if (result.success) {
      console.log('\n✅ Weekly Org Pulse completed successfully!');
      console.log(`   Duration: ${result.duration}ms`);
      console.log(`   Agents executed: ${result.agentResults.length}`);
      console.log(`   Outputs generated: ${result.outputs.length}`);

      // Log output paths
      result.outputs.forEach((output) => {
        console.log(`   📄 ${output.type}: ${output.path}`);
      });
    } else {
      console.error('\n❌ Weekly Org Pulse failed!');
      console.error(`   Error: ${result.error?.message}`);
    }
  } catch (error) {
    console.error('❌ Workflow execution error:', error);
    throw error;
  }
}

// CLI execution
if (require.main === module) {
  runWeeklyOrgPulse()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('Fatal error:', error);
      process.exit(1);
    });
}
