---
name: docs-todos-auditor
description: Audit docs/todos/ directory against codebase state. Detects completed, stale, or outdated todo docs by cross-referencing git history and source code. Use when user asks to audit todos, check pending work, clean up todo docs, or after completing a major task. Also trigger proactively when a session completes significant implementation work that may have resolved a todo doc.
version: 1.0.0
tools: Read, Glob, Grep, Bash, Edit, Agent
---

# docs/todos/ Auditor

Audit, evaluate, and maintain `docs/todos/` directories across any project that adopts the two-tier documentation pattern (`docs/` = active, `docs/todos/` = pending).

**This skill can modify and delete files in `docs/todos/`.** It presents findings first, then applies changes:

| Action | Confirmation |
|--------|-------------|
| Structural fixes (dead links, paths, re-ordering) | Autonomous |
| Deletion of 100% completed `TODO_*.md` files (unambiguous) | **Autonomous — MUST delete** |
| Deletion where any ambiguity remains (partial completion, unclear rollup, dangling refs) | Requires user approval |
| Ambiguous references | Requires user approval |

**Deletion rule (non-negotiable):** A completed `TODO_*.md` file MUST be deleted autonomously when ALL of the following hold:
1. Every checklist item / acceptance criterion is `[x]` or marked DONE.
2. The parent (`TODO.md` or `ROADMAP.md`) has been updated to reflect completion (rollup done).
3. Related source code, tests, and Makefile wiring exist and are green.
4. No cross-reference from another active TODO depends on the file staying.

If all four hold, delete without asking. Git history preserves the spec. Only ask when something is ambiguous (partial work, missing rollup, or another TODO still points to it as a live dependency).

TODO source files in `docs/todos/` are git-committed truth — keep them accurate, internally consistent, and correctly cross-referenced.

## Workflow

### Phase 1: Discovery

Find the todos directory and its entry point.

1. Check for `docs/todos/` directory:
```bash
ls docs/todos/*.md 2>/dev/null
```

2. Identify the entry point (in priority order):
   - `docs/todos/ROADMAP.md` (preferred — maps docs to phases)
   - `docs/README.md` (secondary — may have a Pending Work section)
   - Neither (just audit individual files)

3. Read the entry point to understand phase structure and doc-to-phase mappings.

4. List all todo docs and note any that are NOT referenced in the entry point (orphans).

### Phase 2: Per-Document Audit

For **each** todo doc in `docs/todos/` (skip the entry point itself):

#### Step 2a: Extract Key Claims

Read the doc and extract:
- **Goal**: What the doc says should be built/changed
- **Key artifacts**: Classes, interfaces, files, methods, or patterns it names
- **Prerequisites**: What it says must exist or be done first
- **Checklist items**: Any `- [ ]` or numbered steps

#### Step 2b: Cross-Reference Against Codebase

For each key artifact the doc names:

```bash
# Check if named files exist
ls <file_path> 2>/dev/null

# Check if named classes/interfaces exist
grep -r "class ClassName\|interface InterfaceName" src/ --include="*.java" --include="*.py" --include="*.go" --include="*.rs" --include="*.ts"

# Check if named methods exist
grep -r "methodName" src/ --include="*.java" --include="*.py" --include="*.go"
```

#### Step 2c: Cross-Reference Against Git History

```bash
# Check recent commits for keywords from the doc title/goal
git log --oneline -20 --grep="<keyword>"

# Check if specific files mentioned in the doc were recently changed
git log --oneline -10 -- <file_path>
```

#### Step 2d: Classify

Based on findings, classify the doc. See [references/audit-criteria.md](references/audit-criteria.md) for detailed criteria.

| Status | Meaning |
|--------|---------|
| COMPLETED | All described work is implemented and verified |
| PARTIALLY DONE | Some items done, others remain |
| STALE | References outdated code, paths, or state |
| CURRENT | Accurately describes pending work |
| BLOCKED | Prerequisites not yet met |

### Phase 3: Audit Report

**ALWAYS output the report BEFORE making any changes.**

Format:

```
## docs/todos/ Audit Report

### Summary
- Total docs: X
- Completed (delete): X
- Partially done (trim): X
- Stale (update): X
- Current (no action): X
- Blocked (no action): X
- Orphaned (not in ROADMAP): X

### Per-Document Findings

#### 1. <filename> — STATUS
**Goal:** <one-line summary>
**Evidence:** <what you found in code/git>
**Action:** <delete | trim | update | none>
**Details:** <specific changes if trim/update>

#### 2. <filename> — STATUS
...

### Entry Point Updates
- <changes needed to ROADMAP.md or docs/README.md>
```

### Phase 4: Apply Changes

Apply changes in this order. Items marked **[confirm]** require user approval before proceeding; all others are applied autonomously.

1. **Delete** completed docs — autonomous when the 4-point deletion rule above is satisfied; `[confirm]` only when ambiguity remains
2. **Edit** partially done docs (mark completed items, remove done sections)
3. **Update** stale docs (fix file paths, class names, test counts, etc.)
4. **Fix broken references** in entry point — remove dead links, correct label/link mismatches, update stale file paths. Do this without asking.
5. **Re-order** sections or items in the entry point to reflect current state (completed phases above pending; items ordered by dependency or phase). Do this without asking unless re-ordering could change meaning.
6. **Update entry point** (ROADMAP.md and/or docs/README.md) to reflect all the above
7. **[confirm if ambiguous]** **Resolve orphans** — docs not referenced in any entry point. If the right home is obvious, add the reference; if ambiguous, ask the user.

### Phase 5: Verify Consistency

After all changes:

1. Confirm every file in `docs/todos/` is referenced in the entry point
2. Confirm no entry point references point to deleted files — fix any that do, autonomously
3. Confirm phase status annotations in ROADMAP.md match reality
4. Confirm all cross-references between TODO files (Parent/Children pointers, plan file paths) are correct and resolvable

## Proactive Trigger Guidance

This skill should be triggered (or suggested) when:

- User explicitly asks to audit, clean up, or check todo docs
- A major implementation task has been completed in the session
- User mentions they finished a feature or refactor that sounds like it might match a todo doc
- User asks to prioritize or plan work (audit first to know what's actually pending)
- Session is wrapping up after significant code changes

## Project Portability

This skill works with **any** project that has a `docs/todos/` directory. It makes no assumptions about:
- Programming language (searches all common source file types)
- Build system (doesn't run builds, only reads and greps)
- Doc format (reads any .md file)

The only assumption is the two-tier pattern: `docs/` for active docs, `docs/todos/` for pending work.

## Related: Task Execution

This skill audits **spec documents** (what to build). For **execution tracking** (how to build it — recursive task decomposition into atomic TODO files), use `/todo-breakdown`. Typical workflow: audit specs first to know what's pending, then use `/todo-breakdown` to decompose the next phase into executable tasks.
