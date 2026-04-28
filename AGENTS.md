# Engineering principles

This file is loaded by Codex CLI (and other tools that read `AGENTS.md`) at the start of every session.
Keep it short, generic, and durable — project-specific details belong in a project-level `AGENTS.md`, not
here.

## How to use the skill catalog

The `skills/` folder contains structured workflows for common engineering tasks: writing plans, debugging,
brainstorming, code review, requesting/receiving review, test-driven development, and shipping changes.
Each skill has a `SKILL.md` with a short TLDR and step-by-step procedure.

When a request matches a skill's `description`, follow that skill's procedure rather than improvising.
Invoke a skill in Codex CLI by referencing it as `$skill-name` (e.g. `$git-commit`, `$writing-plans`).
Skills you should reach for proactively:

| Situation | Skill |
|-----------|-------|
| User describes a bug or unexpected behavior | `systematic-debugging`, `debugging-errors` |
| User asks for a plan / strategy | `writing-plans`, `spec-to-code` |
| Multi-step or non-trivial implementation | `executing-plans`, `subagent-driven-development` |
| User asks for code review or feedback | `reviewing-code`, `second-opinion` |
| Wrapping up a development branch | `finishing-a-development-branch`, `git-commit` |
| Preparing to ship a change | `verification-before-completion` |

## Code style

- Default to writing **no comments**. Add one only when *why* is non-obvious. Don't explain *what*
  well-named identifiers already say.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust framework
  guarantees. Validate at system boundaries.
- Prefer editing existing files over creating new ones. Avoid premature abstraction.
- For JS/TS: prefer `const` over `let`; never use `var`. Use `async`/`await` over raw promises.
- For Python: PEP 8, type hints on every function signature, prefer `pathlib`.
- For Java: prefer `Optional` over null returns; use meaningful exception types over `RuntimeException`.

## Git & PR hygiene

- Never commit directly to `main` or `master` — use a feature branch and open a PR.
- Never force-push to a shared branch.
- Conventional-commit-style subjects (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`) keep history readable.
- Squash-merge into the default branch unless the project says otherwise.

## Security & secrets

- Never commit credentials, tokens, or PII.
- Parameterised queries only — no string concatenation in SQL.
- Don't log passwords, tokens, API keys, or full request/response bodies. Log correlation IDs and metadata.
- Follow OWASP Top 10. Validate and sanitize input at system boundaries.

## Verification before claiming done

A task is not complete until you have evidence it works:

- For library code: run the relevant tests, not just the type-checker.
- For UI changes: open the feature in a browser and exercise the golden path.
- For long-running tasks: use the `verification-before-completion` skill as a checklist.
