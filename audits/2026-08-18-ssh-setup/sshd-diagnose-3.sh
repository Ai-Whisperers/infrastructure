#!/bin/bash
set +e  # don't exit on errors
echo "=== iptables full ==="
iptables -L -nv 2>&1 | head -50
echo
echo "=== iptables nat ==="
iptables -t nat -L -nv 2>&1 | head -20
echo
echo "=== iptables mangle ==="
iptables -t mangle -L -nv 2>&1 | head -20
echo
echo "=== nftables ruleset ==="
nft list ruleset 2>&1 | head -50
echo
echo "=== ufw ==="
ufw status verbose 2>&1 | head -10
echo
echo "=== fail2ban ==="
fail2ban-client status 2>&1 | head
echo
echo "=== firewall-cmd (firewalld) ==="
firewall-cmd --list-all 2>&1 | head -20
echo
echo "=== ip route ==="
ip route 2>&1
echo
echo "=== test connect from host to 38.9.96.180:22 ==="
timeout 3 bash -c "echo > /dev/tcp/38.9.96.180/22" 2>&1 && echo "  from-host: OPEN" || echo "  from-host: CLOSED"
echo
echo "=== test connect from host to 100.78.180.49:22 ==="
timeout 3 bash -c "echo > /dev/tcp/100.78.180.49/22" 2>&1 && echo "  from-host-tailscale: OPEN" || echo "  from-host-tailscale: CLOSED"
echo
echo "=== ip link show ==="
ip link show
echo
echo "=== /etc/ssh/sshd_config (full) ==="
cat /etc/ssh/sshd_config 2>&1 | head -50
echo
echo "=== /etc/ssh/sshd_config.d/ contents ==="
for f in /etc/ssh/sshd_config.d/*; do
    echo "=== $f ==="
    cat "$f"
done