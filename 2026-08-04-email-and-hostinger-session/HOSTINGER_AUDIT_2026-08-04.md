# Hostinger Account Audit — 2026-08-04

**Source:** Hostinger API (token: `En3UNhLWIpGb5hboP74GJVN1FyRxqsYEpIfifvf74b8482c7`, regenerated today)

---

## TL;DR — What you actually have on Hostinger

| Asset | Count | Status |
|---|---|---|
| **Domains** | 2 unique (`sunstein.cloud`, `ometzdental.com`) | both active |
| **Active subscriptions** | 4 | 3 auto-renewing, 1 non-renewing |
| **VPS servers** | 1 (KVM 8, 8 CPU / 32 GB / 400 GB) | running |
| **AI-Whisperers domain?** | ❌ **NOT in this account** | registered elsewhere |
| **Live mailboxes** | 0 (mailboxes are managed inside VPS/hosting plans, not via this API) | — |

**Big finding:** `ai-whisperers.com` is **NOT** on this Hostinger account. It's registered at **Squarespace Domains LLC**, DNS delegated to **Google Cloud DNS**. You cannot manage its mail via this Hostinger API — you'd need Squarespace access for domain settings, or you can wire the mail via Hostinger *Mail for any domain* pointing MX records at Hostinger from any DNS provider (which is what we set up in the multi-inbox plan).

---

## 1. Domains (3 entries, 2 unique)

| ID | Domain | Type | Status | Registered | Expires |
|---|---|---|---|---|---|
| 29033603 | `sunstein.cloud` | free_domain | active | 2026-02-18 | never (free) |
| 29047386 | `sunstein.cloud` | domain | active | 2026-02-19 | 2027-02-19 |
| 32382634 | `ometzdental.com` | domain | active | 2026-06-29 | 2029-06-29 |

Two `sunstein.cloud` entries are normal — one is the free domain that came with the VPS, the other is a paid registration. `ometzdental.com` is the Ometz Dental client site.

### `ai-whisperers.com` is missing from this list

Confirmed via `whois`: registered with **Squarespace Domains LLC**, not Hostinger. You own it, but not through this Hostinger account. Two paths:
- **(a) Transfer ai-whisperers.com to Hostinger** (~5 days for transfer, $0 usually; squarespace → hostinger registrar transfer)
- **(b) Keep at Squarespace, point MX/SPF/DKIM/DMARC records to Hostinger's mail servers from Google Cloud DNS** (no transfer; what the current multi-inbox plan does)

**(b) is faster.** (a) gives unified management.

## 2. DNS zones

### `sunstein.cloud` (15 records)

**Mail records (already set up — this is the reference template for ai-whisperers.com):**

| Type | Name | Content |
|---|---|---|
| MX | @ | `5 mx1.hostinger.com` / `10 mx2.hostinger.com` |
| TXT | @ | `v=spf1 include:_spf.mail.hostinger.com ~all` |
| TXT | _dmarc | `v=DMARC1; p=none` |
| CNAME | hostingermail-a._domainkey | `hostingermail-a.dkim.mail.hostinger.com` |
| CNAME | hostingermail-b._domainkey | `hostingermail-b.dkim.mail.hostinger.com` |
| CNAME | hostingermail-c._domainkey | `hostingermail-c.dkim.mail.hostinger.com` |
| CNAME | autoconfig | `autoconfig.mail.hostinger.com` |
| CNAME | autodiscover | `autodiscover.mail.hostinger.com` |

**Infra subdomains (all → 72.61.44.159):**
- `openclaw`, `agent`, `portainer`, `traefik`, `*` (wildcard)

`www` → `sunstein.cloud` (CNAME)

### `ometzdental.com` (1 record only)

| Type | Name | Content |
|---|---|---|
| A | @ | `72.61.44.159` |

No MX, no mail records. **No email set up here.**

### `ai-whisperers.com` — **not in this account**, no records visible

## 3. Subscriptions (4 active)

| ID | Product | Status | Price (¢) | Renews |
|---|---|---|---|---|
| AzyyTfVBav0Jk2HUb | KVM 8 (VPS) | **non_renewing** | $647.88/yr | 2027-02-27 (manual) |
| 16BUgJVD1RS7w2nCl | Starter Business Email | active (auto) | $19.08/yr | 2027-02-19 |
| 16CHS6VNt7aCn6uWq | .COM Domain (ometzdental) | active (auto) | $60.57/3yr | 2029-06-02 |
| 6oZlvVBdblETCde | .CLOUD Domain (sunstein) | active (auto) | $26.19/yr | 2027-01-23 |

**Heads up:**
- The VPS is marked `non_renewing` — meaning it will **expire 2027-02-27** unless you re-enable auto-renew. That's your primary infrastructure. Don't lose it.
- **Starter Business Email** is active but attached to which domain? Could be `sunstein.cloud` (most likely — that's the domain that's been around since VPS setup). It needs to be confirmed and/or migrated if you want `ai-whisperers.com` mail.

## 4. VPS (1 server)

| Field | Value |
|---|---|
| ID | 1396188 |
| Hostname | `srv1396188.hstgr.cloud` |
| Plan | KVM 8 |
| State | **running** |
| vCPUs | 8 |
| Memory | 32 GB |
| Disk | 400 GB |
| Bandwidth | 32 TB/mo |
| IPv4 | `72.61.44.159` (matches AGENTS.md — confirmed) |
| IPv6 | `2a02:4780:66:42fb::1` |
| Template | Ubuntu 24.04 with Docker |
| DC | data_center_id 14 |
| Created | 2026-02-18 |

This is the server hosting agent-zero, litellm, traefik, portainer, ollama, evolution-api, redis, postgres, grafana, prometheus, qdrant, vaultwarden — per AGENTS.md.

## 5. Mail — what I could NOT enumerate via API

The Hostinger public API does **not** expose:
- Mailbox list (which mailboxes exist, their addresses)
- Mailbox quotas
- Email forwarding rules
- Active IMAP/SMTP sessions
- Email history/storage usage

For mailboxes, the canonical source is the **hPanel web UI** (https://hpanel.hostinger.com → Emails). The public API is mostly for domain/DNS/VPS management.

This means: **to answer "do I have any existing mailboxes?" I need to either** (a) log into hPanel in a browser, or (b) infer from DNS records (which mailboxes are configured to receive). For `sunstein.cloud`, the mail DNS records exist (MX, SPF, DKIM, DMARC, autoconfig, autodiscover) — so **at least one mailbox** is likely configured. For `ometzdental.com`, **no mail is set up**. For `ai-whisperers.com`, **not on this account**.

## 6. What this changes in our setup plan

### Before this audit (assumption)
- "ai-whisperers.com is on Hostinger → activate Hostinger Mail"
- "All 6 mailboxes are new"

### After this audit (verified)
- **ai-whisperers.com is NOT on Hostinger** → to get Hostinger Mail for it, we add the MX/SPF/DKIM/DMARC records to Google Cloud DNS (where the domain's NS points), pointing at Hostinger's mail servers. No transfer needed.
- **Existing Hostinger Mail sub on `sunstein.cloud`** (Starter Business Email, $19.08/yr, renews Feb 2027) — this might be where your current work email lives. Worth checking in hPanel.
- **`ometzdental.com` has no email set up** — if Gaby needs an email there, we'd add it (probably on a separate Hostinger Mail sub, ~$19/yr per the Starter plan).
- **VPS renews manually in Feb 2027** — flag this on your calendar, don't lose it.

## 7. Recommendations

| Priority | Action |
|---|---|
| **HIGH** | Calendar reminder: VPS manual renewal Feb 2027 |
| **HIGH** | Log into hPanel → confirm what `sunstein.cloud` mailboxes exist |
| **MED** | Decide: keep `ai-whisperers.com` at Squarespace, or transfer to Hostinger (1 wk for unified management) |
| **MED** | Decide: add Hostinger Mail for `ometzdental.com` ($19/yr), or use a free alternative |
| **LOW** | Once mailboxes exist anywhere on Hostinger, the official Hostinger MCP server (`hostinger/api-mcp-server`) can be wired in for programmatic DNS updates |

## 8. Updated plan for "set up email for ai-whisperers.com"

**Old plan:** Activate Hostinger Mail in hPanel for ai-whisperers.com (impossible — domain not here)

**New plan:**
1. Add 5 DNS records to Google Cloud DNS for ai-whisperers.com (MX×2, SPF, DKIM×3, DMARC) using **Hostinger's standard mail records** (the same template as sunstein.cloud)
2. Activate Hostinger Mail in hPanel — Hostinger will accept the domain because the DNS records now point at its mail servers
3. Create the 4 mailboxes (ivan@, kiki@, hello@, support@)
4. Paste secrets to .env via paste-secret.sh
5. Run verify-inboxes.sh

**Time:** ~20 min (5 min DNS records, 5 min hPanel activation, 10 min secret paste × 8)

---

## 9. Audit script (reusable)

```bash
TOKEN=$(cat /root/.config/hostinger/token)
echo "=== domains ==="
curl -sS -H "Authorization: Bearer $TOKEN" https://developers.hostinger.com/api/domains/v1/portfolio | python3 -m json.tool
echo "=== subscriptions ==="
curl -sS -H "Authorization: Bearer $TOKEN" https://developers.hostinger.com/api/billing/v1/subscriptions | python3 -m json.tool
echo "=== VPS ==="
curl -sS -H "Authorization: Bearer $TOKEN" https://developers.hostinger.com/api/vps/v1/virtual-machines | python3 -m json.tool
echo "=== DNS for sunstein.cloud ==="
curl -sS -H "Authorization: Bearer $TOKEN" https://developers.hostinger.com/api/dns/v1/zones/sunstein.cloud | python3 -m json.tool
```

Run this monthly to catch new domains/subscriptions before they auto-renew.