#!/bin/sh
set -eu

SRSUE_BIN="${SRSUE_BIN:-/mnt/d/projects/oran-sc-ric/srsRAN_4G/build/srsue/src/srsue}"
SRSUE_CFG="${SRSUE_CFG:-/mnt/d/projects/oran-sc-ric/e2-agents/srsRAN/ue_zmq_docker.conf}"
RF_LIB_DIR="${RF_LIB_DIR:-/mnt/d/projects/oran-sc-ric/srsRAN_4G/build/lib/src/phy/rf}"

if [ ! -x "$SRSUE_BIN" ]; then
  echo "Missing srsUE binary at $SRSUE_BIN"
  echo "Build srsRAN_4G in WSL first so the container can reuse the existing artifacts."
  exit 1
fi

if [ ! -f "$SRSUE_CFG" ]; then
  echo "Missing srsUE config at $SRSUE_CFG"
  exit 1
fi

if [ ! -c /dev/net/tun ]; then
  echo "/dev/net/tun is not available inside the UE container."
  echo "Start this service with NET_ADMIN and the TUN device mapped."
  exit 1
fi

export LD_LIBRARY_PATH="$RF_LIB_DIR:${LD_LIBRARY_PATH:-}"

exec "$SRSUE_BIN" "$SRSUE_CFG"
