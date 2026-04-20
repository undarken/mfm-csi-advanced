#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if command -v lua >/dev/null 2>&1; then
  LUA_BIN="lua"
elif command -v lua5.4 >/dev/null 2>&1; then
  LUA_BIN="lua5.4"
else
  echo "ERROR: Lua interpreter not found. Run ./scripts/setup_dev_env.sh first."
  exit 1
fi

echo "Running smoke test with ${LUA_BIN}"
"${LUA_BIN}" "${REPO_ROOT}/tests/lua/reaper_smoke_test.lua"
