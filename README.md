# Twitch Watch

An Omarchy bar-widget plugin for watching Twitch streams with a chat pane,
tiled side by side, from your keyboard.

- A bar pill that turns red when any channel you follow is live.
- Click it (or a keybinding) for a searchable picker of your live followed
  channels, sorted subscribed → viewer count → most-recently-followed, with
  live thumbnails. Type to filter, or type an arbitrary channel name.
- Picking a channel opens [streamlink](https://streamlink.github.io/) piping
  into `mpv` for the video, and [Chatuino](https://chatuino.net/) for chat,
  tiled side by side in Hyprland.
- Picking again while already watching something **hot-swaps** the stream and
  chat in place over mpv's IPC socket — no window close/reopen, no flicker.
- A settings pane (gear icon) for default stream quality, a locked chat-pane
  width, and the picker's refresh interval.

This plugin is a thin UI layer. All the actual work — Twitch API calls, mpv
IPC, window placement — happens in three plain bash scripts under `scripts/`,
which you can also run directly from a terminal without the bar widget.

## How it works

`Panel.qml` polls `scripts/twitch-followed-live` in the background and shows
whatever it already has the instant you open the picker (no fetch-on-open
delay). Selecting a channel runs `scripts/twitch-watch <channel>`, which:

- Launches `streamlink --player mpv ...` with an `--input-ipc-server` socket,
  and Chatuino in a terminal, if nothing is playing yet.
- Otherwise sends `loadfile <url> replace` over that socket and relaunches
  just the chat window, keeping the same mpv process/window in place.

See the comments in `scripts/twitch-watch` for the Hyprland-specific details
(a Ghostty `--class` quirk, a tiling race with mpv's own auto-resize, and how
window orientation/width are kept consistent) — they're all handled inside
the script, no extra setup needed for those.

## Prerequisites

- `streamlink`, `mpv`, `socat`, `jq`, `curl`, `libsecret` (`pacman`)
- [`chatuino`](https://aur.archlinux.org/packages/chatuino-bin) (AUR) —
  logged in separately via `chatuino account` (its own Twitch login, unrelated
  to this plugin's)

You'll also register your own (free) Twitch application for this plugin's API
access — see Setup below. It never uses Chatuino's own login/token.

## Install

```bash
omarchy plugin add https://github.com/Ch3w3y/omarchy-twitch-watch.git --enable
```

Then run the bundled installer, which copies the companion scripts to
`~/.local/bin` and scaffolds `~/.config/twitch-watch/config.json` (no
`sudo`/`pkexec`, no package manager calls, nothing written outside `$HOME`):

```bash
~/.config/omarchy/plugins/io.github.ch3w3y.twitch-watch/install.sh
```

It checks for the dependencies above and, if anything's missing, prints the
exact `pacman`/AUR command to install them — it never runs one itself, so
you're always the one entering your password.

## Setup

1. **Register a Twitch app** at
   [dev.twitch.tv/console/apps/create](https://dev.twitch.tv/console/apps/create):
   - Name: anything, as long as it doesn't contain the word "Twitch" anywhere
     (Twitch's own registration form rejects that)
   - OAuth Redirect URL: `http://localhost` (required by the form, unused by
     the device-code flow this plugin uses)
   - Client Type: **Public**
   - Copy the **Client ID** from the app's page afterward

2. Put that Client ID in `~/.config/twitch-watch/config.json`:
   ```json
   { "client_id": "<your client id>" }
   ```

3. **Log in** (device-code flow — prints a URL and a short code, opens your
   browser):
   ```bash
   twitch-auth login
   ```
   The resulting token is stored in your system keyring (`secret-tool`,
   service `twitch-watch`) — never in a plain file.

4. **Hyprland setup.** Add to `~/.config/hypr/windows.lua` (requires
   `misc.size_limits_tiled = true` in `~/.config/hypr/looknfeel.lua` for the
   `min_size` rules to apply to tiled windows — see the
   [Hyprland wiki](https://wiki.hypr.land/Configuring/Basics/Variables/#misc)):
   ```lua
   o.window({ class = "^(mpv)$" }, { float = false, min_size = { 400, 200 } })
   o.window({ title = "^(Chatuino)$" }, { min_size = { 250, 200 } })
   ```
   And a keybinding in `~/.config/hypr/bindings.lua` to open the picker:
   ```lua
   o.bind("SUPER + SHIFT + T", "Watch Twitch stream", "omarchy-shell -q io.github.ch3w3y.twitch-watch toggle")
   ```

5. The bar pill should already be enabled from `omarchy plugin add --enable`
   above. Move it with `omarchy bar move io.github.ch3w3y.twitch-watch
   --section right` if you'd like it elsewhere.

## Configuration

Everything the settings pane exposes lives in
`~/.config/twitch-watch/config.json`, the single source of truth for both the
QML UI and the bash scripts:

| Key | Meaning | Default |
| --- | --- | --- |
| `client_id` | Your registered Twitch app's Client ID | *(required, see Setup)* |
| `default_quality` | Streamlink quality preference (`best`, `1080p60`, `720p60`, `480p`) | `"best"` |
| `chat_width` | Chat pane width in pixels, reapplied on every launch/swap when locked | `420` |
| `locked` | Reset the chat pane to `chat_width` on every launch/swap | `true` |
| `refresh_interval_sec` | How often the picker's background poll refreshes | `60` |

## Using it without the bar widget

Everything also works from a terminal once `install.sh` has run:

```bash
twitch-watch                # opens a text picker (fzf-style, via Omarchy's menu)
twitch-watch <channel>      # launch or hot-swap directly
```

## Uninstall

```bash
~/.config/omarchy/plugins/io.github.ch3w3y.twitch-watch/uninstall.sh
omarchy plugin remove io.github.ch3w3y.twitch-watch
```

The uninstaller removes the companion scripts from `~/.local/bin` and asks
before deleting your config and keyring token. It does not touch the Hyprland
config lines from step 4 above — remove those yourself if you added them.

## Privacy & permissions

- Talks only to `id.twitch.tv`/`api.twitch.tv` (your own registered app) and
  your local Hyprland/mpv/chatuino — nothing else.
- The OAuth token is kept in your system keyring, not a plain file.
- No `sudo`/`pkexec`, no package-manager calls, no writes outside `$HOME`.

## License

MIT — see [LICENSE](LICENSE).
