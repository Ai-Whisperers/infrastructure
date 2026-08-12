#!/usr/bin/env bash
# docker-network-cleanup.sh — identify and remove orphan Docker networks
# "Orphan" = no containers/services using them, no longer referenced by stacks
# SAFE: only removes networks that are confirmed unused
# Usage: bash docker-network-cleanup.sh [--apply]
#
# Without --apply: dry-run, lists orphans
# With --apply: actually removes them
set -u

APPLY=false
[ "${1:-}" = "--apply" ] && APPLY=true

echo "=== Docker network cleanup — $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo ""

# 1. Get all networks
NETWORKS=$(docker network ls --format "{{.Name}}" | grep -vE "^(bridge|host|none|docker_gwbridge|ingress)$")

# 2. For each, count active endpoints (containers/services using it)
ORPHANS=()
for net in $NETWORKS; do
  CONTAINERS=$(docker network inspect "$net" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | wc -w)
  SERVICES=$(docker network inspect "$net" --format '{{len .Services}}' 2>/dev/null || echo "0")
  USAGE=$((CONTAINERS + SERVICES))

  if [ "$USAGE" -eq 0 ]; then
    ORPHANS+=("$net")
    echo "  🗑️  ORPHAN: $net (0 containers, $SERVICES services)"
  else
    echo "  ✓ used:   $net ($CONTAINERS containers, $SERVICES services)"
  fi
done

echo ""
echo "=== Summary ==="
echo "  total networks scanned: $(echo $NETWORKS | wc -w)"
echo "  orphans found: ${#ORPHANS[@]}"

if [ ${#ORPHANS[@]} -eq 0 ]; then
  echo "  ✓ nothing to clean"
  exit 0
fi

if [ "$APPLY" = false ]; then
  echo ""
  echo "DRY-RUN. To remove these orphans, run:"
  echo "  bash $0 --apply"
  exit 0
fi

echo ""
echo "=== REMOVING ORPHANS ==="
for net in "${ORPHANS[@]}"; do
  echo -n "  removing $net ... "
  if docker network rm "$net" 2>/dev/null; then
    echo "✓ removed"
  else
    echo "✗ FAILED (probably has a service attached that the count missed)"
  fi
done

echo ""
echo "=== cleanup complete ==="