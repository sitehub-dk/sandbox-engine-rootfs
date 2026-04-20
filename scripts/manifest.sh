#!/usr/bin/env bash
# Produces dist/manifest.json listing every built ext4 image.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
AGENT_REF="${AGENT_REF:-$(cat "${DIST}/sandbox-agent.sha" 2>/dev/null || echo unknown)}"
BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

{
  echo '{'
  echo "  \"build_time\": \"${BUILD_TIME}\","
  echo "  \"sandbox_agent_ref\": \"${AGENT_REF}\","
  echo '  "images": ['
  first=1
  for f in "${DIST}"/rootfs-*.ext4; do
    [[ -e "${f}" ]] || continue
    name="$(basename "${f}" .ext4)"
    size=$(wc -c <"${f}" | tr -d ' ')
    sha=$(shasum -a 256 "${f}" | awk '{print $1}')
    [[ $first -eq 1 ]] || echo '    ,'
    first=0
    printf '    {"name":"%s","size":%s,"sha256":"%s"}\n' "${name}" "${size}" "${sha}"
  done
  echo '  ]'
  echo '}'
} >"${DIST}/manifest.json"

echo ">> wrote ${DIST}/manifest.json" >&2
cat "${DIST}/manifest.json"
