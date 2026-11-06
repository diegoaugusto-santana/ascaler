#!/usr/bin/env bash
# Acompanha as decisoes do ascaler. Use "./simulation/logs.sh all" para ver tambem a CPU lida.
set -euo pipefail
filtro="scaled|WARNING"
[ "${1:-}" = "all" ] && filtro="METRIC|scaled|WARNING"
docker service logs -f -t --no-task-ids --tail 0 ascaler_ascaler 2>&1 | grep --line-buffered -E "$filtro"
