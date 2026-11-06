#!/usr/bin/env bash
# Remove a simulacao. Use "./simulation/down.sh --swarm" para sair do Swarm tambem.
set -euo pipefail
docker stack rm demo ascaler
if [ "${1:-}" = "--swarm" ]; then
  sleep 10
  docker swarm leave --force
fi
