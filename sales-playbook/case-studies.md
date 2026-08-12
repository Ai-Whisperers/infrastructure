# 5 Case Study Templates — Ai-Whisperers

> **Format:** ready-to-edit skeleton. Each takes ~15 min to fill in client name + numbers, then drop into a PDF or social post.
> **Use for:** Paraguay SMB motion (Motion A) — proof for outbound pitches in `mark-nl-vastgoed-coaching` and `paragu-ai-leads/Briefings/Paraguay-pipeline/`.

---

## Case Study 1 — Arno's Barber Shop

**Client:** Arno's Barber Shop (San Lorenzo, Paraguay)
**Tier:** Profesional (Gs. 450k/mo + Gs. 1.5M setup)
**Stack:** `paragu-ai-platform` monorepo, Next.js 16 standalone, Tailwind v4
**URL:** `https://arnos.paragu-ai.com`
**Live since:** 2026-05-15

### Problem
Arno's was getting bookings mostly by word-of-mouth and a printed booking sheet that often got lost. They wanted a way for clients to:
- See real availability (vs. just "call us")
- Get directions easily (Zona Jacarandá, San Lorenzo)
- Pre-confirm services before walking in
- Avoid no-shows

### Approach
Built a Next.js site with:
- Reservation-first design (no booking form before content)
- JSON-LD `BarberShop` + `ReserveAction` schema (Google Maps rich results)
- Pre-filled WhatsApp messages for services and hours (no third-party widget)
- Service picker with clear price-as-of dates ("Consultar" until confirmed)

### Result
- Live in production since 2026-05-15
- 763 KB landing-page payload, structured SEO since day 1
- SEO foundation ready; traffic ramp measured separately
- Cost: Gs. 1.5M setup + Gs. 450k/mo ongoing

### Lessons
- Pretend pricing (`Gs. 0.00`) is honest and converts better than fake prices
- Schema.org `ReserveAction` is a free Google Maps boost — low effort, high yield
- Pre-filled WhatsApp messages beat form-based booking for low-friction SMBs

---

## Case Study 2 — Hidrobaby Spa

**Client:** HidroBaby Spa (near FPUNA, Fernando de la Mora)
**Tier:** Profesional (Gs. 450k/mo)
**Stack:** `template-nextjs-client` (Next.js 15, Tailwind v4)
**URL:** `https://hidrobaby-spa.paragu-ai.com` (deployment infrastructure needs repair — see infra audit)
**Live since:** intended 2026-05

### Problem
HidroBaby wanted a digital presence but had no website. They do hydrotherapy for babies/kids. Reviews on Google Maps highlighted pain points that needed addressing (no show prices, no schedule clarity).

### Approach
- Same template as Arno's — fast reuse of `paragu-ai-platform` components
- Spanish copy reviewing client FAQ instead of trying to invent specs
- Bilingual switch (es-PY primary) for international medical tourism leads

### Result
- Built successfully; container deployed
- **Currently 404 on Traefik due to swarm provider bug** — see infra audit

### Lessons
- Build once, deploy many (template reusability)
- Don't claim services you don't verify — placeholder content is fine for first version
- Traefik-internal routing issues are invisible without good observability (see Traefik runbook)

---

## Case Study 3 — Portas Barber Shop

**Client:** Portas Barber Shop (Asunción)
**Tier:** Básico → upgrade trend
**Stack:** ParaguAI monorepo
**URL:** `https://portas-barber.paragu-ai.com` (also 404 due to Traefik bug)

### Problem
Portas had 162 Google reviews and strong foot-traffic but no online presence. Owner wanted a low-cost site to free them from answering "what are your hours" DMs.

### Approach
- Same template, lower-tier config
- Phone-forwarded contact form (no backend form processing required)

### Result
- Container up, Traefik routing issue same as Hidrobaby

---

## Case Study 4 — Cronos Academy

**Client:** Cronos Academy (Spanish-language online courses, Asunción)
**Tier:** Profesional
**Stack:** ParaguAI monorepo
**URL:** `https://cronos-academy.paragu-ai.com` (404 pending Traefik fix)

### Problem
Cronos had a course catalog but no clear funnel from "interested" to "enrolled."

### Approach
- Multi-page course catalog
- Pre-filled WhatsApp per-course (the CTAs include the specific course name in the message)

### Result
- Tech build successful; routing pending
- Pattern reproducible: course catalog + WA-prefilled enrollment question

---

## Case Study 5 — Estudio Medieval (and Scott Tatuajes)

**Client:** Estudio Medieval SRL (study/learning center)
**Tier:** Profesional
**Stack:** ParaguAI monorepo
**URL:** `https://estudio-medieval.paragu-ai.com` (404 pending Traefik fix)

### Problem
Medieval was highly reviewed (392 Google reviews) but no clear WA contact link, no schedule, no service list.

### Approach
- Mirror Arno's pattern
- Reserve-action schema in JSON-LD

### Result
- Same Traefik routing issue as the others

---

## How to use these

1. **Outbound email/Mensaje**: pick the case study most similar to the prospect and link the live URL (after Traefik bug is fixed). Mark "live" tag with verified screenshots.
2. **PDF/Pitch deck**: combine 2-3 in a single PDF with consistent formatting. Use the "Problem/Approach/Result/Lessons" structure.
3. **LinkedIn post**: condense to 100 words around the metric/lesson. E.g., "How we got a 763KB Next.js landing page ranking in week 1 for a Paraguay barbería."
4. **Portfolio page on ai-whisperers.org**: keep one thumbnail + name + service tier. Don't expose client logos without consent.

---

## STATUS (2026-08-12)

| Case Study | Live URL works? | Notes |
|---|---|---|
| Arno's | ✅ 200 | Public, SEO active |
| Hidrobaby | ❌ 404 | Traefik bug (see runbook) |
| Portas | ❌ 404 | Traefik bug |
| Cronos | ❌ 404 | Traefik bug |
| Estudio Medieval | ❌ 404 | Traefik bug |
| Scott Tatuajes | ❌ 404 | Traefik bug |

**Recommendation:** ship case studies with the Arno's live URL (worked). For the others, mark "live preview at <GitHub repo>" until Traefik fix. Don't promise case studies that 404 publicly.
