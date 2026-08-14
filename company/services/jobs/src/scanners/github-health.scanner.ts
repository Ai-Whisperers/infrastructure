import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../db/prisma.service';
import { GitHubService } from '../integrations/github.service';
// HealthStatus type - using string for SQLite compatibility
type HealthStatus = 'GOOD' | 'WARNING' | 'CRITICAL' | 'UNKNOWN';

@Injectable()
export class GitHubHealthScanner {
  private readonly logger = new Logger(GitHubHealthScanner.name);

  constructor(
    private prisma: PrismaService,
    private github: GitHubService,
  ) {}

  @Cron(CronExpression.EVERY_HOUR)
  async scanAllRepositories() {
    this.logger.log('Starting repository health scan');
    const startTime = Date.now();

    try {
      const repos = await this.github.listOrganizationRepos();
      let processed = 0;
      let failed = 0;

      for (const repo of repos) {
        try {
          await this.scanRepository(repo.name);
          processed++;
        } catch (error) {
          this.logger.error(`Failed to scan ${repo.name}: ${error.message}`);
          failed++;
        }
      }

      const duration = Math.round((Date.now() - startTime) / 1000);

      await this.prisma.syncLog.create({
        data: {
          syncType: 'GITHUB_SCAN',
          status: failed > 0 ? 'PARTIAL' : 'COMPLETED',
          itemsProcessed: processed,
          itemsFailed: failed,
          startedAt: new Date(startTime),
          completedAt: new Date(),
          duration,
        },
      });

      this.logger.log(`Health scan completed: ${processed} processed, ${failed} failed in ${duration}s`);
    } catch (error) {
      this.logger.error(`Health scan failed: ${error.message}`);

      await this.prisma.syncLog.create({
        data: {
          syncType: 'GITHUB_SCAN',
          status: 'FAILED',
          errorMessage: error.message,
          startedAt: new Date(startTime),
          completedAt: new Date(),
        },
      });
    }
  }

  async scanRepository(repoName: string) {
    this.logger.debug(`Scanning repository: ${repoName}`);

    // Fetch repository details
    const repoData = await this.github.getRepository(repoName);
    const protection = await this.github.getBranchProtection(repoName, repoData.default_branch);
    const pulls = await this.github.getPullRequests(repoName);
    const commits = await this.github.getRecentCommits(repoName, 7);

    // Calculate health metrics
    const stalePRs = pulls.filter(pr => {
      const daysOld = (Date.now() - new Date(pr.created_at).getTime()) / (1000 * 60 * 60 * 24);
      return daysOld > 7;
    });

    const healthScore = this.calculateHealthScore({
      hasProtection: !!protection,
      stalePRs: stalePRs.length,
      openPRs: pulls.length,
      recentCommits: commits.length,
      openIssues: repoData.open_issues_count,
    });

    const healthStatus = this.getHealthStatus(healthScore);

    // Upsert repository data
    const repository = await this.prisma.repository.upsert({
      where: { name: repoName },
      update: {
        url: repoData.html_url,
        description: repoData.description,
        isPrivate: repoData.private ? 1 : 0,
        starCount: repoData.stargazers_count,
        forkCount: repoData.forks_count,
        openIssues: repoData.open_issues_count,
        openPRs: pulls.length,
        lastActivity: repoData.pushed_at ? new Date(repoData.pushed_at) : null,
        healthScore,
        healthStatus: healthStatus as any,
        hasProtection: protection ? 1 : 0,
        requiredChecks: JSON.stringify(protection?.required_status_checks?.checks) || null,
        updatedAt: new Date(),
      },
      create: {
        name: repoName,
        url: repoData.html_url,
        description: repoData.description,
        isPrivate: repoData.private ? 1 : 0,
        starCount: repoData.stargazers_count,
        forkCount: repoData.forks_count,
        openIssues: repoData.open_issues_count,
        openPRs: pulls.length,
        lastActivity: repoData.pushed_at ? new Date(repoData.pushed_at) : null,
        healthScore,
        healthStatus: healthStatus as any,
        hasProtection: protection ? 1 : 0,
        requiredChecks: JSON.stringify(protection?.required_status_checks?.checks) || null,
      },
    });

    // Record health checks
    const checks = [
      {
        checkType: 'branch_protection',
        status: protection ? 'PASS' : 'FAIL',
        message: protection ? 'Branch protection enabled' : 'Branch protection not configured',
      },
      {
        checkType: 'stale_prs',
        status: stalePRs.length === 0 ? 'PASS' : stalePRs.length > 3 ? 'FAIL' : 'PASS',
        message: `${stalePRs.length} stale PRs (>7 days old)`,
        details: { stalePRs: stalePRs.map(pr => ({ number: pr.number, title: pr.title })) },
      },
      {
        checkType: 'activity',
        status: commits.length > 0 ? 'PASS' : 'FAIL',
        message: `${commits.length} commits in last 7 days`,
      },
    ];

    for (const check of checks) {
      await this.prisma.healthCheck.create({
        data: {
          repositoryId: repository.id,
          checkType: check.checkType,
          status: check.status as any,
          message: check.message,
          details: JSON.stringify(check.details) || null,
        },
      });
    }

    return repository;
  }

  private calculateHealthScore(metrics: {
    hasProtection: boolean;
    stalePRs: number;
    openPRs: number;
    recentCommits: number;
    openIssues: number;
  }): number {
    let score = 0;

    // Branch protection (30 points)
    if (metrics.hasProtection) score += 30;

    // PR health (25 points)
    if (metrics.stalePRs === 0) score += 25;
    else if (metrics.stalePRs <= 2) score += 15;
    else if (metrics.stalePRs <= 5) score += 5;

    // Activity (25 points)
    if (metrics.recentCommits >= 10) score += 25;
    else if (metrics.recentCommits >= 5) score += 15;
    else if (metrics.recentCommits >= 1) score += 10;

    // Issue management (20 points)
    if (metrics.openIssues === 0) score += 20;
    else if (metrics.openIssues <= 5) score += 15;
    else if (metrics.openIssues <= 10) score += 10;
    else if (metrics.openIssues <= 20) score += 5;

    return Math.min(100, score);
  }

  private getHealthStatus(score: number): HealthStatus {
    if (score >= 80) return 'GOOD';
    if (score >= 60) return 'WARNING';
    if (score >= 40) return 'CRITICAL';
    return 'UNKNOWN';
  }
}