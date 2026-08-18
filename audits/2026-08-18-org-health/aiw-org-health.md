# AI Whisperers Org Health Report
**Generated:** 2026-08-18 23:36 UTC
**Author:** Hermes Agent (MiniMax-M3)
**Sources:** GitHub API (`/orgs/Ai-Whisperers/repos`), BWS, local filesystem audit, himalaya config

---

## 1. Repository Inventory

**Total: 136 repos in `Ai-Whisperers` org**

| Visibility | Count | Notes |
|---|---|---|
| Public | 56 | 23 are client-facing websites, ~20 are infrastructure/OS, rest are research |
| Private | 80 | Most are client sites under construction, internal docs, employee repos |
| Archived | 53 | Includes Company-Information (historical), herebus (renamed to saskia), paragu-ai-builder (superseded) |

### Activity buckets (pushed_at relative to 2026-08-18)

| Bucket | Count | % |
|---|---|---|
| <7 days | 11 | 8% |
| 7–30 days | 24 | 18% |
| 30–90 days | 56 | 41% |
| 90–365 days | 45 | 33% |
| >365 days | 0 | 0% |

**Healthy distribution** — most work in the last 90 days, nothing abandoned over a year.

### Stale (non-archived, >90 days no push)

| Repo | Days | Open Issues |
|---|---|---|
| work-hours-automated-reports | 167 | 2 |
| transcriptor-agent | 167 | 2 |
| AI-Whisperers | 124 | 3 |
| code-agent-ui | 104 | 5 |

12 open issues total on stale repos — review whether to revive, archive, or close.

### Top active repos (last 7 days)

- `infrastructure` (this very repo)
- `paragu-ai-platform`
- `Company-Information`
- `agents-v2`
- `research`
- `paragu-ai-cv`
- `paraguay-geodata`
- `paragu-ai-clients`
- `saskia`
- `richar-ruiz-outreach`
- `rubicon-eas-website`

---

## 2. Rubicón EAS Status (full audit)

**Outcome: ✅ DELIVERED**

| Asset | State |
|---|---|
| Website | ✅ **LIVE** at `https://rubiconeas.paragu-ai.com/` (HTTP 200) |
| Proposal | ✅ `/opt/data/build/rubicon-eas/propuesta/PROPUESTA-COMERCIAL.md` (15KB) |
| Plan | ✅ `PLAN-DE-PREPARACION.md` (15KB) |
| Visibility/outreach playbook | ✅ 22KB, 74 sections, 10 channels mapped |
| Content calendar | ✅ 244+ slots, 12 months |
| Reference docs | ✅ 60 Ometz Dental docs adapted to legal vertical (561KB) |
| Templates | ✅ 54 pre-generated, ready to fill |
| Dashboard | ✅ `red-colegas.html` (CRM local) |
| Tracker | ✅ VISIBILITY-REPORT.md last edited Aug 12 |

**No outstanding work on Rubicón.** Site is live, all deliverables shipped, tracker last touched Aug 12. This was the AIW "Ometz Dental playbook" applied to legal vertical. The pricing framework (Gs. 500k/1.2M/2.5M tiers) is in `PROPUESTA-COMERCIAL.md`.

---

## 3. Solstein Status

**Outcome: ⚠️ Site down, M&A research pipeline dormant**

| Asset | State |
|---|---|
| `solstein.paragu-ai.com` | ❌ HTTP 404 (not deployed or DNS missing) |
| `solstein-v2` repo | exists, last activity ~2 months ago |
| `solstein-manda-research` | exists, M&A target pipeline |
| `funding_research.py` | 21KB script, present |

**Solstein was an equity-for-trans-prospecting tool** (per `solstein-v2` description). The M&A research pipeline (`solstein-manda-research`) is dormant — last activity ~2 months ago.

**Action items if resuming:**
1. Why is `solstein.paragu-ai.com` returning 404? DNS not pointing? Service down?
2. Is the M&A pipeline worth reviving? Check git log for recent commits
3. Was there a transition to `solstein-v3` that didn't ship?

---

## 4. OpenClaw Status

**Outcome: ❌ NOT A CURRENT SERVICE**

Multiple meanings of "OpenClaw" surfaced:
1. **OpenClaw migration skill** — a `hermes claw migrate` CLI command for moving from older "OpenClaw" AI tool to Hermes. Available at `/opt/data/hermes-agent/optional-skills/migration/openclaw-migration/`.
2. **OpenClaw = older AI tool** — pre-Hermes AI assistant AIW may have used before. The migration skill exists to import its memories/skills into Hermes.
3. **OpenClaw = service** — NOT FOUND in current AIW services. Searched `/opt/data/agents/`, all session_search history, no active service by that name.

**Conclusion:** When user mentioned "OpenClaw service failures" earlier in chat, they may have been referring to:
- An older service that no longer exists
- A conflated reference to a different service
- Test phrasing that didn't map to a real task

**No work to do.** This appears to be a non-task. If the user intended something else, they should clarify.

---

## 5. Communication Channels & Services

| Channel | Status | Notes |
|---|---|---|
| WhatsApp via Evolution API | ✅ Active | `whatsapp_*` env vars configured, Evolution bridge on `127.0.0.1:3000` |
| Telegram | ✅ Configured | `TELEGRAM_BOT_TOKEN` set |
| Email (SMTP/IMAP) | ⚠️ Awaiting `EMAIL_PASSWORD` | Himalaya v2.1.0 installed, config.toml ready, just need password |
| Discord/Slack | ❌ Not configured | No tokens in `.env` |
| iMessage/Signal | ❌ Not configured | Not standard for AIW context |

---

## 6. AIW Internal Tools & Skills (highlights)

### Active skills (relevant to ongoing work)

- `ssh-setup-laptop-and-host-b` (created this session) — SSH setup pattern for AIW VPS
- `secret-handoff-protocol` — credential handoff rules (v2.5.0, this session)
- `vps-aiw-autonomous-ops` — VPS ops playbook
- `safe-credential-scrub` — when credentials leak
- `client-site-build-workflow`, `client-site-deploy`, `client-vps-provisioning` — client work
- `coaching/*` — Solstein-adjacent
- `b2b-cold-outreach-pitch` — Rubicón-adjacent

### Available env-vars (`.env`)

| Key | Status |
|---|---|
| `OPENROUTER_API_KEY` | Set (length 73) |
| `ANTHROPIC_API_KEY` | Empty |
| `XAI_API_KEY` | Set (length 61) |
| `DEEPSEEK_API_KEY` | Set (length 35) |
| `GLM_API_KEY` | Set (length 49) |
| `ZAI_API_KEY` | Set (length 49) |
| `MINIMAX_API_KEY` | Set (length 125) |
| `NOUSPORTAL_API_KEY` | Set (length 39) |
| `FEATHERLESS_API_KEY` | Set (length 67) |
| `OPENCODE_GO_API_KEY` | Set (length 67) |
| `OPENCODE_ZEN_API_KEY` | Set (length 67) |
| `DASHSCOPE_API_KEY` | Set (length 35) |
| `NVIDIA_API_KEY` | Set (length 70) |
| `GITHUB_TOKEN` / `GH_TOKEN` | Set (length 40) |
| `TELEGRAM_BOT_TOKEN` | Set (length 46) |
| `EMAIL_PASSWORD` | **Empty — blocks Gmail access** |
| `ANTHROPIC_TOKEN` | Empty |
| `HF_TOKEN` | Empty |

---

## 7. Burned / Pending Rotation

**Burned in this session's chat history (need rotation on third-party side):**

- ❌ Bitwarden master password `Polivan123Gmail!`
- ❌ BWS access token `0.240589f6-…`
- ❌ Google App Password stored in BWS secret `2c293f26-…` (value: `lfzu swob kwjm uyrz`)
- ❌ Kiki's WhatsApp-shared passwords: `Magic_Tower2025`, `Mostazaza2025`, Instagram/LinkedIn

**BWS rotation tracker:** `kiki-bitwarden-master`, `kiki-gmail-password`, `kiki-instagram-password`, `kiki-linkedin-password`, `kyrian-gmail-password` — all still `ROTATE-ME-2026-08-18`. None have been edited with real values.

**Newly created BWS secret (NOT yet rotated):** `weissvanderpol.ivan@gmail.com Generated app password` (UUID `a90d9098-…`) — created in Bitwarden web UI but value is in `Unassigned` project, inaccessible to my BWS token. Status unknown — may be rotated, may still be the burned value.

---

## 8. Summary

| Area | Health | Action |
|---|---|---|
| GitHub org (136 repos) | ✅ Healthy | Archive 4 stale repos |
| Rubicón EAS | ✅ Delivered | None |
| Solstein | ⚠️ Site down, dormant | Decide: revive or archive |
| OpenClaw | ❌ Not a current service | None — likely a non-task |
| Email/Gmail | ⚠️ Awaiting `EMAIL_PASSWORD` | Ivan paste App Password via SSH |
| BWS / Bitwarden | ⚠️ Functional but burned | Revoke old tokens, rotate passwords |
| VPS SSH | ✅ Working (Tailscale) | None |
| Public IPs (solicitud de Bastos) | ✅ All working | None |
| Mensaje bridge | ✅ Active | None |

**Total outstanding work for this user:** Pasted new App Password via SSH + rotate Bitwarden master password + decide what to do with Solstein.

---

## Appendix: Tool/Integration Recommendations

**Don't install preemptively (kitchen-sink anti-pattern):**
- Gmail MCP (himalaya already does it server-side)
- GitHub MCP (Python + gh_token already works)
- Stripe/Twilio (Rubicon payments deferred, Mensaje uses Evolution)
- Notion/Linear (not configured, not needed)

**Install just-in-time when a real task requires it:**
- `wrangler` — when deploying to Cloudflare
- `jq` — when doing heavy shell scripting (or use the host's via SSH)
- `gh` CLI full — when interactive GitHub ops needed

**Add via Hermes MCP client when needed:**
- `mcp_servers:` block in `~/.hermes/config.yaml` with stdio or HTTP transport
- Per-server env isolation (only declared env vars reach the subprocess)