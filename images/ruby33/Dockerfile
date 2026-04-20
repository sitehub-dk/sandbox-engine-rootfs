# rootfs-ruby33 — Ruby 3.3 + bundler, for Rails/Sinatra sandboxes.
# Detector: sandbox-engine/internal/detect/ruby.go
# syntax=docker/dockerfile:1.6
FROM ruby:3.3-slim-bookworm

ARG AGENT_BIN=dist/sandbox-agent

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    BUNDLE_SILENCE_ROOT_WARNING=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv ca-certificates curl git \
      build-essential libpq-dev libsqlite3-dev libyaml-dev \
      nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem install --no-document bundler foreman

COPY ${AGENT_BIN} /tmp/sandbox-agent
COPY images/_common/sandbox-agent.service /tmp/sandbox-agent.service
COPY images/_common/install-agent.sh /tmp/install-agent.sh
RUN sh /tmp/install-agent.sh && rm -f /tmp/sandbox-agent /tmp/sandbox-agent.service /tmp/install-agent.sh
