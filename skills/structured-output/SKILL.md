---
name: structured-output
description: "Utility reference for emitting structured JSON from skills so downstream automation (MCP tools, other skills) can parse results without scraping prose. Reference this skill from any skill that produces output consumed by another skill or tool."
---

# Structured Output

## When to Emit Structured JSON

Emit a structured JSON block when **any** of the following are true:

- The skill result will be consumed by another skill (e.g. `writing-plans` output feeds `subagent-driven-development`)
- The result contains IDs, URLs, or counts that a downstream MCP tool needs (Jira key, GitHub PR number, etc.)
- The skill is invoked inside a multi-agent pipeline where an orchestrator will parse the output
- The user explicitly asks for machine-readable output

If the output is purely informational (e.g. a how-to explanation), skip the JSON block — don't add noise.

## Standard Envelope Format

Wrap skill-specific data in this envelope so consumers have a consistent parsing target:

```json
{
  "skill": "skill-name",
  "timestamp": "2026-04-10T14:32:00Z",
  "status": "success",
  "data": {}
}
```

| Field | Values | Notes |
|-------|--------|-------|
| `skill` | string | Matches the `name` field in the skill's front matter |
| `timestamp` | ISO 8601 UTC | Use the current wall-clock time at emission |
| `status` | `"success"` \| `"partial"` \| `"failed"` | `"partial"` when the skill completed but with warnings; `"failed"` when it could not complete |
| `data` | object | Skill-specific payload — see each skill's "Structured Output" section |

### Error Envelope

When `status` is `"failed"`, add a top-level `"error"` field:

```json
{
  "skill": "jira-create-ticket",
  "timestamp": "2026-04-10T14:32:00Z",
  "status": "failed",
  "error": "Jira API returned 403 — check token permissions",
  "data": {}
}
```

## How to Emit

1. Produce the JSON object (with the envelope or skill-specific shape as documented in the skill).
2. Emit it inside a fenced code block tagged `json`:

   ````
   ```json
   { ... }
   ```
   ````

3. Place it as the **last fenced code block** in the response — consumers search for the final ` ```json ` block to avoid false-positive matches in code examples earlier in the response.

## How Consumers Should Parse

Look for the last occurrence of a ` ```json ` fenced block in the response text. In pseudocode:

```python
blocks = re.findall(r"```json\s*([\s\S]*?)```", response_text)
payload = json.loads(blocks[-1])  # last block wins
```

Skills that reference this standard:
- `skills/jira-create-ticket/SKILL.md` — emits `ticket_id`, `url`, `summary`, `status`
- `skills/writing-plans/SKILL.md` — emits `plan_id`, `tasks[]`, `total_tasks`
- `skills/reviewing-code/SKILL.md` — emits `verdict`, `blocking_count`, `non_blocking_count`, `issues[]`

## Skill-Specific Schemas

Each skill documents its own `data` shape in a dedicated "Structured Output" section. The envelope wrapper is optional when a skill's output is simple and unambiguous (e.g. `jira-create-ticket` emits its payload directly), but encouraged for pipeline contexts where the `skill` and `status` fields help route results.
