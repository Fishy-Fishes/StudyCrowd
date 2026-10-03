#!/usr/bin/env bash
# Runs the Discord -> Claude bridge: prints one line per message from channels named *claude*.
# Token is read from $BRIDGE_TOKEN_FILE (default ~/.config/studycrowd/bot-token), never from the repo.
set -euo pipefail
cd "$(dirname "$0")"
export NODE_USE_ENV_PROXY=1
export NODE_EXTRA_CA_CERTS="${NODE_EXTRA_CA_CERTS:-/root/.ccr/ca-bundle.crt}"
exec node --no-warnings bridge.js 2>&1
