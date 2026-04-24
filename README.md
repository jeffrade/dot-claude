# ~/.claude

System-wide configurations and knowledge base for Claude Code.

---

## What's tracked

| Directory / File | Purpose |
|-----------------|---------|
| `CLAUDE.md` | Global Claude Code instructions |
| `agents/` | Custom agents (`makefile-expert`, `skill-architect`) |
| `skills/` | Personal skills (`makefile`, `todo-breakdown`, `iac-conventions`, `dns-setup`) |
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

### Useful prompts (for humans, by humas)

#### Confidence Intervals on Specs and Plans
```
/plugin-dev:create-plugin Review the @<FILE>.md and ultrathink on the entire <NAME_FOR> file. Launch Opus sub-Agents to critique and give feedback on what can be improved with THEIR confidence rating (0%-100%) of the current section they are reviewing (BEFORE their suggestions are stated and applied) so that you can keep itertating on the plan until every section reaches a confidence rating of 90% (cap iterations to a maximum of 6). Each section MUST have edge cases in <WHAT_FILE_DOES> that the <GOAL_OF_FILE>. Any questions? 
```

