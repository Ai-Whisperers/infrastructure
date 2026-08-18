#!/bin/bash
# ============================================================
# AuthorizedKeysFile override — points sshd at the agent-managed file
# ============================================================
# Run this AFTER sshd-harden.sh on Host B as root.
# Optional but recommended: lets the hermes-agent container manage
# authorized_keys without you needing to ssh/noVNC every time.
#
# What it does:
#   - Adds /etc/ssh/sshd_config.d/01-agent-keys.conf
#     with AuthorizedKeysFile /opt/data/.ssh/authorized_keys
#   - Reloads sshd
#
# Idempotent.
# ============================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (try: sudo bash $0)" >&2
    exit 1
fi

DROPIN="/etc/ssh/sshd_config.d/01-agent-keys.conf"

echo "=== Writing $DROPIN ==="
cat > "$DROPIN" <<'EOF'
# A.I.W. — point sshd at agent-managed authorized_keys
# Generated 2026-08-18 by agent-keys-dropin.sh
# This file lives at /opt/data/.ssh/authorized_keys (the agent's bind-mount).
# The hermes-agent container can append/remove keys here without needing
# noVNC or external SSH.
AuthorizedKeysFile /opt/data/.ssh/authorized_keys
EOF

chmod 644 "$DROPIN"
echo "wrote: $(wc -l < "$DROPIN") lines"

# Ensure /run/sshd exists (some hosts drop it; sshd -t fails without it)
if [[ ! -d /run/sshd ]]; then
    mkdir -p /run/sshd
    chmod 0755 /run/sshd
    chown root:root /run/sshd
    echo "  created /run/sshd (was missing)"
fi

# Validate
echo "=== Validating with sshd -t ==="
if ! sshd -t; then
    rm -f "$DROPIN"
    echo "ERROR: sshd -t failed. Removed drop-in." >&2
    exit 1
fi

# Make sure /opt/data/.ssh/authorized_keys exists with sane perms
mkdir -p /opt/data/.ssh
chmod 700 /opt/data/.ssh
if [[ ! -f /opt/data/.ssh/authorized_keys ]]; then
    touch /opt/data/.ssh/authorized_keys
    chmod 600 /opt/data/.ssh/authorized_keys
    echo "created /opt/data/.ssh/authorized_keys (empty)"
else
    chmod 600 /opt/data/.ssh/authorized_keys
    echo "/opt/data/.ssh/authorized_keys exists ($(wc -l < /opt/data/.ssh/authorized_keys) lines, mode 600)"
fi

# Reload
echo "=== Reloading sshd ==="
if systemctl reload ssh 2>/dev/null; then
    echo "  systemctl reload ssh OK"
elif systemctl reload sshd 2>/dev/null; then
    echo "  systemctl reload sshd OK"
elif service ssh reload 2>/dev/null; then
    echo "  service ssh reload OK"
else
    SSHD_PID=$(pgrep -o sshd || true)
    if [[ -n "$SSHD_PID" ]]; then
        kill -HUP "$SSHD_PID"
        echo "  SIGHUP sent to sshd pid=$SSHD_PID"
    fi
fi

# Verify
echo "=== Verifying ==="
sshd -T 2>/dev/null | grep -i 'authorizedkeysfile'

echo
echo "=== Done ==="
echo
echo "Test from your laptop (as the right user):"
echo "  ssh hermes 'whoami && date'   # now reads from /opt/data/.ssh/authorized_keys"
echo
echo "From the agent container:"
echo "  ssh -i /opt/data/.ssh/id_ed25519 hermes@100.78.180.49 'whoami'"
echo
echo "The agent can now append keys by:"
echo "  echo '<pubkey>' >> /opt/data/.ssh/authorized_keys"
echo "  chmod 600 /opt/data/.ssh/authorized_keys"
echo
echo "To undo:"
echo "  rm $DROPIN && systemctl reload ssh"