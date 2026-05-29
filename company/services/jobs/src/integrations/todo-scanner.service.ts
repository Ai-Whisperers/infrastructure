import { Injectable, Logger } from '@nestjs/common';
import { GitHubService } from './github.service';

export interface TodoItem {
  id: string;
  text: string;
  type: 'TODO' | 'FIXME' | 'HACK' | 'NOTE' | 'BUG' | 'CRITICAL' | 'WARNING';
  priority: 'low' | 'medium' | 'high' | 'critical';
  file: string;
  line: number;
  author?: string;
  createdAt: Date;
  context?: string;
  assignee?: string;
}

export interface RepositoryTodos {
  repository: string;
  totalTodos: number;
  criticalCount: number;
  todos: TodoItem[];
  lastScanned: Date;
  healthImpact: number; // 0-100, how much todos affect health score
}

@Injectable()
export class TodoScannerService {
  private readonly logger = new Logger(TodoScannerService.name);

  // Critical patterns that need immediate attention
  private readonly criticalPatterns = [
    /(?:CRITICAL|URGENT|SECURITY|VULNERABILITY|EXPLOIT)/i,
    /(?:FIXME|BUG|ERROR|FAIL|BROKEN)/i,
    /(?:HACK|WORKAROUND|TEMPORARY)/i,
    /(?:TODO.*(?:ASAP|URGENT|CRITICAL|IMPORTANT))/i,
  ];

  // Todo patterns to scan for
  private readonly todoPatterns = [
    /\/\/\s*(TODO|FIXME|HACK|NOTE|BUG|CRITICAL|WARNING)[\s:]*([^\n\r]*)/gi,
    /\/\*\s*(TODO|FIXME|HACK|NOTE|BUG|CRITICAL|WARNING)[\s:]*([^*]*)\*\//gi,
    /#\s*(TODO|FIXME|HACK|NOTE|BUG|CRITICAL|WARNING)[\s:]*([^\n\r]*)/gi,
    /<!--\s*(TODO|FIXME|HACK|NOTE|BUG|CRITICAL|WARNING)[\s:]*([^>]*?)-->/gi,
  ];

  constructor(private readonly github: GitHubService) {}

  async scanRepositoryTodos(repoName: string): Promise<RepositoryTodos> {
    this.logger.log(`Scanning TODOs for repository: ${repoName}`);

    try {
      const todos: TodoItem[] = [];
      let criticalCount = 0;

      // Get repository tree to find all files
      const tree = await this.github.getRepositoryTree(repoName);
      const codeFiles = this.filterCodeFiles(tree);

      // Scan each code file for todos
      for (const file of codeFiles.slice(0, 50)) { // Limit to prevent API rate limits
        try {
          const content = await this.github.getFileContent(repoName, file.path);
          const fileTodos = this.extractTodosFromContent(content, file.path);

          todos.push(...fileTodos);
          criticalCount += fileTodos.filter(t => t.priority === 'critical').length;
        } catch (error) {
          this.logger.warn(`Failed to scan file ${file.path}: ${error.message}`);
        }
      }

      // Calculate health impact based on todo severity and count
      const healthImpact = this.calculateHealthImpact(todos);

      const result: RepositoryTodos = {
        repository: repoName,
        totalTodos: todos.length,
        criticalCount,
        todos: todos.sort((a, b) => this.getPriorityScore(b.priority) - this.getPriorityScore(a.priority)),
        lastScanned: new Date(),
        healthImpact,
      };

      this.logger.log(`Found ${todos.length} TODOs in ${repoName} (${criticalCount} critical)`);
      return result;
    } catch (error) {
      this.logger.error(`Failed to scan TODOs for ${repoName}: ${error.message}`);
      return {
        repository: repoName,
        totalTodos: 0,
        criticalCount: 0,
        todos: [],
        lastScanned: new Date(),
        healthImpact: 0,
      };
    }
  }

  private filterCodeFiles(tree: any[]): any[] {
    const codeExtensions = ['.js', '.ts', '.tsx', '.jsx', '.py', '.java', '.c', '.cpp', '.h', '.cs', '.php', '.rb', '.go', '.rs', '.swift', '.kt', '.scala', '.md', '.yml', '.yaml', '.json', '.xml', '.html', '.css', '.scss', '.vue', '.svelte'];

    return tree.filter(item =>
      item.type === 'blob' &&
      codeExtensions.some(ext => item.path.toLowerCase().endsWith(ext)) &&
      !item.path.includes('node_modules') &&
      !item.path.includes('.git') &&
      !item.path.includes('dist') &&
      !item.path.includes('build')
    );
  }

  private extractTodosFromContent(content: string, filePath: string): TodoItem[] {
    const todos: TodoItem[] = [];
    const lines = content.split('\n');

    lines.forEach((line, index) => {
      for (const pattern of this.todoPatterns) {
        let match;
        while ((match = pattern.exec(line)) !== null) {
          const type = match[1].toUpperCase() as TodoItem['type'];
          const text = match[2]?.trim() || '';

          if (text) {
            const priority = this.determinePriority(type, text);
            const todo: TodoItem = {
              id: `${filePath}:${index + 1}:${match.index}`,
              text,
              type,
              priority,
              file: filePath,
              line: index + 1,
              createdAt: new Date(),
              context: this.getContext(lines, index),
            };

            // Try to extract assignee from text
            const assigneeMatch = text.match(/@(\w+)/);
            if (assigneeMatch) {
              todo.assignee = assigneeMatch[1];
            }

            todos.push(todo);
          }
        }
      }
    });

    return todos;
  }

  private determinePriority(type: string, text: string): TodoItem['priority'] {
    // Check for critical patterns first
    for (const pattern of this.criticalPatterns) {
      if (pattern.test(text)) {
        return 'critical';
      }
    }

    // Type-based priority
    switch (type.toLowerCase()) {
      case 'critical':
      case 'bug':
        return 'critical';
      case 'fixme':
      case 'hack':
        return 'high';
      case 'todo':
        // Check if it's high priority TODO
        if (/(?:asap|urgent|important|priority)/i.test(text)) {
          return 'high';
        }
        return 'medium';
      case 'note':
      case 'warning':
        return 'low';
      default:
        return 'medium';
    }
  }

  private getContext(lines: string[], currentIndex: number): string {
    const start = Math.max(0, currentIndex - 2);
    const end = Math.min(lines.length, currentIndex + 3);
    return lines.slice(start, end).join('\n');
  }

  private calculateHealthImpact(todos: TodoItem[]): number {
    if (todos.length === 0) return 0;

    let impact = 0;
    for (const todo of todos) {
      switch (todo.priority) {
        case 'critical':
          impact += 15; // Each critical TODO reduces health by 15 points
          break;
        case 'high':
          impact += 8;
          break;
        case 'medium':
          impact += 3;
          break;
        case 'low':
          impact += 1;
          break;
      }
    }

    return Math.min(50, impact); // Cap at 50 point reduction
  }

  private getPriorityScore(priority: TodoItem['priority']): number {
    switch (priority) {
      case 'critical': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  async getRepositoryTodoSummary(repoName: string) {
    const todos = await this.scanRepositoryTodos(repoName);

    return {
      repository: repoName,
      summary: {
        total: todos.totalTodos,
        critical: todos.criticalCount,
        high: todos.todos.filter(t => t.priority === 'high').length,
        medium: todos.todos.filter(t => t.priority === 'medium').length,
        low: todos.todos.filter(t => t.priority === 'low').length,
      },
      healthImpact: todos.healthImpact,
      topTodos: todos.todos.slice(0, 5), // Top 5 most important
    };
  }
}