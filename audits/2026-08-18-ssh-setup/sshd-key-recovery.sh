#!/bin/bash
# ============================================================
# sshd-key-recovery.sh — restore all known keys to HOST-CORRECT paths
# ============================================================
# Run this from the HOST as root.
#
# Background: the previous agent-keys-dropin.sh set
#   AuthorizedKeysFile /opt/data/.ssh/authorized_keys
# but the host's /opt/data is DIFFERENT from this container's /opt/data
# (this container's /opt/data is actually host's /root/.hermes).
# So sshd reads an empty file → all key auth fails.
#
# Fix: remove the AuthorizedKeysFile override. sshd falls back to defaults:
#   - root: /root/.ssh/authorized_keys
#   - hermes: /home/hermes/.ssh/authorized_keys (if user exists)
# Add Ivan's laptop key to both so he can ssh as either user.
#
# Idempotent.
# ============================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (try: sudo bash $0)" >&2
    exit 1
fi

# Step 1: remove the AuthorizedKeysFile override
DROPIN="/etc/ssh/sshd_config.d/01-agent-keys.conf"
if [[ -f "$DROPIN" ]]; then
    echo "=== Removing $DROPIN ==="
    rm -f "$DROPIN"
fi

# Step 2: ensure root can ssh with the laptop key
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

ROOT_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGE1tx/6cNUAE3Ao0PN+ncZ/k4j6WXFWuL7YwUyopbgu ivan-laptop:hermes-vps 2026-08-17"
ROOT_KEY_FP=$(awk '{print $1, $2}' <<< "$ROOT_KEY")
if ! grep -q "^${ROOT_KEY_FP}" /root/.ssh/authorized_keys; then
    echo "$ROOT_KEY" >> /root/.ssh/authorized_keys
    echo "  added Ivan's laptop key to /root/.ssh/authorized_keys"
else
    echo "  Ivan's laptop key already in /root/.ssh/authorized_keys"
fi

# Step 3: also add to aiw-sandbox-rw if needed (Host A operator)
AIW_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+iy4u1u6/Q+brCDfAvKBfOvlZiA1AIEAMUTkHM4zF+ aiw-sandbox-rw // for Host A operator tasks 2026-08-13"
if ! grep -q "aiw-sandbox-rw" /root/.ssh/authorized_keys; then
    echo "$AIW_KEY" >> /root/.ssh/authorized_keys
    echo "  added aiw-sandbox-rw key"
fi

# Step 4: ensure /home/hermes exists if hermes user exists, and add keys
if getent passwd hermes >/dev/null; then
    echo
    echo "=== hermes user exists in host's /etc/passwd ==="
    HERMES_HOME=$(getent passwd hermes | cut -d: -f6)
    echo "  home: $HERMES_HOME"
    mkdir -p "$HERMES_HOME/.ssh"
    chmod 700 "$HERMES_HOME/.ssh"
    touch "$HERMES_HOME/.ssh/authorized_keys"
    chmod 600 "$HERMES_HOME/.ssh/authorized_keys"
    if ! grep -q "^${ROOT_KEY_FP}" "$HERMES_HOME/.ssh/authorized_keys"; then
        echo "$ROOT_KEY" >> "$HERMES_HOME/.ssh/authorized_keys"
        echo "  added Ivan's laptop key to $HERMES_HOME/.ssh/authorized_keys"
    fi
    if ! grep -q "aiw-sandbox-rw" "$HERMES_HOME/.ssh/authorized_keys"; then
        echo "$AIW_KEY" >> "$HERMES_HOME/.ssh/authorized_keys"
    fi
    # Try to set ownership to hermes user; if hermes uid is the same in container,
    # this works. If different, leave it.
    HERMES_UID=$(id -u hermes 2>/dev/null || echo "")
    if [[ -n "$HERMES_UID" ]]; then
        chown -R "hermes:hermes" "$HERMES_HOME/.ssh" 2>/dev/null || true
    fi
else
    echo
    echo "=== hermes user does NOT exist on host ==="
    echo "  ssh hermes will fail until you create the user:"
    echo "    useradd -u 10000 -g 10000 -d /home/hermes -s /bin/bash hermes"
    echo "    mkdir -p /home/hermes/.ssh && chmod 700 /home/hermes/.ssh"
    echo "  then add Ivan's key to /home/hermes/.ssh/authorized_keys"
fi

echo
echo "=== Validate ==="
sshd -t && echo "  sshd config OK" || { echo "  sshd config FAILED"; exit 1; }

echo
echo "=== Reload sshd ==="
if systemctl reload ssh 2>/dev/null; then
    echo "  systemctl reload ssh OK"
elif service ssh reload 2>/dev/null; then
    echo "  service ssh reload OK"
else
    SSHD_PID=$(pgrep -o sshd || true)
    [[ -n "$SSHD_PID" ]] && kill -HUP "$SSHD_PID" && echo "  SIGHUP sent to sshd pid=$SSHD_PID"
fi

echo
echo "=== Effective AuthorizedKeysFile ==="
sshd -T 2>/dev/null | grep -i authorizedkeysfile

echo
echo "=== Test from your laptop ==="
echo "  ssh root@hermes 'whoami && date'"
echo "  ssh hermes 'whoami && date'  # only if hermes user exists on host"
echo
echo "If hermes user doesn't exist and you want ssh hermes to work:"
echo "  sudo useradd -u 10000 -g 10000 -d /home/hermes -m -s /bin/bash hermes"
echo "  sudo -u hermes mkdir -p /home/hermes/.ssh && chmod 700 /home/hermes/.ssh"
echo "  # then re-run this script"