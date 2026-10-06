#!/usr/bin/env bash
# install-lsp.sh — pre-install every mason package this LazyVim config needs
# (LSP servers, formatters, linters, DAP adapters) on an Intel Mac, macOS 26,
# MacPorts-only.
#
# Why: LazyVim installs these on demand, which is slow and flaky the first time
# you open a file of some language. This warms them all up in one go.
#
# Idempotent: packages already installed are skipped. Re-runnable.
#
#   ./install-lsp.sh                 # runtimes (MacPorts) + all mason packages
#   SKIP_RUNTIMES=1 ./install-lsp.sh # mason packages only
set -euo pipefail

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# Package list — mason REGISTRY names (not lspconfig server names).
# Verified against github.com/mason-org/mason-registry and the enabled LazyVim
# extras (docker, go, java, json, markdown, prisma, sql, tailwind, toml,
# typescript.biome, typescript.oxc, linting.eslint, ai.copilot-native,
# lang.typescript, lang.python) plus the user's cssls.lua and example.lua.
# ---------------------------------------------------------------------------
LSP_PACKAGES=(
  lua-language-server                     # lua_ls (LazyVim base)
  css-lsp                                 # cssls        (plugins/cssls.lua)
  json-lsp                                # jsonls       (lang.json)
  tailwindcss-language-server             # tailwindcss  (lang.tailwind)
  prisma-language-server                  # prismals     (lang.prisma)
  dockerfile-language-server              # dockerls     (lang.docker)
  docker-compose-language-service         # docker_compose_language_service
  marksman                                # marksman     (lang.markdown)
  taplo                                   # taplo        (lang.toml)
  biome                                   # biome        (typescript.biome)
  oxlint                                  # oxlint       (typescript.oxc)
  gopls                                   # gopls        (lang.go)
  jdtls                                   # jdtls        (lang.java)
  vtsls                                   # vtsls        (lang.typescript)
  pyright                                 # pyright      (lang.python default)
  ruff                                    # ruff         (lang.python)
  eslint-lsp                              # eslint       (linting.eslint)
  copilot-language-server                 # copilot      (ai.copilot-native)
)

TOOL_PACKAGES=(
  # base + user's example.lua
  stylua shellcheck shfmt flake8
  # lang.go
  goimports gofumpt gomodifytags impl delve golangci-lint
  # lang.docker / lang.markdown / lang.sql / typescript.oxc
  hadolint
  markdownlint-cli2 markdown-toc
  sqlfluff
  oxfmt
  prettier
  # debug adapters
  java-debug-adapter java-test js-debug-adapter debugpy
)

PACKAGES=("${LSP_PACKAGES[@]}" "${TOOL_PACKAGES[@]}")

# ---------------------------------------------------------------------------
# 1. Language runtimes mason's installers rely on (MacPorts).
#    jdtls -> JDK; npm-based LSPs -> node; pip-based tools -> python; go tools -> go.
# ---------------------------------------------------------------------------
if [ "${SKIP_RUNTIMES:-0}" != "1" ]; then
  if [ -x /opt/local/bin/port ] || command -v port >/dev/null 2>&1; then
    export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
    say "Installing language runtimes via MacPorts (go, node, python, jdk)..."
    sudo port install go nodejs22 python312 openjdk17 || \
      warn "Some runtimes failed to install; some packages may not work."
    sudo port select --set python3 python312 >/dev/null 2>&1 || true
    sudo port select --set nodejs  nodejs22  >/dev/null 2>&1 || true
  else
    warn "MacPorts not found (/opt/local/bin/port). Skipping runtimes; continuing."
  fi
fi

# ---------------------------------------------------------------------------
# 2. Neovim itself + the plugins must exist before mason can run.
# ---------------------------------------------------------------------------
if ! command -v nvim >/dev/null 2>&1; then
  echo "ERROR: nvim not found. Run ./bootstrap.sh (or sudo port install neovim) first." >&2
  exit 1
fi

say "Syncing LazyVim plugins..."
nvim --headless "+Lazy! sync" +qa || warn "Lazy sync reported an issue (continuing)."

# ---------------------------------------------------------------------------
# 3. Install the mason packages headlessly and wait until finished.
# ---------------------------------------------------------------------------
say "Installing ${#PACKAGES[@]} mason packages (Intel x86_64)..."
export MASON_PACKAGES="${PACKAGES[*]}"

lua_script="$(mktemp)"
trap 'rm -f "$lua_script"' EXIT
cat > "$lua_script" <<'LUA'
local names = vim.split(vim.env.MASON_PACKAGES or "", "%s+", { trimempty = true })

-- mason.nvim is lazy-loaded in LazyVim; load it explicitly so :MasonInstall exists.
require("lazy").load({ plugins = { "mason.nvim" } })

local ok_reg, registry = pcall(require, "mason-registry")
if not ok_reg then
  print("ERROR: mason-registry unavailable. Is mason.nvim installed?")
  vim.cmd("cquit")
end

local missing, unknown = {}, {}
for _, name in ipairs(names) do
  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    unknown[#unknown + 1] = name
  elseif not pkg:is_installed() then
    missing[#missing + 1] = name
  end
end

if #unknown > 0 then
  print("Unknown mason packages: " .. table.concat(unknown, ", "))
end
if #missing == 0 then
  print("All " .. #names .. " packages already installed.")
  if #unknown > 0 then vim.cmd("cquit") end
  return
end

print("Installing " .. #missing .. ": " .. table.concat(missing, " "))
vim.cmd("MasonInstall " .. table.concat(missing, " "))

local function all_installed()
  for _, name in ipairs(missing) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok or not pkg:is_installed() then return false end
  end
  return true
end

-- Wait up to 1 hour; vim.wait pumps the event loop so async installs progress.
if vim.wait(60 * 60 * 1000, all_installed, 1000) then
  print("DONE: all packages installed.")
  if #unknown > 0 then vim.cmd("cquit") end
else
  local still = {}
  for _, name in ipairs(missing) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok or not pkg:is_installed() then still[#still + 1] = name end
  end
  print("INCOMPLETE: " .. table.concat(still, ", "))
  vim.cmd("cquit")
end
LUA

nvim --headless "+luafile $lua_script" "+qa"

say "Done. Open nvim and run :Mason to review, or :LazyHealth to check health."
