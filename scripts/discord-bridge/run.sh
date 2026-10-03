#!/usr/bin/env bash
# Runs the Discord -> Claude bridge and restarts it if it crashes. Exit code 2 from bridge.js is fatal.
# Token: $DISCORD_BOT_TOKEN or $BRIDGE_TOKEN_FILE (default ~/.config/studycrowd/bot-token). Channel: $BRIDGE_CHANNEL_ID.
# Crash loop (5 exits within 5 minutes): backs off to 60s between restarts and posts one warning to the channel.
cd "$(dirname "$0")"
export NODE_USE_ENV_PROXY=1
export NODE_EXTRA_CA_CERTS="${NODE_EXTRA_CA_CERTS:-/root/.ccr/ca-bundle.crt}"
exits=()
warned=0
while true; do
  node --no-warnings bridge.js 2>&1
  code=$?
  [ "$code" -eq 2 ] && { echo "[bridge] fatal, not restarting"; exit 2; }
  now=$(date +%s)
  recent=()
  for t in "${exits[@]}" "$now"; do [ $((now - t)) -lt 300 ] && recent+=("$t"); done
  exits=("${recent[@]}")
  delay=5
  if [ "${#exits[@]}" -ge 5 ]; then
    delay=60
    if [ "$warned" -eq 0 ]; then
      warned=1
      node --no-warnings reply.js - ":warning: Bridge keeps crashing (exit $code). Retrying every minute; messages are caught up on reconnect." >/dev/null 2>&1
    fi
  else
    warned=0
  fi
  echo "[bridge] exited ($code), restarting in ${delay}s"; sleep "$delay"
done
