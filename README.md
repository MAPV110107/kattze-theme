# kattze-theme

256-color monochrome theme for Termux and Helix featuring NomadNet-style borders, a blinking cursor, and JetBrainsMono Nerd Font.

## Prerequisites

* **Termux source:** Install exclusively from **F-Droid** or **GitHub Releases**. The Google Play build is deprecated and incompatible with modern repositories and `termux-reload-settings`.
* **Native environment:** Run directly in Termux, outside `proot-distro` containers or `root`/`tsu` sessions, to ensure access to `~/.termux` and the `$TERMUX_VERSION` environment variable.
* **Connectivity:** Direct access to `github.com` and `raw.githubusercontent.com`.
* **Force-close behavior:** Upon completion, the installer executes `kill -9 -1` to terminate Termux completely and force `font.ttf` to reload on next launch. Save active sessions and stop background services beforehand.

## Dependencies

On a clean Termux installation, update packages and install the required dependencies:

```bash
pkg update && pkg upgrade -y && pkg install -y curl helix xz-utils
```

* `curl`: Fetches the installer, color palette, theme, and font.
* `helix`: Target editor where `kattze.toml` and `config.toml` are applied.
* `xz-utils`: Required by `tar -xJf` as a fallback if the direct `.ttf` download fails and the script extracts the `.tar.xz` Nerd Fonts release archive.

## Installation

```bash
curl -fsSL "https://raw.githubusercontent.com/MAPV110107/kattze-theme/main/install.sh" | bash
```

This injects `~/.termux/colors.properties` (with a backup at `~/.termux/kattze.properties`), `~/.termux/font.ttf`, `terminal-cursor-blink-rate=500` into `~/.termux/termux.properties`, and `~/.config/helix/themes/kattze.toml`, while updating `~/.config/helix/config.toml` without overwriting unrelated settings.

## Verification

Reopen Termux after the automatic shutdown and verify Nerd Font glyph rendering and the Helix theme:

```bash
printf '\ue7a8 \uf126 \uf07c\n'
hx
```
