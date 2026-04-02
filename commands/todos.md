---
description: Audit, clean, and discover TODOs across the project. Runs the 5-step todo-audit lifecycle.
---

Run a full TODO lifecycle audit on this project:

1. **CLEAN** — Find completed TODO files, summarize to ROADMAP.md, delete the files
2. **AUDIT** — Verify remaining TODOs match current source code, mark stale items
3. **SYNC DOCS** — Update CLAUDE.md, README.md, and other docs with current state
4. **DISCOVER** — Scan source code for untracked `#TODO`, `# TODO`, `TODO`, `#FIXME`, `#HACK` comments
5. **REFINE** — Improve remaining TODOs with more detail, suggest breakdowns, ask Y/N to resolve ambiguity

Report a summary after each step. Ask user to confirm before deleting files or making large changes.
