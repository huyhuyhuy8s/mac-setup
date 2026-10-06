#!/usr/bin/env bash
# bootstrap.sh — install the MacPorts toolchain this dotfiles repo depends on.
# Target: Intel Mac running macOS 26 (Tahoe). MacPorts only (no Homebrew).
#
# MacPorts itself is a signed .pkg from macports.org — install that first, then
# run this script.
set -euo pipefail

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

# 1. Xcode Command Line Tools: needed by MacPorts and nvim-treesitter parsers.
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools (a system dialog will appear)..."
  xcode-select --install || true
  echo "Finish the install, then re-run ./bootstrap.sh"
  exit 1
fi

# 2. MacPorts must already be installed.
if [ ! -x /opt/local/bin/port ]; then
  cat <<'EOF'
MacPorts is not installed. Install it first:
  1. Download the macOS 26 (Tahoe) package from https://www.macports.org/install.php
  2. Open the .pkg and follow the installer (it asks for your password).
  3. Re-run ./bootstrap.sh
EOF
  exit 1
fi

export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# 3. Update the port tree.
say "Updating MacPorts (sudo port selfupdate)..."
sudo port selfupdate

# 4. Core ports. (No casks on MacPorts; kitty is a normal port.)
say "Installing ports..."
sudo port install \
  neovim ripgrep fd fzf lazygit tree-sitter-cli \
  nodejs22 python312 go tmux starship git kitty

# 5. Activate the default python3 / nodejs.
say "Selecting default python3 / nodejs..."
sudo port select --set python3 python312 || warn "port select python3 failed"
sudo port select --set nodejs  nodejs22  || warn "port select nodejs failed"

# 6. tmux-256color terminfo: shipped on Tahoe, so this is only a fallback.
if command -v infocmp >/dev/null 2>&1 && ! infocmp tmux-256color >/dev/null 2>&1; then
  say "Adding tmux-256color terminfo (fallback)..."
  curl -fsSL https://raw.githubusercontent.com/tmux/tmux/master/terminfo/t/tmux-256color \
    | tic -x -o "$HOME/.terminfo" - || warn "terminfo fallback failed"
fi

# 7. Maple Mono NF font: no MacPorts port, install into ~/Library/Fonts.
say "Installing Maple Mono NF font..."
FONT_URL="$(curl -fsSL https://api.github.com/repos/subframe7536/maple-font/releases/latest 2>/dev/null \
  | grep -oE 'https://[^"]*MapleMono-NF\.zip' | head -1 || true)"
if [ -n "${FONT_URL:-}" ]; then
  tmp="$(mktemp -d)"
  curl -fsSL "$FONT_URL" -o "$tmp/MapleMono-NF.zip"
  mkdir -p "$HOME/Library/Fonts"
  unzip -oq "$tmp/MapleMono-NF.zip" -d "$HOME/Library/Fonts/"
  xattr -cr "$HOME"/Library/Fonts/MapleMono-NF*.ttf 2>/dev/null || true
  rm -rf "$tmp"
  say "Maple Mono NF installed to ~/Library/Fonts"
else
  warn "Could not auto-download Maple Mono NF. Download 'MapleMono-NF.zip' from"
  warn "https://github.com/subframe7536/maple-font/releases, unzip into ~/Library/Fonts,"
  warn "then run: xattr -cr ~/Library/Fonts/MapleMono-NF*.ttf"
fi

# 8. Optional: Java for the LazyVim lang.java extra.
say "Installing OpenJDK 17 (optional, for the Java LSP)..."
sudo port install openjdk17 || warn "openjdk17 install failed (optional)"

# 9. Optional: global biome for the typescript.biome extra (mason also provides one).
if command -v npm >/dev/null 2>&1; then
  say "Installing global biome (optional)..."
  sudo npm install -g @biomejs/biome || warn "biome install failed (optional)"
fi

cat <<'EOF'

NOTE: tmuxinator is NOT available in MacPorts. Pick one:
  a) Ruby gem:  sudo port install ruby34 && sudo gem install tmuxinator
  b) tmuxp:     sudo port install py312-tmuxp   (different CLI)

Next: ./install.sh
EOF
