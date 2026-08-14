# Security Notes

## Tracked Vulnerabilities

### validator.js URL Validation Bypass (CVE-2025-56200)

**Status:** Tracking - No patch available
**Severity:** Medium (CVSS 6.1)
**Affected Version:** validator.js <= 13.15.15
**Latest Available Version:** 13.15.15
**Published:** September 30, 2025

**Description:**
A URL validation bypass vulnerability exists in validator.js through version 13.15.15. The `isURL()` function uses '://' as a delimiter to parse protocols, while browsers use ':' as the delimiter. This parsing difference allows attackers to bypass protocol and domain validation by crafting URLs leading to XSS and Open Redirect attacks.

**Impact Assessment:**
- **Current Impact:** None - The codebase does not use `isURL()` directly or indirectly through `@IsUrl` decorator
- **Dependency Chain:** validator.js is a transitive dependency through class-validator@0.14.2
- **Risk Level:** Low - Vulnerability not exploitable in current codebase

**Mitigation:**
- Verified that `isURL()` function is not used anywhere in the codebase
- Verified that `@IsUrl` decorator from class-validator is not used
- Monitoring validator.js repository for patches
- Will update to patched version as soon as available

**Next Steps:**
1. Monitor validator.js GitHub releases for version > 13.15.15
2. Monitor class-validator for updates that may include patched validator.js
3. Update immediately when patch is released
4. No code changes required unless the affected function is introduced

**Last Updated:** 2025-10-16
