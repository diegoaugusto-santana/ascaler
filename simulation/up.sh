#!/usr/bin/env bash
# Sobe o ambiente completo de simulacao em um Swarm de um no.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then
  if ip link show eth0 >/dev/null 2>&1; then
    docker swarm init --advertise-addr eth0 >/dev/null
  else
    docker swarm init >/dev/null
  fi
  echo "Swarm iniciado."
fi

docker build -q -t ascaler:local -f ascaler/Dockerfile.1.2.0 ascaler >/dev/null
echo "Imagem ascaler:local criada."

docker stack deploy --detach=true -c stack/ascaler.yml ascaler >/dev/null 2>&1
docker stack deploy --detach=true -c simulation/app.yml demo >/dev/null 2>&1

echo "Aguardando o app chegar a 3 replicas (pode levar 2 minutos na primeira vez)..."
for _ in $(seq 1 60); do
  if [ "$(docker service ls --filter name=demo_web --format '{{.Replicas}}')" = "3/3" ]; then
    docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Image}}'
    echo "Pronto. Rode: ./simulation/load.sh"
    exit 0
  fi
  sleep 5
done

echo "O app nao chegou a 3/3. Veja docs/simulacao.md." >&2
docker service ls --format 'table {{.Name}}\t{{.Replicas}}\t{{.Image}}' >&2
exit 1
