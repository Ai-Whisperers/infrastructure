# Outreach Sequence — Paraguay SMB + EU Consulting

> **Use for:** Motion A (Paraguai SMB) and Motion B (EU).
> **Cadence:** 4 touches over 2 weeks. Stop on reply.
> **Tone:** direct, no fluff, no emoji. Spanish for PY, English for EU.

---

## Paraguay SMB sequence (Spanish, WhatsApp-first)

### Touch 1 — WhatsApp cold, 1-2 sentences
> Hola [Nombre], vi tu local en [barrio/zona]. Soy [tu nombre], de Ai-Whisperers. Hacemos sitios web para [rubro] en Paraguay desde Gs. 150k/mes. ¿Querés que te pase 2-3 ejemplos reales o preferís otro día?

Why: low-commitment ask (3 ejemplos vs "agendar demo"). Works because:
- If they read it, they reply
- If they ignore, you don't waste time
- Local-rubro mention ("barbería / spa / peluquería") shows research

### Touch 2 — WhatsApp, 4 days later, if no reply
> [Nombre], te paso los ejemplos: [link1], [link2], [link3]. Todos Paraguay. Si querés saber más cómo funciona, me escribís. Si no, sin compromiso.

Why: gives proof-of-work but doesn't push.

### Touch 3 — Final WhatsApp, 7 days after Touch 2
> Última vez que te escribo por esto. Si querés una propuesta real para tu local, decime y la armo. Si no, éxito.

Why: psychological close — produces either reply or silence. Replys are useful data.

---

## EU Consulting sequence (English, email-first)

### Touch 1 — Email, hyper-personalized
Subject: [their company] + [specific observation]
Body: 4-6 lines. Lead with one specific observation from their public footprint (LinkedIn post they made, product feature they ship, podcast they were on). Then one sentence about what Ai-Whisperers does. Then one CTA.

> Subject: Re: the EuroTour podcast with [name]
>
> Hi [first name], listened to your [podcast] episode on [topic] — really liked your take on [specific point]. That's exactly the kind of leverage most [their industry] founders miss.
>
> Quick context on me: I run Ai-Whisperers, a 2-person AI engineering studio that takes equity or fixed fees for transformation work. Phase 1 is a 2-week diagnostic that lands a board-ready plan; Phase 2 is multi-year pilots.
>
> Two questions if you have 15 min this week:
> 1. Is AI-native transformation something you've actually looked at, or is it on a back-burner?
> 2. If interested, when's a good slot?
>
> — Ivan

### Touch 2 — 5 days later, shorter
> Subject: re: [same]
> Hi [first], bumping. The diagnostic slots for [month] are starting to fill. Will you have the 15 min this week, or should I close the file?

### Touch 3 — Final, 7 days later, brief
> Subject: re: [same]
> Closing the file. If you ever want to pick this back up, my number is +595 991 501444 and my email is ivan@ai-whisperers.com. Buena suerte.

---

## Templates for common variants

### Demo / proposal email (after intro call)
> Subject: our conversation — proposed engagement
>
> Hi [first], here's the recap:
>
> **Diagnostic (€25K, 2 weeks):**
> - Kickoff memo by day 1
> - Baseline metrics snapshot by day 5
> - Transformation plan, 15-20 pages, by day 9
> - Final presentation, 90 min virtual, day 10
>
> If we agree on Phase 2, the diagnostic fee is **credited** toward the multi-year engagement, plus there's a clause for equity participation (PPA template attached).
>
> Reading time: 15 minutes. Decision deadline: Tuesday COB.
>
> Attachment: [SOW link]
> Attachment: [PPA template link]

### Self-decline (after silence)
> Hi [first], closing the file. Felt the timing wasn't right. If anything changes, my number is +595 991 501444. Buena suerte — Iván.

### Thank-you (after won deal)
> [first], gracias por la confianza. Setup call para el lunes — te paso el calendar invite. Saludos, Iván.

---

## LinkedIn content (Spanish — public)

Posts 2×/semana. Combine one of:
- Lesson learned (`Hicimos X para cliente Y. Esto aprendimos.`)
- Behind-the-build (`¿Por qué nuestro landing page de barbería pesa 763KB?`)
- Tool share (`Acabamos de open-source una plantilla de sitio para [rubro] en Paraguay.`)
- Industry insight (`El truco de los sitios [rubro] en Paraguay que nadie te dice.`)

Each post ends with one CTA, rotated weekly:
- Link to a case study
- Free PDF download
- Schedule of free 15-min audit call

---

## Tracking

Use `aiw-crm.py new <name>` to log every lead immediately. Use `log` for every touch, with `--next-action` set so the dashboard surfaces overdue re-contacts after 7 days.

Run `aiw-crm.py dashboard` weekly Mondays. Anything not in `won` or `lost` for 14+ days needs decision: continue, close, or escalate.

---

## What's NOT in this doc

- Cold-call script (we don't do these by phone in either market)
- Email forwarding from system aliases (handled in CRM automation, not here)
- LinkedIn automation (manual only — saved outreach sent with `aiw-crm.py log` for retro lookup)
- WhatsApp automation rules (your local PY rep gets them, you don't run them from this layer)

---

## Companion files

- `/opt/data/scratchpad/sales-playbook/aiw-crm.py` — CRM CLI
- `/opt/data/scratchpad/sales-playbook/case-studies.md` — 5 case study skeletons
- `/opt/data/scratchpad/sales-portfolio-2026-08-12.md` (in GitHub audits/) — pricing catalog

---

Last updated: 2026-08-12. Keep this file fresh as you learn what actually works (rejection rates, response rates).
