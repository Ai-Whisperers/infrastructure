#!/usr/bin/env python3
"""Gmail inbox sync via Bitwarden Secrets Manager.

Reads the Gmail App Password from BWS directly (never via agent context).
Uses IMAP to fetch unread messages.
Prints counts and metadata ONLY - never prints the credential.

Usage:
  export BWS_TOKEN='<machine-account-access-token>'
  export GMAIL_USER='ai.whisperer.wvdp@gmail.com'
  export BWS_SECRET_UUID='2c293f26-a229-47f0-a13f-b4aa0159d75a'
  python3 gmail_sync.py

Or as root via systemd / cron, with BWS_TOKEN in /root/.bws-env.
"""
import os
import sys
import imaplib
import email
from email.header import decode_header
from datetime import datetime
from pathlib import Path

# Locate bitwarden_sdk automatically
# Common locations:
#   - /root/.scratch/bws_lib (set up by install-and-create.sh)
#   - /opt/data/.venv/lib/python3.11/site-packages (agent container)
BWS_LIB_CANDIDATES = [
    '/root/.scratch/bws_lib',
    '/opt/data/.venv/lib/python3.11/site-packages',
]
for candidate in BWS_LIB_CANDIDATES:
    if os.path.isdir(os.path.join(candidate, 'bitwarden_sdk')):
        sys.path.insert(0, candidate)
        break
else:
    # Fallback: also try the env var if set
    if os.environ.get('BWS_LIB') and os.path.isdir(os.path.join(os.environ['BWS_LIB'], 'bitwarden_sdk')):
        sys.path.insert(0, os.environ['BWS_LIB'])

try:
    import bitwarden_sdk
except ImportError:
    print('err: bitwarden_sdk not found. Tried:', BWS_LIB_CANDIDATES, file=sys.stderr)
    print('err: set BWS_LIB env var to the path containing bitwarden_sdk/', file=sys.stderr)
    sys.exit(2)

from bitwarden_sdk import BitwardenClient, ClientSettings, DeviceType


def log(msg):
    print('[{}] {}'.format(datetime.now().isoformat(timespec='seconds'), msg))


def main():
    bws_token = os.environ.get('BWS_TOKEN')
    secret_uuid = os.environ.get('BWS_SECRET_UUID')
    gmail_user = os.environ.get('GMAIL_USER')
    if not (bws_token and secret_uuid and gmail_user):
        print('err: BWS_TOKEN, BWS_SECRET_UUID, GMAIL_USER must all be set', file=sys.stderr)
        sys.exit(2)

    log('connecting to Bitwarden...')
    client = BitwardenClient(ClientSettings(
        api_url='https://api.bitwarden.com',
        identity_url='https://identity.bitwarden.com',
        user_agent='hermes-gmail-sync',
        device_type=DeviceType.SERVER,
    ))
    login = client.auth().login_access_token(bws_token, None)
    if not login.success:
        print('err: BWS login failed: {}'.format(login.error_message), file=sys.stderr)
        sys.exit(1)
    log('BWS authenticated')

    log('fetching secret...')
    r = client.secrets().get(secret_uuid)
    if not r.success:
        print('err: secret fetch failed: {}'.format(r.error_message), file=sys.stderr)
        sys.exit(1)
    data = r.to_dict()['data']
    secret_key = data['key']
    secret_value = data['value'].strip()  # App Password; do not print or log this
    secret_len = len(secret_value)
    log('fetched secret key="{}" (value length: {} chars)'.format(secret_key, secret_len))

    # Build IMAP connection
    log('connecting to imap.gmail.com:993...')
    try:
        imap = imaplib.IMAP4_SSL('imap.gmail.com', 993, timeout=30)
    except Exception as e:
        print('err: IMAP connect failed: {}'.format(e), file=sys.stderr)
        sys.exit(1)

    # Authenticate using the App Password
    # IMPORTANT: secret_value is passed directly to imap.login; it is not logged.
    try:
        imap.login(gmail_user, secret_value)
    except imaplib.IMAP4.error as e:
        print('err: IMAP auth failed (check if App Password is valid and IMAP is enabled): {}'.format(e), file=sys.stderr)
        sys.exit(1)
    log('IMAP authenticated as {}'.format(gmail_user))

    # Fetch unread
    imap.select('INBOX')
    status, data = imap.search(None, 'UNSEEN')
    if status != 'OK':
        print('err: search failed: {}'.format(status), file=sys.stderr)
        imap.logout()
        sys.exit(1)

    msg_nums = data[0].split() if data[0] else []
    unread_count = len(msg_nums)
    log('inbox: {} unread'.format(unread_count))

    # Fetch latest5 unread message headers (subject + from + date only, no body)
    if unread_count > 0:
        log('latest unread messages:')
        latest = msg_nums[-5:]
        for num in reversed(latest):
            status, msg_data = imap.fetch(num, '(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT DATE)])')
            if status != 'OK':
                continue
            raw = msg_data[0][1].decode('utf-8', errors='replace') if msg_data[0] else ''
            # Parse headers manually to avoid full email parsing overhead
            headers = email.message_from_string('From: x\r\nSubject: x\r\nDate: x\r\n\r\n' + raw)
            from_ = decode_header(headers.get('From', ''))
            subject = decode_header(headers.get('Subject', ''))
            date = headers.get('Date', '')
            from_str = ' '.join(
                (b.decode(c or 'utf-8') if isinstance(b, bytes) else b)
                for b, c in from_
            )
            subj_str = ' '.join(
                (b.decode(c or 'utf-8') if isinstance(b, bytes) else b)
                for b, c in subject
            )
            log('  [{}] {} | {}'.format(date, from_str[:60], subj_str[:60]))

    imap.logout()
    log('done')


if __name__ == '__main__':
    main()