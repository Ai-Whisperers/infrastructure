import { Module } from '@nestjs/common';
import { GitHubHealthScanner } from './github-health.scanner';
import { DocsCheckScanner } from './docs-check.scanner';
import { IntegrationsModule } from '../integrations/integrations.module';

@Module({
  imports: [IntegrationsModule],
  providers: [GitHubHealthScanner, DocsCheckScanner],
  exports: [GitHubHealthScanner, DocsCheckScanner],
})
export class ScannersModule {}