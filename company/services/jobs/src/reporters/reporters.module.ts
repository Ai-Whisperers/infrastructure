import { Module } from '@nestjs/common';
import { OrgPulseReporter } from './org-pulse.reporter';
import { IntegrationsModule } from '../integrations/integrations.module';
import { ScannersModule } from '../scanners/scanners.module';

@Module({
  imports: [IntegrationsModule, ScannersModule],
  providers: [OrgPulseReporter],
  exports: [OrgPulseReporter],
})
export class ReportersModule {}