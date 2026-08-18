#!/usr/bin/env python3
"""Create placeholder secrets in Bitwarden Secrets Manager.

Creates empty/ROTATE-ME placeholder secrets that the user edits in the
Bitwarden web UI to fill in the actual values.

Usage:
  python3 bws_create_placeholders.py \
    --token-file ~/.bws-new-token.secret \
    --org-id 1d9b5a44-0c14-41aa-83ae-b4a90136155c \
    --project-id a1d64864-77f9-4e6a-8d6e-b4a90137189a

The script reads the BWS token from a file (mode 600), then creates a set of
placeholder secrets under the project. Values are short markers like
'ROTATE-ME-2026-08-18' that the user replaces in the Bitwarden web UI.

After the script completes, it shreds the token file (unless --keep-files).
"""
import argparse
import os
import sys
import uuid
from pathlib import Path

sys.path.insert(0, '/opt/data/.venv/lib/python3.11/site-packages')

import bitwarden_sdk
from bitwarden_sdk import BitwardenClient, ClientSettings, DeviceType


# Secrets to create. Each becomes a placeholder in BWS that the user
# edits via the Bitwarden web UI.
# Format: (key, note)
PLACEHOLDERS = [
    ('kiki-bitwarden-master', 'Replace with new Bitwarden master password after rotation. Original burned in chat 2026-08-18.'),
    ('kiki-gmail-password', 'Replace with new app-specific password or rotated password. 2FA enabled.'),
    ('kiki-instagram-password', 'Replace with rotated Instagram password.'),
    ('kiki-linkedin-password', 'Replace with rotated LinkedIn password.'),
    ('kyrian-gmail-password', 'Replace with new/rotated password for kyrianweiss.vdp@gmail.com.'),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--org-id', required=True)
    ap.add_argument('--project-id', required=True)
    ap.add_argument('--token-file', required=True)
    ap.add_argument('--keep-files', action='store_true')
    args = ap.parse_args()

    org_uuid = uuid.UUID(args.org_id)
    proj_uuid = uuid.UUID(args.project_id)

    token_path = Path(args.token_file).expanduser()
    if not token_path.exists():
        print(f"err: token file not found: {token_path}", file=sys.stderr)
        sys.exit(2)
    if token_path.stat().st_mode & 0o077:
        print(f"err: token file has loose permissions (must be 600)", file=sys.stderr)
        sys.exit(2)

    token = token_path.read_text().strip()
    if not token:
        print("err: token file is empty", file=sys.stderr)
        sys.exit(2)

    settings = ClientSettings(
        api_url='https://api.bitwarden.com',
        identity_url='https://identity.bitwarden.com',
        user_agent='hermes-bws-placeholders',
        device_type=DeviceType.SERVER,
    )
    client = BitwardenClient(settings)
    login = client.auth().login_access_token(token, None)
    if not login.success:
        print(f"err: login failed: {login.error_message}", file=sys.stderr)
        sys.exit(1)
    print("login: ok\n")

    print(f"creating {len(PLACEHOLDERS)} placeholders in project {proj_uuid}...")
    created = []
    for key, note in PLACEHOLDERS:
        placeholder_value = 'ROTATE-ME-2026-08-18'
        print(f"  creating: {key}")
        r = client.secrets().create(
            org_uuid,
            key,
            placeholder_value,
            note,
            [proj_uuid],
        )
        if r.success:
            secret_id = r.to_dict().get('data', {}).get('id')
            created.append((key, secret_id))
            print(f"    id: {secret_id}")
        else:
            print(f"    err: {r.error_message}", file=sys.stderr)

    print(f"\n=== Created {len(created)} of {len(PLACEHOLDERS)} placeholders ===\n")
    for key, sid in created:
        print(f"  {key}: {sid}")

    # Verify list shows them
    print("\n=== Final list of secrets in project ===")
    r = client.secrets().list(org_uuid)
    if r.success:
        for s in r.to_dict().get('data', {}).get('data', []):
            if isinstance(s, dict):
                print(f"  {s.get('key')}: {s.get('id')}")

    if not args.keep_files:
        try:
            size = token_path.stat().st_size
            with open(token_path, 'wb') as f:
                f.write(os.urandom(size))
            token_path.unlink()
            print(f"\nshredded: {token_path}")
        except Exception as e:
            print(f"warn: could not shred token file: {e}", file=sys.stderr)

    print("\n=== NEXT STEPS ===")
    print("1. Go to https://vault.bitwarden.com → Secrets Manager → Projects → hermes")
    print("2. For each placeholder below, click it, edit the value field, save:")
    for key, _ in created:
        print(f"   - {key}")
    print("3. Optional: also edit the Note field to track which account and rotation date")
    print("\nDone.")


if __name__ == '__main__':
    main()