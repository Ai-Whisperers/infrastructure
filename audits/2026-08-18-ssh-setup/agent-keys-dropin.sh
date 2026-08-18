#!/bin/bash
# ============================================================
# AuthorizedKeysFile override — CORRECTED VERSION
# ============================================================
# v1 (broken): set AuthorizedKeysFile /opt/data/.ssh/authorized_keys
#   This FAILED because /opt/data in this container is actually
#   the host's /root/.hermes. The host's sshd reads its own /opt/data,
#   which is a different directory.
#
# v2 (this): set AuthorizedKeysFile to BOTH the default AND /opt/data/.ssh/authorized_keys
#   sshd allows multiple AuthorizedKeysFile paths; tries each in order.
#   So the host's defaults still work AND the agent can append to its own file.
#
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/Ai-Whisperers/infrastructure/BRANCH/audits/2026-08-18-ssh-setup/agent-keys-dropin.sh" | sudo bash
# ============================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (try: sudo bash $0)" >&2
    exit 1
fi

DROPIN="/etc/ssh/sshd_config.d/01-agent-keys.conf"

echo "=== Writing $DROPIN (v2: include defaults) ==="
cat > "$DROPIN" <<'EOF'
# A.I.W. — point sshd at agent-managed authorized_keys IN ADDITION to defaults
# Generated 2026-08-18 by agent-keys-dropin.sh v2
#
# sshd tries each path in order; first match wins. So the host defaults
# (/root/.ssh/authorized_keys and /home/<user>/.ssh/authorized_keys) keep working,
# AND we can append to /opt/data/.ssh/authorized_keys from the agent container.
#
# NOTE: /opt/data in the agent container is actually the host's /root/.hermes
# (bind-mounted). So this file lives at host's /root/.hermes/.ssh/authorized_keys.
# The agent's writes land there.
AuthorizedKeysFile /root/.ssh/authorized_keys /home/%u/.ssh/authorized_keys /opt/data/.ssh/authorized_keys
EOF

chmod 644 "$DROPIN"
echo "wrote: $(wc -l < "$DROPIN") lines"

# Validate
if ! sshd -t; then
    rm -f "$DROPIN"
    echo "ERROR: sshd -t failed. Removed drop-in." >&2
    exit 1
fi
echo "  sshd -t OK"

# Make sure the agent-side file exists with sane perms
mkdir -p /opt/data/.ssh
chmod 700 /opt/data/.ssh
if [[ ! -f /opt/data/.ssh/authorized_keys ]]; then
    touch /opt/data/.ssh/authorized_keys
fi
chmod 600 /opt/data/.ssh/authorized_keys
chown hermes:hermes /opt/data/.ssh /opt/data/.ssh/authorized_keys 2>/dev/null || true

# Reload
echo "=== Reloading sshd ==="
if systemctl reload ssh 2>/dev/null; then
    echo "  systemctl reload ssh OK"
elif service ssh reload 2>/dev/null; then
    echo "  service ssh reload OK"
else
    SSHD_PID=$(pgrep -o sshd || true)
    [[ -n "$SSHD_PID" ]] && kill -HUP "$SSHD_PID" && echo "  SIGHUP sent"
fi

# Verify
echo "=== AuthorizedKeysFile effective ==="
sshd -T 2>/dev/null | grep -i authorizedkeysfile

echo
echo "=== Done ==="
echo "From your laptop:"
echo "  ssh root@hermes 'whoami && date'   # uses /root/.ssh/authorized_keys"
echo "  ssh hermes 'whoami && date'        # uses /home/hermes/.ssh/authorized_keys"
echo
echo "From the agent container (self-SSH):"
echo "  ssh -i /opt/data/.ssh/id_ed25519 hermes@100.78.180.49 'whoami'"
echo
echo "Agent can append keys (now works):"
echo "  echo '<pubkey>' >> /opt/data/.ssh/authorized_keys"
echo "  chmod 600 /opt/data/.ssh/authorized_keys"
echo
echo "To undo: rm $DROPIN && systemctl reload ssh"
