#!/usr/bin/env bash
# Cross-builds sandbox-agent for Linux amd64 from a pinned sandbox-engine commit.
# Output: dist/sandbox-agent
set -euo pipefail

AGENT_REF="${AGENT_REF:?AGENT_REF must be set, e.g. main or a git sha}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
WORK="${ROOT}/.build/sandbox-engine"

mkdir -p "${DIST}"

# Resolve a clone URL. If GH_TOKEN is set (headless/CI path) embed it inline
# so git stops prompting for credentials. Otherwise rely on `gh` keyring.
if [[ -n "${GH_TOKEN:-}" ]]; then
  CLONE_URL="https://x-access-token:${GH_TOKEN}@github.com/sitehub-dk/sandbox-engine.git"
else
  CLONE_URL="https://github.com/sitehub-dk/sandbox-engine.git"
fi

if [[ ! -d "${WORK}/.git" ]]; then
  echo ">> cloning sitehub-dk/sandbox-engine into ${WORK}" >&2
  if [[ -n "${GH_TOKEN:-}" ]]; then
    git clone --no-checkout --filter=blob:none "${CLONE_URL}" "${WORK}" >&2
  else
    gh repo clone sitehub-dk/sandbox-engine "${WORK}" -- --no-checkout --filter=blob:none >&2
  fi
fi

(
  cd "${WORK}"
  # Keep the tokenized URL ephemeral — set the remote for this fetch only.
  git -c "remote.origin.url=${CLONE_URL}" fetch --all --quiet
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
