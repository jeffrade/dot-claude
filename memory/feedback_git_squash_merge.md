---
name: git squash merge
description: Use git merge --squash to collapse a feature branch into a single commit on master — simpler than interactive rebase squashing
type: feedback
---

To merge an entire feature branch into master as **one commit**:

```bash
git checkout master
git merge --squash feature-branch
git commit -m "message"
```

Stages all the branch's changes as a single uncommitted diff on master. No interactive rebase, no editor, no commit picking.

**Why:** User found this much easier than `git rebase -i` squashing. Preferred for branches being merged and deleted anyway.

**How to apply:** When the user wants to merge a feature branch cleanly as one commit, suggest `--squash` first. Only suggest interactive rebase if they need to keep some commits separate.
