---
name: breakdown
description: "Recursive task decomposition for TODO files. Use when the user asks to break down tasks, create subtask files, identify next work, or mentions TODO_N.md files. Also use when discussing task granularity, atomicity of work items, or planning implementation order for a phased roadmap."
allowed-tools: Read, Glob, Grep, Write
---

# TODO Breakdown — Recursive Task Decomposition

Break down non-atomic TODO items into subtask files until every item is atomic and ready to execute.

---

## Data Model: Rose Tree

The TODO stack is a **rose tree** (general ordered tree) serialized as one file per depth level.

```
Tree a = Leaf a | Branch a [Tree a]

where a = (item_id, description, checkpoint)
      Leaf   = atomic task, ready to execute
      Branch = non-atomic task, children in next-level file
```

**Serialization:** Each depth level is stored in `TODO_{N}.md`. A single file contains all nodes at that depth, both leaves and internal nodes. Internal nodes are expanded in `TODO_{N+1}.md`.

**Execution order:** Post-order DFS — all leaves at max depth execute first, then their parents are marked complete, then the next-shallowest incomplete items, bubbling up to the root.

**Expansion:** Only one root-level item from TODO.md is decomposed at a time. The TODO file stack represents the active subtree for that one item.

---

## Tree Links (Critical)

Every node except the root must have an explicit **parent pointer**. Every internal node must have explicit **child pointers**. Without these, completion propagation breaks.

### Parent pointer (in child file)

Each item in `TODO_{N+1}.md` declares which item in `TODO_{N}.md` it decomposes:

```markdown
## 3.1 — ParseAndValidatePrimaryKey Happy Path Tests
**Parent:** 2.4
```

### Child pointer (in parent file)

Each non-atomic item in `TODO_{N}.md` declares where its children live:

```markdown
## 2.4 — Add ParseAndValidatePrimaryKey Tests
**Children:** TODO_3 items 3.1, 3.2
```

Atomic items in the parent have no child pointer — they are leaves at that level.

### File header (maps to parent file)

```markdown
# Subtasks: {description}

Parent: `TODO_{N}.md`
Decomposes: 2.4 → (3.1, 3.2), 2.5 → (3.3, 3.4, 3.5)
```

The `Decomposes` line is the adjacency list for this level's parent→children edges.

---

## Well-Formedness Invariants

Before creating or executing a TODO file, verify these hold. If any are violated, fix the tree before proceeding.

1. **Unique parent** — Every item in `TODO_{N+1}` has exactly one parent in `TODO_N` (injective child→parent mapping).

2. **Complete expansion** — Every non-atomic item in `TODO_N` has ≥1 child in `TODO_{N+1}` (no internal nodes without children).

3. **No orphans** — Every item in `TODO_{N+1}` traces back to a parent in `TODO_N` (no children without parents).

4. **Acyclic** — Guaranteed by depth indexing: depth N+1 > depth N, so no cycles are possible.

5. **Leaf consistency** — Atomic items in `TODO_N` have no children in `TODO_{N+1}` (leaves don't expand).

6. **Depth contiguity** — If `TODO_N` exists, `TODO_{N-1}` must also exist (no skipped levels).

---

## Procedure

### Step 1: Discover the tree

Glob for `TODO*.md` in the working directory. Sort by N to build the file stack. Read the deepest file (max N).

### Step 2: Assess atomicity

Apply the atomicity predicate (see below) to every item in the deepest file. Classify each as LEAF or BRANCH.

### Step 3: Act

**All items are LEAF:** The tree is fully expanded. Report ready. Show the first incomplete leaf (post-order = deepest-first, then left-to-right within a level).

**Some items are BRANCH:** Create `TODO_{N+1}.md`:
- Expand only the BRANCH items into children
- Write the `Decomposes:` header mapping parent→children
- Add `**Parent:** X.Y` to each child item
- Annotate parent items with `**Children:** TODO_{N+1} items ...`
- Assess the new children: if any are still BRANCH, repeat (recurse)

### Step 4: Termination check

Each expansion must strictly reduce scope — every child is a proper subset of its parent's work. The atomicity predicate provides the base case. Finite input + strict reduction = finite depth. If a decomposition produces children that aren't clearly smaller than the parent, stop and flag for human review.

---

## Traversal: "What Do I Work On Next?"

Post-order DFS on the rose tree, serialized as:

```
function next_task(stack):
    N = max depth (highest-numbered TODO file)
    items = read TODO_N.md, in order

    for item in items:
        if item is incomplete:
            return item          # next leaf to execute

    # All items at depth N are complete
    propagate_completion(N)      # mark parents done
    remove TODO_N.md from stack  # or archive — ask human
    return next_task(stack)      # recurse shallower
```

**Completion propagation:** When all children of parent X.Y are complete, X.Y is complete. Check by reading `TODO_{N}.md`, finding items whose `Children:` all appear in the completed set.

**Termination:** The stack shrinks by one file each time the deepest level is fully complete. Eventually the root item in `TODO.md` is marked done, and the next root item is selected for decomposition.

---

## Atomicity Predicate (Leaf Test)

A node is a **leaf** when ALL of:

1. **One concern** — Tests one method, creates one file, or makes one focused edit to one file. Exception: interface + implementation = one concern (inseparable).

2. **Fully determined** — Implementation requires zero design decisions. Code is templated in an ancestor TODO or follows an obvious pattern.

3. **One checkpoint** — Exactly one build/test verification point.

4. **Failure isolation** — If it fails, exactly one thing to investigate.

5. **Self-contained** — No additional source files to read beyond what ancestor plans analyzed.

A node is a **branch** (needs children) when ANY of:

- Tests for ≥2 unrelated methods grouped together
- Multiple file operations that aren't inseparable
- Requires reading new source files to determine approach
- Contains sub-steps with different verification points
- Mixes concerns (implementation + tests, or updates to ≥2 unrelated services)

**Heuristic:** 3–6 tests for one method with shared setup = leaf. 10+ tests for one method = split by happy-path vs error-path. Tests for ≥2 unrelated methods = always split.

---

## Output Format

### File header

```markdown
# Subtasks: {brief description}

Parent: `TODO_{N}.md`
Decomposes: {X.A} → ({N+1}.1, {N+1}.2), {X.B} → ({N+1}.3, {N+1}.4, {N+1}.5)
```

### Item format

```markdown
## {N+1}.1 — {Concise title}
**Parent:** {X.A}

{What to do. Reference ancestor plans for templates: "See TODO_1 Step 2."}

**Checkpoint:** `make test` — {expected result}
```

### Rules

- Item IDs use the file's depth as prefix: TODO_3.md → 3.1, 3.2, 3.3
- Every item has a `**Parent:**` line (the parent item ID in the previous-level file)
- Every item has a `**Checkpoint:**` line with exact command + expected result
- Reference ancestor plans for code — don't duplicate
- When annotating a parent item with its children, append a `**Children:**` line (don't rewrite the item)

---

## Completion Flow

When all items in `TODO_{N}.md` are complete:

1. Mark their parent items in `TODO_{N-1}.md` as done (check via `Children:` links)
2. If all items in `TODO_{N-1}.md` are now done, repeat upward
3. Eventually bubbles to `TODO.md` — mark the strategic item done
4. Select the next root item from `TODO.md` for decomposition

Whether to delete or archive completed TODO files: ask the human on first completion.

---

## Edge Cases

**No TODO.md exists:** Ask the user. Do not create one without direction.

**Item is borderline atomic:** Break it down. An extra tree level costs nothing. A non-atomic item discovered mid-execution wastes real time.

**Parent plan has code templates:** Reference with "See TODO_1 Step N" — the ancestor is the source of truth, not the child.

**Expansion doesn't reduce scope:** Stop. This means the atomicity definition is wrong for this domain, or the item can't be decomposed further. Flag for human review.

**Mixed leaves and branches at one level:** Normal. Only expand branches. Leaves at that level are executed after the deeper subtree completes (post-order).
