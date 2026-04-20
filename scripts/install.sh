#!/usr/bin/env bash
# Fetch the latest sandbox-engine-rootfs release and install every ext4 image under
# /data/rootfs/. Designed to be invoked on the Proxmox host that runs sandbox-engine.
#
# Idempotent: already-matching SHAs are left untouched. Logs go to journald via
# systemd-cat if present, else stdout.
set -euo pipefail

REPO="${REPO:-sitehub-dk/sandbox-engine-rootfs}"
DEST="${DEST:-/data/rootfs}"
TAG="${TAG:-latest}"

log() {
  if command -v systemd-cat >/dev/null 2>&1; then
    printf '%s\n' "$*" | systemd-cat -t sandbox-engine-rootfs
  fi
  printf '%s %s\n' "$(date -u +%H:%M:%SZ)" "$*"
}

command -v gh >/dev/null 2>&1 || { log "gh CLI is required on the Proxmox host"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

if [[ "${TAG}" == latest ]]; then
  log "resolving latest release tag for ${REPO}"
  TAG=$(gh release view --repo "${REPO}" --json tagName -q .tagName)
fi
log "installing release ${TAG} from ${REPO} into ${DEST}"

mkdir -p "${DEST}"
gh release download "${TAG}" --repo "${REPO}" --pattern '*.ext4' --pattern 'manifest.json' --dir "${WORK}"

if [[ ! -f "${WORK}/manifest.json" ]]; then
  log "manifest.json missing from release ${TAG}"
  exit 2
fi

python3 - "${WORK}" "${DEST}" <<'PY'
import hashlib, json, os, shutil, sys
work, dest = sys.argv[1], sys.argv[2]
with open(os.path.join(work, "manifest.json")) as f:
    manifest = json.load(f)

def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

changed = 0
for img in manifest["images"]:
    src = os.path.join(work, img["name"] + ".ext4")
    dst = os.path.join(dest, img["name"] + ".ext4")
    if not os.path.exists(src):
        print(f"missing from release: {src}", file=sys.stderr); sys.exit(3)
    actual = sha(src)
    if actual != img["sha256"]:
        print(f"checksum mismatch for {img['name']}: got {actual} want {img['sha256']}", file=sys.stderr); sys.exit(4)
    if os.path.exists(dst) and sha(dst) == img["sha256"]:
        print(f"unchanged: {img['name']}")
        continue
    tmp = dst + ".tmp"
    shutil.copyfile(src, tmp)
    os.rename(tmp, dst)
    print(f"installed: {img['name']} ({img['size']} bytes)")
    changed += 1

print(f"done — {changed} image(s) updated, {len(manifest['images']) - changed} unchanged")
PY

log "install.sh finished"
