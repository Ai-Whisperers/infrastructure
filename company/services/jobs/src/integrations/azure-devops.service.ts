import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

interface WorkItem {
  id: number;
  fields: {
    'System.Title': string;
    'System.State': string;
    'System.WorkItemType': string;
    'System.AreaPath': string;
    'System.IterationPath': string;
    'System.AssignedTo'?: {
      displayName: string;
      uniqueName: string;
    };
  };
  _links: {
    html: {
      href: string;
    };
  };
}

@Injectable()
export class AzureDevOpsService {
  private readonly logger = new Logger(AzureDevOpsService.name);
  private baseUrl: string;
  private organization: string;
  private project: string;
  private pat: string;

  constructor(
    private config: ConfigService,
    private http: HttpService,
  ) {
    this.organization = config.get('AZURE_DEVOPS_ORG', '');
    this.project = config.get('AZURE_DEVOPS_PROJECT', 'AI-Whisperers');
    this.pat = config.get('AZURE_DEVOPS_PAT', '');
    this.baseUrl = `https://dev.azure.com/${this.organization}`;
  }

  private getHeaders() {
    const auth = Buffer.from(`:${this.pat}`).toString('base64');
    return {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json',
    };
  }

  async getWorkItem(id: string): Promise<WorkItem | null> {
    if (!this.organization || !this.pat) {
      this.logger.warn('Azure DevOps not configured');
      return null;
    }

    try {
      const url = `${this.baseUrl}/_apis/wit/workitems/${id}?api-version=7.0`;
      const response = await firstValueFrom(
        this.http.get(url, {
          headers: this.getHeaders(),
        }),
      );
      return response.data;
    } catch (error) {
      this.logger.error(`Failed to get work item ${id}: ${error.message}`);
      return null;
    }
  }

  async searchWorkItems(query: string): Promise<WorkItem[]> {
    if (!this.organization || !this.pat) {
      this.logger.warn('Azure DevOps not configured');
      return [];
    }

    try {
      const wiql = {
        query: `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${this.project}' AND ${query}`,
      };

      const url = `${this.baseUrl}/${this.project}/_apis/wit/wiql?api-version=7.0`;
      const response = await firstValueFrom(
        this.http.post(url, wiql, {
          headers: this.getHeaders(),
        }),
      );

      if (response.data.workItems.length === 0) {
        return [];
      }

      // Get full work item details
      const ids = response.data.workItems.map((wi: any) => wi.id).join(',');
      const detailsUrl = `${this.baseUrl}/_apis/wit/workitems?ids=${ids}&api-version=7.0`;
      const detailsResponse = await firstValueFrom(
        this.http.get(detailsUrl, {
          headers: this.getHeaders(),
        }),
      );

      return detailsResponse.data.value;
    } catch (error) {
      this.logger.error(`Failed to search work items: ${error.message}`);
      return [];
    }
  }

  async createWorkItemLink(
    workItemId: string,
    url: string,
    comment: string,
  ): Promise<boolean> {
    if (!this.organization || !this.pat) {
      this.logger.warn('Azure DevOps not configured');
      return false;
    }

    try {
      // First, get the work item to check existing links
      const workItem = await this.getWorkItem(workItemId);
      if (!workItem) {
        return false;
      }

      // Prepare the patch document
      const patchDocument = [
        {
          op: 'add',
          path: '/relations/-',
          value: {
            rel: 'Hyperlink',
            url: url,
            attributes: {
              comment: comment,
            },
          },
        },
      ];

      const updateUrl = `${this.baseUrl}/_apis/wit/workitems/${workItemId}?api-version=7.0`;
      await firstValueFrom(
        this.http.patch(updateUrl, patchDocument, {
          headers: {
            ...this.getHeaders(),
            'Content-Type': 'application/json-patch+json',
          },
        }),
      );

      this.logger.log(`Created link from work item ${workItemId} to ${url}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to create work item link: ${error.message}`);
      return false;
    }
  }

  async addWorkItemComment(workItemId: string, text: string): Promise<boolean> {
    if (!this.organization || !this.pat) {
      this.logger.warn('Azure DevOps not configured');
      return false;
    }

    try {
      const url = `${this.baseUrl}/${this.project}/_apis/wit/workitems/${workItemId}/comments?api-version=7.0-preview`;
      await firstValueFrom(
        this.http.post(
          url,
          { text },
          {
            headers: this.getHeaders(),
          },
        ),
      );

      this.logger.log(`Added comment to work item ${workItemId}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to add work item comment: ${error.message}`);
      return false;
    }
  }

  parseWorkItemIds(text: string): string[] {
    // Match patterns like: #123, AB#123, WI123, Work Item 123
    const patterns = [
      /#(\d+)/g,
      /[A-Z]{2}#(\d+)/g,
      /WI\s*(\d+)/gi,
      /Work\s*Item\s*(\d+)/gi,
    ];

    const ids = new Set<string>();

    for (const pattern of patterns) {
      const matches = text.matchAll(pattern);
      for (const match of matches) {
        ids.add(match[1]);
      }
    }

    return Array.from(ids);
  }
}