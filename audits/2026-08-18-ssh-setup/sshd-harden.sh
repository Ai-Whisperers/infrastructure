#!/bin/bash
# ============================================================
# sshd hardening + key setup — idempotent, run on HOST B as root
# ============================================================
# Run this once. Re-running is safe (idempotent).
#
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/Ai-Whisperers/infrastructure/setup-1787079356/audits/2026-08-18-ssh-setup/sshd-harden.sh" | sudo bash
#   then, separately, if you want agent-side key management:
#   curl -fsSL "https://raw.githubusercontent.com/Ai-Whisperers/infrastructure/setup-1787079356/audits/2026-08-18-ssh-setup/agent-keys-dropin.sh" | sudo bash
# ============================================================

set -euo pipefail

DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN_FILE="${DROPIN_DIR}/00-aiw-hardening.conf"
BACKUP_DIR="/root/sshd-backup-$(date +%Y%m%d-%H%M%S)"
AGENT_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDp1SG5RJLr5YKWhxFMXk8rxQRAn2NjqRVTSp+RCcJ49"
IVAN_LAPTOP_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGE1tx/6cNUAE3Ao0PN+ncZ/k4j6WXFWuL7YwUyopbgu ivan-laptop:hermes-vps 2026-08-17"

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

MaxAuthTries 10
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
AllowUsers hermes root
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

# Make sure /home/hermes exists with proper perms
echo "=== Ensuring /home/hermes exists ==="
if ! getent passwd hermes >/dev/null; then
    echo "WARNING: hermes user does not exist in /etc/passwd" >&2
    echo "  the agent container has its own hermes user; host needs to create one for sshd to allow" >&2
fi
if [[ -d /home/hermes ]]; then
    chown -R hermes:hermes /home/hermes 2>/dev/null || true
    chmod 755 /home/hermes
    mkdir -p /home/hermes/.ssh
    chmod 700 /home/hermes/.ssh
    touch /home/hermes/.ssh/authorized_keys
    chmod 600 /home/hermes/.ssh/authorized_keys

    # Make sure Ivan's laptop key + the agent's own key are both accepted for hermes
    grep -q "ivan-laptop" /home/hermes/.ssh/authorized_keys || \
        echo "$IVAN_LAPTOP_KEY" >> /home/hermes/.ssh/authorized_keys
    grep -q "hermes@host-b" /home/hermes/.ssh/authorized_keys || \
        echo "$AGENT_KEY hermes-agent@host-b // for Tailscale SSH agent->self" >> /home/hermes/.ssh/authorized_keys
    chown -R hermes:hermes /home/hermes/.ssh
    echo "  /home/hermes/.ssh/authorized_keys now contains:"
    cut -d' ' -f1,3- /home/hermes/.ssh/authorized_keys | sed 's/^/    /'
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
sshd -T 2>/dev/null | grep -iE '^(passwordauthentication|maxauthtries|pubkeyauthentication|allowusers|clientalive|maxstartups)' | sort | head

echo
echo "=== Done ==="
echo
echo "Test from your laptop:"
echo "  ssh hermes 'whoami && date'      # should print 'hermes' now"
echo "  ssh root@hermes 'whoami'         # should print 'root'"
echo
echo "From inside the agent container (after this is done):"
echo "  ssh -i /opt/data/.ssh/id_ed25519 hermes@100.78.180.49 'whoami'"
echo
echo "If anything is wrong, restore from backup:"
echo "  cp $BACKUP_DIR/*.conf $DROPIN_DIR/"
echo "  systemctl reload ssh"