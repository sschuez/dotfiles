#!/bin/bash
# Linux/Omarchy customizations installer
# Applies minimal patches to existing configs rather than replacing them

set -e

LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Linux/Omarchy customizations..."
echo ""

# Run each component's apply script
for apply_script in "$LINUX_DIR"/*/apply.sh; do
  if [ -f "$apply_script" ]; then
    bash "$apply_script"
    echo ""
  fi
done

echo "All customizations applied."
