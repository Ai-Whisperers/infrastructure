# Ai-Whisperers — Complete Repo Analysis + AI System Upgrade Plan (May 2026)

---

## PART 1: INVENTORY — 41 Repos, 3 Tiers

### █ TIER 1 — Active & Deployed (30 Docker services)
| Docker Service | GitHub Repo | GitHub? | Tech | Status |
|---|---|---|---|---|
| paragu-ai-builder_web (3/3) | paragu-ai-builder | ✅ | Next.js, TypeScript, 478MB | HEALTHY |
| elviajero_web (2/2) | elviajero | ❌ PRIVATE? | Next.js 15+ | HEALTHY |
| fun4me_web (0/2) | fun4me | ✅ | Next.js 16.2.2, Supabase | DOWN |
| 3md-website_web (2/2) | 3md-website | ❌ MISSING | Next.js | HEALTHY |
| golden-visa-advisory_web (2/2) | golden-visa-advisory | ❌ MISSING | Next.js | HEALTHY |
| superspuma_web (2/2) | superspuma | ❌ MISSING | Next.js | HEALTHY |
| pitchy_web (2/2) | pitchy | ❌ MISSING | Next.js | HEALTHY |
| depiflash_web (2/2) | depiflash | ✅ | Next.js 15.3.6, 108KB | HEALTHY |
| nexa_web (1/1) | nexa-paraguay | ❌ PRIVATE? | Next.js Pages Router | HEALTHY |
| clinica-duerksen_web (2/2) | clinica-duerksen | ✅ ARCHIVED | N/A | HEALTHY (legacy) |
| anthro-party-argentina_web (2/2) | anthro-party-argentina | ✅ | SvelteKit | HEALTHY |
| 30vcs_web (1/1) | — | ❌ MISSING | N/A | HEALTHY |
| bichos-gym_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| brahm-the-racoon_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| cocodrilo-fitness_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| dayah-litworks_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| granja-cabral_web (1/1) | — | ❌ MISSING | N/A | HEALTHY |
| luis-de-leon-concept_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| magnolia-peluqueria_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| maiyu-atelier_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| mantra-spa_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| nicolas-duarte_website (1/1) | — | ❌ MISSING | N/A | HEALTHY |
| nudo_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| ozmontania_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| ozmontania-website_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| villamayor-asociados_web (2/2) | — | ❌ MISSING | N/A | HEALTHY |
| hermes-ws_hermes-workspace (1/1) | outsourc-e/hermes-workspace | ✅ external | PWA | HEALTHY |
| evolution_evolution_api (1/1) | — | ❌ | evoapicloud | HEALTHY |
| postgres_postgres (1/1) | — | ❌ | postgres:14 | HEALTHY |
| traefik_traefik (1/1) | — | ❌ | traefik:v3.5.3 | HEALTHY |
| openwebui_open-webui (1/1) | — | ❌ external | Open WebUI | HEALTHY |

**CRITICAL FINDING: ~20 Docker services have NO matching public GitHub repo.** These images may be built from private repos or built locally and pushed. This means no CI/CD, no source tracking, no version history, no change management.

### █ TIER 2 — GitHub Repos (Not Deployed)
| Repo | Language | Size | Last Push | Use |
|------|----------|------|-----------|-----|
| Vete | TypeScript | 150MB | 2026-04-20 | Multi-tenant vet clinic mgmt |
| telescope-ai | Python | 54KB | 2026-04-27 | AI telescope control (MCP ready) |
| aiw-docs | Markdown | 45KB | 2026-04-13 | Platform documentation |
| work-hours-automated-reports | Python | 479KB | 2026-03-04 | Clockify + DevOps reports |
| company | Python | 9.3MB | 2026-03-12 | Staff profiles, CVs, resumes |
| Courses-Content | Python | 9.2MB | 2026-03-12 | Training courses |
| courses-website | TypeScript | 114KB | 2026-03-04 | Courses website |
| work-coordination | Markdown | 384KB | 2026-03-04 | Agent swarm coordination |
| agentic-schemas | JS | 726KB | 2025-11-12 | 20 design patterns |
| mcp-for-deploys | TypeScript | 186KB | 2025-12-16 | MCP for deployments |
| deploy-automated-blueprint | Dockerfile | 87KB | 2025-12-11 | Quickstart blueprint |
| cluster-template | Python | 109KB | 2025-11-17 | K8s cluster template |
| blueprint-code-once | — | 13.6MB | 2025-12-21 | Arrow backbone blueprint |
| .github | Markdown | 19KB | 2026-03-04 | Org health files |
| folyo | JS | 80MB | 2026-03-04 | CV/resume Jekyll template |
| infrastructure-cost-tracker | Shell | 679KB | 2026-03-04 | [ARCHIVED] |

### █ TIER 3 — Research / ML / Legacy
| Repo | Language | Size | Last Push | Notes |
|------|----------|------|-----------|-------|
| hiv-antigen-ai | Python | 389MB | 2026-03-04 | Hyperbolic VAE — huge dataset |
| Taller_Ocampos | TS | 109MB | 2026-03-04 | Auto repair shop system |
| WPG-Amenities | JS | 37MB | 2025-09-30 | Hotel website |
| tnas-ternary-toolkit | Python | 268KB | 2026-01-03 | Ternary NN toolkit |
| ternary-vaes-analysis | Python | 43.8MB | 2026-01-21 | VAE analysis |
| predictive-additive-capacity | Python | 4.4MB | 2026-01-14 | ML capacity control |
| codon-encoder-api | Python | 143KB | 2026-02-05 | Codon encoding |
| psicologia-ia | Python | 113KB | 2026-03-04 | Psychology AI template |
| mikie-fisio | TS | 98KB | 2026-03-04 | Physiotherapy |
| local-models-server | PS1 | 14.2MB | 2026-03-04 | GGUF/ONNX server |

---

## PART 2: PROBLEMS IDENTIFIED

### Everything is the same stack, deployed differently
- 28 client websites → all Next.js + Tailwind
- But each one built independently, deployed independently, no shared components
- paragu-ai-builder is the blueprint → but only 2-3 sites actually use it
- elviajero has CI/CD (npm publish → docker), others don't

### No source control for 20+ running sites
- ~20 Docker services with NO matching GitHub repo
- Can't rollback, can't audit, can't track changes
- If the VPS dies, those sites are gone

### Old tech
- Postgres:14 (2023 era — 16/17 out)
- Most sites on Next.js 15 (stable, but 16.x is current)
- No Dependabot, no CodeQL, no automated upgrades

### fun4me is DOWN
- fun4me_web at 0/2 replicas
- exited (143) = SIGTERM, likely crash-looping

### 15 repos untouched since March
- AI research, ML repos, templates → all abandoned
- Some huge repos with sensitive data possible (local-models-server: 14MB with possible API keys)

---

## PART 3: AI SYSTEM UPGRADE PLAN

### IMMEDIATE (This Session)

| # | Action | Why | How |
|---|--------|-----|-----|
| 1 | **Fix fun4me** | Only down site | Check logs, rollback |
| 2 | **Add missing 20 repos to GitHub** | No source control | Push from Docker images, create repos |
| 3 | **Set up Dependabot** | All repos get auto-updates | Single .github/dependabot.yml |
| 4 | **Grafana alerting for 0/2 replicas** | Catch fun4me-like incidents | Add alert rules |

### SHORT-TERM (This Week)

| # | Action | Why | How |
|---|--------|-----|-----|
| 5 | **paragu-ai-builder as template** | All client sites from one blueprint | Add config-driven site generator |
| 6 | **Unified CI/CD template** | 20+ sites with no CI | One GHA workflow, 1 env var per site |
| 7 | **Automated rollback script** | Deployments are risky without rollback | docker service update --rollback |
| 8 | **Postgres 14→16 upgrade** | Security + performance | Dump → restore → test |
| 9 | **Docker weekly prune cron** | VPS disk cleanup | docker system prune -f --volumes |

### MEDIUM-TERM (This Month)

| # | Action | Why | How |
|---|--------|-----|-----|
| 10 | **hermes-incident-commander hook** | Auto-heal 0/2 replicas | Hook into Docker events |
| 11 | **SEO automation per client** | All 28 sites get ranking reports | Cron job per site |
| 12 | **Vete deployment** | Vet clinic app not deployed | Dockerize from source |
| 13 | **telescope-ai → MCP server deploy** | Connect telescope to Hermes | Docker service + MCP in config |
| 14 | **AI client onboarding pipeline** | New client → site → SEO → cron → covered | Automate from paragu-ai-builder |
| 15 | **Abandoned repo triage** | Archive or revive 15 dead repos | Review per repo |

---

## PART 4: REPOS THAT NEED AI SYSTEMS SET UP

### Repos that already have an AI angle — should be upgraded

| Repo | Current | Upgrade Path |
|------|---------|-------------|
| **telescope-ai** | Standalone Python app | Deploy as Docker service, add MCP server config to Hermes. Now callable from Hermes: `mcp_telescope_control` |
| **Vete** | Not deployed, not containerized | Dockerize. Add Supabase MCP. Add Hermes cron for appointment reminders/billing. |
| **work-hours-automated-reports** | Python script | Wrap as Hermes skill. Cron job auto-generates reports. |
| **mcp-for-deploys** | Prototype | Integrate into paragu-ai-builder deployment pipeline |
| **agentic-schemas** | Reference docs | Convert into agentskills.io skills. 20 design patterns → 20 skills |
| **deploy-automated-blueprint** | Dockerfile | Integrate into hermes-workspace deployment flow |
| **work-coordination** | Markdown | Convert to Kanban board spec. Use our Kanban plugin. |
| **courses-website** | Next.js | Deploy behind Traefik. Add AI course content generator cron. |
| **hiv-antigen-ai** | ML pipeline (389MB) | Wrap HPC MCP server around model inference. Hermes calls it for bioinf research. |
| **tnas-ternary-toolkit** | ML research | Build MCP tool for ternary NN optimization from Hermes |

### Repos that need NO AI — just lifecycle management

| Repo | Action |
|------|--------|
| Taller_Ocampos, WPG-Amenities, Odontology, Summer-courses | Archive (never touched since Dec 2025) |
| mikie-fisio, psicologia-ia, folyo | Archive (templates, 1 push each) |
| blueprint-code-once, cluster-template, organization-template | Archive (experimental) |
| company, aiw-docs, .github | Keep as-is (documentation) |
