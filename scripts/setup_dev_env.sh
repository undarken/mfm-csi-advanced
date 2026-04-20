#!/usr/bin/env bash
set -euo pipefail

ensure_lua() {
  if command -v lua >/dev/null 2>&1; then
    echo "Found lua: $(command -v lua)"
    return 0
  fi

  if command -v lua5.4 >/dev/null 2>&1; then
    echo "Found lua5.4: $(command -v lua5.4)"
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "Lua not found; installing lua5.4 with apt-get"
    if [ "$(id -u)" -eq 0 ]; then
      apt-get update
      apt-get install -y lua5.4
    elif command -v sudo >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y lua5.4
    else
      echo "ERROR: apt-get is available, but no privileges to install lua5.4."
      exit 1
    fi
  else
    echo "ERROR: Lua interpreter not found and no supported package manager detected."
    exit 1
  fi

  if command -v lua >/dev/null 2>&1 || command -v lua5.4 >/dev/null 2>&1; then
    echo "Lua setup complete."
    return 0
  fi

  echo "ERROR: Lua installation did not produce a runnable interpreter."
  exit 1
}

ensure_lua
