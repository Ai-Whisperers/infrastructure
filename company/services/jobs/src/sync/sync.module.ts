import { Module } from '@nestjs/common';
import { AdoGithubLinker } from './ado-github-linker.service';
import { IntegrationsModule } from '../integrations/integrations.module';

@Module({
  imports: [IntegrationsModule],
  providers: [AdoGithubLinker],
  exports: [AdoGithubLinker],
})
export class SyncModule {}