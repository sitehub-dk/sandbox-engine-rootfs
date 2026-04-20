# rootfs-php83 — PHP 8.3 CLI + composer, for Laravel/Symfony/plain PHP sandboxes.
# Detector: sandbox-engine/internal/detect/php.go
# syntax=docker/dockerfile:1.6
FROM php:8.3-cli-bookworm

ARG AGENT_BIN=dist/sandbox-agent

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv ca-certificates curl git unzip \
      libzip-dev libsqlite3-dev libicu-dev libonig-dev libxml2-dev \
    && docker-php-ext-install -j"$(nproc)" zip pdo pdo_sqlite pdo_mysql intl mbstring \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ${AGENT_BIN} /tmp/sandbox-agent
COPY images/_common/sandbox-agent.service /tmp/sandbox-agent.service
COPY images/_common/install-agent.sh /tmp/install-agent.sh
RUN sh /tmp/install-agent.sh && rm -f /tmp/sandbox-agent /tmp/sandbox-agent.service /tmp/install-agent.sh
