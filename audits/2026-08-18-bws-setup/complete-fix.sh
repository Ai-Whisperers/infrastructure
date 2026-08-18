#!/bin/bash
# Complete VPS diagnostic + fix - runs as root
# Step 1 of 2: diagnostic + install. Step 2 (placeholder creation) runs separately.
set -uo pipefail

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
N='\033[0m'

step() { echo -e "${Y}==>${N} $*"; }
ok()   { echo -e "${G}[ok]${N} $*"; }
fail() { echo -e "${R}[FAIL]${N} $*"; }
sec()  { echo -e "\n${Y}=== $* ===${N}"; }

ORG_ID="1d9b5a44-0c14-41aa-83ae-b4a90136155c"
PROJECT_ID="a1d64864-77f9-4e6a-8d6e-b4a90137189a"

# Find BWS token
TOKEN_FILE=""
for path in /root/.bws-new-token.secret /opt/data/inbox/bws-token.secret /tmp/bws-token.txt; do
    if [[ -f "$path" ]] && [[ -r "$path" ]]; then
        TOKEN_FILE="$path"
        break
    fi
done

if [[ -z "$TOKEN_FILE" ]]; then
    fail "No readable BWS token found"
    exit 1
fi
ok "Using BWS token: $TOKEN_FILE"
echo "    First 12 chars: $(head -c 12 "$TOKEN_FILE")"

sec "0. Sanity"
echo "hostname: $(hostname)"
echo "user: $(whoami) uid=$(id -u)"
echo "kernel: $(uname -r)"

sec "1. SSH hardening"
[[ -f /etc/ssh/sshd_config.d/00-aiw-hardening.conf ]] && ok "00-aiw-hardening.conf exists" || fail "MISSING"
sshd -t 2>&1 && ok "sshd -t passes" || fail "sshd -t FAILS"
step "Effective sshd:"
sshd -T 2>/dev/null | grep -iE '^(maxauthtries|passwordauthentication|pubkeyauthentication|listenaddress|port|allowusers|authorizedkeysfile)' | sort | sed 's/^/    /'

sec "2. Authorized keys"
for p in /root/.ssh/authorized_keys /home/hermes/.ssh/authorized_keys; do
    [[ -f "$p" ]] && echo "    $p ($(stat -c '%a %U:%G' $p), $(wc -l < "$p") keys):" && awk '{print "      " $1, substr($2,1,12)"...", $3}' "$p"
done

sec "3. Network"
echo "Public IP: $(hostname -I | awk '{print $1}')"
step "sshd listeners:"
ss -tlnp 2>/dev/null | grep -E ':22\b'

sec "4. Install bitwarden_sdk"
python3 -c "import bitwarden_sdk" 2>/dev/null && ok "already importable" || {
    step "Downloading wheel from GitHub..."
    WHEEL_URL="https://github.com/bitwarden/sdk-sm/releases/download/python-v2.1.0/bitwarden_sdk-2.1.0-cp313-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
    TMPDIR=$(mktemp -d /tmp/bws_unz.XXXXXX)
    cd "$TMPDIR"
    if curl -fsSL "$WHEEL_URL" -o bws.whl 2>&1; then
        if unzip -q bws.whl 2>&1; then
            LIB=$(find . -maxdepth 1 -name 'bitwarden_sdk' -type d | head -1)
            if [[ -n "$LIB" ]]; then
                echo "BWS_LIB=$LIB" > /tmp/bws_env.sh
                echo "BWS_TOKEN_FILE=$TOKEN_FILE" >> /tmp/bws_env.sh
                echo "BWS_ORG_ID=$ORG_ID" >> /tmp/bws_env.sh
                echo "BWS_PROJ_ID=$PROJECT_ID" >> /tmp/bws_env.sh
                echo "TMPDIR=$TMPDIR" >> /tmp/bws_env.sh
                ok "extracted. env written to /tmp/bws_env.sh"
                ok "lib at: $LIB"
            else
                fail "no bitwarden_sdk dir after unzip"
                exit 1
            fi
        else
            fail "unzip failed"
            exit 1
        fi
    else
        fail "wheel download failed"
        exit 1
    fi
}

sec "5. Summary - run step2 next"
echo "Diagnostic + SDK install complete."
echo
echo "If step 4 succeeded, the env file is at /tmp/bws_env.sh"
echo "Next: source it and run the placeholder creator python (separate command)"
echo
echo "  source /tmp/bws_env.sh"
echo "  python3 /root/.scratch/create_placeholders.py"