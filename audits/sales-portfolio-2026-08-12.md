# Sales Portfolio Analysis — Ai-Whisperers

> **Audience:** internal strategy. NOT for client-facing copy.
> **Date:** 2026-08-12
> **Source of truth repos:**
> - `Ai-Whisperers/company/README.md` · `Ai-Whisperers/marketing-strategy/EXECUTIVE-SUMMARY.md`
> - `Ai-Whisperers/Outreach-agent/Pricing/` (canonical pricing — Europe + Paraguay)
> - `Ai-Whisperers/solstein-v2/docs/commercial/` (PE-firm motion templates)
> - `Ai-Whisperers/solstein-manda-research/` (M&A pipeline IP)
> - `Ai-Whisperers/golden-visa-advisory/`, `mark-nl-vastgoed-coaching/`, `course-catalog.md`

---

## 1. Executive summary — what Ai-Whisperers actually sells

A 2-person engineering studio in Paraguay (San Lorenzo) that sells **three orthogonal motions** with different ICPs, pricing, and channels:

| Motion | Offer | Primary market | Currency | ACV |
|---|---|---|---|---|
| **A. ParaguAI SMB** | Subscription sites + automation | PY beauty/wellness/F&B B2C + B2B | Gs. | Gs. 4–22 M / yr |
| **B. Ai-Whisperers Europe** | Value-based AI consulting, monthly retainers | NL/EU coaching, real estate, SMB | EUR € | €6K–66K / yr |
| **C. Solstein / PE Motion** | Equity-for-transformation + diagnostics | PE firms & portcos (LATAM/EU) | EUR € | €25K diag → equity Phase 2+ |

**Common to all three**: GitHub-as-marketing (public proof), Parasite SEO sites (the 28+ client sites), and outsourced engineering firepower via `paragu-ai-builder` / `paragu-ai-platform`.

---

## 2. The product catalog — pro/con by motion

### Motion A. ParaguAI SMB subscription

The 28+ live client sites (`paragu-ai-clients` monorepo, replaces 24 separate repos) run on this motion. Built on `template-nextjs-client` (Next.js 15, Tailwind v4, WA-first) and `site-template` (Next.js 16 universal).

**Pros:**
- **Recurring revenue** at predictable monthly price (Gs. 150K–1.8M = $20–240/mo). Cheapest entry in the catalog.
- **Built-in upsell ladder** (Básico → Profesional → Premium). Cross-tier upgrade is a single Slack thread; no new build.
- **Public proof**: 28 live sites = organic portfolio that ranks in Google for Paraguay niches (barbería San Lorenzo, etc.). Compounds without ad spend.
- **Multi-language by default** (es-PY primary, en optional). 80+ features ready in template.
- **Hostile-builder proof**: the `ometzdental` v1 → v2 case study shows we can ship a real client site that beats the previous Hostinger-templated one (the v1 was suspended by Hostinger for trademark complaint — we rebuilt it leaner).

**Cons:**
- **Low per-account value** (~$240/mo ceiling). To reach €5K MRR you need 21 Premium clients. Burnout risk is real with two ops people.
- **Currency risk**: Gs. is volatile; pricing must reset quarterly against USD.
- **TAM is geographically capped** (Paraguay + nearby Asunción/market). To grow outside PY you must switch motion.
- **Onboarding tax is high per unit**: every new client wants 30-45 min of personalization even with template.
- **WhatsApp-first is a trademark minefield**. The `gpt/wpp/wa-mensaje` banlist forced a Hostinger suspension in 2026-Q1; we still carry that risk into every site that talks about booking/CRM.

**Packaging rationale** (from Mark's quote, scaled): the pricing table mixes site+automation to lock clients beyond "website" — once the bot is running and the CRM is wired, churn drops.

---

### Motion B. Ai-Whisperers Europe (NL/EU consulting)

Live engagements: **Mark (De Vastgoedbegeleider, coaching/real estate)** and **Wesley van de Camp (ops consultant)**. Mark's repo `mark-nl-vastgoed-coaching` is the canonical engagement case.

**Pros:**
- **High per-account MRR** (€500/mo entry, €3.5K/mo Pro ceiling, Enterprise custom > €5.5K/mo).
- **Value-based pricing**, not time-based — we charge for transformation, not hours. Reframes the conversation away from "is this expensive?" to "is this worth the lift?"
- **Methodology moat**: `solstein-v2` and `code-agent` are IP that a competitor in NL would have to build from scratch. The methodology is publishable (we put it in the playbook chapter), which paradoxically builds trust (transparent methodology is rare in EU consulting).
- **Existing relationships**: Mark (NL real estate coaching) + Wesley (ops) = live pipeline. Both already signed language: EN + NL where needed. `cursor-standards` ruleset for `outreach/language-locale` is ready-made.
- **Currency stability** in EUR — predictable revenue base.

**Cons:**
- **No deals closed yet to validate pricing** (per the README: "No closed deals yet to validate"). All numbers are hypothesis.
- **Capacity ceiling**: EU retainer work needs 5-10 hrs/wk of dedicated attention. With 2 ops people, max 3-4 active EU retainers before quality drops.
- **Time-zone tax**: PY → NL = 5-6 hr offset. Async-first works; sync needs to be scheduled carefully.
- **EU compliance overhead**: GDPR + VAT + BBL Dutch private limited process for serious clients. We need a fiscal EU entity or a fiscal representative; this is open.
- **LinkedIn/outbound automation scoped separately** (per Mark's quotation footnote). That's a product variant we haven't formalized.

**Packaging rationale**: the four tiers (Starter/Growth/Pro/Enterprise) are designed for an **expansion ladder** — every Eng tier hardcodes an `Upgrade signal` (more workflows, deeper automation) that justifies the 5-10× price jump.

---

### Motion C. Solstein — PE/portco motion

`solstein-v2` = internal prospecting tool + transformation methodology. NOT a SaaS (v1 SaaS was archived; see `competitive-positioning.md` "we are not a SaaS product sold to PE firms").

**Pros:**
- **Equity-as-currency** is the kicker. AI-Whisperers' actual business model per `BUSINESS.md`: "taking equity (or fixed fee) in transformation engagements". This is asymmetric: PE portcos have €10M+ valuations; even a 0.5% stake can dwarf any retainer.
- **Diagnostic (Phase 1) is standalone**, chargeable at €25K with no Phase 2 obligation. The SOW deliberately says: "If Client chooses not to proceed with Provider to Phase 2, Client retains the full deliverable and owes nothing beyond the fixed fee." That's a trust-builder.
- **Honest positioning game**: the `competitive-positioning.md` document names six alternatives (MBB, Accenture, boutique, OS-partner hire, portco hire, do-nothing) and gives an honest differential — not "we're better". This is rare in the EU PE scene; it reads as credible.
- **Solstein-M&A Research** is a pipeline product feeding prospect identification (25+ data sources). Even without closing, it generates outreach-grade briefings.
- **Wizard Academy** is positioned as the educational / lead-magnet arm of this motion (`Exponential Magic School`).

**Cons:**
- **No track record vs. MBB/Accenture** = "career-cover" gap (PE LPs don't trust boutique operating partners yet). Onboarding / first 3 deals will be 18-month sales cycles.
- **2-person team is a credibility gap**. PE partners look for size; even though we'd subcontract, the message is "we are small." Have to reframe as "senior + lean = faster."
- **Pricing window** (per Phase 1 SOW) is €25K fixed-fee, change-orders at €1,800/person-day. This is below MBB€1M benchmarks — buyers may discount us as "cheap." Have to frame as "right-sized for the diagnostic."
- **The equity deals haven't closed**. The complete commercial package (SOW, PPA, equity term sheet, pitch deck outline, security posture, legal posture) is in `solstein-v2/docs/commercial/` but I can't see in the corpus evidence of an executed equity transaction. This is the largest open assumption.
- **MAS regulatory exposure**: taking equity in portcos that may be in PE-driven roll-ups requires careful KYC/AML. Need a fiscal/legal review before the first equity close.

**Packaging rationale**: the package = SOW + methodology playbook (10 chapters) + case studies + sample assessments + commercial templates + legal/security posture. PE firms buy by the package, not by the day. The Phase-1 €25K is a foot-in-the-door; equity in Phase 2+ is where the asymmetric upside lives.

---

## 3. Cross-motion pricing options (consolidated table)

Below: the **catalog of priced offers**, drawn from `Outreach-agent/Pricing/`. Rate source: market benchmarks (2026) + internal estimates; no closed deals yet to validate.

| Tier | Motion | Description | Monthly | Setup | Currency |
|---|---|---|---|---|---|
| **Starter / Básico** | A. PY SMB | Site + hosting + landing page | Gs. 150K (~$20) | Gs. 500K | Gs. |
| **Profesional** | A. PY SMB | Site + automations + lead follow-up | Gs. 400–650K | Gs. 1.2–2.5M | Gs. |
| **Premium** | A. PY SMB | Full ops automations | Gs. 800K–1.8M | Gs. 2.5–5M | Gs. |
| **Starter** | B. EU consulting | Audit + landing + advisory report | €500–700 | €400–500 | EUR |
| **Growth** | B. EU consulting | Pilot workflow + integrations + monthly review | €1.5K–2.5K | €1.5K–2.5K | EUR |
| **Pro** | B. EU consulting | Multi-workflow + content engine + SLA 48h | €3.5K–5.5K | €4.5K | EUR |
| **Enterprise** | B. EU consulting | Multi-agent orchestration + dedicated account | Custom (€5.5K+) | Custom | EUR |
| **PE Phase 1** | C. PE diagnostic | Two-week org + codebase diagnostic | — | €25,000 one-shot | EUR |
| **PE Phase 2+** | C. PE transformation | Equity + multi-year pilots | Fixed + equity | Variable | EUR |

**Hidden cost notes** (from various footers):
- All prices exclude VAT (IVA in PY; BTW in NL).
- "LinkedIn/outbound automation scoped separately after engineering review" (Mark quote) — not in the catalog; ticket of size.
- Setup fees are tax-distinct from monthly (commonly recognized as a project deliverable, not a recurring service).
- Cross-market pricing ratios: €500 ≈ Gs. 4.5M ≈ $530 → so `Starter/Monthly` ratio EU/PY is ~1.0× in USD but 1.0× in EUR. `Pro` ratio is 1.6× EU/PY in USD — i.e. EU buys less per dollar but more absolute value.

---

## 4. Commissions & incentives

Currently **nothing codified in the corpus**. The `Outreach-agent/Pricing/` reads "internal use" — there's no sales team comp plan in any open repo. Building one from scratch:

### Recommended commission structure (motions A/B/C)

| Motion | Role | Commission | Cap |
|---|---|---|---|
| **A. PY SMB** | Self-serve / inside sales (closed by founders) | 5–10% of Year-1 contract value (setup + 12 mo) on first closed deal; 2.5% on renewal | 10% of total PY GTV per quarter |
| **B. EU consulting** | Closer (founder-led) | 10% of TCV Year-1, paid 50% on signature + 50% after 90-day success check | Per-deal: €2,500 cap (so Pro deals don't net €3,500) |
| **B. EU referral** | Partner (NL introductions via warm intros) | 10% of TCV Year-1, paid as ongoing residual for 12 months | Capped at 3 deals per partner/year |
| **C. PE Phase 1** | Senior partner (founder-led) | 8% of fixed fee | None — flat 8% regardless of TCV |
| **C. PE Phase 2+ (equity)** | Originator + closer (split) | 1–2% of equity-stake value at close, plus 0.5% annual board-advisor retainer | Disclosed in PPA upfront; vesting 4y/1y-cliff |

### Rules of engagement
- **Who can claim a lead**: first briefing-date in the CRM (`Briefings/Europe`, `Briefings/Paraguay-pipeline`) is the canonical "registered lead." After 60 days of inactivity the lead returns to pool.
- **Compounding**: if a single buyer purchases across two motions (e.g., EU Pro + Paraguay Premium for a parent company), the higher commission rate applies to the bundled deal.
- **No commissions on renewals unless re-scoped** — churn kills margins. Reset at TCV-vs-cohort.
- **Draw against commission**: optional, capped at 50% of trailing 90-day commission average. Repaid from future deals.

### Compensation philosophy
The repo corpus is consistent: the studio is **founder-led, no sales reps yet**. Commissions become relevant when we add headcount OR when we open up referrals/affiliates. Until then, the founders are the sales team and the "commission" is the multiple of base.

---

## 5. How the motions should be structured

Three sub-orgs, not three brands. Here's the structure that fits the actual ops:

```
Ai-Whisperers · Single legal entity · 2 founders + contracted help
├── Motion A. ParaguAI
│   ├── Build: paragu-ai-platform monorepo (private, the source of truth)
│   ├── Deploy: paragu-ai-clients monorepo (public, 11+ live)
│   ├── Templates: template-nextjs-client (v1) + site-template (v2) — keep both for back-compat
│   ├── Sales: founder-led + WhatsApp + cold-DM to F&B list (paragu-ai-leads.csv)
│   └── CS: founder-led inside the WA conversation
│
├── Motion B. Ai-Whisperers Europe
│   ├── Build: code-agent + solstein-v2 (private; GitHub-as-marketing)
│   ├── Sales: founder-led via mark-nl-vastgoed-coaching + Warm-intro pipeline
│   ├── Outreach: Outreach-agent/Leads/Briefings/Europe
│   └── CS: monthly async reviews + Slack-connect
│
└── Motion C. Solstein
    ├── Outreach: solstein-manda-research (data) + solstein-v2 (case studies + SOW/PPA)
    ├── Sales: founder-led, 6-18 month cycles
    ├── Engagement: 2-wk diagnostic then optional Phase-2
    └── Equity: held via PPA template; needs legal opinion per portco
```

**Decision points** (what's actually still open in the repo corpus):
- **EU entity**: do we set up a Dutch B.V. or run EU work from Paraguay? Tax + VAT implications differ. Recommend B.V. (or Estonian e-Residency OÜ) before Year-2.
- **PE fiscal structure**: how to hold equity (SPV/holding company in NL or US-Delaware C-Corp?). Existing repos imply a holding pattern but I haven't seen the actual vehicles.
- **Sales headcount**: founders cover all three motions today. Growth requires either a) a closer on Motion B (cheapest leverage, EU language fit), or b) a rev-ops generalist for Motion A (build templates + SDR outreach).

---

## 6. Possible sales channels — best-to-worst by motion

Drawn from `marketing-strategy/EXECUTIVE-SUMMARY.md` + `Outreach-agent/Leads/_TEMPLATE.md` + corpus review.

### Channels ranked by expected ROI (per motion)

| Channel | Motion A (PY) | Motion B (EU) | Motion C (PE) | Why |
|---|---|---|---|---|
| **GitHub-as-marketing** (this corpus) | 🟢 Medium | 🟢 **High** | 🟢 **High** | 42 public repos = unique proof; nobody in EU can match it for AI-native transformation |
| **WhatsApp/LinkedIn outbound** (templated: `Outreach-agent/Outreach/email-history/`) | 🟢 **High** | 🟢 **High** | 🟡 Medium | PY: WA is the primary business channel. EU: LinkedIn + cold email is standard. PE: warm intros only |
| **SEO via client sites** | 🟢 **High** | 🟡 Medium | — | PY local SEO compounds: 28 sites × niche keywords → programmatic traffic |
| **Inbound from existing clients** (referral) | 🟢 **High** | 🟢 Medium | 🟡 Medium | "Got the site, now I want automations" is a known upgrade path |
| **Free tools / lead magnets** (yt-transcript, code-agent UI) | — | 🟡 Medium | — | EU audience evaluates tools; PY buys relationships |
| **Paid ads (Google/Meta)** | 🟡 Medium | 🟡 Low | ❌ Avoid | Low-margin channels for both markets; only useful for retargeting |
| **Guest posts / podcasts** | 🟡 Medium | 🟡 Medium | 🟢 **High** | PE partners consume thought-leadership; consider PE-focused outlets (PEHub, Strictly Financial) |
| **Conferences / in-person** | ❌ | ❌ | 🟢 **High** | PE/portco world runs on handshakes. Find 3 events/yr to attend |
| **Product Hunt launches** | — | 🟡 Low | — | Noise/return ratio poor for B2B AI in 2026 |
| **Strategic partnerships** (other PY devs, NL PE lawyers) | 🟢 **High** | 🟢 **High** | 🟢 **High** | "Find 3 strategic partners" is the highest-leverage motion long-term |
| **Cold email templates** (`Outreach-agent/Outreach/email-history/`) | 🟢 **High** | 🟢 **High** | 🟡 Medium | Pre-built scripts; just need to ship |
| **PR in LATAM/EU media** | 🟡 Medium | 🟡 Medium | 🟢 Medium | Long-lead play for PE motion only |

### The two highest-leverage plays to ship in next 90 days

1. **For Motion A (Paraguai)**: ship 10 client sites with a parallel **WA-driven referral promo** ("bring me 1 paying neighbor this month, get next-month free"). The tool exists; we need the playbook. Couple with **daily LinkedIn content in Spanish** (founder brand, not brand brand).

2. **For Motion B+C (EU/PE)**: open the `solstein-manda-research` repo as a **public free tool** ("run a free 5-min research pass on your target") + use it to seed outbound to PE partners. Push via LinkedIn ops-engineering thought leadership 2-3×/week.

---

## 7. Pros and cons — overall portfolio

### Portfolio-level pros
- **Three motion diversity**: PY low-end + EU mid-tier + PE high-end. Hedged across geographies and ticket sizes.
- **Public proof everywhere**: every product/engagement has a public repo. Nobody in our competitive set (MBB/Accenture/boutiques) ships this much proof.
- **Methodology moat in `solstein-v2`** + **template moat in `paragu-ai-clients`**: these are real, publishable, defensible IP.
- **Multi-currency**: Gs./USD/EUR mix provides natural FX hedge.
- **Compounding assets**: client sites produce leads → leads produce sites → sites produce leads.

### Portfolio-level cons
- **Capacity ceiling at 2 ops**: until we bring on a closer (EU motion) or an SDR (PY motion), we cannot exceed ~€10K MRR across all three motions without burning founders out.
- **No sales infrastructure**: no CRM instance, no outbound sequencing, no funnel reporting. The `Briefings/` template is the de facto CRM. Buy Pipedrive or HubSpot this quarter.
- **Trademark ban constrains Motion A**: every site that mentions WhatsApp/Meta must be scrubbed (24+ open compliance PRs already, per `all-prs.json`). This is a tax.
- **No EU entity yet** = capacity/growth ceiling on Motion B.
- **No closed equity deals** = Motion C is still hypothesis-priced.
- **Founders are full-stack + sales + delivery**: every minute spent on strategy is a minute not on delivery. Need a fractional COO or chief of staff within 6 months.

---

## 8. Recommended order of operations (next 90 days)

If I were the founders, this is the sequence:

| Week | Action | Motion | Effort |
|---|---|---|---|
| 1 | Set up Pipedrive (or HubSpot) CRM, migrate the `Briefings/` template | Cross | 4 hr |
| 1 | Spin up a `code-agent` public demo on Hugging Face Spaces | B+C | 6 hr |
| 2 | Ship 5 case study PDFs from existing client work (Hidrobaby, Arno's, etc.) using `paragu-ai-leads` data | A | 8 hr |
| 2-3 | Draft the "WA-driven referral promo" playbook for ParaguAI clients | A | 4 hr |
| 3 | Open sales to 5 named EU targets using `mark-nl-vastgoed-coaching` format | B | 6 hr |
| 3 | Decide EU entity question (NL B.V. vs. EE OÜ); book 1-hr consult | B | 1 hr + $300 consult |
| 4 | Pitch PE-Phase-1 €25K diagnostic to **one** named PE firm (via Mark's network) | C | 8 hr prep + 6 hr meetings |
| 5 | Ship `solstein-manda-research` as public web tool (lite version, no API keys required) | C | 12 hr |
| 6-8 | Run outbound sequence using `Outreach-agent` templates against EU MBB-bypass targets | B | 12 hr/wk |
| 8 | Quarterly review: assess MRR, close-rate, hire closer (motion B) or SDR (motion A) | Cross | 1 day |

**Goal: by day 90, hit €5K MRR across all three motions combined (= ~$5.5K MRR).** Below that, stay lean; above that, hire.

---

## 9. Quick financial sanity checks

| Check | Question | Source |
|---|---|---|
| Gross margin on Motion A Premium (Gs. 800K/mo = $107/mo at Gs. 7,500/USD) | Are we gross-margin positive? | Cost infra: Paraguay thin; mostly labor. Likely yes 70%+ |
| What does Motion B Pro cost to deliver? | €3.5K/mo for ~5-8 hrs/wk of senior delivery + content engine + 1 workflow = gross 80%+ | `mark-nl-vastgoed-coaching/03_PRODUCT/` not opened, but design implies senior-led |
| What does Motion C PE Phase 1 cost to deliver? | €25K fixed for ~160 person-hours = €156/hr effective | `phase-1-sow-template.md §6` |
| What is the breakeven for hire a closer? | €3K/mo salary × 12 = €36K + €9K overhead = €45K. Need 1 EU Pro deal (€42K setup + €42K Y1 MRR → 90-day payback) | Math above |

**Bottom line**: with a single EU Pro deal closed, the studio crosses the threshold where hire-a-closer becomes self-funding. Without that, every quarter burns runway.

---

## 10. Open questions for founders

1. **EU entity formation**: which jurisdiction, which fiscal representative, target formation date?
2. **First PE-Phase-1 signature**: do we have a warm intro pending, or do we need to build the pipeline from scratch?
3. **Sales headcount plan**: closer (motion B) or SDR (motion A) first?
4. **Sales CRM**: Pipedrive (cheaper, PY-friendly) or HubSpot (richer, better for PE motion)?
5. **Equity vehicle**: legal vehicle to hold portco equity?
6. **Trademark scrubbing**: continue parallel campaign or pause new sites that involve WA/Meta until banlist is invalidated?
7. **Pricing review cadence**: when (next quarter? annually?) do we revisit the Gs. and € numbers?
8. **Who is the first named PE firm** to send the Phase-1 SOW to?

---

**Source files referenced:**
- `Ai-Whisperers/company/README.md`
- `Ai-Whisperers/marketing-strategy/EXECUTIVE-SUMMARY.md`
- `Ai-Whisperers/Outreach-agent/Pricing/Pricing Table – Lead Pipeline Overview.md`
- `Ai-Whisperers/Outreach-agent/Pricing/Europe/Quotation – Mark – De Vastgoedbegeleider.md`
- `Ai-Whisperers/Outreach-agent/Pricing/Europe/Quotation – Wesley van de Camp.md`
- `Ai-Whisperers/Outreach-agent/Pricing/Paraguay/Quotation – Bichos Gym.md`
- `Ai-Whisperers/Outreach-agent/Pricing/Paraguay/Quotation – Cerveza Trentina (B2B Paraguay).md`
- `Ai-Whisperers/solstein-v2/docs/BUSINESS.md`
- `Ai-Whisperers/solstein-v2/docs/commercial/competitive-positioning.md`
- `Ai-Whisperers/solstein-v2/docs/commercial/phase-1-sow-template.md`
- `Ai-Whisperers/solstein-v2/README.md`
- `Ai-Whisperers/solstein-manda-research/README.md`
- `Ai-Whisperers/golden-visa-advisory/README.md`
- `Ai-Whisperers/mark-nl-vastgoed-coaching/README.md`
- `Ai-Whisperers/paragu-ai-leads/README.md`
- `Ai-Whisperers/paragu-ai-clients/README.md`
- `Ai-Whisperers/template-nextjs-client/README.md`
- `Ai-Whisperers/site-template/README.md`
