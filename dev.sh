#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$ROOT_DIR/server"
PCB_DIR="$ROOT_DIR/packages/pcb"
VENV_DIR="$SERVER_DIR/.venv"
API_PORT="${API_PORT:-8400}"
WEB_PORT="${WEB_PORT:-5400}"

echo "==> Starting Artifex local development..."

# 1. Root npm dependencies
if [ ! -d "$ROOT_DIR/node_modules" ]; then
  echo "==> Installing root npm dependencies..."
  npm install
fi

# 2. PCB worker bundle
if [ ! -f "$PCB_DIR/dist/pcb-worker.mjs" ]; then
  echo "==> Building PCB worker bundle..."
  (cd "$PCB_DIR" && npm install --ignore-scripts && npm run bundle)
fi

# 3. Python virtualenv & dependencies
if [ ! -d "$VENV_DIR" ]; then
  echo "==> Creating Python virtualenv in $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install --upgrade pip
  "$VENV_DIR/bin/pip" install -e "$SERVER_DIR[dev]"
fi

# 4. Check .env
if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "==> Creating .env from .env.example..."
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  echo "    Note: Set META_API_KEY in .env to enable the AI agent."
fi

# Check if ports are already taken
check_port() {
  local port=$1
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    return 0 # taken
  fi
  return 1 # free
}

cleanup() {
  echo ""
  echo "==> Shutting down Artifex..."
  if [ -n "${API_PID:-}" ] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
  fi
  if [ -n "${WEB_PID:-}" ] && kill -0 "$WEB_PID" 2>/dev/null; then
    kill "$WEB_PID" 2>/dev/null || true
  fi
  wait 2>/dev/null || true
  echo "==> Stopped."
}
trap cleanup EXIT INT TERM

# Start Backend API
if check_port "$API_PORT"; then
  echo "==> API port $API_PORT is already running."
else
  echo "==> Starting API server on port $API_PORT..."
  (
    cd "$SERVER_DIR"
    FW_WEB_DEV_PORT="$WEB_PORT" "$VENV_DIR/bin/python" -m uvicorn artifex.app:app \
      --port "$API_PORT" \
      --proxy-headers \
      --forwarded-allow-ips 127.0.0.1
  ) &
  API_PID=$!
fi

# Start Frontend Vite Dev Server
if check_port "$WEB_PORT"; then
  echo "==> Web port $WEB_PORT is already running."
  echo "==> App is ready at http://localhost:$WEB_PORT"
  # Keep script alive if background API was started
  if [ -n "${API_PID:-}" ]; then
    wait "$API_PID"
  fi
else
  echo "==> Starting Web app on http://localhost:$WEB_PORT..."
  (
    cd "$ROOT_DIR/web"
    FW_API="http://127.0.0.1:$API_PORT" "$ROOT_DIR/node_modules/.bin/vite" dev --port "$WEB_PORT" --strictPort
  ) &
  WEB_PID=$!
  wait "$WEB_PID"
fi
