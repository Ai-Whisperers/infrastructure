#!/bin/bash
# Run this on the host as root
# Verifies what's possible for the .env path

set -e

echo "=== Hermes home on host ==="
ls -la /opt/data/
echo
echo "=== Hermes home is /root/.hermes (bind mount source for agent's /opt/data) ==="
ls -la /root/.hermes/ 2>&1 | head -5
echo
echo "=== Can we write to /opt/data/.hermes/? ==="
mkdir -p /opt/data/.hermes 2>&1
ls -la /opt/data/.hermes/ 2>&1 | head -5
echo
echo "=== Test write to /opt/data/.hermes/.env ==="
test -w /opt/data/.hermes/ && echo "  /opt/data/.hermes is writable" || echo "  /opt/data/.hermes NOT writable"
test -d /opt/data/.hermes && touch /opt/data/.hermes/.env.test 2>&1
ls -la /opt/data/.hermes/.env.test 2>&1 | head -2
echo
echo "=== Also check /root/.hermes/.env (the bind mount source) ==="
test -f /root/.hermes/.env && {
    ls -la /root/.hermes/.env
    echo "  /root/.hermes/.env exists and is the bind mount source"
} || echo "  /root/.hermes/.env doesn't exist"
echo
echo "=== Confirm agent's /opt/data/.env ==="
echo "Agent view of /opt/data/.env:"
ls -la /opt/data/.env 2>&1 | head -3
echo
echo "=== The real path: himalaya on the host reads from /opt/data/.env ==="
echo "  - Container's /opt/data/.env is bind-mounted from /root/.hermes/.env"
echo "  - Both paths refer to the SAME file"
echo "  - Writing to /opt/data/.env (as the agent) updates /root/.hermes/.env (visible to himalaya on host)"