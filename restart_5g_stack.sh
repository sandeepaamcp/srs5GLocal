#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRSRAN_DOCKER_DIR="$ROOT_DIR/srsRAN_Project/docker"
COMPOSE_FILES=(
  -f docker-compose.yml
  -f docker-compose.ue.yml
  -f docker-compose.ui.yml
)

cd "$SRSRAN_DOCKER_DIR"

echo "Stopping 5G stack..."
docker compose "${COMPOSE_FILES[@]}" down

echo "Starting 5G stack..."
docker compose "${COMPOSE_FILES[@]}" up -d

echo "Waiting for srsUE attach..."
for _ in $(seq 1 30); do
  if docker exec srsran_ue ip addr show tun_srsue >/dev/null 2>&1 &&
     docker exec srsran_ue ping -I tun_srsue -c 1 -W 2 10.45.1.1 >/dev/null 2>&1; then
    echo "srsUE is attached and can reach 10.45.1.1."
    docker compose "${COMPOSE_FILES[@]}" ps
    exit 0
  fi
  sleep 2
done

echo "Stack started, but srsUE did not become reachable within 60 seconds." >&2
echo "Recent srsUE logs:" >&2
docker logs --tail 40 srsran_ue >&2 || true
exit 1
