description: "Load recent work context — reads git status, recent commits, plan files, and summarizes pending work"
---

You are loading context for recent local work. Reconstruct context as follows:

1. **Check git state** — run `git status` and `git log --oneline -5`. Note the current branch, any uncommitted changes, and the most recent commit messages.

2. **Find recent plan files** — look for files modified in the last 7 days under `docs/plans/`, `plans/`, or `.claude/plans/` (try all three). Read any found files to extract task lists and pending items.

3. **Identify in-progress work** — from the git branch name and recent commits, infer what feature or fix was being worked on. Note any staged or unstaged changes that suggest incomplete work.

4. **Summarize the session state** in this format:
   > Current work context: **[branch/feature name]**. Last changes: [top 1-2 commit messages or "no commits yet"]. Uncommitted changes: [file names or "none"]. Pending from plan: [open tasks or "no plan files found"].

5. **Confirm with the engineer** — ask: "Does this match what you remember? Want to continue where we left off, or is there something else you need to tackle first?"

If git is not available or this is not a git repo, skip git steps and go directly to plan files. If no plan files exist either, say so and ask the engineer to describe what they were working on.
