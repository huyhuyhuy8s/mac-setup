# Secrets

These API keys existed on the Linux machine as plaintext files. On macOS they
belong in the **Keychain** (recommended). The shell rc files read Keychain
first and fall back to a plaintext file, so you can use either.

| Secret | Keychain service | Fallback file | Used by |
|--------|------------------|---------------|---------|
| OpenRouter API key | `openrouter-key` | `~/.secrets/openrouter-key` | `~/.zshrc` / `~/.bashrc` → `$OPENROUTER_API_KEY` |
| OpenCode Go key | `opencode-go-key` | `~/.secrets/opencode-go-key` | opencode tooling (reads it itself) |
| Context7 API key | `context7-key` | `~/.secrets/context7-key` | OpenCode MCP header (`{file:…}`), Claude Code (`${CONTEXT7_API_KEY}`), Codex |

The repo **never** contains the key values. `.gitignore` excludes `*.key`,
`*-key`, `.secrets/`, and `secrets/`.

---

## Option A — Keychain (recommended)

Create the items. `-w` at the **end with no value** makes `security` prompt
interactively, so the secret never lands in shell history or `ps` output.
`-U` updates in place if the item already exists.

```bash
# OpenRouter key
/usr/bin/security add-generic-password -a "$USER" -s openrouter-key -U \
  -l "OpenRouter API key" -T /usr/bin/security -w

# OpenCode Go key
/usr/bin/security add-generic-password -a "$USER" -s opencode-go-key -U \
  -l "OpenCode Go key" -T /usr/bin/security -w

# Context7 API key (used by the opencode/claude/codex MCPs)
/usr/bin/security add-generic-password -a "$USER" -s context7-key -U \
  -l "Context7 API key" -T /usr/bin/security -w
```

Each command prompts:

```
password data for new item:
retype password for new item:
```

Verify / read back (prints only the value):

```bash
/usr/bin/security find-generic-password -a "$USER" -s openrouter-key -w
```

Update later: re-run the same `add-generic-password -U … -w` command.
Delete:

```bash
/usr/bin/security delete-generic-password -a "$USER" -s openrouter-key
```

### Notes / gotchas

- `-T /usr/bin/security` puts `security` itself in the item's ACL, so the
  rc-file read does not pop a GUI "allow access" dialog. If you ever do see a
  dialog, click **Always Allow**.
- The login keychain is unlocked automatically after a **GUI login**. In a
  **pure SSH session** (or before first unlock) it can be locked and the read
  fails silently — the wrapper then falls back to the file. If you use SSH a
  lot, consider a keychain-unlock helper to unlock once per login, or use
  Option B (plaintext file).
- Reads run once per interactive shell (~5–20 ms when unlocked), and the
  wrapper exports nothing when the value is missing.

---

## Option B — plaintext file (fallback)

Only if you prefer not to use Keychain. The rc wrapper reads these if Keychain
has no item.

```bash
mkdir -p ~/.secrets && chmod 700 ~/.secrets

# Paste each key without a trailing newline:
printf '%s' 'PASTE_OPENROUTER_KEY_HERE' > ~/.secrets/openrouter-key
printf '%s' 'PASTE_OPENCODE_GO_KEY_HERE' > ~/.secrets/opencode-go-key
printf '%s' 'PASTE_CONTEXT7_KEY_HERE' > ~/.secrets/context7-key

chmod 600 ~/.secrets/*-key
```

Sanity check:

```bash
source ~/.zshrc && [ -n "$OPENROUTER_API_KEY" ] && echo "OPENROUTER_API_KEY is set"
```
