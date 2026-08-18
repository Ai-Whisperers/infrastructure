#!/bin/bash
echo "=== Effective sshd config (sshd -T) — key lines ==="
sshd -T 2>/dev/null | grep -iE "^(authorizedkeysfile|listenaddress|port|passwordauthentication|maxauthtries|allowusers|permitrootlogin|pubkeyauthentication)" | sort

echo
echo "=== /root/.ssh/ ==="
ls -la /root/.ssh/
echo "  authorized_keys (line count + key prefixes):"
wc -l /root/.ssh/authorized_keys 2>/dev/null
awk "{print \"    \" \$1, substr(\$2,1,12)\"...\", \$3}" /root/.ssh/authorized_keys 2>/dev/null

echo
echo "=== /home/* users and their .ssh/ ==="
getent passwd | awk -F: "\$3 >= 1000 && \$3 < 65000 {print \$1, \$6, \$7}"
for h in /home/*; do
    [[ -d "$h/.ssh" ]] || continue
    user=$(basename "$h")
    echo "  /home/$user/.ssh/:"
    ls -la "$h/.ssh/" 2>&1 | head -5
    if [[ -f "$h/.ssh/authorized_keys" ]]; then
        awk "{print \"    \" \$1, substr(\$2,1,12)\"...\"}" "$h/.ssh/authorized_keys"
    fi
done

echo
echo "=== Network interfaces ==="
ip -4 addr show | awk "/inet / {print \"  \" \$NF, \$2}"

echo
echo "=== Test ssh localhost ==="
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new root@127.0.0.1 "whoami; hostname" 2>&1 | head -3

echo
echo "=== iptables rules (port 22) ==="
iptables -L -n 2>/dev/null | grep -E "(22|ssh)" | head -10 || echo "  iptables not available or no rules"
