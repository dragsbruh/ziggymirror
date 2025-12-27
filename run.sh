#!/bin/bash

set -euo pipefail

mkdir -p "$HTTP_DIR"

while true; do
  echo "info: triggering sync"
  "$SYNC_SCRIPT"
  sleep "$SYNC_INTERVAL"
done &

if [ -n "$PORT" ]; then
  echo "httpd: starting httpd on port $PORT"
  exec httpd -f -p "$PORT" -h "$HTTP_DIR"
else
  echo "httpd: disabled"
  wait
fi
