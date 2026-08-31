# aiw-fallback — Cloudflare Worker (catch-all for *.paragu-ai.com)

This directory contains the canonical source for Cloudflare Workers deployed under
the Ai-Whisperers account (`9eb1832f3e42a1dbd6ba854f8d6a1cb2`).

## Workers in this directory

| Worker            | Routes                                         | Purpose                                                                 |
|-------------------|------------------------------------------------|-------------------------------------------------------------------------|
| `aiw-fallback.js` | `*.paragu-ai.com/*`                            | Catch-all. Routes recognized hostnames to CF Pages, 404s everything else |

## Deployment

Each file has a companion GitHub Actions workflow in `.github/workflows/`:

- `deploy-worker.yml` — uploads Worker scripts via the Cloudflare API

Both workflows require:
- `CLOUDFLARE_API_TOKEN` — repo or environment secret
- `CLOUDFLARE_ACCOUNT_ID` — repo or environment secret (currently `9eb1832f3e42a1dbd6ba854f8d6a1cb2`)

Set these under Settings → Environments → `production` so they don't leak to forks.

## Versioning

- The Worker keeps a 90-day version history on Cloudflare (last 20 + rollback)
- Bump the `vN` comment at the top of each script on every change
- Roll back via: `wrangler rollback aiw-fallback <version-id>` (or via dashboard)

## Hosts routed by `aiw-fallback`

| Host                          | Backend                              |
|-------------------------------|--------------------------------------|
| `geodata.paragu-ai.com`       | `paraguay-geodata.pages.dev`         |
| `datos.paragu-ai.com`         | `paraguay-geodata.pages.dev`         |

To add another host: extend `PAGES_BACKING` in `aiw-fallback.js` and commit.