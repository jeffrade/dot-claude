# Makefile Best Practices — Comprehensive Knowledge Document

Compiled from: CloudPosse docs, makefiletutorial.com, Stanford CS107, MIT GNU make docs, OSDev wiki, felixcrux.com, math.colostate.edu (makepp), dev.to (shrsv + AWS), medium.com (stack-me-up + moritz.knoll), StackOverflow (2 questions, user-provided), and Gemini LLM research synthesis.

**Unavailable sources** (blocked/bot-protected): reddit.com (all three threads), beningo.com (both articles — content truncated in HTML).

---

## Primary Reference — The GNU Make Manual ("The Bible")

When building or extending this agent, or when stuck on any `make`-related question, consult these authoritative references first:

- **Full Manual Index**: https://www.gnu.org/software/make/manual/html_node/index.html
- **Concept Index**: https://www.gnu.org/software/make/manual/html_node/Concept-Index.html

These are the canonical, exhaustive reference for all GNU Make behavior. Everything in this knowledge doc is derived from or consistent with that manual. If this doc doesn't cover something, the manual does.

> **Note**: The GNU Make manual extract lives alongside this file at `references/gnu-make-manual-extract.md` (1,426 lines, 19 sections). The agent reads both reference files on demand — no merge needed. They complement each other: this file has community-sourced best practices and examples; the manual extract has authoritative GNU Make documentation.

---

## 0. DevixLabs Makefile Conventions (MUST FOLLOW)

These are the owner's mandatory conventions for all Makefiles produced or reviewed by this agent. They take precedence over any conflicting advice in later sections.

### Convention 1: Target Visibility — Public Top, Private Bottom

Targets follow the same visibility pattern as methods in Java/Python:

- **Public targets** (user-facing) go at the **top** of the Makefile. These are what humans type: `make help`, `make all`, `make test`, `make clean`.
- **Private targets** (called by other targets or by LLM agents only) are prefixed with `_` (underscore) and placed at the **bottom** of the file, below a clear separator comment.

```makefile
# ─── PUBLIC TARGETS (user-facing) ───────────────────────────────────────────

.PHONY: all help test clean build

help:
	@echo "Available commands:"
	@echo "  make all   - Full build pipeline"
	@echo "  make test  - Run tests"
	@echo "  make clean - Remove artifacts"

all: clean _check build test _post-build
	@echo "✓ Pipeline complete"

test: build
	@scripts/test.sh

clean:
	@scripts/clean.sh

build: _check
	@scripts/build.sh

# ─── PRIVATE TARGETS (called by other targets / LLM agents) ────────────────
# These are internal implementation details. Do NOT call directly.

.PHONY: _check _post-build

_check:
	@scripts/check.sh

_post-build:
	@scripts/post-build.sh
```

**Rationale**: Humans and CI/CD only need to see public targets. Private targets are implementation details — separating them reduces cognitive load and makes `make help` output clean.

### Convention 2: Complexity → scripts/ Directory

If a target's recipe cannot be expressed as 1-3 simple commands, **delegate to a bash script** in `scripts/`:

```makefile
# ✅ Simple — inline is fine
clean:
	rm -rf build/ dist/

# ✅ Simple — one tool command
test:
	@./gradlew test

# ❌ Too complex for inline — move to scripts/
deploy:
	@scripts/deploy.sh

# ❌ NEVER do this — multi-line bash logic in a recipe
deploy:
	@if [ -z "$(ENV)" ]; then echo "ERROR: ENV required"; exit 1; fi
	@docker build -t $(IMAGE) .
	@docker push $(IMAGE)
	@kubectl set image deployment/app app=$(IMAGE)
	@echo "Deployed to $(ENV)"
```

**Benefits**:
- Scripts are independently testable and lintable (`shellcheck`)
- Shell syntax highlighting works in scripts (not in Makefiles)
- Complex control flow (loops, conditionals, error handling) is maintainable in shell
- LLM agents can run scripts directly without Make

**Reference**: Both `Makefile.example` and `java/Makefile` in the appget.dev project demonstrate this — nearly every target delegates to `@scripts/*.sh` or `@./gradlew`.

### Convention 3: Logging & Exit Status for CI/CD and LLMs

Every Makefile (and its delegated scripts) MUST produce structured output that CI/CD pipelines and LLM agents can parse:

```makefile
build: _check
	@echo "Building..."
	@scripts/build.sh
	@echo "✓ Build complete"

test: build
	@echo "Running tests..."
	@scripts/test.sh || (echo "✗ Tests failed" && exit 1)
	@echo "✓ Tests passed"
```

**Rules**:
- Use `@echo` for status messages (suppress the echo command itself with `@`)
- Prefix success with `✓` and failure with `✗` for scannable output
- Scripts MUST exit non-zero on failure — Make propagates this automatically
- Never use `-` prefix to suppress errors on targets that should fail loudly
- The `-` prefix is acceptable ONLY on `clean` targets (where partial cleanup is fine)

### Convention 4: `help` as Default Target

The first target in every Makefile MUST be `help:`. This makes it the default when someone runs bare `make`:

```makefile
help:
	@echo "Available commands:"
	@echo "  make all    - Full build pipeline"
	@echo "  make test   - Run tests"
	@echo "  make clean  - Remove artifacts"
	@echo "  make help   - Show this message"
```

Use simple `@echo` statements for the help target — not the CloudPosse `awk` pattern (which is elegant but opaque and hard to debug). The manual approach is readable by humans and LLMs alike.

### Convention 5: LLM Guardrail Comment

Every Makefile should include this comment near the top:
```makefile
# Note to LLMs: DO NOT MUDDY THIS FILE UP. Create a bash script in scripts/ if complex logic is needed.
```

This prevents LLM agents from expanding simple Makefiles into complex monstrosities with inline bash.

### Real-World Reference

The appget.dev project demonstrates these conventions:
- **Template**: `Makefile.example` (language-agnostic, all subprojects follow this)
- **Live implementation**: `java/Makefile` (delegates to `./gradlew` and `scripts/`)
- **Private target example**: `_generate-default-script` in `java/Makefile`

---

## 1. Philosophy & Mindset

### Declarative, Not Scripting

The single most important mental shift: **Makefiles describe relationships between files, not sequences of commands.** A Makefile is a dependency graph, not a shell script. You declare "target X depends on Y and Z; here is how to produce X from them." Make decides whether to execute the recipe at all based on timestamps — you do not.

This inverts typical design thinking: start from the target files you want and work backward through their prerequisites.

### When Make Wins Over Shell Scripts

- Multiple file transformations with complex interdependencies
- Builds where only changed subsets need reprocessing
- Projects where incremental builds matter (C/C++, code generation pipelines, static site generators, TypeScript transpilation, Sass compilation)
- Anywhere timestamp-based staleness detection saves meaningful time

### When Make Is Overkill

Single-command workflows with no file dependency tracking benefit little from Make. A plain shell script is clearer in that case.

### Core Mental Model

Make compares **modification timestamps**: if any prerequisite is newer than the target, the recipe runs. If the target is up-to-date, nothing happens. This is not optional behavior — it is the entire point of Make.

---

## 2. Core Syntax & Rules

### Rule Structure

```makefile
target: prerequisites
	command
	command
```

- **target**: A file to produce, or a phony action name
- **prerequisites**: Files that must exist (and be up-to-date) before the recipe runs
- **command**: Shell commands to produce the target — **must start with a TAB character, not spaces**

Inline form (rarely used):
```makefile
target: prerequisites ; command
	command
```

### The Tab Requirement

This is the #1 source of beginner errors. Make distinguishes tabs from spaces syntactically. Recipe lines **must** be indented with a single tab (`\t`). Spaces cause:
```
Makefile:5: *** missing separator.  Stop.
```

Configure your editor to never convert tabs to spaces in Makefiles.

### Comments

Lines starting with `#` are ignored:
```makefile
# This is a comment
CC = gcc  # Inline comment also works
```

### First Target = Default Target

The first target defined in the Makefile is what runs when you invoke `make` with no arguments. By convention this is `all` or `help`. Never rely on alphabetical ordering — position determines default.

### Multiple Targets in One Rule

When multiple targets share the same prerequisite, list them together. Make treats this as separate rules — each target is built independently:

```makefile
# Dependency-only: all three .o files depend on command.h
# (the recipe comes from a pattern rule elsewhere)
kbd.o command.o files.o: command.h
```

If a recipe is provided, `$@` expands to whichever individual target is being built:
```makefile
kbd.o command.o files.o: command.h
	$(CC) $(CFLAGS) -c $(patsubst %.o,%.c,$@) -o $@
```

### Multiple Rules for One Target

All prerequisites merge across rules. Only the last rule with a recipe provides commands. This lets you add dependencies from different locations:
```makefile
foo.o: foo.c
foo.o: config.h  # Adds a dependency without overriding the recipe
```

### Line Continuation

Long lines split with backslash-newline:
```makefile
some_file:
	echo Long line \
		continued here
```

For multi-command shell execution in one shell (preserving `cd`, variables, etc.):
```makefile
all:
	cd subdir && \
	echo "now in subdir"
```

Each line without continuation runs in a **separate shell** — `cd` in one line does not affect the next.

### Dollar Signs

- `$(VAR)` or `${VAR}` — Make variable reference
- `$$` — Literal `$` passed to shell (for shell variables inside recipes)
- `$@`, `$<`, `$^` — Automatic variables (see Section 3)

```makefile
all:
	sh_var='test'; echo $$sh_var    # Shell variable
	echo $(MAKE_VAR)                # Make variable
```

### Shell Selection

```makefile
SHELL = /bin/bash
```

Default shell is `/bin/sh`. Set explicitly for bash-specific features.

---

## 3. Variables & Assignment

### Four Assignment Operators

| Operator | Name | Behavior |
|----------|------|----------|
| `=` | Recursive (lazy) | Expanded every time the variable is used; can reference variables defined later |
| `:=` | Simply expanded (immediate) | Expanded once at definition time; value is fixed |
| `?=` | Conditional | Sets value only if variable is not already defined |
| `+=` | Append | Appends to existing value with a space separator |

### Assignment Deep Dive (from StackOverflow)

**`:=` Simple/Immediate Assignment**
Evaluated exactly once at the point of definition. If `CC := ${GCC} ${FLAGS}` resolves to `gcc -W` at that line, every subsequent use of `${CC}` substitutes `gcc -W` verbatim — even if `GCC` or `FLAGS` change later.

```makefile
GCC = gcc
FLAGS = -W
CC := ${GCC} ${FLAGS}   # CC is now fixed as "gcc -W"
GCC = clang             # Too late — CC is already "gcc -W"
```

**`=` Recursive/Lazy Assignment**
Evaluated every time the variable is referenced. This means it sees the *current* value of any variables it depends on at the time of use — not at the time of definition.

```makefile
GCC = gcc
FLAGS = -W
CC = ${GCC} ${FLAGS}    # Not evaluated yet
GCC = clang             # Reassign before use
# Now ${CC} → "clang -W" because = is lazy
```

⚠️ **Infinite loop trap**: `CC = ${CC} -extra` with `=` causes infinite recursion. Use `+=` or `:=` instead.

**`?=` Conditional Assignment**
Assigns only if the variable has no current value. Ideal for defaults that callers can override:

```makefile
COMPILER ?= gcc         # Use gcc unless user passes COMPILER=clang
```

**`+=` Append**
Appends with a single space separator:

```makefile
CC = gcc
CC += -Wall             # CC is now "gcc -Wall"
```

See also: https://www.gnu.org/software/make/manual/html_node/Flavors.html

### When to Use Which

**Use `:=` by default.** It behaves like variables in programming languages — set once, used many times, no performance surprises.

```makefile
# := expands immediately
SRCS := $(wildcard src/*.c)   # Computed once at parse time

# = expands lazily — can cause repeated re-evaluation, potential infinite loops
TIMESTAMP = $(shell date)     # Re-evaluated every use (OK here, but be aware)
```

**Use `?=` for user-overridable defaults:**
```makefile
DEBUG ?= 0
DOCKER_TAG ?= latest
BUILD_DIR ?= ./build
```
Users can override: `make DEBUG=1` or `make DOCKER_TAG=dev`

**Use `+=` to accumulate flags:**
```makefile
CFLAGS := -Wall -O2
CFLAGS += -std=c99           # Append without overwriting
```

### Recursive vs. Simply Expanded — The Critical Difference

```makefile
# Recursive (=) — danger of self-reference
CFLAGS = $(CFLAGS) -Wall     # INFINITE LOOP — CFLAGS references itself

# Simply expanded (:=) — safe append pattern
CFLAGS := $(CFLAGS) -Wall    # Appends current value; no loop
# But += is cleaner for this:
CFLAGS += -Wall
```

### Automatic Variables

These expand within a recipe based on the current rule context:

| Variable | Expands to |
|----------|-----------|
| `$@` | The target name |
| `$<` | The first prerequisite only |
| `$^` | All prerequisites (space-separated, deduplicated) |
| `$+` | All prerequisites including duplicates (preserves order) |
| `$?` | Prerequisites newer than the target |
| `$*` | The stem matched by `%` in a pattern rule |
| `$\|` | Order-only prerequisites (GNU Make 4.x+) |

```makefile
$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^   # $@ = target, $^ = all objects

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@   # $< = the .c file, $@ = the .o file
```

### Built-In Compiler Variables (GNU Implicit Rules Use These)

| Variable | Default | Meaning |
|----------|---------|---------|
| `CC` | `cc` | C compiler |
| `CXX` | `g++` | C++ compiler |
| `CFLAGS` | (empty) | Flags for C compiler |
| `CXXFLAGS` | (empty) | Flags for C++ compiler |
| `CPPFLAGS` | (empty) | Preprocessor flags (shared by C and C++) |
| `LDFLAGS` | (empty) | Linker flags |

Always define these explicitly; do not rely on implicit defaults in production Makefiles.

### Variable Reference Syntax

```makefile
$(VAR)    # Standard — prefer this
${VAR}    # Also valid, less common
```

Single-character variables can omit parens: `$@` is equivalent to `$(@)` — but always use parens for multi-char names.

### Target-Specific Variables

Variables that apply only within a specific target's recipe and its prerequisites:
```makefile
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

profile: CFLAGS += -pg
profile: $(TARGET)
```

### Pattern-Specific Variables

```makefile
time_critical.o: CFLAGS := -O3   # Override flags for one file
```

### Environment Variables

Environment variables are automatically available as Make variables. Make variables override environment variables by default. To export a Make variable back to the shell:
```makefile
export MY_VAR = value
.EXPORT_ALL_VARIABLES:   # Export everything (use sparingly)
```

### `override` Directive — Modify Command-Line Variables

When a user passes a variable on the command line (`make CFLAGS=-O2`), normal Makefile assignments to that variable are **silently ignored**. Use `override` to force the Makefile's value:

```makefile
# User runs: make CFLAGS=-O2
# Without override, this line is silently ignored:
CFLAGS += -Wall                    # IGNORED — CFLAGS stays "-O2"

# With override, it works:
override CFLAGS += -Wall           # CFLAGS is now "-O2 -Wall"
```

Use `override` when the Makefile must guarantee certain flags (e.g., include paths, mandatory warnings) regardless of what the user passes.

### `undefine` Directive — Remove a Variable

Removes a variable definition entirely (GNU Make 3.82+):
```makefile
undefine LEGACY_VAR
override undefine FORCED_VAR      # Even if set on command line
```

### Multiline Variable (define Block)

```makefile
define GREETING
Hello
World
endef

all:
	echo "$(GREETING)"
```

---

## 4. Targets & .PHONY

### What is .PHONY?

A phony target is a label for an action, not an actual file to produce. Without `.PHONY`, if a file named `clean` exists in the directory, `make clean` will say "nothing to do" and skip the recipe entirely.

```makefile
.PHONY: clean
clean:
	rm -f *.o $(TARGET)
```

**Rule: declare every target that does not produce a file as `.PHONY`.**

```makefile
.PHONY: all clean install test check help deps build run
```

Grouping them on one `.PHONY` line is idiomatic. You can also declare them individually.

### Performance Benefit of .PHONY

Declaring a target phony also prevents Make from searching for implicit rules to build that target, which improves performance on large projects.

### Standard GNU Target Names

These are the conventional targets users expect in any project:

| Target | Purpose |
|--------|---------|
| `all` | Default: build everything. The first target; runs when `make` is invoked with no arguments. |
| `clean` | Remove all generated files, object files, intermediates. Allow fresh rebuild. |
| `install` | Copy final binary/artifacts to system path (e.g., `/usr/local/bin`) |
| `uninstall` | Remove installed files |
| `test` or `check` | Run the project's test suite |
| `dist` | Create a distribution tarball |
| `distclean` | Like `clean` but also remove configuration artifacts |
| `help` | Print available targets (not GNU standard but widely adopted best practice) |

### CloudPosse Standard Root Targets

CloudPosse also recommends: `deps`, `build`, `install`, `default`, `all`. Their convention: `default: help` makes the help text the default output when someone runs `make` without arguments.

### Target Dependencies for Automatic Prerequisite Execution

```makefile
build: deps
	@docker build -t example/test .

deps:
	@npm install
```

Running `make build` automatically runs `make deps` first if `deps` hasn't been satisfied.

### Order-Only Prerequisites

Prerequisites after `|` are ensured to exist but do not trigger a rebuild if they change:
```makefile
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $@
```

Use this for directories: you want the directory to exist, but changing the directory itself shouldn't force recompilation of every file in it.

### Double-Colon Rules

Each `::` rule is independent — executes if its own dependencies are newer than the target:
```makefile
foo::
	echo "first rule for foo"
foo::
	echo "second rule for foo — runs independently"
```

### Empty Target Files (Sentinel Files)

Used to record when an action last ran. Create a file as proof of completion:
```makefile
.stamps/deps-installed: package.json
	npm install
	@mkdir -p .stamps
	touch $@

node_modules: .stamps/deps-installed
```

`$?` lists only prerequisites newer than the target — useful for incremental actions.

---

## 5. Pattern Rules & Wildcards

### Pattern Rules

Use `%` as a wildcard to write one rule covering many files:

```makefile
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
```

The `%` matches one or more characters (the "stem"). In the prerequisite, `%` is replaced by the same stem found in the target.

### Static Pattern Rules

Apply a pattern rule to a specific set of targets:
```makefile
OBJECTS = foo.o bar.o baz.o

$(OBJECTS): %.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@
```

More efficient than generic pattern rules when you know the exact set of files. Explicit rules always override pattern rules; later pattern rules override earlier ones.

### Wildcard (`*`) in Rules

The `*` glob expands in **targets, prerequisites, and recipe commands** (shell does the expansion):
```makefile
print: $(wildcard *.c)
	ls -la $?
```

**IMPORTANT**: Never use bare `*` in variable assignments — it does NOT expand there:
```makefile
# WRONG — OBJ_FILES contains the literal string "*.o"
OBJ_FILES = *.o

# CORRECT — use the wildcard function
OBJ_FILES = $(wildcard *.o)
```

### The `wildcard` Function

```makefile
SOURCES := $(wildcard src/*.c)
HEADERS := $(wildcard include/*.h)
```

**Warning**: `$(wildcard **/*.c)` does NOT work for recursive globbing in GNU Make. The `**` pattern is a bash 4+ `globstar` feature — Make's `wildcard` function treats `**` as a literal match, not recursive descent. Use `$(shell find ...)` for reliable recursive discovery:
```makefile
SOURCES := $(shell find src -name '*.c')
HEADERS := $(shell find include -name '*.h')
```

### `patsubst` — Pattern Substitution

Transform one list into another:
```makefile
SOURCES := a.c bc.c def.c
OBJECTS := $(patsubst %.c,%.o,$(SOURCES))
# Result: a.o bc.o def.o
```

Shorthand (suffix substitution reference):
```makefile
OBJECTS := $(SOURCES:.c=.o)        # Simpler suffix form
OBJECTS := $(SOURCES:%.c=%.o)      # Full pattern form
```

### `addprefix` and `addsuffix`

```makefile
INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))
# Produces: -Isrc -Isrc/utils -Iinclude ...
```

### Automatic Dependency Generation

**The problem**: When a `.h` header changes, `.o` files that include it must recompile. Without tracking this, Make misses header-triggered rebuilds.

**The solution**: Use compiler flags `-MMD -MP` to auto-generate `.d` dependency files, then include them:

```makefile
CPPFLAGS := $(INC_FLAGS) -MMD -MP
DEPS := $(OBJS:.o=.d)

# Include the generated dependency files
# The leading - suppresses errors if .d files don't exist yet
-include $(DEPS)
```

Each `.d` file looks like:
```
foo.o: foo.c foo.h common.h
```

When `foo.h` changes, Make knows `foo.o` is stale. This is the **correct, complete solution** for C/C++ header dependency tracking.

Complete production pattern:
```makefile
TARGET_EXEC := myprogram
BUILD_DIR   := ./build
SRC_DIRS    := ./src

SRCS   := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c')
OBJS   := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS   := $(OBJS:.o=.d)

INC_DIRS   := $(shell find $(SRC_DIRS) -type d)
INC_FLAGS  := $(addprefix -I,$(INC_DIRS))
CPPFLAGS   := $(INC_FLAGS) -MMD -MP

$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -r $(BUILD_DIR)

-include $(DEPS)
```

### Implicit Rules (GNU Built-In)

Make has built-in pattern rules for common transformations:
- `.c` → `.o`: `$(CC) $(CPPFLAGS) $(CFLAGS) -c`
- `.cpp`/`.cc` → `.o`: `$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c`
- `.o` → executable: `$(CC) $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS)`

These are convenient for small projects but explicit pattern rules are clearer in production Makefiles.

---

## 6. Build Organization

### Separate Build Directories

Never mix source files and build artifacts. Keep source trees clean:

```makefile
BUILD_DIR := ./build

$(BUILD_DIR)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@
```

`$(dir $@)` extracts the directory portion of the target path, enabling `mkdir -p` to create nested build directories automatically.

### Directory Targets with Order-Only Prerequisites

```makefile
$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS) | $(BUILD_DIR)
	$(CC) $^ -o $@
```

Using `| $(BUILD_DIR)` (order-only) means Make ensures the directory exists but does not treat directory mtime changes as requiring a rebuild.

### Flag Organization (from felixcrux.com)

Structure compiler flags into logical groups:
```makefile
FLAGS        := -std=gnu99 -Iinclude                  # Mandatory requirements
CFLAGS       := -pedantic -Wall -Wextra -march=native  # Quality flags
DEBUGFLAGS   := -O0 -D_DEBUG                          # Debug-only
RELEASEFLAGS := -O2 -DNDEBUG                           # Release-only

# Separate targets use different flag sets
debug: $(SOURCES) $(HEADERS)
	$(CC) $(FLAGS) $(CFLAGS) $(DEBUGFLAGS) -o $(TARGET) $(SOURCES)

release: $(SOURCES) $(HEADERS)
	$(CC) $(FLAGS) $(CFLAGS) $(RELEASEFLAGS) -o $(TARGET) $(SOURCES)
```

### Variant Builds (Debug/Release/Profile)

Target-specific variable overrides enable variant builds without duplicating recipes:
```makefile
profile: CFLAGS += -pg
profile: $(TARGET)
	@echo "Profile build complete"
```

### Installation Paths

Follow the GNU convention: `PREFIX` is the logical install prefix, `DESTDIR` is a staging root prepended only at install time (never baked into `PREFIX`):
```makefile
PREFIX  ?= /usr/local
BINDIR  := $(PREFIX)/bin

install: release
	install -D $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

install-strip: release
	install -D -s $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	-rm $(DESTDIR)$(BINDIR)/$(TARGET)
```

This way `make install` installs to `/usr/local/bin/` and `make install DESTDIR=/tmp/staging` installs to `/tmp/staging/usr/local/bin/` (for packaging). The `-D` flag to `install` creates directories as needed.

### Dependency-Tracking Files as Artifacts

Use sentinel/stamp files to record completion of non-file-producing steps:
```makefile
node_modules: package.json
	npm install
	touch $@   # Mark node_modules as up-to-date relative to package.json
```

This makes `npm install` run only when `package.json` is newer than `node_modules`.

**Caveat**: `$@` here is a directory. Any file operation inside `node_modules/` also updates the directory mtime, which can cause false negatives (Make skips `npm install` when it shouldn't). A sentinel file is more reliable:
```makefile
.stamps/deps-installed: package.json
	npm install
	@mkdir -p .stamps
	touch $@
```

### .DELETE_ON_ERROR

If a recipe fails partway through, the partially-written target file can be left in a corrupt state. This special target tells Make to delete it:
```makefile
.DELETE_ON_ERROR:
```

Make this a habit in C/C++ Makefiles.

---

## 7. Advanced Patterns

### Include Files — Modular Makefiles

Split large Makefiles into organized modules:
```makefile
# Main Makefile
include tasks/Makefile.docker
include tasks/Makefile.test
-include tasks/Makefile.*    # Glob — leading - suppresses error if none exist
```

The leading `-` on `-include` prevents Make from failing when the included file does not exist (useful for optional `.d` dependency files and optional task modules).

**CloudPosse pattern** — include all task files from a directory:
```makefile
-include tasks/Makefile.*
```

### Recursive Make (Sub-Makes)

When you must invoke Make in subdirectories, always use `$(MAKE)`, never bare `make`:
```makefile
all:
	cd subdir && $(MAKE)
	$(MAKE) -C other-subdir
```

`$(MAKE)` passes through `-j`, `--dry-run`, and other flags correctly. Bare `make` does not.

**Caution**: Recursive Make has well-documented problems (Peter Miller's "Recursive Make Considered Harmful"):
- Parallel builds (`-j`) cannot parallelize across recursive invocations
- Dependencies between subdirectories are invisible to the top-level Make
- Prefer a single non-recursive Makefile for large projects when possible

### Namespaced Targets (CloudPosse Pattern)

For large projects, use `/` as a delimiter to namespace related targets:
```makefile
docker/build:
	docker build -t $(IMAGE) .

docker/push:
	docker push $(IMAGE)

docker/run:
	docker run $(IMAGE)

test/unit:
	./run-unit-tests.sh

test/integration:
	./run-integration-tests.sh
```

**Do NOT use `:` as a delimiter** — it silently breaks Make's dependency resolution. `/` is safe and visually clear.

Organize related targets in separate files: `Makefile.docker`, `Makefile.test`, then include them.

### Pass Variables as Arguments

Command-line `key=value` arguments override Make variables. Recipes access them via Make expansion `$(VAR)`:
```makefile
make docker/build DOCKER_TAG=v1.2.3
# Inside the recipe, $(DOCKER_TAG) expands to v1.2.3
```

**Important**: Command-line variables are NOT automatically exported as environment variables to subprocesses (scripts, child processes). To make them visible to scripts, either:
1. Use `export DOCKER_TAG` in the Makefile, or
2. Pass them explicitly: `DOCKER_TAG=$(DOCKER_TAG) scripts/deploy.sh`, or
3. Use `.EXPORT_ALL_VARIABLES:` (exports everything — use sparingly)

### VPATH — Directory Search

Tell Make where to search for prerequisites:
```makefile
VPATH = src:../headers      # Search src, then ../headers

vpath %.c src               # Search src only for .c files
vpath %.h include           # Search include only for .h files
```

`vpath` (lowercase) is more selective and preferred over `VPATH`.

### `.PRECIOUS` — Preserve Intermediates

Make deletes intermediate files it creates during chained rules. Declare files precious to keep them:
```makefile
.PRECIOUS: %.o
```

### `.SECONDARY` — Similar to .PRECIOUS

Prevents deletion of secondary files (intermediates) while not treating them as always-stale.

### `.ONESHELL` — Single Shell for Entire Recipe

By default, each line in a recipe runs in a **separate shell**. This means `cd`, variable assignments, and control flow don't persist across lines. `.ONESHELL` changes this — the entire recipe runs in one shell invocation:

```makefile
.ONESHELL:

deploy:
	cd build/
	echo "Deploying from $$(pwd)"   # This works — same shell as cd
	tar czf release.tar.gz .
	scp release.tar.gz server:/opt/
```

Without `.ONESHELL`, you'd need backslash continuation and `&&`:
```makefile
deploy:
	cd build/ && \
	echo "Deploying from $$(pwd)" && \
	tar czf release.tar.gz . && \
	scp release.tar.gz server:/opt/
```

**Note**: `.ONESHELL` applies globally to all recipes. With it enabled, `@` and `-` prefixes only work on the **first line** of each recipe. Requires GNU Make 3.82+.

### `.SECONDEXPANSION` — Deferred Prerequisite Expansion

Normally Make expands all prerequisites when it reads the Makefile. `.SECONDEXPANSION` enables a second expansion pass at rule execution time, allowing prerequisites to use automatic variables like `$@`:

```makefile
.SECONDEXPANSION:

# Each .o file depends on a .c file with the same stem AND its own header
%.o: %.c $$(patsubst %.o,%.h,$$@)
	$(CC) -c $< -o $@

# Useful when prerequisites vary per-target and can't be expressed with a simple pattern
PROGRAMS = foo bar baz
$(PROGRAMS): $$@.c $$@.h
	$(CC) $^ -o $@
```

The `$$` is literal `$` after the first expansion — it becomes `$` for the second pass. Use sparingly; it adds complexity. Most use cases are better served by static pattern rules.

### Double-Colon for Plugin-Style Rules

```makefile
clean::
	rm -f *.o

clean::
	rm -f *.d
```

Both clean recipes run independently. Useful when multiple included Makefiles all contribute to the same phony target.

---

## 8. Conditional Logic

### ifeq / ifneq

```makefile
ifeq ($(VAR), value)
    # Commands when VAR equals "value"
else
    # Otherwise
endif

ifneq ($(VAR), value)
    # Commands when VAR does not equal "value"
endif
```

### ifdef / ifndef

```makefile
ifdef DEBUG
    CFLAGS += -g -DDEBUG
endif

ifndef FRAMEWORK_PATH
    $(error FRAMEWORK_PATH is not set. Cannot continue.)
endif
```

### Checking for Empty / Whitespace

```makefile
ifeq ($(strip $(VAR)),)
    # VAR is empty or whitespace-only
endif
```

`$(strip ...)` removes leading/trailing whitespace before comparison.

### Platform Detection

```makefile
OS := $(shell uname -s)

ifeq ($(OS),Linux)
    LIBS := -lm
else ifeq ($(OS),Darwin)
    LIBS :=
else
    $(warning Unsupported OS: $(OS))
    LIBS :=
endif
```

### Checking for Tool Availability

```makefile
PANDOC := $(shell command -v pandoc 2>/dev/null)
ifeq ($(strip $(PANDOC)),)
    $(error Pandoc not found. Install with: brew install pandoc)
endif
```

### Flags Check

```makefile
# Check if -i flag was passed to make
ifneq (,$(findstring i,$(MAKEFLAGS)))
    $(info Ignoring errors mode enabled)
endif
```

---

## 9. Functions & String Operations

### Syntax

```makefile
$(function argument1, argument2, ...)
${function argument1, argument2, ...}
```

### Text Manipulation

**`$(subst from,to,text)`** — Simple substitution:
```makefile
bar := $(subst .c,.o,foo.c bar.c)
# Result: foo.o bar.o
```

**`$(patsubst pattern,replacement,text)`** — Pattern substitution:
```makefile
OBJS := $(patsubst %.c,%.o,$(SRCS))
# Shorthand:
OBJS := $(SRCS:.c=.o)
# Full pattern shorthand:
OBJS := $(SRCS:%.c=%.o)
```

**`$(strip text)`** — Remove leading/trailing whitespace:
```makefile
CLEAN := $(strip $(VAR))
```

**`$(filter pattern...,text)`** — Keep matching words:
```makefile
obj_files := foo.c bar.o baz.o
objs_only := $(filter %.o,$(obj_files))
# Result: bar.o baz.o
```

**`$(filter-out pattern...,text)`** — Remove matching words:
```makefile
non_c := $(filter-out %.c,$(ALL_FILES))
```

**`$(sort list)`** — Sort and deduplicate:
```makefile
UNIQUE := $(sort foo bar foo baz)
# Result: bar baz foo
```

**`$(word n,text)`** — Extract nth word (1-indexed):
```makefile
second := $(word 2,foo bar baz)
# Result: bar
```

**`$(words text)`** — Count words:
```makefile
count := $(words $(SRCS))
```

**`$(firstword text)`** / **`$(lastword text)`**:
```makefile
first := $(firstword $(SRCS))
```

### File Name Operations

```makefile
$(dir src/foo.c)          # Result: src/
$(notdir src/foo.c)       # Result: foo.c
$(suffix src/foo.c)       # Result: .c
$(basename src/foo.c)     # Result: src/foo
$(addsuffix .c,foo bar)   # Result: foo.c bar.c
$(addprefix src/,foo bar) # Result: src/foo src/bar
```

### `$(foreach var,list,text)`

Iterate over a list:
```makefile
DIRS := src lib test
CLEAN_DIRS := $(foreach d,$(DIRS),$(BUILD_DIR)/$(d))
# Result: build/src build/lib build/test
```

### `$(call func,args...)`

User-defined functions:
```makefile
# Define a function using define
define compile_target
	$(CC) $(CFLAGS) -c $(1) -o $(2)
endef

# Call it
%.o: %.c
	$(call compile_target,$<,$@)
```

`$(0)` = function name, `$(1)`, `$(2)`, ... = arguments.

### `$(shell command)`

Execute a shell command and capture output (newlines become spaces):
```makefile
BUILD_DATE := $(shell date +%Y-%m-%d)
GIT_SHA    := $(shell git rev-parse --short HEAD)
SRCS       := $(shell find src -name '*.c')
```

**Caution**: `$(shell ...)` runs at parse time (or each time for `=`-assigned variables). Use `:=` to evaluate once:
```makefile
GIT_SHA := $(shell git rev-parse --short HEAD)
```

### `$(wildcard pattern)`

```makefile
SRCS := $(wildcard src/*.c)           # Non-recursive — src/ only
# For recursive: use $(shell find src -name '*.c')
```

### `$(info ...)`, `$(warning ...)`, `$(error ...)`

```makefile
$(info Building target: $(TARGET))           # Print to stdout, continue
$(warning CFLAGS is empty!)                 # Print warning, continue
$(error REQUIRED_VAR is not set. Aborting.) # Print error, stop make
```

### `$(value var)`

Returns the unexpanded definition of a variable (useful for debugging recursive variables).

### `$(origin var)`

Returns where a variable came from: `undefined`, `default`, `environment`, `file`, `command line`, `override`, `automatic`.

---

## 10. Output Control & UX

### Suppressing Command Echo with `@`

By default, Make prints each command before executing it. Prefix with `@` to suppress:
```makefile
all:
	@echo "Building..."     # Prints the message, not the echo command
	@$(CC) -c foo.c         # Runs silently
	$(CC) -c bar.c          # Prints the command line before running
```

### Selective Silence Strategy

Show high-level status messages; hide low-level compiler invocations:
```makefile
%.o: %.c
	@echo "  CC  $<"
	@$(CC) $(CFLAGS) -c $< -o $@
```

### Suppressing Errors with `-`

Prefix a command with `-` to continue even if it fails (non-zero exit code):
```makefile
clean:
	-rm -f *.o       # Don't fail if no .o files exist
	-rm -f $(TARGET) # Don't fail if not built yet
```

### Force Execution with `+`

Prefix a command with `+` to run it even under `make -n` (dry run) or `make -t` (touch):
```makefile
all:
	+$(MAKE) -C subdir    # Recursive make always runs, even in dry-run mode
```

### Recipe Prefix Summary

| Prefix | Effect |
|--------|--------|
| `@` | Suppress command echo (silence) |
| `-` | Ignore non-zero exit (continue on error) |
| `+` | Always execute, even under `-n`/`-t` |

Prefixes can be combined: `@-command` suppresses echo AND ignores errors.

### Error Handling Flags

- `make -k` — Continue building other targets even after a failure
- `make -i` — Ignore all errors (like `-` prefix everywhere)
- `make -n` — Dry run: print what would execute without running it
- `make -p` — Print the full database of rules and variables (powerful for debugging)
- `make -j <n>` — Run up to N recipes in parallel (e.g. `make -j4`). From the shell command line, `make -j$(nproc)` uses all CPU cores (the shell expands `$(nproc)` before Make sees it — don't confuse with Make's `$(...)` syntax). Requires that targets have correct dependency declarations — incorrect deps cause race conditions in parallel mode.
- `make -s` — Silent mode: suppress all command echoing (like `@` on every line)

### Self-Documenting Help Target (CloudPosse Pattern)

This is a widely-adopted best practice: add `##` comment lines above targets, then generate help automatically using `awk`:

```makefile
## help: Show this help message
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-_0-9%:\\]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			gsub("\\\\", "", helpCommand); \
			gsub(":+$$", "", helpCommand); \
			printf "  \x1b[32;01m%-35s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u
	@printf "\n"

.PHONY: help
```

**Set it as the default target:**
```makefile
.DEFAULT_GOAL := help
# Or simply make it the first target
```

### Manual Help Target (simpler, always works)

```makefile
help:
	@echo "Available commands:"
	@echo "  make all         - Full build pipeline"
	@echo "  make test        - Run unit tests"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make run-server  - Start server on localhost:8080"

.PHONY: help
```

### `$(MAKEFILE_LIST)`

Built-in variable containing the list of Makefiles being processed. Used in the CloudPosse help target above.

### `MAKEFLAGS`

Contains flags passed to the current Make invocation. Useful for detecting `-j`, `-s`, etc.

### Quiet Mode Toggle

```makefile
Q ?= @     # Default: quiet

%.o: %.c
	$(Q)$(CC) -c $< -o $@
	
# User can run: make Q= to see all commands
```

---

## 11. CloudPosse Patterns

*These are CloudPosse-specific conventions, marked as such. Many are excellent general practices.*

### Namespace with `/` Delimiter

```makefile
docker/build:
	@docker build -t $(IMAGE_NAME) .

docker/push:
	@docker push $(IMAGE_NAME)

k8s/deploy:
	kubectl apply -f manifests/

k8s/rollback:
	kubectl rollout undo deployment/$(APP)
```

Never use `:` as a target delimiter — it silently breaks Make's dependency parsing.

### Modular Task Files

```makefile
# Root Makefile
-include tasks/Makefile.*
```

Each `tasks/Makefile.docker`, `tasks/Makefile.terraform`, etc. defines its own namespaced targets. The leading `-` allows an empty `tasks/` directory without error.

### Avoid `$(eval ...)`

CloudPosse explicitly warns against `$(eval ...)`. It creates confusing execution paths because Make preprocesses all `$(...)` interpolations before executing commands line-by-line. The behavior is hard to reason about and debug. Use explicit rules or shell scripts instead.

### Sane Defaults with `?=`

```makefile
DOCKER_TAG    ?= latest
DOCKER_IMAGE  ?= myapp
ENVIRONMENT   ?= dev
AWS_REGION    ?= us-east-1
```

Callers override at invocation: `make docker/build DOCKER_TAG=v2.0.0`

### Small Targets, Shell Scripts for Complexity

**Do not embed 50-line bash scripts in Makefile recipes.** Delegate to scripts:
```makefile
deploy:
	@scripts/deploy.sh

generate:
	@scripts/generate.sh

test:
	@scripts/run-tests.sh
```

Benefits:
- Scripts are testable independently
- Shell syntax highlighting and linting (shellcheck) apply
- Recipes stay readable
- Complex logic (loops, conditionals) is more maintainable in shell

### Pass Variables to Scripts via Environment

Command-line variables are NOT automatically exported to script subprocesses. You must explicitly export them:
```makefile
export ENVIRONMENT
export AWS_REGION

deploy:
	@scripts/deploy.sh
# Now: make deploy ENVIRONMENT=prod AWS_REGION=us-west-2
# deploy.sh sees $ENVIRONMENT and $AWS_REGION in its environment
```

Alternative — pass inline (no `export` needed):
```makefile
deploy:
	ENVIRONMENT=$(ENVIRONMENT) AWS_REGION=$(AWS_REGION) scripts/deploy.sh
```

### `deps` as Standard Target

```makefile
deps:
	brew install jq
	pip install -r requirements.txt
	npm install

build: deps
	@scripts/build.sh
```

### Default Target as Help

```makefile
default: help

.PHONY: default help
```

---

## 12. Best Practices Summary

### Non-Negotiable Rules

1. **Always use TABs for recipe indentation** — never spaces. Configure your editor.
2. **Always declare non-file targets as `.PHONY`** — prevents silent failures when files match target names.
3. **Use `:=` for variable assignment** unless you specifically need lazy evaluation.
4. **Never use bare `*` in variable assignments** — use `$(wildcard ...)`.
5. **Never use `$(wildcard **/*.c)` for recursive search** — it doesn't work in GNU Make. Use `$(shell find ...)`.
6. **Always use `$(MAKE)` for recursive invocations** — never bare `make`.
7. **`help` as first target** — make it the default. Use simple `@echo`, not awk magic.
8. **Public targets at top, `_`-prefixed private targets at bottom** — visibility pattern (see Section 0).
9. **Complex recipes → `scripts/`** — if it's more than 1-3 simple commands, delegate to a shell script.
10. **Structured logging with exit status** — `✓`/`✗` prefixes, non-zero exit on failure (see Section 0).
11. **Run `.DELETE_ON_ERROR:`** in C/C++ Makefiles to prevent corrupt intermediate files.

### Strong Recommendations

8. **Use `?=` for user-overridable configuration** — never hardcode environment-specific values.
9. **Separate build artifacts from source** — use a `build/` or `dist/` directory.
10. **Generate dependencies automatically** with `-MMD -MP` and `-include $(DEPS)`.
11. **Use dynamic file discovery** (`$(wildcard ...)` or `$(shell find ...)`) — avoid hardcoding file lists.
12. **Keep recipes short** — delegate complex logic to shell scripts (`scripts/*.sh`).
13. **Prefix recipes with `@`** to silence noisy command echoing; show meaningful status messages instead.
14. **Use `?` for prerequisites newer than target** (`$?`) when doing incremental actions.
15. **Use order-only prerequisites (`|`)** for directories to avoid false rebuilds.

### Namespace and Organization

16. **Use `/` as target namespace delimiter** for large projects (e.g., `docker/build`, `test/unit`).
17. **Split large Makefiles** into `tasks/Makefile.*` includes.
18. **Group all `.PHONY` declarations** at the top or immediately before each target.
19. **Put configuration variables at the top** — one place to change, easily found.
20. **Make `all` the first target** (or `help`) — it defines the default behavior.

### Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | Fix |
|-------------|---------|-----|
| Spaces instead of tabs | Causes "missing separator" error | Configure editor |
| Missing `.PHONY` | Silent failure when file named `clean` exists | Always declare |
| Using `=` instead of `:=` | Repeated re-evaluation, potential infinite loops | Use `:=` |
| Bare `*` in variable | Does NOT glob — stored as literal `*.c` | Use `$(wildcard *.c)` |
| Hardcoded file lists | New files not automatically included | Use `$(wildcard ...)` |
| Long bash in recipes | Hard to debug, no shellcheck, hard to read | Move to scripts/ |
| Using `:` in target names | Silently breaks Make dependency parsing | Use `/` delimiter |
| `$(eval ...)` | Confusing execution order | Use explicit rules |
| Bare `make` in recipes | Doesn't propagate flags like `-j`, `--dry-run` | Use `$(MAKE)` |
| No `help` target | Users must read the Makefile to know what to run | Always provide `help` |
| Missing `-MMD -MP` in C/C++ | Header changes don't trigger recompile | Add dependency generation |
| Embedding make in CI without isolation | Parallel builds share state, fight over files | Use separate build dirs |
| `$(wildcard **/*.c)` | Does NOT recurse in GNU Make — `**` is not `globstar` | Use `$(shell find ...)` |
| `clean` depending on `check` | Can't clean when tooling is broken | `clean` must be self-contained |
| Missing `export` for script vars | Command-line vars don't reach subprocesses | Explicit `export VAR` |
| Missing `override` for mandatory flags | Command-line `CFLAGS=` silently overrides Makefile | `override CFLAGS +=` |

### Debugging Techniques

```makefile
make -n           # Dry run: show what would execute
make -p           # Dump full Make database (rules, variables, defaults)
make -d           # Debug: show all dependency checks
make VERBOSE=1    # If you've implemented a quiet mode toggle
$(info $(VAR))    # Print variable value at parse time
```

---

## 13. Practical Examples

### Minimal C Project

```makefile
CC     := gcc
CFLAGS := -Wall -Wextra -O2 -std=c99
TARGET := myprogram
SRCS   := $(wildcard src/*.c)
OBJS   := $(SRCS:.c=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS)
```

### C Project with Separate Build Dir and Auto Dependencies

```makefile
CC         := gcc
CFLAGS     := -Wall -Wextra -O2 -std=c99
TARGET     := myprogram
BUILD_DIR  := build
SRC_DIR    := src

SRCS := $(shell find $(SRC_DIR) -name '*.c')
OBJS := $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(OBJS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

.DELETE_ON_ERROR:
-include $(DEPS)
```

### Multi-Platform Build with Conditionals

```makefile
CC     := gcc
CFLAGS := -Wall -O2

OS := $(shell uname -s)
ifeq ($(OS),Linux)
    LDFLAGS := -lm
else ifeq ($(OS),Darwin)
    LDFLAGS :=
else
    $(warning Unknown OS: $(OS))
    LDFLAGS :=
endif

ifdef DEBUG
    CFLAGS += -g -O0 -DDEBUG
endif

.PHONY: all clean

TARGET := myapp
SRCS   := $(wildcard *.c)
OBJS   := $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS)
```

### Static Site Generator

```makefile
PANDOC   := $(shell command -v pandoc 2>/dev/null)
SRC_DIR  := src
OUT_DIR  := build
SOURCES  := $(wildcard $(SRC_DIR)/*.md)
HTMLS    := $(patsubst $(SRC_DIR)/%.md,$(OUT_DIR)/%.html,$(SOURCES))

ifeq ($(strip $(PANDOC)),)
    $(error Pandoc not found. Install with: brew install pandoc)
endif

.PHONY: all clean

all: $(HTMLS)

$(OUT_DIR)/%.html: $(SRC_DIR)/%.md | $(OUT_DIR)
	$(PANDOC) $< -o $@ --standalone

$(OUT_DIR):
	mkdir -p $@

clean:
	rm -rf $(OUT_DIR)
```

### Node.js / Polyglot Project Makefile

```makefile
.PHONY: all clean install test lint build deploy

NODE_ENV ?= development
IMAGE_TAG ?= latest

## all: Full build (install, lint, test, build)
all: install lint test build

## install: Install dependencies
install:
	npm ci

## lint: Run linter
lint:
	npm run lint

## test: Run test suite
test:
	npm test

## build: Compile TypeScript
build:
	npm run build

## clean: Remove build artifacts
clean:
	rm -rf dist/ node_modules/

## deploy: Build and deploy
deploy: build
	@scripts/deploy.sh

## help: Show this help
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## //' | column -t -s ':'

.DEFAULT_GOAL := help
```

### CloudPosse-Style Infrastructure Makefile

```makefile
# Configuration — all overridable at invocation
DOCKER_IMAGE ?= myapp
DOCKER_TAG   ?= latest
ENVIRONMENT  ?= dev
AWS_REGION   ?= us-east-1

.PHONY: default help deps build test deploy clean

default: help

## help: Show available targets
help:
	@printf "Available targets:\n\n"
	@awk '/^[a-zA-Z\-_0-9%:\\]+/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = $$1; \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			gsub("\\\\", "", helpCommand); \
			gsub(":+$$", "", helpCommand); \
			printf "  \x1b[32;01m%-30s\x1b[0m %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -u

## deps: Install dependencies
deps:
	@scripts/install-deps.sh

## docker/build: Build Docker image
docker/build:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

## docker/push: Push Docker image
docker/push: docker/build
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

## test: Run test suite
test:
	@scripts/test.sh

## deploy: Deploy to environment
deploy:
	@scripts/deploy.sh

## clean: Remove build artifacts
clean:
	-rm -rf build/ dist/

-include tasks/Makefile.*
```

### Makefile for Code Generation Pipeline (appget.dev pattern)

```makefile
# All targets delegate to scripts/*.sh — complex logic stays in shell, not Make
.PHONY: all help check features-to-specs parse-schema generate build test clean verify

## help: Show available commands
help:
	@echo "Available commands:"
	@echo "  make all              - Full pipeline: clean → generate → test → build"
	@echo "  make features-to-specs - Convert .feature files to specs.yaml"
	@echo "  make parse-schema     - Parse schema.sql → models.yaml"
	@echo "  make generate         - Generate all artifacts"
	@echo "  make test             - Run unit tests"
	@echo "  make verify           - All server-dependent tests (requires server running)"
	@echo "  make clean            - Remove build artifacts"

## check: Static analysis and tooling checks
check:
	@scripts/check.sh

## clean: Remove build artifacts (no prerequisites — clean must always work)
clean:
	@scripts/clean.sh

## all: Full build pipeline (no server needed)
all: clean check generate test build

## features-to-specs: Convert .feature files + metadata.yaml to specs.yaml
features-to-specs: check
	@scripts/features-to-specs.sh

## parse-schema: Parse schema.sql and generate models.yaml
parse-schema: check
	@scripts/parse-schema.sh

## generate: Generate all artifacts
generate: features-to-specs parse-schema
	@scripts/generate.sh

## build: Compile everything
build: check
	@scripts/build.sh

## test: Run unit tests
test: build
	@scripts/test.sh

## verify: All server-dependent tests (requires server running)
verify: build
	@scripts/verify.sh
```

### Debug/Release Builds with Compiler Switching (from StackOverflow)

A real-world pattern for C/C++ projects with automatic dependency generation, debug/release separation, and compiler switching via command-line variables:

**Features:**
- Debug build is default; `make BUILD=release` for release
- `make COMPILER=clang` to switch compiler (gcc is default)
- Automatic dependency generation (rebuild only changed files)
- Makefile changes trigger full rebuild
- `clean` removes entire build directory
- `make run_<target>` to build and run in one step

```makefile
BUILD     ?= debug
COMPILER  ?= gcc

BUILD_DIR := build/$(BUILD)

ifeq ($(BUILD), debug)
  CFLAGS := -g -O0 -DDEBUG
else
  CFLAGS := -O2 -DNDEBUG
endif

# Automatic dependency files
SRCS    := $(wildcard *.c)
OBJS    := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRCS))
DEPS    := $(OBJS:.o=.d)

TARGET  := $(BUILD_DIR)/myprogram

$(TARGET): $(OBJS) Makefile
	$(COMPILER) $(CFLAGS) -o $@ $(OBJS)

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(COMPILER) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR):
	mkdir -p $@

-include $(DEPS)

.PHONY: clean run_myprogram

clean:
	rm -rf build/

run_myprogram: $(TARGET)
	./$(TARGET)
```

**Key points:**
- `Makefile` is listed as a prerequisite — any change to the Makefile triggers a full rebuild
- `-MMD -MP` generates `.d` dependency files tracking header includes
- `-include $(DEPS)` silently includes them (the `-` suppresses errors if they don't exist yet)
- `BUILD_DIR` separates debug and release artifacts, so both can coexist
- Passing `COMPILER=clang` or `BUILD=release` on the command line works because `?=` only sets if unset

**Limitations noted by SO answer:**
- Assumes all source files in one directory (multi-directory needs more structure)
- Don't archive build artifacts — only source + Makefile

---

## Source Notes

| Source | Status | Key Contribution |
|--------|--------|-----------------|
| docs.cloudposse.com/best-practices/developer/makefile/ | Fetched | Namespacing, help target awk pattern, modular includes, `?=` defaults, shell script delegation |
| makefiletutorial.com | Fetched | Comprehensive syntax reference, automatic variables, production example with `-MMD -MP` |
| web.stanford.edu CS107 guide | Fetched | Clean educational overview, phony targets, implicit targets |
| web.mit.edu GNU make docs | Fetched | VPATH, `.PHONY`, special targets, static pattern rules, double-colon rules |
| felixcrux.com/blog | Fetched | Flag organization (FLAGS/DEBUGFLAGS/RELEASEFLAGS), `.SECONDEXPANSION` dependency trick |
| math.colostate.edu (makepp) | Fetched | Pattern rules, multi-directory, wildcard types, repository builds |
| dev.to/shrsv (mastering makefiles) | Fetched | Conditionals, debugging commands, static site generator pattern |
| dev.to/aws (fun and profit) | Fetched | Real-world applications (Terraform, Docker), PHONY emphasis |
| beningo.com (embedded, both) | Unavailable | Content truncated in HTML fetch |
| stackoverflow.com — Variable flavors (:= vs = vs ?= vs +=) | User-provided | Deep dive on assignment semantics + Flavors.html link |
| stackoverflow.com — Best practice Makefile for C/C++ | User-provided | Debug/release/compiler switching pattern with auto-deps |
| medium.com/stack-me-up | Fetched | Declarative mindset, `node_modules` pattern, myth debunking |
| wiki.osdev.org/Makefile | Fetched | `-MMD -MP` dependency generation, `todolist` target, `$?` usage |
| reddit.com (all 3 threads) | Unavailable | Site blocks automated fetches |
| medium.com/@moritz.knoll | Fetched | Beginner-friendly walkthrough, `fclean`/`re` targets |
| Gemini LLM synthesis | Included | Validated and integrated throughout |
