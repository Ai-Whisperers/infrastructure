#!/usr/bin/env bash
# verify-inboxes.sh — check all 6 accounts authenticate cleanly
# Run after secrets are pasted. Outputs ✓/✗ per account.
set -u

ACCOUNTS="ivan-personal kiki-personal ivan-company kiki-company hello-shared support-shared"
PASS=0
FAIL=0

echo "=== Multi-Inbox Verification ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Load .env so auth.cmd shell-outs can read secrets
if [ -f /root/.hermes/.env ]; then
  set -a
  . /root/.hermes/.env
  set +a
else
  echo "  ✗ /root/.hermes/.env not found — run paste-secret.sh first"
  exit 1
fi

for acct in $ACCOUNTS; do
  echo -n "  $acct: "
  if himalaya --account "$acct" folder list >/dev/null 2>&1; then
    folder_count=$(himalaya --account "$acct" folder list 2>/dev/null | grep -c '│' || echo 0)
    echo "✓ OK ($folder_count folders visible)"
    PASS=$((PASS+1))
  else
    err=$(himalaya --account "$acct" folder list 2>&1 | tail -1)
    echo "✗ FAIL — $err"
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo "=== Result: $PASS passed, $FAIL failed ==="

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "Troubleshooting:"
  echo "  1. Verify env vars: grep -E '^HIMALAYA_' /root/.hermes/.env"
  echo "  2. For Gmail accounts: check 2FA enabled + App Password generated"
  echo "  3. For Hostinger accounts: check mailbox created in hPanel + DNS MX records propagated"
  echo "  4. Re-paste any missing secret: bash /root/.hermes/scripts/paste-secret.sh VAR_NAME"
  exit 1
fi
exit 0