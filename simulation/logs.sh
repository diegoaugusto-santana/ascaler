#!/usr/bin/env bash
# Follows the ascaler decisions. Use "./simulation/logs.sh all" to also see the CPU it reads.
set -euo pipefail
filter="scaled|WARNING"
[ "${1:-}" = "all" ] && filter="METRIC|scaled|WARNING"
docker service logs -f -t --no-task-ids --tail 0 ascaler_ascaler 2>&1 | grep --line-buffered -E "$filter"
