# Infrastructure Repo - Merger Notice (2026-05-29)

This repository now contains **consolidated infrastructure** for Ai-Whisperers.

## Merged Repositories

The following repositories have been merged into this one:

| Source Repo | Location Here | Status |
|-------------|---------------|--------|
| `aiw-infra` | `/iac/` | ✓ Merged |
| `ci-cd` | `/ci/` | ✓ Merged |
| `Company-Information` | `/company/` | ✓ Merged |
| `priorities` | `/priorities/` | ✓ Merged |
| `mcp-for-deploys` | `/mcp/` | ✓ Merged |

## Directory Structure

```
infrastructure/
├── .github/          # GitHub workflows (original)
├── iac/              # Infrastructure as Code (from aiw-infra)
├── ci/               # CI/CD workflows (from ci-cd)
├── company/          # Company documentation (from Company-Information)
├── priorities/       # Operational priorities (from priorities)
├── mcp/              # MCP server for deployments (from mcp-for-deploys)
└── *.md             # Root-level documentation (original)
```

## Why This Merge?

1. **Single Source of Truth:** All infrastructure in one place
2. **Reduced Overhead:** 5 fewer repos to maintain
3. **Better Discoverability:** Everything related to infrastructure in one location
4. **Easier Updates:** Change once, deploy everywhere

## What Happened to Source Repos?

All source repos have been archived. They exist for history only.

**If you were referencing any of the source repos:**

- Update your references to point to this repo
- Use the subdirectory paths listed above
- Old URLs will redirect to archived repos (read-only)

## Next Steps

1. ✓ Merge completed (2026-05-29)
2. ⏳ Archive source repos (aiw-infra, ci-cd, Company-Information, priorities, mcp-for-deploys)
3. ⏳ Update internal documentation and references
4. ⏳ Notify team members of new structure

## Contact

Questions about this merger? Contact the DevOps team or open an issue.