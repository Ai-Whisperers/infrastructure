import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  Res,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { Response } from 'express';
import { ReportsService } from './reports.service';
import { OrgPulseReporter } from '../reporters/org-pulse.reporter';
import { TodoScannerService } from '../integrations/todo-scanner.service';

@ApiTags('Reports')
@Controller('api/reports')
export class ReportsController {
  private readonly logger = new Logger(ReportsController.name);

  constructor(
    private readonly reportsService: ReportsService,
    private readonly orgPulseReporter: OrgPulseReporter,
    private readonly todoScanner: TodoScannerService,
  ) {}

  @Get('repositories')
  @ApiOperation({ summary: 'List all repositories' })
  @ApiResponse({ status: 200, description: 'Returns list of repositories' })
  async listRepositories() {
    return this.reportsService.listRepositories();
  }

  @Post('generate/:repoName')
  @ApiOperation({ summary: 'Generate report for a specific repository' })
  @ApiResponse({ status: 201, description: 'Report generated successfully' })
  @ApiResponse({ status: 404, description: 'Repository not found' })
  async generateRepoReport(
    @Param('repoName') repoName: string,
    @Body() options?: { format?: 'markdown' | 'html' | 'json' },
  ) {
    this.logger.log(`Generating report for repository: ${repoName}`);

    try {
      const report = await this.reportsService.generateRepositoryReport(repoName, options?.format || 'markdown');
      return {
        success: true,
        repository: repoName,
        reportId: report.id,
        format: options?.format || 'markdown',
        generatedAt: new Date().toISOString(),
      };
    } catch (error) {
      this.logger.error(`Failed to generate report for ${repoName}: ${error.message}`);
      throw error;
    }
  }

  @Get('download/:repoName')
  @ApiOperation({ summary: 'Download report for a repository' })
  @ApiQuery({ name: 'format', enum: ['markdown', 'html', 'json'], required: false })
  @ApiResponse({ status: 200, description: 'Report file' })
  @ApiResponse({ status: 404, description: 'Report not found' })
  async downloadReport(
    @Param('repoName') repoName: string,
    @Query('format') format: 'markdown' | 'html' | 'json' = 'markdown',
    @Res() res: Response,
  ) {
    try {
      const report = await this.reportsService.getRepositoryReport(repoName, format);

      if (!report) {
        return res.status(HttpStatus.NOT_FOUND).json({
          error: 'Report not found. Generate a report first.',
        });
      }

      // Set appropriate headers based on format
      const filename = `${repoName}-report-${new Date().toISOString().split('T')[0]}`;

      switch (format) {
        case 'json':
          res.setHeader('Content-Type', 'application/json');
          res.setHeader('Content-Disposition', `attachment; filename="${filename}.json"`);
          return res.send(JSON.stringify(report, null, 2));

        case 'html':
          res.setHeader('Content-Type', 'text/html');
          res.setHeader('Content-Disposition', `attachment; filename="${filename}.html"`);
          return res.send(report.content);

        case 'markdown':
        default:
          res.setHeader('Content-Type', 'text/markdown');
          res.setHeader('Content-Disposition', `attachment; filename="${filename}.md"`);
          return res.send(report.content);
      }
    } catch (error) {
      this.logger.error(`Failed to download report: ${error.message}`);
      return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'Failed to download report',
      });
    }
  }

  @Post('generate-all')
  @ApiOperation({ summary: 'Generate reports for all repositories' })
  @ApiResponse({ status: 201, description: 'Reports generation started' })
  async generateAllReports() {
    this.logger.log('Starting bulk report generation');

    const repositories = await this.reportsService.listRepositories();
    const results = [];

    for (const repo of repositories) {
      try {
        const report = await this.reportsService.generateRepositoryReport(repo.name, 'markdown');
        results.push({
          repository: repo.name,
          status: 'success',
          reportId: report.id,
        });
      } catch (error) {
        results.push({
          repository: repo.name,
          status: 'failed',
          error: error.message,
        });
      }
    }

    return {
      totalRepositories: repositories.length,
      successful: results.filter(r => r.status === 'success').length,
      failed: results.filter(r => r.status === 'failed').length,
      results,
    };
  }

  @Get('history/:repoName')
  @ApiOperation({ summary: 'Get report history for a repository' })
  @ApiResponse({ status: 200, description: 'Report history' })
  async getReportHistory(@Param('repoName') repoName: string) {
    return this.reportsService.getReportHistory(repoName);
  }

  @Post('org-pulse')
  @ApiOperation({ summary: 'Generate organization-wide pulse report' })
  @ApiResponse({ status: 201, description: 'Org pulse report generated' })
  async generateOrgPulse() {
    this.logger.log('Generating organization pulse report');

    try {
      const report = await this.orgPulseReporter.generateReport();
      return {
        success: true,
        type: 'org-pulse',
        week: new Date().toISOString(),
        summary: report.summary,
      };
    } catch (error) {
      this.logger.error(`Failed to generate org pulse: ${error.message}`);
      throw error;
    }
  }

  @Get('latest')
  @ApiOperation({ summary: 'Get latest reports for all repositories' })
  @ApiResponse({ status: 200, description: 'Latest reports' })
  async getLatestReports() {
    return this.reportsService.getLatestReports();
  }

  @Get('todos/:repoName')
  @ApiOperation({ summary: 'Get TODO items for a repository' })
  @ApiResponse({ status: 200, description: 'Repository TODOs' })
  async getRepositoryTodos(@Param('repoName') repoName: string) {
    this.logger.log(`Scanning TODOs for repository: ${repoName}`);
    return this.todoScanner.scanRepositoryTodos(repoName);
  }

  @Get('todos/:repoName/summary')
  @ApiOperation({ summary: 'Get TODO summary for a repository' })
  @ApiResponse({ status: 200, description: 'Repository TODO summary' })
  async getRepositoryTodoSummary(@Param('repoName') repoName: string) {
    this.logger.log(`Getting TODO summary for repository: ${repoName}`);
    return this.todoScanner.getRepositoryTodoSummary(repoName);
  }
}