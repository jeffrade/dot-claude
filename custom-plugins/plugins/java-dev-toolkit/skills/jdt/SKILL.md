---
name: jdt
description: Java development toolkit — review, explore, test, design, or implement Java code using specialized agents guided by Effective Java principles
argument-hint: "<action> [target]"
tools: Agent
---

Single entry point for the java-dev-toolkit. Routes to the right specialized agent based on the action keyword.

## Usage

```
/jdt review [file-or-scope]     — Code review against Effective Java and anti-patterns
/jdt explore [path-or-topic]    — Map architecture, trace flows, analyze dependencies
/jdt test [file-or-action]      — Write tests, analyze coverage, assess testability
/jdt design <topic>             — Design modules, interfaces, data models
/jdt impl <task>                — Implement or refactor production code
```

## Routing Rules

Parse the FIRST word of the arguments to determine the action:

| First word | Agent to dispatch | Role |
|---|---|---|
| `review` | **java-reviewer** | Observe and report findings — never modify code |
| `explore` | **java-navigator** | Map architecture, trace paths, identify patterns |
| `test` | **java-tester** | Write JUnit 5 tests, analyze coverage gaps |
| `design` | **java-architect** | Design systems, modules, interfaces — no code |
| `impl` | **java-developer** | Write or refactor production Java code |

If no action keyword is recognized, ask the user which action they want.

## Dispatch Instructions

When dispatching any agent, ALWAYS include these instructions:

> **Step 1:** Use Glob to find `**/jdt/references/core-principles.md`. The directory containing this file is your reference root.
> **Step 2:** Read `core-principles.md` and `index.md` from that directory.
> **Step 3:** Read the role-specific reference (see below).

### Per-agent reference loading:

- **java-reviewer**: Also read `review-checklist.md` and `anti-patterns.md`
- **java-navigator**: Load Tier 2 references on-demand as topics arise
- **java-tester**: Also read `testing-guide.md`
- **java-architect**: Also read `architecture-guide.md`
- **java-developer**: Also read `implementation-guide.md`

## Action Details

### `/jdt review [target]`
- No target: review all uncommitted changes via `git diff`
- File path: review that specific file
- Directory: review all `.java` files in that directory
- Output: severity-rated findings report (CRITICAL/WARNING/INFO) with Effective Java citations

### `/jdt explore [target]`
- No target: full breadth-first project exploration
- Path: focus on that package or module
- Topic (quoted): trace that topic through the codebase (e.g., `"payment flow"`)
- Output: architecture overview, module map, dependencies, patterns, principle deviations

### `/jdt test [target]`
- File path: write JUnit 5 tests for that class
- `coverage`: analyze test coverage gaps across the project
- `testability <path>`: assess testability of a class and recommend improvements
- `contract <interface>`: write contract tests for an interface
- Output: test code or coverage analysis report

### `/jdt design <topic>`
- Always requires a topic argument
- Output: design document with data model, interface contracts, module structure, build config, and Effective Java rationale

### `/jdt impl <task>`
- Task description or file path
- Output: production Java code following core principles (final/private, immutable, generics, DI, inline SQL)
