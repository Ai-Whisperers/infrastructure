#!/bin/bash
# One-shot: install bitwarden_sdk from wheel + create placeholders.
# Assumes: complete-fix.sh was run earlier, /root/.bws-new-token.secret exists.
# This script does ONLY the wheel install + placeholder creation.

set -uo pipefail

ORG_ID="1d9b5a44-0c14-41aa-83ae-b4a90136155c"
PROJECT_ID="a1d64864-77f9-4e6a-8d6e-b4a90137189a"

# Pick BWS token
TOKEN_FILE=""
for path in /root/.bws-new-token.secret /opt/data/inbox/bws-token.secret /tmp/bws-token.txt; do
    [[ -f "$path" && -r "$path" ]] && TOKEN_FILE="$path" && break
done
[[ -z "$TOKEN_FILE" ]] && { echo "No readable BWS token"; exit 1; }
echo "Using token: $TOKEN_FILE (first 12: $(head -c 12 "$TOKEN_FILE"))"

# Download correct wheel
WHEEL_URL="https://github.com/bitwarden/sdk-sm/releases/download/python-v2.1.0/bitwarden_sdk-2.1.0-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
TMPDIR=$(mktemp -d /tmp/bws_unz.XXXXXX)
cd "$TMPDIR"
echo "Downloading wheel..."
curl -fsSL "$WHEEL_URL" -o bws.whl || { echo "wheel download failed"; exit 1; }
unzip -q bws.whl || { echo "unzip failed"; exit 1; }
LIB=$(find "$TMPDIR" -maxdepth 1 -name 'bitwarden_sdk' -type d | head -1)
[[ -z "$LIB" ]] && { echo "no bitwarden_sdk dir"; exit 1; }
echo "Extracted to: $LIB"
# Make the path absolute
case "$LIB" in
    /*) ;;
    *)  LIB="$TMPDIR/$LIB" ;;
esac
echo "Absolute lib path: $LIB"

# Run placeholder creator with PYTHONPATH
export BWS_TOKEN_FILE="$TOKEN_FILE"
export BWS_ORG_ID="$ORG_ID"
export BWS_PROJ_ID="$PROJECT_ID"
# Handle unbound PYTHONPATH under set -u
if [[ -z "${PYTHONPATH:-}" ]]; then
    export PYTHONPATH="$LIB"
else
    export PYTHONPATH="$LIB:$PYTHONPATH"
fi

python3 /root/.scratch/create_placeholders.py
RC=$?

# Cleanup
cd /
rm -rf "$TMPDIR"

exit $RC