#!/usr/bin/env bash
# install-skills.sh — install the agent-skill sets from the Linux machine onto
# an Intel Mac (macOS 26, MacPorts), via the `skills` CLI (npm `skills`).
#
# The CLI installs to ~/.agents/skills and symlinks each skill into the global
# skills dir of every targeted agent (OpenCode, Claude Code, Codex, ...).
#
#   ./install-skills.sh                      # install all sources to default agents
#   AGENTS="opencode" ./install-skills.sh    # only OpenCode
#   LIST_ONLY=1 ./install-skills.sh          # list what each source offers
set -euo pipefail

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# Sources (owner/repo). Derived from ~/.agents/.skill-lock.json and the
# 36 untracked skills on the source machine (all from mattpocock/skills).
# ---------------------------------------------------------------------------
SOURCES=(
  mattpocock/skills          # ask-matt, grilling, grill-me/with-docs, wayfinder,
                             # to-spec, to-tickets, implement, tdd, code-review,
                             # triage, handoff, prototype, research, domain-modeling, ...
  anthropics/skills          # skill-creator, pdf, ...
  vercel-labs/skills         # find-skills, ...
  JuliusBrussee/caveman      # caveman, compress, caveman-commit/review/help/...
  humanizerai/agent-skills   # humanize, cold-email, follow-up, readability, ...
  greensock/gsap-skills      # gsap-core/plugins/react/scrolltrigger/... (optional)
)

# Global agents to link into. Override with AGENTS="opencode claude-code codex".
if [ -n "${AGENTS:-}" ]; then
  read -r -a AGENT_LIST <<< "$AGENTS"
else
  AGENT_LIST=(opencode claude-code codex)
fi

# ---------------------------------------------------------------------------
# Node >= 22.20 is required by the skills CLI.
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node not found. Run ./bootstrap.sh (installs nodejs22) first." >&2
  exit 1
fi
major=$(node -p 'process.versions.node.split(".")[0]')
minor=$(node -p 'process.versions.node.split(".")[1]')
if [ "$major" -lt 22 ] || { [ "$major" -eq 22 ] && [ "$minor" -lt 20 ]; }; then
  warn "node $(node -v) is older than 22.20; the skills CLI may not run."
  warn "Update with: sudo port install nodejs22 && sudo port select --set nodejs nodejs22"
fi

say "skills CLI: npx -y skills (global install to ~/.agents/skills)"
say "Target agents: ${AGENT_LIST[*]}"

if [ "${LIST_ONLY:-0}" = "1" ]; then
  for src in "${SOURCES[@]}"; do
    say "=== $src ==="
    npx -y skills add "$src" --list || warn "list failed: $src"
  done
  exit 0
fi

for src in "${SOURCES[@]}"; do
  say "Installing skills from $src ..."
  # -g global, -y no prompts, -s '*' all skills, -a target agents
  npx -y skills add "$src" -g -y -s '*' -a "${AGENT_LIST[@]}" \
    || warn "failed: $src (continuing)"
done

say "Done."
cat <<'EOF'

Skills live in ~/.agents/skills  (lockfile: ~/.agents/.skill-lock.json)
Inspect with:   npx -y skills list -g
Update later:   re-run this script (it re-adds/updates each source)

Not covered by these upstream sources (they were custom/system on the Linux box):
  context7-mcp, opencode-zen-models, omarchy, diagnose-crash, ponytail
EOF
