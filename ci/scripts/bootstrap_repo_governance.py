#!/usr/bin/env python3
"""Bootstrap governance on one or many Ai-Whisperers repositories.

Actions:
1) Create/Update `.github/workflows/governance.yml` caller
2) Open PR
3) Apply branch protection required checks on default branch

Usage:
  python scripts/bootstrap_repo_governance.py --repos base,template-nextjs-client
  python scripts/bootstrap_repo_governance.py --from-file repos.txt
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Iterable

ORG = "Ai-Whisperers"
BRANCH = "chore/bootstrap-governance"
WORKFLOW_CONTENT = """name: Governance

on:
  pull_request:
  push:
    branches: [main, master, Main, \"aiw/main\"]

jobs:
  governance:
    uses: Ai-Whisperers/ci-cd/.github/workflows/governance.yml@main
"""


def run(cmd: list[str], cwd: str | None = None, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=cwd, check=check, text=True, capture_output=True)


def repo_default_branch(repo: str) -> str:
    out = run(["gh", "api", f"repos/{ORG}/{repo}"])
    return json.loads(out.stdout)["default_branch"]


def ensure_governance_file(repo_dir: Path) -> bool:
    target = repo_dir / ".github" / "workflows" / "governance.yml"
    target.parent.mkdir(parents=True, exist_ok=True)
    before = target.read_text() if target.exists() else None
    target.write_text(WORKFLOW_CONTENT)
    return before != WORKFLOW_CONTENT


def open_pr(repo: str, default_branch: str) -> str:
    existing = run(
        ["gh", "pr", "list", "-R", f"{ORG}/{repo}", "--head", BRANCH, "--state", "open", "--json", "url"],
    )
    items = json.loads(existing.stdout)
    if items:
        return items[0]["url"]

    pr = run(
        [
            "gh",
            "pr",
            "create",
            "-R",
            f"{ORG}/{repo}",
            "--base",
            default_branch,
            "--head",
            BRANCH,
            "--title",
            "chore: bootstrap central governance",
            "--body",
            "Adds reusable governance caller from `Ai-Whisperers/ci-cd` and enables branch protection required check.",
        ]
    )
    return pr.stdout.strip()


def process_repo(workdir: Path, repo: str) -> dict:
    full = f"{ORG}/{repo}"
    local = workdir / repo.replace("/", "__")
    default = repo_default_branch(repo)

    if not local.exists():
        run(["gh", "repo", "clone", full, str(local)])

    run(["git", "fetch", "--all", "--prune"], cwd=str(local))
    run(["git", "checkout", default], cwd=str(local))
    run(["git", "pull", "--ff-only"], cwd=str(local))
    run(["git", "checkout", "-B", BRANCH], cwd=str(local))

    changed = ensure_governance_file(local)
    if changed:
        run(["git", "add", ".github/workflows/governance.yml"], cwd=str(local))
        run(["git", "commit", "-m", "chore(ci): add central governance workflow caller"], cwd=str(local))
        run(["git", "push", "-u", "origin", BRANCH, "-f"], cwd=str(local))

    pr_url = open_pr(repo, default)
    # keep protection idempotent; if PR check missing it will pass after merge
    payload = {
        "required_status_checks": {"strict": True, "contexts": [".github/workflows/governance.yml"]},
        "enforce_admins": False,
        "required_pull_request_reviews": None,
        "restrictions": None,
        "allow_force_pushes": False,
        "allow_deletions": False,
        "block_creations": False,
        "required_conversation_resolution": True,
        "lock_branch": False,
        "allow_fork_syncing": True,
    }
    p = subprocess.run(
        ["gh", "api", f"repos/{ORG}/{repo}/branches/{default}/protection", "--method", "PUT", "--input", "-"],
        input=json.dumps(payload),
        text=True,
        capture_output=True,
        check=True,
    )

    return {"repo": repo, "default_branch": default, "changed": changed, "pr": pr_url}


def parse_repos(args: argparse.Namespace) -> list[str]:
    repos: list[str] = []
    if args.repos:
        repos.extend([x.strip() for x in args.repos.split(",") if x.strip()])
    if args.from_file:
        for line in Path(args.from_file).read_text().splitlines():
            s = line.strip()
            if s and not s.startswith("#"):
                repos.append(s)
    return sorted(set(repos))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repos", help="Comma-separated repo names")
    ap.add_argument("--from-file", help="File with one repo per line")
    args = ap.parse_args()

    repos = parse_repos(args)
    if not repos:
        raise SystemExit("No repos provided")

    with tempfile.TemporaryDirectory(prefix="gov-bootstrap-") as td:
        workdir = Path(td)
        results = []
        for repo in repos:
            try:
                results.append(process_repo(workdir, repo))
            except subprocess.CalledProcessError as e:
                results.append({"repo": repo, "error": e.stderr.strip() or str(e)})

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
