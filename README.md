# kaarma-skills

A curated set of AI agent skills, slash commands, and safety hooks that work across multiple coding CLIs:
[Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Codex CLI](https://github.com/openai/codex),
[Gemini CLI](https://github.com/google-gemini/gemini-cli), [Cursor](https://cursor.com), and Google Antigravity.

The same content drives all five tools — install once and your AI assistants share a consistent set of patterns
for writing plans, reviewing code, debugging, brainstorming, and shipping changes.

## What's inside

| Path | Purpose |
|------|---------|
| `skills/` | Skills (folders with `SKILL.md` + optional reference docs and scripts) |
| `agents/` | Subagent definitions (e.g. `code-reviewer`) |
| `commands/` | Claude Code slash commands |
| `gemini-commands/` | Gemini CLI slash commands (TOML format) |
| `hooks/` | Shell-script safety hooks (force-push block, protected-branch block, etc.) |
| `scripts/` | Smoke tests and maintenance scripts |

## Prerequisites

Before installing this repo, set up the basic development tools for your operating system.

### GitHub

Create a GitHub account and make sure you can access the repositories you need. For practice or onboarding,
create a private `hello-world` repository and verify you can clone it locally.

### macOS

Install Apple's command-line tools, Homebrew, Git, Python 3, and Antigravity:

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
brew install git
brew install python3
git --version
python3 --version
```

For Python projects, prefer a virtual environment per project:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Download Antigravity from [antigravity.google](https://antigravity.google/product/antigravity-ide), then sign in
and connect it to GitHub when prompted. To work from Antigravity, use **Clone repository**, choose **Clone from
GitHub**, complete the GitHub authorization flow, and select the repository to clone.

### Windows

Install Git, Python 3, and Antigravity:

1. Install Git for Windows from [git-scm.com](https://git-scm.com/download/win), then verify in PowerShell:
   ```powershell
   git --version
   ```
2. Install Python 3.13 from the Microsoft Store or [python.org](https://www.python.org/downloads/windows/), then verify:
   ```powershell
   python --version
   ```
3. Download Antigravity from [antigravity.google](https://antigravity.google/product/antigravity-ide), then sign in
   and connect it to GitHub when prompted. To work from Antigravity, use **Clone repository**, choose **Clone from
   GitHub**, complete the GitHub authorization flow, and select the repository to clone.

## Install

### macOS / Linux
```bash
git clone https://github.com/mykaarma/kaarma-skills.git ~/kaarma-skills
cd ~/kaarma-skills
./setup.sh
```

### Windows (PowerShell)
```powershell
git clone https://github.com/mykaarma/kaarma-skills.git $HOME/kaarma-skills
cd $HOME/kaarma-skills
.\setup.ps1
```

The installer detects which CLIs are installed on your machine (`claude`, `codex`, `gemini`, `cursor`,
`antigravity`) and links the appropriate folders into each one's config directory:

| CLI | Config directory |
|-----|------------------|
| Claude Code | `~/.claude/{skills,agents,hooks,commands,CLAUDE.md,AGENTS.md}` |
| Codex CLI | `~/.codex/{skills,AGENTS.md}` |
| Gemini CLI | `~/.gemini/{skills,commands,GEMINI.md}` |
| Cursor | `~/.cursor/skills/` |
| Antigravity | `~/.gemini/{antigravity-ide,config}/skills/` |

On Windows, Antigravity is also detected from the usual IDE install location:
`%LOCALAPPDATA%\Programs\Antigravity IDE\Antigravity IDE.exe`.

By default the installer creates symlinks so `git pull` automatically updates every CLI. Pass `--copy` if
you'd rather have copies (recommended on Windows).

### Flags (Bash)

```bash
./setup.sh              # symlink skills into every detected CLI
./setup.sh --copy       # copy instead of symlinking (Windows-friendly)
./setup.sh --dry-run    # show what would change without touching anything
./setup.sh --help       # print usage
```

### Flags (PowerShell)

```powershell
.\setup.ps1              # copy skills into every detected CLI
.\setup.ps1 -Copy        # explicit copy mode (default on Windows)
.\setup.ps1 -DryRun      # show what would change without touching anything
.\setup.ps1 -Help        # print usage
```

If PowerShell blocks `setup.ps1` with "running scripts is disabled on this system", run it with a
process-scoped policy bypass instead of changing machine-wide settings:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

## Starting Local App Builds

When asking an AI coding agent to build a new local app, start with this prompt so the `building-apps` skill is
loaded and the default stack stays aligned:

```text
Use the building-apps skill.

I want to build a local app. Before writing code:
1. Stop if there is no repo-local SPEC.md or PLAN.md.
2. If the SPEC/PLAN is missing, create it from my requirements and wait for my approval.
3. Make sure the SPEC/PLAN has milestones, each with acceptance criteria.
4. Build only the first milestone first; stop after it is working, verified, and ready for review.
5. Use Python for the backend unless an existing repo stack or the approved SPEC explicitly requires another backend.
6. Use vanilla HTML/CSS/JavaScript for the frontend unless the approved SPEC explicitly requires a framework.
7. Serve the frontend from the Python backend; do not ask me to open index.html directly.
8. Keep third-party API calls server-side and log backend outbound API responses with redaction/truncation.
```

This prompt is intentionally explicit: it forces a milestone-based SPEC/PLAN, keeps the first build scoped to
milestone one, and prevents agents from choosing Java, Node.js, or a frontend build stack when the
`building-apps` skill recommends a Python backend and vanilla JavaScript frontend for greenfield local apps.

## Configuring hooks

Hooks live in `hooks/` and are invoked by Claude Code via `hooks/hooks.json`. Behavior can be tuned via
environment variables — set them in your shell profile or your CLI's settings.

| Variable | Default | Effect |
|----------|---------|--------|
| `PROTECTED_BRANCHES` | `main\|master` | Pipe-separated regex of branches that block direct commits. Empty string disables. |
| `TODO_TICKET_PREFIX` | unset | If set (e.g. `PROJ`), warn on `TODO` comments in Java files that don't reference `TODO(PROJ-NNN)`. |

## Contributing

PRs from forks are welcome. Before opening one:

1. Fork the repo and create a feature branch.
2. Run the smoke test locally — `./scripts/smoke-test-ai-assets.sh`. CI will run it again on push.
3. Keep changes focused. New skills go in their own folder under `skills/<skill-name>/SKILL.md`.

See [`skills/writing-skills/SKILL.md`](skills/writing-skills/SKILL.md) for the conventions every skill is
expected to follow (frontmatter, TLDR, structure).

## License

GPLv3 — see [`LICENSE`](LICENSE).
