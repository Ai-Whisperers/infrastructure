import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class SlackService {
  private readonly logger = new Logger(SlackService.name);
  private webhookUrl: string;

  constructor(
    private config: ConfigService,
    private http: HttpService,
  ) {
    this.webhookUrl = config.get('SLACK_WEBHOOK_URL', '');
  }

  async sendMessage(message: any): Promise<boolean> {
    if (!this.webhookUrl) {
      this.logger.warn('Slack webhook not configured');
      return false;
    }

    try {
      await firstValueFrom(
        this.http.post(this.webhookUrl, message),
      );
      this.logger.log('Slack notification sent successfully');
      return true;
    } catch (error) {
      this.logger.error(`Failed to send Slack notification: ${error.message}`);
      return false;
    }
  }
}