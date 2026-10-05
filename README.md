# mac-setup — Omarchy → macOS dev environment

An adapted copy of a Linux (Omarchy 4.x) development environment, prepared for a
MacBook Pro running **macOS 26 (Apple Silicon)**.

It migrates **Neovim (LazyVim)**, **tmux**, **kitty**, **starship**, and
**tmuxinator**, removes the Linux/Omarchy-only couplings, and installs the
native macOS equivalents.

Everything here is version-pinned where it matters (`dotfiles/nvim/lazy-lock.json`),
and the dotfiles are symlinked so this folder can double as your git repo.

---

## What's included

| Path | Installs to | Notes |
|------|-------------|-------|
| `dotfiles/nvim/` | `~/.config/nvim` | LazyVim + 16 extras; macOS patches applied |
| `dotfiles/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | unchanged behaviour |
| `dotfiles/kitty/kitty.conf` + `theme.conf` | `~/.config/kitty/` | theme baked in, macOS fixes |
| `dotfiles/starship.toml` | `~/.config/starship.toml` | unchanged |
| `dotfiles/tmuxinator/myproject.yml` | `~/.config/tmuxinator/` | placeholder project — edit `root:` for your machine |
| `dotfiles/shell/{bashrc,zshrc,bash_profile}` | `~/.bashrc`, `~/.zshrc`, `~/.bash_profile` | Omarchy sourcing removed, brew + starship added |
| `bootstrap.sh` | — | installs Homebrew packages, casks, fonts, terminfo |
| `install.sh` | — | symlinks dotfiles into place (with backup) |
| `SECRETS.md` | — | how to recreate API keys (Keychain) |
| `manual-install.sh` | — | one self-contained script to type if the repo can't be cloned |
| `MANUAL-INSTALL.md` | — | hand-entry install guide (no repo access) |

---

## Prerequisites

- Apple Silicon Mac (arm64), macOS 26.
- Admin rights (Homebrew + the optional JDK symlink).
- Network access.

---

## Quick start

Transfer the folder to the Mac, then:

```bash
cd ~/mac-setup
chmod +x bootstrap.sh install.sh
./bootstrap.sh     # Homebrew + all packages, apps, fonts
./install.sh       # symlink the dotfiles into ~
# then set up secrets (see SECRETS.md)
# then open a NEW terminal and run: nvim
```

---

## Step-by-step

### 1. Transfer this folder to the Mac

From the Linux machine (pick one):

```bash
# A) archive + AirDrop/scp
tar czf mac-setup.tar.gz mac-setup
scp mac-setup.tar.gz you@macbook:~
# on the Mac: tar xzf mac-setup.tar.gz
```

```bash
# B) git (recommended if you want to keep syncing)
cd ~/mac-setup
git init && git add . && git commit -m "chore: initial mac-setup"
# create an empty repo on your host, then:
git remote add origin <your-repo-url> && git push -u origin main
```

### 2. Bootstrap

```bash
cd ~/mac-setup
./bootstrap.sh
```

This installs, in order:

- **Xcode Command Line Tools** (git + clang for `nvim-treesitter` parsers).
- **Homebrew** (if missing).
- Formulae: `neovim` `ripgrep` `fd` `fzf` `lazygit` `tree-sitter-cli` `node`
  `python3` `go` `tmux` `starship` `tmuxinator` `git`.
- Casks: `kitty`, `font-maple-mono-nf`.
- The `tmux-256color` terminfo entry (not present in macOS's default DB).
- Optional: global `biome`, `openjdk@17` (for the Java LSP).

Re-runnable. If it stops at the Xcode step, finish that install and run it again.

### 3. Install the dotfiles

```bash
./install.sh
```

It symlinks each file into `~`, backing up any real file it replaces to
`~/.dotfiles-backup-<timestamp>/`, and clones the tmux
`vim-tmux-navigator` plugin (the tmux config `run`s it directly; TPM is not used).

> Prefer copies over symlinks? Replace `ln -s "$src" "$dst"` in `install.sh`
> with `cp -RL "$src" "$dst"`.

### 4. Secrets

API keys are stored in the **macOS Keychain** (recommended), with a plaintext
`~/.secrets/<name>` file as fallback. See **`SECRETS.md`** for the exact commands.

### 5. First Neovim launch

```bash
nvim
```

LazyVim will install ~70 plugins (can take a few minutes). Then:

```
:LazyHealth      " recommended by LazyVim
:checkhealth     " look for errors under clipboard, language providers
```

### 6. Verify the rest

```bash
tmux -V                     # 3.x
kitty --version
starship --version
mux ls                      # tmuxinator projects
eval "$(/opt/homebrew/bin/brew shellenv)" && echo "$PATH" | tr : '\n' | head
```

- **kitty**: check the font renders, transparency/blur works, and Option+Enter
  splits tmux panes (`macos_option_as_alt yes` is now set).
- **tmux**: prefix is `C-Space` (second prefix `C-b`); `q` reloads config.
- **starship**: open a new shell; the prompt should be the cyan `❯` theme.

---

## What changed vs the Linux config

| File | Change | Why |
|------|--------|-----|
| `nvim/lua/plugins/go-lint.lua` | `cmd` `/usr/bin/golangci-lint` → `golangci-lint` | path is Linux-specific; use PATH |
| `nvim/lua/config/remote_clipboard.lua` | rewritten cross-platform | keeps OSC 52; adds `pbcopy`/`pbpaste` on macOS; guards the Linux-only `/proc` process walk |
| `nvim/lua/plugins/theme.lua` | symlink dereferenced to a real file | it was a symlink into Omarchy's theme state (`terminus` theme) that would break on macOS |
| `kitty/kitty.conf` | `include …/omarchy/current/theme/kitty.conf` → local `theme.conf` | Omarchy theme path doesn't exist on macOS |
| `kitty/kitty.conf` | removed duplicate `opacity`; kept `background_opacity 0.70` | `opacity` is not a valid option and warns |
| `kitty/kitty.conf` | added `macos_option_as_alt yes` | required for tmux `M-Enter`/`M-Escape`/`M-Arrow` bindings |
| `kitty/kitty.conf` | commented out `listen_on …${XDG_RUNTIME_DIR}…` | macOS has no `XDG_RUNTIME_DIR`; feature was Omarchy/Hyprland cwd lookup |
| `shell/bashrc`, `zshrc` | removed Omarchy `/etc/omarchy.conf` + `$OMARCHY_PATH/default/bash/rc` sourcing; added `brew shellenv` + `starship init` + Keychain secret read | the Omarchy files don't exist on macOS |
| `tmux/tmux.conf` | unchanged | portable; only the `tmux-256color` terminfo needs installing |
| `starship.toml` | unchanged | portable |
| `tmuxinator/myproject.yml` | generic placeholder | original project name/paths replaced; edit `root:` and pane commands |

---

## Dependencies installed (and why)

| Tool | Used by |
|------|---------|
| `neovim` 0.12.x | LazyVim (requires ≥ 0.11.2) |
| `ripgrep`, `fd`, `fzf` | Telescope/search, file finding |
| `lazygit` | LazyVim `<leader>gg`, neo-tree git integration |
| `tree-sitter-cli` | `nvim-treesitter` parser builds (now required) |
| `node`/`npm` | many LSPs, markdown-preview, eslint/biome |
| `python3` | Python tooling |
| `go` | `gopls`, `goimports`, `gofumpt` (LazyVim `lang.go`) |
| `tmux` | tmux config + nvim-tmux-navigator |
| `starship` | prompt |
| `tmuxinator` | `mux` / project sessions |
| `kitty` (cask) | terminal |
| `font-maple-mono-nf` (cask) | `font_family Maple Mono NF` |
| `openjdk@17` (optional) | `jdtls` (LazyVim `lang.java`) |

Everything else (LSP servers, formatters, linters) is installed on demand by
**mason** on first use.

---

## Known macOS gotchas / troubleshooting

- **`terminals database is inaccessible` / terminfo errors** — the
  `tmux-256color` entry. `bootstrap.sh` installs it; if it failed, either
  re-run it or change `default-terminal` in `dotfiles/tmux/tmux.conf` to
  `screen-256color`.
- **`~/.tmux.conf` shadows the config** — macOS tmux prefers `~/.tmux.conf`
  over `~/.config/tmux/tmux.conf`. Ensure no stale `~/.tmux.conf` exists.
- **markdown-preview blank / prints a Node version** — run:
  `cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app && npm install`.
- **Mason installs an x86_64 binary on arm64** (e.g. `hadolint`, error -86) —
  install that tool via `brew` instead and point the linter at it.
- **Clipboard** — Neovim uses `pbcopy`/`pbpaste` natively. Inside tmux the
  bundled `remote_clipboard.lua` also emits OSC 52. If `:checkhealth` is happy
  but paste is empty, confirm kitty's `clipboard_control` allows read and tmux
  has `set-clipboard on`.
- **Java LSP** — `jdtls` needs a JDK on PATH; link it as shown by `bootstrap.sh`.
- **Icons look like boxes** — the Nerd Font isn't active/installed; reinstall
  `font-maple-mono-nf` and restart kitty.

---

## Not migrated (by design)

- **Omarchy theme system / Hyprland / quickshell / waybar** — Linux desktop only.
  The current theme's colours are baked into `nvim/lua/plugins/theme.lua` and
  `kitty/theme.conf`.
- **mise-managed toolchains** — a `~/.config/mise` existed on the Linux box.
  If you rely on it, install `mise` and recreate `mise.toml`; otherwise the brew
  formulae cover the essentials.
- **alacritty / ghostty configs** — available on the Linux box but not requested.
- **opencode / oh-my-pi (`PIG_HOME`)** — separate tools; recreate separately.
- **Hyprland global keybindings that used kitty's `listen_on` socket.**

---

## Keeping it in sync

```bash
cd ~/mac-setup
git add -A
git commit -m "chore: tweak"
git push
```

`~/.config/nvim` is a symlink into this repo, so `:Lazy` sync updates
`dotfiles/nvim/lazy-lock.json` here automatically — commit it to pin versions.
