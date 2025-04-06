#! /bin/bash

# Workaround for kitty running detached and not closing when nvim is exited

/Applications/kitty.app/Contents/MacOS/kitty \
  --start-as maximized \
  --title "tridactyl-editor" \
  sh -c "nvim \"$1\"; exit"
