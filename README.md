# AI Whisperers Infrastructure

Central documentation for the AI Whisperers production infrastructure.

**Last updated:** May 8, 2026
**Hermes Agent:** v0.13.0 (v2026.5.7)
**VPS:** Hostinger (72.61.44.159)
**Hostname:** agentzero

---

## TABLE OF CONTENTS

1. [Quick Reference](#quick-reference)
2. [VPS Specifications](#vps-specifications)
3. [Domain Map (30+ sites)](#domain-map)
4. [Docker Services (38)](#docker-services)
5. [Networks & Ports](#networks--ports)
6. [Hermes Agent Setup](#hermes-agent-setup)
7. [Infrastructure Diagram](#infrastructure-diagram)
8. [Key Commands](#key-commands)
9. [How Client Websites Work](#how-client-websites-work)
10. [Repos & AI Setup Potential](#repos--ai-setup-potential)
11. [Devices & Access](#devices--access)
12. [Upgrade Roadmap](#upgrade-roadmap)
13. [Previous Docs (Archived)](#previous-docs-archived)

---

## Quick Reference

| What | Value |
|------|-------|
| SSH | root@72.61.44.159 |
| Hermes | v0.13.0 — Gateway active |
| Workspace | workspace.sunstein.cloud |
| Web Chat | hermes-chat.paragu-ai.com (Open WebUI) |
| Telegram | @ArchMagusBot |
| API Key | hermes-api-2026 on port 8642 |
| Monitoring | monitor.paragu-ai.com (Grafana) |
| Main site | paragu-ai.com |
| DNS | Cloudflare |
| SSL | Traefik + Let's Encrypt |
| Domains | 30+ sites across paragu-ai.com, sunstein.cloud |

---

## VPS Specifications

| Spec | Value |
|------|-------|
| Provider | Hostinger |
| IP | 72.61.44.159 |
| Hostname | agentzero |
| OS | Ubuntu 24.04.4 LTS |
| CPU | AMD EPYC 9354P (8 vCPUs) |
| RAM | 31 GB (17 GB available) |
| Disk | 387 GB (292 GB used — 76%) |
| Swap | 4 GB (2.6 GB used) |
| Kernel | 6.8.0-90-generic |

### Users
- `root` — full access
- `ubuntu` — system user

### Tailscale
- Tailscale IP: 100.91.243.120
- VPN access to the VPS without public SSH

---

## Domain Map

### paragu-ai.com (client websites)
These are all SaaS-style sites — one per client, mostly Next.js on Docker Swarm behind Traefik.

| Site | URL | Stack | Status |
|------|-----|-------|--------|
| paragu-ai | paragu-ai.com | Next.js/TS | ACTIVE |
| 3md | 3md-website.paragu-ai.com | Next.js | ACTIVE |
| 30vcs | 30vcs.paragu-ai.com | Next.js | ACTIVE |
| Anthro Party AR | anthro-party-argentina.paragu-ai.com | SvelteKit | ACTIVE |
| Bichos Gym | bichosgym.paragu-ai.com | Next.js | ACTIVE |
| Brahm Raccoon | brahm.paragu-ai.com | Next.js | ACTIVE |
| Clinica Duerksen | clinicaduerksen.paragu-ai.com | Next.js | ACTIVE |
| Cocodrilo Fitness | cocodrilofitness.paragu-ai.com | Next.js | ACTIVE |
| Dayah Litworks | dayah.paragu-ai.com | Next.js | ACTIVE |
| Depiflash | depiflash.paragu-ai.com | Next.js 15 | ACTIVE |
| El Viajero | viajero.paragu-ai.com / el-viajero.paragu-ai.com | Next.js 15+ | ACTIVE |
| Fun4Me | fun4me.paragu-ai.com | Next.js 16 | **DOWN** (0/2) |
| Golden Visa | goldenvisa.paragu-ai.com | Next.js | ACTIVE |
| Granja Cabral | granjacabral.paragu-ai.com | Next.js | ACTIVE |
| Luis de Leon | luisleon.paragu-ai.com | Next.js | ACTIVE |
| Magnolia Peluqueria | magnolia-peluqueria.paragu-ai.com | Next.js | ACTIVE |
| Maiyu Atelier | maiyu.paragu-ai.com | Next.js | ACTIVE |
| Mantra Spa | mantraspa.paragu-ai.com | Next.js | ACTIVE |
| Nico Duarte | nicolas-duarte.paragu-ai.com | Next.js | ACTIVE |
| Nudo | nudo.paragu-ai.com | Next.js | ACTIVE |
| Ozmontania | ozmontania.paragu-ai.com | Next.js | ACTIVE |
| Pitchy/Vitrumpy | pitchy.paragu-ai.com / vitrumpy.paragu-ai.com | Next.js | ACTIVE |
| Superspuma | superspuma.paragu-ai.com | Next.js | ACTIVE |
| Villamayor | villamayor.paragu-ai.com | Next.js | ACTIVE |

### sunstein.cloud (infrastructure)

| Service | URL | What | Status |
|---------|-----|------|--------|
| Hermes Workspace | workspace.sunstein.cloud | Web UI + terminal for Hermes | ACTIVE |
| Evolution API | evolution.sunstein.cloud | WhatsApp message bridge | ACTIVE |
| Space Agent | space.sunstein.cloud | Edge compute | ACTIVE |
| Open WebUI | hermes-chat.paragu-ai.com | Open WebUI chat frontend | ACTIVE |
| WhatsApp AI | whatsapp-ai.sunstein.cloud | AI WhatsApp agent | ACTIVE |

---

## Docker Services

### Infrastructure (system)
| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| traefik | traefik:v3.5.3 | 80/443 | Reverse proxy, SSL, routing |
| postgres | postgres:14 | 5432 | Primary database |
| evolution_api | evoapicloud/evolution-api:latest | 8080 | WhatsApp API |
| evolution_redis | redis:latest | — | WhatsApp session cache |
| grafana | grafana/grafana:latest | 3030 | Monitoring dashboard |
| prometheus | prom/prometheus:latest | 9090 | Metrics collection |
| node-exporter | prom/node-exporter:latest | — | VPS metrics |
| portainer | portainer/portainer-ce:latest | 9000 | Docker management UI |
| open-webui | ghcr.io/open-webui/open-webui:main | 30081 | Chat frontend |
| hermes-workspace | ghcr.io/outsourc-e/hermes-workspace | 3000 | Hermes web UI |
| space-agent | space-agent:latest | — | Edge compute |
| wa-connect | whatsapp-connect:v3 | — | WhatsApp bridge |
| whatsapp-ai | whatsapp-ai-agent:v3.0.1 | 8000 | AI WhatsApp bot |

### Client Websites (28 services)
All Next.js-based. See [Domain Map](#domain-map) for URLs.

---

## Networks & Ports

### Docker Swarm Networks
| Network | Scope | Purpose |
|---------|-------|---------|
| agent-net | overlay | Main swarm — all client websites + Traefik |
| aiw-infra-net | overlay | Infrastructure services |
| ingress | overlay | Traefik ingress routing |
| docker_gwbridge | local | Docker host gateway |
| docker0 | bridge | Default Docker bridge |

### Key Ports
| Port | Service | Notes |
|------|---------|-------|
| 80 | HTTP → Traefik | Redirects to 443 |
| 443 | HTTPS → Traefik | All SSL traffic |
| 3000 | hermes-workspace | Web UI |
| 3030 | Grafana | Monitoring |
| 5432 | Postgres | Database |
| 8080 | Evolution API | WhatsApp |
| 8642 | Hermes API | API key: hermes-api-2026 |
| 9090 | Prometheus | Metrics |
| 9000 | Portainer | Docker UI |
| 30081 | Open WebUI | Chat |
| 11434 | Ollama | Local models (inactive) |
| 4000 | LiteLLM | Model proxy (inactive) |

---

## Hermes Agent Setup

### Version & Core
- **Hermes:** v0.13.0 (v2026.5.7) — 222 commits behind HEAD
- **Python:** 3.11.15
- **Config:** `~/.hermes/config.yaml` (config version 23)

### Model Architecture
| Tier | Provider | Model | Cost/M | Use |
|------|----------|-------|--------|-----|
| T1 Main | deepseek | deepseek-chat | $0.14-0.28 | Interactive, cron, delegation |
| T2 Cheap | openrouter | gemini-2.5-flash | $0.05-0.15 | Vision, compression, search, curator |
| T3 Trivial | deepseek | deepseek-chat | — | Approval, MCP, flush memories |
| Fallback 1 | deepseek | deepseek-chat | — | Primary fallback |
| Fallback 2 | ollama-local | qwen2.5-coder:7b | Free | Local fallback |
| Fallback 3 | litellm | groq-llama | Free | Last resort |

### Provider Profiles (v0.13)
- `full-power` → deepseek-chat (default)
- `cheap` → gemini-2.5-flash (classification, extraction, triage, summary)
- `code` → deepseek-chat (write_code, refactor, debug)

### 16 MCP Servers
See [hermes-complete-documentation.md](./hermes-complete-documentation.md) for full list.

### 21 Plugins (10 active)
See [hermes-complete-documentation.md](./hermes-complete-documentation.md) for full list.

### 956 Skills
- 73 official Hermes bundled
- 13 OnlyTerp ops/dev/security skills
- 40+ wondelai cross-platform skills
- 754 Anthropic cybersecurity skills (MITRE ATT&CK mapped)
- 76+ community skills (litprog, maestor, super-hermes, drawio, execplan, agentic-mcp, avoid-ai-writing, nextcloud, incident-commander, dojo, etc.)

### 10 Cron Jobs
See [hermes-complete-documentation.md](./hermes-complete-documentation.md) for full list.

### Memory
- **Active:** Mnemosyne (SQLite + vector search, zero deps)
- **Also available:** Hindsight, Mem0, Honcho (installed but not active)
- **Always active:** Built-in MEMORY.md + USER.md + FTS5 session search

### Messaging
| Platform | Bot ID | Notes |
|----------|--------|-------|
| Telegram | @ArchMagusBot | Active — seo-team channel configured |
| WhatsApp | Baileys bridge via Evolution API | 5 allowed users |
| Discord | Bot | seo-team channel prompt |
| API | 0.0.0.0:8642 | Key: hermes-api-2026 |

---

## Infrastructure Diagram

```
Internet
  │
  ▼ 80/443
Cloudflare DNS
  │
  ▼
Traefik v3.5.3 (SSL termination + routing)
  │
  ├── *.paragu-ai.com ──► 28 client websites (Next.js, Docker Swarm)
  │
  └── *.sunstein.cloud
      ├── workspace ──► hermes-workspace (web UI)
      ├── evolution ──► Evolution API (WhatsApp)
      ├── space ──► Space Agent
      ├── hermes-chat ──► Open WebUI
      └── whatsapp-ai ──► WhatsApp AI bot

Host (agentzero VPS)
  ├── Hermes Agent (systemd)
  │   ├── Gateway (Telegram, Discord, WhatsApp, API)
  │   ├── 16 MCP servers (subprocess)
  │   ├── 10 cron jobs
  │   └── 956 skills
  │
  ├── Docker Swarm (38 containers)
  │   ├── traefik, postgres, grafana, prometheus
  │   ├── evolution-api + redis
  │   └── 28 client websites
  │
  ├── Postgres (main database)
  └── Portainer (Docker UI)
```

---

## Key Commands

### System
```bash
ssh root@72.61.44.159          # SSH to VPS
htop                           # Live CPU/RAM
df -h                          # Disk usage
docker stats                   # Container resource use
```

### Hermes
```bash
hermes --version               # Check version
hermes doctor                  # Full system audit
hermes cron list               # List scheduled jobs
hermes cron trigger <id>       # Manual cron run
hermes plugins list            # List all plugins
hermes skills list             # Search/install skills
hermes memory status           # Check memory provider
hermes config check            # Validate config
hermes tools list              # All available tools
hermes mcp list                # MCP servers
hermes curator run             # Cleanup skills
systemctl --user restart hermes-gateway  # Restart gateway
systemctl --user status hermes-gateway   # Gateway status
```

### Docker
```bash
docker service ls              # All swarm services
docker service logs <name>     # Service logs
docker service ps <name>       # Service replicas
docker system df               # Docker disk usage
```

### Common Debugging
```bash
curl https://<site>.paragu-ai.com  # Test site
docker service update --force <name>  # Force redeploy
docker service scale <name>=<n>  # Scale replicas
journalctl -u docker.service -n 50  # Docker logs
tail -f ~/.hermes/logs/agent.log   # Hermes agent log
```

---

## How Client Websites Work

### Deployment Flow
1. **Developer pushes code** to GitHub (paragu-ai-builder or standalone repo)
2. **GitHub Actions** builds Docker image (e.g. `elviajero:prod`)
3. **Docker Swarm** pulls image and deploys
4. **Traefik** discovers new service via Docker labels and provisions SSL
5. **Cloudflare DNS** points domain to VPS IP

### Stack per Site
```
Next.js (TypeScript) → Docker Swarm → Traefik → Cloudflare → End User
       │                    │             │            │
   ESM Bundle           container         SSL       CDN cache
   Server Components    replicas       Let's Encrypt  DDoS protection
```

### CI/CD (varies)
- **elviajero** — automatic via GitHub Packages + deploy
- **paragu-ai-builder** — automatic via GitHub Actions
- **~20 other sites** — built locally or manually, no CI/CD
- **~28 Docker images** — most built with nixpacks / `docker build`

---

## Repos & AI Setup Potential

### High Priority
| Repo | What We Should Do |
|------|-------------------|
| paragu-ai-builder (479MB) | Make blueprint for ALL client sites. Add AI content gen, SEO automation, auto-deploy cron |
| Vete (150MB) | Dockerize and deploy. Add AI appointment reminders, diagnostic support |
| telescope-ai (54KB) | Deploy MCP server, connect to Hermes for telescope control |
| fun4me (6KB) | **Fix deployment** — currently 0/2 replicas |

### Medium Priority
| Repo | What We Should Do |
|------|-------------------|
| work-hours-automated-reports | Wrap as Hermes skill. Cron auto-generates weekly reports |
| courses-website | Deploy behind Traefik. Add AI content generator cron |
| aiw-docs | Archived — content now in this repo |
| mcp-for-deploys | Integrate into paragu-ai-builder CI/CD |

### Low / Reference
| Repo | Notes |
|------|-------|
| agentic-schemas | 20 design patterns — could convert to skills |
| work-coordination | Archived — Kanban plugin covers this |
| company | Archived — staff profiles |

---

## Devices & Access

### VPS
| Device | How to Access |
|--------|--------------|
| Hostinger VPS agentzero | SSH: `ssh root@72.61.44.159` |
| Tailscale | Tailscale IP: `100.91.243.120` — VPN access |
| Portainer | Docker UI — access via SSH tunnel or port 9000 (internal) |

### Desktops / Laptops
| System | Purpose | Hermes Access |
|--------|---------|--------------|
| (not on VPS) | Development machines | Via Telegram @ArchMagusBot, WhatsApp, or `workspace.sunstein.cloud` |

### Remote Access Paths
```
CLI:   ssh root@72.61.44.159 → tmux → hermes chat
Web:   Browser → workspace.sunstein.cloud
Telegram: @ArchMagusBot → /chat
WhatsApp: Send message to bot number
API:   POST http://72.61.44.159:8642/v1/chat/completions (key: hermes-api-2026)
```

---

## Upgrade Roadmap

### This Week
| # | Task | Priority |
|---|------|----------|
| 1 | Fix fun4me (0/2 replicas) | CRITICAL |
| 2 | Add 20 missing repos to GitHub | HIGH |
| 3 | Set up Dependabot across org | HIGH |
| 4 | Grafana alert rules | MEDIUM |
| 5 | Automated Docker prune cron | MEDIUM |

### This Month
| # | Task | Priority |
|---|------|----------|
| 6 | postgres 14→16 upgrade | MEDIUM |
| 7 | Unified CI/CD template for all sites | MEDIUM |
| 8 | Vete Dockerization + deploy | MEDIUM |
| 9 | telescope-ai MCP deploy | LOW |
| 10 | Archive 15 abandoned repos | LOW |

### Longer Term
| # | Task | Notes |
|---|------|-------|
| 11 | Convert paragu-ai-builder to config-driven site generator | All 28 sites from 1 blueprint |
| 12 | Hermes smart model routing | Needs OpenRouter key |
| 13 | Langfuse self-hosted tracing | Observability |

---

## Key Files

| File | What's In It |
|------|-------------|
| `hermes-complete-documentation.md` | Full Hermes setup — all MCPs, plugins, skills, cron, memory, config |
| `hermes-ecosystem-master-inventory.md` | Ecosystem map — 110+ repos, key people, community tools |
| `ai-whisperers-org-audit.md` | 41 repos, Docker services, upgrade roadmap |
| `ai-whisperers-full-analysis.md` | Deep analysis — AI problem detection per area |

---

## Previous Docs (Archived)

| Archived Repo | Old Purpose | Why Archived |
|--------------|-------------|--------------|
| Ai-Whisperers/aiw-docs | Platform documentation | Stale — referenced OpenClaw, Java, tools no longer used |
| Ai-Whisperers/work-coordination | Agent swarm coordination | Superseded by Hermes Kanban plugin |
| Ai-Whisperers/company | Staff profiles, CVs | Not infrastructure documentation |
