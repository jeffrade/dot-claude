---
name: evaluate
description: Evaluator skill. Validates correctness (Makefile targets pass) and completeness (requirements coverage). Use when agent or user work is complete and needs validation before handoff or acceptance. User invocation: /evaluator:evaluate. Agent invocation: Skill("evaluator:evaluate") with handoff JSON as $ARGUMENTS.
tools: Bash, Read, Glob, Grep, Write
---

# Evaluate

Second-pass critic: validates **correctness** (Makefile targets) and **completeness** (requirements coverage) before accepting work.

Read and internalize these references before executing any step:
- [references/handoff-schema.md](references/handoff-schema.md) — input/output contracts, severity enum, auto-FAIL rule, gap_id generation
- [references/retry-protocol.md](references/retry-protocol.md) — retry rules, failure object schema, sink file, propagation rules
- [references/makefile-checks.md](references/makefile-checks.md) — required targets, escalation paths
- [references/completeness-criteria.md](references/completeness-criteria.md) — requirement sources, scoring, unverifiable handling

---

## Step 1: Detect Invocation Context

Parse `$ARGUMENTS`:

```bash
python3 -c "
import sys, json
args = sys.argv[1]
try:
    data = json.loads(args)
    if isinstance(data, dict) and 'task' in data:
        print('AGENT')
    else:
        print('USER')
except:
    print('USER')
" "$ARGUMENTS"
```

- `AGENT` → use handoff JSON for all inputs
- `USER` → use conversation context

---

## Step 2: Apply Auto-FAIL Rule (agent context only)

If `retry_context.previous_gaps` is present in the handoff JSON, apply the auto-FAIL rule from [references/handoff-schema.md](references/handoff-schema.md) before any other work.

Severity ranks: optional=0, minor=1, should-fix=2, medium=3, high=4, must-fix=5, very-high=6, security-vulnerability=7.

For each gap in `previous_gaps`:
- If severity rank ≥ 5 AND gap `id` NOT in `fixed_in_this_attempt` → **AUTOMATIC FAIL**

Output immediately:
```
## Evaluator Report — FAILED

**Reason:** Auto-FAIL: gap "<description>" (severity: <severity>) was not fixed in this attempt.
**Gap ID:** <id>

### Next Steps
<agent-invoked>: Retry budget: <retry_count>/<max_retries>. Fix the gap above and re-invoke.
```

Stop. Do not proceed to further steps.

---

## Step 3: Source Requirements

**Agent context:**
- Use `requirements` array from handoff JSON if non-empty.
- If `requirements` is empty and `plan_file` is set: read the plan file and extract `- [ ]` lines.

Verify plan file exists if specified:
```bash
test -f "PLAN_FILE_PATH" || echo "MISSING"
```
If missing → non-retriable hard fail: `cause: plan_file_missing`.

**User context:**
- Read requirements from conversation context.
- If a plan file was mentioned, read it for `- [ ]` checklist items.

---

## Step 4: Makefile Gate

Check Makefile exists:
```bash
test -f Makefile && echo "FOUND" || echo "NOT_FOUND"
```

If `NOT_FOUND` → non-retriable hard fail. Report:
```
FAIL: No Makefile found. Non-retriable. Create a Makefile with targets: check, test, smoke, verify, all.
```

Check required targets:
```bash
for target in check test smoke verify all; do
  grep -qE "^${target}\s*:" Makefile \
    && echo "OK: $target" \
    || echo "MISSING: $target"
done
```

If any target missing → follow escalation path in [references/makefile-checks.md](references/makefile-checks.md).

---

## Step 5: Run Makefile Targets

Run sequentially. Capture exit code and stderr for each. Stop on first failure.

```bash
make check 2>&1; echo "EXIT_CODE:$?"
```
```bash
make test 2>&1; echo "EXIT_CODE:$?"
```
```bash
make smoke 2>&1; echo "EXIT_CODE:$?"
```
```bash
make verify 2>&1; echo "EXIT_CODE:$?"
```

Record per target: exit code, last 20 lines of output.

---

## Step 6: Completeness Check

Follow [references/completeness-criteria.md](references/completeness-criteria.md) exactly.

For each requirement, check three signals: git diff, test output, make target output.

Score: `n/total`. Pass = 100%. Partial = fail. Unverifiable = flag with `[?]`, not auto-fail.

---

## Step 7: Evaluate and Report

**If PASS:**

Output report and success JSON from [references/handoff-schema.md](references/handoff-schema.md).

**If FAIL:**

Output report:
```
## Evaluator Report — FAILED

**Task:** <task>
**Attempts:** <retry_count + 1> / <max_retries>

### Makefile Results
- check: [PASS|FAIL (exit N)|NOT RUN (blocked by <target> failure)]
- test: [PASS|FAIL (exit N)|NOT RUN]
- smoke: [PASS|FAIL (exit N)|NOT RUN]
- verify: [PASS|FAIL (exit N)|NOT RUN]

### Completeness
- [x] req — verified in path:line (signal)
- [ ] req — NOT FOUND in codebase
- [ ] req — exists but untested
- [?] req — UNVERIFIABLE (flagged for user review)

### Gaps Found
- { "id": "<gap_id>", "description": "...", "severity": "<severity>", "requirement": "req-N", "section": "..." }

### Next Steps
<user>: Review failures above and decide corrective action.
<agent, not exhausted>: Retrying (attempt <N+1>/<max_retries>)...
<agent, exhausted>: Retry budget exhausted. Escalating to caller.

**Sink file:** ~/.claude/tmp/evaluator-failure-{failure_id}.json
```

**User context:** stop after report.

**Agent context:**
- If `retry_count < max_retries` and `no_retry != true`: increment `retry_count`, re-run from Step 4.
- If exhausted: compute `failure_id`, write sink file, output failure object from [references/retry-protocol.md](references/retry-protocol.md).

### Compute gap_id for each gap found

```bash
python3 -c "
import hashlib
gap_id = hashlib.sha256(str(['DESCRIPTION', 'SEVERITY', 'REQUIREMENT', 'SECTION']).encode()).hexdigest()[:9]
print(gap_id)
"
```

### Write sink file (on exhaustion)

```bash
FAILURE_ID=$(python3 -c "
import hashlib, json, sys
h = hashlib.sha256(str([sys.argv[1], json.loads(sys.argv[2]), int(sys.argv[3])]).encode()).hexdigest()[:9]
print(h)
" "CAUSE" '["evaluator","CALLER_ID"]' RETRY_COUNT)

mkdir -p ~/.claude/tmp
# Write failure JSON to ~/.claude/tmp/evaluator-failure-${FAILURE_ID}.json
```

Report: DONE or BLOCKED.
