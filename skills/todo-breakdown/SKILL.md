---
name: todo-breakdown
description: "This skill should be used when the user asks to break down tasks, create subtask files, identify next work, implement/execute TODO items, or mentions TODO_N.md files. Also use when discussing task granularity, atomicity of work items, planning implementation order for a phased roadmap, or when a task seems too large to tackle directly. Trigger even if the user just says 'break this down' or 'what should I work on next' in the context of a TODO-driven workflow. CRITICAL: Also trigger when the user asks to implement, execute, or work on TODO*.md files — this skill defines the completion marking protocol ([DONE] prefix, bottom-up propagation) that MUST be followed during and after execution."
allowed-tools: Read, Glob, Grep, Write, Edit
version: 0.6.0
---

# TODO Breakdown — Recursive Task Decomposition

Break down non-atomic TODO items into subtask files until every item is atomic and ready to execute.

**Conciseness rule:** TODO_N.md files must be ~100-150 lines max. Items are titles + brief descriptions + checkpoints. No complete code dumps — the executor reads source files at execution time.

---

## Data Model: Rose Tree

The TODO stack is a **rose tree** (general ordered tree) serialized as one file per node group.

```
Tree a = Leaf a | Branch a [Tree a]

where a = (item_id, description, checkpoint)
      Leaf   = atomic task, ready to execute
      Branch = non-atomic task, children in another file
```

### File Naming

- `TODO.md` is the **root**. Items use plain numeric IDs: `1`, `2`, `3`, ...
- `TODO_N.md` files use **sequential indices** (N=1, 2, 3...). Items use prefix `N.`: `N.1`, `N.2`, ...
- N is a sequential index, **NOT a depth level**. Multiple files can coexist, each decomposing different root items or sub-items.
- Tree structure is tracked via explicit `Parent:` / `Children:` pointers, not implied by N.
- Multiple root items (or groups like phases) can be decomposed upfront into separate files.

### File Status

TODO_N.md files have a `Status` in their header:

- **`Status: active`** — Currently being worked on. The traversal algorithm starts here.
- **`Status: planned`** — Pre-planned breakdown for future work. May need revision when activated.

When a `planned` file becomes the next to work on, the executor **must verify** the breakdown against the current codebase before executing (see Execution Protocol).

**Execution order:** Post-order DFS within each file — deepest leaves first, then parents marked complete, bubbling up to root.

---

## Tree Links

Every node except the root needs a **parent pointer**. Every non-leaf needs **child pointers**. Without these, completion propagation breaks.

**Parent pointer** (in child file): `**Parent:** 2.4`
**Child pointer** (in parent file): `**Children:** TODO_3 items 3.1, 3.2`
**File header**: `Parent: TODO_{N}.md` + `Decomposes: 2.4 → (3.1, 3.2)`

---

## Completion Marking

Prepend `[DONE]` to the item heading:

```markdown
## [DONE] 3.1 — UserService.Create Happy Path Tests
```

Use the Edit tool to prepend `[DONE] ` to the `## ` heading. Do not rewrite the rest of the item.

### Deferred Items

Items explicitly marked as deferred (e.g., "Deferred to Phase 2") are NOT incomplete — they are intentionally out-of-scope for the current decomposition. Deferred items:
- Do NOT block parent completion
- Do NOT need `[DONE]` prefix (they were never in-scope)
- Are noted in the parent TODO.md for future planning

When checking "are all children done?", skip deferred items.

---

## Well-Formedness Invariants

1. **Unique parent** — Every child has exactly one parent (tracked via `Parent:` pointer).
2. **Complete expansion** — Every non-atomic item has at least one child.
3. **No orphans** — Every child traces back to a root item via parent pointers.
4. **Acyclic** — Guaranteed by parent pointer direction (children always point up).
5. **Leaf consistency** — Atomic items have no children.

---

## Procedure

### Step 1: Discover the tree

Glob for `TODO*.md` in the working directory. Sort by N. Read the deepest file.

### Step 2: Assess atomicity

Apply the atomicity predicate to every incomplete item. Classify each as LEAF or BRANCH.

### Step 3: Act

**All items are LEAF:** Tree is fully expanded. Report the first incomplete leaf.

**Some items are BRANCH:** Create the next `TODO_{N}.md` (where N is the next unused index):
- Expand BRANCH items into children
- Write `Decomposes:` header with `Status: active` (or `planned` for future work)
- Add `**Parent:**` to each child
- Annotate parents with `**Children:**`
- If new children are still BRANCH, recurse into a new file

### Step 4: Termination check

Each expansion must strictly reduce scope. If children aren't clearly smaller than the parent, flag for human review.

---

## Atomicity Predicate

A node is a **leaf** when ALL of:

1. **One concern** — One file, one method, or one focused edit. Exception: interface + implementation = one concern.
2. **One checkpoint** — Exactly one build/test verification point.
3. **Failure isolation** — If it fails, exactly one thing to investigate.

A node is a **branch** when ANY of:

- Multiple unrelated file operations
- Requires reading new source files to determine approach
- Sub-steps with different verification points
- Mixes concerns (implementation + tests for unrelated code)

---

## Output Format

### File header

```markdown
# Subtasks: {brief description}

Status: active | planned
Parent: `TODO.md` (or `TODO_{M}.md` if decomposing a sub-item)
Decomposes: #X → (N.1, N.2), #Y → (N.3, N.4)
```

### Item format

```markdown
## N.1 — {Concise title}
**Parent:** #X

**Create/Modify:** `path/to/File.cs`

{1-3 sentences: what this does, key design decisions if any.}

**Checkpoint:** `{build/test command}` — expected result
```

For test items, list test cases in a table (name + what it asserts) rather than writing complete test bodies.

### Rules

- Item IDs use the file's N as prefix: TODO_3.md items are 3.1, 3.2, 3.3
- Every item has `**Parent:**` and `**Checkpoint:**` lines
- Include interface/contract definitions when they ARE the design decision
- Omit complete file contents — the executor reads source files during execution
- When annotating a parent with children, append `**Children:**` (don't rewrite the item)

---

## Execution Protocol

When executing a leaf node:

1. **Read source files** at execution time — don't rely on code in the plan being current.
2. **Run the checkpoint.** Every leaf has a `**Checkpoint:**` line. Do not mark [DONE] until it passes.
3. **Document deviations.** If the implementation differs from the plan, add a `**Deviation:**` note to the leaf before marking [DONE].
4. **Do not add scope.** If you notice something extra that should be done, note it for the human. Execute exactly what the plan specifies.

### Activating a Planned File

When a `Status: planned` file becomes the next to work on:

1. **Change status** to `Status: active`.
2. **Verify the breakdown** — read source files referenced by each item, check git log for changes since the file was created. The plan was written with incomplete information; the codebase may have evolved.
3. **Revise if needed** — update, split, merge, or remove items that no longer match reality. Add a `**Revised:**` note explaining what changed and why.
4. **Then execute** normally, starting from the first incomplete leaf.

---

## Traversal: "What Do I Work On Next?"

```
function next_task(files):
    # 1. Find the active file
    active = find file with Status: active
    if active:
        for item in active (in order):
            if item is incomplete and not deferred: return item
        # All items complete — finish this file
        propagate_completion(active)   # mark parents [DONE] in parent file
        delete active                  # REQUIRED — completed files are ephemeral

    # 2. Activate the next planned file
    planned = find lowest-N file with Status: planned
    if planned:
        activate(planned)   # Status: planned → active, verify breakdown
        return next_task(files)

    # 3. No files left — all work complete
    return null
```

**Completion propagation:** When all non-deferred children of parent X are `[DONE]`, mark X as `[DONE]` in the parent file (identified via `Parent:` header).

### MANDATORY: Delete Completed Non-Root Files

When all items in a non-root `TODO_N.md` are `[DONE]` (or deferred), **you MUST delete the file immediately.** Non-root TODO files are ephemeral work-tracking artifacts, not permanent documentation. Root `TODO.md` is never deleted.

**This is not optional.** A completed `TODO_N.md` left on disk creates confusion about what work remains. Delete it in the same response where you mark the last item `[DONE]`.

---

## Edge Cases

- **No TODO.md exists:** Ask the user.
- **Borderline atomic:** Break it down. An extra level costs nothing.
- **Expansion doesn't reduce scope:** Stop. Flag for human review.
- **Mixed leaves and branches:** Normal. Only expand branches.
- **Execution deviates from plan:** Document in the leaf node before marking [DONE]. Propagate significant deviations to sibling leaves.
