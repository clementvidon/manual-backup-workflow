#!/bin/bash
set -euo pipefail

mkdir -pv "$HOME/.local/bin"

for file in scripts/*; do
    if [ -f "$file" ]; then
        target="$HOME/.local/bin/$(basename "$file")"
        install -m 755 "$file" "$target"
        echo "Installed: $target"
    fi
done

echo
echo "Installed manual backup tools."
echo "Scripts installed in: $HOME/.local/bin"
echo
echo "Make sure $HOME/.local/bin is in your PATH."
