# rootfs-browser — Node 22 base + Chromium + X11/noVNC stack for preview_mode=browser.
# Consumed by sandbox-engine PRs #8 (CDP sessions) and #9 (noVNC live view).
# syntax=docker/dockerfile:1.6
FROM node:22-bookworm-slim

ARG AGENT_BIN=dist/sandbox-agent

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    DISPLAY=:0

RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv ca-certificates curl git \
      chromium chromium-sandbox \
      xvfb xinit fluxbox x11vnc \
      websockify novnc \
      fonts-noto-core fonts-dejavu-core \
      xauth xkb-data xserver-xorg-core xserver-xorg-video-dummy \
      dbus dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Helper: start an idle desktop + VNC + noVNC pipeline. Invoked by the
# guest-agent's desktop_start op from sandbox-engine PR #9.
RUN cat >/usr/local/bin/desktop-start <<'SH' \
 && chmod +x /usr/local/bin/desktop-start
#!/bin/sh
# Idle desktop stack used by sandbox-engine preview_mode=browser.
# Starts Xvfb :0, fluxbox WM, x11vnc on :5900, and websockify -> :6080 serving noVNC.
set -eu
PORT_VNC=${PORT_VNC:-5900}
PORT_NOVNC=${PORT_NOVNC:-6080}
export DISPLAY=:0
mkdir -p /var/log/desktop
: > /var/log/desktop/xvfb.log
: > /var/log/desktop/fluxbox.log
: > /var/log/desktop/x11vnc.log
: > /var/log/desktop/novnc.log
Xvfb :0 -screen 0 1280x800x24 -nolisten tcp -ac >/var/log/desktop/xvfb.log 2>&1 &
sleep 0.5
fluxbox >/var/log/desktop/fluxbox.log 2>&1 &
x11vnc -display :0 -forever -shared -rfbport "${PORT_VNC}" -nopw -quiet \
  >/var/log/desktop/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc "${PORT_NOVNC}" "localhost:${PORT_VNC}" \
  >/var/log/desktop/novnc.log 2>&1 &
wait
SH

# Helper: start a headless Chromium exposing DevTools on 9222. Invoked by the
# guest-agent's chromium_start op from sandbox-engine PR #8.
RUN cat >/usr/local/bin/chromium-start <<'SH' \
 && chmod +x /usr/local/bin/chromium-start
#!/bin/sh
# Headless Chromium with remote-debugging on 9222 for sandbox-engine CDP sessions.
set -eu
URL=${1:-about:blank}
exec chromium \
  --headless=new \
  --no-sandbox \
  --disable-dev-shm-usage \
  --remote-debugging-address=0.0.0.0 \
  --remote-debugging-port=9222 \
  "${URL}"
SH

COPY ${AGENT_BIN} /tmp/sandbox-agent
COPY images/_common/sandbox-agent.service /tmp/sandbox-agent.service
COPY images/_common/install-agent.sh /tmp/install-agent.sh
RUN sh /tmp/install-agent.sh && rm -f /tmp/sandbox-agent /tmp/sandbox-agent.service /tmp/install-agent.sh
