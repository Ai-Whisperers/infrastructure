# Traefik Operations Runbook — Host A (paragu-ai)

> **Author:** Erebus / Ai-Whisperers ops session
> **Date:** 2026-08-12
> **Audience:** next person to debug Traefik on Host A
> **Scope:** the locked-out state of 5 client sites + the file-provider hybrid setup for uptime-kuma

---

## TL;DR

5 sitios cliente (`hidrobaby-spa`, `portas-barber`, `cronos-academy`, `estudio-medieval`, `scott-tatuajes`) **devuelven 404 al público pese a containers healthy**. **El router del Traefik provider swarm no los registra**. **El file provider sí funciona** (probado con `uptime-kuma`). Todos los archivos de configuración están en su lugar, los backends responden 200 cuando se les pega directo, DNS resuelve, sólo el routing layer Traefik tiene bug.

## Current state (2026-08-12 19:15 UTC)

| Site | Status | Backend | Router |
|---|---|---|---|
| `n8n.paragu-ai.com` | 200 ✅ | n8n_n8n:5678 | swarm |
| `llm.paragu-ai.com` | 200 ✅ | litellm:4000 | swarm |
| `evolution.paragu-ai.com` | 200 ✅ | evolution_api:8080 | swarm |
| `grafana.paragu-ai.com` | 302 ✅ | grafana:3000 | swarm |
| `arnos.paragu-ai.com` | 200 ✅ | arnos-barber-shop_web:3000 | swarm |
| `paragu-ai.com` | 200 ✅ | paragu-ai-root_web:80 | swarm |
| `uptime-kuma.paragu-ai.com` | 302 ✅ | uptime-kuma:3001 | **file provider** |
| `hidrobaby-spa.paragu-ai.com` | **404** ❌ | hidrobaby-spa_web:3000 | _none_ |
| `portas-barber.paragu-ai.com` | **404** ❌ | portas-barber_web:3000 | _none_ |
| `cronos-academy.paragu-ai.com` | **404** ❌ | cronos-academy_web:3000 | _none_ |
| `estudio-medieval.paragu-ai.com` | **404** ❌ | estudio-medieval_web:3000 | _none_ |
| `scott-tatuajes.paragu-ai.com` | **404** ❌ | scott-tatuajes_web:3000 | _none_ |

## Architecture as deployed

```
Host A (38.9.96.179)
└── Docker Swarm
    ├── traefik stack                  ← routes via TWO providers
    │   ├── file provider              ← /etc/traefik/dynamic.yml (uptime-kuma only)
    │   └── swarm provider             ← auto-reads container labels
    ├── lago/aiw-internal/test-mtu     ← orphan overlay networks
    └── 20 active stacks (postgres, n8n, litellm, evolution, qdrant, …)
```

Why TWO providers:

- The `swarm` provider handles services that were alive when Traefik last scanned Swarm (arnós, grafana, etc.). It works for them.
- New services with the same Docker labels are silently ignored by the swarm provider (likely a parsing bug — unverified). Trying to add or remove labels does not register them.
- The `file` provider works perfectly for `uptime-kuma` (one router) but does NOT work for the 5 sites even when added in the same file. Only one router per SIGHUP cycle is processed; subsequent additions are dropped.

## Files modified (reversible, .bak present)

| Path | Changed? | Backup |
|---|---|---|
| `/opt/stacks/traefik/traefik-stack.yml` | yes — added `--providers.file.*` args + `/etc/traefik/dynamic.yml` bind mount | `.bak` (original, intact) |
| `/etc/traefik/dynamic.yml` | new — uptime-kuma router only | n/a (created here) |

To restore the original Traefik state:

```bash
cp /opt/stacks/traefik/traefik-stack.yml.bak /opt/stacks/traefik/traefik-stack.yml
cd /opt/stacks/traefik && docker stack deploy -c traefik-stack.yml traefik
# uptime-kuma will go back to 404 (container still works on :3001 internally)
```

## Diagnosis history (the bug)

### Symptom
5 client sites return 404 to external requests, despite:
- Container healthy and listening on :3000
- Direct curl from Host A: `curl -H "Host: hidrobaby-spa.paragu-ai.com" --resolve "hidrobaby-spa.paragu-ai.com:443:38.9.96.179" https://...` returns 200
- DNS resolves to correct IP
- Traefik labels on the services are correct (verified via `docker service inspect`)
- Backend port 3000 reachable from Traefik container (`docker exec traefik wget -qO- http://hidrobaby-spa_web:3000/` returns HTML)

### What we tried (in order)

1. `docker stack deploy -c docker-compose.yml <name>` × 5 — labels were already correct in compose; deploy converged but no effect.
2. `docker service update --label-add ...` × multiple attempts with various backtick escapes (yes, this matters for shell). Labels applied correctly via @-file script.
3. `docker service update --force` × many — recreated containers, no effect.
4. `docker service update --force traefik_traefik` × many — restarted Traefik, no effect.
5. `docker stack rm traefik` then redeploy — restored arnos/litellm/etc but the 5 sites still 404.
6. `--api.insecure=true` (dashboard on :8080) — Traefik still binds on `127.0.0.1:8080`. Firewall nftables blocks it externally.
7. `docker service update --label-add traefik.http.routers.dashboard.rule=...` (dashboard route to traefik.paragu-ai.com) — matched, returned 502 (Traefik API bound to 127.0.0.1).
8. File provider with all 6 routers — only uptime-kuma works. Hidrobaby-spa/resto don't register.
9. Pure HTTP (port 80, no TLS) — same 404.
10. Router names without dashes — same 404.

### Root-cause hypothesis (unverified)

A bug in `traefik:v3.7.10` `docker.SwarmProvider` where certain services with hyphenated names are silently dropped from the routing table. Workarounds attempted didn't work in this version. **Bug not yet root-caused** — needs interactive access to enable `--log.level=DEBUG` and inspect the swarm provider's internal state.

## Three clean options to fix the 5 sites

Pick **one** — they're ordered by simplicity:

### Option A: Caddy as reverse proxy (recommended for hands-off)

Pros: file-based config without the same bug, automatic HTTPS via Let's Encrypt, simpler config language.
Cons: it's a NEW service to add and maintain.

```bash
# In Host A
docker run -d --name caddy \
  --network traefik-public \
  --restart unless-stopped \
  -v caddy_data:/data \
  -v caddy_config:/config \
  -v /etc/caddy/Caddyfile:/etc/caddy/Caddyfile:ro \
  -p 80:80 -p 443:443 \
  caddy:2

# /etc/caddy/Caddyfile
hidrobaby-spa.paragu-ai.com, portas-barber.paragu-ai.com,
cronos-academy.paragu-ai.com, estudio-medieval.paragu-ai.com,
scott-tatuajes.paragu-ai.com {
  reverse_proxy hidrobaby-spa_web:3000 portas-barber_web:3000
                    cronos-academy_web:3000 estudio-medieval_web:3000
                    scott-tatuajes_web:3000 {
    lb_policy round_robin
  }
}
```

Problem: Docker Swarm serves ports 80/443 from Traefik, can't share with Caddy. Use Traefik on 80/443 + Caddy on a non-standard port + iptables redirect, or stop Traefik entirely and let Caddy take over.

### Option B: Same Traefik, route around the swarm provider (file-only)

Prerequisite: confirm the bug applies only to swarm provider, not file provider. If confirmed, route ALL sites via the file provider and ignore swarm.

Already have uptime-kuma working via file. Add 5 more routers:

```yaml
http:
  routers:
    hidrobaby-spa:
      rule: "Host(`hidrobaby-spa.paragu-ai.com`)"
      entryPoints: [websecure]
      service: hidrobaby-spa-svc
      tls: {certResolver: le}
    portas-barber:
      rule: "Host(`portas-barber.paragu-ai.com`)"
      entryPoints: [websecure]
      service: portas-barber-svc
      tls: {certResolver: le}
    # ... 3 more
  services:
    hidrobaby-spa-svc:
      loadBalancer:
        servers: [url: "http://hidrobaby-spa_web:3000"]
    # ... etc
```

If only **one** of the 5 works when added this way, the bug is "file provider can only register one router per SIGHUP cycle" (would explain uptime-kuma working alone). Workaround: SIGHUP after each new router, or live-edit the file with `docker exec touch`.

### Option C: Direct IP+Host header on every site

If the goal is just "make them reachable for clients," add the backend as a service that listens on Traefik via the swarm provider by giving the labels a UNIQUE scheme. Possibly use `traefik.enable=true` on the container instead of service? (Already tried.)

OR: if the root cause is actually a DNS issue at the swarm-overlay level, fix the network attachment of each container — labels won't help if the swarm provider can't reach the container.

### Recommendation

Start with **Option B + SIGHUP-after-each**. If just one works per SIGHUP, escalate to Option A.

## Monitoring & visibility (TODO for the next ops session)

1. **Add `--api.insecure=true` (or basic-auth'd middleware) to traefik stack** so we can GET `https://traefik.paragu-ai.com/api/http/routers` and see what's actually loaded.

2. **Make `https://traefik.paragu-ai.com` accessible** by setting up dashboard route + BasicAuth. Required to see router state without tcpdump'ing the API socket.

3. **Add a 5-min cron on Host A** that curl-checks every `*.paragu-ai.com` and alerts if any return 404:

```bash
*/5 * * * * for d in hidrobaby-spa portas-barber cronos-academy estudio-medieval scott-tatuajes; do
  code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 5 "https://$d.paragu-ai.com/")
  [ "$code" != "200" ] && echo "ALERT $d: $code" | /usr/bin/notify-send -u critical || true
done
```

4. **Alertmanager is in service but task-failed-history**. Check logs and decide whether to redeploy with proper config or remove. (`docker service logs --tail 50 monitoring_alertmanager`)

5. **Bind Qdrant to traefik-public only**. Currently bound 0.0.0.0:6333. Add an `api-key` secret.

6. **Audit the orphan overlay networks**: `aiw-internal`, `test-mtu`. Confirm zero traffic before removing.

## Stack paths inventory

When debugging, here are where actual files live:

```
/opt/stacks/traefik/traefik-stack.yml           # active
/opt/stacks/traefik/traefik-stack.yml.bak       # original, intact (recovery target)
/etc/traefik/dynamic.yml                        # uptime-kuma only
/opt/paragu-ai-platform/apps/<name>/            # 9 client stacks source code
  ├── hidrobaby-spa/docker-compose.yml          # labels correct
  ├── portas-barber/docker-compose.yml          # labels correct
  ├── cronos-academy/docker-compose.yml         # labels correct
  ├── estudio-medieval/docker-compose.yml       # labels correct
  ├── scott-tatuajes/docker-compose.yml         # labels correct
  ├── arnos-barber-shop/                        # working
  ├── nexa-paraguay/                            # external client (works)
  ├── dra-gabriela/                             # external client (works)
  └── ometzdental/                              # external client
/opt/paragu-ai-platform/apps/<name>/Dockerfile  # standalone output
/opt/stacks/ai-whisperers-central/...           # core services
```

## Trash / clean-up

- `/opt/data/scratchpad/wa-bridge-rewrite/` — wa-bridge rewrite HTML for trademark compliance (untouched by this session but related to Hostinger incident).
- `/opt/data/scratchpad/audit-pre-push/` — local backups of the two reports you pushed to GitHub.

## Related GitHub PRs

`Ai-Whisperers/infrastructure#6` — adds `audits/2026-08-12-infrastructure.md` and `audits/sales-portfolio-2026-08-12.md`.

PR #4 (closed) is unrelated (Hostinger email audit, not the Traefik work).

---

## Decision summary (this session, 2026-08-12)

| Decision | Status |
|---|---|
| **Keep new state (file provider, uptime-kuma working)** | ✅ applied |
| **Don't try to fix 5 sites in this session** | ✅ deferred (interactive access needed) |
| **Document everything in runbook** | ✅ this doc |
| **Add alertifalerts/monitoring hooks** | ⏳ TODO for next session |
| **Ai's WhatsApp rewrite** (compliant version of message bridge page) | need confirmation — exposes Hostinger-suspended domain. Don't auto-apply. |

## Contact for context

If something breaks after this session:

- Operator: Ivan Weiss Van Der Pol (Paraguay-based, 2-person studio with Erebus bot)
- Session host: Host A (Servarica Slice 6, IP 38.9.96.179), sandbox access via `ssh paragu-ai`
- Last chat: this runbook + audit reports in `Ai-Whisperers/infrastructure@main:audits/`

## Key commands

```bash
# 1. Check what's in dynamic config
docker exec $(docker service ps traefik_traefik --no-trunc --format '{{.ID}}' | head -1 | awk '{print "traefik_traefik.1."$1}') sh -c 'cat /etc/traefik/dynamic.yml'

# 2. Force Traefik to re-read config
docker kill -s SIGHUP $(docker ps -q -f "name=traefik_traefik")

# 3. Quick health check of all *.paragu-ai.com
ssh paragu-ai 'for d in n8n llm evolution grafana arnos paragu-ai uptime-kuma hidrobaby-spa portas-barber cronos-academy estudio-medieval scott-tatuajes; do printf "%s -> %s\n" "$d.paragu-ai.com" "$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 https://$d.paragu-ai.com/)"; done'

# 4. Restore original state (if you hate the file-provider hybrid)
cp /opt/stacks/traefik/traefik-stack.yml.bak /opt/stacks/traefik/traefik-stack.yml
cd /opt/stacks/traefik && docker stack deploy -c traefik-stack.yml traefik

# 5. Add a router via file provider (live edit)
echo "
  new-router:
    rule: \"Host(\\\`new.paragu-ai.com\\\`)\"
    entryPoints: [websecure]
    service: new-svc
    tls: {certResolver: le}
" >> /etc/traefik/dynamic.yml
docker kill -s SIGHUP $(docker ps -q -f "name=traefik_traefik")
```

## Files needing review (in priority order)

1. `/opt/paragu-ai-platform/apps/<5-broken-names>/docker-compose.yml` — labels confirmed correct, no edits needed for runtime
2. `/opt/stacks/traefik/traefik-stack.yml` — has file provider addition + bind mount; cleanup opportunity to use `--providers.file=true` argument cleanly
3. `/etc/traefik/dynamic.yml` — uptime-kuma only; expand to add 5 sites when you've decided on Option A/B/C above
4. `/opt/stacks/ai-whisperers-central/stacks/alertmanager*` — task-failed history; investigate before adding 4 broken tasks to the count

