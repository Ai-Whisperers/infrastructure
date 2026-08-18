#!/bin/bash
# One-shot: install bitwarden_sdk from wheel + create placeholders.
# - Downloads the prebuilt wheel
# - Extracts to /root/.scratch/bws_lib/ (persistent, not /tmp)
# - Sets PYTHONPATH and runs the python placeholder creator
# - Does NOT delete the lib dir (so subsequent runs work)

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

LIB="/root/.scratch/bws_lib"
mkdir -p /root/.scratch

# Skip download if already extracted
if [[ ! -d "$LIB/bitwarden_sdk" ]]; then
    WHEEL_URL="https://github.com/bitwarden/sdk-sm/releases/download/python-v2.1.0/bitwarden_sdk-2.1.0-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
    TMPDIR=$(mktemp -d /tmp/bws_wheel.XXXXXX)
    cd "$TMPDIR"
    echo "Downloading wheel..."
    curl -fsSL "$WHEEL_URL" -o bws.whl || { echo "wheel download failed"; exit 1; }
    unzip -q bws.whl || { echo "unzip failed"; exit 1; }
    # Copy to persistent lib location
    cp -r "$TMPDIR/bitwarden_sdk" "$LIB/" || { echo "copy failed"; exit 1; }
    if [[ -d "$TMPDIR/bitwarden_sdk-2.1.0.dist-info" ]]; then
        cp -r "$TMPDIR/bitwarden_sdk-2.1.0.dist-info" "$LIB/"
    fi
    cd /
    rm -rf "$TMPDIR"
    echo "Extracted to persistent: $LIB/bitwarden_sdk"
else
    echo "Using existing lib at $LIB/bitwarden_sdk"
fi

# Verify import works
echo
echo "Verifying bitwarden_sdk importable..."
PYTHONPATH="$LIB" python3 -c "import bitwarden_sdk; print('OK:', bitwarden_sdk.__file__)" || {
    echo "Import failed even with PYTHONPATH=$LIB"
    echo "Contents of $LIB:"
    ls -la "$LIB"/
    exit 1
}

# Run placeholder creator
export BWS_TOKEN_FILE="$TOKEN_FILE"
export BWS_ORG_ID="$ORG_ID"
export BWS_PROJ_ID="$PROJECT_ID"
export BWS_LIB="$LIB"

python3 /root/.scratch/create_placeholders.py
RC=$?

# Do NOT delete LIB - keep it for subsequent runs
exit $RC