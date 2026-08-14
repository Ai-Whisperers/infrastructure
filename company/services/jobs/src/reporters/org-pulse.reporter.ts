import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../db/prisma.service';
import { GitHubService } from '../integrations/github.service';
import { SlackService } from '../integrations/slack.service';
import * as fs from 'fs/promises';
import * as path from 'path';
import { marked } from 'marked';
import { format, getWeek, getYear } from 'date-fns';

interface RepoMetrics {
  name: string;
  health: string;
  commits: number;
  prs: number;
  issues: number;
  lastActivity: Date | null;
  protection: boolean;
  stalePRs: number;
  coverage?: number;
}

interface OrgMetrics {
  totalRepos: number;
  activeRepos: number;
  totalCommits: number;
  totalPRs: number;
  totalIssues: number;
  averageHealth: number;
  topContributors: Array<{ name: string; commits: number }>;
}

@Injectable()
export class OrgPulseReporter {
  private readonly logger = new Logger(OrgPulseReporter.name);
  private readonly reportsPath = path.join(process.cwd(), 'reports');

  constructor(
    private prisma: PrismaService,
    private github: GitHubService,
    private slack: SlackService,
  ) {}

  @Cron('0 9 * * MON') // Every Monday at 9 AM
  async generateWeeklyReport() {
    this.logger.log('Starting weekly Org Pulse report generation');
    const startTime = Date.now();

    try {
      const report = await this.generateReport();
      const week = getWeek(new Date());
      const year = getYear(new Date());

      // Save to database
      await this.prisma.report.create({
        data: {
          type: 'ORG_PULSE',
          week,
          year,
          content: report.markdown,
          htmlContent: report.html,
          summary: report.summary,
        },
      });

      // Save to file system
      await this.saveReportToFile(report.markdown, week, year);

      // Send notifications
      await this.notifyChannels(report.summary);

      const duration = Math.round((Date.now() - startTime) / 1000);
      this.logger.log(`Weekly Org Pulse report generated in ${duration}s`);
    } catch (error) {
      this.logger.error(`Failed to generate weekly report: ${error.message}`);
    }
  }

  async generateReport(): Promise<{
    markdown: string;
    html: string;
    summary: any;
  }> {
    const metrics = await this.collectMetrics();
    const markdown = this.generateMarkdown(metrics);
    const html = await marked(markdown);

    return {
      markdown,
      html,
      summary: {
        week: getWeek(new Date()),
        year: getYear(new Date()),
        totalRepos: metrics.org.totalRepos,
        activeRepos: metrics.org.activeRepos,
        healthScore: metrics.org.averageHealth,
        totalCommits: metrics.org.totalCommits,
      },
    };
  }

  private async collectMetrics(): Promise<{
    repos: RepoMetrics[];
    org: OrgMetrics;
  }> {
    const repositories = await this.prisma.repository.findMany({
      include: {
        healthChecks: {
          take: 10,
          orderBy: { timestamp: 'desc' },
        },
      },
    });

    const repoMetrics: RepoMetrics[] = [];
    let totalCommits = 0;
    let totalPRs = 0;
    let totalIssues = 0;
    let activeRepos = 0;

    for (const repo of repositories) {
      // Get weekly activity
      const commits = await this.github.getRecentCommits(repo.name, 7);
      const prs = await this.github.getPullRequests(repo.name);
      const stalePRs = prs.filter(pr => {
        const daysOld = (Date.now() - new Date(pr.created_at).getTime()) / (1000 * 60 * 60 * 24);
        return daysOld > 7;
      });

      const metrics: RepoMetrics = {
        name: repo.name,
        health: repo.healthStatus.toLowerCase(),
        commits: commits.length,
        prs: prs.length,
        issues: repo.openIssues,
        lastActivity: repo.lastActivity,
        protection: repo.hasProtection === 1,
        stalePRs: stalePRs.length,
      };

      repoMetrics.push(metrics);

      totalCommits += commits.length;
      totalPRs += prs.length;
      totalIssues += repo.openIssues;

      if (commits.length > 0) {
        activeRepos++;
      }
    }

    // Get top contributors
    const contributorMap = new Map<string, number>();
    for (const repo of repositories) {
      const commits = await this.github.getRecentCommits(repo.name, 7);
      for (const commit of commits) {
        const author = commit.commit.author?.name || 'Unknown';
        contributorMap.set(author, (contributorMap.get(author) || 0) + 1);
      }
    }

    const topContributors = Array.from(contributorMap.entries())
      .map(([name, commits]) => ({ name, commits }))
      .sort((a, b) => b.commits - a.commits)
      .slice(0, 5);

    const averageHealth = repositories.reduce((sum: number, r: any) => sum + r.healthScore, 0) / repositories.length;

    return {
      repos: repoMetrics,
      org: {
        totalRepos: repositories.length,
        activeRepos,
        totalCommits,
        totalPRs,
        totalIssues,
        averageHealth: Math.round(averageHealth),
        topContributors,
      },
    };
  }

  private generateMarkdown(metrics: { repos: RepoMetrics[]; org: OrgMetrics }): string {
    const date = format(new Date(), 'MMMM d, yyyy');
    const week = getWeek(new Date());

    let markdown = `# AI-Whisperers Org Pulse Report\n\n`;
    markdown += `**Week ${week} - ${date}**\n\n`;

    // Executive Summary
    markdown += `## Executive Summary\n\n`;
    markdown += `- **Total Repositories:** ${metrics.org.totalRepos}\n`;
    markdown += `- **Active This Week:** ${metrics.org.activeRepos}\n`;
    markdown += `- **Total Commits:** ${metrics.org.totalCommits}\n`;
    markdown += `- **Open PRs:** ${metrics.org.totalPRs}\n`;
    markdown += `- **Open Issues:** ${metrics.org.totalIssues}\n`;
    markdown += `- **Average Health Score:** ${metrics.org.averageHealth}%\n\n`;

    // Top Contributors
    markdown += `## Top Contributors\n\n`;
    markdown += `| Contributor | Commits |\n`;
    markdown += `|------------|---------|\n`;
    for (const contributor of metrics.org.topContributors) {
      markdown += `| ${contributor.name} | ${contributor.commits} |\n`;
    }
    markdown += `\n`;

    // Repository Health
    markdown += `## Repository Health\n\n`;
    markdown += `| Repository | Health | Commits | PRs | Issues | Stale PRs | Protection |\n`;
    markdown += `|------------|--------|---------|-----|--------|-----------|------------|\n`;

    const sortedRepos = metrics.repos.sort((a, b) => b.commits - a.commits);
    for (const repo of sortedRepos) {
      const healthEmoji = this.getHealthEmoji(repo.health);
      const protectionEmoji = repo.protection ? '✅' : '❌';
      markdown += `| ${repo.name} | ${healthEmoji} ${repo.health} | ${repo.commits} | ${repo.prs} | ${repo.issues} | ${repo.stalePRs} | ${protectionEmoji} |\n`;
    }
    markdown += `\n`;

    // Recommendations
    markdown += `## Recommendations\n\n`;

    const criticalRepos = metrics.repos.filter(r => r.health === 'critical');
    if (criticalRepos.length > 0) {
      markdown += `### Critical Attention Required\n\n`;
      for (const repo of criticalRepos) {
        markdown += `- **${repo.name}**: `;
        if (repo.stalePRs > 3) {
          markdown += `${repo.stalePRs} stale PRs need review. `;
        }
        if (!repo.protection) {
          markdown += `Branch protection not configured. `;
        }
        if (repo.commits === 0) {
          markdown += `No activity this week. `;
        }
        markdown += `\n`;
      }
      markdown += `\n`;
    }

    const warningRepos = metrics.repos.filter(r => r.health === 'warning');
    if (warningRepos.length > 0) {
      markdown += `### Attention Recommended\n\n`;
      for (const repo of warningRepos) {
        markdown += `- **${repo.name}**: Consider addressing ${repo.issues} open issues\n`;
      }
      markdown += `\n`;
    }

    // Footer
    markdown += `---\n\n`;
    markdown += `*Generated by AI-Whisperers Org OS*\n`;
    markdown += `*Report generated on ${format(new Date(), 'yyyy-MM-dd HH:mm:ss')}*\n`;

    return markdown;
  }

  private getHealthEmoji(health: string): string {
    switch (health) {
      case 'good':
        return '🟢';
      case 'warning':
        return '🟡';
      case 'critical':
        return '🔴';
      default:
        return '⚫';
    }
  }

  private async saveReportToFile(content: string, week: number, year: number): Promise<void> {
    try {
      // Ensure reports directory exists
      await fs.mkdir(this.reportsPath, { recursive: true });

      const filename = `${year}-W${week.toString().padStart(2, '0')}.md`;
      const filepath = path.join(this.reportsPath, filename);

      await fs.writeFile(filepath, content, 'utf-8');
      this.logger.log(`Report saved to ${filepath}`);
    } catch (error) {
      this.logger.error(`Failed to save report to file: ${error.message}`);
    }
  }

  private async notifyChannels(summary: any): Promise<void> {
    try {
      const message = {
        text: '📊 Weekly Org Pulse Report Generated',
        blocks: [
          {
            type: 'header',
            text: {
              type: 'plain_text',
              text: '📊 AI-Whisperers Weekly Org Pulse',
            },
          },
          {
            type: 'section',
            fields: [
              {
                type: 'mrkdwn',
                text: `*Week:* ${summary.week}`,
              },
              {
                type: 'mrkdwn',
                text: `*Year:* ${summary.year}`,
              },
              {
                type: 'mrkdwn',
                text: `*Active Repos:* ${summary.activeRepos}/${summary.totalRepos}`,
              },
              {
                type: 'mrkdwn',
                text: `*Health Score:* ${summary.healthScore}%`,
              },
              {
                type: 'mrkdwn',
                text: `*Total Commits:* ${summary.totalCommits}`,
              },
            ],
          },
          {
            type: 'actions',
            elements: [
              {
                type: 'button',
                text: {
                  type: 'plain_text',
                  text: 'View Full Report',
                },
                url: `${process.env.DASHBOARD_URL || 'http://localhost:3001'}/reports/${summary.year}-W${summary.week}`,
              },
            ],
          },
        ],
      };

      await this.slack.sendMessage(message);
    } catch (error) {
      this.logger.error(`Failed to send notifications: ${error.message}`);
    }
  }
}