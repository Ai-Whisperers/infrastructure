#!/bin/bash
set -euo pipefail

echo "=== hostname / uname ==="
hostname
uname -a

echo
echo "=== Are we in a container? ==="
if [[ -f /.dockerenv ]]; then echo "  /.dockerenv exists (likely Docker container)"; fi
if [[ -f /run/.containerenv ]]; then echo "  /run/.containerenv exists (systemd-nspawn)"; fi
echo "  /proc/1/cgroup (first 3 lines):"
head -3 /proc/1/cgroup 2>/dev/null

echo
echo "=== sshd process ==="
ps -ef | grep -E 'sshd' | grep -v grep | head -5

echo
echo "=== Port 22 LISTEN ==="
cat /proc/net/tcp | awk 'NR>1 && $4=="0A" && $2 ~ /:0016$/ {print "  port 22 LISTEN uid="$8" inode="$10}' || echo "  no LISTEN for :22"

echo
echo "=== sshd_config drop-ins ==="
ls -la /etc/ssh/sshd_config.d/ 2>&1

echo
echo "=== Main sshd_config AuthorizedKeysFile / ListenAddress / Port ==="
grep -iE '^(AuthorizedKeysFile|ListenAddress|Port)' /etc/ssh/sshd_config 2>/dev/null

echo
echo "=== Effective sshd config (sshd -T) — key lines only ==="
sshd -T 2>/dev/null | grep -iE '^(authorizedkeysfile|listenaddress|port|passwordauthentication|maxauthtries|allowusers|permitrootlogin|pubkeyauthentication)' | sort

echo
echo "=== /root/.ssh/ ==="
ls -la /root/.ssh/ 2>&1
echo "  authorized_keys (key fingerprints):"
awk '{print $1, substr($2,1,12)"...", $3}' /root/.ssh/authorized_keys 2>/dev/null

echo
echo "=== /home/*/.ssh/ ==="
for d in /home/*/.ssh; do
    [[ -d "$d" ]] || continue
    user=$(basename $(dirname "$d"))
    echo "  user: $user"
    ls -la "$d" 2>&1 | head -3
    if [[ -f "$d/authorized_keys" ]]; then
        awk '{print "    "$1, substr($2,1,12)"...", $3}' "$d/authorized_keys"
    fi
done

echo
echo "=== Test ssh from this host ==="
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new root@127.0.0.1 'whoami; hostname' 2>&1 | head -3

echo
echo "=== Interfaces ==="
for iface in $(ls /sys/class/net/ | grep -v lo); do
    ip=$(ip -4 addr show $iface 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)
    [[ -n "$ip" ]] && echo "  iface $iface: $ip"
done
