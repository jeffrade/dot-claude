# Makefile Checks

Defines what the evaluator checks for in a project's Makefile.

## Required Targets

All five must exist in the Makefile. Check with:

```bash
for target in check test smoke verify all; do
  grep -qE "^${target}\s*:" Makefile \
    && echo "OK: $target" \
    || echo "MISSING: $target"
done
```

Any missing target = hard fail. Report which targets are missing.

### Target Definitions

| Target | Purpose | Evaluator runs it? |
|--------|---------|-------------------|
| `check` | Static checks — lint, format, type-check | Yes |
| `test` | Unit and integration tests | Yes |
| `smoke` | Minimal live invocation sanity check | Yes |
| `verify` | End-to-end verification | Yes |
| `all` | Aggregator: runs the four above + private targets | No (structural only) |

### Execution Order

Evaluator runs: `check` → `test` → `smoke` → `verify`

First failure stops the sequence. Subsequent targets are marked `NOT RUN` in the report.

### `all` Target Convention

`all` must exist but is NOT run by the evaluator. Its role is project-level convenience.

Expected structure:
```makefile
all: _private_target_1 check test smoke verify _private_target_2
```

Underscore-prefixed targets (e.g., `_build`, `_generate`) are private — not required by the evaluator, but `all` must invoke them where needed. The evaluator only verifies `all` is declared.

## Missing Targets: Escalation Path

### User context
Report the missing targets. Stop. Example:
```
FAIL: Makefile is missing required targets: [smoke, verify]
Add these targets to your Makefile before re-running /evaluator:evaluate.
```

### Agent context
Spawn the `makefile` skill (`~/.claude/skills/makefile`) with instruction:
> "Add the following missing Makefile targets: [list]. Follow the conventions in makefile-checks.md."

```
Skill("makefile", "Add missing Makefile targets: smoke, verify. Follow conventions in ~/.claude/custom-plugins/plugins/evaluator/skills/evaluate/references/makefile-checks.md.")
```

This counts as retry #1. After the skill returns, re-invoke `evaluator:evaluate` with `retry_count` incremented.

## No Makefile Found

If no `Makefile` file exists at the project root — non-retriable hard fail. Do not attempt to create one. Report:
```
FAIL: No Makefile found. This is a non-retriable failure.
Create a Makefile with targets: check, test, smoke, verify, all.
```
