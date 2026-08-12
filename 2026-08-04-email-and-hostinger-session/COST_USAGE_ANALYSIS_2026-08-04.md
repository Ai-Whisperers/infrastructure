# Cost & Usage Analysis — 2026-08-04

**Scope:** Every Hostinger subscription + every VPS resource. Marked USED / WASTED / AMBIGUOUS with proof.

---

## Total monthly cost

**$713.34/year = ~$59.45/month** for everything Hostinger.

(Plus estimated $30-50/mo for Cloudflare R2/egress, Meta API subscriptions, etc. — separate billing.)

---

## Hostinger subscriptions — by line item

| Product | Cost | Period | Next bill | Auto-renew | Status |
|---|---|---|---|---|---|
| KVM 8 VPS | **$647.88/yr** | yearly | 2027-02-13 | ✅ YES (just verified) | USED HEAVILY |
| Starter Business Email | $19.08/yr | yearly | 2027-02-19 | ✅ YES | AMBIGUOUS (need hPanel check) |
| .CLOUD Domain (sunstein.cloud) | $26.19/yr | yearly | 2027-01-23 | ✅ YES | **USED — critical** |
| .COM Domain (ometzdental.com) | $60.57/3yr = $20.19/yr amortized | 3-year | 2029-06-02 | ✅ YES | USED (Cloudflare Pages host) |

---

## Per-subscription usage analysis

### 1. KVM 8 VPS — $647.88/yr

**Verdict: USED. Cannot downgrade. Do not lose.**

| Resource | Plan capacity | Used | Utilization |
|---|---|---|---|
| vCPU | 8 cores | varies, currently low load | <50% typical |
| Memory | 32 GB | ~11 GB | ~35% (plenty of headroom) |
| Disk | 400 GB | 281 GB | 73% (after prune, was 82%) |
| Bandwidth | 32 TB/mo | unknown (no API access) | probably <10% (64 small sites) |

**Hosts:** 64 Docker stacks, 77 running containers, 11 infra services (traefik, postgres, evolution-api, redis, loki, grafana, openwebui, portainer, agent-zero, litellm, hermes-workspace), 11 cron jobs.

**Downgrade option?** Not really. Going smaller means losing the fleet. Worth the money.

**Auto-renew confirmed:** YES. No action needed.

### 2. Starter Business Email — $19.08/yr

**Verdict: AMBIGUOUS — likely used but unverified.**

- DNS for sunstein.cloud has full mail config (MX, SPF, DKIM, DMARC, autoconfig, autodiscover) → strongly suggests 1+ mailbox exists
- Hostinger API does NOT expose mailbox list → can't enumerate from here
- hPanel only way to check

**Risk if unused:** $19/yr wasted. Trivial.

**Action:** When you log into hPanel next (for VPS renewal check, etc.), look at Emails section. If you see mailboxes like `hello@sunstein.cloud` or `ivan@sunstein.cloud`, it's used. If empty, cancel it and use the new Hostinger Mail for ai-whisperers.com we're about to set up.

### 3. .CLOUD Domain — sunstein.cloud — $26.19/yr

**Verdict: USED. Critical.**

- 15 DNS records configured (MX, SPF, DKIM×3, DMARC, autodiscover, autoconfig, www, * wildcard, openclaw, agent, portainer, traefik, etc.)
- The `*` wildcard A record → 72.61.44.159 is what makes `bichos-gym.sunstein.cloud`, `nexa.sunstein.cloud`, etc. all work
- Without it: 64+ client subdomains stop resolving

**Risk if lost:** Catastrophic. Lose every client's `.sunstein.cloud` URL.

**Auto-renew:** YES.

### 4. .COM Domain — ometzdental.com — $60.57 / 3 years = $20.19/yr amortized

**Verdict: USED.**

- Domain registered here
- DNS delegated to Cloudflare (NS records point to CF, not Hostinger NS servers) → DNS for this domain is managed at Cloudflare, not here
- Website hosted on Cloudflare Pages (per memory — Ometz Dental site is a CF Pages site, not on this VPS)

**Risk if lost:** Lose ometzdental.com (Gaby's client site domain).

**Auto-renew:** YES.

---

## VPS features — what's oversized?

| Feature | Capacity | Actual use | Verdict |
|---|---|---|---|
| vCPU | 8 | usually <1 load avg, peaks at 18.9 | oversized (4 vCPU would suffice, but no smaller tier at Hostinger KVM 8 is the smallest "8" tier — actually it's labeled "KVM 8" for 8 vCPU, the smaller tier is "KVM 4" at half the price) |
| Memory | 32 GB | 11 GB | oversized (16 GB tier would work) |
| Disk | 400 GB | 281 GB | appropriate |
| Bandwidth | 32 TB/mo | unknown | probably oversized |

**Potential savings by downsizing:**
- KVM 4 (4 vCPU / 16 GB / 200 GB / 16 TB) → roughly $324/yr vs $648/yr = **$324/yr savings**
- BUT: would risk running out of memory under load (we've seen load 18.9 spikes already)
- AND: migration is non-trivial (would need to move 64 stacks + DB)

**Recommendation:** Stay on KVM 8 for now. Revisit in 6 months after measuring real bandwidth.

---

## What's NOT included in Hostinger (separate billing)

These are NOT on Hostinger and I cannot enumerate their costs from here:

| Service | Vendor | What it does | Likely cost |
|---|---|---|---|
| Cloudflare Pages | Cloudflare | ometzdental.com + other client sites | free tier + Workers paid = ~$5/mo |
| Cloudflare R2 | Cloudflare | backups (ai_backup.sh script) | ~$1-5/mo depending on usage |
| Meta Graph API | Meta | FB/IG posting for clients | $0 (free) |
| LiteLLM proxy | Groq/Hermes | AI inference for agents | ~$10-50/mo |
| WhatsApp Business | evolution-api (self-hosted) | client WhatsApp bots | $0 (self-hosted, but VPS uses cycles) |
| Various LLM APIs (anthropic, openai, etc.) | multiple | AI features | ~$20-100/mo depending on usage |
| GitHub | GitHub | repo hosting | $0 (free tier) or $4/mo (Pro) |

**Total non-Hostinger cost (estimate): $40-160/mo = $480-1920/yr**

Grand total (estimated all-in): **$1,200-2,600/yr** for the entire Ai-Whisperers infrastructure + client platforms.

---

## What's included but not used?

After thorough audit:

| Resource | Status | Evidence |
|---|---|---|
| Disk (119 GB unused after prune) | Available headroom | df shows 106 GB free |
| Memory (20 GB unused) | Available headroom | free shows 19 GB available |
| Bandwidth (probably >90% unused) | Available headroom | can't measure precisely, but 32 TB is huge |
| VPS snapshot/backups | UNKNOWN — Hostinger API doesn't expose | check hPanel |
| VPS firewall (mentioned in AGENTS.md, not visible in API) | UNKNOWN | check hPanel |
| SSL certs (paid wildcard?) | UNKNOWN — Let's Encrypt is free, so probably not | check hPanel |

**Concrete UNUSED items found:** None with certainty from API access alone.

The audit is incomplete because **Hostinger's API doesn't expose many subscription line items**. Items like "VPS backups" (often an add-on), "Premium SSL", "CDN", "Priority Support" — these would only show up in the hPanel subscription list, not the billing API.

---

## Action items to find true "unused" stuff

1. **hPanel → Subscriptions** (browser only) — full list of every line item, including add-ons
2. **hPanel → VPS → Backups** — paid or free?
3. **hPanel → VPS → Snapshots** — paid or free?
4. **hPanel → Emails → Forwarders** — paid or free? (forwarders are often a hidden $0.50/mo fee)
5. **hPanel → Domains → Add-ons** — privacy protection, DNS premium, etc.

The user (you) must do this. I cannot.

---

## Summary table

| Subscription | Cost/yr | Used? | Action |
|---|---|---|---|
| KVM 8 VPS | $647.88 | ✅ heavily | keep |
| sunstein.cloud | $26.19 | ✅ critical | keep |
| ometzdental.com | $20.19 amort | ✅ in use | keep |
| Starter Business Email | $19.08 | ❓ ambiguous | verify in hPanel |
| **TOTAL** | **$713.34** | mostly used | verify email sub |

---

## No waste found from API-accessible data

The Hostinger API returns 4 subscriptions, all in active use (or ambiguous). I found **no "included but not used" items** in the data I can reach.

**However:** I likely can't see all the line items. hPanel will have the full picture. Worth a 5-min browser check to look for add-ons.

---

## Recommendations

1. ✅ **Keep everything that's auto-renewing** — they all serve a purpose
2. 🔍 **Verify Starter Business Email** in hPanel — if no mailboxes exist, cancel it
3. 📅 **VPS auto-renewal is ON** — confirmed in this audit, no action needed
4. 💰 **No immediate cost savings to capture** — KVM 8 is the right size for now
5. 🔄 **Re-run this audit monthly** via `bash /root/.hermes/scripts/hostinger-audit.sh`