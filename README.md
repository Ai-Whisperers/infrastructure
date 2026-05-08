# AI Whisperers Infrastructure

Central documentation for the AI Whisperers production infrastructure.

**Last updated:** May 8, 2026  
**Erebus (AI Workforce Lead):** deployed, SOUL.md active  
**Hermes Agent:** v0.13.0 (updated May 8)  
**VPS:** Hostinger (72.61.44.159) — agentzero  
**Disk:** 53% used (was 76%, freed ~85GB via build cache prune)  
**Client sites:** 24 tracked  

---

## Quick Reference

| Item | Value |
|------|-------|
| **SSH** | root@72.61.44.159 |
| **Erebus** | AI Workforce Lead — WhatsApp + Hermes TUI |
| **Hermes** | v0.13.0 — Gateway active |
| **Workspace** | workspace.sunstein.cloud |
| **Web Chat** | hermes-chat.paragu-ai.com (Open WebUI) |
| **Telegram** | @ArchMagusBot |
| **Monitoring** | monitor.paragu-ai.com (Grafana) |
| **Health Monitor** | Cron every 15m → WhatsApp |
| **Main site** | paragu-ai.com |
| **DNS** | Cloudflare |
| **SSL** | Traefik + Let's Encrypt |
| **Domains** | 30+ sites across paragu-ai.com, sunstein.cloud |

---

## Domains

### paragu-ai.com (client sites)

| Site | URL | Status |
|------|-----|--------|
| paragu-ai | paragu-ai.com | OK |
| 30vcs | 30vcs.paragu-ai.com | OK |
| Brahm Raccoon | brahm.paragu-ai.com | OK |
| Dayah Litworks | dayah.paragu-ai.com | OK |
| Depiflash | depiflash.paragu-ai.com | OK |
| Fun4Me | fun4me.paragu-ai.com | OK (restored May 8) |
| Golden Visa | goldenvisa.paragu-ai.com | OK |
| Magnolia Peluqueria | magnolia-peluqueria.paragu-ai.com | OK |
| Maiyu Atelier | maiyu.paragu-ai.com | OK |
| Nico Duarte | nicolas-duarte.paragu-ai.com | OK |
| Nudo | nudo.paragu-ai.com | OK |
| Ozmontania | ozmontania.paragu-ai.com | OK |
| Pitchy/Vitrumpy | pitchy.paragu-ai.com | OK |
| Superspuma | superspuma.paragu-ai.com | OK |
| Villamayor | villamayor.paragu-ai.com | OK |
| El Viajero | el-viajero.paragu-ai.com | DEGRADED (1/2, OOM) |
| 3md | 3md-website.paragu-ai.com | No DNS |
| Anthro Party AR | anthro-party-argentina.paragu-ai.com | No DNS |
| Bichos Gym | bichosgym.paragu-ai.com | No DNS |
| Clinica Duerksen | clinicaduerksen.paragu-ai.com | No DNS |
| Cocodrilo Fitness | cocodrilofitness.paragu-ai.com | No DNS |
| Granja Cabral | granjacabral.paragu-ai.com | No DNS |
| Luis de Leon | luisleon.paragu-ai.com | No DNS |
| Mantra Spa | mantraspa.paragu-ai.com | No DNS |

### sunstein.cloud (infrastructure)

| Service | URL | What | Status |
|---------|-----|------|--------|
| Hermes Workspace | workspace.sunstein.cloud | Web UI + terminal | OK |
| Evolution API | evolution.sunstein.cloud | WhatsApp bridge | OK |
| Space Agent | space.sunstein.cloud | Edge compute | OK |
| Open WebUI | hermes-chat.paragu-ai.com | Chat frontend | OK |

---

## Hermes Agent

| Config | Value |
|--------|-------|
| **SOUL** | Erebus — AI Workforce Lead |
| **Sub-personas** | /erebus dev, ops, research, client |
| **Skills** | 240 active (754 moved to optional) |
| **Active MCPs** | 12 (brave-search, cloudflare, context7, exa, filesystem, github, sequential-thinking, supabase, wikipedia, postgres, puppeteer, memory-server) |
| **Disabled MCPs** | stripe, atlassian, obsidian, arxiv, google-drive, slack |
| **Fallback model** | anthropic/claude-sonnet-4 via OpenRouter |
| **Cron jobs** | 11 active — all deliver to WhatsApp |
| **Plugins** | 10 active |
| **Knowledge graph** | Seeded (12 entities, 12 relations) |

---

## Known Issues

| Issue | Status |
|-------|--------|
| El Viajero OOM on replica 2 | Needs code fix or memory limit increase |
| 8 client sites with no DNS | Old clients, domains not in Cloudflare |
| GITHUB_TOKEN lacks read:packages | Fine-grained PAT needs manual scope grant |
| fun4me root / 404s | Next 16 Turbopack route group bug |
| State DB vacuum | Background process (1.5GB DB) |
