# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please send an email to security@ai-whisperers.com. All security vulnerabilities will be promptly addressed.

Please do not publicly disclose the vulnerability until it has been addressed by the team.

## Security Updates

### Current Security Status

#### CVE-2025-54798: tmp Package Symlink Vulnerability (LOW)

**Status:** Mitigated via npm overrides
**Severity:** Low (CVSS 2.5)
**Affected Component:** `tmp` package (dev dependency)
**Fix Applied:** 2025-10-02

**Details:**
- **Vulnerability:** The `tmp` package (≤ 0.2.3) allows arbitrary temporary file/directory write via symbolic link
- **Impact:** Local attacker with high complexity could write files outside temp directory
- **Mitigation:** Added npm override to enforce `tmp@^0.2.4` which patches this issue
- **Risk Level:** Very Low - development dependency only, requires local access

**Dependency Chain:**
```
@nestjs/cli → inquirer → external-editor → tmp (vulnerable)
```

**Applied Fix:**
Added to `package.json`:
```json
{
  "overrides": {
    "tmp": "^0.2.4"
  }
}
```

**Note:** A clean install (`npm ci` or delete `node_modules` and run `npm install`) is required to fully apply the override. The override ensures all future installations use the patched version.

**References:**
- CVE-2025-54798
- GitHub Advisory: GHSA-52f5-9888-hmc6
- Fixed in: tmp@0.2.4

### Security Best Practices

1. **Dependencies**: Run `npm audit` regularly to check for vulnerabilities
2. **Updates**: Keep dependencies up to date with `npm update`
3. **Secrets**: Never commit secrets to the repository - use `.env` files (gitignored)
4. **Access Control**: Use environment-specific credentials and limit access appropriately
5. **Code Review**: All changes require peer review before merging to main

### Dependency Security

- **npm audit**: Run automatically in CI/CD pipeline
- **Dependabot**: Enabled for automatic security updates
- **Overrides**: Used to patch transitive dependencies when needed
- **Review Process**: All dependency updates reviewed before merging

## Security Features

### Authentication & Authorization
- GitHub OAuth for user authentication
- Environment-based API keys for service-to-service communication
- Role-based access control (RBAC) for dashboard features

### Data Protection
- Sensitive data stored in environment variables
- Database credentials encrypted at rest
- CORS configured to allow only trusted origins
- HTTPS enforced in production

### Infrastructure Security
- All services run with minimal required permissions
- Redis (if enabled) requires authentication
- Database connections use SSL/TLS in production
- Regular security audits of deployed infrastructure

## Compliance

This project follows:
- OWASP Top 10 security guidelines
- npm security best practices
- Industry-standard secret management practices

## Security Checklist for Contributors

Before submitting a PR:
- [ ] No secrets or credentials committed
- [ ] All new dependencies scanned with `npm audit`
- [ ] Authentication/authorization properly implemented for new endpoints
- [ ] Input validation added for user-supplied data
- [ ] Error messages don't leak sensitive information
- [ ] Security-relevant changes documented

---

*Last Updated: 2025-10-02*
