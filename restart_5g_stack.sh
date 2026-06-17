#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRSRAN_DOCKER_DIR="$ROOT_DIR/srsRAN_Project/docker"
COMPOSE_FILES=(
  -f docker-compose.yml
  -f docker-compose.ue.yml
  -f docker-compose.ui.yml
)
HOST_TCP_PORTS=(9999 3300)

is_tcp_port_listening() {
  local port="$1"

  if command -v ss >/dev/null 2>&1; then
    ss -H -ltn "sport = :$port" 2>/dev/null | grep -q .
  elif command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1
  else
    nc -z 127.0.0.1 "$port" >/dev/null 2>&1
  fi
}

wait_for_tcp_port_closed() {
  local port="$1"

  for _ in $(seq 1 30); do
    if ! is_tcp_port_listening "$port"; then
      echo "Port $port is down."
      return 0
    fi
    sleep 1
  done

  echo "Port $port is still listening after 30 seconds." >&2
  return 1
}

wait_for_tcp_port_open() {
  local port="$1"

  for _ in $(seq 1 30); do
    if is_tcp_port_listening "$port"; then
      echo "Port $port is up."
      return 0
    fi
    sleep 1
  done

  echo "Port $port did not start listening within 30 seconds." >&2
  return 1
}

wait_for_published_ports_closed() {
  echo "Waiting for published ports to go down..."
  for port in "${HOST_TCP_PORTS[@]}"; do
    wait_for_tcp_port_closed "$port"
  done
}

wait_for_published_ports_open() {
  echo "Waiting for published ports to come back up..."
  for port in "${HOST_TCP_PORTS[@]}"; do
    wait_for_tcp_port_open "$port"
  done
}

cd "$SRSRAN_DOCKER_DIR"

echo "Stopping 5G stack..."
docker compose "${COMPOSE_FILES[@]}" down --remove-orphans
wait_for_published_ports_closed

echo "Starting 5G stack..."
docker compose "${COMPOSE_FILES[@]}" up -d
wait_for_published_ports_open

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
