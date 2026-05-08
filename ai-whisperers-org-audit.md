# Ai-Whisperers — Complete Organization Audit & Upgrade Roadmap (May 2026)

---

## SECTION 1: ORG STRUCTURE — 40 REPOS

### Active Client Websites (Docker Swarm Deployed)
| Repo | GitHub URL | Tech | Docker | Status |
|------|-----------|------|--------|--------|
| paragu-ai-builder | AI-powered website builder for beauty & wellness PY | Next.js/TS | paragu-ai:prod (3/3) | ACTIVE |
| elviajero | Paraguayan food e-commerce | Next.js/TS | elviajero:prod (2/2) | ACTIVE |
| fun4me | Adult store e-commerce | Next.js/TS | fun4me:prod (0/2 FAIL) | DOWN |
| 3md-website | Marketing digital PY | Next.js/TS | 3md-website:prod (2/2) | ACTIVE |
| 3md_web | Marketing digital PY (legacy) | Next.js/TS | 3md-website:prod (2/2) | ACTIVE |
| golden-visa-advisory | Paraguay golden visa | Next.js/TS | golden-visa-advisory:prod (2/2) | ACTIVE |
| goldenvisa | Golden visa (secondary) | Next.js/TS | golden-visa-advisory:prod (2/2) | ACTIVE |
| superspuma | Superspuma store | Next.js/TS | superspuma:prod (2/2) | ACTIVE |
| pitchy | Pitchy app | Next.js/TS | pitchy:prod (2/2) | ACTIVE |
| maiyu-atelier | Atelier store | Next.js/TS | maiyu-atelier:prod (2/2) | ACTIVE |
| villamayor-asociados | Law firm | Next.js/TS | villamayor-asociados:prod (2/2) | ACTIVE |
| luis-de-leon-concept | Artist portfolio | Next.js/TS | luis-de-leon-concept:prod (2/2) | ACTIVE |
| mantra-spa | Spa website | Next.js/TS | mantra-spa:prod (2/2) | ACTIVE |
| cocodrilo-fitness | Gym website | Next.js/TS | cocodrilo-fitness:prod (2/2) | ACTIVE |
| bichos-gym | Gym website | Next.js/TS | bichos-gym:prod (2/2) | ACTIVE |
| magnolia-peluqueria | Hair salon | Next.js/TS | magnolia-peluqueria:prod (2/2) | ACTIVE |
| ozmontania | Outdoors store | Next.js/TS | ozmontania-website:prod (2/2) | ACTIVE |
| ozmontania-website | Outdoors (standalone) | Next.js/TS | same image | ACTIVE |
| dayah-litworks | Art/litworks | Next.js/TS | dayah-litworks-deploy:prod (2/2) | ACTIVE |
| depiflash | Laser hair removal | Next.js/TS | depiflash:prod (2/2) | ACTIVE |
| nudo | Restaurant | Next.js/TS | nudo:prod (2/2) | ACTIVE |
| brahm-the-racoon | Fun4Me brand | Next.js/TS | brahm-the-racoon:latest (2/2) | ACTIVE |
| anthro-party-argentina | Event website | SvelteKit | anthro-party-argentina:prod (2/2) | ACTIVE |
| clinica-duerksen | Medical clinic | Next.js/TS | clinica-duerksen:prod (2/2) | ACTIVE |
| 30vcs | (unknown) | Next.js | 30vcs:latest (1/1) | ACTIVE |
| nicolas-duarte_website | Personal site | Next.js | nicolas-duarte-site:latest (1/1) | ACTIVE |
| granja-cabral | Farm website | Next.js | granja-cabral:prod (1/1) | ACTIVE |
| nexa-paraguay | Paraguay business portal | Next.js (Pages Router) | nexa-paraguay:prod (1/1) | ACTIVE |

### Internal / Tools / Templates
| Repo | Description | Language | Last Push |
|------|------------|----------|-----------|
| Vete | Multi-tenant vet clinic mgmt — Next.js 15, Supabase | TS/Next.js | 2026-04-20 |
| aiw-docs | Platform documentation | Markdown | 2026-04-13 |
| telescope-ai | AI telescope control (Celestron) | Python | 2026-04-27 |
| work-hours-automated-reports | Clockify + Azure DevOps reports | Python | 2026-03-04 |
| company | Staff profiles, CVs, resumes | Markdown | 2026-03-12 |
| Courses-Content | Professional training courses | Markdown | 2026-03-12 |
| courses-website | Courses website | Next.js | 2026-03-04 |
| work-coordination | AI agent swarm coordination | N/A | 2026-03-04 |
| agentic-schemas | 20 agentic design patterns | Markdown | 2025-11-12 |
| mcp-for-deploys | MCP server for deploys | N/A | 2025-12-16 |
| deploy-automated-blueprint | Quickstart deploy blueprint | N/A | 2025-12-11 |
| cluster-template | K8s cluster config | YAML | 2025-11-17 |
| blueprint-code-once-deploy-everywhere | Arrow backbone OSS | N/A | 2025-12-21 |
| organization-template | GH org template | Markdown | 2025-12-25 |
| .github | Org community health files | Markdown | 2026-03-04 |
| folyo | CV/resume Jekyll template | Jekyll | 2026-03-04 |

### Archived / Superseded
| Repo | Superseded By | Archived |
|------|--------------|----------|
| paragu-ai-platform | paragu-ai-builder | 2026-04-30 |
| clinica-duerksen-standalone | paragu-ai-builder | 2026-04-30 |
| solstein-mvp-demo | solstein-coder | 2026-04-30 |
| photos-to-kml | — | 2026-04-30 |
| infrastructure-cost-tracker | — | 2026-04-30 |
| ai-whisperers-portfolio-website | paragu-ai-builder | 2026-04-30 |

### Research / ML
| Repo | Description | Last Push |
|------|------------|-----------|
| hiv-antigen-ai | Hyperbolic & 3-adic VAE for bioinformatics | 2026-03-04 |
| tnas-ternary-toolkit | Ternary {-1,0,1} neural network weights | 2026-01-03 |
| ternary-vaes-analysis | Architecture analysis | 2026-01-21 |
| predictive-additive-capacity-control-library | ML capacity control | 2026-01-14 |
| codon-encoder-api | Codon encoding API | 2026-02-05 |
| local-models-server | GGUF/ONNX model server config | 2026-03-04 |
| psicologia-ia | Psychology practice tools | 2026-03-04 |
| mikie-fisio | Physiotherapy | 2026-03-04 |

---

## SECTION 2: INFRASTRUCTURE (Docker Swarm)

**38 containers across 30+ services, all on 1 VPS (Hostinger, 32GB RAM, 387GB disk)**

### Services Running (Docker Swarm)
| Category | Count | Details |
|----------|-------|---------|
| Client websites | 28 | Mostly Next.js, behind Traefik |
| Messaging infra | 3 | evolution-api, evolution-redis, wa-connect |
| Monitoring | 4 | grafana, prometheus, node-exporter, qdrant |
| Database | 1 | postgres:14 |
| Web UI | 1 | open-webui |
| Workspace | 1 | hermes-workspace |
| Edge infra | 1 | space-agent |
| **Total** | **~38** | |

### Infra Stack
- **Orchestrator:** Docker Swarm (not Kubernetes)
- **Reverse proxy:** Traefik v3.5.3 (auto SSL via Let's Encrypt)
- **Network:** agent-net (shared across all services)
- **Domains:** Various *.sunstein.cloud, *.paragu-ai.com, *.cloud domains
- **Build system:** GitHub Actions → build image → deploy to swarm

---

## SECTION 3: ISSUES FOUND

### P0 — Critical (Needs immediate attention)
1. **fun4me_web: 0/2 replicas** — service is DOWN. Exited (143) loops.
2. **Dashboard systemd crashes** — OOM during frontend build on this VPS.
3. **GitHub MCP broken** — auth failing, cannot push/PR from Hermes.

### P1 — High Priority
4. **No CI/CD on most client sites** — 14+ repos on ci-cd but ~10+ aren't automated.
5. **fun4me_web stuck at 0/2** — needs investigation.
6. **No automated security scanning** — no Dependabot, no CodeQL, no Snyk across org.
7. **Older repos unpushed** — 15 repos not pushed since 2026-03-04 (abandoned).

### P2 — Medium
8. **Multi-site image tag duplication** — `3md-website:prod` used by 2 services, `golden-visa-advisory:prod` by 2 services.
9. **No unified build/deploy tool** — each site built independently via GitHub Actions.
10. **No monitoring alerts** — Grafana runs but no alerting configured.
11. **Postgres:14** — version is 2+ years old, should upgrade to 16/17.

### P3 — Low
12. **folyo, cluster-template, organization-template** — never pushed to since creation.
13. **local-models-server** — contains API keys in git history risk.
14. **No Dependabot across 40 repos.**

---

## SECTION 4: ECOSYSTEM UPGRADES — What We Can Apply Per Work Area

### A) Client Websites (28 Next.js sites)
**Current:** Each site is its own Next.js app with identical stack (Tailwind, shadcn/ui)
**Problem:** Massive duplication — 28 separate builds, 28 separate deploys, 28 Docker images

**Hermes-powered upgrades to implement:**

| Upgrade | Effort | Impact | How |
|---------|--------|--------|-----|
| 1. **paragu-ai-builder blueprint upgrade** | Medium | All sites | Add shared component library, auto-generate sites from template |
| 2. **Automated SEO cron** per site | Low | All sites | Use existing seo-24-7-monitor + seo-client-ranking-audit patterns per client |
| 3. **Web Vitals monitoring cron** | Low | All sites | New cron: curl each site, check Lighthouse scores, log regressions |
| 4. **Automated content refresh** | Medium | Content sites | Cron job per site to query Google Trends, suggest blog updates |
| 5. **Image optimization pipeline** | Low | All sites | Add Sharp layer, auto-compress on deploy via GitHub Action |
| 6. **Automated A/B testing** | High | High-traffic | Add GrowthBook/PostHog to paragu-ai-builder template |
| 7. **Telegram/WhatsApp deploy notifications** | Low | All sites | Gateway hook: on build success, send status to client channel |

### B) E-commerce (elviajero, fun4me, superspuma, ozmontania)
**Current:** Each has product DB, cart, checkout, WhatsApp notification
**Problem:** fun4me is DOWN. All could share inventory/cart infrastructure.

**E-commerce upgrades:**

| Upgrade | Effort | Impact | How |
|---------|--------|--------|-----|
| 1. **Fix fun4me deployment** | Medium | fun4me | Find crash in logs, rollback or rebuild |
| 2. **elviajero lifecycle expansion** | Low | All | Current lifecycle cron checks abandoned carts — add coupon triggers, loyalty |
| 3. **Shared Supabase schema** | High | All ecom | Consolidate Postgres tables into one Supabase project with tenant_id |
| 4. **WhatsApp order notifications** | Low | All | Use existing wa-connect + Hermes gateway to broadcast order updates |
| 5. **Automated restock alerts** | Low | All | Cron: check stock levels, generate WhatsApp alerts (we have this for elviajero) |
| 6. **Price drop tracking** | Medium | All | Cron: competitor price scraping → alert if undercut |

### C) DevOps / Infrastructure
**Current:** Docker Swarm on single VPS, Traefik, no monitoring alerts

**DevOps upgrades:**

| Upgrade | Effort | Impact | How |
|---------|--------|--------|-----|
| 1. **Grafana alerting** | Low | All infra | Add alert rules per service health check |
| 2. **Postgres upgrade 14→16** | Medium | DB | Dump, restore to 16 container, test |
| 3. **Hindsight memory on VPS** | Low | Hermes | Already installed — train on client deployment data |
| 4. **Automated deploy rollback** | Low | All sites | Add rollback.sh that restores previous Docker image tag |
| 5. **Unified CI/CD pipeline** | Medium | 28 sites | One GitHub Action template all repos reference |
| 6. **Docker image cleanup cron** | Low | VPS disk | Prune old images weekly |
| 7. **fail2ban for VPS** | Low | Security | Install and configure |
| 8. **Dependabot across org** | Medium | All repos | Add .github/dependabot.yml, create issues for ~15 unpushed repos |

### D) Bioinformatics & ML Research
**Current:** hiv-antigen-ai, tnas-ternary-toolkit, ternary-vaes-analysis, predictive-additive-capacity-control

**Upgrades:**

| Upgrade | Effort | Impact | How |
|---------|--------|--------|-----|
| 1. **MCP server for bioinf tools** | Medium | Research | Wrap hiv-antigen models as MCP tools → callable from Hermes |
| 2. **telescope-ai → MCP** | Medium | Astronomy | Already has MCP server — deploy to swarm, hook to Hermes |
| 3. **Automated experiment tracking** | Low | ML | Add MLflow hooks, track experiments from Hermes sessions |
| 4. **Paper digest cron** | Low | Research | Weekly cron: fetch arxiv papers on bioinf/ternary nets, summarize |

### E) Hermes Agent Itself
**Already installed** — see /root/hermes-ecosystem-master-inventory.md

**Remaining to add from Priorities:**

| Item | Effort | Status |
|------|--------|--------|
| Fix GitHub MCP auth | Low | ❌ MCP broke during session |
| fun4me deploy fix | Medium | ❌ Service at 0/2 |
| Grafana alerting | Low | ❌ |
| Postgres upgrade 14→16 | Medium | ❌ |
| Dependabot across org | Medium | ❌ |
| Automated rollback script | Low | ❌ |

---

## SECTION 5: IMMEDIATE NEXT STEPS (This Session)

| # | Action | Effort | Who |
|---|--------|--------|-----|
| 1 | **Fix fun4me deployment** — check logs, rollback if needed | 15 min | Me |
| 2 | **Fix GitHub MCP** — re-auth or restart | 5 min | Me |
| 3 | **Add Grafana alert rules** | 20 min | Me |
| 4 | **Dependabot PR for org** | 10 min | Me |
| 5 | **Postgres backup + upgrade** | 30 min | Need approval |
