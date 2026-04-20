# sandbox-engine-rootfs

ext4 guest-image builder for the Firecracker microVMs spun up by
[`sitehub-dk/sandbox-engine`](https://github.com/sitehub-dk/sandbox-engine).

Each image is a self-contained ext4 filesystem with:

- language toolchain and framework CLIs baked in,
- the `sandbox-agent` binary (cross-built from a pinned sandbox-engine commit)
  at `/usr/local/bin/sandbox-agent`, started on boot via systemd so the vsock
  fast path for diffs / file ops / CDP / noVNC is live before sandbox-engine's
  health poll fires.

## Images

| Key | Base | Toolchain | Used by sandbox-engine |
|---|---|---|---|
| `rootfs-ruby33` | `ruby:3.3-slim-bookworm` | Ruby 3.3, bundler, foreman, node (for Rails assets) | `internal/detect/ruby.go` (Rails, Sinatra) |
| `rootfs-rust185` | `rust:1.85-slim-bookworm` | Rust 1.85 stable, cargo, `libssl-dev`, `pkg-config` | `internal/detect/rust.go` (binary crates) |
| `rootfs-java21` | `eclipse-temurin:21-jdk-jammy` | JDK 21, Gradle 8.12, Maven 3.9.9 | `internal/detect/java.go` (Spring Boot / Gradle / Maven) |
| `rootfs-php83` | `php:8.3-cli-bookworm` | PHP 8.3 CLI, composer, pdo, intl, mbstring, zip | `internal/detect/php.go` (Laravel, Symfony, plain PHP) |
| `rootfs-elixir17` | `elixir:1.17-slim` | Erlang/OTP, Elixir 1.17, hex, rebar, `phx_new`, node | `internal/detect/elixir.go` (Phoenix) |
| `rootfs-browser` | `node:22-bookworm-slim` | Chromium (headless-new), Xvfb + fluxbox + x11vnc + websockify + noVNC, helper scripts `desktop-start` and `chromium-start` | `preview_mode: browser` (PR #9), `POST /v1/sandboxes/:id/cdp/session` (PR #8) |

All images carry the same `sandbox-agent` baked in. The specific commit it was
built from is pinned as `AGENT_REF` in [`Makefile`](./Makefile) and echoed into
`dist/manifest.json`.

## Build locally

Requires Linux (Ubuntu 24.04 or equivalent) with:

- Docker Engine / Docker Desktop and `docker buildx`
- `e2fsprogs` for `mkfs.ext4`
- `gh` authenticated against an account that can read
  `sitehub-dk/sandbox-engine`

```bash
make agent            # cross-compile sandbox-agent into dist/
make ruby33           # build a single image, e.g. dist/rootfs-ruby33.ext4
make images           # build all six
make release          # build all + write dist/manifest.json
```

Outputs land in `dist/` and are gitignored.

### Firecracker-specific ext4 flags

The quickstart kernel (5.10) used by sandbox-engine rejects the 64-bit ext4
feature and the `metadata_csum` feature (see
[sandbox-engine 2026-04-09 vm-boot-stability changelog](https://github.com/sitehub-dk/sandbox-engine/blob/main/docs/changes/2026-04-09-vm-boot-stability.md)).
`scripts/tar-to-ext4.sh` disables both so the emitted image boots cleanly:

```
mkfs.ext4 -O ^64bit,^metadata_csum,^huge_file ...
```

## Consumer workflow (Proxmox host running sandbox-engine)

`sandbox-engine` reads rootfs images from `/data/rootfs/`. To install the
latest release on the host:

```bash
gh auth login                                          # once
scripts/install.sh                                     # pulls the newest release
scripts/install.sh TAG=v2026.04.21-1                   # pin a specific tag
```

The installer downloads the release assets, verifies each image's SHA-256
against `manifest.json`, and writes `*.ext4` atomically into `/data/rootfs/`.
It is idempotent — already-matching images are left untouched.

## CI

`.github/workflows/build.yml` runs on every push and pull request:

- `agent` job cross-builds `sandbox-agent` from the pinned sandbox-engine
  commit (requires the `SANDBOX_ENGINE_READ_TOKEN` repo secret — a PAT with
  `repo:read` scope for the private sandbox-engine repository).
- `image` job matrix-builds all six rootfs variants in parallel using the
  shared agent artifact.
- `release` job runs only on published GitHub Releases: it downloads every
  image artifact, generates `dist/manifest.json`, and uploads them all back
  onto the release.

Tag a new release via `gh release create vYYYY.MM.DD-N --generate-notes`.

## Bumping the pinned sandbox-agent

```bash
gh api repos/sitehub-dk/sandbox-engine/commits/main -q .sha
# Paste into Makefile AGENT_REF, commit, push — CI rebuilds everything.
```

## Layout

```
.
├── Makefile                          # orchestration (agent, images, release, manifest, clean)
├── scripts/
│   ├── build-agent.sh                # clones sandbox-engine @ AGENT_REF, cross-builds sandbox-agent
│   ├── build-image.sh                # Dockerfile → exported tar → ext4 for one image
│   ├── tar-to-ext4.sh                # ext4 creation with Firecracker-compatible flags
│   ├── manifest.sh                   # dist/manifest.json emitter
│   └── install.sh                    # consumer-side installer (Proxmox host)
├── images/
│   ├── _common/
│   │   ├── sandbox-agent.service     # systemd unit, copied into every image
│   │   └── install-agent.sh          # baked-in install helper
│   ├── ruby33/Dockerfile
│   ├── rust185/Dockerfile
│   ├── java21/Dockerfile
│   ├── php83/Dockerfile
│   ├── elixir17/Dockerfile
│   └── browser/Dockerfile            # Chromium + X11 + noVNC
└── .github/workflows/build.yml
```

## Out of scope

- Signing release artifacts (add cosign when the attestation story firms up).
- Publishing as OCI images — sandbox-engine wants raw ext4.
- Running the images. Integration testing lives on `smolvm-host`
  (Proxmox VMID 230) behind `go test -tags=kvm` gates inside
  `sitehub-dk/sandbox-engine`.
