#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

note() {
    printf 'OK: %s\n' "$1"
}

emit_bash_hook_input() {
    COMMAND_VALUE="$1" python3 -c 'import json, os; print(json.dumps({"tool": "Bash", "tool_input": {"command": os.environ["COMMAND_VALUE"]}}))'
}

search_tool() {
    if command -v rg >/dev/null 2>&1; then
        rg "$@"
    else
        grep -E "$@"
    fi
}

# ---------------------------------------------------------------------------
# Shell syntax — every shipped shell file parses cleanly
# ---------------------------------------------------------------------------
shell_files=(
    "setup.sh"
    "hooks/session-start"
    "hooks/pre-tool-bash"
    "hooks/post-tool-edit"
    "hooks/run-hook.cmd"
)

for file in "${shell_files[@]}"; do
    bash -n "$file"
done
note "shell syntax"

# ---------------------------------------------------------------------------
# Markdown relative links — every internal link in skills/ and commands/ resolves
# ---------------------------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import re
import sys

root = Path(".").resolve()
files = list(root.glob("skills/**/*.md")) + list(root.glob("commands/*.md"))
pat = re.compile(r'\[[^\]]+\]\(([^)]+)\)')
missing = []
ignore = {
    ("skills/writing-skills/anthropic-best-practices.md", "reference/finance.md"),
    ("skills/writing-skills/anthropic-best-practices.md", "reference/sales.md"),
    ("skills/writing-skills/anthropic-best-practices.md", "reference/product.md"),
    ("skills/writing-skills/anthropic-best-practices.md", "reference/marketing.md"),
}

for path in files:
    text = path.read_text(errors="ignore")
    for match in pat.finditer(text):
        target = match.group(1)
        if target.startswith(("http://", "https://", "/en/docs", "#")):
            continue
        if target.startswith(("reference/", "./", "../")):
            resolved = (path.parent / target).resolve()
        elif target.startswith("skills/"):
            resolved = (root / target).resolve()
        else:
            continue
        rel = str(path.relative_to(root))
        if (rel, target) in ignore:
            continue
        if not resolved.exists():
            missing.append(f"{rel} -> {target}")

if missing:
    print("\n".join(missing), file=sys.stderr)
    sys.exit(1)
PY
note "markdown relative links"

# ---------------------------------------------------------------------------
# Slash-command wrappers — every /command referenced by a skill exists
# ---------------------------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import sys
import re

root = Path(".").resolve()
command_names = {p.stem for p in (root / "commands").glob("*.md")}
pat = re.compile(r'`/([a-z][a-z0-9-]+)`')
missing = []

for rel_path in (
    "skills/review-team/SKILL.md",
    "skills/launch-team/SKILL.md",
    "skills/incident-team/SKILL.md",
):
    path = root / rel_path
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    for command in pat.findall(text):
        if command not in command_names:
            missing.append(f"{path.relative_to(root)} -> /{command}")

if missing:
    print("\n".join(sorted(set(missing))), file=sys.stderr)
    sys.exit(1)
PY
note "slash-command wrappers"

# ---------------------------------------------------------------------------
# Built-in command name collisions — our custom names must not shadow built-ins
# ---------------------------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import sys

root = Path(".").resolve()

claude_reserved = {
    "add-dir", "agents", "allowed-tools", "android", "app", "autofix-pr", "batch",
    "branch", "btw", "bug", "checkpoint", "chrome", "claude-api", "clear", "color",
    "compact", "config", "context", "continue", "copy", "cost", "debug", "desktop",
    "diff", "doctor", "effort", "exit", "export", "extra-usage", "fast", "feedback",
    "fork", "help", "hooks", "ide", "init", "insights", "install-github-app",
    "install-slack-app", "ios", "keybindings", "login", "logout", "loop", "mcp",
    "memory", "mobile", "model", "passes", "permissions", "plan", "plugin",
    "powerup", "pr-comments", "privacy-settings", "quit", "rc", "release-notes",
    "reload-plugins", "remote-control", "remote-env", "rename", "reset", "resume",
    "review", "rewind", "sandbox", "schedule", "security-review", "settings",
    "setup-bedrock", "setup-vertex", "simplify", "skills", "stats", "status",
    "statusline", "stickers", "tasks", "teleport", "terminal-setup", "theme", "tp",
    "ultraplan", "upgrade", "usage", "vim", "voice", "web-setup",
}

gemini_reserved = {
    "about", "agents", "auth", "bashes", "bug", "chat", "clear", "commands",
    "compress", "copy", "dir", "directory", "docs", "editor", "exit", "extensions",
    "help", "hooks", "ide", "init", "mcp", "memory", "model", "permissions", "plan",
    "policies", "privacy", "quit", "restore", "resume", "rewind", "settings",
    "setup-github", "shells", "skills", "stats", "terminal-setup", "theme", "tools",
    "upgrade", "vim",
}

checks = (
    ("Claude", {p.stem for p in (root / "commands").glob("*.md")}, claude_reserved),
    ("Gemini", {p.stem for p in (root / "gemini-commands").glob("*.toml")}, gemini_reserved),
)

conflicts = []
for cli_name, custom_names, reserved_names in checks:
    for command in sorted(custom_names & reserved_names):
        conflicts.append(f"{cli_name}: /{command}")

if conflicts:
    print("\n".join(conflicts), file=sys.stderr)
    sys.exit(1)
PY
note "built-in command name collisions"

# ---------------------------------------------------------------------------
# setup.sh — Antigravity IDE config is detected even without a PATH launcher
# ---------------------------------------------------------------------------
setup_home="$(mktemp -d "${TMPDIR:-/tmp}/ai-smoke-home.XXXXXX")"
mkdir -p "$setup_home/.gemini/antigravity"
setup_output="$(HOME="$setup_home" PATH="/usr/bin:/bin" ./setup.sh --dry-run 2>&1)"
rm -rf "$setup_home"
printf '%s' "$setup_output" | search_tool -q '\.gemini/antigravity/skills' || fail "setup.sh did not detect Antigravity IDE config without PATH launcher"
note "setup.sh Antigravity IDE config detection"

# ---------------------------------------------------------------------------
# post-tool-edit hook — Java logger + var checks fire on bad code
# ---------------------------------------------------------------------------
todo_dir="$(mktemp -d "${TMPDIR:-/tmp}/ai-smoke-java.XXXXXX")"
java_file="$todo_dir/SmokeTest.java"
cat >"$java_file" <<'EOF'
class SmokeTest {
  void x() {
    System.out.println("x");
  }
}
EOF
hook_output="$(printf '{"tool":"Edit","tool_input":{"file_path":"%s"}}' "$java_file" | hooks/post-tool-edit 2>&1 || true)"
rm -rf "$todo_dir"
printf '%s' "$hook_output" | search_tool -q 'System\.out\.println' || fail "post-tool-edit Java logger check did not trigger"
note "post-tool-edit hook checks"

# ---------------------------------------------------------------------------
# pre-tool-bash hook — force push, protected branch, rm -rf, /etc writes
# ---------------------------------------------------------------------------
emit_bash_hook_input 'git push --force origin HEAD' | hooks/pre-tool-bash >/tmp/ai-smoke-pretool.out 2>&1 && fail "pre-tool-bash did not block force push"
grep -q 'BLOCKED: Force push detected.' /tmp/ai-smoke-pretool.out || fail "pre-tool-bash block message missing"
note "pre-tool-bash force-push block"

commit_repo="$(mktemp -d "${TMPDIR:-/tmp}/ai-smoke-repo.XXXXXX")"
git -C "$commit_repo" init -b main >/dev/null 2>&1
git -C "$commit_repo" config user.name "AI Smoke Test"
git -C "$commit_repo" config user.email "ai-smoke@example.com"
printf 'x\n' > "$commit_repo/test.txt"
git -C "$commit_repo" add test.txt >/dev/null 2>&1
git -C "$commit_repo" -c commit.gpgsign=false commit -m "init" >/dev/null 2>&1
printf 'y\n' >> "$commit_repo/test.txt"
emit_bash_hook_input "git -C ${commit_repo} commit -am test" | hooks/pre-tool-bash >/tmp/ai-smoke-pretool-commit.out 2>&1 && fail "pre-tool-bash did not block protected-branch commit"
grep -q "BLOCKED: Direct commit on protected branch 'main' detected." /tmp/ai-smoke-pretool-commit.out || fail "pre-tool-bash protected-branch block message missing"
rm -rf "$commit_repo"
note "pre-tool-bash protected-branch commit block"

printf 'not-json' | hooks/pre-tool-bash >/tmp/ai-smoke-pretool-parse.out 2>&1 && fail "pre-tool-bash did not fail closed on invalid input"
grep -q 'BLOCKED: Could not parse Bash hook input.' /tmp/ai-smoke-pretool-parse.out || fail "pre-tool-bash parse-failure block message missing"
note "pre-tool-bash parse failure block"

emit_bash_hook_input 'rm -rf -- /' | hooks/pre-tool-bash >/tmp/ai-smoke-pretool-rm.out 2>&1 && fail "pre-tool-bash did not block rm -rf -- /"
grep -q 'BLOCKED: Catastrophic rm -rf detected targeting / or ~.' /tmp/ai-smoke-pretool-rm.out || fail "pre-tool-bash rm -- block message missing"
note "pre-tool-bash rm -- block"

emit_bash_hook_input 'tee -a /etc/hosts' | hooks/pre-tool-bash >/tmp/ai-smoke-pretool-tee.out 2>&1 && fail "pre-tool-bash did not block tee -a /etc/hosts"
grep -q 'BLOCKED: Attempted write to system directory (/etc/ or /usr/).' /tmp/ai-smoke-pretool-tee.out || fail "pre-tool-bash tee flag block message missing"
note "pre-tool-bash tee flag block"

printf '\nAll AI asset smoke tests passed.\n'
