# Audit Criteria for docs/todos/ Documents

## Status Categories

Each todo doc is classified into one of these statuses after audit:

### COMPLETED
The work described in the doc is fully implemented and verified.

**Signals:**
- Git commits exist that implement the described feature/refactor
- Source code matches what the doc specifies (classes exist, methods exist, tests pass)
- No remaining unchecked items in the doc's checklist (if it has one)

**Action:** Delete the file. Remove from ROADMAP.md and docs/README.md index.

### PARTIALLY DONE
Some items in the doc are implemented but others remain.

**Signals:**
- Some classes/methods/tests exist but not all
- Git commits cover part of the described work
- Checklist has a mix of done and not-done items

**Action:** Edit the doc to mark completed items (strikethrough or remove), leaving only remaining work. Update any stale references (file paths, class names, test counts).

### STALE
The doc references code, patterns, or state that no longer exists or has changed.

**Signals:**
- File paths in the doc don't exist in the codebase
- Class/method names referenced have been renamed or removed
- Test counts or build commands are outdated
- Dependencies or prerequisites have changed

**Action:** Update stale references to match current codebase. Flag to user if the staleness is severe enough to warrant a rewrite.

### CURRENT
The doc accurately describes pending work that hasn't been started.

**Signals:**
- Referenced files/classes still exist in expected locations
- Prerequisites listed are still accurate
- No git commits address the described work

**Action:** No changes needed. Confirm in report.

### BLOCKED
The doc describes work that can't proceed due to unmet prerequisites.

**Signals:**
- Doc explicitly states a dependency on another doc/phase
- The blocking work hasn't been completed

**Action:** Verify the blocking dependency is still accurate. Note in report.

## Cross-Reference Techniques

### Git History Check
```bash
# Find commits mentioning key terms from the doc
git log --oneline --all --grep="<key term>" | head -10

# Check if specific files were created/modified
git log --oneline --all -- <file path>
```

### Codebase State Check
```bash
# Check if classes/interfaces exist
grep -r "class ClassName" src/ --include="*.java"
grep -r "interface InterfaceName" src/ --include="*.java"

# Check if methods exist
grep -r "methodName" src/ --include="*.java"
```

### Freshness Indicators
- Doc last modified date vs recent commit dates
- Whether doc references match current file tree
- Whether test counts match actual test suite size

## Entry Point Maintenance

If the project has a `docs/todos/ROADMAP.md`:
- Verify every todo doc in the directory is referenced in ROADMAP.md
- Verify no ROADMAP.md references point to deleted files
- Update phase status annotations based on audit findings

If the project has a `docs/README.md`:
- Verify the Pending Work section matches the current docs/todos/ contents
- Update phase/status info to match ROADMAP.md
