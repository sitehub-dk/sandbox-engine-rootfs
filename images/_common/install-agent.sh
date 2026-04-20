#!/bin/sh
# Common per-image post-install: drop sandbox-agent into the image and enable it.
# Expects /tmp/sandbox-agent to already exist (copied in by the Dockerfile).
set -eu

install -Dm0755 /tmp/sandbox-agent /usr/local/bin/sandbox-agent
install -Dm0644 /tmp/sandbox-agent.service /etc/systemd/system/sandbox-agent.service
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/sandbox-agent.service \
  /etc/systemd/system/multi-user.target.wants/sandbox-agent.service

# Trim apt metadata and caches — the ext4 image counts every byte.
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/*.deb /root/.cache || true
