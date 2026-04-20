#!/usr/bin/env bash
# Convert a staged rootfs directory into a Firecracker-compatible ext4 image.
# Usage: scripts/tar-to-ext4.sh <staging-dir> <output.ext4>
#
# Firecracker's quickstart kernel (5.10) rejects 64-bit ext4. We disable
# the 64bit + metadata_csum features (see sandbox-engine issue 2026-04-09).
# Image size = ceil(1.25 * content_size / 64MiB) * 64MiB, minimum 256 MiB.
set -euo pipefail

STAGE="${1:?staging dir required}"
OUT="${2:?output path required}"

[[ -d "${STAGE}" ]] || { echo "stage dir missing: ${STAGE}" >&2; exit 2; }

# Measure content in 1 KiB blocks; add 25% slack; round up to 64 MiB.
CONTENT_KIB=$(du -sk "${STAGE}" | awk '{print $1}')
TARGET_KIB=$(( CONTENT_KIB * 125 / 100 ))
ALIGN_KIB=$(( 64 * 1024 ))
SIZE_KIB=$(( (TARGET_KIB + ALIGN_KIB - 1) / ALIGN_KIB * ALIGN_KIB ))
if (( SIZE_KIB < 256 * 1024 )); then
  SIZE_KIB=$(( 256 * 1024 ))
fi
SIZE_MIB=$(( SIZE_KIB / 1024 ))

echo ">> sizing ${OUT} at ${SIZE_MIB} MiB (content: ${CONTENT_KIB} KiB)" >&2

mkdir -p "$(dirname "${OUT}")"
rm -f "${OUT}"
truncate -s "${SIZE_MIB}M" "${OUT}"

# Firecracker 5.10 kernel requirements: disable 64bit and metadata_csum.
mkfs.ext4 \
  -q \
  -L rootfs \
  -O "^64bit,^metadata_csum,^huge_file" \
  -E "lazy_itable_init=0,lazy_journal_init=0" \
  -d "${STAGE}" \
  "${OUT}"

file "${OUT}" >&2
