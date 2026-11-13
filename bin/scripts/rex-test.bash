#!/usr/bin/env bash
# Runs rex against a private server that loads rex/init.lua and bin/scripts
# from the checkout it is called in, so a change can be tried without touching
# the live server. The server starts on first use and keeps running until
# `rex-test.bash server stop`.
#   $@ = rex arguments
set -euo pipefail

root=$(git rev-parse --show-toplevel)
dir=${TMPDIR:-/tmp}
dir=${dir%/}/rex-test-$(basename "$root")
server=unix://$dir/sock

running() { rex -S "$server" --autostart=false server status >/dev/null 2>&1; }

if ! running; then
    mkdir -p "$dir"
    # Panes inherit the server's REX_SERVER. Without this one, every rex
    # command run inside them would reach the live server.
    REX_SERVER=$server DOTFILES=$root nohup rex server run --listen "$server" \
        --config "$root/rex/init.lua" --state-dir "$dir" --restore=false \
        >"$dir/log" 2>&1 &
    for _ in {1..50}; do
        running && break
        sleep 0.1
    done
fi

exec rex -S "$server" --autostart=false "$@"
