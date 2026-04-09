# ~/.claude Maintenance TODOs

Status: active

---

## 1 — Verify and fix hardcoded path in settings.json

**File:** `settings.json` line 209

The devix-labs marketplace entry uses an absolute path:
```json
"path": "/home/jrade/.claude/custom-plugins"
```

This breaks on macOS (`/Users/jrade/`), WSL, or any other username. Should be `~/.claude/custom-plugins` — but first verify Claude Code expands `~` in marketplace path configs. If `~` is not supported, this may be intentional and acceptable.

**Steps:**
1. Check Claude Code docs or test empirically: does `~` work in a marketplace `path` field?
2. If yes: edit `settings.json` line 209, change to `"path": "~/.claude/custom-plugins"`
3. Run `make list-plugins` to confirm devix-labs marketplace still loads

**Checkpoint:** `make list-plugins` shows `docs-todos-auditor` and `java-dev-toolkit` from devix-labs marketplace

---

## 2 — Clean up duplicate plugin cache entries

Three plugins have stale cached versions from the now-defunct `claude-code-plugins` marketplace (installed 2026-03-10) alongside current versions from `claude-plugins-official`:

- `feature-dev`
- `security-guidance`
- `frontend-design`

Uninstall the old marketplace versions to reduce cache noise. Only `claude-plugins-official` versions are active and should remain.

**Checkpoint:** `make list-plugins` shows no duplicate entries; all three plugins resolve to `claude-plugins-official` versions only
