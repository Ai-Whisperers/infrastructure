# ParaguAI — Complete Build Wishlist

Everything that should be built but isn't yet. Organized by impact, with sources.

---

## TIER 0: SYSTEMIC FIXES (Blocking Everything)

These affect ALL clients. Fix them once, benefit everywhere.

### 0.1 Fix All 22 Cron Jobs
| Source | Current | What to Build |
|--------|---------|---------------|
| All crons ERROR | All 22 jobs failing — OpenRouter or model deprecation | Diagnose error logs, fix provider config, resume pipeline |

### 0.2 NPM-Publish client-kit as @ai-whisperers/client-kit
| Source | Current | What to Build |
|--------|---------|---------------|
| superspuma, dayah, depiflash | Manual copy of 7 components per repo | Extract to npm package: Header, Footer, WhatsAppFloat, CookieConsent, CTABanner, MobileCTA, ProcessSection. Version it. All repos consume from npm. |

### 0.3 Unified i18n Package as @ai-whisperers/i18n
| Source | Current | What to Build |
|--------|---------|---------------|
| 4 different patterns across sites | Each site reinvents locale loading | Pick golden-visa's master-JSON pattern (7 langs in 1 file) and package it. All new sites use it. |

### 0.4 Move /tmp/ Repos to Permanent Home
| Source | Current | What to Build |
|--------|---------|---------------|
| villamayor-asociados, maiyu-atelier | Live from /tmp — lost on reboot | Move to /root/{name}, add to Docker, ensure regular git push |

### 0.5 Fix All 3 IC Cron Jobs
| Source | Current | What to Build |
|--------|---------|---------------|
| ic-health-check, ic-hourly-audit, ic-morning-briefing | All ERROR | Fix to actually monitor and report — currently broken scuttlebutt |

---

## TIER 1: REVENUE CLIENTS (Build These First)

### 1.1 Superspuma — Revenue Features

Revenue gap: 3 high-value features from business docs.

#### Bundle Builder (+Gs 1,170,000 avg order uplift)
| Source | What to Build |
|--------|---------------|
| /contacts/deal-strategy.md | Product bundling UI: select mattress + base + pillow → discounted bundle price. Already have bundle.ts in elviajero — port it. Similar to "Frequently Bought Together" but for configurable products. |
| | **Est:** 8h |
| | **Stack:** React + JSON content (no DB needed) |

#### Product Finder Quiz
| Source | What to Build |
|--------|---------------|
| /docs/opportunity-analysis.md | "¿Qué colchón eres?" quiz: 5-7 questions about sleeping position, firmness preference, budget → recommendation. Product-quiz.tsx exists in fun4me — port it. |
| | **Est:** 6h |
| | **Stack:** React + if-else logic + content/es.json |

#### Real Product Photos
| Source | What to Build |
|--------|---------------|
| Current: 24 placeholder images | Source real product photos from superspuma.com.py or client. Add to /public/images/products/ |
| | **Est:** depends on client |

#### B2B Portal (2300 Existing Clients)
| Source | What to Build |
|--------|---------------|
| /contacts/leticia-roig.md | Wholesale login: bulk ordering, custom pricing (already in elviajero's bulk-price.tsx + auth-context), order history, invoice download |
| | **Est:** 40h |
| | **Stack:** Copy elviajero auth + cart + order flows. SQLite or Supabase. |

#### Store Locator with Map
| Source | What to Build |
|--------|---------------|
| /docs/business-analysis.md | Map of Superspuma tiendas físicas (Villeta, Asunción, Argentina). Already have leaflet in ozmontania — port. |
| | **Est:** 3h |

### 1.2 Golden Visa Advisory — MVP Complete, Add Depth

| Feature | Source | Notes |
|---------|--------|-------|
| Blog | GV currently has 0 blog pages | SEO content: residency guides, Paraguay business setup, investor tips |
| Live Consultation Booking | Integration with calendar | Cal.com or similar embedded |
| Cost Calculator | "Cuánto cuesta mi visa?" | Interactive form: business type → estimated costs + timeline |
| GTMA/CSU/EU Treaty Passport Info | Missing from site | Paraguay's unique treaty-based residency programs — major differentiator |
| Success Stories Grid | Content exists (SuccessStory.tsx) but needs real cases | Get Raul's actual client wins |

### 1.3 Granja Cabral / Laura Egg Business

| Feature | Source | Notes |
|---------|--------|-------|
| WhatsApp Sales Pipeline | WA group 120363408591139576 | Automated order taking via WhatsApp (already have whatsapp-cart.tsx in fun4me) |
| Egg Production Dashboard | laura-egg-business/03_sales | Interactive charts: eggs/day, feed costs, profit margins |
| Client Order Portal | Existing clients place standing orders | Simple: product list + quantity + delivery date → WhatsApp order |
| Feed Cost Tracker | laura-egg-business/04_supply_chain | Track ingredient costs, calculate break-even egg price |
| Chicken Health Logger | laura-egg-business/01_core_operations | Daily health entries: mortality, feed consumption, temperature |

---

## TIER 2: ACTIVE DEVELOPMENT CLIENTS

### 2.1 Fun4Me — Fix + Push (Blocking Auth)

| Bug/Feature | Source | What to Build |
|-------------|--------|---------------|
| Git push to remote | — | Auth fixed 2026-05-04 (custom pg api). Branches un-pushed. |
| Order save to DB | ROADMAP-v4.md B1 | Checkout doesn't save to Supabase |
| Admin auth | ROADMAP-v4.md B2 | Zero auth protection on /admin |
| User accounts | FULL-PLAN.md Phase 1 | Profile, addresses, preferences, CI/ID upload |
| CI/ID Verification | FULL-PLAN.md Phase 2 | Upload + verify identification documents |
| Event Ticketing | FULL-PLAN.md Phase 3 | Sell tickets to events (calendario + checkout) |
| Blacklist | FULL-PLAN.md Phase 4 | Entry verification for community safety |
| Guest checkout → account | Roadmap 1.5 | After purchase, prompt to create account |
| Payment integration | ROADMAP.md Problem 2 | Bancard vPOS or similar for Paraguay |
| Loyalty program | ROADMAP.md Phase 4 | Customer points/rewards |

### 2.2 Dayah LitWorks — Cover Management System

| Feature | What to Build |
|---------|---------------|
| Cover naming/tracking system | 239 unnamed covers — need a database. Simple: name, genre, client, status, date |
| Author portfolio pages | Per-author landing pages with their books/covers |
| E-book preview | Amazon "Look Inside" style preview |
| Client dashboard | Authors log in, see their book's cover options, approve/download |
| Bundle pricing widget | Pick X covers for Y price (currently in content/es.json) |

### 2.3 El Viajero — Feature Complete, Polish

| Feature | What to Build |
|---------|---------------|
| Supabase migration | Currently SQLite — fragile for multi-replica Docker |
| Real payment gateway | Bancard vPOS integration |
| Stock sync | Reconcile online store with physical shop inventory |
| Auto-order to WhatsApp | New orders → auto-forward to shop WhatsApp |
| Delivery tracking | Real-time courier integration |
| Product variant matrix | Size × color × material × price per variant |

### 2.4 Oz Montania — Content Overhaul

| Feature | Source | Notes |
|---------|--------|-------|
| Real images | 0 of 7 pages have real photos | Get from IG @ozmontania. 40+ major works documented |
| Full portfolio | RESEARCH.md lists 20+ works, site shows 6 | Add: institutional murals, festivals, international work |
| Estudio 8 section | Link points to "#" | Production studio co-founded by Oz |
| Awards/recognition | RESEARCH.md — Distinguished Personality, jury roles | Social proof |
| Pedagogical work | Workshops, Museo del Prado, Quito | Differentiator |
| Store | Currently empty | Prints, merch, commissioned mural inquiry |
| Blog | Content mode | Artist diary / process posts |

---

## TIER 3: SERVICE CLIENTS (Auto-Generated, Need Real Content)

### 3.1 Clinica Duerksen — Data Layer

| Feature | Source | Notes |
|---------|--------|-------|
| Real content populate | ROAST.md | Current: fake reviews, empty address, placeholder photo. Need real: doctor bio, address, phone, photos, patient testimonials |
| Wire Supabase queries | ROAST.md | Supabase client exists, zero queries use it |
| Service pages | ROAST.md | Nav links to /servicios — page doesn't exist. 8 services in code, 0 rendered pages |
| Appointment booking | app/agendar-cita/ exists | Might work — test and wire to real calendar |
| Patient forms | app/formulario-paciente/ | Wire to Supabase submissions |
| Error handling | ROAST.md | No error.tsx, loading.tsx, or 404 page |
| Performance | Remove framer-motion → CSS | ~45KB JS savings |
| CI/CD + tests | 0 tests | Add vitest + Playwright |

### 3.2 Magnolia Peluqueria, Mantra Spa, Bichos Gym, Luis de Leon, Cocodrilo Fitness

| All have same problem | What's missing |
|----------------------|----------------|
| LEAD-AUDIT.md exists | Read the audit and implement fixes |
| Auto-generated, never customized | Real content: business name, address, phone, photos, services, team |
| Docker services exist | Verify they deploy correctly (some may be stale) |
| No unique features | Each needs at least 1 differentiator beyond template |

### 3.3 3MD Website — 250+ Item TODO

| Category | Items | Est. Hours |
|----------|-------|------------|
| Foundation (A-001 to A-025) | Template cleanup, Docker, DNS, deploy scaffold | 8h |
| Design System (B-001 to B-020) | globals.css, fonts, tokens, contrast, animations | 6h |
| Components (C-001 to C-035) | Header, Footer, Hero, Portfolio grid, Services, Blog, Contact form, etc. | 16h |
| Pages (D-001 to D-015) | Home, Portfolio (×5 subtypes), Services (×4), About, Blog (×3), Contact | 12h |
| Content (E-001 to E-020) | Real copy, images, team bios, case studies | 8h |
| SEO (F-001 to F-010) | JSON-LD, meta, sitemap, OG images | 4h |
| Deploy (G-001 to G-005) | Docker build, stack deploy, CF DNS | 2h |
| **Total** | **~56h** | |

---

## TIER 4: INFRASTRUCTURE & PLATFORM

### 4.1 ParaguAI Builder — Platform Improvements

| Feature | Source/Notes |
|---------|-------------|
| Real WhatsApp numbers | LAUNCH_READINESS.md — 6 sites have placeholder numbers |
| Demo sites → real demos | /salon-maria etc. use fake data — needs real-looking demos |
| Tenant admin panel | Client logs in, edits their own content |
| Builder CI/CD | Auto-build on content change |
| Analytics per tenant | Each site gets its own GA4/Search Console |
| Template versioning | When client-kit updates, all tenants get updates |
| Performance budgets | Lighthouse CI gates on deploy |

### 4.2 Vete / Lealtis — Platform Overhaul

| Issue | Current | Fix |
|-------|---------|-----|
| Login broken | 500 error on /terrapet/portal/login | Debug auth chain |
| 758 failing tests | 509 integration + 249 component | Fix mock issues, schema drift |
| Security leak | SERVICE_ROLE_KEY in git history | git-filter-branch, rotate keys |
| 776 lint warnings | 9000 allowed on commit | Fix errors, reduce threshold |
| 16 services at 0% coverage | Critical business logic untested | Write tests |
| No CI gate | Builds need 8GB heap | Fix CI workflow |

### 4.3 Monitoring & Observability

| Feature | Current | Build |
|---------|---------|-------|
| Grafana dashboard | Missing | Prometheus data exists, needs dashboard |
| Uptime monitoring | None | Health endpoints exist on most services — aggregate |
| Error tracking | None | Sentry or similar for all client sites |
| Log aggregation | Loki exists? | Check /root/loki-config/ status |
| Alerting | None | Set up for: disk, OOM, 5xx rates |
| Performance budgets | None | Lighthouse CI for every site |

### 4.4 Hermes Web UI — Ship It

| Feature | Notes |
|---------|-------|
| /root/hermes-web-ui built | Multi-model AI chat dashboard |
| Needs deployment | Docker service exists? Check status |
| Telegram/Discord/Slack/WA | Already integrated — just need to deploy |

---

## TIER 5: NICHE / SIDE PROJECTS

### 5.1 Stroopwafel Huis
| Feature | Notes |
|---------|-------|
| Online ordering | Currently static brochure |
| Payment | Mercado Pago or Bancard |
| Delivery zone map | Where do they deliver in Asunción? |
| WhatsApp ordering | Copy elviajero cart → WhatsApp flow |

### 5.2 Refugio Animal Paraguay
| Feature | Notes |
|---------|-------|
| 402 PRs, CHANGELOG.md | Determine current state — what's built vs need? |
| Adoption portal | Full workflow: browse → apply → approve |
| Donation system | EU donation support mentioned |
| Animal directory | Search/filter adoptable animals |

### 5.3 Depiflash — Missing URL
| Feature | Notes |
|---------|-------|
| No traefik rule found | Site built but not deployed to live DNS? Or traefik rule missing |
| Verify live status | Check if depiflash.paragu-ai.com resolves |
| Gallery + testimonials built | Content exists, may just need redeploy |

### 5.4 30vcs — Placeholder
| Feature | Notes |
|---------|-------|
| Next.js 16.2.4 but no content | Empty placeholder. Determine if client exists or kill it |
| 0 git commits | Never committed. Decide fate. |

### 5.5 Nudo — Minimal Metal Band Site
| Feature | Notes |
|---------|-------|
| Minimal src/ structure | Band site works, but could add: tour dates, merch store, music player |
| 8 pages currently | Add: discography with audio player, mailing list |

---

## TIER 6: CROSS-CLIENT REUSABLE MODULES

These should exist as reusable @ai-whisperers/* packages:

| Package | Source Code | Notes |
|---------|-------------|-------|
| @ai-whisperers/whatsapp | elviajero + fun4me + client-kit | Shared: WhatsApp float, WhatsApp cart, share, auto-message builder |
| @ai-whisperers/cart | elviajero | Full cart engine: add/remove/quantities/multi-select/merger/sidebar |
| @ai-whisperers/checkout | elviajero + fun4me | Stepper, shipping, payment method selection, COD, pickup |
| @ai-whisperers/promo-engine | elviajero | Promo codes (percentage/fixed), BOGO, bundle discounts, auto-promo |
| @ai-whisperers/auth | fun4me (pg) + elviajero (sqlite) | Universal auth with multiple backends |
| @ai-whisperers/admin-panel | fun4me | Admin dashboard: product/order/user/coupon CRUD |
| @ai-whisperers/seo | elviajero + duerksen | JSON-LD generators, OG builder, sitemap helper |
| @ai-whisperers/i18n | golden-visa | Master JSON → localized strings, language switcher |
| @ai-whisperers/ui | duerksen + fun4me | Radix-based component library (button, card, dialog, etc.) |
| @ai-whisperers/forms | duerksen | Validated fields, contact forms, server actions, rate limiting |
| @ai-whisperers/blog | elviajero + duerksen | Blog engine: posts, categories, RSS, JSON-LD, comments |

---

## ESTIMATED EFFORT SUMMARY

| Tier | Area | Est. Hours | Priority |
|------|------|------------|----------|
| 0 | Systemic fixes | 8h | 🔴 NOW |
| 1.1 | Superspuma revenue features | 57h | 🔴 NOW |
| 1.2 | Golden Visa depth | 16h | 🟡 THIS WEEK |
| 1.3 | Laura egg dashboards | 20h | 🟡 THIS WEEK |
| 2.1 | Fun4Me fix + push | 8h | 🔴 NOW |
| 2.2 | Dayah cover system | 16h | 🟡 THIS WEEK |
| 2.3 | El Viajero polish | 24h | 🟢 SOON |
| 2.4 | Oz Montania overhaul | 20h | 🟡 THIS WEEK |
| 3.1 | Duerksen data layer | 16h | 🟡 THIS WEEK |
| 3.2 | 5 auto-gen sites → real | 40h | 🟢 NEXT WEEK |
| 3.3 | 3MD website | 56h | 🟢 NEXT WEEK |
| 4 | Infra + platform | 40h | 🟢 ONGOING |
| 5 | Niche projects | 24h | 🟢 WHEN FREE |
| 6 | Reusable packages | 40h | 🟢 ONGOING |
| **Total** | | **~385h** | |

---

## SOURCE REFERENCE

| Document | Source of Requests |
|----------|-------------------|
| superspuma/docs/opportunity-analysis.md | Bundle builder, B2B portal, store locator, quiz |
| superspuma/contacts/deal-strategy.md | Pricing strategy, revenue upsells |
| superspuma/contacts/leticia-roig.md | Contact info, client needs |
| golden-visa-advisory/docs/ | Raul's requirements (in docs/) |
| fun4me-store/ROADMAP.md | V3 roast: 239 features → reality check |
| fun4me-store/ROADMAP-v4.md | 13 bugs, hardening, Phase 1.5 |
| fun4me-store/FUN4ME-FULL-PLAN.md | 60h build: auth, CI/ID, ticketing, blacklist |
| duerksen/ROAST.md | Data layer, real content, error handling, perf |
| duerksen/docs/plan-implementacion-completo.md | Implementation plan |
| 3md-website/TODO.md | 250+ item todo list |
| vete/EPICS.md | 100 epics, 758 failing tests |
| vete/EXECUTION_PLAN.md | Full execution plan |
| ozmontania-website/RESEARCH.md | 10 content gaps |
| paragu-ai-builder/LAUNCH_READINESS_QUESTIONNAIRE.md | 38 items (WhatsApp numbers, demo strategy, content) |
| laura-egg-business/ | 10 directories of business data |

---

*Generated 2026-05-04. Sources: business docs, roasts, roadmaps, TODO files, execution plans across all 15+ repos.*
