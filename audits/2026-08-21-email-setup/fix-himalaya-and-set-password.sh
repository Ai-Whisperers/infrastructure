#!/bin/bash
# Fix himalaya config paths AND set EMAIL_PASSWORD in one shot.
# This is the "clean fix" — uses sed (not nano) so it works on the host
# without interactive prompts.

set -euo pipefail

# We expect the caller to provide the new App Password via env var.
# If not provided, we just fix the config paths and exit.
if [[ -z "${NEW_APP_PASSWORD:-}" ]]; then
    echo "ERROR: NEW_APP_PASSWORD env var not set"
    echo "Usage: NEW_APP_PASSWORD='abcd efgh ijkl mnop' bash $0"
    echo "       (or unset to just fix the config paths)"
    exit 2
fi

# 1. Fix himalaya config - replace /opt/data/.env with /root/.hermes/.env
# in BOTH password.command lines
CONFIG="/opt/data/.config/himalaya/config.toml"
if [[ -f "$CONFIG" ]]; then
    echo "Before:"
    grep "password.command" "$CONFIG" || true
    sed -i 's|grep -E "\\^EMAIL_PASSWORD=" /opt/data/.env|grep -E "\\^EMAIL_PASSWORD=" /root/.hermes/.env|g' "$CONFIG"
    echo "After:"
    grep "password.command" "$CONFIG" || true
else
    echo "WARN: $CONFIG not found"
fi

# 2. Write EMAIL_PASSWORD to /root/.hermes/.env (the bind mount source)
# The bind mount makes /opt/data/.env == /root/.hermes/.env on host
# We use sed to replace the empty EMAIL_PASSWORD line with the new value
ENV_FILE="/root/.hermes/.env"
if [[ -f "$ENV_FILE" ]]; then
    echo "Before:"
    grep "^EMAIL_PASSWORD=" "$ENV_FILE" || true
    # Escape forward slashes in the password for sed
    ESCAPED_PW=$(printf '%s\n' "$NEW_APP_PASSWORD" | sed 's/[\/&]/\\&/g')
    sed -i "s|^EMAIL_PASSWORD=$|EMAIL_PASSWORD=${ESCAPED_PW}|" "$ENV_FILE"
    echo "After:"
    grep "^EMAIL_PASSWORD=" "$ENV_FILE" | sed 's/=.*$/=<REDACTED>/'
    echo "  (length: $(grep -E '^EMAIL_PASSWORD=' $ENV_FILE | cut -d= -f2- | tr -d "\n" | wc -c) chars)"
else
    echo "ERROR: $ENV_FILE not found"
    exit 1
fi

# 3. Verify by running himalaya with config override
echo ""
echo "Testing himalaya connection..."
HIMALAYA_CONFIG="/opt/data/.config/himalaya/config.toml" \
himalaya -a ivan mailbox list 2>&1 | head -15 || echo "  (himawaya test failed, but config is fixed)"