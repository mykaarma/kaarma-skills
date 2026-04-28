---
name: session-metrics
description: "Report session summary — files changed, git diff stats, context health check, and cost-awareness tips. Use to get a snapshot of what's been accomplished and whether to /compact. Trigger when the user asks for session stats, cost summary, context health, what changed this session, or how many tokens/messages have been used."
---

# Session Metrics

Produce a fast, scannable snapshot of the current session: what changed, how much context has been consumed, and actionable cost/efficiency tips.

This skill is intentionally low-overhead. Run git commands, count signals, and present results. Do not read large files or invoke subagents.

---

## Step 1: Gather Git State

Run these commands to collect raw data:

```bash
# Changed file summary
git diff --stat HEAD 2>/dev/null || echo "(no commits yet)"

# Untracked and staged files
git status --short 2>/dev/null

# Lines added/removed since last commit
git diff HEAD --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {print "+" add " lines added, -" del " lines removed"}'

# Last 5 commits for context
git log --oneline -5 2>/dev/null
```

---

## Step 2: Estimate Session Activity

Claude does not have direct access to token counts. Estimate from observable signals:

- **Messages exchanged**: Count the visible turns in the current conversation. Report as "approximately N turns".
- **Files read**: Count distinct files you recall reading this session.
- **Files modified/created**: Extract from `git status` output.
- **Tools invoked**: Estimate from the tools used (Bash, Read, Edit, Write, Grep, Glob, subagents).
- **Subagents dispatched**: Note if the Agent tool, dispatching-parallel-agents skill, or any subagent was used.

---

## Step 3: Produce the Report

Format output using this exact structure:

```
## Session Metrics

### Activity Summary
- Approximate turns: ~N
- Files read this session: ~N
- Files modified: N  (from git status)
- Files created: N   (from git status)
- Tools invoked: [Bash, Read, Edit, Write, Grep, ...]
- Subagents dispatched: N (or "none")

---

### Change Impact
<paste git diff --stat output here>

Lines changed: +X added, -Y removed
Untracked files: N

---

### Recent Commits
<paste git log --oneline -5 output>

---

### Context Health Check
- Session length: [short / moderate / long — estimate based on turn count]
  - < 20 turns: short — context is fresh
  - 20–50 turns: moderate — consider /compact if starting a new task
  - > 50 turns: long — strongly recommend /compact before continuing
- Large files in context: [note any files > 200 lines that were read]
- Subagent multiplier: [if subagents were used, note that each dispatched agent carries its own context cost]

---

### Cost-Awareness Tips
[Show only the tips that apply to this session]

- If session is long (>50 turns): "Context is large — run /compact before your next task to reduce cost and improve response quality."
- If many files were read: "N files were read. In future queries, target specific files or use Grep instead of reading entire directories."  
- If subagents were dispatched: "Subagents multiply context cost — each agent starts a full new context window. Batch independent tasks into a single agent where possible."
- If > 10 files were modified: "Large change set. Consider breaking future sessions into smaller, focused tasks."
- Always show: "Long contexts cost more per message. Use /compact regularly, especially before switching tasks."

---

### Productivity Summary
**Accomplished this session:**
[Summarize in 2-4 bullets based on git diff --stat and git log. Focus on what changed, not how.]

**Next steps:**
[Based on git status, call out:]
- Uncommitted changes: "N files have uncommitted changes — run /git-commit or commit manually."
- Untracked files: "N untracked files — stage them if intentional, or add to .gitignore."
- No changes: "Clean working tree — nothing to commit."
```

---

## Notes for Execution

- Keep total output under 60 lines. Be concise — this is a glanceable summary.
- Do not re-read files to produce this report. Use only git commands and your conversation memory.
- If git is not available or the directory is not a repo, skip git sections and note it.
- If the working directory has no commits, report that and skip diff/log sections.
- Do not invoke other skills from within this skill.
