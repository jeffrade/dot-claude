---
name: todo-audit
description: "Audit and clean up the TODO lifecycle across any project. Triggers when: user says 'audit todos', 'clean up todos', 'what's left to do', 'check my todos', 'are there stale todos', 'find untracked TODOs', 'sync my docs'. Also triggers when user completes work and asks about remaining tasks, or when TODO_N.md files exist alongside completed ROADMAP items. Works with the todo-breakdown skill — this skill audits and cleans, todo-breakdown decomposes and creates."
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent
version: 1.0.0
---

# TODO Audit — Lifecycle Cleanup & Discovery

Full lifecycle audit of the project's TODO system. Runs 5 steps in order:
Clean → Audit → Sync Docs → Discover → Refine.

**Relationship to todo-breakdown:** This skill AUDITS and CLEANS. The todo-breakdown skill DECOMPOSES and CREATES. After step 5 (Refine), hand off any items needing breakdown to the todo-breakdown skill.

---

## Step 1: CLEAN — Remove Completed TODOs

Find and delete completed TODO files. Completed work should live in ROADMAP.md, not orphaned files.

### Procedure

1. Glob for `TODO*.md`, `todo*.md` in `docs/todos/`, `docs/`, and project root
2. For each TODO file, check if ALL items are marked `[DONE]` or if the corresponding ROADMAP entry is marked `[x]`
3. For completed files:
   a. Verify ROADMAP.md has a summary of the completed work (date, what was done)
   b. If not, add a one-line completion summary to ROADMAP.md
   c. **Delete the file immediately** — completed TODO files are ephemeral, not historical records
4. Report what was cleaned

### Completion Detection

A TODO file is complete when ANY of:
- All items have `[DONE]` prefix
- The corresponding ROADMAP.md line has `[x]` checkbox
- The file references code/features that now exist and pass tests
- The file's acceptance criteria are all met (check the codebase)

---

## Step 2: AUDIT — Verify Remaining TODOs Match Reality

Surviving TODO files and ROADMAP items may be stale after code changes.

### Procedure

1. Read ROADMAP.md — for each unchecked `[ ]` item:
   a. Check if the described work already exists in the codebase (grep for key functions, files, classes)
   b. If the work is done but not marked: mark `[x]`, add completion date
   c. If the work is partially done: note what remains
   d. If the work is obsolete (code was deleted, approach changed): mark as obsolete or remove
2. For each surviving TODO_N.md file:
   a. Read each item's `Create/Modify` file paths — do they still exist? Have they changed?
   b. Check if items reference functions/classes that were renamed or removed
   c. Flag stale items for user review

---

## Step 3: SYNC DOCS — Update Non-TODO Documentation

After cleaning and auditing, project docs may reference stale counts, completed items, or old architecture.

### Procedure

1. Read CLAUDE.md — check for:
   - Stale test counts (run `make test 2>&1 | tail -1` to get current count)
   - References to TODO files that were deleted in Step 1
   - Feature descriptions that are now outdated
   - Agent/file counts that changed
2. Read README.md — check for stale descriptions or missing features
3. Read docs/REFERENCE.md (if exists) — check make targets, command lists
4. Read agent/skill files — check for "known gaps" or caveats that are now resolved
5. Fix all stale references in a single pass

### What to Update

- Test counts, topic counts, term counts
- "Not yet implemented" → now implemented
- "Known gap: X" → gap now filled
- Stale file references → updated or removed
- Phase completion status

---

## Step 4: DISCOVER — Find Untracked Work in the Codebase

Scan source code for work items that aren't in ROADMAP or any TODO file.

### Source Code Pattern Scan

Search for these patterns (case-insensitive) across all project source files, excluding `.venv/`, `node_modules/`, vendor dirs, and generated files:

```
Regex patterns (match all common variations):
  #\s*TODO\b     — matches #TODO, # TODO, #  TODO
  #\s*FIXME\b    — matches #FIXME, # FIXME
  #\s*HACK\b     — matches #HACK, # HACK
  #\s*XXX\b      — matches #XXX
  (?<!\w)TODO\b  — matches bare TODO (not part of another word)
  (?<!\w)FIXME\b — matches bare FIXME
```

**Important:** The user's common patterns are `#TODO`, `# TODO`, and bare `TODO` (no hash). Ensure all three are caught.

### Procedure

1. Run the regex scan across `*.py`, `*.sh`, `*.md`, `*.js`, `*.ts` (and other source types in the project)
2. Exclude test fixtures, vendored code, `.venv`, `__pycache__`
3. Group results by file
4. For each found item, check if it's already tracked in ROADMAP.md or a TODO file
5. Report NEW (untracked) items with file path, line number, and the comment text
6. Ask the user if any should be added to ROADMAP.md

### Structural Gaps

Also check for:
- Placeholder functions (functions that return empty lists, hardcoded values, or raise `NotImplementedError`)
- Stub files (agents/skills with "not yet implemented" in their description)
- ROADMAP items that reference future phases with no breakdown

---

## Step 5: REFINE — Improve Remaining TODOs

After steps 1-4, the surviving TODO items are verified and current. Now improve them.

### Procedure

1. For each remaining ROADMAP item that is unchecked:
   a. Is it specific enough to execute? If vague, add detail
   b. Is it small enough? If it spans multiple concerns, suggest breakdown (→ hand off to todo-breakdown skill)
   c. Does it have acceptance criteria? If not, suggest some
2. For each surviving TODO_N.md file:
   a. Are items still atomic? (One concern, one checkpoint, one failure mode)
   b. Are file paths and function names current?
   c. Are checkpoints runnable? (`make check`, specific test commands)
3. **Ask the user Yes/No questions** to resolve any ambiguity:
   - "ROADMAP says 'calibrate Fidelity selectors' — is this still needed or has the approach changed?"
   - "TODO_4.md item 4.3 references `lib/foo.py` which doesn't exist. Should this be `lib/bar.py` or is it new?"
   - "Found 3 untracked TODOs in source code. Add to ROADMAP?"

### Hand-Off to todo-breakdown

If any ROADMAP item needs decomposition into a TODO_N.md file, tell the user:
> "Item X needs breakdown. Say 'break down [item]' to invoke the todo-breakdown skill."

Do NOT create TODO_N.md files yourself — that's the todo-breakdown skill's job.

---

## Output Format

After each step, report a brief summary:

```
## Step 1: CLEAN
- Deleted: TODO_1_knowledge_db_strategy_gaps.md (completed 2026-04-02)
- Deleted: TODO_2_glossary_empty_definitions.md (completed 2026-04-02)
- Kept: TODO_4_chain_calibration.md (3/5 items incomplete)

## Step 2: AUDIT
- ROADMAP: marked 2 items complete (were done but unchecked)
- ROADMAP: flagged 1 item as potentially stale
- TODO_4: items 4.2 and 4.3 reference renamed files — updated

## Step 3: SYNC DOCS
- CLAUDE.md: updated test count 587 → 612
- CLAUDE.md: removed reference to deleted TODO_2
- README.md: no changes needed

## Step 4: DISCOVER
- Found 5 untracked TODOs in source code:
  - lib/chain_scanner.py:15: # TODO: calibrate CSS selectors
  - lib/market_context.py:45: # FIXME: handle rate limiting
  ...
- 3 are already covered by ROADMAP items
- 2 are NEW — recommend adding to ROADMAP

## Step 5: REFINE
- Questions for user:
  1. [Y/N] Add "FIXME: handle rate limiting" to ROADMAP Phase 2?
  2. [Y/N] Is "calibrate Fidelity selectors" still the right approach?
  ...
```

---

## Edge Cases

- **No ROADMAP.md exists:** Ask the user where their task tracking lives.
- **No TODO files exist:** Skip Step 1, proceed with remaining steps.
- **Massive codebase:** Limit source scan to top-level `lib/`, `scripts/`, `src/` dirs. Ask before scanning deeper.
- **No stale items found:** Report "All clean" and skip to Step 4 (discovery).
