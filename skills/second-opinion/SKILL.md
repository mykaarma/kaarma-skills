---
name: second-opinion
description: "Use when you have a written implementation plan and want an independent review before execution. Dispatches Codex CLI or a Claude subagent to analyze the plan for flaws, gaps, and risks. Invoke manually with /second-opinion."
---

# Second Opinion — Independent Plan Review

## Overview

Review an implementation plan before execution by dispatching an independent reviewer — either **Codex CLI** (local) or a **Claude subagent**. The reviewer analyzes the plan against the actual codebase and returns a structured report with a verdict: PROCEED, REVISE, or RETHINK.

**Where this fits:**
```
/brainstorm → /write-plan → /second-opinion → /execute-plan
```

<HARD-GATE>
This skill NEVER modifies the plan file. It NEVER invokes execution skills. It only presents findings. The user decides what to do next.
</HARD-GATE>

## When to Use

- After `/write-plan` produces a plan and before `/execute-plan`
- When a plan touches unfamiliar parts of the codebase
- When a plan involves risky changes (migrations, schema changes, breaking APIs)
- When you want a fresh perspective before committing to execution

## Process

You MUST follow these 5 steps in order:

### Step 1: Locate the Plan

Check if the user provided a plan path as an argument. If not:

1. Scan `docs/plans/` for plan files
2. List the most recent plans with their dates and names
3. Ask the user to pick one

```
Found these plans:
1. docs/plans/2026-03-26-auth-refactor.md
2. docs/plans/2026-03-25-payment-api.md
3. docs/plans/2026-03-24-notification-service.md

Which plan should I review? (number or file path)
```

If `docs/plans/` doesn't exist or is empty, ask the user for the plan file path directly.

### Step 2: Gather Context

1. Read the plan file completely
2. Extract file paths mentioned in the plan — look for patterns like:
   - Explicit paths: `src/main/java/...`, `path/to/file.ext`
   - Code blocks referencing files: `Modify: path/to/file`
   - Import statements referencing project files
3. Present detected files to the user:

```
Detected files referenced in the plan:
- src/main/java/com/mykaarma/payment/PaymentService.java
- src/main/resources/db/migration/V42__add_column.sql
- src/test/java/com/mykaarma/payment/PaymentServiceTest.java

Want to add more files for context? @ mention any files to include, or type "no" to proceed.
```

- If the user types "no", "none", "skip", or "done" — proceed with detected files only
- If the user @ mentions files — add those files to the context and proceed

4. Read all confirmed files and store their contents

### Step 3: Choose Reviewer

Always ask the user:

```
How would you like the plan reviewed?

1. Codex CLI — runs locally
2. Claude subagent — runs as a Claude subagent in this session

Choose (1 or 2):
```

**If user picks Codex CLI:**
- Check if `codex` is installed: run `which codex`
- If not found, tell the user:
  ```
  Codex CLI not found. Install it with: npm install -g @openai/codex
  Then authenticate with: codex login
  Or choose option 2 (Claude subagent) instead.
  ```
- If installed but not authenticated (command fails with auth error), tell the user:
  ```
  Codex CLI is not authenticated. Run: codex login
  Or choose option 2 (Claude subagent) instead.
  ```
- Do not proceed with Codex path if not installed or not authenticated

**If user picks Claude subagent:**
- No prerequisites needed, proceed directly

### Step 4: Dispatch Review

**Build the prompt:**
1. Read the review prompt template from `reference/review-prompt-template.md` (relative to this skill's directory)
2. Replace `{{PLAN_CONTENT}}` with the full plan file contents
3. Replace `{{FILE_CONTENTS}}` with all gathered context files, each preceded by its file path as a header:
   ```
   ### File: src/main/java/.../PaymentService.java
   <file contents>

   ### File: src/main/resources/.../V42__add_column.sql
   <file contents>
   ```

**Codex CLI path:**
1. Write the assembled prompt to a temp file: `/tmp/second-opinion-prompt-<timestamp>.md`
2. Run Codex in non-interactive mode, capturing only the final response:
   ```bash
   codex exec --output-last-message /tmp/second-opinion-result-<timestamp>.md "$(cat /tmp/second-opinion-prompt-<timestamp>.md)" 2>/dev/null
   ```
   - Use `codex exec` (non-interactive mode) — NOT the interactive `codex` command
   - Use `--output-last-message <file>` to capture the final agent message cleanly
   - Redirect stderr (`2>/dev/null`) to suppress session logs, model info, and connection noise
   - Tell the user: "Codex is reviewing the plan... this may take a minute."
3. Read the result file and present it
4. Clean up both temp files (`/tmp/second-opinion-prompt-*` and `/tmp/second-opinion-result-*`)

**Claude subagent path:**
1. Dispatch a `general-purpose` Agent with the assembled prompt as the task
2. The prompt already contains all instructions and the required output format
3. Capture the returned result

### Step 5: Present Results

1. Display the reviewer's structured report as-is (it follows the template format):
   - **Verdict** (PROCEED / REVISE / RETHINK)
   - **Critical Issues**
   - **Gaps**
   - **Suggestions**
   - **What's Good**

2. Based on the verdict, add guidance:

   **If PROCEED:**
   ```
   The plan looks solid. You can proceed to execution with /execute-plan.
   ```

   **If REVISE:**
   ```
   The plan needs updates before execution. Address the Critical Issues and Gaps above,
   then re-run /second-opinion to verify, or proceed to /execute-plan if you're confident
   in your fixes.
   ```

   **If RETHINK:**
   ```
   The reviewer found fundamental issues with the approach. Consider revisiting the design
   with /brainstorm before creating a new plan.
   ```

## Key Constraints

- **Manual only** — this skill is never auto-triggered. User must invoke `/second-opinion`.
- **Read-only** — never modify the plan file, never modify codebase files.
- **No execution** — never invoke `/execute-plan` or any implementation skill.
- **Context size** — if the assembled prompt (plan + files) is very large, warn the user and suggest trimming context or switching to the subagent path which handles larger context better.
- **Temp file cleanup** — always delete `/tmp/second-opinion-prompt-*.md` after Codex finishes.
