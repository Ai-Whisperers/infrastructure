#!/bin/bash
# ============================================================
# sshd hardening — idempotent, run on HOST B as root
# ============================================================
# Pasted by Ivan in chat; requires root on the host that owns sshd
# (NOT inside the hermes-agent container).
#
# Usage:
#   sudo bash /tmp/sshd-harden.sh
# or:
#   bash /tmp/sshd-harden.sh   (if already root)
#
# What it does:
#   1. Backs up any existing sshd_config.d drop-ins to /root/sshd-backup-<date>/
#   2. Writes /etc/ssh/sshd_config.d/00-aiw-hardening.conf with:
#        - MaxAuthTries 10
#        - PasswordAuthentication no
#        - PubkeyAuthentication yes
#        - AllowUsers hermes
#        - ClientAliveInterval 30
#        - ClientAliveCountMax 4
#   3. Validates config with `sshd -t`
#   4. Reloads sshd (SIGHUP — no dropped connections)
#   5. Verifies the running sshd picked up the new config
#
# Re-running is safe: the file is overwritten with the same content.
# ============================================================

set -euo pipefail

DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN_FILE="${DROPIN_DIR}/00-aiw-hardening.conf"
BACKUP_DIR="/root/sshd-backup-$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (try: sudo bash $0)" >&2
    exit 1
fi

mkdir -p "$DROPIN_DIR"
mkdir -p "$BACKUP_DIR"

# Back up existing drop-ins
echo "=== Backing up existing drop-ins to $BACKUP_DIR ==="
if ls "$DROPIN_DIR"/*.conf 2>/dev/null | head -1 | grep -q .; then
    cp -a "$DROPIN_DIR"/*.conf "$BACKUP_DIR/" 2>/dev/null || true
fi

# Write the hardening drop-in
echo "=== Writing $DROPIN_FILE ==="
cat > "$DROPIN_FILE" <<'EOF'
# A.I.W. hardening drop-in
# Generated 2026-08-18 by sshd-harden.sh
# See /root/sshd-backup-*/ for pre-hardening state.

MaxAuthTries 10
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
AllowUsers hermes
ClientAliveInterval 30
ClientAliveCountMax 4
LoginGraceTime 30
MaxStartups 30:60:100
EOF

chmod 644 "$DROPIN_FILE"
echo "wrote: $(wc -l < "$DROPIN_FILE") lines"

# Validate
echo "=== Validating with sshd -t ==="
if ! sshd -t; then
    echo "ERROR: sshd -t failed. Restoring backup..." >&2
    cp -a "$BACKUP_DIR"/*.conf "$DROPIN_DIR/" 2>/dev/null || true
    exit 1
fi

# Reload (SIGHUP — no dropped connections)
echo "=== Reloading sshd ==="
if systemctl reload ssh 2>/dev/null; then
    echo "  systemctl reload ssh OK"
elif systemctl reload sshd 2>/dev/null; then
    echo "  systemctl reload sshd OK"
elif service ssh reload 2>/dev/null; then
    echo "  service ssh reload OK"
else
    # Last resort: kill -HUP the master sshd
    SSHD_PID=$(pgrep -o sshd || true)
    if [[ -n "$SSHD_PID" ]]; then
        kill -HUP "$SSHD_PID"
        echo "  SIGHUP sent to sshd pid=$SSHD_PID"
    else
        echo "WARNING: could not reload sshd automatically. Run: sudo systemctl reload ssh" >&2
    fi
fi

# Verify
echo "=== Verifying effective config ==="
sleep 1
sshd -T 2>/dev/null | grep -iE '^(passwordauthentication|maxauthtries|pubkeyauthentication|allowusers|clientalive)' | head

echo
echo "=== Done ==="
echo "From your laptop, test passwordless login:"
echo "  ssh -v hermes 'whoami && date'"
echo
echo "If anything is wrong, restore from backup:"
echo "  cp $BACKUP_DIR/*.conf $DROPIN_DIR/"
echo "  systemctl reload ssh"