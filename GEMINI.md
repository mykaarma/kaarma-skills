# Engineering principles

This file is loaded by Gemini CLI at the start of every session. Keep it short, generic, and durable —
project-specific details belong in a project-level `GEMINI.md`, not here.

## How to use the skill catalog

The `skills/` folder contains structured workflows for common engineering tasks. Slash commands in
`gemini-commands/` (e.g. `/brainstorm`, `/write-plan`, `/execute-plan`, `/git-commit`) load the matching
skill and execute its procedure.

Reach for these proactively when the user's request matches:

| Situation | Command / Skill |
|-----------|-----------------|
| User describes a bug or unexpected behavior | `systematic-debugging`, `debugging-errors` |
| User asks for a plan / strategy | `/write-plan` (`writing-plans`) |
| Multi-step or non-trivial implementation | `/execute-plan` (`executing-plans`) |
| User asks for code review or feedback | `reviewing-code`, `second-opinion` |
| Wrapping up a development branch | `/git-commit` (`git-commit`), `finishing-a-development-branch` |
| Preparing to ship a change | `verification-before-completion` |

## Code style

- Default to writing **no comments**. Add one only when *why* is non-obvious.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen. Validate at system
  boundaries.
- Prefer editing existing files over creating new ones. Avoid premature abstraction.
- For JS/TS: prefer `const` over `let`; never use `var`. Use `async`/`await` over raw promises.
- For Python: PEP 8, type hints on every function signature, prefer `pathlib`.
- For Java: prefer `Optional` over null returns; use meaningful exception types over `RuntimeException`.

## Git & PR hygiene

- Never commit directly to `main` or `master` — use a feature branch and open a PR.
- Never force-push to a shared branch.
- Conventional-commit-style subjects (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`).
- Squash-merge into the default branch unless the project says otherwise.

## Security & secrets

- Never commit credentials, tokens, or PII.
- Parameterised queries only — no string concatenation in SQL.
- Don't log passwords, tokens, API keys, or full request/response bodies.
- Follow OWASP Top 10. Validate and sanitize input at system boundaries.

## Verification before claiming done

- For library code: run the relevant tests, not just the type-checker.
- For UI changes: open the feature in a browser and exercise the golden path.
- For long-running tasks: use the `verification-before-completion` skill as a checklist.
