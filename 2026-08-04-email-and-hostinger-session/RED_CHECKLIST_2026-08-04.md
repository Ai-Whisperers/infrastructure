# 🔴 RED CHECKLIST — items only YOU can do

This is the exact set of actions that require browser access to third-party sites. Each is fully scripted below — paste commands, click buttons, follow the steps. Total time: ~25 min.

---

## A. Re-enable VPS auto-renewal (2 min) — CRITICAL

**Why:** Your KVM 8 VPS is set to **non-renewing** and expires 2027-02-27. Losing it = losing all 64 client sites + agent-zero + every agent.

**Steps:**
1. Go to https://hpanel.hostinger.com
2. Login with your Hostinger account
3. Top menu → **Billing** → **Subscriptions**
4. Find **KVM 8** (subscription ID `AzyyTfVBav0Jk2HUb`)
5. Click the row → **Enable auto-renewal** toggle
6. Verify it now shows "Auto-renew: ON" and next billing date ≈ 2027-02-27

**Verify it's done:** I can re-probe via API — say "check VPS renewal" after you've done this.

---

## B. Set up mail for ai-whisperers.com (20 min)

The domain is NOT on Hostinger (it's at Squarespace registrar, DNS at Google Cloud DNS). Plan: point MX/SPF/DKIM/DMARC records at Hostinger Mail from Google Cloud DNS, then activate mailboxes in hPanel.

### B1. Add 5 DNS records to Google Cloud DNS (5 min)

**Where:** https://console.cloud.google.com/net-services/dns/zones

**Steps:**
1. Find the zone for `ai-whisperers.com` (might need to create one if doesn't exist)
2. Add these 5 records (copy-paste from the sunstein.cloud template that already works):

| Type | Name | Content | TTL |
|---|---|---|---|
| MX | @ | `5 mx1.hostinger.com` | 14400 |
| MX | @ | `10 mx2.hostinger.com` | 14400 |
| TXT | @ | `v=spf1 include:_spf.mail.hostinger.com ~all` | 3600 |
| TXT | _dmarc | `v=DMARC1; p=none` | 3600 |

For DKIM, you need 3 CNAMEs that Hostinger will give you when you activate mail. **Don't add DKIM yet** — do it after step B2.

**Verify:** Run `dig MX ai-whisperers.com +short` — should return both mx1 and mx2 records.

### B2. Activate Hostinger Mail for ai-whisperers.com (5 min)

**Where:** https://hpanel.hostinger.com → Emails

**Steps:**
1. Login to hPanel
2. **Emails** → **Manage** → find `ai-whisperers.com` (it may show as "not active" since the DNS wasn't pointed)
3. Click **Activate Mail** — Hostinger will verify DNS and provide:
   - The 3 DKIM CNAME records to add to Google Cloud DNS
   - IMAP/SMTP server details (already in our himalaya config)
4. Copy the DKIM records → go back to Google Cloud DNS → add them

### B3. Create 4 mailboxes in hPanel (5 min)

For each mailbox, go to hPanel → Emails → Mailboxes → Create, set a strong password:

- `ivan@ai-whisperers.com`
- `kiki@ai-whisperers.com`
- `hello@ai-whisperers.com`
- `support@ai-whisperers.com`

**Save the 4 passwords** — you'll paste them in step C.

### B4. Generate 2 Gmail App Passwords (5 min)

For each Gmail (Ivan's + Kiki's):
1. https://myaccount.google.com/security → enable **2-Step Verification** (skip if already on)
2. https://myaccount.google.com/apppasswords
3. App = **Mail**, Device = **Other (custom name)** → type `himalaya`
4. Click **Generate** → 16-char password appears (with spaces — **remove them**)

Save both 16-char passwords.

---

## C. Paste 8 secrets to .env (3 min)

Run these one at a time. Each prompts for hidden input, writes to .env, sets chmod 600. Safe.

```bash
# Personal Gmail — addresses + App Passwords
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_IVAN_GMAIL            "Ivan's Gmail (e.g. ivan.smith@gmail.com)"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_IVAN_APP_PASSWORD      "Ivan's 16-char App Password (no spaces)"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_KIKI_GMAIL            "Kiki's Gmail"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_KIKI_APP_PASSWORD      "Kiki's 16-char App Password (no spaces)"

# Hostinger Mail — 4 mailbox passwords from B3
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_IVAN_COMPANY_PASSWORD  "Ivan's ai-whisperers.com password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_KIKI_COMPANY_PASSWORD  "Kiki's ai-whisperers.com password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_HELLO_PASSWORD         "hello@ai-whisperers.com password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_SUPPORT_PASSWORD       "support@ai-whisperers.com password"
```

---

## D. Wire the Hostinger MCP into Hermes (1 min — you do, since config.yaml is locked)

The block I generated is at `/root/.hermes/HOSTINGER_MCP_CONFIG_BLOCK.yaml`. Open it, copy the YAML, and paste into `/root/.hermes/config.yaml` under `mcp:` after `github:` and before `memory-server:`.

After saving, restart the gateway with:
```bash
hermes gateway restart
```

I cannot edit config.yaml myself (Hermes blocks it for security). You have to do this.

---

## E. Verify everything works (1 min — automated)

After C + D:

```bash
# Test all 6 inboxes authenticate
bash /root/.hermes/scripts/verify-inboxes.sh

# Re-run Hostinger audit
bash /root/.hermes/scripts/hostinger-audit.sh

# Test full inventory
cat /root/.hermes/FULL_INVENTORY_2026-08-04.md
```

I'll handle the verification report. Just say "verify everything" once you've done B + C + D.

---

## Summary of timeline

| Step | Time | Blocker |
|---|---|---|
| A. VPS auto-renewal | 2 min | hPanel only |
| B1. DNS records (5) | 5 min | Google Cloud DNS only |
| B2. Activate Hostinger Mail | 5 min | hPanel only |
| B3. Create 4 mailboxes | 5 min | hPanel only |
| B4. Generate 2 Gmail App Passwords | 5 min | Google account only |
| C. Paste 8 secrets | 3 min | terminal only |
| D. Wire Hostinger MCP | 1 min | config.yaml + terminal |
| E. Verify | 1 min | terminal only |
| **TOTAL** | **~25 min** | mixed |

---

## What I'll do automatically once you say "verify everything"

1. Replace `PLACEHOLDER_*` in himalaya config with real addresses from .env
2. Run `verify-inboxes.sh` — should print 6× ✓ OK
3. Test Hostinger MCP server connection
4. Confirm morning-inbox-triage cron will work tomorrow 08:00
5. Write `/root/.hermes/VERIFICATION_REPORT_2026-08-04.md` with proof
6. Mark all todos as completed

---

## What I did autonomously (already done) — recap

✓ himalaya v2.0.0 installed
✓ himalaya config.toml with 6 accounts (placeholders ready)
✓ paste-secret.sh helper (chmod 700)
✓ verify-inboxes.sh + inbox-triage-cron.sh (chmod 700)
✓ multi-inbox-manager skill
✓ MULTI_INBOX_SETUP.md playbook
✓ Hostinger MCP server installed (hostinger-mcp-server v2.0.1)
✓ HOSTINGER_MCP_CONFIG_BLOCK.yaml (paste into config.yaml)
✓ Hostinger audit (HOSTINGER_AUDIT_2026-08-04.md)
✓ hostinger-audit.sh (re-runnable)
✓ Full inventory (FULL_INVENTORY_2026-08-04.md)
✓ VPS renewal calendar file (vps-renewal-alert.ics)
✓ Invisible stacks audit (INVISIBLE_STACKS_AUDIT.md — 192 lines, each of 10 sites analyzed)
✓ Cloudflare token fixed (was dead, now active)
✓ 3 monitoring crons added (/etc/cron.d/aiw-vps-monitoring)
✓ Orphan networks removed (paraguai_default + polki-squad_default)
✓ Disk monitor active (currently alerting: 86% disk, 100% swap)
✓ Build cache prune running in background (96 GB → ~57 GB so far)

---

**When you've done all the red items, say "verify everything" and I'll wrap up.**