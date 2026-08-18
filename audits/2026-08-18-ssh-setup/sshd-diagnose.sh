#!/bin/bash
set -euo pipefail

echo "=== hostname / uname ==="
hostname
uname -a

echo
echo "=== Are we in a container? ==="
if [[ -f /.dockerenv ]]; then echo "  /.dockerenv exists (likely Docker container)"; fi
if [[ -f /run/.containerenv ]]; then echo "  /run/.containerenv exists (likely systemd-nspawn)"; fi
cat /proc/1/cgroup 2>/dev/null | head -3

echo
echo "=== sshd process ==="
ps -ef | grep -E 'sshd' | grep -v grep | head -5

echo
echo "=== sshd binary location ==="
which sshd
ls -la /usr/sbin/sshd 2>/dev/null

echo
echo "=== Port 22 LISTEN (with bind address) ==="
cat /proc/net/tcp | awk 'NR>1 && $4=="0A" && $2 ~ /:0016$/ {print "  port 22 LISTEN uid="$8" inode="$10}' || echo "  no LISTEN for :22"

# Try ss if available
ss -tlnp 2>/dev/null | grep -E ':22' || echo "  ss not available or no :22"

echo
echo "=== sshd_config drop-ins ==="
ls -la /etc/ssh/sshd_config.d/

echo
echo "=== Effective sshd config (AuthorizedKeysFile + ListenAddress) ==="
sshd -T 2>/dev/null | grep -iE '^(authorizedkeysfile|listenaddress|port|passwordauthentication|maxauthtries|allowusers|permitrootlogin)' | sort

echo
echo "=== authorized_keys files (per-user) ==="
echo "-- /root/.ssh/authorized_keys --"
ls -la /root/.ssh/authorized_keys 2>&1
cut -d' ' -f1,3 /root/.ssh/authorized_keys 2>/dev/null | head -5
echo
echo "-- /home/*/.ssh/authorized_keys (if any) --"
for d in /home/*/.ssh/authorized_keys; do
    if [[ -f "$d" ]]; then
        echo "  $d exists, keys:"
        cut -d' ' -f1,3 "$d" | head -5
    fi
done

echo
echo "=== ListenAddress in main config ==="
grep -i 'ListenAddress' /etc/ssh/sshd_config 2>/dev/null
grep -ri 'ListenAddress' /etc/ssh/sshd_config.d/ 2>/dev/null

echo
echo "=== Test from this host: ssh root@localhost ==="
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new root@127.0.0.1 'whoami' 2>&1 | head -5

echo
echo "=== Test sshd is binding ==="
# Find which interfaces sshd is bound to
for iface in $(ls /sys/class/net/ | grep -v lo); do
    ip=$(ip -4 addr show $iface 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)
    if [[ -n "$ip" ]]; then
        echo "  iface $iface: $ip"
    fi
done
