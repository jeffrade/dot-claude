---
name: git branch comparison commands
description: Use --oneline git log commands when comparing branches or finding missing commits — more useful than plain git diff
type: feedback
---

When comparing branches or finding what's missing, use these first — not just `git diff <other-branch>`:

```bash
# Commits in branch-b not in branch-a (concise)
git log branch-a..branch-b --oneline

# Same but with file change stats
git log branch-a..branch-b --oneline --stat

# Commits unique to each branch (symmetric difference)
git log branch-a...branch-b --oneline --left-right

# During a rebase, reference the original branch tip
git log master..ORIG_HEAD --oneline

# Show what would be merged
git log HEAD..origin/main --oneline
```

**Why:** `git diff <branch>` is too noisy. Commit-level summaries with `--oneline` are better for branch cleanup decisions and understanding divergence.

**How to apply:** Any time user asks about comparing branches, finding missing commits, deciding if a branch is safe to delete, or understanding divergence — lead with `--oneline` log commands before raw diffs.
