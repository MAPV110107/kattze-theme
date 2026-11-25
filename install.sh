#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/MAPV110107/kattze-theme/main"
FONT_RAW_URL="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf"
FONT_RELEASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"

TERMUX_DIR="$HOME/.termux"
HELIX_DIR="$HOME/.config/helix"
HELIX_THEMES_DIR="$HELIX_DIR/themes"
TERMUX_PROPS="$TERMUX_DIR/termux.properties"
HELIX_CONFIG="$HELIX_DIR/config.toml"

command -v wget >/dev/null 2>&1 || pkg install -y wget

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

fetch_file() {
  local rel_path="$1"
  local dest="$2"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$rel_path" ]; then
    cp "$SCRIPT_DIR/$rel_path" "$dest"
  else
    wget -qO "$dest" "$REPO_RAW/$rel_path"
  fi
}

install_font() {
  local tmp_font
  tmp_font="$(mktemp)"
  if wget -qO "$tmp_font" "$FONT_RAW_URL" && [ -s "$tmp_font" ]; then
    mv "$tmp_font" "$TERMUX_DIR/font.ttf"
  else
    rm -f "$tmp_font"
    local tmp_dir tmp_tar font_file
    tmp_dir="$(mktemp -d)"
    tmp_tar="$tmp_dir/JetBrainsMono.tar.xz"
    wget -qO "$tmp_tar" "$FONT_RELEASE_URL"
    tar -xJf "$tmp_tar" -C "$tmp_dir"
    font_file="$(find "$tmp_dir" -type f -name 'JetBrainsMonoNerdFont-Regular.ttf' | head -n 1)"
    [ -n "$font_file" ] && cp "$font_file" "$TERMUX_DIR/font.ttf"
    rm -rf "$tmp_dir"
  fi
}

mkdir -p "$TERMUX_DIR" "$HELIX_THEMES_DIR"

# Inject Termux palette, font and Helix theme
fetch_file "termux/colors.properties" "$TERMUX_DIR/colors.properties"
cp "$TERMUX_DIR/colors.properties" "$TERMUX_DIR/kattze.properties"
install_font
fetch_file "helix/kattze.toml" "$HELIX_THEMES_DIR/kattze.toml"

# Inject Termux cursor blink rate
touch "$TERMUX_PROPS"
if grep -qE '^[[:space:]]*terminal-cursor-blink-rate[[:space:]]*=' "$TERMUX_PROPS"; then
  sed -i 's/^[[:space:]]*terminal-cursor-blink-rate[[:space:]]*=.*/terminal-cursor-blink-rate=500/' "$TERMUX_PROPS"
else
  printf '\nterminal-cursor-blink-rate=500\n' >> "$TERMUX_PROPS"
fi

# Update Helix config.toml while preserving unrelated keys
touch "$HELIX_CONFIG"
TMP_CONFIG="$(mktemp)"

awk '
BEGIN {
  section = ""
  wrote_theme = 0
  wrote_border = 0
  seen_editor = 0
  n = 0
}
/^[[:space:]]*\[/ {
  if (section == "" && !wrote_theme) {
    out[++n] = "theme = \"kattze\""
    wrote_theme = 1
  }
  if (section == "editor" && !wrote_border) {
    out[++n] = "popup-border = \"all\""
    wrote_border = 1
  }
  sec = $0
  sub(/^[[:space:]]*\[+/, "", sec)
  sub(/\].*$/, "", sec)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", sec)
  section = sec
  if (section == "editor") seen_editor = 1
  if (section == "editor.cursor-shape") next
  out[++n] = $0
  next
}
section == "editor.cursor-shape" { next }
section == "" && /^[[:space:]]*theme[[:space:]]*=/ {
  out[++n] = "theme = \"kattze\""
  wrote_theme = 1
  next
}
section == "editor" && /^[[:space:]]*popup-border[[:space:]]*=/ {
  out[++n] = "popup-border = \"all\""
  wrote_border = 1
  next
}
{ out[++n] = $0 }
END {
  while (n > 0 && out[n] ~ /^[[:space:]]*$/) n--
  if (!wrote_theme) print "theme = \"kattze\""
  for (i = 1; i <= n; i++) print out[i]
  if (!seen_editor) {
    if (n > 0 || !wrote_theme) print ""
    print "[editor]"
    print "popup-border = \"all\""
  } else if (section == "editor" && !wrote_border) {
    print "popup-border = \"all\""
  }
  print ""
  print "[editor.cursor-shape]"
  print "normal = \"underline\""
  print "insert = \"bar\""
  print "select = \"underline\""
}
' "$HELIX_CONFIG" > "$TMP_CONFIG"

mv "$TMP_CONFIG" "$HELIX_CONFIG"

if [ -n "${TERMUX_VERSION:-}" ]; then
  command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings
  sync
  sleep 1
  kill -9 -1
fi
