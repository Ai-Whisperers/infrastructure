#!/bin/bash
# Quick: verify EMAIL_PASSWORD works + send test email
# Trigger: after Ivan pastes new App Password into /opt/data/.env

set -uo pipefail

echo "=== Verifying EMAIL_PASSWORD in /opt/data/.env ==="
PWLEN=$(grep -E '^EMAIL_PASSWORD=' /opt/data/.env | cut -d= -f2- | tr -d '\n' | wc -c)
echo "  EMAIL_PASSWORD length: $PWLEN (expected 16 for Google App Password)"
if [[ $PWLEN -ne 16 ]]; then
    echo "  ERROR: App Password should be 16 chars. Did you paste it correctly?"
    echo "  (no spaces, just 16 letters like 'abcd efgh ijkl mnop' or 'abcdefghijklmnop')"
    exit 1
fi

echo
echo "=== Testing Gmail IMAP connection via himalaya ==="
himalaya mailbox list 2>&1 | head -20

echo
echo "=== Sending test email to weissvanderpol.ivan@gmail.com ==="
cat <<'EOF' | himalaya message send --account ivan -
From: Ivan Weiss Van Der Pol <weissvanderpol.ivan@gmail.com>
To: weissvanderpol.ivan@gmail.com
Subject: Hermes test - $(date +%Y-%m-%dT%H:%M)
Date: $(date -R)

This is a test email sent via himalaya + Google App Password, server-side
credential flow. The App Password value never transited chat, state.db,
agent.log, or the LLM provider's request log.

If you received this, Gmail auth + SMTP send both work.

— sent by AI agent on Ivan's behalf
EOF

RC=$?
echo
echo "=== Send result: $RC ==="
if [[ $RC -eq 0 ]]; then
    echo "  Email sent successfully"
else
    echo "  Send failed - check himalaya output above"
fi