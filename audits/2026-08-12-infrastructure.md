# Infrastructure Audit — ParaguAI / Ai-Whisperers

**Date:** 2026-08-12 (Wednesday)
**Auditor:** internal ops review session
**Method:** operator-supplied brief + live verification (public curl + SSH batchmode + `docker [stack|service|ps] ls` from Host A)
**Scope:** three hosting environments + adjacent services. **Sandbox limitation:** no SSH credentials for Host B or Host Z; verification on those derives from SSH banner + public DNS + external curl.

---

## 1. Host inventory

### 1.1 Host A — paragu-ai (Servarica Slice 6)
- **IP:** 38.9.96.179
- **Hostname:** paragu-ai.com — DNS un-proxied (A record via Cloudflare)
- **OS / kernel:** Linux, uptime 5 d 05 h
- **Resources:** 24 GB RAM (7 GB in use) · disk 727 GB total (29 GB used, 698 GB free, 4%)
- **Container runtime:** Docker Swarm 29.7.2, single-node leader (`*` = manager), node id `iy2xetmpvcv11q8sie3007pgc`
- **Active overlay network:** `traefik-public` (where all sites and services with Traefik labels hang)
- **Edge proxy:** Traefik v3.7 (`traefik:v3.7@sha256:9c3b91d5…dcb2ac`) on ports 80/443, Let's Encrypt `le.acme` valid (account email `weissvanderpol.ivan@gmail.com`), provider `providers.swarm=true`, `network=traefik-public`, `exposedByDefault=false` (services must explicitly declare `traefik.enable=true`)
- **Active Swarm stacks:** 20 (alertbridge, arnos-barber-shop, cronos-academy, dra-gabriela, estudio-medieval, evolution, hidrobaby-spa, langfuse, litellm, monitoring, n8n, nexa-paraguay, paragu-ai-root, portas-barber, postgres, qdrant, redirects, scott-tatuajes, traefik, uptime-kuma)
- **Total Swarm services:** 35+ replicated tasks (plus 3 `global` for cadvisor/node-exporter), all `Up`

#### Core stack (ai-whisperers-central)

Eight core dependencies on `traefik-public`:

| Service | Stack | Internal port | Public endpoint | Verified state | Notes |
|---|---|---|---|---|---|
| **Traefik 3.7** | traefik | :80, :443 | all `*.paragu-ai.com` | ✅ up 3d | dashboard API enabled |
| **Postgres 14** | postgres | :5432 | `pg_isready → accepting connections` | ✅ up 3d | shared by n8n, evolution, langfuse, qdrant |
| **n8n (latest)** | n8n | :5678 | `n8n.paragu-ai.com` | ✅ `200 /healthz → {"status":"ok"}` | primary automation layer |
| **LiteLLM `berriai/litellm:main-v1.81.14-stable`** | litellm | :4000 | `llm.paragu-ai.com/v1/chat/completions` | ✅ `/v1/models → 200`, `/v1/chat/completions → 200` with virtual key, root `/health → 401` (expected, master key required) | Router names referenced in brief: `primary`, `fast`, `reasoning`, `vision` |
| **LiteLLM Redis 7-alpine** | litellm | :6379 | (internal) | ✅ `PONG` | |
| **Evolution API v2.3.7** | evolution | :8080 | `evolution.paragu-ai.com` | ✅ `200 / → {status:200, message:"Welcome to Evolution API", version:"2.3.7", manager:"http://localhost:8080/manager", clientName:"evolution_exchange"}` | OSS bridge service (Evolution API). Carve-out: explicit upstream name preserved. |
| **Evolution Redis (latest)** | evolution | :6379 | (internal) | ✅ `PONG` | |
| **Qdrant (latest)** | qdrant | :6333, :6334 | bound public 6333 | ✅ up 3d | vector store, public bind ⚠️ see §3 |
| **Langfuse 3** | langfuse | 6 services: web, worker, clickhouse 24, minio, redis 7, minio-init oneshot | langfuse.<public-domain> | ✅ web/worker up 3d, redis/clickhouse/minio up 3d, `minio-init 0/1` (oneshot completed) | LLM observability |
| **ParaguAI root** | paragu-ai-root | nginx:alpine · :80 | `paragu-ai.com` | ✅ `200 → 1380 B` (static page) | corporate landing |
| **Redirects** | redirects | nginx:alpine · :9999 (host) | (popup links on :9999) | ✅ up 2d | helper |

#### Monitoring stack

| Service | Image | Port | State | Notes |
|---|---|---|---|---|
| Prometheus | `prom/prometheus:v3.1.0` | :9090 | ✅ "Prometheus Server is Healthy" | active |
| Grafana | `grafana/grafana:11.5.0` | :3000 | ✅ `/api/health → db ok, version 11.5.0` | exposed on `grafana.paragu-ai.com` |
| Alertmanager | `prom/alertmanager:latest` | :9093 | ⚠️ 1 running 3d, **4 task failed/exit history** | needs log review (churn visible) |
| cAdvisor (global) | `gcr.io/cadvisor/cadvisor:v0.49.1` | :8080 | ✅ healthy | 1/1 |
| node-exporter (global) | `prom/node-exporter:v1.8.2` | :9100 | ✅ up | 1/1 |
| Uptime-Kuma | uptime-kuma/uptime-kuma 1/1 (healthy) | :3001 | ⚠️ container up, `uptime-kuma.paragu-ai.com → 404` | missing DNS entry or Traefik rule |
| alert-bridge (Python 3.12) | python:3.12-alpine | — | ✅ up 3d | internal bridge |
| alertbridge bridge | python:3.12-alpine | :9099 | ✅ up 3d | exposes :9099 to host |

### 1.2 Host B — hermes (Servarica Slice 2)
- **IP:** 38.9.96.180
- **Hostname:** hermes.paragu-ai.com
- **SSH:** port 22 open, banner ED25519, authentication `Permission denied (publickey,password,keyboard-interactive)` from sandbox
- **DNS:** from sandbox `getent ahostsv4 hermes.paragu-ai.com → 127.0.1.1` (does not resolve to public IP; only accessible for those already running the SSH tunnel)
- **What the brief covers:**
  - Compose at `/root/.hermes/hermes-agent/docker-compose.yml`
  - Gateway with `network_mode: host`, s6-supervised, shares PID with dashboard `pid: service:gateway`
  - Dashboard bound `127.0.0.1:9119`
  - `~/.hermes` bind-mounted to `/opt/data`, ownership `10000:10000` (caveat: root `docker exec` will re-chown to `0:0` and break the dashboard; always `-u hermes`)
  - Dashboard session token pinned in compose (`HERMES_DASHBOARD_SESSION_TOKEN`), must match `~/.hermes/desktop.json` on laptop or every API call returns 401
  - Remote-messaging gateway live via `@ArchMagusBot`, token in `/root/.hermes/.env`, allowed users via pairing
  - SSH tunnel from laptop: systemd user unit `hermes-dashboard-tunnel.service` forwards `127.0.0.1:9119 → hermes:9119`, `loginctl enable-linger` to survive logout/reboot
- **Could not audit services from here** (sandbox lacks SSH key)

### 1.3 Host Z — agentzero (Hostinger VPS)
- **IP:** 72.61.44.159
- **State:** `ssh: connect to host 72.61.44.159 port 22: Connection timed out` — **down or blocked**
- **What the brief covers:** big fleet (30+ containers: searxng, crawl4ai, qdrant, LiteLLM, monitoring, older Hermes) per `agentzero-services` skill
- **History:** suspended by Hostinger in 2026-Q1 — reason for the migration to Host B
- **Action:** confirm from laptop with `ssh agentzero uptime` (also blocked from sandbox) before declaring decisive. **No real traffic to this VPS for months per corpus.**

### 1.4 Laptop local (this sandbox)
- **OS:** Linux 7.0.0-29-generic, xfce4 + x11vnc :5900, multi-monitor Xinerama
- **Home:** `/opt/data` = bind-mount of `~/.hermes` from Host B (via tunnel — sectioned)
- **Python:** 3.13.5, `pip` absent, uv installed, PEP 668 (use venv or uv)
- **Hermes profile:** `default` active
- **Projects:** Blender + house-field project, `paragu-ai-platform` monorepo (not on Host A, only per-app build artifacts rsync'd)

---

## 2. Services by subdomain

Live verification result (external curl, no tunnel), date 2026-08-12 ~17:00 UTC.

| Subdomain | HTTP | Traefik Host rule | Container | Observation |
|---|---|---|---|---|
| `paragu-ai.com` | **200** ✅ | ✅ `Host: paragu-ai.com` (apex → paragu-ai-root) | nginx:alpine · 80 | corporate landing |
| `n8n.paragu-ai.com` | **200** ✅ | ✅ | n8n 1.0 · 5678 | healthz OK |
| `llm.paragu-ai.com` | **401** ✅ | ✅ | LiteLLM 1.81.14 · 4000 | expected without master key; `/v1/models` internal returns 200 with key |
| `evolution.paragu-ai.com` | **200** ✅ | ✅ | Evolution API · 8080 | manager path `/manager/get-instances` returns React HTML wrapper |
| `grafana.paragu-ai.com` | **200** ✅ | ✅ | grafana 11.5 · 3000 | /api/health OK |
| **uptime-kuma.paragu-ai.com** | **404** ⚠️ | ❌ (container up, no rule) | uptime-kuma · 3001 | healthy container, route missing |
| `arnos.paragu-ai.com` | **200** ✅ | ✅ | arnos-barber-shop:prod · 3000 | Next.js, schema.org/BarberShop, JSON-LD with complete wa.me `ReserveAction` |
| **hidrobaby-spa.paragu-ai.com** | **404** ❌ | ❌ | hidrobaby-spa:prod · 3000 (up) | container serves 200 when targeted directly to IP, Traefik rule missing |
| **portas-barber.paragu-ai.com** | **404** ❌ | ❌ | portas-barber:prod · 3000 (up) | idem |
| **cronos-academy.paragu-ai.com** | **404** ❌ | ❌ | cronos-academy:prod · 3000 (up) | idem |
| **estudio-medieval.paragu-ai.com** | **404** ❌ | ❌ | estudio-medieval:prod · 3000 (up) | idem |
| **scott-tatuajes.paragu-ai.com** | **404** ❌ | ❌ | scott-tatuajes:prod · 3000 (up) | idem |
| `nexa-paraguay.paragu-ai.com` | **404** (route hostname without entry) | — | nexa-paraguay:prod · running 45h with 1 shutdown + 1 shutdown 2d | **Container is backend for public site `nexaparaguay.com.py`** (Hostinger). `/api/health` confirms `service:"nexa-paraguay"`. |
| `dra-gabriela.paragu-ai.com` | **404** | — | dra-gabriela:prod · running 2d with 2 failed | **Container is backend for `ometzdental.com`** (Cloudflare-fronted). `/api/health` confirms `service:"dra-gabriela", uptime:174963`. |

### Routing conclusion

Three clear categories:
1. **End-to-end works** (Traefik + DNS + cert + response): `paragu-ai.com`, `n8n`, `llm`, `evolution`, `grafana`, `arnos`
2. **Traefik label missing on stack** (container healthy, direct IP returns 200): `hidrobaby-spa`, `portas-barber`, `cronos-academy`, `estudio-medieval`, `scott-tatuajes` — minimum fix = add 4 labels per stack
3. **Public endpoint is not *.paragu-ai.com but the client's own domain**: `nexaparaguay.com.py`, `ometzdental.com` — Host A Swarm exposes backend at `/api/*` with proxy in Hostinger or CF for the client; `*.paragu-ai.com` remains as historical subdomain, non-functional

---

## 3. Findings (priority ordered)

### 🔴 P0 — Client sites broken publicly

**5 of 8 client-delivered sites return 404** even though container is alive, app listening on :3000, IP-direct serves 200. This is the largest public-internal dissonance. The stacks `arnos-barber-shop`, `hidrobaby-spa`, `portas-barber`, `cronos-academy`, `estudio-medieval`, `scott-tatuajes` deployed with inconsistent Traefik label coverage. Only `arnos` is complete.

Cause: deployment set the `com.docker.stack.namespace` but the Traefik labels (`traefik.enable=true`, `traefik.http.routers.X.rule=Host(\`sub.paragu-ai.com\`)`, `traefik.http.services.X.loadbalancer.server.port=3000`, `traefik.http.routers.X.tls=true`, `traefik.http.routers.X.tls.certresolver=le`) are missing in 5 of 6.

Fix without touching images: `docker service update --label-add …` on each (no rebuild required). Runtime secrets/variables per stack (e.g. Next.js `NEXT_PUBLIC_SITE_URL`) probably also missing.

### ⚠️ P1 — Alertmanager with churn

`docker service ps monitoring_alertmanager` shows 4 restart/fail in history. Container `Running 3 days ago` is alive, but something is restarting it. Review: `docker service logs --tail 200 monitoring_alertmanager` (logs not downloaded in this audit).

### ⚠️ P1 — Subdomains poorly hosted

- `uptime-kuma.paragu-ai.com`: container up with healthcheck, but no Traefik rule (same bug as client sites). If central monitor dashboard is wanted at this URL, this should be fixed.
- `litellm.paragu-ai.com` / `n8n.paragu-ai.com` (if `api` is separated): no verifiable public entry — only canonical names `llm`/`n8n`.

### 🟡 P2 — Stack with supervisor instead of docker-compose

Evolution API v2.3.7 is running as a Swarm service, not standalone. This is good (auto-restart, rolling update via swarm), but the pairing flows (which the brief identified at `/opt/stacks/ai-whisperers-central/stacks/evolution/`) now live inside the `evolution` Swarm stack. **Directory `/opt/stacks/ai-whisperers-central/` does NOT exist** on Host A (path in brief doesn't match). Likely: the stack was rebuilt natively with `docker stack deploy` from a `docker-compose.yml` renamed to `docker-stack.yml`; the legacy repo lives only in `/opt/data/scratchpad/aiw-central/` and `round2/round3-backup/`.

### 🟡 P2 — Orphan overlays `docker_gwbridge` and `test-mtu`

In `docker network ls`:
- `aiw-internal` overlay — no stacks actively using it (ex-aiw-central)
- `test-mtu` overlay — orphan, dry-run
- `langfuse_langfuse` overlay — used only by langfuse stack, properly encapsulated
- `docker_gwbridge` — default bridge

Unused overlay networks waste IPs from the Swarm pool (10.0.0.0/8 default); while `/8` is ample, inventory noise. Safe cleanup = first audit with `docker network inspect` to verify active containers before `docker network rm`.

### 🟡 P2 — Qdrant listening on public bind

`*:6333->6333/tcp` — Qdrant bound to `0.0.0.0`. Health-critical because it's a vector store: **should be limited to `127.0.0.1` or to the `traefik-public` overlay** per the pattern of others. Did not verify whether Qdrant authentication is active.

### 🟢 P3 — Health checks
- Prometheus + Grafana + Alertmanager: healthy
- Postgres + 2x Redis: `PONG`/`accepting connections`
- Evolution + n8n + LiteLLM: `/health` (or variants) endpoints respond OK
- Client Next.js containers: 200 direct to IP, but 404 publicly due to missing rule

### 🟢 P3 — DNS / un-proxied CDN records
- `*.paragu-ai.com` resolves via CF un-proxied → 38.9.96.179 (apex and subdomains). Correct for Traefik LE passthrough.
- `hermes.paragu-ai.com` from sandbox → 127.0.1.1 (sandbox local does not resolve; only laptop with tunnel reaches)

---

## 4. Adjacent services

### 4.1 Other providers / accounts
- **Supabase MCP**: per brief, wired for managed Postgres / edge fun (same-tier access). Not audited this pass.
- **LLM providers** (profile MiniMax-M3 via minimax-oauth with fallback chain): openrouter/free → alibaba qwen-turbo → nvidia llama-3.1-8b → zai glm-4.6. Backup config at `/opt/data/backups/config.yaml.20260809-190136`.

### 4.2 Brand-safety note

The operator maintains a mechanical trademark banlist with carve-outs for functional terms and OSS upstream names (Evolution API explicit). This audit report has been scrubbed: branded strings have been generalized where they would trip the banlist, while preserving technical accuracy (IPs, ports, endpoints, paths, commands).

### 4.3 Runtime metadata
- Conversation initiated 2026-08-12 (Wednesday)
- Runtime model: MiniMax-M3 via minimax-oauth

---

## 5. Open questions and recommended actions

### Confirm with the operator
1. **Are the 5 client sites with 404 (hidrobaby-spa, portas-barber, cronos-academy, estudio-medieval, scott-tatuajes) local sites delivered to final clients that should be reachable?** If yes, under what public domain? If supposed to be `*.paragu-ai.com` and not responding, Traefik rules need to be added.
2. **Add Traefik labels to the 5 stacks?** Pure fix: 4 labels per stack + redeploy service. Doesn't touch images. Estimated time < 10 min.
3. **What to do with `nexa-paraguay` and `dra-gabriela`?** Keep Swarm as external production backend, or shut down and rely only on Hostinger.
4. **Real status of Host Z (agentzero)** — need SSH opened from laptop to confirm down state.
5. **Clean `aiw-internal` and `test-mtu` overlays?** Only if nothing in production depends on them.

### Suggested fix priority
- Today: 5 stacks Traefik → 200 on `*.paragu-ai.com`
- Today: relaunch `monitoring_alertmanager` and read fail logs
- Tomorrow: confirm fall of Host Z from laptop
- This week: bind Qdrant to traefik-public + secret `QDRANT_API_KEY`
- This week: add `uptime-kuma.paragu-ai.com` rule
- Pending: bind credentials for Host B for direct audit

---

## 6. Sources / methods

- Operator-supplied brief (initial prompt)
- Live verification via terminal with sandbox (Host A via `paragu-ai` alias resolving to 38.9.96.179)
- Key commands executed (summary):
  - `ssh -o BatchMode=yes paragu-ai 'docker ps'`
  - `ssh -o BatchMode=yes paragu-ai 'docker service ls'`
  - `ssh -o BatchMode=yes paragu-ai 'docker stack ls'`
  - `curl -sk https://<sub>.paragu-ai.com/...`
  - `docker exec <container> redis-cli ping / pg_isready / wget -qO- …`
  - `docker exec monitoring_prometheus … wget -qO- http://localhost:9090/-/healthy`
  - `dig`/`host`/`nslookup`: not available in sandbox; used `getent ahostsv4` and public DNS via `ssh paragu-ai` instead
- Notable truncated outputs:
  - `/opt/data/scratchpad/host-a-deploy-bundle/` and `.tar.gz` — historical backup 2026-08-10 07:12
  - `/opt/data/scratchpad/round3-backup/` (20 KB) — last snapshot
  - `/opt/data/scratchpad/hostinger-trapped-assets.md` — Hostinger incident note

---

**Next step if asked to "do all":** patch the 5 broken Traefik stacks + relaunch Alertmanager + add `uptime-kuma` rule + reconfirm Qdrant bind. Total < 30 min and 0 irreversible changes.
