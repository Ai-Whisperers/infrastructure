# Solstein M&A — public-facing tool (lite) — Architectural Sketch

> **Status:** NOT BUILT YET. Architectural sketch for when there's bandwidth.
> **Source code:** `[Ai-Whisperers/solstein-manda-research](https://github.com/Ai-Whisperers/solstein-manda-research)` (private; 88 tests passing; 25+ data sources; 8 scoring dimensions).

## Why build it

The full pipeline takes 5-15 min per company. Founders don't have 5-15 min when they're cold-browsing leads. A **lite web tool** that runs the *free* sources only (Wikipedia, GitHub, SEC EDGAR, yfinance, GLEIF, Brave News, DNS) gives a 60-second first-pass. Used to:

1. Generate top-of-funnel leads (companies with high scores = sales targets)
2. Build the public brand as "we know this space"
3. Capture leads (gated PDF report)

## Architecture proposal

```
solstein-lite/
├── README.md
├── LICENSE (MIT)
├── web/
│   ├── next-app/                # Next.js 16 (matches ai-whisperers.org style)
│   │   ├── app/api/research/    # POST endpoint
│   │   ├── app/report/[id]/     # public read-only report viewer
│   │   └── app/free/            # landing + form
│   └── packages/
│       └── solstein-core/       # pulled from solstein-manda-research
├── pipeline/lite.py             # 60s subset of pipeline.research.run_pipeline()
└── deploy/
    └── docker-compose.yml       # CF Worker + R2 + Next.js
```

## Lite-mode design

- **Inputs:** company name + URL (no API keys required)
- **Sources run (subset):** Wikipedia, GitHub, yfinance, GLEIF, Brave News, DNS
- **Score:** only 4 dimensions (out of 8): market position, financial signal, tech footprint, exposure
- **Output:** markdown report (~500 words) + JSON with the 4 dimension scores
- **Time:** 60 seconds (vs. 5-15 min full pipeline)
- **Lead capture:** email gate to download PDF; otherwise share-by-link

## Tech bundle

- Next.js 16 (Tailwind v4) — same as `ai-whisperers.org`
- Vercel deploy + R2 storage for PDFs
- Cloudflare Worker for rate limiting + analytics
- LiteLLM (already hosted at `llm.paragu-ai.com`) for any LLM-backed enrichment

## What NOT to include (kept private)

- The detailed scoring rubric (8 dimensions with vetoes, kill criteria) — that's the moat
- Paid data sources (Clearbit, Crunchbase, Glassdoor) — only available behind a paid plan
- CrewAI multi-agent research flow — overkill for free tier

## How to launch (5 minutes)

1. Clone repo: `git clone https://github.com/Ai-Whisperers/solstein-manda-research`
2. Pull out the free sources subset
3. Wrap in a Next.js 16 form
4. Deploy to Vercel under `research.ae-Whisperers.com` (or similar)
5. LinkedIn launch: "Free 60-second AI-native research on any EU/Paraguay company. 4-dimension score. No signup."

## Estimated build time

- Day 1: Carve out the free source subset (4h)
- Day 2: Next.js form + API route (3h)
- Day 3: PDF export + landing page (3h)
- Day 4: Deploy + analytics (2h)
- Day 5: LinkedIn launch + first 100 requests

**Total: ~12-16 hours.**

## Connection to sales pipeline

Once the lite tool launches:

- Visitors run a free report → captured as CRM `discovery` lead
- High-score results (>75 score) → manual outreach to sales contacts
- Score <50 → discard
- Score 50-75 → run full pipeline (paid engagement opportunity)

## Linkage

- `Outreach-agent/Outreach/` — emails send to leads with the lite tool URL
- `aiw-crm.py new <name>` — capture leads from submit form
- `magnetic-skip/pdf-export` — branded output
- `ai-whisperers.org/infrastructure` — running docs linked from footer

## Open questions

- Which scoring dimensions to include in the lite version? (Suggest: market position, financial signal, tech footprint, exposure. Confirm with founder review.)
- Lead-capture vs. no-capture trade-off: capture = emails to nurture, no-capture = more virality. Recommend capture + the score-stripped URL stays shareable without email.
- Domain: research.ai-whisperers.com / solstein.ai-whisperers.com / scout.ai-whisperers.com? Recommend **research.ai-whisperers.com**.
- Self-host vs Vercel? Recommend Vercel for the front-end (free tier, fast) + R2 storage.

---

**Last updated:** 2026-08-12. Re-evaluate when EU motion has 5+ discovery calls completed.
