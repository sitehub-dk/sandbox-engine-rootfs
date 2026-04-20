#!/usr/bin/env bash
# Builds a single rootfs variant: Dockerfile -> staged rootfs tree -> ext4 image.
# Usage: scripts/build-image.sh <key>
# Produces: dist/rootfs-<key>.ext4
set -euo pipefail

KEY="${1:?image key required (e.g. ruby33, browser)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
BUILD="${ROOT}/.build/images/${KEY}"
DOCKERFILE="${ROOT}/images/${KEY}/Dockerfile"

[[ -f "${DOCKERFILE}" ]] || { echo "no Dockerfile at ${DOCKERFILE}" >&2; exit 2; }
[[ -x "${DIST}/sandbox-agent" ]] || { echo "missing dist/sandbox-agent — run 'make agent' first" >&2; exit 2; }

mkdir -p "${BUILD}" "${DIST}"
rm -rf "${BUILD}/stage"
mkdir -p "${BUILD}/stage"

IMAGE_TAG="sandbox-engine-rootfs-builder:${KEY}"

echo ">> building ${KEY} container image" >&2
DOCKER_BUILDKIT=1 docker buildx build \
  --platform linux/amd64 \
  --file "${DOCKERFILE}" \
  --tag "${IMAGE_TAG}" \
  --build-arg AGENT_BIN=dist/sandbox-agent \
  --load \
  "${ROOT}"

echo ">> exporting container filesystem to stage" >&2
CID=$(docker create --platform linux/amd64 "${IMAGE_TAG}" /bin/true)
trap 'docker rm -f "${CID}" >/dev/null 2>&1 || true' EXIT
docker export "${CID}" | tar -C "${BUILD}/stage" -xf -

# Remove container-ism that break in microVM boot.
rm -f "${BUILD}/stage/.dockerenv" "${BUILD}/stage/etc/hostname" || true

"${ROOT}/scripts/tar-to-ext4.sh" "${BUILD}/stage" "${DIST}/rootfs-${KEY}.ext4"
