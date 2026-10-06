#!/usr/bin/env bash
# install-mcp-skills.sh — install the **custom/system MCP servers** and the
# **non-upstream skills** on an Intel Mac (macOS 26, MacPorts).
#
# Companion to:
#   bootstrap.sh        system + MacPorts packages
#   install-lsp.sh      mason language servers
#   install-skills.sh   upstream agent skills (via the `skills` CLI)
#   install-mcp-skills.sh  <-- this: local/custom skills + MCP servers
#
# What it does:
#   1. Installs the vendored custom/system skills (dotfiles/skills/*) into
#      ~/.agents/skills and symlinks them into Claude Code, Codex and OpenCode.
#   2. Installs the MCP server prerequisites: Node >= 24 (for gsd-core),
#      codegraph, and Playwright's browsers.
#   3. Configures the MCP servers in OpenCode (~/.config/opencode/opencode.json):
#      context7, gh_grep, codegraph, playwright, gsd.
#   4. Prints the Claude Code / Codex wiring.
#
# The Context7 token is NEVER written in plaintext: the config references
#   {file:~/.secrets/context7-key}
#
#   ./install-mcp-skills.sh                 # everything
#   SKIP_PREREQS=1 ./install-mcp-skills.sh  # only skills + opencode config
#   AGENTS="opencode" ./install-mcp-skills.sh
set -euo pipefail

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO/dotfiles/skills"
CTX7_SECRET="$HOME/.secrets/context7-key"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
CANONICAL="$HOME/.agents/skills"

# ---------------------------------------------------------------------------
# 1. Custom / system skills (vendored, offline)
# ---------------------------------------------------------------------------
if [ -n "${AGENTS:-}" ]; then
  IFS=' ' read -r -a _agents <<< "$AGENTS"
else
  _agents=(claude-code codex opencode)
fi
AGENT_SKILL_DIRS=()
for a in "${_agents[@]}"; do
  case "$a" in
    claude-code) AGENT_SKILL_DIRS+=("$HOME/.claude/skills") ;;
    codex)       AGENT_SKILL_DIRS+=("$HOME/.codex/skills") ;;
    opencode)    AGENT_SKILL_DIRS+=("$HOME/.config/opencode/skills") ;;
    *) warn "unknown agent '$a' (skipping)";;
  esac
done

if [ -d "$SKILLS_SRC" ]; then
  say "Installing custom/system skills from dotfiles/skills ..."
  mkdir -p "$CANONICAL"
  for d in "$SKILLS_SRC"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    dest="$CANONICAL/$name"
    rm -rf "$dest"
    cp -RL "$d" "$dest"
    for adir in "${AGENT_SKILL_DIRS[@]}"; do
      mkdir -p "$adir"
      ln -sfn "$dest" "$adir/$name"
    done
    say "  $name  ->  ${AGENT_SKILL_DIRS[*]}"
  done
else
  warn "no $SKILLS_SRC directory; skipping custom skills"
fi

# ---------------------------------------------------------------------------
# 2. MCP prerequisites
# ---------------------------------------------------------------------------
if [ "${SKIP_PREREQS:-0}" != "1" ]; then
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

  # gsd-core requires Node >= 24; MacPorts ships versioned ports.
  node_major=0
  command -v node >/dev/null 2>&1 && node_major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$node_major" -lt 24 ]; then
    say "Installing Node 24 via MacPorts (required by @opengsd/gsd-core)..."
    if sudo port install nodejs24; then
      sudo port select --set nodejs nodejs24 || warn "port select nodejs failed"
    else
      warn "nodejs24 port unavailable; install Node >= 24 another way for the gsd MCP."
    fi
  fi

  # codegraph: standalone installer (bundles its own runtime, no Node needed).
  if ! command -v codegraph >/dev/null 2>&1; then
    say "Installing codegraph (colbymchenry/codegraph)..."
    curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh \
      || warn "codegraph install failed; the codegraph MCP will not start."
  fi

  # Playwright MCP needs the browsers downloaded once.
  say "Installing Playwright browsers (for the playwright MCP)..."
  npx -y playwright install || warn "playwright browser install failed"

  # GSD framework: the 72 `gsd-*` system skills + agents/commands/hooks.
  # Installer is per-runtime and requires Node >= 24.
  if command -v node >/dev/null 2>&1 && [ "$(node -p 'process.versions.node.split(".")[0]')" -ge 24 ]; then
    gsd_flags=()
    for a in "${_agents[@]}"; do
      case "$a" in
        claude-code) gsd_flags+=(--claude) ;;
        codex)       gsd_flags+=(--codex) ;;
        opencode)    gsd_flags+=(--opencode) ;;
      esac
    done
    if [ "${#gsd_flags[@]}" -gt 0 ]; then
      say "Installing GSD framework (skills, agents, commands, hooks)..."
      npx -y @opengsd/gsd-core@latest "${gsd_flags[@]}" --global || warn "GSD install failed"
    fi
  else
    warn "skipping GSD install (needs Node >= 24)"
  fi
fi

# ---------------------------------------------------------------------------
# 3. OpenCode MCP configuration (merged, idempotent, backed up)
# ---------------------------------------------------------------------------
say "Configuring OpenCode MCP servers..."
mkdir -p "$(dirname "$OPENCODE_CONFIG")" "$(dirname "$CTX7_SECRET")"

# Ensure the secret file exists so opencode's {file:...} interpolation resolves.
if [ ! -f "$CTX7_SECRET" ]; then
  umask 077; : > "$CTX7_SECRET"
  warn "created empty $CTX7_SECRET — put your Context7 key in it (and rotate the old one)"
fi

OPENCODE_CONFIG="$OPENCODE_CONFIG" CTX7_SECRET="$CTX7_SECRET" python3 - <<'PY'
import json, os, shutil, time

path = os.environ["OPENCODE_CONFIG"]
secret = os.environ["CTX7_SECRET"]

cfg = {}
if os.path.exists(path):
    shutil.copy2(path, f"{path}.bak-{time.strftime('%Y%m%dT%H%M%S')}")
    with open(path) as f:
        try:
            cfg = json.load(f)
        except json.JSONDecodeError:
            raise SystemExit(f"ERROR: {path} is not valid JSON; refusing to edit.")

ctx7 = {"type": "remote", "url": "https://mcp.context7.com/mcp", "enabled": True,
        "headers": {"Authorization": "Bearer {file:" + secret.replace(os.path.expanduser("~"), "~") + "}"}}

servers = {
    "context7": ctx7,
    "gh_grep":   {"type": "remote", "url": "https://mcp.grep.app", "enabled": True},
    "codegraph": {"type": "local", "command": ["codegraph", "serve", "--mcp"], "enabled": True,
                  "environment": {"CODEGRAPH_TELEMETRY": "0", "DO_NOT_TRACK": "1"}},
    "playwright": {"type": "local", "command": ["npx", "-y", "@playwright/mcp"], "enabled": True},
    "gsd":        {"type": "local", "command": ["npx", "-y", "-p", "@opengsd/gsd-core", "gsd-mcp-server"], "enabled": True},
}

mcp = cfg.get("mcp", {})
for name, spec in servers.items():
    mcp[name] = spec            # overwrite with the canonical spec
cfg["mcp"] = mcp

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print("wrote", path, "with mcp servers:", ", ".join(servers))
PY

# ---------------------------------------------------------------------------
# 4. Apply the MCP servers to Claude Code and Codex (no plaintext tokens)
# ---------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1 || [ -f "$HOME/.claude.json" ]; then
  say "Configuring Claude Code MCP servers (~/.claude.json)..."
  CLAUDE_JSON="$HOME/.claude.json" python3 - <<'PY'
import json, os, shutil, time
path = os.environ["CLAUDE_JSON"]
cfg = {}
if os.path.exists(path):
    shutil.copy2(path, f"{path}.bak-{time.strftime('%Y%m%dT%H%M%S')}")
    with open(path) as f:
        try:
            cfg = json.load(f)
        except json.JSONDecodeError:
            raise SystemExit(f"ERROR: {path} is not valid JSON; refusing to edit.")
# ${CONTEXT7_API_KEY} is expanded by Claude Code from the shell env (see SECRETS.md).
servers = {
    "context7":   {"type": "http", "url": "https://mcp.context7.com/mcp",
                   "headers": {"Authorization": "Bearer ${CONTEXT7_API_KEY}"}},
    "gh_grep":    {"type": "http", "url": "https://mcp.grep.app"},
    "codegraph":  {"command": "codegraph", "args": ["serve", "--mcp"]},
    "playwright": {"command": "npx", "args": ["-y", "@playwright/mcp"]},
    "gsd":        {"command": "npx", "args": ["-y", "-p", "@opengsd/gsd-core", "gsd-mcp-server"]},
}
m = cfg.get("mcpServers", {})
m.update(servers)
cfg["mcpServers"] = m
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print("wrote", path, "->", ", ".join(servers))
PY
fi

if command -v codex >/dev/null 2>&1; then
  say "Configuring Codex MCP servers (~/.codex/config.toml)..."
  codex mcp add codegraph  -- codegraph serve --mcp                 || warn "codex add codegraph failed"
  codex mcp add playwright -- npx -y @playwright/mcp                || warn "codex add playwright failed"
  codex mcp add gsd        -- npx -y -p @opengsd/gsd-core gsd-mcp-server || warn "codex add gsd failed"
  codex mcp add gh_grep    --url https://mcp.grep.app               || warn "codex add gh_grep failed"
  # context7 needs a bearer token; add manually (Codex rejects inline tokens):
  #   [mcp_servers.context7]
  #   url = "https://mcp.context7.com/mcp"
  #   bearer_token_env_var = "CONTEXT7_API_KEY"
fi

say "Custom/system skills: $(ls -1 "$CANONICAL" 2>/dev/null | wc -l) in $CANONICAL"
say "MCP: opencode applied; Claude Code + Codex applied where installed."
say "Context7 token: $CTX7_SECRET (exported as CONTEXT7_API_KEY by the shell rc)."
