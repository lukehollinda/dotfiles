#! /usr/bin/env bash
set -euo pipefail

## This script sets up symlinks for the dotfiles in this repo.
repo_root=$(git rev-parse --show-toplevel)


# "Source Relative to Repo Root|Absolute Path of Destination Link"
links=(
  "tridactyl/tridactylrc|$HOME/.tridactylrc"
  "tmux/tmux.conf|$HOME/.tmux.conf"
  "git/gitconfig|$HOME/.gitconfig"
  "nvim|$HOME/.config/nvim"
  "starship/starship.toml|$HOME/.config/starship.toml"
)

for entry in "${links[@]}"; do
  IFS='|' read -r src dst <<< "$entry"
  ln -sfh "$repo_root/$src" "$dst"
done
