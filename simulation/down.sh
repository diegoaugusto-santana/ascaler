#!/usr/bin/env bash
# Removes the simulation. Use "./simulation/down.sh --swarm" to also leave the Swarm.
set -euo pipefail
docker stack rm demo ascaler
if [ "${1:-}" = "--swarm" ]; then
  sleep 10
  docker swarm leave --force
fi
