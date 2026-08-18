#!/bin/bash
# ============================================================
# sshd-key-recovery.sh — restore all known keys to /opt/data/.ssh/authorized_keys
# ============================================================
# Run this from the HOST as root. The previous agent-keys-dropin.sh may have
# left authorized_keys empty; this script puts ALL known keys back.
#
# Idempotent: re-running is safe (dedupes by key).
# ============================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (try: sudo bash $0)" >&2
    exit 1
fi

AUTH_FILE="/opt/data/.ssh/authorized_keys"

# All known public keys, one per line. Add new keys here as needed.
KNOWN_KEYS=(
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDp1SG5RJLr5YKWhxFMXk8rxQRAn2NjqRVTSp+RCcJ49 hermes-agent@host-b // for agent self-ssh, added 2026-08-18"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+iy4u1u6/Q+brCDfAvKBfOvlZiA1AIEAMUTkHM4zF+ aiw-sandbox-rw // for Host A operator tasks 2026-08-13"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGE1tx/6cNUAE3Ao0PN+ncZ/k4j6WXFWuL7YwUyopbgu ivan-laptop:hermes-vps 2026-08-17"
)

mkdir -p /opt/data/.ssh
chmod 700 /opt/data/.ssh

# Build a deduped file preserving comments
> "$AUTH_FILE"
for entry in "${KNOWN_KEYS[@]}"; do
    read -r keytype keybase comment <<< "$entry"
    keyfp="${keytype} ${keybase}"
    if ! grep -q "^${keyfp}" "$AUTH_FILE" 2>/dev/null; then
        echo "$entry" >> "$AUTH_FILE"
        echo "  added: $keyfp"
    else
        echo "  already present: $keyfp"
    fi
done

chmod 600 "$AUTH_FILE"
chown hermes:hermes "$AUTH_FILE" 2>/dev/null || true

echo
echo "=== Final authorized_keys ==="
cat "$AUTH_FILE"
echo
echo "=== Permissions ==="
stat -c '%a %U:%G %n' "$AUTH_FILE"

echo
echo "=== Validate sshd config ==="
if sshd -t; then
    echo "  sshd config: OK"
else
    echo "  sshd config FAILED"
    exit 1
fi

# Reload
echo
echo "=== Reloading sshd ==="
if systemctl reload ssh 2>/dev/null; then
    echo "  systemctl reload ssh OK"
elif service ssh reload 2>/dev/null; then
    echo "  service ssh reload OK"
else
    SSHD_PID=$(pgrep -o sshd || true)
    [[ -n "$SSHD_PID" ]] && kill -HUP "$SSHD_PID" && echo "  SIGHUP sent to sshd pid=$SSHD_PID"
fi

echo
echo "=== Test from your laptop ==="
echo "  ssh root@hermes 'whoami'        # should print 'root'"
echo "  ssh hermes 'whoami && date'      # should print 'hermes' now"