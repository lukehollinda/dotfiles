#!/usr/bin/env bash
# tmux's confirm-before kill-pane: y closes the pane, any other key cancels.
#   $1 = the session, $2 = the block to close

read -rsn1 -p "kill-pane? (y/n) " key
[[ "$key" == y ]] && rex block close -s "$1" "$2"
