#!/bin/bash
# Alacritty customizations for Omarchy
# Patches existing config rather than replacing it

set -e

ALACRITTY_CONFIG="${ALACRITTY_CONFIG:-$HOME/.config/alacritty/alacritty.toml}"

if [ ! -f "$ALACRITTY_CONFIG" ]; then
  echo "Error: Alacritty config not found at $ALACRITTY_CONFIG"
  exit 1
fi

echo "Applying Alacritty customizations..."

# Customization: Ctrl+Space for Vi Mode (tmux-like copy mode)
add_vimode_binding() {
  if grep -q "ToggleViMode" "$ALACRITTY_CONFIG"; then
    echo "  [skip] ToggleViMode already present"
    return
  fi

  echo "  [add] Ctrl+Space -> ToggleViMode"

  # Insert new binding before the closing ] of the bindings array
  # Also ensure proper comma placement
  awk '
    /^\[keyboard\]/ { in_keyboard = 1 }
    in_keyboard && /^bindings = \[/ { in_bindings = 1 }
    in_bindings && /^\]/ {
      print "{ key = \"Space\", mods = \"Control\", action = \"ToggleViMode\" }"
      in_bindings = 0
    }
    in_bindings && /^\{.*\}[[:space:]]*$/ && !/,$/ {
      # Add comma to binding line if missing (for valid TOML array)
      print $0 ","
      next
    }
    { print }
  ' "$ALACRITTY_CONFIG" > "$ALACRITTY_CONFIG.tmp" && mv "$ALACRITTY_CONFIG.tmp" "$ALACRITTY_CONFIG"
}

add_vimode_binding

echo "Done."
