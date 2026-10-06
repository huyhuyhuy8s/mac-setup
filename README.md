# mac-setup — Omarchy → macOS dev environment

An adapted copy of a Linux (Omarchy 4.x) development environment, prepared for
an **Intel Mac** running **macOS 26 (Tahoe)** using **MacPorts only** (no Homebrew).

It migrates **Neovim (LazyVim)**, **tmux**, **kitty**, **starship**, and
**tmuxinator**, removes the Linux/Omarchy-only couplings, and installs the
native macOS equivalents.

The dotfiles are symlinked, so this folder can double as a git repo.

---

## What's included

| Path | Installs to | Notes |
|------|-------------|-------|
| `dotfiles/nvim/` | `~/.config/nvim` | LazyVim + 16 extras; macOS patches applied |
| `dotfiles/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` | unchanged behaviour |
| `dotfiles/kitty/kitty.conf` + `theme.conf` | `~/.config/kitty/` | theme baked in, macOS fixes |
| `dotfiles/starship.toml` | `~/.config/starship.toml` | unchanged |
| `dotfiles/tmuxinator/myproject.yml` | `~/.config/tmuxinator/` | placeholder project — edit `root:` |
| `dotfiles/shell/{bashrc,zshrc,bash_profile}` | `~/.bashrc`, `~/.zshrc`, `~/.bash_profile` | Omarchy sourcing removed, MacPorts PATH + starship + Keychain |
| `bootstrap.sh` | — | installs MacPorts ports, the font, terminfo |
| `install.sh` | — | symlinks dotfiles into place (with backup) |
| `SECRETS.md` | — | how to recreate API keys (Keychain) |
| `manual-install.sh` / `MANUAL-INSTALL.md` | — | hand-entry route if this repo can't be reached |
| `install-lsp.sh` | — | pre-install every LSP/formatter/linter/DAP mason package (Intel) |

---

## Prerequisites

- Intel Mac running macOS 26 (Tahoe). *(macOS 26 is the last Intel release.)*
- **MacPorts installed** — a signed `.pkg` from
  <https://www.macports.org/install.php> (pick the macOS 26 / Tahoe package).
  It installs to `/opt/local` and needs your admin password.
- Xcode Command Line Tools (`xcode-select --install`) — required by MacPorts
  and by `nvim-treesitter`.
- Admin rights (`sudo`) — MacPorts installs are system-wide.

---

## Quick start

```bash
cd ~/mac-setup
chmod +x bootstrap.sh install.sh
./bootstrap.sh     # MacPorts ports + font + terminfo
./install.sh       # symlink the dotfiles into ~
./install-lsp.sh   # pre-install language servers (optional, recommended)
# then set up secrets (see SECRETS.md)
# then open a NEW terminal and run: nvim
```

---

## Step-by-step

### 1. Transfer this folder to the Mac

From the Linux machine:

```bash
tar czf mac-setup.tar.gz mac-setup            # AirDrop/scp it
# on the Mac: tar xzf mac-setup.tar.gz
```

If the Mac can't `git clone`, use the hand-entry route in `MANUAL-INSTALL.md`.

### 2. Bootstrap (MacPorts)

```bash
cd ~/mac-setup
./bootstrap.sh
```

This runs:

- **Xcode Command Line Tools** check (git + clang for `nvim-treesitter`).
- `sudo port selfupdate`.
- Ports: `neovim` `ripgrep` `fd` `fzf` `lazygit` `tree-sitter-cli`
  `nodejs22` `python312` `go` `tmux` `starship` `git` `kitty`.
- `sudo port select` to activate `python3` and `nodejs`.
- The **Maple Mono NF** font into `~/Library/Fonts` (no MacPorts port exists),
  with the quarantine attribute cleared.
- Optional: `openjdk17` (Java LSP), global `biome`.
- A fallback `tmux-256color` terminfo entry *only if* it's missing (Tahoe
  ships it, so normally skipped).

Re-runnable. Not in MacPorts: **tmuxinator** — see step 5.

### 3. Install the dotfiles

```bash
./install.sh
```

Symlinks each file into `~`, backing up any real file it replaces to
`~/.dotfiles-backup-<timestamp>/`, and clones the tmux
`vim-tmux-navigator` plugin (the tmux config `run`s it directly; TPM is unused).

> Prefer copies over symlinks? Replace `ln -s "$src" "$dst"` with
> `cp -RL "$src" "$dst"` in `install.sh`.

### 4. Secrets

API keys live in the **macOS Keychain** (recommended), with a plaintext
`~/.secrets/<name>` fallback. See **`SECRETS.md`**.

### 5. tmuxinator

MacPorts has no `tmuxinator` port. Pick one:

```bash
# a) Ruby gem
sudo port install ruby34
sudo gem install tmuxinator

# b) tmuxp (different CLI)
sudo port install py312-tmuxp
```

The shell alias is `mux='tmuxinator'`.

### 6. First Neovim launch

```bash
nvim
```

LazyVim installs ~70 plugins (a few minutes). Then `:LazyHealth` and
`:checkhealth`.

### 7. Pre-install the language servers (optional, recommended)

```bash
./install-lsp.sh
```

Installs all 38 mason packages this config uses — LSP servers (`gopls`, `jdtls`,
`vtsls`, `pyright`, `ruff`, `biome`, `oxlint`, `css-lsp`, `json-lsp`,
`tailwindcss-language-server`, `prisma-language-server`, `dockerfile-language-server`,
`docker-compose-language-service`, `marksman`, `taplo`, `eslint-lsp`,
`copilot-language-server`, `lua-language-server`) plus formatters, linters, and
DAP adapters (`stylua`, `shellcheck`, `shfmt`, `flake8`, `goimports`, `gofumpt`,
`gomodifytags`, `impl`, `delve`, `golangci-lint`, `hadolint`,
`markdownlint-cli2`, `markdown-toc`, `sqlfluff`, `oxfmt`, `prettier`,
`java-debug-adapter`, `java-test`, `js-debug-adapter`, `debugpy`).

- Runs headlessly and **waits** until every package is installed.
- Idempotent — re-runs skip what's already there.
- Also installs the runtime prerequisites via MacPorts (`go`, `nodejs22`,
  `python312`, `openjdk17`). Skip that with `SKIP_RUNTIMES=1 ./install-lsp.sh`.
- Fails with a non-zero exit if any package name is unknown or failed.

Package names are mason **registry** names (verified), not lspconfig server
names — e.g. `cssls`→`css-lsp`, `vtsls`→`vtsls`, `eslint`→`eslint-lsp`.

---

## What changed vs the Linux config

| File | Change | Why |
|------|--------|-----|
| `nvim/lua/plugins/go-lint.lua` | `cmd` `/usr/bin/golangci-lint` → `golangci-lint` | path is Linux-specific; use PATH |
| `nvim/lua/config/remote_clipboard.lua` | rewritten cross-platform | keeps OSC 52; adds `pbcopy`/`pbpaste`; guards the Linux-only `/proc` process walk |
| `nvim/lua/plugins/theme.lua` | symlink dereferenced to a real file | was a symlink into Omarchy's theme state (`terminus`) that would break |
| `kitty/kitty.conf` | `include …/omarchy/current/theme/kitty.conf` → local `theme.conf` | Omarchy theme path doesn't exist |
| `kitty/kitty.conf` | dropped duplicate `opacity`; kept `background_opacity 0.70` | `opacity` is not a valid option |
| `kitty/kitty.conf` | added `macos_option_as_alt yes` | required for tmux `M-Enter`/`M-Escape`/`M-Arrow` bindings |
| `kitty/kitty.conf` | commented out `listen_on …${XDG_RUNTIME_DIR}…` | macOS has no `XDG_RUNTIME_DIR`; feature was Omarchy/Hyprland cwd lookup |
| `shell/bashrc`, `zshrc` | removed Omarchy sourcing; added MacPorts PATH (`/opt/local`) + `starship init` + Keychain read | the Omarchy files don't exist on macOS |
| `tmux/tmux.conf` | unchanged | portable; `tmux-256color` is present on Tahoe |
| `starship.toml` | unchanged | portable |
| `tmuxinator/myproject.yml` | generic placeholder | original project name/paths replaced; edit `root:` |

---

## Dependencies installed (and why)

| Tool | MacPorts port | Used by |
|------|---------------|---------|
| Neovim 0.12.x | `neovim` | LazyVim (requires ≥ 0.11.2) |
| ripgrep / fd / fzf | `ripgrep` `fd` `fzf` | Telescope/search, file finding |
| lazygit | `lazygit` | LazyVim `<leader>gg`, neo-tree git |
| tree-sitter CLI | `tree-sitter-cli` | `nvim-treesitter` parser builds |
| Node 22 / Python 3.12 | `nodejs22` `python312` | many LSPs, formatters |
| Go | `go` | `gopls`, `goimports`, `gofumpt` |
| tmux | `tmux` | tmux config + vim-tmux-navigator |
| starship | `starship` | prompt |
| git | `git` | plugin cloning |
| kitty | `kitty` | terminal (port may lag upstream by a release; `kitty --version`) |
| Java 17 (optional) | `openjdk17` | `jdtls` |

LSP servers, formatters, and linters are installed on demand by **mason** on
first use (x86_64 binaries select correctly on Intel).

---

## Known macOS / Intel gotchas

- **Fonts have no MacPorts port.** `bootstrap.sh` downloads `MapleMono-NF.zip`
  into `~/Library/Fonts` and runs `xattr -cr`. If kitty shows boxes, re-run:
  `xattr -cr ~/Library/Fonts/MapleMono-NF*.ttf` and restart kitty.
- **`tmuxinator` is not in MacPorts** — install the gem or use tmuxp (step 5).
- **`~/.tmux.conf` shadows the config** — macOS tmux prefers `~/.tmux.conf`
  over `~/.config/tmux/tmux.conf`. Ensure no stale `~/.tmux.conf` exists.
- **markdown-preview blank / prints a Node version** — run:
  `cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app && npm install`.
- **Clipboard** — Neovim uses `pbcopy`/`pbpaste` natively; inside tmux the
  bundled `remote_clipboard.lua` also emits OSC 52. If paste is empty, check
  kitty's `clipboard_control` and tmux `set-clipboard`.
- **Java LSP** — `jdtls` needs a JDK; `openjdk17` is installed by `bootstrap.sh`.
- **MacPorts build lag** — if a port fails to fetch a binary, try
  `sudo port sync && sudo port install <port>` (it may build from source).
- **Intel + Mason** — x86_64 is the well-supported path; the arm64-only
  `hadolint` bug does not apply.

---

## Not migrated (by design)

- **Omarchy theme system / Hyprland / quickshell / waybar** — Linux desktop only.
  The current theme's colours are baked into `nvim/lua/plugins/theme.lua` and
  `kitty/theme.conf`.
- **mise-managed toolchains** — a `~/.config/mise` existed on the Linux box. If
  you rely on it, install `mise` and recreate `mise.toml`; otherwise the ports
  above cover the essentials.
- **alacritty / ghostty configs** — present on the Linux box but not requested.
- **opencode / oh-my-pi (`PIG_HOME`)** — separate tools; recreate separately.

---

## Keeping it in sync

```bash
cd ~/mac-setup
git add -A && git commit -m "chore: tweak" && git push
```

`~/.config/nvim` is a symlink into this repo, so `:Lazy` updates
`dotfiles/nvim/lazy-lock.json` here automatically — commit it to pin versions.

---

## Keep company / machine-specific data out of git

This repo is pushed to a remote. Before every push, review:

```bash
git status
git diff --cached
```

**Never commit:** real tmuxinator projects (only the `myproject.yml` placeholder
is tracked — other `dotfiles/tmuxinator/*.yml` are gitignored), API keys (use
the Keychain; see `SECRETS.md`), internal hostnames, project names, ticket IDs,
customer data, or internal URLs.

If company data is ever committed, removing it in a later commit is **not**
enough — it stays in history. Rewrite history (`git filter-branch` /
`git filter-repo`) and force-push, or delete and recreate the repo for a
guaranteed purge.

