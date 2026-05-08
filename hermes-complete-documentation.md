# Ai-Whisperers — Complete Hermes Setup + AI-Enabled Repos Documentation
## May 8, 2026 — Hostinger VPS (72.61.44.159)

---

## PART 1: HERMES AGENT — Complete Setup Inventory

### Version & Core
| Item | Value |
|------|-------|
| Hermes Agent | v0.13.0 (v2026.5.7) |
| Python | 3.11.15 |
| OpenAI SDK | 2.33.0 |
| Config version | 23 |
| Gateway | Active (1d+ uptime, via systemd user service) |
| Workspace | workspace.sunstein.cloud (via Traefik) |
| API Server | 0.0.0.0:8642 (hermes-api-2026) |
| Dashboard | Not running (OOM on build) |

### Model Architecture (4-tier)
| Tier | Provider | Model | Cost/M | Tasks |
|------|----------|-------|--------|-------|
| T1 Main | deepseek (api.deepseek.com) | deepseek-chat | $0.14-0.28 | Interactive, cron, delegation |
| T2 Cheap | openrouter | gemini-2.5-flash | $0.05-0.15 | Vision, compression, session search, title gen, curator |
| T3 Trivial | deepseek | deepseek-chat | — | Approval, MCP, flush memories |
| Fallback 1 | deepseek | deepseek-chat | — | Primary fallback |
| Fallback 2 | custom:ollama-local | qwen2.5-coder:7b | Free | Local fallback |
| Fallback 3 | custom:litellm | groq-llama | Free | Last resort |

### Provider Profiles (ProviderProfile — v0.13 feature)
- `full-power` → deepseek-chat (default)
- `cheap` → gemini-2.5-flash (classification, extraction, triage, summary)
- `code` → deepseek-chat (write_code, refactor, debug)

### MCP Servers (16 enabled)
| Server | Type | Status | Notes |
|--------|------|--------|-------|
| brave-search | npx @brave/brave-search-mcp-server | Active | Brave API key |
| cloudflare | npx @cloudflare/mcp-server-cloudflare | Active | CF API token |
| context7 | npx @upstash/context7-mcp | Active | Documentation search |
| exa | npx exa-mcp-server | Active | Semantic search |
| filesystem | npx @modelcontextprotocol/server-filesystem /root | Active | File ops |
| github | npx @modelcontextprotocol/server-github | Active | GitHub API |
| sequential-thinking | npx .../server-sequential-thinking | Active | Structured reasoning |
| stripe | npx @stripe/mcp | Active | Payment ops |
| supabase | https://mcp.supabase.com/mcp (OAuth Bearer) | Active | DB queries |
| wikipedia | npx wikipedia-mcp | Active | Article fetch |
| postgres | npx .../server-postgres | Active | Read-only VPS Postgres |
| puppeteer | npx .../server-puppeteer | Active | Headless browser |
| memory-server | npx .../server-memory | Active | KV knowledge graph |
| arxiv | npx arxiv-mcp-server | Active | Paper search |
| atlassian | npx @sooperset/mcp-atlassian | Active | Jira/Confluence |
| obsidian | npx mcp-obsidian | Active | Note vault |

### Plugins (21 directories, 10 active via config)
| Plugin | Source | Status | What It Does |
|--------|--------|--------|-------------|
| cost_tracker | bundled | Active | Token tracking |
| disk-cleanup | bundled | Active | Auto-cleanup |
| google_meet | bundled | Active | Meeting join/transcribe |
| hermes-context-manager | entrepeneur4lyf | Active | 6-strategy silent context compression |
| hermes-lcm | bundled | Active | DAG context engine |
| hermes_otel | bundled | Active | OpenTelemetry |
| kanban | bundled | Active | Multi-agent work board |
| request_logger | bundled | Active | HTTP logging |
| rtk-rewrite | ogallotti | Active | 89% tool output reduction |
| spotify | bundled | Active | Music control |
| web-search-plus | community | Active | Multi-provider search |
| agent-analytics | Agent-Analytics | Cloned | Analytics dashboard tab |
| evey-bridge | 42-evey | Cloned | Claude Code bridge |
| hermes-skill-factory | Romanescu11 | Cloned | Auto-skills from workflows |
| hermes-web-search-plus | robbyczgw-cla | Cloned | Multi-provider search |
| hermes-webui | nesquena | Cloned | Web dashboard |
| hermes-workspace | outsourc-e | Deployed Swarm | Full web workspace |
| mnemosyne | AxDSan | Symlinked mem provider | SQLite+vector memory |
| plur | plur-ai | Cloned | Shared memory format |
| SkillClaw | AMAP-ML | Cloned | Skill evolution |
| vessel-browser | community | Cloned | AI-native browser MCP |

### Memory Providers (installed)
| Provider | Status | What It Adds |
|----------|--------|-------------|
| Built-in MEMORY.md + USER.md | Always active | Bounded agent/user notes |
| Built-in SQLite FTS5 | Always active | Full-text session search |
| **Mnemosyne** (188★) | **Active** | SQLite + sqlite-vec hybrid search, BEAM architecture (hot/episodic/scratchpad), temporal triples, sleep consolidation, 6 tools |
| Hindsight (8.3K★) | Past provider | Knowledge graph, cross-memory synthesis |
| Mem0 (55K★) | Installed | Server-side LLM extraction |
| Honcho | Installed | Dialectic user modeling |

### Skills (956 SKILL.md files)
**Official bundled (73):** Built-in with Hermes v0.13.0

**OnlyTerp's 13 ops skills:** audit-mcp, audit-approval-bypass, cost-report, daily-inbox-triage, hermes-weekly, meeting-prep, nightly-backup, pr-review, release-notes, rotate-secrets, spam-trap, telegram-triage, weekly-dep-audit

**wondelai/skills (40+):** UX research, design critique, marketing personas, CRO audit, product strategy, QA test design, code audit, CI/CD, architecture, refactoring, PR review

**Community installed:**
- litprog-skill (literate programming)
- maestro (long-running agents, plan-approve-execute)
- super-hermes (analyze own prompts)
- drawio (diagrams from text)
- hermeshub (community skill browser)
- execplan-skill (multi-step checkpoints)
- agentic-mcp-skill (progressive MCP)
- icarus-plugin (self-memory, train replacement)
- avoid-ai-writing (remove AI patterns)
- hermes-nextcloud (Nextcloud file/note/calendar)
- hermes-incident-commander (SRE automation)
- hermes-dojo (auto-improve skills)
- **Anthropic-Cybersecurity-Skills (754 skills, 6.1K★):** Mapped to MITRE ATT&CK, NIST CSF 2.0, D3FEND

### Hooks
| Hook | Fires On | Use |
|------|----------|-----|
| activity-logger | agent:start/end, session:start/end, command:* | Logs everything |
| error-tracker | agent:step | Catch loops/failures |
| long-task-alert | agent:step | Warn at 15+ iterations |
| pr-watcher | agent:end | Log PR creation |
| HMC hooks | pre/post tool call, pre LLM call, session end | Silent context compression |

### Cron Jobs (10 active)
| Name | Schedule | What It Does |
|------|----------|-------------|
| El Viajero Daily Briefing | 0 8 * * * | Admin WhatsApp briefing |
| El Viajero Low Stock Alert | 0 9,15 * * * | Stock <5 WhatsApp alert |
| el-viajero-lifecycle | every 60m | Abandoned cart + review reminders |
| elviajero-healthcheck | every 15m | API health → auto-force-deploy |
| weekly client priority tracker | 0 9 * * 1 | Update client-priority-tracker.md |
| seo-client-ranking-audit | 0 8 * * 1 | SERP ranking for 5 client sites |
| weekly-curator-report | 0 6 * * 1 | Curator skill cleanup summary |
| weekly-hermes-health-check | 0 7 * * 1 | hermes doctor + report |
| seo-24-7-monitor | every 120m | Disk, kanban, ranking drops |
| weekly-self-evolution | 0 5 * * 1 | GEPA DSPy evolution pass |

### Configuration Optimizations (OnlyTerp-derived)
- Compression: threshold=0.30, target_ratio=0.12, protect_last_n=15
- Prompt caching: 5m TTL, all content cached
- Goals /goal loop: enabled (40 turns, gemini-flash judge)
- Session auto-resume: 24h idle
- Checkpoints v2: auto_resume on
- DeepSeek prompt caching: active (90% cache-hit discount)
- MCP tools.resources=false, tools.prompts=false on all servers
- Security: redact_secrets, Tirith, command allowlist, website blocklist

### Messaging Gateway (4 platforms)
| Platform | Bot/Account | Status |
|----------|------------|--------|
| Telegram | @ArchMagusBot | Active |
| WhatsApp | Baileys bridge (wa-connect) | Active — 5 allowed users |
| Discord | Bot with seo-team channel | Active |
| API Server | 0.0.0.0:8642 | Active |

### Docker Infra (38 containers)
| Stack | Services | Status |
|-------|----------|--------|
| Client websites | 28 Next.js sites | 27/28 healthy (fun4me DOWN) |
| Traefik | v3.5.3, Let's Encrypt, agent-net | Healthy |
| Postgres | 14, 1 replica | Healthy |
| Monitoring | Grafana + prometheus + node-exporter + qdrant | Healthy |
| WhatsApp | evolution-api + redis + wa-connect | Healthy |
| Web UI | open-webui (port 30081) | Healthy |
| Workspace | hermes-workspace | Healthy |
| Space | space-agent | Healthy |
| VPS | 32GB RAM, 387GB disk, 59% used | Healthy |

---

## PART 2: GITHUB REPOS — ORG WIDE

### Repos with AI Setup Potential (relevant to this document)

| Repo | Size | Tech | AI Potential | Priority |
|------|------|------|-------------|----------|
| **paragu-ai-builder** | 479MB | Next.js/TS | **Blueprint AI site builder** — all client sites should derive from this. Add AI content gen, SEO automation, auto-deploy via Hermes cron. | HIGH |
| **Vete** | 150MB | Next.js/TS + Supabase | **Vet clinic AI** — appointment reminders, diagnostic support, billing automation. Not deployed. | HIGH |
| **telescope-ai** | 54KB | Python | **MCP server for telescope control** — already has MCP surface. Deploy to swarm, connect to Hermes. | MEDIUM |
| **depiflash** | 108KB | Next.js 15 | **Client site** — already deployed. SEO + content upgrades. | LOW |
| **fun4me** | 6KB | Next.js 16, Supabase | **E-commerce** — currently DOWN. Fix and add lifecycle automation. | HIGH (fix) |
| **anthro-party-argentina** | 29.8MB | SvelteKit | **Event site** — not typical stack. Learn from for future Svelte projects. | LOW |
| **work-hours-automated-reports** | 479KB | Python | **Hermes skill candidate** — wrap as skill, add cron for weekly reporting. | MEDIUM |
| **courses-website** | 114KB | Next.js/TS | **Deploy behind Traefik** — add AI course content generator cron. | LOW |
| **aiw-docs** | 45KB | Markdown | **Platform docs** — this document should be merged there. | MEDIUM |
| **mcp-for-deploys** | 186KB | TypeScript | **MCP deployment server** — integrate with paragu-ai-builder CI/CD. | LOW |
| **agentic-schemas** | 726KB | JS | **20 design patterns** — convert to agentskills.io skills. | LOW |
| **work-coordination** | 384KB | Markdown | **Kanban spec** — our Kanban plugin already covers this. | REFERENCE |
| **company** | 9.3MB | Python | **Staff profiles** — no AI angle. Keep as docs. | NONE |
| **hiv-antigen-ai** | 389MB | Python | **Bioinf ML research** — archive. Dataset in git is problematic. | NONE |
| **tnas-ternary-toolkit** | 268KB | Python | **Ternary NN research** — archive. Not production. | NONE |

### Repos Already Archived (34)
All repos with `[A]` tag: WPG-Amenities, Taller_Ocampos, agentic-schemas, ai-whisperers-portfolio-website, hiv-antigen-ai, cluster-template, Courses-Content, Summer-courses, deploy-automated-blueprint, blueprint-code-once, mcp-for-deploys, Odontology, local-models-server, organization-template, codon-encoder-api, tnas-ternary-toolkit, predictive-additive-capacity, ternary-vaes-analysis, photos-to-kml, psicologia-ia, mikie-fisio, infrastructure-cost-tracker, company, clinica-duerksen, solstein-mvp-demo, paragu-ai-platform, alejandro-villamayor, courses-website, .github, work-coordination, work-hours-automated-reports, folyo

---

## PART 3: COMMUNITY IMPROVEMENTS WE ADOPTED

| Source | Improvement | When | Impact |
|--------|------------|------|--------|
| **OnlyTerp** | 13 ops/dev/security skills | P0 | Audit, rotate, backup, cost-report, triage |
| **OnlyTerp** | Compression tuning 0.30/0.12/15 | P0 | ~40% more aggressive compression |
| **OnlyTerp** | MCP scoped access (resources=false) | P1 | Smaller tool surface, less prompt waste |
| **HMC (entrepeneur4lyf)** | 6-strategy silent context compression | P1 | Layered on built-in compressor |
| **Nous/self-evolution** | GEPA + DSPy evolution pipeline | P0 | Weekly self-improvement |
| **outsourc-e** | hermes-workspace + Traefik | P1 | Web UI at workspace.sunstein.cloud |
| **AxDSan** | Mnemosyne memory (188★) | P3 | Zero-dep SQLite+vector, BEAM architecture |
| **mukul975** | 754 cybersecurity skills (6.1K★) | P3 | MITRE ATT&CK mapped |
| **conorbronsdon** | avoid-ai-writing (1.4K★) | P3 | Strip AI patterns |
| **wondelai** | 40+ cross-platform skills (895★) | P0 | UX, marketing, CRO, QA, code audit |
| **Romanescu11** | skill-factory (246★) | P1 | Auto-generate skills |
| **AMAP-ML** | SkillClaw (1.2K★) | P1 | Dedup + evolve skills |
| **ogallotti** | rtk-rewrite (89% token reduction) | P1 | Tool output savings |
| **nesquena** | hermes-webui (6.2K★) | P1 | Web/phone chat UI |
| **diamond2nv** | hermesd TUI monitor | P2 | Live monitoring |
| **tokscale** | Token tracking | P2 | Per-agent cost visibility |
| **dodo-reach/fathah** | hermes-desktop (1.1K★/1.3K★) | N/A | Native Mac desktop |
| **EKKOLearnAI** | hermes-web-ui (4.0K★) | N/A | Config dashboard |
| **xaspx** | hermes-control-interface (612★) | N/A | Self-hosted dashboard |
| **clawvader-tech** | hermes-telegram-miniapp (215★) | N/A | Telegram Mini App |
| **pyrate-llama** | hermes-ui (106★) | N/A | Glassmorphic web UI |
| **Cranot** | super-hermes (146★) | P3 | Analyze own prompts |
| **tlehman** | litprog-skill (128★) | P3 | Literate programming |
| **ReinaMacCredy** | maestro (152★) | P3 | Plan-approve-execute |
| **Lethe044** | incident-commander | P3 | SRE auto-heal |
| **Yonkoo11** | hermes-dojo | P3 | Auto-improve weak skills |
| **42-evey** | evey-bridge-plugin | P3 | Claude Code bridge |
| **plur-ai** | plur shared memory | P3 | Cross-platform engram |
| **FahrenheitResearch** | weather-plugin | P3 | NWS data |
| **anpicasso** | chrome-profiles | P3 | Browser profile switching |
| **No** smart model routing | ❌ need OpenRouter key | — | Could save 30-50% on simple turns |
| **No** Langfuse tracing | ❌ medium effort | — | Observability |
| **No** mission-control | ❌ overkill for 1 VPS | — | Fleet orchestration |

---

## PART 4: DEPLOYMENT PATTERNS

### Client Website Stack (28 sites)
```
GitHub → GitHub Actions (build image) → Docker Swarm → Traefik → Cloudflare DNS → HTTPS
```

### Hermes Infra
```
Hermes Agent (host, systemd) → Gateway (systemd) → API Server (8642)
  → MCP Servers (16, via npx subprocesses)
  → Plugins (21, 10 active)
  → Skills (956 SKILL.md files)
  → Memory (Mnemosyne SQLite+vector + built-in FTS5)
  → Cron (10 jobs)
  → Platforms (Telegram, WhatsApp, Discord, API)
```

### VPS Layout
```
Hostinger VPS (72.61.44.159)
├── Hermes Agent (v0.13.0, host process)
│   ├── /root/.hermes/config.yaml (3690 lines)
│   ├── /root/.hermes/skills/ (956 skills)
│   ├── /root/.hermes/plugins/ (21 plugins)
│   ├── /root/.hermes/cron/jobs.json (10 jobs)
│   └── /root/.hermes/hermes-agent/ (source checkout)
├── Docker Swarm (agent-net)
│   ├── traefik (v3.5.3, SSL termination)
│   ├── Postgres (14)
│   ├── Evolution API + Redis
│   ├── Grafana + Prometheus
│   ├── 28 client websites
│   └── hermes-workspace
├── systemd user services
│   ├── hermes-gateway.service
│   └── hermes-dashboard.service (disabled — OOM)
└── GitHub org: Ai-Whisperers (41 repos)
```
