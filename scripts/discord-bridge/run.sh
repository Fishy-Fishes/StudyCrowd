#!/usr/bin/env bash
# Runs the Discord -> Claude bridge and restarts it if it crashes. Exit code 2 from bridge.js is fatal.
# Token: $BRIDGE_TOKEN_FILE (default ~/.config/studycrowd/bot-token). Channel: $BRIDGE_CHANNEL_ID.
cd "$(dirname "$0")"
export NODE_USE_ENV_PROXY=1
export NODE_EXTRA_CA_CERTS="${NODE_EXTRA_CA_CERTS:-/root/.ccr/ca-bundle.crt}"
while true; do
  node --no-warnings bridge.js 2>&1
  code=$?
  [ "$code" -eq 2 ] && { echo "[bridge] fatal, not restarting"; exit 2; }
  echo "[bridge] exited ($code), restarting in 5s"; sleep 5
done
