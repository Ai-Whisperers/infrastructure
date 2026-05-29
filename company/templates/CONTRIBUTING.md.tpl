# Contributing to {{REPOSITORY_NAME}}

First off, thank you for considering contributing to {{REPOSITORY_NAME}}! It's people like you that make the AI-Whisperers community such a great place to learn, inspire, and create.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Pull Requests](#pull-requests)
- [Development Process](#development-process)
- [Style Guidelines](#style-guidelines)
  - [Git Commit Messages](#git-commit-messages)
  - [Code Style](#code-style)
  - [Documentation Style](#documentation-style)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by the [AI-Whisperers Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@ai-whisperers.com.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/{{REPOSITORY_NAME}}.git`
3. Create a branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Commit your changes: `git commit -m 'feat: add amazing feature'`
6. Push to your fork: `git push origin feature/amazing-feature`
7. Open a Pull Request

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear and descriptive title**
- **Exact steps to reproduce the problem**
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Environment details** (OS, versions, etc.)

### Suggesting Features

Feature suggestions are welcome! Please provide:

- **Clear and descriptive title**
- **Detailed description** of the proposed feature
- **Use case** explaining why this feature would be useful
- **Possible implementation** approach (if you have ideas)
- **Alternative solutions** you've considered

### Pull Requests

1. **Follow the style guidelines** below
2. **Include tests** for new functionality
3. **Update documentation** as needed
4. **Ensure CI passes** before requesting review
5. **Link related issues** in the PR description
6. **Request review** from maintainers

## Development Process

1. **Branch Naming**:
   - `feature/` - New features
   - `fix/` - Bug fixes
   - `docs/` - Documentation changes
   - `refactor/` - Code refactoring
   - `test/` - Test additions/changes
   - `chore/` - Maintenance tasks

2. **Testing Requirements**:
   - All new features must have tests
   - Bug fixes should include regression tests
   - Maintain or improve code coverage

3. **Review Process**:
   - At least one maintainer approval required
   - All CI checks must pass
   - No merge conflicts
   - Up-to-date with main branch

## Style Guidelines

### Git Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks
- `perf`: Performance improvements

Example:
```
feat(api): add user authentication endpoint

Implements JWT-based authentication for API endpoints.
Includes refresh token mechanism and role-based access.

Closes #123
```

### Code Style

#### JavaScript/TypeScript
- Use ESLint configuration
- Prefer `const` over `let`
- Use meaningful variable names
- Add JSDoc comments for functions

```javascript
/**
 * Calculate the health score for a repository
 * @param {Object} metrics - Repository metrics
 * @returns {number} Health score (0-100)
 */
function calculateHealthScore(metrics) {
  // Implementation
}
```

#### Python
- Follow PEP 8
- Use type hints
- Add docstrings

```python
def calculate_health_score(metrics: dict) -> int:
    """
    Calculate the health score for a repository.

    Args:
        metrics: Repository metrics dictionary

    Returns:
        Health score between 0 and 100
    """
    # Implementation
```

### Documentation Style

- Use Markdown for documentation
- Include code examples
- Keep language clear and concise
- Update README when adding features

## Community

- **Discord**: [AI-Whisperers Community](https://discord.gg/ai-whisperers)
- **Forum**: [discussions.ai-whisperers.com](https://discussions.ai-whisperers.com)
- **Twitter**: [@AIWhisperers](https://twitter.com/AIWhisperers)

## Recognition

Contributors will be recognized in:
- The project's CONTRIBUTORS.md file
- Release notes
- Our community spotlight

Thank you for contributing to AI-Whisperers! 🎉