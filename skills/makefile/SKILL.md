---
name: makefile
description: "This skill should be used when the user creates, edits, reviews, or debugs Makefiles, when reading or modifying any file named Makefile or Makefile.*, when discussing make targets, .PHONY declarations, make variables, make recipes, or build pipelines using GNU Make. Also load when the user mentions 'make all', 'make clean', 'make test', 'make help', scripts/ delegation, or any Makefile anti-pattern, even if they don't explicitly say 'Makefile'."
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# Makefile Skill

Expert guidance for writing, reviewing, modifying, and debugging Makefiles across all major languages (Java, Go, Python, Rust, Node.js, C/C++, infrastructure/DevOps). Enforce DevixLabs conventions on every Makefile touched.

---

## DevixLabs Conventions (Hard Rules)

These five conventions are mandatory for all Makefiles produced or reviewed. They take precedence over any conflicting general advice.

### Convention 1: Target Visibility — Public Top, Private Bottom

Public targets (user-facing) go at the top. Private targets (called by other targets or LLM agents only) are prefixed with `_` and placed at the bottom, below a clear separator comment.

```makefile
# --- PUBLIC TARGETS (user-facing) -------------------------------------------

help:
	@echo "Available commands:"
	@echo "  make all   - Full build pipeline"
	@echo "  make test  - Run tests"
	@echo "  make clean - Remove artifacts"

all: clean _check build test _post-build
	@echo "Done"

test: build
	@scripts/test.sh

clean:
	@scripts/clean.sh

build: _check
	@scripts/build.sh

# --- PRIVATE TARGETS (called by other targets / LLM agents) -----------------
# Internal implementation details. Do NOT call directly.

.PHONY: _check _post-build

_check:
	@scripts/check.sh

_post-build:
	@scripts/post-build.sh
```

### Convention 2: Complexity -> scripts/ Directory

If a recipe cannot be expressed as 1-3 simple commands, delegate to a bash script in `scripts/`. Scripts are independently testable, lintable (`shellcheck`), and maintainable. Complex control flow belongs in shell, not in Makefile recipes.

### Convention 3: Structured Logging & Exit Status

Produce output that CI/CD pipelines and LLM agents can parse:
- Use `@echo` for status messages (suppress the echo command with `@`)
- Prefix success with a checkmark and failure with an X for scannable output
- Scripts MUST exit non-zero on failure (Make propagates this automatically)
- Never use `-` prefix to suppress errors on targets that should fail loudly
- The `-` prefix is acceptable ONLY on `clean` targets

### Convention 4: `help` as Default Target

The first target in every Makefile MUST be `help:`. Use simple `@echo` statements (not the CloudPosse `awk` pattern). Readable by humans and LLMs alike.

### Convention 5: LLM Guardrail Comment

Include near the top of every Makefile:
```makefile
# Note to LLMs: DO NOT MUDDY THIS FILE UP. Create a bash script in scripts/ if complex logic is needed.
```

---

## Quick Reference

### Variable Assignment Operators

| Operator | Name | Behavior |
|----------|------|----------|
| `:=` | Simple (immediate) | Expanded once at definition time — **use by default** |
| `=` | Recursive (lazy) | Expanded every time referenced — risk of infinite loops |
| `?=` | Conditional | Sets only if not already defined — use for user-overridable defaults |
| `+=` | Append | Appends with space separator |

### Automatic Variables

| Variable | Expands to |
|----------|-----------|
| `$@` | Target name |
| `$<` | First prerequisite only |
| `$^` | All prerequisites (deduplicated) |
| `$+` | All prerequisites (with duplicates) |
| `$?` | Prerequisites newer than target |
| `$*` | Stem matched by `%` in pattern rule |

### Recipe Line Prefixes

| Prefix | Effect |
|--------|--------|
| `@` | Suppress command echo (silence) |
| `-` | Ignore non-zero exit (continue on error) |
| `+` | Always execute, even under `make -n` |

### Top Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Spaces instead of tabs | Configure editor for tab indentation in Makefiles |
| Missing `.PHONY` | Declare every non-file target as `.PHONY` |
| Using `=` instead of `:=` | Use `:=` by default to avoid re-evaluation and infinite loops |
| Bare `*` in variable assignment | Use `$(wildcard *.c)` — bare `*` stores a literal string |
| `$(wildcard **/*.c)` for recursion | Does NOT work in GNU Make — use `$(shell find ...)` |
| Long bash logic in recipes | Move to `scripts/` and delegate |
| `:` in target names | Breaks Make dependency parsing — use `/` delimiter |
| Bare `make` in recipes | Use `$(MAKE)` to propagate flags like `-j` |
| No `help` target | Always provide `help` as the first (default) target |
| `clean` depending on `check` | `clean` must be self-contained (work when tooling is broken) |
| Missing `export` for script vars | Command-line vars don't reach subprocesses without `export` |

---

## Convention Compliance Checklist

When reviewing or writing any Makefile, verify:

1. `help` is the first target (default when `make` is run bare)?
2. All non-file targets declared `.PHONY`?
3. Public targets above separator comment, `_`-prefixed private targets below?
4. Complex recipes (>3 simple commands) delegated to `scripts/`?
5. Status messages use structured logging?
6. Recipe indentation uses tabs (not spaces)?
7. Variables use `:=` by default (`:=` unless lazy evaluation is specifically needed)?
8. `clean` target has no prerequisites (self-contained)?
9. LLM guardrail comment present near top of file?
10. No bare `*` in variable assignments (use `$(wildcard ...)`)?

---

## References

Read on demand — do not load into context upfront. Use `Read` with `offset`/`limit` to pull specific sections.

- **`references/best-practices-knowledge.md`** (1,848 lines) — Comprehensive best practices compiled from 14+ sources. Sections: Philosophy, Core Syntax, Variables, Targets, Pattern Rules, Build Organization, Advanced Patterns, Conditionals, Functions, Output Control, CloudPosse Patterns, Best Practices Summary, Practical Examples.

- **`references/gnu-make-manual-extract.md`** (1,426 lines) — Authoritative GNU Make manual sections. Sections: Variable Flavors, Setting Variables, Automatic Variables, Pattern Rules, Wildcards, Phony/Special Targets, Implicit Rules, Functions Reference, Conditionals, Recipe Execution, Include Directive, Recursive Make, Options Summary.

**Primary online references** (fetch via WebFetch when the above files are insufficient):
- Full Manual Index: https://www.gnu.org/software/make/manual/html_node/index.html
- Concept Index: https://www.gnu.org/software/make/manual/html_node/Concept-Index.html

---

## Agent Escalation

For complex tasks that exceed quick guidance, dispatch the `makefile-expert` agent:

- Writing a complete Makefile from scratch for a new project
- Deep review of multiple Makefiles across a project
- Debugging obscure or multi-layered Make errors
- Generating `scripts/` stubs with proper `shellcheck` validation
- Comprehensive Makefile restructuring to match conventions
