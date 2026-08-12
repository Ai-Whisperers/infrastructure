#!/usr/bin/env bash
# hostinger-audit.sh — re-runnable audit of Hostinger account state
# Usage: bash /root/.hermes/scripts/hostinger-audit.sh
set -e

TOKEN=$(cat /root/.config/hostinger/token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "  ✗ no token at /root/.config/hostinger/token"
  exit 1
fi

H='Authorization: Bearer '$TOKEN

echo "=== Hostinger account audit — $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo ""

echo "--- domains ---"
curl -sS --max-time 10 -H "$H" https://developers.hostinger.com/api/domains/v1/portfolio \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for d in data:
    print(f'  {d[\"domain\"]:30s} type={d[\"type\"]:15s} status={d[\"status\"]:10s} expires={d.get(\"expires_at\") or \"never\"}')"

echo ""
echo "--- subscriptions ---"
curl -sS --max-time 10 -H "$H" https://developers.hostinger.com/api/billing/v1/subscriptions \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
total = 0
for s in data:
    auto = 'auto' if s['is_auto_renewed'] else 'MANUAL'
    price = s['renewal_price'] / 100
    total += price if s['is_auto_renewed'] else 0
    print(f'  {s[\"name\"]:30s} {auto:6s} \${price:>8.2f}  next={s.get(\"next_billing_at\") or s.get(\"expires_at\",\"-\")}')
print(f'  --- auto-renew total: \${total:.2f}/yr ---')"

echo ""
echo "--- VPS ---"
curl -sS --max-time 10 -H "$H" https://developers.hostinger.com/api/vps/v1/virtual-machines \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data:
    ipv4 = next((i['address'] for i in v.get('ipv4',[])), '-')
    print(f'  {v[\"hostname\"]:35s} {v[\"plan\"]:10s} state={v[\"state\"]:8s} vCPU={v[\"cpus\"]} RAM={v[\"memory\"]}MB disk={v[\"disk\"]}GB ipv4={ipv4}')"

echo ""
echo "--- DNS zones (enumerate domains + records) ---"
DOMAINS=$(curl -sS --max-time 10 -H "$H" https://developers.hostinger.com/api/domains/v1/portfolio \
  | python3 -c "import json,sys; [print(d['domain']) for d in json.load(sys.stdin)]")
for d in $DOMAINS; do
  count=$(curl -sS --max-time 10 -H "$H" "https://developers.hostinger.com/api/dns/v1/zones/$d" \
    | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
  has_mx=$(curl -sS --max-time 10 -H "$H" "https://developers.hostinger.com/api/dns/v1/zones/$d" \
    | python3 -c "import json,sys; print('YES' if any(r['type']=='MX' for r in json.load(sys.stdin)) else 'no')" 2>/dev/null)
  echo "  $d: $count records, MX=$has_mx"
done

echo ""
echo "=== audit complete ==="