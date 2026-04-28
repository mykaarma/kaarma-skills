# Engineering principles

This file is loaded by Claude Code at the start of every session. Keep it short, generic, and durable —
project-specific details belong in a project-level `CLAUDE.md`, not here.

## How to use the skill catalog

The `skills/` folder contains structured workflows for common engineering tasks: writing plans, debugging,
brainstorming, code review, requesting/receiving review, test-driven development, debugging incidents, and
shipping changes. Each skill has a `SKILL.md` with a short TLDR and step-by-step procedure.

When a request matches a skill's `description`, invoke it via the `Skill` tool *before* generating any
other response. Do not paraphrase a skill from memory — read it and follow it. Skills you should reach
for proactively:

| Situation | Skill |
|-----------|-------|
| User describes a bug or unexpected behaviour | `systematic-debugging`, `debugging-errors` |
| User asks for a plan / strategy | `writing-plans`, `spec-to-code` |
| Multi-step or non-trivial implementation | `executing-plans`, `subagent-driven-development` |
| User asks for code review or feedback | `reviewing-code`, `second-opinion` |
| Wrapping up a development branch | `finishing-a-development-branch`, `git-commit` |
| Preparing to ship a change | `verification-before-completion` |

## Code style

- Default to writing **no comments**. Add one only when *why* is non-obvious (a hidden invariant, a
  workaround for a specific bug, behaviour that would surprise a reader). Don't explain *what* well-named
  identifiers already say.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust framework
  guarantees. Validate at system boundaries (user input, external APIs).
- Prefer editing existing files over creating new ones. Avoid premature abstraction — three similar lines
  are better than a fragile helper.
- For JS/TS: prefer `const` over `let`; never use `var`. Use `async`/`await` over raw promises.
- For Python: PEP 8, type hints on every function signature, prefer `pathlib`.
- For Java: prefer `Optional` over null returns; use meaningful exception types over `RuntimeException`.

## Git & PR hygiene

- **Never commit directly to `main` or `master`.** Use a feature branch and open a PR. The
  `pre-tool-bash` hook enforces this — set `PROTECTED_BRANCHES` to customize the regex.
- **Never force-push** to a shared branch. The hook also blocks this.
- Conventional-commit-style subjects (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`) keep history readable.
- Squash-merge into the default branch unless the project says otherwise.

## Security & secrets

- Never commit credentials, tokens, or PII. The `.gitignore` covers common cases — if you create a new
  secrets file, add the pattern.
- Parameterised queries only — no string concatenation in SQL (the `post-tool-edit` hook flags this).
- Don't log passwords, tokens, API keys, or full request/response bodies. Log correlation IDs and metadata.
- Follow OWASP Top 10. Validate and sanitise input at system boundaries.

## Verification before claiming done

A task is not complete until you have evidence it works:

- For library code: run the relevant tests, not just the type-checker.
- For UI changes: open the feature in a browser and exercise the golden path. Type-checks verify code
  correctness, not feature correctness — say so explicitly when you can't actually run the UI.
- For long-running tasks: use the `verification-before-completion` skill as a checklist before reporting
  the work as done.

## Hooks reference

The `hooks/` folder contains shell scripts wired into Claude Code via `hooks/hooks.json`:

- `pre-tool-bash` — blocks force-push, direct commits to protected branches, `DROP TABLE`/`DROP DATABASE`,
  `rm -rf /`, and writes to `/etc/` or `/usr/`. Configurable via `PROTECTED_BRANCHES`.
- `post-tool-edit` — warns on `System.out.println` in Java, `var` in TS/JS, `console.log` in non-test JS
  files, and string-concatenated SQL. Optional TODO-ticket check via `TODO_TICKET_PREFIX`.
- `session-start` — runs at session start.

Hooks emit warnings to stderr but don't block writes (with the exception of `pre-tool-bash`, which exits 2
to block dangerous commands).
