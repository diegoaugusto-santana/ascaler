#!/usr/bin/env bash
# Generates the load peak. In another terminal, follow it with ./simulation/logs.sh
set -euo pipefail
cd "$(dirname "$0")"
echo "Load start (UTC): $(date -u +%T)"
docker run --rm -i --network host grafana/k6 run - < load.js
