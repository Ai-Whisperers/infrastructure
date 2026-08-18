#!/bin/bash
# One-shot: extract bitwarden_sdk wheel + create placeholders.
# Keeps the wheel extracted in /tmp (re-extracts if missing) but DOES NOT clean up.
# Uses cd to ensure PYTHONPATH relative paths work.

set -uo pipefail

ORG_ID="1d9b5a44-0c14-41aa-83ae-b4a90136155c"
PROJECT_ID="a1d64864-77f9-4e6a-8d6e-b4a90137189a"

# Pick BWS token
TOKEN_FILE=""
for path in /root/.bws-new-token.secret /opt/data/inbox/bws-token.secret /tmp/bws-token.txt; do
    [[ -f "$path" && -r "$path" ]] && TOKEN_FILE="$path" && break
done
[[ -z "$TOKEN_FILE" ]] && { echo "No readable BWS token"; exit 1; }
echo "Using token: $TOKEN_FILE (first12: $(head -c 12 "$TOKEN_FILE"))"

# Persistent lib location
LIB="/root/.scratch/bws_lib"
mkdir -p "$LIB"

# Re-extract if not present
if [[ ! -d "$LIB/bitwarden_sdk" ]] || [[ ! -f "$LIB/bitwarden_sdk/__init__.py" ]]; then
    echo "Extracting wheel to $LIB..."
    WHEEL_URL="https://github.com/bitwarden/sdk-sm/releases/download/python-v2.1.0/bitwarden_sdk-2.1.0-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
    cd /tmp
    rm -rf wheel_extract
    mkdir wheel_extract
    cd wheel_extract
    curl -fsSL "$WHEEL_URL" -o bws.whl || { echo "wheel download failed"; exit 1; }
    unzip -q bws.whl || { echo "unzip failed"; exit 1; }
    # Clean target dir then copy properly
    rm -rf "$LIB"/*
    cp -rL bitwarden_sdk "$LIB/" || { echo "cp bitwarden_sdk failed"; exit 1; }
    cp -rL bitwarden_py "$LIB/" || { echo "cp bitwarden_py failed"; exit 1; }
    [[ -d bitwarden_sdk-2.1.0.dist-info ]] && cp -rL bitwarden_sdk-2.1.0.dist-info "$LIB/" || true
    cd /
    rm -rf /tmp/wheel_extract
    echo "Extracted to $LIB:"
    ls "$LIB/"
else
    echo "Reusing existing lib at $LIB"
fi

echo
echo "Verifying bitwarden_sdk importable..."
python3 -c "import sys; sys.path.insert(0, '$LIB'); import bitwarden_sdk; print('OK:', bitwarden_sdk.__file__)" || {
    echo "Import failed"
    ls -la "$LIB/"
    exit 1
}

# Run placeholder creator
export BWS_TOKEN_FILE="$TOKEN_FILE"
export BWS_ORG_ID="$ORG_ID"
export BWS_PROJ_ID="$PROJECT_ID"
export BWS_LIB="$LIB"

python3 /root/.scratch/create_placeholders.py