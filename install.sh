#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" &&
  pwd
)"

scripts_dir="$repo_root/scripts"

mkdir -pv "$HOME/.local/bin"

for file in "$scripts_dir"/*; do
  if [ -f "$file" ]; then
    target="$HOME/.local/bin/$(basename "$file")"
    install -m 755 "$file" "$target"
    echo "Installed: $target"
  fi
done

echo
echo "Installed personal backup tools."
echo "Scripts installed in: $HOME/.local/bin"
echo
echo "Make sure $HOME/.local/bin is in your PATH."
