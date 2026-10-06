# Manual install (no repo access)

If the internal Mac can't reach your personal GitHub, you don't need it. The
whole environment is reproduced by **`manual-install.sh`** — one self-contained
script of `write_file` heredocs plus the **MacPorts** commands. No clone, no
external config files, nothing from this repo at runtime.

The only external fetches are: **MacPorts ports** and, on first `nvim` launch,
**upstream plugin repos** (LazyVim, Telescope, …) — not your personal repo.

> You will need a second screen/device showing `manual-install.sh` while you
> type on the Mac. Read-only is fine; never run the script anywhere but the Mac.

---

## Route A — type one script (full parity)

**1. On the Mac, create the file and type its contents.**

```bash
mkdir -p ~/setup && cd ~/setup
nvim manual-install.sh      # or: nano manual-install.sh
```

Type the entire contents of `manual-install.sh` (1,600+ lines). It is organised
as independent blocks:

- the Xcode + MacPorts section at the top,
- one `write_file "$HOME/..." <<'MANUAL_EOF' … MANUAL_EOF` block per config file,
- a final tmux-plugin clone.

**2. Syntax-check, then run.**

```bash
bash -n manual-install.sh              # catch typos first
bash manual-install.sh                 # ports + write all configs
```

- To write configs only and skip ports: `INSTALL_PORTS=0 bash manual-install.sh`
- Existing files are backed up to `<file>.bak.<timestamp>` before being written.
- The port section needs `sudo` and a prior MacPorts install.

**3. Open a NEW terminal and run `nvim`.** LazyVim installs the plugins.

---

## Route B — less typing (recommended)

Let MacPorts and LazyVim provide the bulk, and type only *your* custom files.

**1. Prerequisites: Xcode CLT + MacPorts.**

```bash
xcode-select --install
# Install MacPorts itself first: download the macOS 26 (Tahoe) .pkg from
#   https://www.macports.org/install.php
# open it and follow the installer, then:
sudo port selfupdate
```

**2. Install the ports.**

```bash
sudo port install neovim ripgrep fd fzf lazygit tree-sitter-cli \
  nodejs22 python312 go tmux starship git kitty

sudo port select --set python3 python312
sudo port select --set nodejs  nodejs22

# optional: Java LSP
sudo port install openjdk17

# tmuxinator is NOT in MacPorts — pick one:
sudo port install ruby34 && sudo gem install tmuxinator
# or: sudo port install py312-tmuxp
```

**3. Install the Maple Mono NF font** (no MacPorts port exists).

```bash
# Download MapleMono-NF.zip from:
#   https://github.com/subframe7536/maple-font/releases
mkdir -p ~/Library/Fonts
unzip -o MapleMono-NF.zip -d ~/Library/Fonts/
xattr -cr ~/Library/Fonts/MapleMono-NF*.ttf      # required for kitty to find it
```

**4. Grab the upstream LazyVim starter** (this is LazyVim's repo, not yours).

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

**5. Type only the custom files** (each is a separate `MANUAL_EOF` block in
`manual-install.sh`).

| Type this | Block in `manual-install.sh` |
|-----------|------------------------------|
| `~/.config/nvim/init.lua` | `write_file $HOME/.config/nvim/init.lua` |
| `~/.config/nvim/lazyvim.json` | **the 16 extras list — don't skip** |
| `~/.config/nvim/.neoconf.json` | tiny |
| `~/.config/nvim/stylua.toml` | tiny |
| `~/.config/nvim/lua/config/lazy.lua` | imports the extras + your plugins |
| `~/.config/nvim/lua/config/options.lua` | tabstop + remote clipboard |
| `~/.config/nvim/lua/config/remote_clipboard.lua` | cross-platform clipboard |
| `~/.config/nvim/lua/config/autocmds.lua` | 8 lines |
| `~/.config/nvim/lua/config/keymaps.lua` | 3 lines |
| `~/.config/nvim/lua/plugins/*.lua` | the plugin set |
| `~/.config/nvim/plugin/after/transparency.lua` | transparency |
| `~/.bashrc`, `~/.zshrc`, `~/.bash_profile` | shell |
| `~/.config/tmux/tmux.conf` | tmux |
| `~/.config/kitty/kitty.conf`, `~/.config/kitty/theme.conf` | kitty |
| `~/.config/starship.toml` | prompt |
| `~/.config/tmuxinator/myproject.yml` | placeholder project |

**Skip** (safe to omit): `lazy-lock.json` (LazyVim regenerates it),
`LICENSE`, `README.md`, `.gitignore`, and `lua/plugins/example.lua`.

**6. Recreate the tmux plugin** the config `run`s directly:

```bash
mkdir -p ~/.config/tmux/plugins
git clone --depth 1 https://github.com/christoomey/vim-tmux-navigator \
  ~/.config/tmux/plugins/vim-tmux-navigator
```

---

## Trim the typing further (lean nvim)

| File | Lines | Keep? |
|------|-------|-------|
| `all-themes.lua` | ~100 | only if you want the extra colourschemes |
| `example.lua` | ~197 | no — LazyVim template |
| `theme.lua` | ~50 | keep (sets the `aether` colourscheme) |
| `harpoon.lua`, `neoclip.lua`, `nvim-ufo.lua`, `undotree.lua`, `telescope.lua`, `snacks*.lua` | — | keep for full parity |

Skipping `all-themes.lua` and `example.lua` removes ~300 lines with no
functional loss beyond unused colourschemes.

---

## Secrets (Keychain)

```bash
/usr/bin/security add-generic-password -a "$USER" -s openrouter-key -U \
  -l "OpenRouter API key" -T /usr/bin/security -w      # prompts; never in history
/usr/bin/security add-generic-password -a "$USER" -s opencode-go-key -U \
  -l "OpenCode Go key" -T /usr/bin/security -w
```

The shell rc reads Keychain first and falls back to `~/.secrets/<service>`.
See `SECRETS.md`.

---

## Verify

```bash
nvim --version            # 0.12.x
tmux -V
kitty --version
starship --version
infocmp tmux-256color >/dev/null && echo "terminfo OK"
```

Then open a NEW terminal and run `nvim`, followed by `:LazyHealth` and
`:checkhealth`. Option+Enter in kitty should split a tmux pane.

---

## What `manual-install.sh` does

- Writes **42 config files** into `$HOME` (backing up any existing real file).
- Installs MacPorts ports, selects python3/nodejs, installs the Maple Mono NF
  font, and adds `tmux-256color` only if missing — unless `INSTALL_PORTS=0`.
- Clones the tmux `vim-tmux-navigator` plugin.
- **Skips** `lazy-lock.json`, `LICENSE`, `README.md`, `.gitignore`.
- Normalises a trailing newline on the two files that lacked one.

Regenerate it from the bundle any time with:

```bash
tools/gen-manual.sh
```

---

## Avoiding the typing altogether

If that is too much, once the Mac can reach **any** approved source (a
company-internal git host, an MDM-deployed package, or an approved file
transfer), push this folder there and clone it — `install.sh` then does the
symlinking as designed. The hand-entry route exists purely for the case where
you have no approved transfer at all.
