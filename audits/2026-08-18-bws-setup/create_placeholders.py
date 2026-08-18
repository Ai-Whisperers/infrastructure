import os, sys, uuid

# Insert bitwarden_sdk location at the front of sys.path
# Caller sets BWS_LIB to the absolute path of the extracted bitwarden_sdk dir
bws_lib = os.environ.get('BWS_LIB')
if bws_lib and os.path.isdir(bws_lib):
    sys.path.insert(0, bws_lib)
else:
    # Try default location
    import glob
    candidates = glob.glob('/tmp/bws_unz.*/bitwarden_sdk')
    if candidates:
        sys.path.insert(0, candidates[0])
    else:
        print('ERROR: bitwarden_sdk not found. Set BWS_LIB env var.')
        sys.exit(1)

import bitwarden_sdk
from bitwarden_sdk import BitwardenClient, ClientSettings, DeviceType

PLACEHOLDERS = [
    ('kiki-bitwarden-master', 'Replace after rotation. Original burned 2026-08-18.'),
    ('kiki-gmail-password', 'Replace with new app-specific password. 2FA enabled.'),
    ('kiki-instagram-password', 'Replace with rotated Instagram password.'),
    ('kiki-linkedin-password', 'Replace with rotated LinkedIn password.'),
    ('kyrian-gmail-password', 'Replace with new password for kyrianweiss.vdp@gmail.com.'),
]

token = open(os.environ['BWS_TOKEN_FILE']).read().strip()
s = ClientSettings(
    api_url='https://api.bitwarden.com',
    identity_url='https://identity.bitwarden.com',
    user_agent='hermes-bws',
    device_type=DeviceType.SERVER,
)
c = BitwardenClient(s)
l = c.auth().login_access_token(token, None)
if not l.success:
    print('login failed:', l.error_message)
    sys.exit(1)
print('login: ok')

for key, note in PLACEHOLDERS:
    r = c.secrets().create(
        uuid.UUID(os.environ['BWS_ORG_ID']),
        key,
        'ROTATE-ME-2026-08-18',
        note,
        [uuid.UUID(os.environ['BWS_PROJ_ID'])],
    )
    if r.success:
        sid = r.to_dict().get('data', {}).get('id')
        print('  created: {} -> {}'.format(key, sid))
    else:
        print('  err {}: {}'.format(key, r.error_message))

# Verify
print('\n=== Verifying ===')
r = c.secrets().list(uuid.UUID(os.environ['BWS_ORG_ID']))
if r.success:
    for sec in r.to_dict().get('data', {}).get('data', []):
        if isinstance(sec, dict):
            print('  {}: {}'.format(sec['key'], sec['id']))