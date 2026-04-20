#!/usr/bin/env bash
# Cross-builds sandbox-agent for Linux amd64 from a pinned sandbox-engine commit.
# Output: dist/sandbox-agent
set -euo pipefail

AGENT_REF="${AGENT_REF:?AGENT_REF must be set, e.g. main or a git sha}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
WORK="${ROOT}/.build/sandbox-engine"

mkdir -p "${DIST}"

if [[ ! -d "${WORK}/.git" ]]; then
  echo ">> cloning sitehub-dk/sandbox-engine into ${WORK}" >&2
  # Prefer GH_TOKEN (headless/CI path) over gh CLI's keyring-backed config.
  if [[ -n "${GH_TOKEN:-}" ]]; then
    git -c "http.extraHeader=Authorization: Bearer ${GH_TOKEN}" \
      clone --no-checkout --filter=blob:none \
      https://github.com/sitehub-dk/sandbox-engine.git "${WORK}" >&2
  else
    gh repo clone sitehub-dk/sandbox-engine "${WORK}" -- --no-checkout --filter=blob:none >&2
  fi
fi

GIT_EXTRA_HDR=()
if [[ -n "${GH_TOKEN:-}" ]]; then
  GIT_EXTRA_HDR=(-c "http.extraHeader=Authorization: Bearer ${GH_TOKEN}")
fi

(
  cd "${WORK}"
  git "${GIT_EXTRA_HDR[@]}" fetch --all --quiet
  git checkout --detach "${AGENT_REF}" >&2
)

echo ">> building sandbox-agent (CGO_ENABLED=0 GOOS=linux GOARCH=amd64) from ${AGENT_REF}" >&2
(
  cd "${WORK}"
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w -X main.agentRef=${AGENT_REF}" \
    -o "${DIST}/sandbox-agent" ./cmd/sandbox-agent/
)

echo "${AGENT_REF}" > "${DIST}/sandbox-agent.sha"
file "${DIST}/sandbox-agent" >&2
