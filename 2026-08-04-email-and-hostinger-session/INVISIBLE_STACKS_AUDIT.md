# Invisible Stacks Audit — 2026-08-04

Stacks running on VPS but no public DNS resolves to them on the *.paragu-ai.com wildcard. 
These were 404 in the broad scan. Each gets its purpose, routing, image age, and recommendation.

---

## 3md-website

**Service state:**
- 3md-website_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/3md-website:2c36ee68cdc67b5a8775a13bd0126b5fceeb43c1)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.3md-website.rule=Host(`3mind.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Per stack name, likely the Ometz/Villa del Mar '3md' website. Probably has its own custom domain (ometzdental.com). **Verify in hPanel DNS zone.**

---

## ai-whisperers-site

**Service state:**
- ai-whisperers-site_web: 1/1 (image: ai-whisperers-site:prod-cd1d5fac-20260728-1745)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.ai-whisperers-mirror.rule=Host(`ai-whisperers.paragu-ai.com`) || Host(`www.ai-whisperers.paragu-ai.com`)
  traefik.http.routers.ai-whisperers-www.rule=Host(`www.ai-whisperers.org`)
  traefik.http.routers.ai-whisperers.rule=Host(`ai-whisperers.org`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Routed to **ai-whisperers.org** (not .com). If .org is yours and intentional, this is fine — but the fleet uses .com. Confirm: does the client know they're at .org?

---

## dra-gabriela

**Service state:**
- dra-gabriela_web: 1/1 (image: dra-gabriela:prod-d393c67e-20260728-1627)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.dra-gabriela-pa.rule=Host(`dragabriela.paragu-ai.com`)
  traefik.http.routers.dra-gabriela-www.rule=Host(`www.ometzdental.com`)
  traefik.http.routers.dra-gabriela.rule=Host(`ometzdental.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Spanish-language site. Likely has a custom domain. **Verify DNS or migrate to .com wildcard.**

---

## golden-visa-advisory

**Service state:**
- golden-visa-advisory_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/golden-visa-advisory:a54e5d7a2a33d59f4a2b0fe54e6c7fe1c796c324)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.golden-visa-advisory.rule=Host(`goldenvisa.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Premium client (golden-visa). Custom domain likely. **Verify DNS.**

---

## ometsdental

**Service state:**
- ometsdental_ometsdental-backend: 1/1 (image: python:3.12-slim)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  (no Traefik routing labels)

**Exposed ports:**
  *:30089->8000/tcp

**Recommendation:**
  Backend on port 30089 — only the API. If the frontend is ometsdental.com hosted elsewhere (per AGENTS.md, it's on Cloudflare Pages), the backend is hidden by design. **Keep.**

---

## ozmontania-website

**Service state:**
- ozmontania-website_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/ozmontania-website:2c36ee68cdc67b5a8775a13bd0126b5fceeb43c1)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.ozmontania-website.rule=Host(`ozmontania.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Site name: ozmontania. Custom domain likely. **Verify DNS.**

---

## pierce-charm

**Service state:**
- pierce-charm_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/pierce-charm:a4eeec56b61391c8ed5a68c2057fafaba70fce28)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.pierce-charm.rule=Host(`piercecharm.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Per CLAUDE.md, single-locale es site. Custom domain likely. **Verify DNS.**

---

## pitchy-website

**Service state:**
- pitchy-website_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/pitchy-website:4f700da0bb1397d66a6f4c3fa874c40b430a3b32)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.pitchy-website.rule=Host(`pitchy-blindex.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Likely pitchy.co client. **Verify DNS.**

---

## somosgay-site

**Service state:**
- somosgay-site_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/somosgay-site:6803632cc3de1596221a21aee8411fe1827d5d1e)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.somosgay-site.rule=Host(`somosgay.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Spanish site (somos = 'we are'). **Verify DNS.**

---

## villamayor-asociados

**Service state:**
- villamayor-asociados_web: 1/1 (image: ghcr.io/ai-whisperers/paragu-ai-platform/villamayor-asociados:2c36ee68cdc67b5a8775a13bd0126b5fceeb43c1)

**Traefik routing (where it ACTUALLY points, if anywhere):**
  traefik.http.routers.villamayor-asociados-villa_mayor_asociados.rule=Host(villa-mayor-asociados.paragu-ai.com)
  traefik.http.routers.villamayor-asociados.rule=Host(`villamayor.paragu-ai.com`)

**Exposed ports:**
  (none exposed publicly)

**Recommendation:**
  Memory says this was fixed in 2026-07-06 session (DNS + Traefik labels). Probably a Traefik label regression — re-run the alias-fix script.

---

## Internal stacks (NOT invisible — they have dedicated ports, that's by design)

| Stack | Port | Why |
|---|---|---|
| wa-connect | 30003 | WhatsApp Connect landing — accessed directly, not via wildcard |
| hermes-ws | 3088 | Hermes Workspace UI — internal tool |
| loki | 3100 | Log aggregation — DevOps tool |
| monitor | 30001 | Grafana — monitoring tool |
| openwebui | 30081 | Open WebUI for local LLMs — internal tool |

**These 5 should NOT be on the wildcard DNS — they are intentionally port-specific.** No action needed.

## Quick action plan for the 10 client-facing invisible stacks

1. Run `bash /root/.hermes/scripts/fleet-alias-fix.sh` (if it exists from previous session) to re-apply Traefik labels for villamayor-asociados + others
2. For 3md-website, dra-gabriela, golden-visa-advisory, ozmontania-website, pierce-charm, pitchy-website, somosgay-site:
   - Check hPanel DNS zones for each — they probably have CNAMEs pointing to sunstein.cloud or 72.61.44.159
   - If CNAMEs exist, they ARE public — but our wildcard scan didn't find them because they use their own domains, not *.paragu-ai.com
3. ai-whisperers-site: confirm .org ownership or migrate to .com
4. ometsdental: backend-only by design, no action
