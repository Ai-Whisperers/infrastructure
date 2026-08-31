#!/usr/bin/env python3
"""
piece2-fill-keys.py — copies every key from default .env into kiki .env.

Why python (not bash): key names and values can contain any byte except
newlines. Shell parsing of .env is a tar pit. Python's os.environ reads
the file literally. No heredocs, no brackets, no history-expansion hazards.

Reads:
    /home/ai-whisperers/.hermes/.env
Writes (append-safe):
    /home/ai-whisperers/.hermes/profiles/kiki/.env
"""
import os
import sys
from pathlib import Path

DEFAULT_ENV = Path("/home/ai-whisperers/.hermes/.env")
KIKI_ENV    = Path("/home/ai-whisperers/.hermes/profiles/kiki/.env")

def fail(msg):
    print(f"FATAL: {msg}", file=sys.stderr)
    sys.exit(1)

if not DEFAULT_ENV.is_file():
    fail(f"{DEFAULT_ENV} does not exist")
if not DEFAULT_ENV.stat().st_mode & 0o400:
    fail(f"{DEFAULT_ENV} is not readable")
if not KIKI_ENV.is_file():
    fail(f"{KIKI_ENV} does not exist (run piece 1 first)")
if not os.access(KIKI_ENV, os.W_OK):
    fail(f"{KIKI_ENV} is not writable")

# parse default .env manually (don't rely on dotenv install; avoid creating deps)
keys = {}
for line in DEFAULT_ENV.read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if "=" not in line:
        continue
    k, _, v = line.partition("=")
    k = k.strip()
    v = v.strip()
    # strip surrounding quotes
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ('"', "'"):
        v = v[1:-1]
    if k:
        keys[k] = v

# read existing kiki keys so we can preserve (e.g. API_SERVER_KEY)
existing = {}
if KIKI_ENV.exists():
    for line in KIKI_ENV.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        existing[k.strip()] = v.strip().strip('"').strip("'")

# write: every key from default, but preserve any pre-existing kiki-only keys
# (notably API_SERVER_KEY which piece1 generated)
merged = {**keys, **existing}

# write atomically: write to temp file, chmod 600, rename
import tempfile
fd, tmp_path = tempfile.mkstemp(prefix=".kiki-env-", dir=str(KIKI_ENV.parent))
try:
    with os.fdopen(fd, "w") as f:
        for k, v in merged.items():
            # values are unquoted; if they have a space, quote with double-quotes
            if any(c in v for c in (' ', '\t', '"')) and not (v.startswith('"') and v.endswith('"')):
                v = f'"{v}"'
            f.write(f"{k}={v}\n")
    os.chmod(tmp_path, 0o600)
    os.replace(tmp_path, KIKI_ENV)
except Exception:
    if os.path.exists(tmp_path):
        os.unlink(tmp_path)
    raise

# report
n_default = len(keys)
n_kept = len(existing)
print(f"OK: copied {n_default} keys from default, kept {n_kept} already in kiki env")
print(f"OK: wrote {len(merged)} total keys to {KIKI_ENV}")
# show keys without values
print("\n--- kiki env keys (values redacted) ---")
for k in sorted(merged):
    v = merged[k]
    print(f"  {k}=<{len(v)} chars>")
