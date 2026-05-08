# Hermes Ecosystem — Complete Master Inventory (May 2026)
Source: Hermes Atlas (110+ repos), awesome-hermes-agent, OnlyTerp guide, official docs, community research

---

## SECTION 1: CORE & OFFICIAL (Nous Research)

| # | Repo | Stars | Trend | Description | Installed? |
|---|------|-------|-------|-------------|------------|
| 1 | NousResearch/hermes-agent | 138.6K | +11.2K/wk | Core — self-improving AI agent, v0.13.0 | ✅ v0.13.0 |
| 2 | hermes-agent-self-evolution | 2.9K | +243/wk | DSPy + GEPA — evolves skills/prompts/code | ❌ |
| 3 | Hermes-Function-Calling | 1.3K | +15/wk | Training data for function-calling models | ❌ |
| 4 | atropos | 1.2K | +31/wk | RL training environments for tool-calling | ❌ |
| 5 | hermes-paperclip-adapter | 1.1K | +72/wk | Hermes as managed Paperclip employee | ❌ |
| 6 | autonovel | 882 | +48/wk | 100k+ word novel-writing pipeline | ❌ |

---

## SECTION 2: MCP SERVERS (10 installed, 27 available)

### Already Installed ✅
| # | Server | Command | Purpose |
|---|--------|---------|---------|
| 1 | sequential-thinking | npx @modelcontextprotocol/server-sequential-thinking | Structured reasoning |
| 2 | filesystem | npx @modelcontextprotocol/server-filesystem /root | File operations |
| 3 | github | npx @modelcontextprotocol/server-github | GitHub API |
| 4 | context7 | npx @upstash/context7-mcp | Docs/code examples search |
| 5 | cloudflare | npx @cloudflare/mcp-server-cloudflare | Workers, KV, D1, R2 |
| 6 | exa | npx exa-mcp-server | Semantic web search |
| 7 | brave-search | npx @brave/brave-search-mcp-server | Web search |
| 8 | stripe | npx @stripe/mcp | Payment ops |
| 9 | wikipedia | npx wikipedia-mcp | Article fetch |
| 10 | supabase | https://mcp.supabase.com/mcp | DB queries |

### Recommended to Install
| # | Server | What It Adds | Why |
|---|--------|-------------|-----|
| 11 | @modelcontextprotocol/server-postgres | Read-only SQL to Postgres | Query 20+ client project DBs |
| 12 | @modelcontextprotocol/server-sqlite | SQLite analysis | Parse cron/session DBs |
| 13 | @modelcontextprotocol/server-puppeteer | Headless browser automation | Beyond our browser tool |
| 14 | @modelcontextprotocol/server-memory | KV knowledge graph | Lightweight memory |
| 15 | @modelcontextprotocol/server-google-drive | Drive file access | Client document reading |
| 16 | @modelcontextprotocol/server-slack | Slack message/search | Already have Discord bridge |
| 17 | @linear/mcp-server-linear | Linear issue CRUD | Issue tracking |
| 18 | @notion/mcp-server-notion | Notion page read/write | Client wikis |
| 19 | @browserbase/mcp-server | Managed headless browser | Hard scraping |
| 20 | @chromadb/mcp-server-chroma | Vector search via ChromaDB | Semantic retrieval |
| 21 | arxiv-mcp-server | Arxiv search + PDF extraction | Research |
| 22 | mcp-server-atlassian | Jira + Confluence | Client project mgmt |
| 23 | dbt-mcp | dbt Cloud queries | Data analytics |
| 24 | mcp-server-e2b | Disposable Python sandboxes | Safe code execution |
| 25 | mcp-obsidian | Obsidian vault access | Personal notes |
| 26 | mem0/mcp-server-mem0 | Cross-device memory | Outside Hermes memory |
| 27 | Cloudflare Observability MCP | Worker logs/analytics | We use Cloudflare |

### MCP Observed Config Pattern (OnlyTerp Part 17)
```yaml
mcp_servers:
  SERVER_NAME:
    enabled_for: [delegation, cron]  # scoped access
    default_trust: untrusted          # security
    sampling: deny                    # no LLM calls from MCP
    tools:
      include: [tool1, tool2]        # minimal tool surface
      resources: false                # disable if not needed
      prompts: false                  # disable if not needed
```

---

## SECTION 3: PLUGINS (13 installed, 22 total available)

### Already Installed ✅
| # | Plugin | Function | State |
|---|--------|----------|-------|
| 1 | cost_tracker | Token/cost tracking | Active |
| 2 | disk-cleanup | Disk space management | Active |
| 3 | google_meet | Meeting join/transcribe | Active |
| 4 | hermes-lcm | DAG-based context engine | Active |
| 5 | hermes_otel | OpenTelemetry observability | Active |
| 6 | kanban | Multi-agent work board | Active |
| 7 | request_logger | HTTP request logging | Active |
| 8 | rtk-rewrite | 89% token reduction on tool output | Active |
| 9 | spotify | Music playback control | Active |
| 10 | web-search-plus | Multi-provider search routing | Active |
| 11 | autocontext | Recursive self-improving context | Cloned |
| 12 | clawshell | Runtime security beyond redact_secrets | Cloned |
| 13 | hindsight | Long-term memory (plugin only) | Cloned |
| 14 | vessel-browser | AI-native browser for MCP control | Cloned |
| 15 | hermes-ccc | Claude Code channel integration | Cloned |
| 16 | hermes-payguard | USDC/x402 payment plugin | Cloned |
| 17 | hermes-blockchain-oracle | Solana blockchain intelligence | Cloned |
| 18 | hermes-skill-factory | Auto-generates skills from workflows | Cloned |
| 19 | hermes-web-search-plus | Multi-provider search (dupe of #10) | Cloned |
| 20 | hermes-webui | Web dashboard | Cloned |
| 21 | hermes-webui (nesquena) | Best web UI (6.2K★) | In plugins/ |

### Available to Install
| # | Plugin | Stars | What It Adds |
|---|--------|-------|-------------|
| 22 | Hermes Context Manager (HMC) | — | Silent-first context compression, 6 strategies, live dashboard |
| 23 | hermes-dashboard-lightrag | — | Graph explorer tab for web dashboard |
| 24 | hermes-dashboard-langfuse | — | Langfuse traces inline |
| 25 | hermes-dashboard-costs | — | Per-provider cost chart |
| 26 | Pi Dynamic Context Pruning | — | Original context optimization (HMC based on this) |

---

## SECTION 4: HOOKS (4 installed, Many Available)

### Already Installed ✅
| # | Hook | Fires On | What It Does |
|---|------|----------|-------------|
| 1 | activity-logger | agent:start/end/step, session:start/end, command:* | Logs all activity |
| 2 | error-tracker | agent:step | Catches loops/failures |
| 3 | long-task-alert | agent:step | Warns at 15+ iterations |
| 4 | pr-watcher | agent:end | Logs PR creation |

### Available to Install (from OnlyTerp)
| # | Hook/Skill | What It Does | Category |
|---|-----------|-------------|----------|
| 5 | audit-mcp | Audit MCP server security posture | Security |
| 6 | rotate-secrets | Rotate API keys/secrets | Security |
| 7 | audit-approval-bypass | Audit approval bypass config | Security |
| 8 | nightly-backup | Nightly backup of Hermes data | Ops |
| 9 | weekly-dep-audit | Weekly dependency audit | Ops |
| 10 | cost-report | Token/cost reporting | Ops |
| 11 | telegram-triage | Triage inbound Telegram messages | Communication |
| 12 | pr-review | Automated PR review | Dev |
| 13 | release-notes | Generate release notes from commits | Dev |
| 14 | daily-inbox-triage | Email inbox triage | Ops |
| 15 | hermes-weekly | Weekly Hermes health report | Ops |
| 16 | spam-trap | Spam detection | Security |
| 17 | meeting-prep | Meeting preparation brief | Dev |

---

## SECTION 5: MEMORY PROVIDERS (8 available)

| # | Provider | Stars | Storage | Cost | Tools | Unique Feature | Installed? |
|---|----------|-------|---------|------|-------|----------------|------------|
| 1 | Hindsight | 8.3K | Local/Cloud | Free/Paid | 3 | Knowledge graph + reflect synthesis. 91.4% LongMemEval | ❌ |
| 2 | Mem0 | 55K | Cloud | Freemium | 3 | Server-side LLM extraction, fastest setup | ❌ |
| 3 | Honcho | — | Cloud | Paid/AGPL | 5 | Dialectic user modeling (models HOW you think) | ❌ |
| 4 | Supermemory | — | Cloud | Paid | 4 | Context fencing, multi-container, session graph | ❌ |
| 5 | Holographic | — | Local SQLite | Free | 2 | Zero deps, HRR algebra + trust scoring | ❌ |
| 6 | OpenViking | — | Self-hosted | Free | 5 | Tiered L0/L1/L2 loading, 80-90% token savings | ❌ |
| 7 | RetainDB | — | Cloud | $20/mo | 5 | Hybrid search (Vector+BM25+reranking) | ❌ |
| 8 | ByteRover | — | Local/Cloud | Free/Paid | 3 | Human-readable Markdown knowledge tree | ❌ |

**Recommendation for our setup:** Hindsight in `local_embedded` mode — free, runs via PostgreSQL daemon, per-client isolation via `bank_id` scoping, uses our existing LiteLLM proxy, knowledge graph entity extraction. Best recall accuracy (91.4% at 10M+ tokens).

---

## SECTION 6: WEB UIs & DASHBOARDS

| # | Project | Stars | Trend | Best For | Deployed? |
|---|---------|-------|-------|----------|-----------|
| 1 | nesquena/hermes-webui | 6.2K | +895/wk HOT | Web/phone chat — best overall | Cloned |
| 2 | outsourc-e/hermes-workspace | 3.6K | +785/wk HOT | Full workspace: chat, terminal, memory, skills, inspector | ❌ |
| 3 | EKKOLearnAI/hermes-web-ui | 4.0K | +734/wk | Multi-platform config dashboard | ❌ |
| 4 | xaspx/hermes-control-interface | 612 | +118/wk | Self-hosted terminal, files, cron, metrics | ❌ |
| 5 | dodo-reach/hermes-desktop | 1.1K | +351/wk | Native Mac workspace | ❌ |
| 6 | fathah/hermes-desktop | 1.3K | +469/wk | Desktop companion | ❌ |
| 7 | chrisryugj/hermes-dashboard | — | — | Web admin (config, MCP, cron, skills) | ❌ |
| 8 | Bichev/hermes-dashboard | — | — | Analytics/cost proxy dashboard | ❌ |
| 9 | pyrate-llama/hermes-ui | 106 | +12/wk | Glassmorphic web UI | ❌ |
| 10 | open-webui | 50K+ | — | General AI chat frontend | ✅ Port 30081 |
| 11 | diamond2nv/hermesd | — | — | TUI monitoring dashboard (terminal only) | ❌ |
| 12 | clawvader-tech/hermes-telegram-miniapp | 215 | +3/wk | Telegram Mini App SPA | ❌ |

---

## SECTION 7: MULTI-AGENT & SWARM FRAMEWORKS

| # | Tool | Stars | What It Adds | Use For |
|---|------|-------|-------------|---------|
| 1 | Kanban (built-in) | In Hermes | Multi-profile collaboration board, workers can orchestrate | ✅ Already using |
| 2 | mission-control | 3.9K | Fleet management, task dispatch, cost tracking | Large-scale fleet orchestration |
| 3 | SkillClaw | 1.2K | Collective skill dedup + evolution | Clean our 76 skills |
| 4 | self-evolution (GEPA) | 2.9K | DSPy + GEPA optimizes skills from execution traces | Weekly evolution cron |
| 5 | swarmclaw | — | Multi-agent swarms (overkill for our scale) | Skip — overkill |

---

## SECTION 8: SKILLS ECOSYSTEM

| # | Skill Library | Stars | Description | Installed? |
|---|--------------|-------|-------------|------------|
| 1 | mukul975/Anthropic-Cybersecurity-Skills | 6.1K | 754 cybersecurity skills, MITRE ATT&CK mapped | ❌ |
| 2 | wondelai/skills | 895 | Cross-platform skills library | ❌ |
| 3 | Agents365-ai/drawio-skill | 1.3K | Natural language → diagrams | ❌ Forced install |
| 4 | AMAP-ML/SkillClaw | 1.2K | Let skills evolve collectively | ❌ |
| 5 | Romanescu11/hermes-skill-factory | 246 | Auto-generate skills from workflows | ✅ Cloned |
| 6 | smartcontractkit/chainlink-agent-skills | 100 | Oracle network skills | ❌ |
| 7 | tlehman/litprog-skill | 128 | Literate programming skill | ❌ |
| 8 | hermes-skins | 293 | Community CLI themes | ❌ Cloned |
| 9 | Cranot/super-hermes | 146 | Hermes writes its own analytical prompts | ❌ |
| 10 | PederHP/skillsdotnet | 9 | C# .NET skills with MCP | ❌ |
| 11 | armelhbobdad/bmad-module-skill-forge | 64 | Converts repos/docs into skills | ❌ |
| 12 | amanning3390/hermeshub | 53 | Community skill browsing/install hub | ❌ |
| 13 | chigwell/skilldock.io | 61 | Registry of reusable AgentSkills | ❌ |
| 14 | tiann/execplan-skill | 33 | Complex multi-step with checkpoints | ❌ |
| 15 | cablate/Agentic-MCP-Skill | 29 | Progressive MCP client | ❌ |
| 16 | black-forest-labs/skills | 57 | FLUX image generation skills | ❌ |
| 17 | adnw-vinc/hermes-nextcloud | 3 | Nextcloud file/note/calendar | ❌ |
| 18 | DougTrajano/pydantic-ai-skills | 283 | Type-safe agentskills.io for Pydantic AI | ❌ |
| 19 | conorbronsdon/avoid-ai-writing | 1.4K | Remove AI writing patterns | ❌ |
| 20 | esaradev/icarus-plugin | 111 | Self-memory, train your replacement | ❌ |
| 21 | ReinaMacCredy/maestro | 152 | Long-running agents with plan-approve-execute | ❌ |

---

## SECTION 9: CONFIG OPTIMIZATIONS (from OnlyTerp, Official Docs, Community)

### A) Smart Model Routing (NOT enabled — needs OpenRouter key)
```yaml
smart_model_routing:
  enabled: true
  max_simple_chars: 160
  max_simple_words: 28
  cheap_model:
    provider: openrouter
    model: google/gemini-2.5-flash
```

### B) Compression Tuning (have — could be more aggressive)
```yaml
# Current
compression:
  threshold: 0.50  # compress at 50% context
  target_ratio: 0.15
  protect_last_n: 25

# Recommended for aggressive cost savings
compression:
  threshold: 0.30  # compress sooner
  target_ratio: 0.12  # shorter tail
  protect_last_n: 15  # fewer messages protected
```

### C) Provider Routing (needs OpenRouter)
```yaml
provider_routing:
  sort: price              # cheapest first
  data_collection: deny    # privacy
  require_parameters: true # all features required
```

### D) Prompt Caching Config
```yaml
prompt_caching:
  cache_ttl: 5m
  cache_memory_digest: true
  cache_skills: true
  cache_system_prompt: true
  min_cache_tokens: 1024
```

### E) Auxiliary Model Pinning (partially done)
```yaml
auxiliary:
  vision:     { provider: openrouter, model: google/gemini-2.5-flash }    # ✅
  web_extract: { provider: openrouter, model: google/gemini-2.5-flash }   # ✅
  compression: { provider: openrouter, model: google/gemini-2.5-flash }   # ✅
  session_search: { provider: openrouter, model: google/gemini-2.5-flash } # ✅
  skills_hub: { provider: openrouter, model: google/gemini-2.5-flash }    # ✅
  approval: { provider: deepseek, model: deepseek-chat }                   # ✅
  mcp: { provider: deepseek, model: deepseek-chat }                        # ✅
  title_generation: { provider: openrouter, model: google/gemini-2.5-flash } # ✅
  curator: { provider: openrouter, model: google/gemini-2.5-flash }        # ✅
  flush_memories: { provider: deepseek, model: deepseek-chat }             # ✅
```

### F) 4-Tier Model Strategy
| Tier | Cost/M | Models | Tasks | Our Config |
|------|--------|--------|-------|-----------|
| T4 Complex | $15-75 | claude-opus-4 | Interactive chat | Not using — no Anthropic key |
| T3 Coding | $3-15 | claude-sonnet-4 | Cron, delegation, coding | Using deepseek-chat instead |
| T2 Summary | $0.05-0.15 | gemini-2.5-flash | Vision, compression, session search | ✅ Using |
| T1 Trivial | $0.14-0.28 | deepseek-chat | Approval, MCP, simple ops | ✅ Using |

---

## SECTION 10: COMMUNITY ECOSYSTEM STATS (April 2026)

- Total ecosystem stars: 282.7K (+20.2K this week)
- 110+ quality-filtered repos across 12 categories
- 8,700+ contributors to core repo
- 47 built-in tools in Hermes Agent
- 20+ LLM providers
- 16 messaging platforms
- 6 execution backends
- 138.6K★ on core repo
- Growing ~5,000 stars/week ecosystem-wide

### Key Contributors
- @SHL0MS — Top core contributor
- @alt-glitch — Gateway platform work
- @benbarclay — Tool system, batch runner
- @CharlieKerfoot — MCP integration, OAuth
- @WAXLYY — Core contributor
- @0xbyt4 — 40 PRs (MCP client, Home Assistant, security fixes, tests)
- @alireza78a — Atomic writes, fd leak prevention
- @teknium1 — Nous CEO, strategy
- @0xNyk — awesome-hermes-agent (2.6K★)
- @OnlyTerp — Optimization guide (182★)
- @Romanescu11 — skill-factory (246★)
- @nesquena — hermes-webui (6.2K★)

---

## SECTION 11: WHAT WE SHOULD INSTALL (PRIORITY ORDER)

### P0 — Install Now
1. **OnlyTerp's 13 skills** — audit-mcp, rotate-secrets, nightly-backup, cost-report, etc.
2. **Hindsight memory provider** (local_embedded mode, per-client isolation)
3. **Compression tuning** (threshold 0.30, target_ratio 0.12, protect_last_n 15)
4. **Self-Evolution cron** — weekly GEPA evolution pass

### P1 — Install This Week
5. **HMC plugin** — layers on compressor for 6-strategy context optimization
6. **MCP scoped access** — add enabled_for/sampling/trust to existing servers
7. **hermes-workspace** (3.6K★) — full web workspace behind Traefik
8. **SkillClaw** — dedup and evolve our 76 skills

### P2 — Install This Month
9. **hermesd TUI monitor** — live monitoring dashboard
10. **MCP postgres** — read-only access to client databases
11. **tokscale** — per-agent token tracking
12. **hermes-skins** — community CLI themes

### P3 — Evaluate
13. mission-control (large-scale fleet — overkill for us)
14. MCP puppeteer (sandboxed browser — we already have browser tool)
15. drawio-skill (diagrams — useful for docs)
16. MCP notion (client wikis)
17. MCP slack (we have Discord bridge)
18. MCP e2b sandboxes (local terminal already works)
