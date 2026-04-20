# rootfs-elixir17 — Elixir 1.17 + Erlang/OTP, for Phoenix sandboxes.
# Detector: sandbox-engine/internal/detect/elixir.go
# syntax=docker/dockerfile:1.6
FROM elixir:1.17-slim

ARG AGENT_BIN=dist/sandbox-agent

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    MIX_HOME=/root/.mix

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv ca-certificates curl git \
      build-essential libssl-dev inotify-tools \
      nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force && mix archive.install --force hex phx_new

COPY ${AGENT_BIN} /tmp/sandbox-agent
COPY images/_common/sandbox-agent.service /tmp/sandbox-agent.service
COPY images/_common/install-agent.sh /tmp/install-agent.sh
RUN sh /tmp/install-agent.sh && rm -f /tmp/sandbox-agent /tmp/sandbox-agent.service /tmp/install-agent.sh
