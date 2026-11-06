#!/usr/bin/env bash
# Gera o pico de carga. Em outro terminal, acompanhe com ./simulation/logs.sh
set -euo pipefail
cd "$(dirname "$0")"
echo "Inicio da carga (UTC): $(date -u +%T)"
docker run --rm -i --network host grafana/k6 run - < load.js
