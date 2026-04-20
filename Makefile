# sandbox-engine-rootfs — ext4 guest images for Firecracker microVMs
#
# Requirements (host):
#   - Linux (CI: ubuntu-latest) or macOS with Docker Desktop (buildx)
#   - docker + buildx
#   - e2fsprogs (mkfs.ext4)
#   - gh (for AGENT_REF resolution and release publishing)
#
# Outputs land in dist/. Each image is a raw ext4 file named <key>.ext4.
# The Firecracker quickstart kernel (5.10) requires: mkfs.ext4 -O ^64bit,^metadata_csum
# See sitehub-dk/sandbox-engine docs/changes/2026-04-09-vm-boot-stability.md for the kernel rationale.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Pinned sandbox-engine commit used to cross-build sandbox-agent.
# Bump by regenerating: `gh api repos/sitehub-dk/sandbox-engine/commits/main -q .sha`
AGENT_REF ?= 1c69b3166c3a9cf405c310f9326a69fd8e4474e6

# All image keys produced by this repo.
IMAGES := ruby33 rust185 java21 php83 elixir17 browser

DIST := dist
IMAGE_EXTS := $(addsuffix .ext4,$(addprefix $(DIST)/rootfs-,$(IMAGES)))

.PHONY: all agent images clean release manifest $(IMAGES) $(addprefix $(DIST)/rootfs-,$(IMAGES))

all: images

# Cross-build sandbox-agent from the pinned sandbox-engine commit.
agent: $(DIST)/sandbox-agent

$(DIST)/sandbox-agent:
	AGENT_REF=$(AGENT_REF) scripts/build-agent.sh

images: agent $(IMAGE_EXTS)

# Per-image target: `make ruby33` → dist/rootfs-ruby33.ext4
$(foreach key,$(IMAGES),$(eval $(key): $(DIST)/rootfs-$(key).ext4))

$(DIST)/rootfs-%.ext4: images/%/Dockerfile $(DIST)/sandbox-agent
	scripts/build-image.sh $*

release: images manifest

manifest: images
	AGENT_REF=$(AGENT_REF) scripts/manifest.sh

clean:
	rm -rf $(DIST)
