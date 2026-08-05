#!/usr/bin/env bash
# vps-disk-monitor.sh — alert when disk > 85% or swap > 90%
# Runs every 6 hours via cron. Sends alert to Telegram if thresholds breached.
# No LLM, no agent — pure shell + curl, ~$0.00/run.
set -u

THRESHOLD_DISK=85
THRESHOLD_SWAP=90
LOG=/root/.hermes/logs/disk-monitor.jsonl
TELEGRAM_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" /root/.hermes/.env 2>/dev/null | cut -d'"' -f2 | cut -d'=' -f2)
TELEGRAM_CHAT=$(grep "^TELEGRAM_DISK_ALERT_CHAT=" /root/.hermes/.env 2>/dev/null | cut -d'"' -f2 | cut -d'=' -f2)

mkdir -p "$(dirname $LOG)"

# Read current state
DISK_PCT=$(df / --output=pcent 2>/dev/null | tail -1 | tr -dc '0-9')
SWAP_PCT=$(free | awk '/Swap/ {if ($2>0) printf "%.0f", $3/$2*100; else print "0"}')
MEM_AVAIL=$(free -g | awk '/Mem/ {print $7}')
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
STATUS="ok"
ALERTS=""

if [ "${DISK_PCT:-0}" -gt "$THRESHOLD_DISK" ]; then
  STATUS="alert"
  ALERTS="$ALERTS 🔴 Disk ${DISK_PCT}% > ${THRESHOLD_DISK}% threshold\n"
fi

if [ "${SWAP_PCT:-0}" -gt "$THRESHOLD_SWAP" ]; then
  STATUS="alert"
  ALERTS="$ALERTS 🔴 Swap ${SWAP_PCT}% > ${THRESHOLD_SWAP}% threshold\n"
fi

# Log every run
echo "{\"ts\":\"$TS\",\"disk_pct\":${DISK_PCT:-0},\"swap_pct\":${SWAP_PCT:-0},\"mem_avail_gb\":${MEM_AVAIL:-0},\"load_1m\":${LOAD:-0},\"status\":\"$STATUS\"}" >> "$LOG"

# Only send Telegram if alert
if [ "$STATUS" = "alert" ] && [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_CHAT" ]; then
  MSG="⚠️ VPS Resource Alert ($TS)
$(echo -e "$ALERTS")
disk: ${DISK_PCT}%
swap: ${SWAP_PCT}%
mem avail: ${MEM_AVAIL} GB
load (1m): ${LOAD}

→ /root/.hermes/logs/disk-monitor.jsonl for history
→ run 'docker system df' to find reclaimable space"

  curl -sS --max-time 10 -X POST \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT" \
    -d text="$MSG" \
    -d parse_mode=HTML >/dev/null 2>&1
fi

exit 0