#!/usr/bin/env bash
# Paste a secret into /root/.hermes/.env without leaking to chat/truncated output.
# Usage: paste-secret.sh VAR_NAME [description]
set -e
VAR="${1:?usage: paste-secret.sh VAR_NAME [description]}"
DESC="${2:-secret}"
ENV_FILE="/root/.hermes/.env"
if [ ! -f "$ENV_FILE" ]; then
  touch "$ENV_FILE"
  chmod 600 "$ENV_FILE"
fi
read -rs -p "Paste value for $VAR ($DESC): " VAL; echo
if grep -q "^${VAR}=" "$ENV_FILE" 2>/dev/null; then
  sed -i "s|^${VAR}=.*|${VAR}=\"${VAL}\"|" "$ENV_FILE"
  echo "  ✓ $VAR updated in $ENV_FILE"
else
  echo "${VAR}=\"${VAL}\"" >> "$ENV_FILE"
  echo "  ✓ $VAR appended to $ENV_FILE"
fi
chmod 600 "$ENV_FILE"
