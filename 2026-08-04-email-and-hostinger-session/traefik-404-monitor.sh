#!/usr/bin/env bash
# traefik-404-monitor.sh — alert when traffic hits non-routed subdomains
# Reads traefik access log, counts 404s, surfaces top offenders to Telegram.
# Run hourly via cron.
set -u

LOG_SOURCE=${TRAEFIK_LOG:-/var/lib/docker/containers/$(docker ps --filter "ancestor=traefik" --format "{{.ID}}" | head -1)/$(docker ps --filter "ancestor=traefik" --format "{{.ID}}" | head -1)-json.log}

TELEGRAM_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" /root/.hermes/.env 2>/dev/null | cut -d'"' -f2)
TELEGRAM_CHAT=$(grep "^TELEGRAM_FLEET_ALERT_CHAT=" /root/.hermes/.env 2>/dev/null | cut -d'"' -f2)

AUDIT_LOG=/root/.hermes/logs/traefik-404.jsonl
mkdir -p "$(dirname $AUDIT_LOG)"

if [ ! -f "$LOG_SOURCE" ]; then
  # Try alternative log location
  LOG_SOURCE=$(find /var/lib/docker/containers -name "*-json.log" -newer /tmp/.traefik-marker 2>/dev/null | xargs grep -l "traefik" 2>/dev/null | head -1)
fi

if [ ! -f "$LOG_SOURCE" ]; then
  echo "  ✗ traefik log not found at $LOG_SOURCE"
  echo "    (set TRAEFIK_LOG env var to override)"
  exit 0
fi

# Count 404s in last hour, grouped by host
SINCE_TS=$(date -d "1 hour ago" -u +%Y-%m-%dT%H:%M:%S)
FOUR_OH_FOURS=$(awk -v since="$SINCE_TS" '
  /"RouterName":"(?:http|https)@docker"/ || /404/ {
    if ($0 ~ since) {
      match($0, /"Host":"[^"]*"/);
      if (RSTART) {
        host = substr($0, RSTART+8, RLENGTH-9);
        count[host]++;
      }
    }
  }
  END {
    for (h in count) if (count[h] >= 5) print count[h], h;
  }
' "$LOG_SOURCE" 2>/dev/null | sort -rn | head -10)

TOTAL=$(echo "$FOUR_OH_FOURS" | wc -l)

if [ "$TOTAL" -eq 0 ]; then
  exit 0
fi

# Log
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TOP=$(echo "$FOUR_OH_FOURS" | head -5)
echo "{\"ts\":\"$TS\",\"since\":\"$SINCE_TS\",\"top_404_hosts\":[$(echo "$FOUR_OH_FOURS" | awk '{printf "[\"%s\",%s],", $2, $1}' | sed 's/,$//')]}" >> "$AUDIT_LOG"

# Telegram alert (only if any host has >=10 hits in 1h)
if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT" ]; then
  BIG=$(echo "$FOUR_OH_FOURS" | awk '$1 >= 10' | head -5)
  if [ -n "$BIG" ]; then
    MSG="🚨 Traefik 404s in last hour:
$BIG
→ full list: $AUDIT_LOG
→ may indicate new client stacks without DNS routing"

    curl -sS --max-time 10 -X POST \
      "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT" \
      -d text="$MSG" >/dev/null 2>&1
  fi
fi

exit 0