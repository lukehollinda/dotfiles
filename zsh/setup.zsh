# Optionally print time taken to source all zsh files at startup
PROFILE_STARTUP=false

if [[ "$PROFILE_STARTUP" == true ]]; then
  # EPOCHREALTIME avoids depending on a date(1) that understands %N
  zmodload zsh/datetime
  profile_source() {
    local file="$1"
    local start=$EPOCHREALTIME
    source "$file"
    printf '(%s): %.3fs\n' "$file" $((EPOCHREALTIME - start))
  }
fi

# Get script path (Below method is used to support sourcing this file through symlink)
script_path=$(readlink -f "${(%):-%x}")
script_dir=$(dirname "$script_path")
DOTFILE_PATH=$(cd "$script_dir" && git rev-parse --show-toplevel 2>/dev/null)
tmux set-environment -g DOTFILE_PATH "$DOTFILE_PATH" 2>/dev/null

# Source all other zsh files
for file in $(find "${DOTFILE_PATH}/zsh" -type f ! -name 'setup.zsh' ! -name 'README.md' | sort)
do
  if [[ "$PROFILE_STARTUP" == true ]]; then
    profile_source "$file"
  else
    source "$file"
  fi
done
