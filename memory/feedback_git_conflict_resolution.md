---
name: git conflict resolution options
description: User prefers diff3 conflict style + knows about git mergetool vimdiff as an alternative for resolving merge/rebase conflicts
type: feedback
---

Two interchangeable options for resolving conflicts — user knows both and picks based on preference:

**Option 1 (preferred) — vim + diff3:**
```bash
git config --global merge.conflictstyle diff3
# If conflicts already exist, re-generate with ancestor:
git checkout --conflict=diff3 <file>
```
Adds `||||||| ancestor` section so you can see what both sides changed *from*:
```
<<<<<<< HEAD
master's version
||||||| ancestor (original before either branch touched it)
=======
feature branch version
>>>>>>> hash msg
```

**Option 2 — git mergetool (vimdiff, 4-pane side-by-side):**
```bash
git config --global merge.tool vimdiff
git config --global mergetool.vimdiff.layout "LOCAL,BASE,REMOTE / MERGED"
git mergetool <file>
```
Opens: `LOCAL (HEAD) | BASE (ancestor) | REMOTE (incoming)` with `MERGED` edit pane at bottom.
Navigate conflicts: `]c` / `[c`. Pick a side: `:diffget LOCAL`, `:diffget BASE`, `:diffget REMOTE`.

Both options are configured globally. Either can be used on any conflicted file — they're not mutually exclusive.

**Edge case options (when neither above is enough):**
```bash
git show HEAD:path/to/file          # clean version from HEAD
git show MERGE_HEAD:path/to/file    # clean version from incoming branch
git show <hash> -- path/to/file     # exact patch the commit applied
```

**Why:** Raw 2-way markers give no context on intent. diff3 and mergetool both expose the common ancestor.

**How to apply:** When user is mid-rebase or resolving conflicts, mention both options. Default to suggesting diff3 first; offer mergetool if they want visual side-by-side.
