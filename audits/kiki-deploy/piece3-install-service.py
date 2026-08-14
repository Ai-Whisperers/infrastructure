#!/usr/bin/env python3
"""
piece3-install-service.py — writes systemd user service, enables it, verifies
gateway is up at 127.0.0.1:8643.

Why python: subprocess for systemctl is much more reliable than shelling out
via heredoc'd bash. The bearer check reads the key from disk at the moment
of curl, never via env-var interpolation.
"""
import os
import re
import subprocess
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

USER = "ai-whisperers"
SVC_DIR = Path(f"/home/{USER}/.config/systemd/user")
SVC_FILE = SVC_DIR / "hermes-gateway-kiki.service"
LOG_DIR = Path(f"/home/{USER}/.hermes/profiles/kiki/logs")
KIKI_ENV = Path(f"/home/{USER}/.hermes/profiles/kiki/.env")
VENV_PY = Path(f"/home/{USER}/.hermes/hermes-agent/.venv/bin/python")
PORT = 8643
HOST = "127.0.0.1"

def die(msg):
    print(f"FATAL: {msg}", file=sys.stderr)
    sys.exit(1)

def sh(cmd, check=True, capture=False):
    """run a command; print only if there's output"""
    r = subprocess.run(cmd, shell=isinstance(cmd, str), capture_output=capture, text=True)
    if check and r.returncode != 0:
        print(f"ERROR running: {cmd}", file=sys.stderr)
        if r.stdout: print(r.stdout, file=sys.stderr)
        if r.stderr: print(r.stderr, file=sys.stderr)
        die(f"command exited {r.returncode}")
    return r

# precondition: running as ai-whisperers, hermes venv present
if os.environ.get("USER") not in (USER, None):
    pass  # system check via whoami below
import pwd
try:
    me = pwd.getpwuid(os.getuid()).pw_name
except KeyError:
    me = os.environ.get("USER", "?")
if me != USER:
    die(f"must run as {USER} (you are {me})")
if not VENV_PY.is_file() or not os.access(VENV_PY, os.X_OK):
    die(f"hermes venv python not found at {VENV_PY}")

# write service file
SVC_DIR.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)
svc_content = f"""[Unit]
Description=Hermes Agent Gateway (profile: kiki)
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/{USER}
ExecStart={VENV_PY} -m hermes_cli.main --profile kiki gateway run
Restart=on-failure
RestartSec=5
Environment=HOME=/home/{USER}
Environment=PYTHONUNBUFFERED=1
StandardOutput=append:{LOG_DIR}/gateway.log
StandardError=append:{LOG_DIR}/logs/gateway.err

[Install]
WantedBy=default.target
"""
SVC_FILE.write_text(svc_content)
os.chmod(SVC_FILE, 0o644)
print(f"OK: service file written: {SVC_FILE}")

# daemon-reload + enable + start
sh("systemctl --user daemon-reload")
sh("systemctl --user enable --now hermes-gateway-kiki.service")
print("waiting 4s for service to bind...")
time.sleep(4)

# status
r = subprocess.run(
    ["systemctl", "--user", "status", "hermes-gateway-kiki", "--no-pager"],
    capture_output=True, text=True
)
print("---status---")
print(r.stdout[:1200])
if r.returncode != 0 and r.returncode != 3:
    print("(non-zero status; service may be in active or failed state)")

# listening port
r = subprocess.run(["ss", "-tln"], capture_output=True, text=True)
print("---listening---")
for line in r.stdout.splitlines():
    if f":{PORT}" in line or "State" in line:
        print(line)

# pull kiki key from disk for the curl, NEVER print it
kiki_env_text = KIKI_ENV.read_text() if KIKI_ENV.is_file() else ""
m = re.search(r"^API_SERVER_KEY=(\S+)", kiki_env_text, re.M)
if not m:
    die("kiki .env has no API_SERVER_KEY line; run piece 1 first")
key = m.group(1)
if len(key) != 64:
    die(f"kiki key length is {len(key)}, expected 64")

# health check
req = urllib.request.Request(
    f"http://{HOST}:{PORT}/health",
    headers={"Authorization": f"Bearer {key}"},
)
print("---health---")
try:
    with urllib.request.urlopen(req, timeout=5) as resp:
        body = resp.read().decode("utf-8", "replace")
        print(f"HTTP {resp.status}: {body[:200]}")
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8", "replace")
    print(f"HTTP {e.code}: {body[:300]}")
except Exception as e:
    print(f"error: {type(e).__name__}: {e}")

# models check
req = urllib.request.Request(
    f"http://{HOST}:{PORT}/v1/models",
    headers={"Authorization": f"Bearer {key}"},
)
print("---models---")
try:
    with urllib.request.urlopen(req, timeout=5) as resp:
        body = resp.read().decode("utf-8", "replace")
        print(body[:800])
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8", "replace")
    print(f"HTTP {e.code}: {body[:300]}")
except Exception as e:
    print(f"error: {type(e).__name__}: {e}")
