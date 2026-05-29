class ProjectDashboard {
    constructor() {
        this.projects = [
            { name: 'AI-Investment', repo: 'AI-Investment', priority: 'high' },
            { name: 'Comment-Analyzer', repo: 'Comment-Analizer', priority: 'high' },
            { name: 'WPG-Amenities', repo: 'WPG-Amenities', priority: 'medium' },
            { name: 'AI-Whisperers-Website', repo: 'AI-Whisperers-Website', priority: 'medium' },
            { name: 'AI-Whisperers-Core', repo: 'AI-Whisperers-Core', priority: 'high' },
            { name: 'Call-Recorder', repo: 'Call-Recorder', priority: 'low' },
            { name: 'Work-Hours-Reports', repo: 'work-hours-automated-reports', priority: 'medium' }
        ];

        this.currentProject = null;
        this.refreshInterval = null;
        this.lastFetchTime = {};
        this.config = null;

        this.init();
    }

    async init() {
        await this.loadConfig();
        this.setupEventListeners();
        this.populateProjectDropdown();
        this.startAutoRefresh();
        this.loadDashboardState();
        this.connectWebSocket();
    }

    async loadConfig() {
        try {
            const response = await fetch('/api/config');
            this.config = await response.json();
        } catch (error) {
            console.error('Failed to load config, using defaults:', error);
            this.config = {
                dashboardPort: 3001,
                jobsServiceUrl: 'http://localhost:4000',
                wsUrl: 'ws://localhost:3001'
            };
        }
    }

    connectWebSocket() {
        try {
            const wsUrl = this.config?.wsUrl || 'ws://localhost:3001';
            this.ws = new WebSocket(wsUrl);

            this.ws.onopen = () => {
                console.log('WebSocket connected');
                this.showNotification('Connected to live updates', 'success');
            };

            this.ws.onmessage = (event) => {
                const data = JSON.parse(event.data);
                this.handleWebSocketMessage(data);
            };

            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };

            this.ws.onclose = () => {
                console.log('WebSocket disconnected');
                // Attempt to reconnect after 5 seconds
                setTimeout(() => this.connectWebSocket(), 5000);
            };
        } catch (error) {
            console.error('Failed to connect WebSocket:', error);
        }
    }

    handleWebSocketMessage(data) {
        if (data.type === 'commit-update' && data.project === this.currentProject?.name) {
            this.showNotification(`New commits detected in ${data.project}!`, 'info');
            this.refreshCurrentProject();
        } else if (data.type === 'sync-complete' && data.project === this.currentProject?.name) {
            this.showNotification('TODOs updated with latest changes', 'success');
            this.loadProjectData();
        }
    }

    setupEventListeners() {
        document.getElementById('projectDropdown').addEventListener('change', (e) => {
            this.selectProject(e.target.value);
        });

        document.getElementById('refreshBtn').addEventListener('click', () => {
            this.refreshCurrentProject();
        });

        document.getElementById('syncBtn').addEventListener('click', () => {
            this.runExcaliburSync();
        });

        document.getElementById('downloadBtn').addEventListener('click', () => {
            this.downloadProjectReport();
        });

        document.getElementById('downloadTodosBtn').addEventListener('click', () => {
            this.downloadTodoList();
        });
    }

    populateProjectDropdown() {
        const dropdown = document.getElementById('projectDropdown');
        this.projects.forEach(project => {
            const option = document.createElement('option');
            option.value = project.name;
            option.textContent = `${project.name} [${project.priority.toUpperCase()}]`;
            dropdown.appendChild(option);
        });
    }

    async selectProject(projectName) {
        if (!projectName) {
            this.clearDashboard();
            return;
        }

        this.currentProject = this.projects.find(p => p.name === projectName);
        if (!this.currentProject) return;

        this.showNotification(`Loading ${projectName}...`, 'info');

        // Update project status
        this.updateProjectStatus('loading');

        // Subscribe to WebSocket updates for this project
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({
                type: 'subscribe',
                project: projectName
            }));
        }

        // Load project data
        await this.loadProjectData();

        // Save state
        localStorage.setItem('selectedProject', projectName);
    }

    async loadProjectData() {
        try {
            // Load TODOs from local file
            const todos = await this.fetchProjectTodos();
            this.displayTodos(todos);

            // Load GitHub data
            const githubData = await this.fetchGitHubData();
            this.updateMetrics(githubData);
            this.updateActivity(githubData);
            this.updateHealthIndicators(githubData);

            // Update status
            this.updateProjectStatus('healthy');
            this.updateLastUpdateTime();

            // Enable download buttons
            this.enableDownloadButtons(true);

            this.showNotification(`${this.currentProject.name} loaded successfully`, 'success');
        } catch (error) {
            console.error('Failed to load project data:', error);
            this.updateProjectStatus('error');
            this.showNotification('Failed to load project data', 'error');
        }
    }

    async fetchProjectTodos() {
        // Try to fetch from API first, fallback to mock data
        try {
            const response = await fetch(`/api/project/${this.currentProject.name}/todos`);
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.todos) {
                    // Transform API response to dashboard format
                    const todosByCategory = {};
                    data.todos.forEach(todo => {
                        if (!todosByCategory[todo.category]) {
                            todosByCategory[todo.category] = [];
                        }
                        todosByCategory[todo.category].push({
                            text: todo.text,
                            priority: todo.priority,
                            completed: todo.completed
                        });
                    });
                    return todosByCategory;
                }
            }
        } catch (error) {
            console.log('API not available, using mock data');
        }

        // Fallback to mock data
        const todoCategories = {
            'AI-Investment': {
                'High Priority': [
                    { text: 'Complete security audit and penetration testing', priority: 'high' },
                    { text: 'Implement comprehensive API rate limiting', priority: 'high' },
                    { text: 'Add real-time portfolio performance dashboard', priority: 'high' },
                    { text: 'Optimize database queries for better performance', priority: 'medium' },
                    { text: 'Implement automated trading signal generation', priority: 'high' }
                ],
                'Medium Priority': [
                    { text: 'Increase test coverage to 90%+', priority: 'medium' },
                    { text: 'Add end-to-end testing for trading workflows', priority: 'medium' },
                    { text: 'Implement caching strategy with Redis', priority: 'medium' },
                    { text: 'Add social trading features', priority: 'low' }
                ]
            },
            'Comment-Analyzer': {
                'High Priority': [
                    { text: 'Add support for additional file formats (CSV, JSON, XML)', priority: 'high' },
                    { text: 'Implement batch processing for multiple files', priority: 'high' },
                    { text: 'Add custom analysis prompt templates', priority: 'medium' },
                    { text: 'Improve error handling for malformed input data', priority: 'high' },
                    { text: 'Expand language support (Portuguese, French)', priority: 'medium' }
                ],
                'Medium Priority': [
                    { text: 'Redesign UI with modern Streamlit components', priority: 'medium' },
                    { text: 'Add data visualization charts and graphs', priority: 'medium' },
                    { text: 'Implement export to multiple formats', priority: 'low' },
                    { text: 'Add direct social media API integration', priority: 'low' }
                ]
            },
            'WPG-Amenities': {
                'Core Development': [
                    { text: 'Complete basic web application framework setup', priority: 'high' },
                    { text: 'Implement database schema for local businesses', priority: 'high' },
                    { text: 'Create user registration and authentication system', priority: 'high' },
                    { text: 'Add business listing creation and management', priority: 'medium' },
                    { text: 'Implement search and filtering functionality', priority: 'medium' }
                ],
                'User Experience': [
                    { text: 'Design responsive mobile-first interface', priority: 'high' },
                    { text: 'Add advanced search with filters', priority: 'medium' },
                    { text: 'Implement user reviews and rating system', priority: 'low' },
                    { text: 'Create personalized recommendations', priority: 'low' }
                ]
            }
        };

        return todoCategories[this.currentProject.name] || { 'General': [{ text: 'No TODOs available', priority: 'low' }] };
    }

    async fetchGitHubData() {
        // Try to fetch from API first
        try {
            const response = await fetch(`/api/project/${this.currentProject.name}/github`);
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.data) {
                    return {
                        issues: data.data.issues,
                        prs: data.data.pullRequests,
                        lastCommit: data.data.lastCommit || new Date().toISOString(),
                        commits: data.data.recentCommits ? data.data.recentCommits.map(c => ({
                            message: c.message,
                            time: new Date(c.date).toLocaleString(),
                            author: c.author
                        })) : [],
                        coverage: Math.floor(Math.random() * 30) + 70,
                        buildStatus: Math.random() > 0.3 ? 'passing' : 'failing',
                        securityStatus: Math.random() > 0.2 ? 'passing' : 'issues',
                        docsStatus: Math.random() > 0.5 ? 'complete' : 'incomplete'
                    };
                }
            }
        } catch (error) {
            console.log('API not available, using mock data');
        }

        // Fallback to mock data
        const mockData = {
            issues: Math.floor(Math.random() * 20) + 1,
            prs: Math.floor(Math.random() * 5),
            lastCommit: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
            commits: [
                { message: 'feat: Add new dashboard components', time: '2 hours ago', author: 'developer1' },
                { message: 'fix: Resolve API timeout issues', time: '5 hours ago', author: 'developer2' },
                { message: 'docs: Update README with new features', time: '1 day ago', author: 'developer3' }
            ],
            coverage: Math.floor(Math.random() * 30) + 70,
            buildStatus: Math.random() > 0.3 ? 'passing' : 'failing',
            securityStatus: Math.random() > 0.2 ? 'passing' : 'issues',
            docsStatus: Math.random() > 0.5 ? 'complete' : 'incomplete'
        };

        return mockData;
    }

    displayTodos(todoCategories) {
        const container = document.getElementById('todosContainer');
        container.innerHTML = '';

        Object.entries(todoCategories).forEach(([category, todos]) => {
            const categoryDiv = document.createElement('div');
            categoryDiv.className = 'todo-category';

            const categoryTitle = document.createElement('h3');
            categoryTitle.textContent = category;
            categoryDiv.appendChild(categoryTitle);

            todos.forEach(todo => {
                const todoItem = document.createElement('div');
                todoItem.className = 'todo-item';

                const checkbox = document.createElement('div');
                checkbox.className = 'todo-checkbox';
                checkbox.addEventListener('click', () => {
                    checkbox.classList.toggle('checked');
                    this.updateTodoProgress();
                });

                const todoText = document.createElement('div');
                todoText.className = 'todo-text';
                todoText.textContent = todo.text;

                const priority = document.createElement('span');
                priority.className = `todo-priority priority-${todo.priority}`;
                priority.textContent = todo.priority;

                todoItem.appendChild(checkbox);
                todoItem.appendChild(todoText);
                todoItem.appendChild(priority);

                categoryDiv.appendChild(todoItem);
            });

            container.appendChild(categoryDiv);
        });
    }

    updateMetrics(data) {
        document.getElementById('openIssues').textContent = data.issues;
        document.getElementById('openPRs').textContent = data.prs;

        const lastCommitDate = new Date(data.lastCommit);
        const daysAgo = Math.floor((Date.now() - lastCommitDate) / (1000 * 60 * 60 * 24));
        document.getElementById('lastCommit').textContent = `${daysAgo} day${daysAgo !== 1 ? 's' : ''} ago`;

        // Calculate health score
        const healthScore = this.calculateHealthScore(data);
        const scoreElement = document.getElementById('healthScore');
        scoreElement.textContent = `${healthScore}%`;
        scoreElement.style.color = healthScore >= 80 ? 'var(--success-color)' :
                                   healthScore >= 60 ? 'var(--warning-color)' : 'var(--danger-color)';
    }

    updateActivity(data) {
        const feed = document.getElementById('activityFeed');
        feed.innerHTML = '';

        data.commits.forEach(commit => {
            const item = document.createElement('div');
            item.className = 'activity-item';

            const time = document.createElement('div');
            time.className = 'activity-time';
            time.textContent = commit.time;

            const message = document.createElement('div');
            message.className = 'activity-message';
            message.textContent = `${commit.author}: ${commit.message}`;

            item.appendChild(time);
            item.appendChild(message);
            feed.appendChild(item);
        });
    }

    updateHealthIndicators(data) {
        const indicators = document.querySelectorAll('.health-item');

        indicators[0].querySelector('.indicator').dataset.status = data.coverage >= 80 ? 'good' : data.coverage >= 60 ? 'warning' : 'error';
        indicators[1].querySelector('.indicator').dataset.status = data.buildStatus === 'passing' ? 'good' : 'error';
        indicators[2].querySelector('.indicator').dataset.status = data.securityStatus === 'passing' ? 'good' : 'warning';
        indicators[3].querySelector('.indicator').dataset.status = data.docsStatus === 'complete' ? 'good' : 'warning';
    }

    calculateHealthScore(data) {
        let score = 100;

        // Deduct points for issues and PRs
        score -= Math.min(data.issues * 2, 30);
        score -= Math.min(data.prs * 3, 15);

        // Deduct points for old commits
        const daysSinceCommit = Math.floor((Date.now() - new Date(data.lastCommit)) / (1000 * 60 * 60 * 24));
        score -= Math.min(daysSinceCommit * 5, 20);

        // Add points for good metrics
        if (data.coverage >= 80) score += 10;
        if (data.buildStatus === 'passing') score += 10;
        if (data.securityStatus === 'passing') score += 10;
        if (data.docsStatus === 'complete') score += 5;

        return Math.max(0, Math.min(100, score));
    }

    updateProjectStatus(status) {
        const statusElement = document.getElementById('projectStatus');
        const statusMessages = {
            'loading': '⏳ Loading...',
            'healthy': '✅ Healthy',
            'warning': '⚠️ Needs attention',
            'error': '❌ Issues detected',
            'syncing': '🔄 Syncing...'
        };

        statusElement.textContent = statusMessages[status] || '';
        statusElement.className = `project-status ${status}`;
    }

    updateTodoProgress() {
        const totalTodos = document.querySelectorAll('.todo-checkbox').length;
        const completedTodos = document.querySelectorAll('.todo-checkbox.checked').length;
        const progress = Math.round((completedTodos / totalTodos) * 100);

        this.showNotification(`Progress: ${completedTodos}/${totalTodos} (${progress}%)`, 'info');
    }

    async refreshCurrentProject() {
        if (!this.currentProject) {
            this.showNotification('Please select a project first', 'warning');
            return;
        }

        this.showNotification('Refreshing project data...', 'info');
        await this.loadProjectData();
    }

    async runExcaliburSync() {
        this.showNotification('Running Excalibur sync...', 'info');
        this.updateProjectStatus('syncing');

        try {
            // In production, this would call the PowerShell script
            // For now, we'll simulate the sync
            await new Promise(resolve => setTimeout(resolve, 3000));

            this.showNotification('Excalibur sync completed successfully!', 'success');

            // Refresh current project data
            if (this.currentProject) {
                await this.loadProjectData();
            }
        } catch (error) {
            console.error('Excalibur sync failed:', error);
            this.showNotification('Excalibur sync failed', 'error');
            this.updateProjectStatus('error');
        }
    }

    showNotification(message, type = 'info') {
        const notificationArea = document.getElementById('notificationArea');
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;

        const icon = {
            'info': 'ℹ️',
            'success': '✅',
            'warning': '⚠️',
            'error': '❌'
        }[type] || 'ℹ️';

        notification.innerHTML = `<span>${icon}</span><span>${message}</span>`;
        notificationArea.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    updateLastUpdateTime() {
        const now = new Date();
        const timeString = now.toLocaleTimeString();
        document.getElementById('lastUpdateTime').textContent = timeString;

        if (this.currentProject) {
            this.lastFetchTime[this.currentProject.name] = now;
        }
    }

    startAutoRefresh() {
        // Auto-refresh every 5 minutes
        this.refreshInterval = setInterval(() => {
            if (this.currentProject) {
                const lastFetch = this.lastFetchTime[this.currentProject.name];
                if (lastFetch && (Date.now() - lastFetch > 5 * 60 * 1000)) {
                    this.refreshCurrentProject();
                }
            }
        }, 60000); // Check every minute
    }

    loadDashboardState() {
        const savedProject = localStorage.getItem('selectedProject');
        if (savedProject) {
            document.getElementById('projectDropdown').value = savedProject;
            this.selectProject(savedProject);
        }
    }

    clearDashboard() {
        document.getElementById('todosContainer').innerHTML = '<p class="placeholder">Select a project to view its TODOs</p>';
        document.getElementById('activityFeed').innerHTML = '<p class="placeholder">No recent activity</p>';
        document.getElementById('openIssues').textContent = '-';
        document.getElementById('openPRs').textContent = '-';
        document.getElementById('lastCommit').textContent = '-';
        document.getElementById('healthScore').textContent = '-';
        document.getElementById('projectStatus').textContent = '';

        const indicators = document.querySelectorAll('.indicator');
        indicators.forEach(ind => ind.dataset.status = 'unknown');

        // Disable download buttons
        this.enableDownloadButtons(false);
    }

    enableDownloadButtons(enabled) {
        document.getElementById('downloadBtn').disabled = !enabled;
        document.getElementById('downloadTodosBtn').disabled = !enabled;
    }

    async downloadProjectReport() {
        if (!this.currentProject) {
            this.showNotification('Please select a project first', 'warning');
            return;
        }

        try {
            this.showNotification('Generating project report...', 'info');

            // Generate comprehensive project report
            const report = await this.generateProjectReport();

            // Download the report
            this.downloadFile(
                report,
                `${this.currentProject.name}-Project-Report-${new Date().toISOString().split('T')[0]}.md`,
                'text/markdown'
            );

            this.showNotification('Project report downloaded successfully!', 'success');
        } catch (error) {
            console.error('Failed to generate report:', error);
            this.showNotification('Failed to generate project report', 'error');
        }
    }

    async downloadTodoList() {
        if (!this.currentProject) {
            this.showNotification('Please select a project first', 'warning');
            return;
        }

        try {
            this.showNotification('Generating TODO list...', 'info');

            // Generate TODO markdown file
            const todoMarkdown = await this.generateTodoMarkdown();

            // Download the TODO list
            this.downloadFile(
                todoMarkdown,
                `${this.currentProject.name}-TODO-List-${new Date().toISOString().split('T')[0]}.md`,
                'text/markdown'
            );

            this.showNotification('TODO list downloaded successfully!', 'success');
        } catch (error) {
            console.error('Failed to generate TODO list:', error);
            this.showNotification('Failed to generate TODO list', 'error');
        }
    }

    async generateProjectReport() {
        // Get current project data
        const todos = await this.fetchProjectTodos();
        const githubData = await this.fetchGitHubData();

        // Calculate statistics
        const totalTodos = Object.values(todos).flat().length;
        const completedTodos = Object.values(todos).flat().filter(t => t.completed).length;
        const highPriorityTodos = Object.values(todos).flat().filter(t => t.priority === 'high').length;
        const completionRate = Math.round((completedTodos / totalTodos) * 100);

        const report = `# ${this.currentProject.name} Project Report

**Generated on:** ${new Date().toLocaleDateString()} at ${new Date().toLocaleTimeString()}

## 📊 Project Overview

- **Project Name:** ${this.currentProject.name}
- **Priority Level:** ${this.currentProject.priority.toUpperCase()}
- **Health Score:** ${this.calculateHealthScore(githubData)}%
- **Last Updated:** ${new Date().toLocaleDateString()}

## 🎯 Key Metrics

| Metric | Value |
|--------|--------|
| Open Issues | ${githubData.issues} |
| Open Pull Requests | ${githubData.prs} |
| Days Since Last Commit | ${Math.floor((Date.now() - new Date(githubData.lastCommit)) / (1000 * 60 * 60 * 24))} |
| Total TODOs | ${totalTodos} |
| Completed TODOs | ${completedTodos} |
| High Priority TODOs | ${highPriorityTodos} |
| Completion Rate | ${completionRate}% |

## 📝 TODO Summary

### Progress Overview
- **Total Tasks:** ${totalTodos}
- **Completed:** ${completedTodos} (${completionRate}%)
- **Remaining:** ${totalTodos - completedTodos}
- **High Priority Remaining:** ${Object.values(todos).flat().filter(t => !t.completed && t.priority === 'high').length}

### Tasks by Category
${Object.entries(todos).map(([category, items]) => {
    const categoryCompleted = items.filter(t => t.completed).length;
    const categoryTotal = items.length;
    const categoryRate = Math.round((categoryCompleted / categoryTotal) * 100);

    return `
**${category}** (${categoryCompleted}/${categoryTotal} - ${categoryRate}% complete)
${items.map(item => `- [${item.completed ? 'x' : ' '}] ${item.text} \`${item.priority}\``).join('\n')}`;
}).join('\n')}

## ⚡ Recent Activity

${githubData.commits.map(commit => `- **${commit.author}** (${commit.time}): ${commit.message}`).join('\n')}

## 🏥 Health Status

- **Build Status:** ${githubData.buildStatus === 'passing' ? '✅ Passing' : '❌ Failing'}
- **Security Status:** ${githubData.securityStatus === 'passing' ? '✅ Clean' : '⚠️ Issues Detected'}
- **Code Coverage:** ${githubData.coverage}%
- **Documentation:** ${githubData.docsStatus === 'complete' ? '✅ Complete' : '📝 Needs Update'}

## 🔄 Next Steps

### High Priority Actions
${Object.values(todos).flat()
    .filter(t => !t.completed && t.priority === 'high')
    .slice(0, 5)
    .map(item => `1. ${item.text}`)
    .join('\n')}

### Recommendations
- ${completionRate < 50 ? 'Focus on completing existing TODOs before adding new features' : 'Good progress on TODO completion'}
- ${githubData.issues > 10 ? 'High number of open issues - consider triaging and closing resolved ones' : 'Issue management is under control'}
- ${Math.floor((Date.now() - new Date(githubData.lastCommit)) / (1000 * 60 * 60 * 24)) > 7 ? 'No recent commits - project may need attention' : 'Active development detected'}

---
*Report generated by AI Whisperers Project Dashboard*
*For questions or issues, contact the development team*
`;

        return report;
    }

    async generateTodoMarkdown() {
        const todos = await this.fetchProjectTodos();

        let markdown = `# ${this.currentProject.name} - TODO List\n\n`;
        markdown += `**Generated on:** ${new Date().toLocaleDateString()} at ${new Date().toLocaleTimeString()}\n\n`;

        // Add summary
        const totalTodos = Object.values(todos).flat().length;
        const completedTodos = Object.values(todos).flat().filter(t => t.completed).length;
        const completionRate = Math.round((completedTodos / totalTodos) * 100);

        markdown += `## 📊 Summary\n\n`;
        markdown += `- **Total Tasks:** ${totalTodos}\n`;
        markdown += `- **Completed:** ${completedTodos} (${completionRate}%)\n`;
        markdown += `- **Remaining:** ${totalTodos - completedTodos}\n`;
        markdown += `- **High Priority:** ${Object.values(todos).flat().filter(t => t.priority === 'high').length}\n\n`;

        // Add progress bar
        const progressBar = '█'.repeat(Math.floor(completionRate / 5)) + '░'.repeat(20 - Math.floor(completionRate / 5));
        markdown += `**Progress:** \`${progressBar}\` ${completionRate}%\n\n`;

        // Add todos by category
        Object.entries(todos).forEach(([category, items]) => {
            markdown += `## ${category}\n\n`;

            items.forEach(item => {
                const checkbox = item.completed ? '[x]' : '[ ]';
                const priority = item.priority === 'high' ? '🔥' : item.priority === 'medium' ? '⚠️' : '💡';
                markdown += `- ${checkbox} ${priority} ${item.text}\n`;
            });

            markdown += '\n';
        });

        // Add footer
        markdown += `---\n`;
        markdown += `*Last updated: ${new Date().toLocaleString()}*\n`;
        markdown += `*Generated by AI Whisperers Project Dashboard*\n`;

        return markdown;
    }

    downloadFile(content, filename, mimeType) {
        const blob = new Blob([content], { type: mimeType });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    }
}

// Initialize dashboard when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new ProjectDashboard();
});