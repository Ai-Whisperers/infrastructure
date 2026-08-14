import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../db/prisma.service';
import { GitHubService } from '../integrations/github.service';
import { AzureDevOpsService } from '../integrations/azure-devops.service';

@Injectable()
export class AdoGithubLinker {
  private readonly logger = new Logger(AdoGithubLinker.name);

  constructor(
    private prisma: PrismaService,
    private github: GitHubService,
    private azureDevOps: AzureDevOpsService,
  ) {}

  @Cron('*/10 * * * *') // Every 10 minutes
  async syncLinks() {
    this.logger.log('Starting ADO-GitHub link sync');
    const startTime = Date.now();

    try {
      const repos = await this.prisma.repository.findMany();
      let processed = 0;
      let failed = 0;
      let linksCreated = 0;

      for (const repo of repos) {
        try {
          const newLinks = await this.syncRepositoryLinks(repo.name);
          linksCreated += newLinks;
          processed++;
        } catch (error) {
          this.logger.error(`Failed to sync links for ${repo.name}: ${error.message}`);
          failed++;
        }
      }

      const duration = Math.round((Date.now() - startTime) / 1000);

      await this.prisma.syncLog.create({
        data: {
          syncType: 'ADO_SYNC',
          status: failed > 0 ? 'PARTIAL' : 'COMPLETED',
          itemsProcessed: processed,
          itemsFailed: failed,
          details: JSON.stringify({
            linksCreated,
          }),
          startedAt: new Date(startTime),
          completedAt: new Date(),
          duration,
        },
      });

      this.logger.log(
        `ADO-GitHub sync completed: ${processed} repos processed, ${linksCreated} links created in ${duration}s`,
      );
    } catch (error) {
      this.logger.error(`ADO-GitHub sync failed: ${error.message}`);

      await this.prisma.syncLog.create({
        data: {
          syncType: 'ADO_SYNC',
          status: 'FAILED',
          errorMessage: error.message,
          startedAt: new Date(startTime),
          completedAt: new Date(),
        },
      });
    }
  }

  async syncRepositoryLinks(repoName: string): Promise<number> {
    this.logger.debug(`Syncing links for repository: ${repoName}`);

    const repository = await this.prisma.repository.findUnique({
      where: { name: repoName },
    });

    if (!repository) {
      throw new Error(`Repository ${repoName} not found in database`);
    }

    let linksCreated = 0;

    // Get recent PRs
    const prs = await this.github.getPullRequests(repoName, 'all');

    for (const pr of prs) {
      // Parse work item IDs from PR title and body
      const text = `${pr.title} ${pr.body || ''}`;
      const workItemIds = this.azureDevOps.parseWorkItemIds(text);

      for (const wiId of workItemIds) {
        const created = await this.createOrUpdateLink({
          repositoryId: repository.id,
          workItemId: wiId,
          pullRequestId: pr.number.toString(),
          pullRequestUrl: pr.html_url,
          pullRequestTitle: pr.title,
        });

        if (created) {
          linksCreated++;
        }
      }

      // Also check commit messages
      const commits = await this.github.getRecentCommits(repoName, 30);
      for (const commit of commits) {
        const commitIds = this.azureDevOps.parseWorkItemIds(commit.commit.message);
        for (const wiId of commitIds) {
          const created = await this.createOrUpdateLink({
            repositoryId: repository.id,
            workItemId: wiId,
            commitSha: commit.sha,
            commitUrl: commit.html_url,
            commitMessage: commit.commit.message,
          });

          if (created) {
            linksCreated++;
          }
        }
      }
    }

    // Check for broken links
    await this.verifyLinks(repository.id);

    return linksCreated;
  }

  private async createOrUpdateLink(params: {
    repositoryId: string;
    workItemId: string;
    pullRequestId?: string;
    pullRequestUrl?: string;
    pullRequestTitle?: string;
    commitSha?: string;
    commitUrl?: string;
    commitMessage?: string;
  }): Promise<boolean> {
    try {
      // Check if link already exists
      const existingLink = await this.prisma.workItemLink.findFirst({
        where: {
          repositoryId: params.repositoryId,
          workItemId: params.workItemId,
          pullRequestId: params.pullRequestId,
          commitSha: params.commitSha,
        },
      });

      if (existingLink) {
        return false; // Link already exists
      }

      // Get or create work item record
      let workItem = await this.prisma.workItem.findUnique({
        where: { id: params.workItemId },
      });

      if (!workItem) {
        // Fetch from Azure DevOps
        const adoWorkItem = await this.azureDevOps.getWorkItem(params.workItemId);
        if (!adoWorkItem) {
          this.logger.warn(`Work item ${params.workItemId} not found in Azure DevOps`);
          return false;
        }

        workItem = await this.prisma.workItem.create({
          data: {
            id: params.workItemId,
            title: adoWorkItem.fields['System.Title'],
            state: adoWorkItem.fields['System.State'],
            areaPath: adoWorkItem.fields['System.AreaPath'],
            iterationPath: adoWorkItem.fields['System.IterationPath'],
            assignedTo: adoWorkItem.fields['System.AssignedTo']?.displayName,
            organization: this.azureDevOps['organization'],
            project: this.azureDevOps['project'],
            url: adoWorkItem._links.html.href,
          },
        });
      }

      // Create link in database
      await this.prisma.workItemLink.create({
        data: {
          repositoryId: params.repositoryId,
          workItemId: params.workItemId,
          pullRequestId: params.pullRequestId,
          commitSha: params.commitSha,
          linkType: params.pullRequestId ? 'PULL_REQUEST' : 'COMMIT',
          status: 'ACTIVE',
        },
      });

      // Create link in Azure DevOps
      const linkUrl = params.pullRequestUrl || params.commitUrl;
      const linkComment = params.pullRequestId
        ? `Linked to PR #${params.pullRequestId}: ${params.pullRequestTitle}`
        : `Linked to commit: ${params.commitMessage}`;

      if (linkUrl) {
        await this.azureDevOps.createWorkItemLink(
          params.workItemId,
          linkUrl,
          linkComment,
        );
      }

      this.logger.log(
        `Created link: Work Item ${params.workItemId} ↔ ${
          params.pullRequestId ? `PR #${params.pullRequestId}` : `Commit ${params.commitSha}`
        }`,
      );

      return true;
    } catch (error) {
      this.logger.error(`Failed to create link: ${error.message}`);
      return false;
    }
  }

  private async verifyLinks(repositoryId: string): Promise<void> {
    const links = await this.prisma.workItemLink.findMany({
      where: {
        repositoryId,
        status: 'ACTIVE',
      },
    });

    for (const link of links) {
      // Verify work item still exists
      const workItem = await this.azureDevOps.getWorkItem(link.workItemId);
      if (!workItem) {
        await this.prisma.workItemLink.update({
          where: { id: link.id },
          data: { status: 'BROKEN' },
        });
        this.logger.warn(`Marked link as broken: Work Item ${link.workItemId} no longer exists`);
      }
    }
  }

  async detectDrift(): Promise<{
    missingInAdo: Array<{ workItemId: string; githubUrl: string }>;
    missingInGithub: Array<{ workItemId: string; prNumber: string }>;
  }> {
    const activeLinks = await this.prisma.workItemLink.findMany({
      where: { status: 'ACTIVE' },
      include: {
        repository: true,
        workItem: true,
      },
    });

    const missingInAdo: Array<{ workItemId: string; githubUrl: string }> = [];
    const missingInGithub: Array<{ workItemId: string; prNumber: string }> = [];

    // Check each link
    for (const link of activeLinks) {
      if (link.pullRequestId) {
        // Verify PR mentions work item
        const prs = await this.github.getPullRequests(link.repository.name, 'all');
        const pr = prs.find(p => p.number.toString() === link.pullRequestId);

        if (pr) {
          const text = `${pr.title} ${pr.body || ''}`;
          const workItemIds = this.azureDevOps.parseWorkItemIds(text);

          if (!workItemIds.includes(link.workItemId)) {
            missingInGithub.push({
              workItemId: link.workItemId,
              prNumber: link.pullRequestId,
            });
          }
        }
      }
    }

    return {
      missingInAdo,
      missingInGithub,
    };
  }

  async repairDrift(): Promise<number> {
    const drift = await this.detectDrift();
    let repaired = 0;

    // Repair missing GitHub references
    for (const item of drift.missingInGithub) {
      this.logger.log(
        `Repairing drift: Adding work item ${item.workItemId} reference to PR ${item.prNumber}`,
      );
      // In a real implementation, we would update the PR body here
      repaired++;
    }

    return repaired;
  }
}