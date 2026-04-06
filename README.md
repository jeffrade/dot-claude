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
| `custom-plugins/` | Devix Labs custom marketplace (`docs-todos-auditor`, `java-dev-toolkit`) |
| `Makefile` | Plugin management commands (`make help` for details) |

---

## New machine setup

Skills and agents are committed — nothing to do for those.

Plugins must be reinstalled (cache is gitignored). Use the Makefile:

```bash
make setup            # Add marketplaces + install all plugins (full new-machine setup)
make add-marketplaces # Register third-party marketplace sources
make install-plugins  # Install all marketplace plugins
make update-plugins   # Update all installed plugins to latest
make list-plugins     # Show installed plugins and status
```

### Marketplaces

| Marketplace | Source | Plugins used |
|-------------|--------|--------------|
| `claude-plugins-official` | Built-in (Anthropic) | pr-review-toolkit, claude-md-management, playwright, code-simplifier |
| `devix-labs` | `~/.claude/custom-plugins/` (local) | docs-todos-auditor, java-dev-toolkit |
| `claude-code-plugins-plus` | [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) | openbb-terminal |
