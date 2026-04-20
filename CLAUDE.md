## 🚫 CRITICAL GIT RULE - ENFORCE STRICTLY

**Claude MUST NEVER execute git write operations. PERIOD.**

- ❌ FORBIDDEN: `git add`, `git commit`, `git push`, `git reset`, `git rebase`, `git pull`, `git checkout`, `git restore`
- ✅ ALLOWED ONLY: `git status`, `git log`, `git diff`, `git show`, `git branch`, `git remote`, `git worktree`

**Consequence:** Using forbidden git commands breaks the codebase. This rule is non-negotiable.

---

## ⚙️ Permission Enforcement

`~/.claude/settings.json` (tracked in `devixlabs/claude` on GitHub) handles two layers:
- **`allow`**: Read-only tools (`Read`, `Glob`, `Grep`), safe bash utilities, build tools, runtimes, and local-only `curl` — all auto-approved, no prompting
- **`ask`**: Destructive or write operations (`rm`, git write ops, `docker push`) — always prompts for confirmation

CLAUDE.md behavioral rules and settings.json mechanical enforcement work together. If something seems auto-approved that shouldn't be, check `settings.json` first.

---

## 🚫 NO FALSE AUTHORITY — ENFORCE STRICTLY

**When I don't have source code, documentation, or empirical evidence, I MUST say "I don't know — try it and see." PERIOD.**

- ❌ FORBIDDEN: Fabricating confident technical explanations for behavior I cannot verify (closed systems, third-party internals, undocumented behavior)
- ✅ REQUIRED: Admit uncertainty explicitly, then offer one or more of:
  1. The empirical test ("try it and see")
  2. Launch a sub-agent to research it (`Agent` tool with web search)
  3. Run a targeted `WebSearch` to find authoritative documentation

**This applies system-wide, every session, every project, every machine.**

---

## 🔍 RIYDKFC — "Research If You Don't Know For Certain"

**When the user writes `RIYDKFC` anywhere in a prompt: STOP. Do not answer from training data alone.**

This is a hard override. Execution:
1. Acknowledge you are executing RIYDKFC
2. Use `WebSearch`, `WebFetch`, or spawn a research `Agent` to find authoritative sources
3. Cite the sources in your response
4. Only then provide an answer grounded in what you actually found

- ❌ FORBIDDEN: Responding with training-data confidence when `RIYDKFC` is present
- ❌ FORBIDDEN: Skipping the research step even if you "think" you know the answer
- ✅ REQUIRED: External research FIRST, answer SECOND — every single time

**This is a direct escalation of NO FALSE AUTHORITY. `RIYDKFC` = user has zero tolerance for hallucination on this specific question.**

---

## Communication Style

- **Be concise.** Short sentences. No fluff. No Silicon Valley verbosity. Say what needs saying, stop.

## General Rules

- **Tests MUST always pass.** NEVER consider work done with broken tests. If code changes break existing tests, update the tests as part of the same work. Run `make test` (or project equivalent) before declaring anything complete. This is non-negotiable across ALL projects.
- PDF reads are limited to 20 pages per call — always split large PDF reads into ≤20-page chunks.
- DO NOT exit plan mode without asking the human user first.
- ALWAYS write plan, spec, requirement files to the current project (i.e. pwd) directory and notify the human user in doing so (or ask for confirmation).
- The human on the other side of claude-code is prone to making small typing or copy & paste errors when talking about any linux command he is executing. Always check first that the command the human is executing is syntactically correct and has no typos.
- ALWAYS run the command shellcheck on all changes to shell (or bash) scripts (or when done creating a new script) and resolve the errors until they're fixed (i.e. exit 0 returned and nothing in stdout/stderr).
- ALWAYS look for a Makefile in a project and understand what each command does AND use them accordingly when working on tasks and source code.
- Grep Makefile targets with `grep -qE "^target\s*:"` — `^target:` misses `target :` (space before colon).
- Makefile heredocs (`<< 'EOF'`) don't work — each recipe line runs in a separate subshell. Use dedicated scripts in `scripts/` instead.

---

## 🔌 Plugin Management

**Skill `$ARGUMENTS` pattern:** `$ARGUMENTS` is a shell env var, not stdin. Never `echo '$ARGUMENTS'` (single quotes block expansion). Pass as `sys.argv[1]`:
```bash
python3 -c "import sys, json; ..." "$ARGUMENTS"
```

**Prefer the marketplace approach** — if a GitHub repo has `.claude-plugin/marketplace.json`, add it as a marketplace and install normally:
```bash
claude plugin marketplace add OWNER/REPO
claude plugin install PLUGIN_NAME@MARKETPLACE_NAME
```

Custom (local) plugins live in `~/.claude/custom-plugins/plugins/` under the `devix-labs` marketplace.

Run `make help` in `~/.claude/` for all plugin management commands.

**Fetching raw files from GitHub:** Use `gh api repos/OWNER/REPO/contents/PATH --jq '.content' | base64 -d` — WebFetch often summarizes markdown instead of returning exact content.

---

## 📚 Reference Directories

### ~/Desktop/claude-code/
Project-specific resources and documentation. Available when needed but NOT loaded into context at startup.

**Current Contents:**
- `TODO.txt` - Miscellaneous scratch notes

### ~/.claude/docs/todos/
Pending maintenance TODOs for this repo. Check `TODO.md` at the start of any maintenance session.
