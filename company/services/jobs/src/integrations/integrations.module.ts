import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { GitHubService } from './github.service';
import { AzureDevOpsService } from './azure-devops.service';
import { SlackService } from './slack.service';
import { TodoScannerService } from './todo-scanner.service';

@Module({
  imports: [HttpModule],
  providers: [GitHubService, AzureDevOpsService, SlackService, TodoScannerService],
  exports: [GitHubService, AzureDevOpsService, SlackService, TodoScannerService],
})
export class IntegrationsModule {}