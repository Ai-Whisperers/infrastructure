#!/bin/bash
# Fix himalaya config to read from /root/.hermes/.env (bind mount source)
# Then write EMAIL_PASSWORD to /opt/data/.env (which is the bind mount source)
# This way himalaya reads the password from the canonical location

set -e

# 1. Update himalaya config - replace /opt/data/.env with /root/.hermes/.env in password.command
CONFIG="/opt/data/.config/himalaya/config.toml"
if [[ -f "$CONFIG" ]]; then
    sed -i 's|/opt/data/.env|/root/.hermes/.env|g' "$CONFIG"
    echo "Updated himalaya config:"
    grep "password.command" "$CONFIG"
fi

# 2. Write EMAIL_PASSWORD to /opt/data/.env (bind mount source = /root/.hermes/.env)
# Replace empty EMAIL_PASSWORD line with the new value
# Wait - user hasn't pasted the new app password yet
# So we just verify the line is editable

grep "EMAIL_PASSWORD=" /opt/data/.env | head -2
