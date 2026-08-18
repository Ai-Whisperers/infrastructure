#!/bin/bash
# Single-file sshd harden via ssh heredoc — no URL, no @url: wrapping risk
# Run from laptop: ssh root@hermes 'bash -s' < /path/to/this/file

set -euo pipefail

# 1. Ensure /run/sshd exists
mkdir -p /run/sshd
chmod 0755 /run/sshd
chown root:root /run/sshd

# 2. Persist /run/sshd across reboots
cat > /etc/tmpfiles.d/sshd.conf <<EOF_TMPFILES
d /run/sshd 0755 root root -
EOF_TMPFILES
chmod 644 /etc/tmpfiles.d/sshd.conf
systemd-tmpfiles --create 2>/dev/null || true

# 3. Write hardening drop-in (separately from /run/sshd so failures don't cascade)
cat > /etc/ssh/sshd_config.d/00-aiw-hardening.conf <<EOF_HARDEN
MaxAuthTries 10
PasswordAuthentication no
PubkeyAuthentication yes
ClientAliveInterval 30
ClientAliveCountMax 4
LoginGraceTime 30
EOF_HARDEN
chmod 644 /etc/ssh/sshd_config.d/00-aiw-hardening.conf

# 4. Validate
if ! sshd -t; then
    echo "ERROR: sshd -t failed; removing drop-in to restore prior state"
    rm -f /etc/ssh/sshd_config.d/00-aiw-hardening.conf
    exit 1
fi

# 5. Reload
if systemctl reload ssh 2>/dev/null; then
    echo "  systemctl reload ssh OK"
elif service ssh reload 2>/dev/null; then
    echo "  service ssh reload OK"
else
    SSHD_PID=$(pgrep -o sshd || true)
    if [[ -n "$SSHD_PID" ]]; then
        kill -HUP "$SSHD_PID"
        echo "  SIGHUP sent to sshd pid=$SSHD_PID"
    else
        echo "ERROR: could not reload sshd"
        exit 1
    fi
fi

echo
echo "=== Effective config (after reload) ==="
sshd -T 2>/dev/null | grep -iE '^(maxauthtries|passwordauthentication|pubkeyauthentication|clientaliveinterval|clientalivecountmax|logingrace)' | sort

echo
echo "=== Done ==="