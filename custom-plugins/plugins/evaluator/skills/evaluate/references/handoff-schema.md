# Handoff Schema

Defines input/output contracts for agent-to-agent (A2A) invocations of `evaluator:evaluate`.

## Input (A2A invocation)

Pass as JSON string in `$ARGUMENTS` when invoking `Skill("evaluator:evaluate")`.

```json
{
  "task": "brief description of what was done",
  "requirements": ["req 1", "req 2"],
  "plan_file": "docs/superpowers/plans/YYYY-MM-DD-foo.md",
  "retry_count": 0,
  "max_retries": 3,
  "no_retry": false,
  "caller_agent_id": "agent-abc123",
  "propagation_path": [],
  "retry_context": {
    "previous_gaps": [
      {
        "id": "e3b0c44a1",
        "description": "brief gap description",
        "severity": "must-fix",
        "requirement": "req-N",
        "section": "Section Name from spec or plan where gap was found (e.g., 'Agent Stack Propagation', 'Makefile Gate')"
      }
    ],
    "fixed_in_this_attempt": ["e3b0c44a1"]
  }
}
```

**Field rules:**
- `task`: max 200 chars. Violation = `malformed_input` non-retriable hard fail.
- `requirements`: max 10 items. Violation = `malformed_input` non-retriable hard fail.
- `retry_context`: omit on attempt 1. Required on attempts 2+.
- `plan_file`: optional. If provided and file doesn't exist = non-retriable hard fail.

## Gap ID Generation

`gap_id = sha256(str([description, severity, requirement, section]))[0:9]`

Compute via Bash:
```bash
python3 -c "import hashlib; print(hashlib.sha256(str(['DESCRIPTION', 'SEVERITY', 'REQUIREMENT', 'SECTION']).encode()).hexdigest()[:9])"
```

Deterministic — same gap fields always produce the same ID across any agent. Replace DESCRIPTION, SEVERITY, REQUIREMENT, SECTION with actual values.

## Severity Enum (ordered low → critical)

| Value | Rank |
|-------|------|
| `optional` | 0 |
| `minor` | 1 |
| `should-fix` | 2 |
| `medium` | 3 |
| `high` | 4 |
| `must-fix` | 5 |
| `very-high` | 6 |
| `security-vulnerability` | 7 |

## Auto-FAIL Rule

Check immediately if `retry_context` is present:

For each gap in `previous_gaps`:
- If severity rank ≥ 5 (`must-fix`) AND gap `id` NOT in `fixed_in_this_attempt` → **automatic FAIL**, no further evaluation.

## Output on Success

```json
{
  "evaluator_failure": false,
  "pass": true,
  "attempts": 1,
  "makefile_results": {
    "check": { "exit_code": 0 },
    "test":  { "exit_code": 0 },
    "smoke": { "exit_code": 0 },
    "verify":{ "exit_code": 0 }
  },
  "completeness": {
    "score": "4/4",
    "verified": ["req 1", "req 2", "req 3", "req 4"],
    "unverifiable": []
  }
}
```

## Output on Failure

See retry-protocol.md for the failure object schema and propagation rules.
