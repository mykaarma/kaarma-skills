#!/usr/bin/env bash
set -euo pipefail

# skills installer
#
# Symlinks (or copies) skills, agents, hooks, commands, and engineering-principles
# files into each detected CLI's config directory.
#
# Detected CLIs:
#   claude        — Claude Code            → ~/.claude/{skills,agents,hooks,commands,CLAUDE.md,AGENTS.md}
#   codex         — OpenAI Codex CLI       → ~/.codex/{skills,AGENTS.md}
#   gemini        — Google Gemini CLI      → ~/.gemini/{skills,commands,GEMINI.md}
#   cursor        — Cursor                 → ~/.cursor/skills/
#   antigravity   — Google Antigravity IDE → ~/.gemini/{antigravity-ide,config}/skills/
#
# Flags:
#   --copy        copy instead of symlink (Windows-friendly, slower updates)
#   --dry-run     print what would change without touching anything
#   --help        show usage

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_TS="$(date +%Y%m%d-%H%M%S)"

MODE="symlink"
DRY_RUN=false

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; }
action() { $DRY_RUN && echo -e "${YELLOW}[DRY-RUN]${NC} $1" || echo -e "${GREEN}[OK]${NC} $1"; }

usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --copy)    MODE="copy"; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help|-h) usage; exit 0 ;;
        *)         error "Unknown flag: $1"; usage; exit 1 ;;
    esac
done

is_windows() {
    [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || "$OSTYPE" == mingw* ]]
}

if is_windows && [ "$MODE" = "symlink" ]; then
    warn "Windows detected — switching to --copy mode (symlinks are unreliable on Windows)."
    MODE="copy"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Backup an existing non-symlink target into $backup_dir/.
maybe_backup() {
    local target="$1" backup_dir="$2"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        $DRY_RUN && { action "would back up $target → $backup_dir/"; return; }
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/"
        info "Backed up $(basename "$target") → $backup_dir/"
    fi
}

# Replace any existing target at $1 with a link or copy from $2.
install_path() {
    local target="$1" source="$2"

    if $DRY_RUN; then
        action "would install $source → $target ($MODE)"
        return
    fi

    [ -L "$target" ] && rm "$target"
    [ -d "$target" ] && [ ! -L "$target" ] && rm -rf "$target"
    [ -f "$target" ] && [ ! -L "$target" ] && rm "$target"

    if [ "$MODE" = "copy" ]; then
        if [ -d "$source" ]; then
            cp -r "$source" "$target"
        else
            cp "$source" "$target"
        fi
    else
        ln -s "$source" "$target"
    fi
    info "$source → $target"
}

# Cursor doesn't follow directory symlinks, so each skill is copied individually.
install_skills_as_copies() {
    local dest_dir="$1"
    mkdir -p "$dest_dir"
    local copied=0
    shopt -s nullglob
    for skill_dir in "$REPO_DIR/skills"/*/; do
        local skill_name
        skill_name="$(basename "$skill_dir")"
        if $DRY_RUN; then
            action "would copy $skill_name → $dest_dir/$skill_name"
        else
            rm -rf "$dest_dir/$skill_name"
            cp -r "$skill_dir" "$dest_dir/$skill_name"
        fi
        copied=$((copied + 1))
    done
    shopt -u nullglob
    info "$copied skills → $dest_dir/"
}

mark_hooks_executable() {
    if $DRY_RUN; then
        action "would chmod +x hooks in $REPO_DIR/hooks/"
        return
    fi
    for f in "$REPO_DIR/hooks"/session-start "$REPO_DIR/hooks"/pre-tool-bash "$REPO_DIR/hooks"/post-tool-edit; do
        [ -f "$f" ] && chmod +x "$f"
    done
    [ -f "$REPO_DIR/scripts/smoke-test-ai-assets.sh" ] && chmod +x "$REPO_DIR/scripts/smoke-test-ai-assets.sh"
    info "marked hooks and scripts executable"
}

# ---------------------------------------------------------------------------
# CLI installers
# ---------------------------------------------------------------------------

setup_claude() {
    echo "--- Claude Code ---"
    if ! command -v claude >/dev/null 2>&1; then
        warn "claude not found — skipping. Install: https://docs.anthropic.com/en/docs/claude-code"
        echo ""
        return
    fi
    info "claude found"

    local dir="$HOME/.claude"
    local backup_dir="$dir/backup-$BACKUP_TS"
    mkdir -p "$dir"

    for item in skills agents hooks commands CLAUDE.md AGENTS.md; do
        maybe_backup "$dir/$item" "$backup_dir"
    done
    for item in skills agents hooks commands CLAUDE.md AGENTS.md; do
        install_path "$dir/$item" "$REPO_DIR/$item"
    done
    echo ""
}

setup_codex() {
    echo "--- Codex CLI ---"
    if ! command -v codex >/dev/null 2>&1; then
        warn "codex not found — skipping. Install: npm install -g @openai/codex"
        echo ""
        return
    fi
    info "codex found"

    local dir="$HOME/.codex"
    local backup_dir="$dir/backup-$BACKUP_TS"
    mkdir -p "$dir"

    for item in skills AGENTS.md; do
        maybe_backup "$dir/$item" "$backup_dir"
    done
    for item in skills AGENTS.md; do
        install_path "$dir/$item" "$REPO_DIR/$item"
    done
    echo ""
}

setup_gemini() {
    echo "--- Gemini CLI ---"
    if ! command -v gemini >/dev/null 2>&1; then
        warn "gemini not found — skipping. Install: npm install -g @google/gemini-cli"
        echo ""
        return
    fi
    info "gemini found"

    local dir="$HOME/.gemini"
    local backup_dir="$dir/backup-$BACKUP_TS"
    mkdir -p "$dir"

    maybe_backup "$dir/GEMINI.md" "$backup_dir"
    install_path "$dir/GEMINI.md" "$REPO_DIR/GEMINI.md"

    maybe_backup "$dir/skills" "$backup_dir"
    install_path "$dir/skills" "$REPO_DIR/skills"

    # Gemini reads slash commands from ~/.gemini/commands/ (TOML files in our case)
    maybe_backup "$dir/commands" "$backup_dir"
    install_path "$dir/commands" "$REPO_DIR/gemini-commands"
    echo ""
}

setup_cursor() {
    echo "--- Cursor ---"
    if ! command -v cursor >/dev/null 2>&1; then
        warn "cursor not found — skipping. In Cursor, run 'Install cursor in PATH' from the Command Palette."
        echo ""
        return
    fi
    info "cursor found"

    # Cursor doesn't follow directory symlinks — always copy individual skills.
    install_skills_as_copies "$HOME/.cursor/skills"
    echo ""
}

has_antigravity() {
    command -v antigravity >/dev/null 2>&1 && return 0
    command -v agy >/dev/null 2>&1 && return 0
    [ -d "$HOME/.gemini/antigravity-ide" ] && return 0
    [ -d "$HOME/.gemini/config" ] && return 0
    [ -d "$HOME/.gemini/antigravity" ] && return 0
    [ -d "/Applications/Antigravity.app" ] && return 0
    [ -d "/Applications/Google Antigravity.app" ] && return 0
    [ -d "$HOME/Applications/Antigravity.app" ] && return 0
    [ -d "$HOME/Applications/Google Antigravity.app" ] && return 0
    return 1
}

setup_antigravity() {
    echo "--- Antigravity ---"
    if ! has_antigravity; then
        warn "Antigravity IDE not found — skipping. Download from https://antigravity.google"
        echo ""
        return
    fi
    info "Antigravity IDE found"

    local skills_dirs=(
        "$HOME/.gemini/antigravity-ide/skills"
        "$HOME/.gemini/config/skills"
    )

    for skills_dir in "${skills_dirs[@]}"; do
        local parent_dir backup_dir
        parent_dir="$(dirname "$skills_dir")"
        backup_dir="$parent_dir/backup-$BACKUP_TS"
        mkdir -p "$parent_dir"
        maybe_backup "$skills_dir" "$backup_dir"
        install_path "$skills_dir" "$REPO_DIR/skills"
    done
    echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo ""
echo "======================================"
echo "  skills installer"
echo "======================================"
echo "  mode: $MODE$($DRY_RUN && echo ' (dry run)')"
echo ""

mark_hooks_executable
echo ""

setup_claude
setup_codex
setup_gemini
setup_cursor
setup_antigravity

echo "======================================"
if $DRY_RUN; then
    echo "  Dry run complete — no changes made."
else
    info "Setup complete!"
    echo ""
    echo "  Restart your CLI(s) to pick up the new config."
    echo "  To update later:  cd $REPO_DIR && git pull"
    if [ "$MODE" = "copy" ]; then
        echo "                   ./setup.sh --copy   # re-sync the copies"
    fi
fi
echo ""
