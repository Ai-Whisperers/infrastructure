# Multi-Inbox Setup — Ivan, Kiki, Ai-Whisperers

**Decision (2026-08-04):** Hostinger Mail (free) for ai-whisperers.com + Gmail App Passwords for personal inboxes. Single tool: `himalaya` CLI for all 6 accounts. No per-user cost.

---

## Status

- [x] Decision made (Hostinger Mail + Gmail App Passwords)
- [x] `/root/.hermes/scripts/paste-secret.sh` created (chmod 700)
- [x] `/root/.config/himalaya/config.toml` template written (6 accounts, placeholder auth)
- [x] Existing Google OAuth token probed — **DEAD** (malformed, needs re-auth). Layer 3 deferred; not needed for email.
- [x] Token file permission hardened: chmod 644 → 600
- [ ] `himalaya` CLI installed (needs `npm install -g himalaya` or curl install — your call)
- [ ] MX/SPF/DKIM/DMARC records added to DNS (Hostinger hPanel → copy records → paste into Google Cloud DNS)
- [ ] `ivan@`, `kiki@`, `hello@`, `support@` mailboxes created in hPanel
- [ ] App Passwords generated (2 personal Gmail + 4 Hostinger)
- [ ] Secrets pasted to `.env` via `paste-secret.sh`
- [ ] `himalaya folder list --account <name>` verified for all 6
- [ ] Cron job wired (daily-inbox-triage at 08:00 weekdays)
- [ ] Telegram DM delivery verified

---

## What's blocking

Three things only **you** can do, because they require either (a) browser access to a third-party site, or (b) a secret only you know.

### BLOCKER 1 — Activate Hostinger Mail on ai-whisperers.com

**Where:** https://hpanel.hostinger.com → Emails → Mailboxes → Create

**Steps:**
1. Log in to hPanel with the Hostinger account that owns ai-whisperers.com (the domain is registered at Squarespace but DNS is delegated to Hostinger's servers, so it should appear in hPanel)
2. Emails → Manage → Create new mailbox
3. Create **four** mailboxes (passwords are independent):
   - `ivan@ai-whisperers.com`
   - `kiki@ai-whisperers.com`
   - `hello@ai-whisperers.com`
   - `support@ai-whisperers.com`
4. For each, set a strong password (16+ chars, save in your password manager — you'll paste them to Hermes via `paste-secret.sh`)
5. Note the IMAP/SMTP settings hPanel shows (should match what we wrote in config.toml):
   - IMAP: `imap.hostinger.com:993` (TLS)
   - SMTP: `smtp.hostinger.com:465` (SSL/TLS) — *not 587*

**Time:** ~5 min

### BLOCKER 2 — Add MX + SPF + DKIM + DMARC records to DNS

**Where:** DNS for ai-whisperers.com — currently on Google Cloud DNS (NS: ns-cloud-b[1-4].googledomains.com)

**Steps:**
1. hPanel → Emails → Manage → click your domain → **DNS Records** section. It will show you the exact MX/SPF/DKIM records Hostinger expects (Hostinger-specific values, not generic).
2. Open Google Cloud DNS: https://console.cloud.google.com/net-services/dns/zones
3. Find the zone for ai-whisperers.com
4. Add each record Hostinger showed you. Typical pattern:
   - `MX  @  mx1.hostinger.com  10`
   - `MX  @  mx2.hostinger.com  20`
   - `TXT @ "v=spf1 include:_spf.hostinger.com ~all"`
   - `TXT default._domainkey "v=DKIM1; k=rsa; p=..."` (Hostinger shows the exact value)
   - `TXT _dmarc "v=DMARC1; p=none; rua=mailto:hello@ai-whisperers.com"`
5. Wait 5–30 min for propagation. Verify with: `dig MX ai-whisperers.com +short`

**Time:** ~10 min (mostly copy-paste)

### BLOCKER 3 — Generate 2 Gmail App Passwords

**Where:** https://myaccount.google.com/apppasswords

**Steps for each Gmail account (Ivan's and Kiki's):**
1. Sign in to the Gmail account
2. Enable 2FA first if not already: https://myaccount.google.com/security → 2-Step Verification
3. Go to App Passwords (only visible after 2FA is on)
4. App: **Mail**, Device: **Other (custom name)** → type `himalaya`
5. Click Generate → 16-char password appears (with spaces in the UI — remove them when pasting)
6. Repeat for the other Gmail account

**Time:** ~5 min

---

## After you finish the 3 blockers: paste these 6 secrets

Run these one at a time. The script prompts with hidden input and writes to `/root/.hermes/.env` (chmod 600). No leak to chat logs.

```bash
# Personal Gmail App Passwords (16 chars, NO spaces)
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_IVAN_GMAIL      "Ivan's full Gmail address (e.g. ivan.smith@gmail.com)"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_IVAN_APP_PASSWORD  "Ivan's 16-char Gmail App Password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_KIKI_GMAIL      "Kiki's full Gmail address"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_KIKI_APP_PASSWORD  "Kiki's 16-char Gmail App Password"

# Company mailboxes (Hostinger, the passwords you set in hPanel)
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_IVAN_COMPANY_PASSWORD  "Ivan's ai-whisperers.com password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_KIKI_COMPANY_PASSWORD  "Kiki's ai-whisperers.com password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_HELLO_PASSWORD         "hello@ai-whisperers.com password"
bash /root/.hermes/scripts/paste-secret.sh HIMALAYA_SUPPORT_PASSWORD      "support@ai-whisperers.com password"
```

After all 8 are in, I'll run:
1. **Sanitize** — replace `PLACEHOLDER_*` in `~/.config/himalaya/config.toml` with the actual addresses from .env
2. **Verify** — `himalaya folder list --account <each>` should return folder list
3. **Smoke test** — `himalaya envelope list --account hello-shared --page-size 1` should return at least an empty list (no error)
4. **Wire cron** — `daily-inbox-triage` at 08:00 weekdays, Telegram DM
5. **Document** — `/root/.hermes/MULTI_INBOX_VERIFICATION.md` with proof of each account working

---

## What's already done

| Step | Status |
|---|---|
| Researched best free email host (Hostinger Mail) | ✅ |
| Audited DNS (Google Cloud DNS via Squarespace registrar) | ✅ |
| Audited existing config (paste-secret helper, himalaya config template) | ✅ |
| Probed existing Google OAuth token — **DEAD, discarded** | ✅ |
| Hardened `~/.hermes/google_token.json` chmod 600 | ✅ |
| Designed 6-account himalaya config (2 personal Gmail + 4 company) | ✅ |
| Designed `daily-inbox-triage` cron with VIP/keyword escalation | ✅ (documented in this file) |

---

## What I'll do **immediately after** you paste all secrets

1. Patch `~/.config/himalaya/config.toml` to replace placeholders with real addresses from .env
2. Run `himalaya folder list` for each account
3. Install `daily-inbox-triage` cron (08:00 weekdays, Telegram DM)
4. Create `multi-inbox-manager` skill in `~/.hermes/skills/`
5. Write `/root/.hermes/MULTI_INBOX_VERIFICATION.md` with proof
6. Update `OMETZ_SETUP_GUIDE.md` to mark Layer 2 (Himalaya) as DONE

---

## Optional — only if you want it

- **Read-only mode for personal Gmail:** you can disable SMTP on those accounts by commenting out the `message.send.backend` blocks. Hermes will still read, search, draft — just not send. Send from a Gmail via Telegram approval gate instead.
- **Forwarding bridge:** have `hello@` auto-forward to `support@` so one triaging agent handles both. Configure in hPanel → Mailbox → Forwarding.
- **Telegram per-account channels:** route each mailbox summary to a different Telegram topic (Ivan's Gmail → topic 1, Kiki's → topic 2, shared → topic 3).