#!/bin/bash
# Removes the twitch-watch companion scripts and, if you confirm, its config
# and saved OAuth token. Does not use sudo/pkexec.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"

for script in twitch-auth twitch-followed-live twitch-watch; do
  if [[ -f "$BIN_DIR/$script" ]]; then
    rm -f "$BIN_DIR/$script"
    echo "Removed $BIN_DIR/$script"
  fi
done

echo
echo "Bar widget: run 'omarchy bar remove io.github.ch3w3y.twitch-watch' (or use"
echo "the bar layout editor) if you added it, then remove the plugin directory:"
echo "  rm -rf ~/.config/omarchy/plugins/io.github.ch3w3y.twitch-watch"
echo
read -r -p "Also delete ~/.config/twitch-watch (config) and the saved OAuth token? [y/N] " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
  rm -rf "$HOME/.config/twitch-watch"
  secret-tool clear service twitch-watch username oauth-token 2>/dev/null || true
  echo "Removed ~/.config/twitch-watch and the keyring entry (if any)."
else
  echo "Left ~/.config/twitch-watch and the keyring entry in place."
fi
