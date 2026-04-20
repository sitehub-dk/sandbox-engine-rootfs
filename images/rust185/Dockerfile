# rootfs-rust185 — Rust 1.85 stable + cargo, for binary crates.
# Detector: sandbox-engine/internal/detect/rust.go
# syntax=docker/dockerfile:1.6
FROM rust:1.85-slim-bookworm

ARG AGENT_BIN=dist/sandbox-agent

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv ca-certificates curl git \
      build-essential pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ${AGENT_BIN} /tmp/sandbox-agent
COPY images/_common/sandbox-agent.service /tmp/sandbox-agent.service
COPY images/_common/install-agent.sh /tmp/install-agent.sh
RUN sh /tmp/install-agent.sh && rm -f /tmp/sandbox-agent /tmp/sandbox-agent.service /tmp/install-agent.sh
