#!/usr/bin/env python3
"""
Ai-Whisperers Lightweight CRM — single-file Python script.

Read ~/.hermes/infra/contacts.json or contacts.csv, render a list of leads,
their stage, last contact, next action. Designed for one or two operators.

Usage:
    python3 aiw-crm.py new <name> --phone "+595..." --email x@y.com --stage discovery
    python3 aiw-crm.py list [--stage proposal]
    python3 aiw-crm.py log <id> --note "Sent outreach email 2026-08-12"
    python3 aiw-crm.py set-stage <id> <new-stage>
    python3 aiw-crm.py dashboard            # light UI summary

Stages: cold → discovery → proposal → won / lost
Storage: ~/.hermes/infra/crm.json (simple JSON, no dep)
"""
import json
import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

def _resolve_default_path():
    # Prefer HERMES_HOME env, then HERMES_DATA env, then /opt/data/.hermes
    for env_var in ("HERMES_HOME", "HERMES_DATA"):
        val = os.environ.get(env_var)
        if val:
            return Path(val) / "infra" / "crm.json"
    return Path("/opt/data/.hermes") / "infra" / "crm.json"

DEFAULT_PATH = _resolve_default_path()
DEFAULT_PATH.parent.mkdir(parents=True, exist_ok=True)

VALID_STAGES = ("cold", "discovery", "proposal", "won", "lost")


def load_db(path=DEFAULT_PATH):
    if not path.exists():
        return {"next_id": 1, "leads": []}
    with path.open() as f:
        return json.load(f)


def save_db(db, path=DEFAULT_PATH):
    with path.open("w") as f:
        json.dump(db, f, indent=2, sort_keys=True)


def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def cmd_new(args):
    db = load_db()
    lead_id = db["next_id"]
    lead = {
        "id": lead_id,
        "name": args.name,
        "phone": getattr(args, "phone", None),
        "email": getattr(args, "email", None),
        "stage": getattr(args, "stage", "cold"),
        "source": getattr(args, "source", "outbound"),
        "created_at": now_iso(),
        "last_contact": None,
        "next_action": None,
        "history": [],
    }
    db["leads"].append(lead)
    db["next_id"] += 1
    save_db(db)
    print(f"Created lead #{lead_id}: {lead['name']} (stage: {lead['stage']})")


def cmd_list(args):
    db = load_db()
    leads = db["leads"]
    if args.stage:
        leads = [l for l in leads if l["stage"] == args.stage]
    if not leads:
        print(f"No leads{' in stage '+args.stage if args.stage else ''}")
        return
    print(f"{'ID':<5}{'NAME':<28}{'STAGE':<12}{'LAST CONTACT':<22}NEXT ACTION")
    for l in leads:
        lc = (l.get("last_contact") or "never")[:19]
        na = l.get("next_action") or "-"
        print(f"{l['id']:<5}{l['name'][:27]:<28}{l['stage']:<12}{lc:<22}{na}")


def cmd_log(args):
    db = load_db()
    lead = next((l for l in db["leads"] if l["id"] == args.id), None)
    if not lead:
        print(f"No lead with id {args.id}", file=sys.stderr)
        sys.exit(1)
    entry = {"at": now_iso(), "note": args.note}
    lead["history"].append(entry)
    lead["last_contact"] = entry["at"]
    if args.next_action:
        lead["next_action"] = args.next_action
    save_db(db)
    print(f"Logged note for #{args.id} ({lead['name']}); last_contact updated")


def cmd_set_stage(args):
    db = load_db()
    lead = next((l for l in db["leads"] if l["id"] == args.id), None)
    if not lead:
        print(f"No lead with id {args.id}", file=sys.stderr)
        sys.exit(1)
    if args.new_stage not in VALID_STAGES:
        print(f"Invalid stage. Use one of: {VALID_STAGES}", file=sys.stderr)
        sys.exit(1)
    prev = lead["stage"]
    lead["stage"] = args.new_stage
    save_db(db)
    print(f"#{args.id} {lead['name']}: {prev} -> {args.new_stage}")


def cmd_dashboard(args):
    db = load_db()
    leads = db["leads"]
    print("\n=== CRM Dashboard ===")
    by_stage = {s: [] for s in VALID_STAGES}
    for l in leads:
        by_stage.setdefault(l["stage"], []).append(l)
    for s in VALID_STAGES:
        n = len(by_stage[s])
        print(f"  {s:<12}: {n}")
    print(f"  {'TOTAL':<12}: {len(leads)}")
    # Overdue next actions (no last_contact, has next_action)
    overdue = []
    from email.utils import parsedate_to_datetime
    for l in leads:
        if l["stage"] in ("won", "lost"):
            continue
        if l["last_contact"]:
            lc = parsedate_to_datetime(l["last_contact"])
            age = (datetime.now(timezone.utc) - lc).days
            if age >= 7:
                overdue.append((l, age))
    if overdue:
        print(f"\n  Overdue re-contact (≥7 days):")
        for l, age in overdue:
            print(f"    #{l['id']} {l['name']:<28} stage={l['stage']:<10} last: {age}d ago")
    else:
        print("\n  No overdue re-contacts.")


def main():
    p = argparse.ArgumentParser(description="Ai-Whisperers CRM")
    sub = p.add_subparsers(dest="command", required=True)

    p_new = sub.add_parser("new")
    p_new.add_argument("name")
    p_new.add_argument("--phone", default=None)
    p_new.add_argument("--email", default=None)
    p_new.add_argument("--stage", default="cold", choices=VALID_STAGES)
    p_new.add_argument("--source", default="outbound")
    p_new.set_defaults(func=cmd_new)

    p_list = sub.add_parser("list")
    p_list.add_argument("--stage", default=None, choices=VALID_STAGES)
    p_list.set_defaults(func=cmd_list)

    p_log = sub.add_parser("log")
    p_log.add_argument("id", type=int)
    p_log.add_argument("--note", required=True)
    p_log.add_argument("--next-action", dest="next_action", default=None)
    p_log.set_defaults(func=cmd_log)

    p_set = sub.add_parser("set-stage")
    p_set.add_argument("id", type=int)
    p_set.add_argument("new_stage", choices=VALID_STAGES)
    p_set.set_defaults(func=cmd_set_stage)

    p_dash = sub.add_parser("dashboard")
    p_dash.set_defaults(func=cmd_dashboard)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
