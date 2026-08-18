#!/bin/bash
# ============================================================
# sshd preflight: diagnose why sshd -t fails with "Missing /run/sshd"
# ============================================================
# Run this from the host as root BEFORE running sshd-harden.sh:
#   curl -fsSL "https://raw.githubusercontent.com/Ai-Whisperers/infrastructure/BRANCH/audits/2026-08-18-ssh-setup/sshd-preflight.sh" | sudo bash
#
# This script:
#   1. Reports why sshd -t is failing
#   2. Creates /run/sshd if missing (with correct perms)
#   3. Ensures /run/sshd persists across reboots (systemd-tmpfiles or manual)
#   4. Re-runs sshd -t to confirm
# ============================================================

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must run as root (try: sudo bash $0)" >&2
    exit 1
fi

echo "=== sshd binary check ==="
which sshd
sshd -V 2>&1 | head -2

echo
echo "=== /run/sshd check ==="
if [[ -d /run/sshd ]]; then
    echo "  /run/sshd EXISTS"
    ls -la /run/sshd
    stat -c '%a %U:%G' /run/sshd
else
    echo "  /run/sshd MISSING (this is the bug sshd -t is complaining about)"
fi

echo
echo "=== Other privilege-separation dirs sshd may want ==="
for d in /run/sshd /var/run/sshd /var/empty/sshd /var/empty; do
    if [[ -d "$d" ]]; then
        echo "  $d EXISTS ($(stat -c '%a %U:%G' "$d"))"
    fi
done

echo
echo "=== sshd config test ==="
sshd -t 2>&1 | head -5 || true

echo
echo "=== sshd Privilege separation setting (effective) ==="
sshd -T 2>/dev/null | grep -i privsep || true

echo
echo "=== FIXING: creating /run/sshd ==="
mkdir -p /run/sshd
chmod 0755 /run/sshd
# /run/sshd should be owned by root, not sshd
chown root:root /run/sshd
echo "  created /run/sshd, mode 0755, owner root:root"

echo
echo "=== Re-validate ==="
if sshd -t 2>&1; then
    echo "  sshd -t OK now"
else
    echo "  sshd -t STILL FAILS, see error above"
    exit 1
fi

echo
echo "=== Make /run/sshd persistent across reboots ==="
# Modern systemd uses tmpfiles.d; create one if missing
TMPFILES=/etc/tmpfiles.d/sshd.conf
if [[ ! -f "$TMPFILES" ]]; then
    cat > "$TMPFILES" <<EOF
# sshd privilege separation directory
# Created by sshd-preflight.sh on $(date -I)
d /run/sshd 0755 root root -
EOF
    chmod 644 "$TMPFILES"
    echo "  wrote $TMPFILES"
    if command -v systemd-tmpfiles >/dev/null 2>&1; then
        systemd-tmpfiles --create
        echo "  systemd-tmpfiles --create OK"
    fi
else
    echo "  $TMPFILES already exists"
    cat "$TMPFILES"
fi

# OpenRC / SysV init fallback (alpine, devuan, etc.)
if command -v rc-update >/dev/null 2>&1; then
    echo "  detected OpenRC — /run/sshd will be created on sshd start"
fi

echo
echo "=== Re-run sshd-harden.sh now ==="
echo "curl -fsSL \"https://raw.githubusercontent.com/Ai-Whisperers/infrastructure/BRANCH/audits/2026-08-18-ssh-setup/sshd-harden.sh\" | sudo bash"
