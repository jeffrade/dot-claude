# ~/.claude

System-wide configurations and knowledge base for Claude Code.

---

## What's tracked

| Directory / File | Purpose |
|-----------------|---------|
| `CLAUDE.md` | Global Claude Code instructions |
| `agents/` | Custom agents (`appget-specialist`, `skill-architect`) |
| `skills/` | Personal skills (`appget-pipeline`, `appget-contracts`, `iac-conventions`, `dns-setup`) |
| `docs/` | Saved Anthropic Claude Code reference docs |

## What's ignored (machine-specific or cache)

| Directory / File | Reason |
|-----------------|--------|
| `plugins/` | Contains hard-coded absolute paths (`/home/jrade/`) and cached plugin code |

---

## New machine setup

Skills and agents are committed — nothing to do for those.

Plugins must be reinstalled (cache is gitignored):

```
/plugin install pr-review-toolkit@claude-plugins-official
/plugin install claude-md-management@claude-plugins-official
/plugin install playwright@claude-plugins-official
/plugin install code-simplifier@claude-plugins-official
```
