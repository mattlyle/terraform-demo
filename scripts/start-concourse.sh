#!/usr/bin/env bash
# Starts Concourse CI using a Podman network (no pod required).
# Both containers join the same network so Concourse can reach Postgres by hostname.
# --privileged is required for the Concourse worker to run task containers.
set -euo pipefail

CONCOURSE_VERSION="7.11"
POSTGRES_VERSION="16"
NETWORK_NAME="concourse-net"
PORT="8080"
ADMIN_USER="admin"
ADMIN_PASS="admin"

if podman network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
  echo "Concourse network already exists. Run stop-concourse.sh first."
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"

echo "Creating network..."
podman network create "${NETWORK_NAME}"

echo "Starting Postgres..."
podman run -d \
  --network "${NETWORK_NAME}" \
  --name concourse-db \
  -e POSTGRES_DB=concourse \
  -e POSTGRES_USER=concourse \
  -e POSTGRES_PASSWORD=concourse \
  "docker.io/postgres:${POSTGRES_VERSION}"

echo "Waiting for Postgres to be ready..."
sleep 5

echo "Starting Concourse..."
podman run -d \
  --network "${NETWORK_NAME}" \
  --name concourse \
  --privileged \
  --cgroupns=host \
  --security-opt seccomp=unconfined \
  -p "${PORT}:8080" \
  -v "${PROJECT_DIR}:/workspace" \
  "docker.io/concourse/concourse:${CONCOURSE_VERSION}" quickstart \
  --add-local-user="${ADMIN_USER}:${ADMIN_PASS}" \
  --main-team-local-user="${ADMIN_USER}" \
  --external-url="http://localhost:${PORT}" \
  --worker-runtime=containerd \
  --postgres-host=concourse-db \
  --postgres-user=concourse \
  --postgres-password=concourse \
  --postgres-database=concourse

echo ""
echo "Concourse starting... give it ~15 seconds to be ready."
echo ""
echo "  UI   : http://localhost:${PORT}"
echo "  Login: fly -t local login -c http://localhost:${PORT} -u ${ADMIN_USER} -p ${ADMIN_PASS}"
echo "  Then : ./scripts/set-pipelines.sh"
