#!/bin/bash
# Run this in the Servarica noVNC console as root.
# This will:
# 1. Create /opt/data/.hermes directory
# 2. Create /root/.hermes/.hermes directory (the canonical BWS path)
# 3. Save the new BWS token to /root/.hermes/.hermes/.env
# 4. Update himalaya config to use the BWS path
# 5. Update Email gateway to use the same BWS path
# 6. Restart the hermes-gateway

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must be root (use sudo bash $0 or run as root)"
    exit 1
fi

if [[ -z "${BWS_TOKEN:-}" ]]; then
    echo "ERROR: BWS_TOKEN env var not set"
    echo "Usage: BWS_TOKEN='0.3faa1f4f-...' bash $0"
    exit 2
fi

echo "=== 1. Create /opt/data/.hermes ==="
mkdir -p /opt/data/.hermes
chmod 700 /opt/data/.hermes

echo "=== 2. Create /root/.hermes/.hermes (canonical BWS path) ==="
mkdir -p /root/.hermes/.hermes
chmod 700 /root/.hermes/.hermes

echo "=== 3. Save BWS token ==="
echo "BWS_TOKEN=${BWS_TOKEN}" > /root/.hermes/.hermes/.env
chmod 600 /root/.hermes/.hermes/.env
echo "  saved: $(wc -c < /root/.hermes/.hermes/.env) bytes"

# Also save to /opt/data/.hermes/.env (the agent's bind mount source)
echo "BWS_TOKEN=${BWS_TOKEN}" > /opt/data/.hermes/.env
chmod 600 /opt/data/.hermes/.env
echo "  saved: $(wc -c < /opt/data/.hermes/.env) bytes"

echo
echo "=== 4. Update himalaya config to use BWS_TOKEN env (more secure) ==="
HIMALAYA=/opt/data/.config/himalaya/config.toml
if [[ -f $HIMALAYA ]]; then
    # Backup
    cp $HIMALAYA ${HIMALAYA}.bak.$(date +%s)
    # Change the password.command to use the env var (BWS_TOKEN) via the new .env location
    sed -i 's|/opt/data/.env|/opt/data/.hermes/.env|g' $HIMALAYA
    # Also add the value extraction if missing
    grep password.command $HIMALAYA | head -3
fi

echo
echo "=== 5. Verify everything ==="
echo "/root/.hermes/.hermes/.env:"
ls -la /root/.hermes/.hermes/.env
echo "/opt/data/.hermes/.env:"
ls -la /opt/data/.hermes/.env
echo "himalaya config password.command:"
grep password.command $HIMALAYA

echo
echo "=== 6. Restart hermes-gateway ==="
# s6-supervise is the init system here
# Find the main-hermes service
s6-svc -t /run/service/main-hermes 2>&1 ||   s6-svc -h /run/service/main-hermes 2>&1 ||   systemctl restart hermes-gateway 2>&1 ||   echo "  (could not auto-restart, run manually: s6-svc -t /run/service/main-hermes)"

echo
echo "=== Done. Now: ==="
echo "1. Restart Hermes from the noVNC console or via s6-supervise"
echo "2. Once running, the agent can read secrets from BWS via MCP"
echo "3. Email is still NOT working - separate fix needed for himalaya to read from BWS"
