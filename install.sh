#!/usr/bin/env bash
# install.sh — symlink this repo's dotfiles into place on macOS.
#
# Safe to re-run: existing real files are moved to a timestamped backup dir
# (~/.dotfiles-backup-<timestamp>) before being replaced with symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT="$REPO/dotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup-$STAMP"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

backup_path() {
  local target="$1"
  if [ -L "$target" ]; then
    rm -f "$target"
  elif [ -e "$target" ]; then
    local rel="${target#"$HOME"/}"
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$target" "$BACKUP/$rel"
    say "backed up $target -> $BACKUP/$rel"
  fi
}

link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { say "MISSING SOURCE: $src (skipped)"; return; }
  mkdir -p "$(dirname "$dst")"
  backup_path "$dst"
  ln -s "$src" "$dst"
  say "linked $dst -> $src"
}

say "Installing dotfiles from $REPO"

link "$DOT/nvim"                        "$HOME/.config/nvim"
link "$DOT/tmux/tmux.conf"              "$HOME/.config/tmux/tmux.conf"
link "$DOT/kitty/kitty.conf"            "$HOME/.config/kitty/kitty.conf"
link "$DOT/kitty/theme.conf"            "$HOME/.config/kitty/theme.conf"
link "$DOT/starship.toml"               "$HOME/.config/starship.toml"
link "$DOT/tmuxinator/myproject.yml"    "$HOME/.config/tmuxinator/myproject.yml"
link "$DOT/shell/bashrc"                "$HOME/.bashrc"
link "$DOT/shell/zshrc"                 "$HOME/.zshrc"
link "$DOT/shell/bash_profile"          "$HOME/.bash_profile"
link "$DOT/local/bin/env"               "$HOME/.local/bin/env"

# tmux: the config `run`s vim-tmux-navigator directly (TPM is not used).
PLUGDIR="$HOME/.config/tmux/plugins"
if [ ! -d "$PLUGDIR/vim-tmux-navigator" ]; then
  mkdir -p "$PLUGDIR"
  say "Cloning tmux vim-tmux-navigator..."
  git clone --depth 1 https://github.com/christoomey/vim-tmux-navigator "$PLUGDIR/vim-tmux-navigator"
else
  say "tmux vim-tmux-navigator already present"
fi

echo
say "Done."
if [ -d "$BACKUP" ]; then
  say "Previous configs backed up to: $BACKUP"
fi
say "Next: open a NEW terminal, then run 'nvim' to let LazyVim install plugins."
