#!/usr/bin/env bash
# Stops and removes Concourse containers and network.
# Pipeline state will be lost -- re-run set-pipelines.sh after restarting.
set -euo pipefail

NETWORK_NAME="concourse-net"

for container in concourse concourse-db; do
  if podman inspect "${container}" >/dev/null 2>&1; then
    echo "Stopping ${container}..."
    podman stop "${container}"
    podman rm "${container}"
  fi
done

if podman network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
  podman network rm "${NETWORK_NAME}"
fi

echo "Done."
