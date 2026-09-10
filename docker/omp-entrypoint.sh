#!/bin/sh
set -eu

forward_pid=/tmp/idea-mcp-forward.pid
if [ -f "$forward_pid" ]; then
  pid=$(cat "$forward_pid" 2>/dev/null || true)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    exec herdr "$@"
  fi
  rm -f "$forward_pid"
fi

socat TCP-LISTEN:64342,bind=127.0.0.1,reuseaddr,fork TCP:host.docker.internal:64342 \
  >/tmp/idea-mcp-forward.log 2>&1 &
printf '%s\n' "$!" >"$forward_pid"

exec herdr "$@"
