# Retry Protocol

Defines retry behavior and n-level agent stack propagation for `evaluator:evaluate`.

## Retry Rules

- **Default max retries:** 3 (override via `max_retries` in handoff input)
- **Retry scope:** per evaluation session — not cumulative across sessions
- **Retry counter:** `retry_count` in handoff input. Increment before each re-run.
- **`no_retry: true`** in input suppresses all retry logic regardless of `max_retries`

### What Counts as a Retry

Each full evaluate cycle = 1 retry consumed.

Spawning the `makefile` skill for missing targets also counts as retry #1. After the makefile skill returns, re-invoke `evaluator:evaluate` with `retry_count: 1`.

### Non-Retriable Failures

These consume no retry — immediate escalate:

| Cause | Condition |
|-------|-----------|
| `no_makefile` | No Makefile file found in project root |
| `malformed_input` | Handoff JSON invalid or token budget exceeded |
| `plan_file_missing` | `plan_file` path in handoff doesn't exist on disk |
| `subagent_crash` | Spawned agent returned no typed result (timeout, OOM, tool error) |

### On Retry Exhaustion

When `retry_count >= max_retries`:
1. Produce failure object (schema below)
2. Compute `failure_id` and write sink file
3. Output failure object — propagate up the stack

## Failure Object Schema

```json
{
  "evaluator_failure": true,
  "exhausted": true,
  "handled_by": null,
  "no_retry": true,
  "propagation_path": ["evaluator", "caller-agent-id"],
  "cause": "make_test_failed",
  "retry_history": [
    { "attempt": 1, "failed": "make test", "exit_code": 1, "stderr": "last 20 lines..." }
  ],
  "sink_file": "~/.claude/tmp/evaluator-failure-{failure_id}.json"
}
```

**`cause` values:** `make_check_failed`, `make_test_failed`, `make_smoke_failed`, `make_verify_failed`, `completeness`, `subagent_crash`, `no_makefile`, `missing_targets`, `malformed_input`, `plan_file_missing`

## Sink File

Compute `failure_id`:
```bash
python3 -c "
import hashlib, json, sys
cause = sys.argv[1]
path = json.loads(sys.argv[2])
retry = int(sys.argv[3])
h = hashlib.sha256(str([cause, path, retry]).encode()).hexdigest()[:9]
print(h)
" "CAUSE" '["evaluator","agent-id"]' RETRY_COUNT
```

Write failure object to disk before propagating:
```bash
mkdir -p ~/.claude/tmp
# write JSON to ~/.claude/tmp/evaluator-failure-{failure_id}.json
```

The top-level session checks `~/.claude/tmp/evaluator-failure-*.json` on completion to surface any failures that were swallowed by intermediate agents.

## N-Level Propagation Rules

When an agent receives a result where `evaluator_failure: true` AND `exhausted: true`:

1. **Pass through:** append own agent ID to `propagation_path`, return the object verbatim to caller.
2. **Cycle detection:** if own ID is already in `propagation_path` — stop. Write a new sink file with `cause: "cycle_detected"`. Do not propagate further.
3. **Subagent crash:** if spawned agent returns no typed object at all — parent synthesizes: `{ "evaluator_failure": true, "exhausted": true, "cause": "subagent_crash", ... }`, writes sink file, propagates up.
4. **Handling:** if this agent CAN resolve the failure — set `handled_by: "<agent-id>"`, act on it, do NOT re-invoke evaluator if `no_retry: true`.
