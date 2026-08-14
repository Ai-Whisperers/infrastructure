import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Octokit } from '@octokit/rest';

@Injectable()
export class GitHubService {
  private readonly logger = new Logger(GitHubService.name);
  private octokit: Octokit;
  private org: string;

  constructor(private config: ConfigService) {
    const token = config.get('GITHUB_TOKEN');
    if (!token) {
      this.logger.warn('GITHUB_TOKEN not configured. Using public API with rate limits.');
    }
    this.octokit = new Octokit({
      auth: token,
    });
    this.org = config.get('GITHUB_ORG', 'Ai-Whisperers');
  }

  async listOrganizationRepos() {
    try {
      const { data } = await this.octokit.repos.listForOrg({
        org: this.org,
        per_page: 100,
        sort: 'updated',
      });
      return data;
    } catch (error) {
      this.logger.error(`Failed to list repos: ${error.message}`);
      if (error.status === 401) {
        throw new Error('GitHub authentication failed. Please check your GITHUB_TOKEN in .env file.');
      }
      if (error.status === 404) {
        throw new Error(`GitHub organization '${this.org}' not found or not accessible.`);
      }
      throw error;
    }
  }

  async getRepository(repo: string) {
    try {
      const { data } = await this.octokit.repos.get({
        owner: this.org,
        repo,
      });
      return data;
    } catch (error) {
      this.logger.error(`Failed to get repo ${repo}: ${error.message}`);
      if (error.status === 401) {
        throw new Error('GitHub authentication failed. Please check your GITHUB_TOKEN in .env file.');
      }
      if (error.status === 404) {
        throw new Error(`Repository '${repo}' not found in organization '${this.org}'.`);
      }
      throw error;
    }
  }

  async getBranchProtection(repo: string, branch: string) {
    try {
      const { data } = await this.octokit.repos.getBranchProtection({
        owner: this.org,
        repo,
        branch,
      });
      return data;
    } catch (error) {
      if (error.status === 404) {
        return null; // No protection
      }
      this.logger.error(`Failed to get branch protection for ${repo}/${branch}: ${error.message}`);
      throw error;
    }
  }

  async getPullRequests(repo: string, state: 'open' | 'closed' | 'all' = 'open') {
    try {
      const { data } = await this.octokit.pulls.list({
        owner: this.org,
        repo,
        state,
        per_page: 100,
      });
      return data;
    } catch (error) {
      this.logger.error(`Failed to get PRs for ${repo}: ${error.message}`);
      throw error;
    }
  }

  async getRecentCommits(repo: string, days: number) {
    try {
      const since = new Date();
      since.setDate(since.getDate() - days);

      const { data } = await this.octokit.repos.listCommits({
        owner: this.org,
        repo,
        since: since.toISOString(),
        per_page: 100,
      });
      return data;
    } catch (error) {
      this.logger.error(`Failed to get commits for ${repo}: ${error.message}`);
      throw error;
    }
  }

  async getLastCommit(repo: string) {
    try {
      const { data } = await this.octokit.repos.listCommits({
        owner: this.org,
        repo,
        per_page: 1,
      });

      if (data.length > 0) {
        const commit = data[0];
        return {
          sha: commit.sha,
          message: commit.commit.message,
          author: commit.commit.author?.name || 'Unknown',
          authorEmail: commit.commit.author?.email,
          date: commit.commit.author?.date,
          url: commit.html_url,
        };
      }
      return null;
    } catch (error) {
      this.logger.error(`Failed to get last commit for ${repo}: ${error.message}`);
      return null; // Return null instead of throwing to handle gracefully
    }
  }

  async getRepositoryContent(repo: string, path: string) {
    try {
      const { data } = await this.octokit.repos.getContent({
        owner: this.org,
        repo,
        path,
      });
      return Array.isArray(data) ? data : [data];
    } catch (error) {
      if (error.status === 404) {
        return [];
      }
      this.logger.error(`Failed to get content for ${repo}/${path}: ${error.message}`);
      throw error;
    }
  }

  async createBranch(repo: string, branchName: string, baseBranch: string = 'main') {
    try {
      // Get the base branch reference
      const { data: ref } = await this.octokit.git.getRef({
        owner: this.org,
        repo,
        ref: `heads/${baseBranch}`,
      });

      // Create new branch
      await this.octokit.git.createRef({
        owner: this.org,
        repo,
        ref: `refs/heads/${branchName}`,
        sha: ref.object.sha,
      });

      return true;
    } catch (error) {
      this.logger.error(`Failed to create branch ${branchName} in ${repo}: ${error.message}`);
      throw error;
    }
  }

  async createOrUpdateFile(
    repo: string,
    path: string,
    content: string,
    message: string,
    branch: string,
  ) {
    try {
      // Check if file exists
      let sha: string | undefined;
      try {
        const { data } = await this.octokit.repos.getContent({
          owner: this.org,
          repo,
          path,
          ref: branch,
        });
        if (!Array.isArray(data) && data.type === 'file') {
          sha = data.sha;
        }
      } catch (error) {
        // File doesn't exist, which is fine
      }

      // Create or update file
      await this.octokit.repos.createOrUpdateFileContents({
        owner: this.org,
        repo,
        path,
        message,
        content: Buffer.from(content).toString('base64'),
        branch,
        sha,
      });

      return true;
    } catch (error) {
      this.logger.error(`Failed to create/update file ${path} in ${repo}: ${error.message}`);
      throw error;
    }
  }

  async createPullRequest(
    repo: string,
    options: {
      title: string;
      body: string;
      head: string;
      base: string;
    },
  ) {
    try {
      const { data } = await this.octokit.pulls.create({
        owner: this.org,
        repo,
        ...options,
      });
      return data;
    } catch (error) {
      this.logger.error(`Failed to create PR in ${repo}: ${error.message}`);
      throw error;
    }
  }

  async getIssues(repo: string, state: 'open' | 'closed' | 'all' = 'open') {
    try {
      const { data } = await this.octokit.issues.listForRepo({
        owner: this.org,
        repo,
        state,
        per_page: 100,
      });
      return data.filter(issue => !issue.pull_request);
    } catch (error) {
      this.logger.error(`Failed to get issues for ${repo}: ${error.message}`);
      throw error;
    }
  }

  async createIssue(
    repo: string,
    options: {
      title: string;
      body: string;
      labels?: string[];
      assignees?: string[];
    },
  ) {
    try {
      const { data } = await this.octokit.issues.create({
        owner: this.org,
        repo,
        ...options,
      });
      return data;
    } catch (error) {
      this.logger.error(`Failed to create issue in ${repo}: ${error.message}`);
      throw error;
    }
  }

  async getRepositoryTree(repo: string, branch: string = 'main'): Promise<any[]> {
    try {
      const { data } = await this.octokit.git.getTree({
        owner: this.org,
        repo,
        tree_sha: branch,
        recursive: 'true',
      });
      return data.tree;
    } catch (error) {
      // Try master branch if main fails
      if (branch === 'main') {
        return this.getRepositoryTree(repo, 'master');
      }
      this.logger.error(`Failed to get tree for ${repo}: ${error.message}`);
      return [];
    }
  }

  async getFileContent(repo: string, path: string): Promise<string> {
    try {
      const { data } = await this.octokit.repos.getContent({
        owner: this.org,
        repo,
        path,
      });

      if (Array.isArray(data)) {
        throw new Error(`Path ${path} is a directory, not a file`);
      }

      if (data.type !== 'file' || !data.content) {
        throw new Error(`Invalid file content for ${path}`);
      }

      // Decode base64 content
      return Buffer.from(data.content, 'base64').toString('utf-8');
    } catch (error) {
      this.logger.error(`Failed to get file content for ${repo}/${path}: ${error.message}`);
      throw error;
    }
  }
}