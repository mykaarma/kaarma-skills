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

## Install

```bash
git clone https://github.com/mykaarma/skills.git ~/skills
cd ~/skills
./setup.sh
```

The installer detects which CLIs are installed on your machine (`claude`, `codex`, `gemini`, `cursor`,
`antigravity`) and links the appropriate folders into each one's config directory:

| CLI | Config directory |
|-----|------------------|
| Claude Code | `~/.claude/{skills,agents,hooks,commands,CLAUDE.md,AGENTS.md}` |
| Codex CLI | `~/.codex/{skills,AGENTS.md}` |
| Gemini CLI | `~/.gemini/{skills,commands,GEMINI.md}` |
| Cursor | `~/.cursor/skills/` |
| Antigravity | `~/.gemini/antigravity/skills/` |

By default the installer creates symlinks so `git pull` automatically updates every CLI. Pass `--copy` if
you'd rather have copies (recommended on Windows).

### Flags

```
./setup.sh              # symlink skills into every detected CLI
./setup.sh --copy       # copy instead of symlinking (Windows-friendly)
./setup.sh --dry-run    # show what would change without touching anything
./setup.sh --help       # print this list
```

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
