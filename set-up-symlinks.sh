#! /usr/bin/env bash
set -euo pipefail

## This script sets up symlinks for the dotfiles in this repo.

# WARNING/TODO: runnning `ln -sf $dotfile-root/dotfiles/nvim ~/.config/nvim`
#   when ~/.config/nvim is a symlink to $dot-root/dotfiles/nvim will cause the symlink
#   to be created IN the dotfiles repo. ~/.config/nvim must not exist before running this script.

repo_root=$(git rev-parse --show-toplevel)


# "Source Relative to Repo Root|Absolute Path of Destination Link"
links=(
  "tridactyl/tridactylrc|$HOME/.tridactylrc"
  "tmux/tmux.comf|$HOME/.tmux.conf"
  "git/gitconfig|$HOME/.gitconfig"
  "nvim|$HOME/.config/nvim"
  "starship/starship.toml|$HOME/.config/starship.toml"
)

for entry in "${links[@]}"; do
  IFS='|' read -r src dst <<< "$entry"
  ln -sf "$repo_root/$src" "$dst"
done
