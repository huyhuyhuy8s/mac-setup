-- Cross-platform remote clipboard for yanks that must reach another machine.
--
-- Every copy is also emitted as OSC 52 (inside tmux this becomes a tmux buffer,
-- rebroadcast to every attached client, local or SSH). Paste prefers a native
-- clipboard when one is available (macOS pbcopy/pbpaste, Linux/Wayland
-- wl-copy/wl-paste); otherwise it falls back to an OSC 52 query that tmux (or
-- the terminal) answers.
--
-- Platform notes:
--   * macOS: uses pbcopy/pbpaste. /proc is unavailable, so the Linux-only
--     ancestor-process probe is skipped.
--   * Linux/Wayland: uses wl-copy/wl-paste when a display is present.
local M = {}

local has_mac = vim.fn.has("mac") == 1
local has_linux = vim.fn.has("linux") == 1

-- Linux-only: walk the process ancestry looking for a process name.
local function proc_lines(pid, file)
  local ok, lines = pcall(vim.fn.readfile, "/proc/" .. pid .. "/" .. file)
  return ok and lines or {}
end

local function proc_ppid(pid)
  for _, line in ipairs(proc_lines(pid, "status")) do
    local ppid = line:match("^PPid:%s+(%d+)")
    if ppid then
      return tonumber(ppid)
    end
  end
end

local function ancestor_process_named(name)
  if not has_linux then
    return false
  end

  local pid = vim.fn.getpid()

  for _ = 1, 16 do
    local ppid = proc_ppid(pid)
    if not ppid or ppid <= 1 then
      return false
    end

    local comm = proc_lines(ppid, "comm")[1] or ""
    if comm:find(name, 1, true) then
      return true
    end

    pid = ppid
  end

  return false
end

-- Native (non-OSC52) clipboard commands for this platform, or nil.
local function native_clipboard()
  if has_mac then
    return {
      copy = { ["+"] = { "pbcopy" }, ["*"] = { "pbcopy" } },
      paste = { ["+"] = { "pbpaste" }, ["*"] = { "pbpaste" } },
    }
  end

  local has_wayland = vim.env.WAYLAND_DISPLAY ~= nil
    and vim.fn.executable("wl-copy") == 1
    and vim.fn.executable("wl-paste") == 1

  if has_wayland then
    return {
      copy = {
        ["+"] = { "wl-copy", "--sensitive", "--type", "text/plain" },
        ["*"] = { "wl-copy", "--sensitive", "--type", "text/plain", "--primary" },
      },
      paste = {
        ["+"] = { "wl-paste", "--no-newline" },
        ["*"] = { "wl-paste", "--no-newline", "--primary" },
      },
    }
  end

  return nil
end

local function osc52_enabled()
  return vim.g.remote_clipboard_osc52 ~= false
    and vim.g.omarchy_remote_clipboard_osc52 ~= false
end

function M.setup()
  local in_tmux = vim.env.TMUX ~= nil
  local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
  local in_herdr = vim.env.HERDR_PANE_ID ~= nil or ancestor_process_named("herdr")

  if not (in_tmux or in_ssh or in_herdr) then
    return
  end

  local osc52 = require("vim.ui.clipboard.osc52")
  local native = native_clipboard()

  local function copy(register)
    local emit = osc52.copy(register)

    return function(lines)
      if native then
        vim.fn.system(native.copy[register], lines)
      end

      if osc52_enabled() then
        emit(lines)
      end
    end
  end

  local function paste(register)
    if not native then
      return osc52.paste(register)
    end

    return function()
      local lines = vim.fn.systemlist(native.paste[register], "", 1)
      return vim.v.shell_error == 0 and lines or {}
    end
  end

  vim.g.clipboard = {
    name = "RemoteClipboard",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
    cache_enabled = 0,
  }
end

return M
