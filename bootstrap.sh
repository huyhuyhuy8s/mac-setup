#!/usr/bin/env bash
# bootstrap.sh — install the macOS toolchain this dotfiles repo depends on.
# Target: Apple Silicon (arm64) Mac running macOS 26. Run once, re-runnable.
set -euo pipefail

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

# 1. Xcode Command Line Tools: provides git and clang (nvim-treesitter parsers).
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools (a system dialog will appear)..."
  xcode-select --install || true
  echo "Finish the install, then re-run ./bootstrap.sh"
  exit 1
fi

# 2. Homebrew.
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Core formulae.
say "Installing formulae (this can take a while)..."
brew install \
  neovim \
  ripgrep fd fzf lazygit tree-sitter-cli \
  node python3 go \
  tmux starship tmuxinator \
  git

# 4. GUI apps + fonts.
say "Installing casks (kitty + Maple Mono NF)..."
brew install --cask kitty font-maple-mono-nf

# 5. tmux-256color terminfo: NOT in macOS's default terminfo database.
#    The tmux.conf uses `default-terminal "tmux-256color"`.
if command -v infocmp >/dev/null 2>&1 && ! infocmp tmux-256color >/dev/null 2>&1; then
  say "Adding tmux-256color terminfo entry..."
  if curl -fsSL https://raw.githubusercontent.com/tmux/tmux/master/terminfo/t/tmux-256color \
      | tic -x -o "$HOME/.terminfo" - 2>/dev/null; then
    say "tmux-256color installed to ~/.terminfo"
  else
    warn "Could not add tmux-256color. Fallback: set default-terminal to 'screen-256color' in dotfiles/tmux/tmux.conf"
  fi
fi

# 6. JS tooling used by the LazyVim biome extra (mason provides a fallback too).
say "Installing global biome (optional)..."
npm install -g @biomejs/biome || warn "biome install failed (optional; mason can provide it)"

# 7. Java (optional, only needed by the LazyVim lang.java extra).
say "Installing OpenJDK 17 (optional, for the Java LSP)..."
brew install openjdk@17 || warn "openjdk@17 install failed (optional)"
cat <<'EOF'
  If you use the Java LSP, link the JDK so jdtls can find it:
    sudo ln -sfn "$(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk
EOF

say "Bootstrap complete. Next: ./install.sh"
