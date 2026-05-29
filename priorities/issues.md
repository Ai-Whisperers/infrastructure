# Active Issues & Priorities

## 🚨 Critical — Investigate ASAP

### 1. All 22 cron jobs in ERROR state
- 16 Solstein jobs, 3 IC jobs, 1 lead-scout, sol-planning, sol-metrics
- ALL returning errors. Likely OpenRouter quota/credits or model deprecation issue.
- Check: `~/.hermes/logs/cron/` for error details.

### 2. VPS disk / memory
- Last cleanup 2026-05-04 freed 21G
- Docker build cache still growing
- Need: docker-build-cache-prevention skill

## 🔴 High Priority

### Superspuma Missing Features
- Real product photos (placeholders currently)
- Product finder quiz
- Bundle builder (+Gs 1.17M upsell)
- B2B portal (2300 existing clients)
- Contact: Leticia Roig via Sarah (WA 113090817425545)

### Fun4Me — Push Pending
- Auth fixed 2026-05-04 (custom pg auth API)
- Needs git push to remote

### Golden Visa Advisory
- Active client (Raul Fretes)
- Live, needs ongoing support

## 🟡 Medium Priority

### Oz Montania
- Live but zero real images — content gap
- 7 pages, all placeholder visuals

### Dayah LitWorks
- 7 client books shipped
- 239 unnamed covers — needs naming/tracking system

### Granja Cabral Egg Business
- 8762 hens, 242 eggs/day
- WhatsApp data pipeline: parse chicken feed costs, egg pricing, orders
- Group: 120363408591139576

## 🟢 Low / Maintenance

### Clean up repo clutter
- Multiple duplicate repos (superspuma in /root/ AND /root/sites/)
- /tmp/ contains villamayor-asociados and maiyu-atelier — should be in /root/
- Research docs scattered

### Sites template standardization
- Every site built from same paragu-ai-builder template
- Verify all sites/ clients have matching Docker services

## 📋 Todo Items Collected

- [ ] Fix all 22 cron jobs
- [ ] Push fun4me-store to remote
- [ ] Build superspuma bundle builder
- [ ] Add real product photos to superspuma, ozmontania
- [ ] Create naming system for dayah-litworks covers
- [ ] Move /tmp/ villa mayor and maiyu to permanent location
- [ ] Document build/deploy workflow for new clients
- [ ] Add Grafana back if missing
