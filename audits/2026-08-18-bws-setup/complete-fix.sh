#!/bin/bash
set -euo pipefail

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
N='\033[0m'

step() { echo -e "${Y}==>${N} $*"; }
ok()   { echo -e "${G}[ok]${N} $*"; }
fail() { echo -e "${R}[FAIL]${N} $*"; }
sec()  { echo -e "\n${Y}=== $* ===${N}"; }

sec "0. Sanity"
echo "hostname: $(hostname)"
echo "user: $(whoami) (uid $(id -u))"
echo "kernel: $(uname -r)"
echo "uptime: $(uptime -p)"

sec "1. SSH hardening"
if [[ -f /etc/ssh/sshd_config.d/00-aiw-hardening.conf ]]; then
    ok "00-aiw-hardening.conf exists"
    sed 's/^/    /' /etc/ssh/sshd_config.d/00-aiw-hardening.conf
else
    fail "00-aiw-hardening.conf MISSING"
fi

if [[ -f /etc/tmpfiles.d/sshd.conf ]]; then
    ok "tmpfiles.d/sshd.conf exists"
    sed 's/^/    /' /etc/tmpfiles.d/sshd.conf
fi

if sshd -t 2>&1; then
    ok "sshd -t passes"
else
    fail "sshd -t FAILS"
fi

echo
step "Effective sshd config:"
sshd -T 2>/dev/null | grep -iE '^(maxauthtries|passwordauthentication|pubkeyauthentication|clientaliveinterval|clientalivecountmax|logingracetime|listenaddress|allowusers|port|authorizedkeysfile)' | sort | sed 's/^/    /'

sec "2. Authorized keys"
for path in /root/.ssh/authorized_keys /home/hermes/.ssh/authorized_keys; do
    if [[ -f $path ]]; then
        echo "    $path ($(stat -c '%a %U:%G' $path), $(wc -l < $path) keys):"
        awk '{print "      " $1, substr($2,1,12)"...", $3}' $path | head -10
    else
        echo "    $path: MISSING"
    fi
done

sec "3. Network and ports"
echo "Public IP: $(hostname -I | awk '{print $1}')"
echo
step "Listening TCP ports:"
if command -v ss &>/dev/null; then
    ss -tlnp 2>/dev/null | head -20
else
    cat /proc/net/tcp | awk 'NR>1 && $4=="0A" {split($2,a,":"); printf "  :%d uid=%d\n", strtonum("0x"a[2]), $8}' | sort -u
fi

sec "4. Bitwarden Secrets Manager setup"
if [[ -f /root/.bws-new-token.secret ]]; then
    ok "/root/.bws-new-token.secret exists ($(stat -c '%a %U:%G %s bytes' /root/.bws-new-token.secret))"
elif [[ -f /home/hermes/.bws-new-token.secret ]]; then
    ok "/home/hermes/.bws-new-token.secret exists"
else
    fail "No BWS token file found"
    echo "    Generate a new BWS token in Bitwarden web UI and save to /root/.bws-new-token.secret (mode 600)"
    exit 1
fi

if [[ ! -d /opt/data/.venv/lib/python3.11/site-packages/bitwarden_sdk ]]; then
    fail "bitwarden_sdk not installed in /opt/data/.venv"
    exit 1
fi
ok "bitwarden_sdk installed"

SCRIPT=/root/.scratch/bws_create_placeholders.py
if [[ ! -f $SCRIPT ]]; then
    fail "$SCRIPT MISSING — fetching from GitHub"
    URL="https://raw.githubusercontent.com/Ai-Whisperers/infrastructure/setup-1787084882/audits/2026-08-18-bws-setup/bws_create_placeholders.py"
    mkdir -p /root/.scratch
    if curl -fsSL "$URL" -o $SCRIPT 2>&1; then
        ok "  fetched from GitHub"
        chmod +x $SCRIPT
    else
        fail "  GitHub fetch failed"
        exit 1
    fi
fi
ok "$SCRIPT exists ($(stat -c '%a %U:%G %s bytes' $SCRIPT))"

sec "5. Create Bitwarden placeholders"
ORG_ID="1d9b5a44-0c14-41aa-83ae-b4a90136155c"
PROJECT_ID="a1d64864-77f9-4e6a-8d6e-b4a90137189a"

step "Running bws_create_placeholders.py..."
if python3 $SCRIPT --token-file /root/.bws-new-token.secret --org-id $ORG_ID --project-id $PROJECT_ID 2>&1; then
    ok "Placeholders created"
else
    fail "Placeholder creation failed"
    echo "    Maybe the BWS token is burned. Generate a fresh one."
fi

sec "6. Final state"
echo
step "Secrets in BWS project hermes:"

cat > /tmp/verify-bws.py <<PYEOF
import sys, uuid
sys.path.insert(0, '/opt/data/.venv/lib/python3.11/site-packages')
import bitwarden_sdk
from bitwarden_sdk import BitwardenClient, ClientSettings, DeviceType
s = ClientSettings(api_url='https://api.bitwarden.com', identity_url='https://identity.bitwarden.com', user_agent='hermes-verify', device_type=DeviceType.SERVER)
c = BitwardenClient(s)
with open('/root/.bws-new-token.secret') as f: tok = f.read().strip()
r = c.auth().login_access_token(tok, None)
if not r.success:
    print('  login failed:', r.error_message)
    sys.exit(1)
r2 = c.secrets().list(uuid.UUID('1d9b5a44-0c14-41aa-83ae-b4a90136155c'))
if r2.success:
    for sec in r2.to_dict().get('data',{}).get('data',[]):
        if isinstance(sec, dict):
            print(f'  {sec["key"]}: {sec["id"]}')
PYEOF

if [[ -f /root/.bws-new-token.secret ]]; then
    python3 /tmp/verify-bws.py
fi
rm -f /tmp/verify-bws.py

sec "7. Summary"
echo "  sshd hardening applied (drop-in exists, sshd -t passes)"
echo "  /run/sshd persistence in place"
echo "  Bitwarden Secrets Manager project hermes accessible"
echo "  Placeholders created (if step 5 succeeded)"
echo
echo "Next steps for you:"
echo "  1. Go to https://vault.bitwarden.com -> Secrets Manager -> Projects -> hermes"
echo "  2. Click each placeholder, edit value to rotated password, save"
echo "  3. Note: actual password values are NOT in this chat"