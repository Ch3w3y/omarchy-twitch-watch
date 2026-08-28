#!/bin/bash
# Installs the twitch-watch companion scripts to ~/.local/bin and scaffolds
# ~/.config/twitch-watch/config.json. Does not touch pacman/AUR, does not use
# sudo/pkexec, and does not modify any file outside $HOME. Checks for missing
# system dependencies and prints (never runs) the command to install them --
# you stay in control of anything that needs a password.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/twitch-watch"

missing_pacman=()
missing_aur=()
command -v streamlink >/dev/null 2>&1 || missing_pacman+=(streamlink)
command -v mpv >/dev/null 2>&1 || missing_pacman+=(mpv)
command -v socat >/dev/null 2>&1 || missing_pacman+=(socat)
command -v jq >/dev/null 2>&1 || missing_pacman+=(jq)
command -v curl >/dev/null 2>&1 || missing_pacman+=(curl)
command -v secret-tool >/dev/null 2>&1 || missing_pacman+=(libsecret)
command -v chatuino >/dev/null 2>&1 || missing_aur+=(chatuino-bin)

if [[ ${#missing_pacman[@]} -gt 0 || ${#missing_aur[@]} -gt 0 ]]; then
  echo "Missing dependencies detected. Run these yourself before continuing:"
  [[ ${#missing_pacman[@]} -gt 0 ]] && echo "  sudo pacman -S --needed ${missing_pacman[*]}"
  [[ ${#missing_aur[@]} -gt 0 ]] && echo "  yay -S ${missing_aur[*]}   # or your preferred AUR helper"
  echo
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

for script in twitch-auth twitch-followed-live twitch-watch; do
  cp "$SCRIPT_DIR/scripts/$script" "$BIN_DIR/$script"
  chmod +x "$BIN_DIR/$script"
  echo "Installed $BIN_DIR/$script"
done

if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
  cat > "$CONFIG_DIR/config.json" <<'EOF'
{
  "client_id": "",
  "default_quality": "best",
  "chat_width": 420,
  "locked": true,
  "refresh_interval_sec": 60
}
EOF
  echo "Created $CONFIG_DIR/config.json (client_id still needs setting -- see README)"
else
  echo "$CONFIG_DIR/config.json already exists, leaving it untouched"
fi

cat <<'EOF'

Next steps (see README.md for full detail):
  1. Register a Twitch app at https://dev.twitch.tv/console/apps/create
     (Client Type: Public, OAuth Redirect URL: http://localhost), then put
     its Client ID in ~/.config/twitch-watch/config.json.
  2. Run: twitch-auth login
  3. Add the mpv/chatuino window rules and a SUPER+SHIFT+T-style keybinding
     from the README to your Hyprland config.
  4. Enable the bar widget: omarchy bar put io.github.ch3w3y.twitch-watch
EOF
