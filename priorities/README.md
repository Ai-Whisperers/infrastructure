# ParaguAI — Operations Base

**Single source of truth.** Repos, clients, sites, infra, cron, contacts, issues.

## Index

| File | What's Inside |
|------|---------------|
| [client-repos.md](client-repos.md) | Every repo: client, framework, last commit, GH link, status, deep details |
| [clients.md](clients.md) | All clients with URLs, contacts, tiers |
| [cron.md](cron.md) | All 22 cron jobs with schedules and status |
| [infrastructure.md](infrastructure.md) | Docker Swarm, Traefik, network map |
| [issues.md](issues.md) | Priority-ordered 🔴🟡🟢 issues |
| [repos.md](repos.md) | Full repo index by category |

## Quick Stats

- **19 live websites** on *.paragu-ai.com + 2 on *.sunstein.cloud
- **22 Docker Swarm services** running on 1 VPS
- **30+ Git repos** (16 client sites, 9 platform, 5 Hermes, rest research/auto)
- **22 cron jobs** — all currently in ERROR state
- **37 GitHub repos** in Ai-Whisperers org (some archived)

## Live Website Map

```
paragu-ai.com          → paragu-ai-builder (3x)
dayah.paragu-ai.com    → Dayah LitWorks
viajero.paragu-ai.com  → El Viajero Comercio
nexa.paragu-ai.com     → Nexa Paraguay
nudo.paragu-ai.com     → Nudo (metal band)
ozmontania.paragu-ai.com → Oz Montania (artist portfolio)
fun4me.paragu-ai.com   → Fun4Me (auth fixed)
superspuma.paragu-ai.com → Superspuma (mattresses)
goldenvisa.paragu-ai.com → Golden Visa Advisory
cabral.paragu-ai.com   → Granja Cabral (egg farm)
duerksen.paragu-ai.com → Clinica Duerksen (dental)
mantra-spa.paragu-ai.com → Mantra Spa
magnolia-peluqueria.paragu-ai.com → Magnolia Peluqueria
maiyu.paragu-ai.com    → Maiyu Atelier
villamayor.paragu-ai.com → Villamayor & Asociados (law)
30vcs.paragu-ai.com    → 30vcs (placeholder)
brahm.paragu-ai.com    → Brahm the Racoon
nicolas-duarte.paragu-ai.com → Nicolas Duarte (portfolio)
space.sunstein.cloud   → Space Agent (AI agent)
gyro.sunstein.cloud    → Gyro (container)
```

## Infrastructure

| Component | Details |
|-----------|---------|
| **Host** | 1 VPS, Ubuntu, Docker Swarm + Compose hybrid |
| **Proxy** | Traefik v3.5.3, Let's Encrypt SSL, Cloudflare DNS |
| **Auth** | Cloudflare DNS (read-only token — user adds A records manually) |
| **Monitoring** | Prometheus + node-exporter + Hermes Incident Commander |
| **DB** | PostgreSQL (shared across apps) |

## Key Contacts

| Person | Role | Contact |
|--------|------|---------|
| Ivan (you) | Founder, ParaguAI / Ai-Whisperers | This chat |
| Leticia Roig | Superspuma Gerente General | Via Sarah |
| Sarah | Leticia's daughter, Superspuma bridge | WA 113090817425545 |
| José Campuzano | Superspuma Director | — |
| Raul Fretes | Golden Visa client | — |
| Bram | Fun4Me partner (concise, strategic) | — |
| Rach | Fun4Me partner | — |

## ⚠️ Known Urgent Issues

1. **All 22 cron jobs erroring** — investigate OpenRouter quotas/model
2. **Superspuma** needs bundle builder (+Gs 1.17M), B2B portal, real product photos
3. **Fun4Me** auth fixed but git push pending
4. **Oz Montania** has zero real images
5. **/tmp/** repos (villamayor-asociados, maiyu-atelier) need permanent homes

## Comms Rules

- **WhatsApp**: max 3 sentences, no markdown, bullet points, zero fluff, 1 actionable per message
- **Telegram**: primary channel
- **Group chats**: English only in Gallinas Oviedo

---

*Generated 2026-05-04. Update when adding new clients or infra changes.*
