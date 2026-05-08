# AI Whisperers Infrastructure

Central documentation for the AI Whisperers production infrastructure.

**Last updated:** May 8, 2026
**Hermes Agent:** v0.13.0 (v2026.5.7)
**VPS:** Hostinger (72.61.44.159) — 32GB RAM, 387GB disk

---

## Quick Reference

| What | Where |
|------|-------|
| Hermes running | v0.13.0, Gateway active |
| Workspace | workspace.sunstein.cloud |
| Web UI | open-webui — port 30081 |
| API Server | 0.0.0.0:8642 |
| Telegram | @ArchMagusBot |
| Monitoring | Grafana — port 3030 |
| Repos | github.com/Ai-Whisperers (41 repos) |

---

## Infrastructure Stack

```
Hostinger VPS (72.61.44.159)
├── Hermes Agent (v0.13.0)
│   ├── 16 MCP servers
│   ├── 21 plugins (10 active)
│   ├── 956 skills
│   ├── 10 cron jobs
│   ├── Mnemosyne memory
│   └── 4-tier model routing
├── Docker Swarm (agent-net)
│   ├── traefik v3.5.3 (SSL/TLS)
│   ├── Postgres 14
│   ├── 28 client websites (Next.js)
│   ├── Grafana + Prometheus
│   ├── Evolution API + Redis
│   └── hermes-workspace
└── GitHub Actions CI/CD
```

---

## Full Documentation Files

### Core Setup
- [hermes-complete-documentation.md](./hermes-complete-documentation.md) — Complete Hermes Agent v0.13 setup: all MCPs, plugins, skills, cron, memory, config, routing, platforms, 38 Docker containers
- [hermes-ecosystem-master-inventory.md](./hermes-ecosystem-master-inventory.md) — Full ecosystem inventory: 110+ repos, all community tools, config optimizations, key people
- [ai-whisperers-org-audit.md](./ai-whisperers-org-audit.md) — Org-wide audit: 41 repos, Docker services, problems, upgrade roadmap
- [ai-whisperers-full-analysis.md](./ai-whisperers-full-analysis.md) — Deep analysis: AI-enabled repos, per-area upgrades, repol lifecycle

### Quick Start
1. SSH to VPS: `ssh root@72.61.44.159`
2. Check Hermes: `hermes --version`
3. Gateway status: `systemctl --user status hermes-gateway`
4. Cron jobs: `hermes cron list`
5. Skills: `hermes skills list`

### Key Commands
```bash
hermes gateway restart    # Restart messaging gateway
hermes cron list          # List scheduled jobs
hermes plugins list       # List enabled plugins
hermes memory status      # Check memory provider
hermes curator run        # Run skill curator
systemctl --user status hermes-gateway
```

---

## What Changed From Previous Docs

This repo replaces and consolidates:
- **aiw-docs** — stale, referenced OpenClaw/Java system
- **work-coordination** — agent swarm coordination (now handled by built-in Kanban)
- **company** — staff profiles (moved to separate repo)

**All three are now archived.** This is the single source of truth for infrastructure.

---

## How to Update This Documentation

1. Clone: `git clone https://github.com/Ai-Whisperers/infrastructure.git`
2. Edit the relevant `.md` file
3. Commit: `git add -A && git commit -m "update: what changed"`
4. Push: `git push`

When adding new MCPs, plugins, skills, or cron jobs, update `hermes-complete-documentation.md`.

---

## License

Internal use — AI Whisperers
