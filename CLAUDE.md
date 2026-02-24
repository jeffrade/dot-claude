## 🚫 CRITICAL GIT RULE - ENFORCE STRICTLY

**Claude MUST NEVER execute git write operations. PERIOD.**

- ❌ FORBIDDEN: `git add`, `git commit`, `git push`, `git reset`, `git rebase`, `git pull`, `git checkout`, `git restore`
- ✅ ALLOWED ONLY: `git status`, `git log`, `git diff`, `git show`, `git branch`, `git remote`

**Consequence:** Using forbidden git commands breaks the codebase. This rule is non-negotiable.

---

## ⚙️ Permission Enforcement

`~/.claude/settings.json` (tracked in `devixlabs/claude` on GitHub) handles two layers:
- **`allow`**: Read-only tools (`Read`, `Glob`, `Grep`), safe bash utilities, build tools, runtimes, and local-only `curl` — all auto-approved, no prompting
- **`ask`**: Destructive or write operations (`rm`, git write ops, `docker push`) — always prompts for confirmation

CLAUDE.md behavioral rules and settings.json mechanical enforcement work together. If something seems auto-approved that shouldn't be, check `settings.json` first.

---

## General Rules

- DO NOT exit plan mode without asking the human user first.
- ALWAYS write plan, spec, requirement files to the current project (i.e. pwd) directory and notify the human user in doing so (or ask for confirmation).
- The human on the other side of claude-code is prone to making small typing or copy & paste errors when talking about any linux command he is executing. Always check first that the command the human is executing is syntactically correct and has no typos.
- ALWAYS run the command shellcheck on all changes to shell (or bash) scripts (or when done creating a new script) and resolve the errors until they're fixed (i.e. exit 0 returned and nothing in stdout/stderr).
- ALWAYS look for a Makefile in a project and understand what each command does AND use them accordingly when working on tasks and source code.

---

## 📚 Reference Directories

### ~/Desktop/claude-code/
Project-specific resources and documentation. Available when needed but NOT loaded into context at startup.

**Current Contents:**
- `linux/r8168-network-driver-fix.md` - Documentation for r8169/r8168 driver conflict and permanent fix (applied 2026-02-04)
