# Completeness Criteria

Defines how `evaluator:evaluate` sources requirements and scores coverage.

## Requirement Sources (Priority Order)

1. **`requirements` array in handoff JSON** (agent context, highest priority)
2. **Plan file checklist items** — parse `- [ ]` and `- [x]` lines from the file at `plan_file`
3. **Conversation context** — requirements mentioned in the current session (user context only)

Use the highest-priority source that has content. If handoff has a non-empty `requirements` array, use it exclusively.

## Verification Method Per Requirement

For each requirement string, verify across three signals:

### Signal 1: Code Exists (git diff / git show)

Check both uncommitted and recently committed changes:
```bash
# Uncommitted changes (working tree + index)
git diff HEAD --stat
git diff HEAD -- "*.py" "*.go" "*.java" "*.ts" "*.js" "*.sh"
# Most recent commit (catches work already committed this session)
git show HEAD --stat
git show HEAD -- "*.py" "*.go" "*.java" "*.ts" "*.js" "*.sh"
```

If `plan_file` is in handoff and the plan file path contains a date prefix (e.g., `2026-04-19`), also check `git log --oneline --since="24 hours ago"` to find relevant commits.

Search the diff/show output for keywords from the requirement. If relevant code changes appear in either source → code exists.

### Signal 2: Tested
Check test output captured from `make test` for lines referencing the requirement's key terms. If test output contains the term and exit code was 0 → tested.

### Signal 3: Passes Make Targets
If `make verify` passed and the requirement relates to a verifiable behavior → passes.

## Scoring

```
score = verified_count / total_requirements
```

- **Verified:** at least 1 signal confirms the requirement. More signals = higher confidence (noted in report), but 1 is sufficient to count as verified.
- **Pass threshold:** 100% (all requirements verified)
- **Partial:** any unverified requirement with a code artifact = FAIL
- **Unverifiable:** requirement has no code artifact to check (e.g., "document the API") = flag in report, NOT auto-failed. User decides.

## Report Format Per Requirement

```
- [x] req text — verified in src/foo.py:42 (git diff + make test)
- [ ] req text — NOT FOUND in codebase
- [ ] req text — exists (src/bar.go) but untested (not in make test output)
- [?] req text — UNVERIFIABLE (no code artifact; flagged for user review)
```

## Handling Unverifiable Requirements

An unverifiable requirement is one where no code artifact can confirm it:
- Documentation tasks
- UX or process requirements
- Requirements that reference external systems not in the diff

Flag these with `[?]` in the report. They do not count against the score but are surfaced for user review. If the user is unavailable (deep A2A chain), include them in the failure object's `completeness.unverifiable` list.
