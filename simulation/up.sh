#!/usr/bin/env bash
# Starts the full simulation environment on a single-node Swarm.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then
  if ip link show eth0 >/dev/null 2>&1; then
    docker swarm init --advertise-addr eth0 >/dev/null
  else
    docker swarm init >/dev/null
  fi
  echo "Swarm initialized."
fi

docker build -q -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler >/dev/null
echo "Image ascaler:local built."

docker stack deploy --detach=true -c stack/ascaler.yml ascaler >/dev/null 2>&1
docker stack deploy --detach=true -c simulation/app.yml demo >/dev/null 2>&1

echo "Waiting for the app to reach 3 replicas (may take 2 minutes the first time)..."
for _ in $(seq 1 60); do
  if [ "$(docker service ls --filter name=demo_web --format '{{.Replicas}}')" = "3/3" ]; then
    docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Image}}'
    echo "Ready. Run: ./simulation/load.sh"
    exit 0
  fi
  sleep 5
done

echo "The app did not reach 3/3. See docs/simulation.md." >&2
docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Image}}' >&2
exit 1
