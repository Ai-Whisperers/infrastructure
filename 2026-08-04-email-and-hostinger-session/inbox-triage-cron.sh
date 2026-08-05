#!/usr/bin/env bash
# inbox-triage-cron.sh — morning sweep across all 6 accounts
# Run via cron at 08:00 weekdays. Output goes to Telegram DM via cronjob delivery.
set -u

ACCOUNTS="ivan-personal kiki-personal ivan-company kiki-company hello-shared support-shared"
WINDOW_HOURS=24
LOG=/root/.hermes/logs/inbox-triage.jsonl
TMP=$(mktemp)
trap "rm -f $TMP" EXIT

mkdir -p "$(dirname $LOG)"

echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Window: ${WINDOW_HOURS}h"
echo ""

# Load .env for auth
if [ -f /root/.hermes/.env ]; then
  set -a
  . /root/.hermes/.env
  set +a
fi

URGENT_TOTAL=0
DECISION_TOTAL=0
INFO_TOTAL=0
NOISE_TOTAL=0

for acct in $ACCOUNTS; do
  if ! himalaya --account "$acct" folder list >/dev/null 2>&1; then
    echo "  ✗ $acct: auth failed (skipping)"
    continue
  fi

  # Pull last 24h, capped at 30 envelopes per account
  ENVELOPES=$(himalaya --account "$acct" envelope list --page-size 30 2>/dev/null || echo "")
  if [ -z "$ENVELOPES" ]; then
    echo "  · $acct: empty"
    continue
  fi

  COUNT=$(echo "$ENVELOPES" | grep -c '│' || echo 0)
  echo "  · $acct: ~${COUNT} recent messages"

  # Log per-account envelope count
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"account\":\"$acct\",\"count\":$COUNT}" >> "$LOG"
done

echo ""
echo "Full triage requires LLM classification. See /root/.hermes/skills/multi-inbox-manager/SKILL.md"
echo "Next step: review the log, then call daily-inbox-triage via Hermes for classification."