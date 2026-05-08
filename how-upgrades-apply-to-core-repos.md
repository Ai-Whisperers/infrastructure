# How Infra Upgrades Apply to Nexa Paraguay & paragu-ai-builder

---

## THE TWO CORE REPOS

### paragu-ai-builder (Multi-Tenant Site Engine)
- **Purpose:** Generate static marketing websites for ANY business type from templates + JSON config
- **Stack:** Next.js 15 + TypeScript + Supabase + Cloudflare Workers
- **Architecture:** `sites/<slug>/` → per-tenant JSON, shared React section pool, no per-tenant code
- **Running:** 3 replicas, `paragu-ai.com`, `www.paragu-ai.com`
- **GitHub:** 479MB — massive repo with templates, schemas, tokens, verticals, content, compliance
- **CLAUDE.md:** 8.3KB — "Universal Website Generation Engine"
- **Key dirs:** `src/schemas/`, `src/tokens/`, `src/registry/`, `src/verticals/`, `src/content/`, `sites/` (per-tenant)

### Nexa Paraguay (Client Standalone)
- **Purpose:** Single-client marketing + lead gen site for Nexa Paraguay (real estate + migration)
- **Stack:** Next.js 16 + React 19 + TypeScript + Pages Router + `@ai-whisperers/*` packages
- **Architecture:** JSON-driven SSR, `content/*.json`, `nexa-pages/*.json`, 26-section SECTION_MAP
- **Running:** 1 replica, `nexa.paragu-ai.com`, `elviajero.paragu-ai.com`
- **GitHub:** Private — 25+ pages, 4-locale (ES/EN/NL/DE), 59 MDX blog articles
- **Docs:** 13 categories (`docs/00-architecture/` through `docs/12-factory/`)

---

## APPLYING EACH INFRA UPGRADE

### 1. HERMES MODEL TIERS → Content Generation

| Tier | Model | Direct Use on These Repos |
|------|-------|--------------------------|
| **T1 deepseek-chat** | $0.14-0.28/M | Write complex content logic. Generate blog MDX draft. Analyze competitor sites |
| **T2 gemini-flash** | $0.05-0.15/M | **Translate 4 locales** (ES→EN→NL→DE). Extract SEO keywords. Generate blog slugs. Classify images |
| **T3 deepseek** | ~$0 | Approve content generations. Quick API calls during build |

Concrete use: `/goal "translate all 16 ES blog posts to EN,NL,DE and write MDX files"` → gemini-flash runs the translations tier, deepseek-chat writes the files. Hours of manual work → minutes.

### 2. 16 MCPS → Development & Operations

| MCP | What It Does for These Repos |
|-----|------------------------------|
| **supabase** | Read/write Supabase schema & data. Add tables for client CRM, lead tracking |
| **postgres** | Query VPS Postgres directly — check if a deployed site has DB issues |
| **github** | Create PRs, review diffs, merge — all from within conversation |
| **cloudflare** | Update Workers config. Set DNS records for new client subdomains |
| **puppeteer** | Run visual regression tests on deploy. Screenshot all pages for QA |
| **context7** | Look up Next.js/React docs when hitting build errors |
| **exa** | Research competitor sites. Find design inspiration |
| **stripe** | Configure payment (if either site adds checkout) |
| **wikipedia** | Pull region/country data for migration content (Nexa use case) |
| **filesystem** | Read/write config files during setup |
| **arxiv** | Research migration laws & policies (Nexa use case) |
| **sequential-thinking** | Debug complex build issues step by step |

Concrete use: "Start a PR on nexa-paraguay adding a new En Español service page" → Hermes reads `site.json`, copies existing service page, replaces content keys, creates PR.

### 3. 956 SKILLS → Cross-Area Upgrade

| Skill Area | Applied to paragu-ai-builder | Applied to Nexa Paraguay |
|-----------|------------------------------|--------------------------|
| **wondelai/refactoring-ui** | Audit design tokens. Fix spacing, color depth, visual hierarchy | Audit 26-section page. Identify UI debt |
| **wondelai/web-typography** | Review font choices across all 23 verticals | Review type scale in theme.ts |
| **wondelai/cro-methodology** | Add conversion audit to client intake process | Audit hero → CTA → form funnel |
| **wondelai/seo-super-agent** | Full keyword research + content gap analysis per vertical | Full SEO campaign for Nexa |
| **wondelai/storybrand-messaging** | Improve brand story per business type | Clarify Nexa's narrative positioning |
| **wondelai/ux-heuristics** | Audit all 26 section components for usability | 10-point heuristic evaluation of live site |
| **wondelai/design-everyday-things** | Apply affordance/signifier principles to section blocks | Review contact forms & CTAs |
| **cybersecurity/mitm prevention** | Review form data handling | Review lead data submission (WhatsApp) |
| **anthropic skills (754)** | Security audit of Supabase RLS, form validation | GDPR compliance for EU users |
| **skill-factory** | Auto-generate CLI scripts for common tasks | Auto-generate deploy runbook updates |

### 4. COMMUNITY PLUGINS → Automation

| Plugin | Applied to paragu-ai-builder | Applied to Nexa Paraguay |
|--------|------------------------------|--------------------------|
| **incident-commander** | Auto-heal if deployments fail. Monitor replica count | Auto-heal if nexa_web drops to 0 replicas |
| **evey-bridge** | Claude Code edits paragu-ai-builder code directly from Hermes | Same — bridge to local IDE |
| **SkillClaw** | Evolve build scripts as patterns emerge | Evolve deploy workflow |
| **hermes-dojo** | Auto-improve weak sections (component generation skill) | Auto-improve content generation pipeline |
| **agent-analytics** | Track build times, deploy frequency | Track visitor metrics across locales |
| **rtk-rewrite** | Reduce token waste during content generation | Shorter system prompts = cheaper locale translations |
| **plur** | Share generated session data across development sessions | Share locale/content work across dev sessions |

### 5. CRON JOBS → Ongoing Operations

| Cron | Applied to paragu-ai-builder | Applied to Nexa Paraguay |
|------|------------------------------|--------------------------|
| **elviajero-healthcheck** (15m) | Add builder-healthcheck equivalent → verify 3/3 replicas | Add nexa-healthcheck → verify 1/1 + content loads |
| **weekly-curator** (Mon 6am) | Clean up stale site configs, unused verticals | Clean up draft blog posts, stale images |
| **weekly-hermes-health** (Mon 7am) | Verify CI/CD pipeline status | Verify deploy pipeline + Supabase connection |
| **weekly-client-priority** (Mon 9am) | Track which verticals need content refresh | Re-prioritize Nexa content roadmap |
| **seo-24-7-monitor** (2h) | Monitor ranking drops for all 23 verticals | Monitor Nexa SERP position for key migration terms |
| **seo-ranking-audit** (Mon 8am) | Rank audit for builder-hosted sites | Rank audit for Nexa target keywords |

New crons we should add:
- `builder-site-healthcheck` (15m) — verify all `sites/*` configs still resolve
- `nexa-content-refresh` (weekly) — check Nexa blog for stale dates, suggest updates
- `builder-pr-queue` (daily) — review open PRs, auto-merge if CI passes

### 6. MEMORY (Mnemosyne) → Development Continuity

With Mnemosyne, Hermes remembers across sessions:
- paragu-ai-builder architecture decisions, why certain patterns were chosen
- Nexa Paraguay's brand voice, content rules, locale-specific constraints
- What was last worked on, what's blocked, where issues were left off
- Previously debugged build errors and their fixes

No more re-explaining the design decisions every session.

### 7. /GOAL RALPH-LOOP → Autonomous Feature Work

Set a single goal and Hermes works on it across turns with a judge evaluating progress:

```
/goal "add a new Real Estate vertical to paragu-ai-builder with 
       property listing schema, gallery component, and contact form"
```

Hermes would: create schema → register vertical → build components → create sample site → test → PR. Without needing handholding.

### 8. PROVIDERPROFILE → Cost-Optimized Work

| Profile | What Tasks Route Here |
|---------|----------------------|
| **cheap** (gemini-flash) | Translation, keyword extraction, image classification, slug generation, schema analysis |
| **code** (deepseek-chat) | Component generation, section writing, JSON schema creation, TypeScript logic |
| **full-power** (deepseek) | Architecture decisions, debug, code review, PR merge decisions |

### 9. CONFIG COMPRESSION (0.30/0.12/15) → Larger Context

With 0.12 target ratio, each conversation can hold ~3x more content before hitting limits. This directly helps when:
- Reviewing 23 verticals' worth of content in one session
- Translating 59 blog posts across 4 locales
- Auditing 26 section components

### 10. MCP ATLASSIAN → Jira Integration

If these repos have Jira/Confluence:
- Link Hermes conversations to Jira tickets
- Auto-create subtasks for content translation
- Search Confluence for client requirements

---

## CONCRETE WORKFLOWS

### Workflow A: Deploy New Client Site (was ~2 days → ~30 min)
```
1. User: "create site for Dentista Asunción"
2. Hermes reads paragu-ai-builder CLAUDE.md → understands multi-tenant architecture
3. Hermes creates sites/dentista-asuncion/ with site.json, content/es.json, tokens.json
4. Runs paragu-ai-builder: gemini-flash generates content, deepseek writes schema
5. Opens PR via GitHub MCP → CI builds → Traefik routes dentista.paragu-ai.com
6. Cron monitors site health (15m check)
7. Incident-commander auto-heals if deploy fails
```

### Workflow B: Add Service to Nexa Paraguay (was ~4h → ~10 min)
```
1. User: "add Visa de Residencia page to Nexa in all 4 locales"
2. Hermes reads nexa site.json, content/*.json, nexa-pages config
3. Duplicates existing service page structure, fills in new content
4. Creates nexa-pages/visa-residencia.json, content/*.json updates in 4 locales
5. Opens PR → CI builds → deploy → screenshots via puppeteer
6. WhatsApp AI bot (nexa instance) gets updated FAQ automatically
```

### Workflow C: SEO Audit All Sites (was manual → cron)
```
1. Weekly cron fires seo-ranking-audit
2. Hermes pulls all 28 client sites from Traefik labels
3. For each site: exa MCP searches top 10 SERP keywords
4. Checks paragu-ai-builder site config for SEO metadata
5. Generates report: keyword ranking, content gaps, recommendations
6. For Nexa specifically: checks 4-locale keyword coverage
7. Opens issues for top 3 gaps
```

### Workflow D: Content Translation Pipeline (was ~6h → ~15 min)
```
1. User writes new blog post in ES (needs NL/DE/EN)
2. Hermes reads the MDX from blog/es/
3. ProviderProfile routes translation to cheap (gemini-flash)
4. Writes NL MDX → DE MDX → EN MDX
5. Updates blog/*/*.json with new article catalogs
6. Opens PR → CI verifies all locales load correctly
7. SEO monitor adds new keywords to ranking tracker
```

### Workflow E: Infrastructure Incident (auto-heal)
```
1. fun4me drops to 0/2 (exactly what's happening now)
2. incident-commander detects 0-replica service
3. Runs: docker service logs fun4me_web → reads exit code 143 (SIGTERM)
4. Checks: is it image issue? Registry auth? OOM?
5. Attempts: docker service update --force fun4me_web
6. If still 0: rolls back to previous image
7. Reports: "fun4me: crash loop - image fun4me:prod exits 143"
```

---

## SUMMARY TABLE

| Infra Component | paragu-ai-builder Impact | Nexa Impact |
|-----------------|--------------------------|-------------|
| T2 gemini-flash | Translate content, SEO keywords | 4-locale translation pipeline |
| 16 MCPs | GitHub PRs, Supabase, Puppeteer QA | Cloudflare DNS, Postgres queries |
| 754 cybersec skills | Security audit forms/data | GDPR compliance |
| incident-commander | Auto-heal build failures | Auto-heal 0-replica crash |
| cron seo-ranking | Weekly audit all 23 verticals | Weekly Nexa keyword rank |
| /goal loop | Autonomous vertical creation | Autonomous page creation |
| Mnemosyne | Remember architecture decisions | Remember content rules |
| ProviderProfile | Cheap for translate, Code for logic | Same |
| Compression (0.30/0.12) | 3x more review per session | 3x more content per session |
| wondelai/refactoring-ui | Audit design tokens | Audit theme.ts, spacing |
| wondelai/cro-methodology | Audit conversion per vertical | Audit Nexa funnel |
| wondelai/seo-super-agent | Keyword research per industry | Full Nexa SEO campaign |
