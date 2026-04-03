# GNU Make Manual — Key Sections Extract

> Extracted from the GNU Make manual (https://www.gnu.org/software/make/manual/) and
> makefiletutorial.com. Sources fetched April 2026. Covers GNU Make 4.x.

---

## Variable Flavors (Types)

GNU Make supports several "flavors" of variables, distinguished by when their values are expanded.

### Recursively Expanded Variables (`=`)

Created with `=` or the `define` directive. The value is stored verbatim; any variable references it contains are expanded **every time the variable is used**, not when it is set.

```makefile
foo = $(bar)
bar = $(ugh)
ugh = Huh?

all:
    echo $(foo)    # Outputs "Huh?" — expands through the chain each use
```

**Advantage:** Variables can reference others not yet defined:
```makefile
CFLAGS = $(include_dirs) -O
include_dirs = -Ifoo -Ibar
```

**Disadvantages:**
- Cannot self-reference (causes infinite loop): `CFLAGS = $(CFLAGS) -O` will loop.
- Functions like `wildcard` and `shell` re-execute every time the variable is referenced — slower and potentially unpredictable.

### Simply Expanded Variables (`:=` or `::=`)

The value is scanned **once at definition time**; all variable references are expanded immediately.

```makefile
x := foo
y := $(x) bar   # y = "foo bar" — captures x's value NOW
x := later      # Does not affect y
```

Practical use with shell:
```makefile
ifeq (0,${MAKELEVEL})
whoami    := $(shell whoami)
host-type := $(shell arch)
MAKE      := ${MAKE} host-type=${host-type} whoami=${whoami}
endif
```

**Whitespace trick** — capturing a literal space:
```makefile
nullstring :=
space := $(nullstring) # end of the line
```
`space` now contains exactly one space character.

**Advantage:** Predictable — works like variables in most programming languages. More efficient than recursive for functions.

### Immediately Expanded Variables (`:::=`)

The `:::=` operator expands the value immediately (like `:=`) but then **quotes all `$` signs** by converting them to `$$`. This means when the variable is later used, make re-expands it — but the literal `$` signs introduced during assignment are preserved.

```makefile
var = first
OUT :::= $(var)    # OUT = "first"
var = second       # Does not affect OUT
```

```makefile
var = one$$two
OUT :::= $(var)    # OUT = "one$$two" (the $$ from var becomes $$)
var = three$$four
```

With `+=`:
```makefile
var = one$$two
OUT :::= $(var)
OUT += $(var)      # Appended text is NOT expanded immediately
var = three$$four
# OUT expands to: "one$$two $(var)" which becomes "one$two three$four"
```

This matches the traditional BSD make `:=` behavior and was added to POSIX Issue 8.

### Conditional Variable Assignment (`?=`)

Only assigns a value if the variable has not been set previously.

```makefile
FOO ?= bar
```

Equivalent to:
```makefile
ifeq ($(origin FOO), undefined)
  FOO = bar
endif
```

**Important:** A variable set to an empty value (`FOO =`) is still considered defined — `?=` will NOT override it.

### Shell Assignment (`!=`)

Executes a shell command and assigns its output. Expands immediately (like `:=`). Dollar signs in the output must be escaped as `$$`.

```makefile
hash != printf '\043'   # hash = "#"
file_list != find . -name '*.c'
```

### Append (`+=`)

See the "Appending to Variables" section below.

---

## Setting & Overriding Variables

### Basic Assignment Syntax

```makefile
variable = value        # recursive
variable := value       # simply expanded
variable ::= value      # simply expanded (POSIX)
variable :::= value     # immediately expanded (BSD compat)
variable ?= value       # conditional (only if not already set)
variable != command     # shell assignment
variable += more        # append
```

Whitespace around the variable name and immediately after the operator is ignored:
```makefile
objects = main.o foo.o bar.o utils.o
```

### Appending to Variables (`+=`)

Appends text preceded by a single space to the existing value:

```makefile
objects = main.o foo.o bar.o utils.o
objects += another.o
# objects = "main.o foo.o bar.o utils.o another.o"
```

**Behavior with simply expanded variables** (`:=`): The new text is expanded immediately before appending:
```makefile
variable := value
variable += more
# Equivalent to: variable := value
#                variable := $(variable) more
```

**Behavior with recursively expanded variables** (`=`): Appended text is stored unexpanded, preserving references:
```makefile
CFLAGS = $(includes) -O
CFLAGS += -pg
# $(includes) is still a deferred reference — not expanded yet
```

### Override Directive

Normally, variables set on the command line (`make CFLAGS=-g`) override makefile assignments. The `override` directive forces a makefile assignment to win even against command-line values:

```makefile
override CFLAGS += -g
# Guarantees -g is always in CFLAGS regardless of command-line
```

Three forms:
```makefile
override variable = value
override variable := value
override variable += more text
```

Once a variable is marked with `override`, subsequent non-override assignments to it are **ignored**.

Works with multi-line definitions:
```makefile
override define foo =
bar
endef
```

### Target-Specific Variables

Variables can be set for specific targets and their prerequisites:

```makefile
all: one = cool

all:
    echo one is defined: $(one)

other:
    echo one is nothing: $(one)
```

### Pattern-Specific Variables

Variables can be set for all targets matching a pattern:

```makefile
%.c: one = cool

blah.c:
    echo one is defined: $(one)
```

---

## Automatic Variables

These are set automatically for each rule and can only be used in recipe lines.

| Variable | Description |
|----------|-------------|
| `$@` | The file name of the **target** of the rule. In a rule with multiple targets, it refers to the particular target that triggered the recipe. |
| `$%` | The **target member name** when the target is an archive member. E.g., in `foo.a(bar.o)`, `$%` is `bar.o`. Empty when the target is not an archive. |
| `$<` | The name of the **first prerequisite**. When derived from an implicit rule, this is the first prerequisite added by that rule. |
| `$?` | The names of all **prerequisites newer than the target**, space-separated. Includes prerequisites without timestamps. |
| `$^` | The names of **all prerequisites**, space-separated. Duplicates are removed. Order-only prerequisites are excluded. |
| `$+` | Like `$^`, but **duplicates are preserved** in the order listed in the makefile. Useful for linker commands where order matters. |
| `$\|` | The names of all **order-only prerequisites**, space-separated. |
| `$*` | The **stem** with which an implicit rule matches. For pattern `a.%.b` matching `dir/a.foo.b`, the stem is `dir/foo`. In explicit rules: the target name minus any recognized suffix. |

**Example:**
```makefile
hey: one two
    echo $@    # "hey"
    echo $<    # "one"
    echo $^    # "one two"
    echo $?    # files newer than hey
```

### Directory and File Variants (D/F)

Each automatic variable has two variants that extract the directory and filename parts:

| Variant | Description |
|---------|-------------|
| `$(@D)` | Directory part of `$@` |
| `$(@F)` | File (name) part of `$@` |
| `$(*D)` | Directory part of `$*` |
| `$(*F)` | File part of `$*` |
| `$(%D)` | Directory part of `$%` |
| `$(%F)` | File part of `$%` |
| `$(<D)` | Directory part of `$<` |
| `$(<F)` | File part of `$<` |
| `$(^D)` | Directory parts of `$^` |
| `$(^F)` | File parts of `$^` |
| `$(+D)` | Directory parts of `$+` |
| `$(+F)` | File parts of `$+` |
| `$(?D)` | Directory parts of `$?` |
| `$(?F)` | File parts of `$?` |

Example usage:
```makefile
foo : bar/lose
    cd $(<D) && gobble $(<F) > ../$@
# $(<D) = "bar", $(<F) = "lose"
```

---

## Pattern Rules

### Introduction

Pattern rules use the `%` character (exactly one per target pattern) to match filenames dynamically. The `%` matches **any nonempty substring** called the **stem**; other characters match literally.

- `%.c` matches any file ending in `.c`
- `s.%.c` matches files starting with `s.`, ending in `.c`, with at least 5 chars total

When `%` appears in prerequisites, it represents the same stem matched in the target.

**Basic syntax:**
```makefile
%.o : %.c
    $(CC) -c $(CFLAGS) $< -o $@
```

This describes how to produce `n.o` from `n.c` for any stem `n`.

### Pattern Matching Details

A target pattern has a prefix and suffix (either or both may be empty), with `%` between them. It matches filenames that start with the prefix and end with the suffix.

**Directory handling:** When a target pattern lacks a slash, directory names are temporarily stripped before matching, then restored when constructing prerequisite names.

Example: Pattern `e%t` matches `src/eat` with stem `src/a`. Combined with prerequisite pattern `c%r`, generates `src/car`.

**Rule selection when multiple patterns match:**
1. Target pattern must match and all prerequisites must exist or be buildable.
2. Make selects the rule with the **shortest stem** (most specific).
3. If stems are equal length, the **first rule in the makefile** wins.

### Static Pattern Rules

Static pattern rules specify multiple targets with pattern-based prerequisite construction, but are restricted to an explicit list of targets (unlike general pattern rules which apply to any matching target).

**Syntax:**
```makefile
targets … : target-pattern : prereq-patterns …
    recipe
```

**Example:**
```makefile
objects = foo.o bar.o all.o
all: $(objects)
    $(CC) $^ -o all

$(objects): %.o: %.c
    $(CC) -c $^ -o $@
```

The stem is extracted from each target by matching `target-pattern`, then substituted into `prereq-patterns`.

**With filter:**
```makefile
obj_files = foo.result bar.o lose.o

$(filter %.o,$(obj_files)): %.o: %.c
    echo "target: $@ prereq: $<"

$(filter %.result,$(obj_files)): %.result: %.raw
    echo "target: $@ prereq: $<"
```

### Pattern Rules vs. Static Pattern Rules

- **Pattern rules** apply to any target that matches — they are implicit rules.
- **Static pattern rules** apply only to an explicit list of targets — they are explicit rules and take precedence.

---

## Wildcard & File Functions

### Wildcard Expansion

Wildcard expansion happens **automatically in rule targets and prerequisites**, but NOT in variable assignments. Use the `wildcard` function to force expansion:

```makefile
# Wrong — stored literally, not expanded:
objects = *.o

# Correct — expanded at assignment time:
objects := $(wildcard *.o)
```

**`$(wildcard pattern…)`**

Returns a space-separated list of existing files matching the patterns. Unmatched patterns produce no output (unlike in rules). Results are sorted.

```makefile
$(wildcard *.c)               # All .c files
$(wildcard src/*.c tests/*.c) # Multiple patterns
```

Combined with patsubst for a common pattern:
```makefile
objects := $(patsubst %.c,%.o,$(wildcard *.c))

foo : $(objects)
    cc -o foo $(objects)
```

### The `file` Function

Read from and write to files directly from makefile logic.

**Syntax:**
```makefile
$(file op filename[,text])
```

**Operators:**
- `>` — Overwrite file with text (creates if missing)
- `>>` — Append text to file
- `<` — Read file contents (text argument not used)

**Behavior:**
- Writing: if text doesn't end with newline, one is added automatically.
- Reading: returns file contents with final newline stripped. Non-existent file returns empty string.
- Writing: returns empty string. Fatal error if file cannot be opened.

**Examples:**
```makefile
# Write argument list to a file for commands that accept @filename:
program: $(OBJECTS)
    $(file >$@.in,$^)
    $(CMD) $(CMDFLAGS) @$@.in
    @rm $@.in

# Write each argument on a separate line:
program: $(OBJECTS)
    $(file >$@.in) $(foreach O,$^,$(file >>$@.in,$O))
    $(CMD) $(CMDFLAGS) @$@.in
    @rm $@.in
```

---

## Phony Targets & Special Targets

### Phony Targets

A phony target is not a real file — it's a label for a recipe to execute on demand.

**Why use `.PHONY`:**
1. Avoid conflicts when a file of the same name exists.
2. Performance: implicit rule search is bypassed for phony targets.

```makefile
.PHONY: clean
clean:
    rm *.o temp
```

Without `.PHONY`, if a file named `clean` exists, `make clean` would do nothing (file is up to date). With `.PHONY`, the recipe always runs.

**Multiple phony targets:**
```makefile
.PHONY: all clean install

all: prog1 prog2 prog3

clean:
    rm -f *.o

install: all
    cp prog1 prog2 prog3 /usr/local/bin
```

**Chained phony targets:**
```makefile
.PHONY: cleanall cleanobj cleandiff

cleanall: cleanobj cleandiff
    rm program

cleanobj:
    rm *.o

cleandiff:
    rm *.diff
```

**Note:** Phoniness is not inherited by prerequisites — each must be declared `.PHONY` explicitly.

### Special Targets

These special target names have built-in meaning in GNU Make:

| Target | Description |
|--------|-------------|
| `.PHONY` | Prerequisites are phony targets — always execute, never check for files |
| `.SUFFIXES` | Prerequisites define the list of suffixes for old-style suffix rules. No prerequisites clears the list. |
| `.DEFAULT` | Recipe runs for any target that has no explicit or implicit rule |
| `.PRECIOUS` | Target files are not deleted if make is interrupted, and intermediate files using this target are preserved |
| `.INTERMEDIATE` | Prerequisites are treated as intermediate files, eligible for automatic deletion |
| `.NOTINTERMEDIATE` | Prerequisites are never treated as intermediate files |
| `.SECONDARY` | Like intermediate, but never automatically deleted |
| `.SECONDEXPANSION` | Enables a second expansion pass of all prerequisites after all makefiles are read |
| `.DELETE_ON_ERROR` | Delete target file if its recipe exits with nonzero status |
| `.IGNORE` | Ignore errors for specified targets (or all targets if no prerequisites) |
| `.LOW_RESOLUTION_TIME` | Treat listed files as having low-resolution timestamps |
| `.SILENT` | Don't echo recipes for specified targets (or all if no prerequisites) |
| `.EXPORT_ALL_VARIABLES` | Export all variables to child processes (like `export` with no args) |
| `.NOTPARALLEL` | Run all targets serially for this invocation (or listed targets serially if they have prerequisites) |
| `.ONESHELL` | All recipe lines for a target are given to a single shell invocation |
| `.POSIX` | Enable POSIX-conforming mode; first failing command in recipe causes immediate failure |

---

## Implicit Rules

Implicit rules describe how to build one type of file from another based on filename extensions or patterns. Make searches for an applicable implicit rule automatically when no explicit recipe is given.

### Built-in Implicit Rules (Catalogue)

Key built-in rules and the variables that customize them:

**C compilation** — `n.o` from `n.c`:
```makefile
$(CC) $(CPPFLAGS) $(CFLAGS) -c
```
Variables: `CC` (default: `cc`), `CFLAGS`, `CPPFLAGS`

**C++ compilation** — `n.o` from `n.cc`, `n.cpp`, or `n.C`:
```makefile
$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c
```
Variables: `CXX` (default: `g++`), `CXXFLAGS`, `CPPFLAGS`

**Pascal compilation** — `n.o` from `n.p`:
```makefile
$(PC) $(PFLAGS) -c
```

**Fortran** — `n.o` from `n.f`, `n.F`, `n.r`:
```makefile
$(FC) $(FFLAGS) -c          # .f
$(FC) $(FFLAGS) $(CPPFLAGS) -c  # .F (with preprocessing)
$(FC) $(FFLAGS) $(RFLAGS) -c   # .r (Ratfor)
```
Fortran preprocessing: `.F`→`.f` via `$(FC) $(CPPFLAGS) $(FFLAGS) -F`

**Modula-2:**
- `.def`→`.sym`: `$(M2C) $(M2FLAGS) $(DEFFLAGS)`
- `.mod`→`.o`: `$(M2C) $(M2FLAGS) $(MODFLAGS)`

**Assembly** — `n.o` from `n.s`:
```makefile
$(AS) $(ASFLAGS)
```
`.S`→`.s` via `$(CPP) $(CPPFLAGS)`
Variables: `AS` (default: `as`), `ASFLAGS`

**Linking** — `n` from `n.o`:
```makefile
$(CC) $(LDFLAGS) n.o $(LOADLIBES) $(LDLIBS)
```
Variables: `CC`, `LDFLAGS`, `LOADLIBES`, `LDLIBS`

**Archive** — `(m)` from `m.o`:
```makefile
$(AR) $(ARFLAGS) $@ $<
$(RANLIB) $@
```
Variables: `AR` (default: `ar`), `ARFLAGS` (default: `rv`), `RANLIB`

**Yacc** — `.y`→`.c`:
```makefile
$(YACC) $(YFLAGS)
```

**Lex** — `.l`→`.c`:
```makefile
$(LEX) $(LFLAGS)
```

**TeX/LaTeX:**
- `.tex`→`.dvi`: `$(TEX)`
- `.web`→`.tex`: `$(WEAVE)`
- `.texinfo`/`.texi`→`.dvi`: `$(TEXI2DVI) $(TEXI2DVI_FLAGS)`
- `.texinfo`/`.texi`→`.info`: `$(MAKEINFO) $(MAKEINFO_FLAGS)`

**Version Control:**
- RCS: extracts files from `n,v` or `RCS/n,v` using `$(CO) $(COFLAGS)`
- SCCS: extracts from `s.n` or `SCCS/s.n` using `$(GET) $(GFLAGS)`

**Variable naming conventions:**
- `COMPILE.x` — compile a source of suffix `.x`
- `LINK.x` — link from suffix `.x`
- `PREPROCESS.x` — preprocess suffix `.x`
- `OUTPUT_OPTION` — typically `-o $@`

**Key implicit rule variables:**
- `CC` — C compiler (default: `cc`)
- `CXX` — C++ compiler (default: `g++`)
- `FC` — Fortran compiler (default: `f77`)
- `AS` — Assembler (default: `as`)
- `AR` — Archive tool (default: `ar`)
- `ARFLAGS` — Archive flags (default: `rv`)
- `PC` — Pascal compiler (default: `pc`)
- `CFLAGS` — C compiler flags
- `CXXFLAGS` — C++ compiler flags
- `CPPFLAGS` — C preprocessor flags
- `LDFLAGS` — Linker flags
- `LDLIBS` / `LOADLIBES` — Libraries to link
- `FFLAGS` — Fortran compiler flags
- `ASFLAGS` — Assembler flags
- `YFLAGS` — Yacc flags
- `LFLAGS` — Lex flags

### Chained Implicit Rules

Make can apply a sequence (chain) of implicit rules to build a target. For example, to build `foo.o` from `foo.y`, make might chain:
1. Yacc rule: `foo.y` → `foo.c` (using `$(YACC) $(YFLAGS)`)
2. C compile rule: `foo.c` → `foo.o`

Make automatically recognizes these chains even when the intermediate file (`foo.c`) doesn't explicitly appear in the makefile.

**Intermediate files — special behavior:**
- **Creation:** Make only creates an intermediate file if one of its prerequisites is outdated. It won't create it just because a target depends on it indirectly.
- **Deletion:** After using an intermediate file to satisfy a chain, make automatically deletes it (prints `rm n.c`). This keeps the build tree clean.

**Preventing intermediate file deletion:**
- List the file as a prerequisite of `.SECONDARY` — preserves it but still treats it as intermediate
- List the file as a prerequisite of `.PRECIOUS` — preserves it and never deletes on interruption
- List the file as a prerequisite of `.NOTINTERMEDIATE` — prevents intermediate treatment entirely
- Simply mention the file as a target or prerequisite anywhere in the makefile

**Constraint:** No single implicit rule may appear twice in a chain (prevents infinite loops).

### Suffix Rules (Old-Style)

The old-fashioned way to define implicit rules, kept for compatibility. Pattern rules are preferred.

**Double-suffix rule** — equivalent to a pattern rule:
```makefile
.c.o:
    $(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $<
# Equivalent to: %.o : %.c
```

**Single-suffix rule** — matches any file:
```makefile
.c:
    $(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $<
# Equivalent to: % : %.c
```

**Managing known suffixes:**
```makefile
.SUFFIXES:           # Clear all known suffixes
.SUFFIXES: .c .o     # Define only these suffixes
```

Limitations: suffix rules cannot have additional prerequisites (they'd be treated as regular targets), and suffix rules with no recipe are meaningless.

---

## Multiple Rules for One Target

A single target may appear in multiple rules. Prerequisites from all rules are **merged** into one list:

```makefile
objects = foo.o bar.o
$(objects): config.h    # Add config.h as dependency without overriding recipes
```

Only **one recipe** is allowed per target. If multiple rules specify recipes, make uses the last one and prints an error. Use **double-colon rules** (`::`) when multiple recipes for the same target are needed:

```makefile
blah::
    echo "hello"

blah::
    echo "hello again"
# Both recipes execute
```

---

## Functions Reference

### Function Invocation Syntax

```makefile
$(function-name arguments)
# or
${function-name arguments}
```

Arguments are comma-separated. Leading whitespace after the opening comma is significant.

---

### Text Manipulation Functions

**`$(subst from,to,text)`**
Replace all occurrences of `from` with `to` in `text`:
```makefile
$(subst ee,EE,feet on the street)
# → "fEEt on the strEEt"
```

**`$(patsubst pattern,replacement,text)`**
Replace whitespace-separated words matching `pattern` with `replacement`. The `%` wildcard matches any nonempty string (stem):
```makefile
$(patsubst %.c,%.o,x.c.c bar.c)
# → "x.c.o bar.o"
```

Shorthand in variable reference:
```makefile
$(var:suffix=replacement)   # = $(patsubst %suffix,%replacement,$(var))
$(var:.c=.o)                # = $(patsubst %.c,%.o,$(var))
```

**`$(strip string)`**
Remove leading/trailing whitespace, collapse internal whitespace to single spaces:
```makefile
$(strip a  b   c )
# → "a b c"
```

**`$(findstring find,in)`**
Return `find` if it appears in `in`, otherwise empty:
```makefile
$(findstring a,a b c)  # → "a"
$(findstring d,a b c)  # → ""
```

**`$(filter pattern…,text)`**
Keep only words in `text` that match one of the patterns (`%` wildcard):
```makefile
$(filter %.c %.s,foo.c bar.c baz.s ugh.h)
# → "foo.c bar.c baz.s"
```

**`$(filter-out pattern…,text)`**
Inverse of `filter` — remove words matching any pattern:
```makefile
$(filter-out %.h,$(files))   # Remove header files from list
```

**`$(sort list)`**
Sort words lexically and remove duplicates:
```makefile
$(sort foo bar lose foo)
# → "bar foo lose"
```

**`$(word n,text)`**
Return the nth word (1-indexed):
```makefile
$(word 2,foo bar baz)  # → "bar"
```

**`$(wordlist s,e,text)`**
Return words from position s to e (inclusive):
```makefile
$(wordlist 2,3,foo bar baz)  # → "bar baz"
```

**`$(words text)`**
Return the count of words:
```makefile
$(words foo bar baz)  # → "3"
```

**`$(firstword names…)`**
Return the first word.

**`$(lastword names…)`**
Return the last word:
```makefile
$(lastword foo bar)  # → "bar"
```

---

### File Name Functions

**`$(dir names…)`**
Extract directory components (everything through last slash; `./` if no slash):
```makefile
$(dir src/foo.c hacks)  # → "src/ ./"
```

**`$(notdir names…)`**
Remove directory components:
```makefile
$(notdir src/foo.c hacks)  # → "foo.c hacks"
```

**`$(suffix names…)`**
Extract file extensions (from last `.`):
```makefile
$(suffix src/foo.c src-1.0/bar.c hacks)  # → ".c .c"
```

**`$(basename names…)`**
Remove file extensions, keep directory path:
```makefile
$(basename src/foo.c src-1.0/bar hacks)  # → "src/foo src-1.0/bar hacks"
```

**`$(addsuffix suffix,names…)`**
Append suffix to each name:
```makefile
$(addsuffix .c,foo bar)  # → "foo.c bar.c"
```

**`$(addprefix prefix,names…)`**
Prepend prefix to each name:
```makefile
$(addprefix src/,foo bar)  # → "src/foo src/bar"
```

**`$(join list1,list2)`**
Merge two lists word-by-word:
```makefile
$(join a b,.c .o)  # → "a.c b.o"
```

**`$(wildcard pattern)`** — see Wildcard section above.

**`$(realpath names…)`**
Return canonical absolute paths (resolves symlinks). Empty string on failure.

**`$(abspath names…)`**
Return absolute paths without resolving symlinks. Files need not exist.

---

### The `foreach` Function

**Syntax:** `$(foreach var,list,text)`

For each word in `list`, temporarily set `var` to that word and expand `text`. Results are concatenated with spaces.

```makefile
dirs := a b c d
files := $(foreach dir,$(dirs),$(wildcard $(dir)/*))
# Equivalent to: $(wildcard a/* b/* c/* d/*)
```

```makefile
foo := who are you
bar := $(foreach wrd,$(foo),$(wrd)!)
# bar = "who! are! you!"
```

Key characteristics:
- `text` is expanded once per word in `list`
- The `var` variable has no lasting effect after the function completes
- If `var` was undefined before, it remains undefined after

---

### The `call` Function

Creates parameterized, reusable macros.

**Syntax:** `$(call variable,param,param,…)`

Parameters are assigned to `$(1)`, `$(2)`, etc. `$(0)` holds the variable name.

```makefile
reverse = $(2) $(1)
foo = $(call reverse,a,b)
# foo = "b a"
```

```makefile
pathsearch = $(firstword $(wildcard $(addsuffix /$(1),$(subst :, ,$(PATH)))))
LS := $(call pathsearch,ls)
# LS = "/bin/ls"
```

**Map function:**
```makefile
map = $(foreach a,$(2),$(call $(1),$(a)))
o = $(call map,origin,o map MAKE)
```

Notes:
- The `variable` argument is a name, not a reference — no `$` needed
- Built-in function names always take precedence over user-defined names
- Parameters are expanded before assignment to `$(1)`, `$(2)`, etc.
- Nested calls create separate local scoping

---

### The `shell` Function

Execute a shell command and capture its output.

```makefile
contents := $(shell cat foo)
files := $(shell echo *.c)
```

- Newlines and CR/LF pairs in output are converted to spaces
- Trailing newlines are removed
- The exit status is stored in `.SHELLSTATUS` variable
- Alternative: the `!=` assignment operator has similar behavior

**When the variable is exported:** To prevent infinite loops, make uses the pre-existing environment value (or empty string) when expanding a variable in the shell that is also being exported.

**Performance note:** In recursively expanded variables, `$(shell ...)` re-executes every time the variable is used. Use `:=` to capture the result once.

---

### The `if` Function

```makefile
$(if condition,then-part[,else-part])
```

Expands `then-part` if `condition` is non-empty, otherwise `else-part` (if provided):
```makefile
foo := $(if this-is-not-empty,then!,else!)  # → "then!"
empty :=
bar := $(if $(empty),then!,else!)            # → "else!"
```

---

### Make Control Functions

**`$(error text…)`**
Generate a fatal error. Make halts immediately. The message text is expanded first:
```makefile
$(error Target $(target) not supported)
```
Only triggers when the function is actually evaluated — not in unused recipes or deferred variables.

**`$(warning text…)`**
Print a warning message to stderr and continue. Returns empty string:
```makefile
$(warning About to do something risky)
```

**`$(info text…)`**
Print text to stdout. No location prefix, no error, returns empty string:
```makefile
$(info Building target: $@)
```

**Key distinction:** `$(error)` halts make; `$(warning)` and `$(info)` allow processing to continue.

---

### The `origin` Function

**`$(origin variable)`**
Returns where a variable was defined:
- `undefined` — never defined
- `default` — built-in default rule
- `environment` — from the environment
- `environment override` — from environment with `-e` flag
- `file` — defined in a makefile
- `command line` — defined on the command line
- `override` — defined with `override` in a makefile
- `automatic` — an automatic variable

---

### The `value` Function

**`$(value variable)`**
Returns the value of a variable without expanding it (useful for recursive variables).

---

## Conditionals

Control which parts of a makefile are used based on variable values.

### Syntax

Simple form:
```makefile
conditional-directive
text-if-true
endif
```

With else:
```makefile
conditional-directive
text-if-true
else
text-if-false
endif
```

Chained:
```makefile
conditional-directive-one
text-if-one-true
else conditional-directive-two
text-if-two-true
else
text-if-false
endif
```

### The Four Directives

**`ifeq`** — test equality (expands both arguments, compares):
```makefile
ifeq (arg1, arg2)
ifeq 'arg1' 'arg2'
ifeq "arg1" "arg2"
ifeq "arg1" 'arg2'
ifeq 'arg1' "arg2"
```

```makefile
ifeq ($(CC),gcc)
  CFLAGS += -g
else
  CFLAGS += -O2
endif
```

**`ifneq`** — test inequality:
```makefile
ifneq ($(a),$(b))
  # a and b differ
endif
```

**`ifdef`** — test if variable has a value (NOTE: tests if defined with any value, not if non-empty):
```makefile
ifdef foo
  echo "foo is defined"
endif
```

`ifdef` only checks if the variable name is defined — it does **not** expand the variable to check for non-empty content.

**`ifndef`** — test if variable is undefined or empty:
```makefile
ifndef VERBOSE
  MAKEFLAGS += --silent
endif
```

**Empty variable check (use `strip`):**
```makefile
ifeq ($(strip $(foo)),)
  echo "foo is empty or whitespace-only"
endif
```

**Spacing rules:** Extra leading spaces are allowed and ignored, but a **tab is not allowed** at the start of a conditional directive line (it would be treated as a recipe).

---

## Recipe Execution & Output Control

### How Recipes Execute

Each recipe line is executed in a **separate, new shell**. This means:
- Shell variables set in one line do not persist to the next
- `cd` in one line does not affect the next line's working directory

**To maintain state across lines**, chain commands with `&&` or use `\` line continuation:
```makefile
foo: bar/lose
    cd $(<D) && gobble $(<F) > ../$@

# Or with backslash continuation (still one shell call):
all:
    cd somewhere; \
    echo "Current dir: $$(pwd)"
```

**MS-DOS exception:** `cd` affects subsequent lines on MS-DOS because working directory is global.

### Recipe Prefixes

| Prefix | Effect |
|--------|--------|
| `@` | **Suppress echoing** of that command line before execution |
| `-` | **Ignore errors** — continue even if this command returns nonzero |
| `+` | **Always execute** even with `-n`, `-t`, or `-q` flags; also forces execution if recipe contains `$(MAKE)` or `${MAKE}` |

```makefile
all:
    @echo "This message prints but the echo command itself won't be shown"
    echo "This command AND the line will be shown"
    -false         # fails but make continues
    touch result   # still runs after the false above
```

### Echo Control

**`@` prefix** — suppress echo for one line:
```makefile
deploy:
    @echo "Deploying..."
    rsync -av dist/ server:
```

**`-s` / `--silent` flag** — suppress all echo (equivalent to `@` on every line).

**`.SILENT` special target** — suppress echo in makefile:
```makefile
.SILENT:          # Suppress echo for all targets
# or
.SILENT: clean    # Only for clean target
```

### SHELL Variable

Change the shell used to execute recipes:
```makefile
SHELL = /bin/bash

cool:
    echo "Using bash features: $${BASH_VERSION}"
```

### Dollar Signs in Recipes

Use `$$` to pass a literal `$` to the shell:
```makefile
all:
    sh_var='test'; echo $$sh_var     # shell variable
    echo $(make_var)                 # make variable
```

### `.ONESHELL` Special Target

Run all recipe lines in a single shell invocation:
```makefile
.ONESHELL:
deploy:
    cd /tmp
    echo "Now in /tmp"   # Works! cd persisted because same shell
```

### Error Handling

- `-` prefix: ignore errors for one line
- `-k` flag: continue building other targets even when one fails
- `-i` flag: ignore all errors globally
- `.DELETE_ON_ERROR` special target: delete target file if recipe fails
- `.IGNORE` special target: ignore errors for specified targets

---

## Instead-of-Execution Flags

These flags change what make does instead of running recipes:

**`-n` / `--just-print` / `--dry-run` / `--recon`**
Print recipes that would be executed without actually running them. Commands starting with `+` or containing `$(MAKE)` still execute. Useful for seeing what would happen:
```bash
make -n install
```

**`-t` / `--touch`**
Touch target files (update timestamps) without running recipes. Makes targets appear up to date.

**`-q` / `--question`**
Silent check — print nothing, run nothing. Exit code:
- `0` — all targets are up to date
- `1` — some target needs updating
- `2` — an error occurred

**Important:** These three flags cannot be combined. The `+` recipe prefix and recipes containing `$(MAKE)` or `${MAKE}` execute regardless of these flags.

---

## Include Directive

### Syntax

```makefile
include filenames…
```

Filenames can contain shell glob patterns. Make reads the included file as if it appeared at that point in the makefile.

**Formatting:** Leading spaces are allowed and ignored, but a **tab is not allowed** (would be treated as a recipe start).

### Handling Missing Files

If an included file is not found, make does **not** immediately fail. Instead:
1. Make notes the missing file.
2. It continues processing the rest of the makefile.
3. After reading all makefiles, it tries to rebuild the missing file using normal rules.
4. If it still can't be found or built, **then** it's a fatal error.

This allows patterns like auto-generated dependency files:
```makefile
-include $(DEPS)    # Include dependency files if they exist
```

### `-include` / `sinclude` Variant

No error (not even a warning) if files don't exist or can't be remade:
```makefile
-include config.mk
sinclude config.mk   # BSD compat alias for -include
```

### Common Use: Auto-Generated Dependencies

```makefile
SRCS := $(wildcard src/*.c)
DEPS := $(SRCS:.c=.d)

-include $(DEPS)

%.d: %.c
    $(CC) -MM $< > $@
```

---

## Recursive Make

### Using `$(MAKE)` in Sub-makes

Always use `$(MAKE)`, not a hardcoded `make`. This preserves flags, the `--print-directory` option, and allows overriding the make binary:

```makefile
all:
    cd subdir && $(MAKE)
    # or equivalently:
    $(MAKE) -C subdir
```

Declare targets that invoke recursive make as `.PHONY`:
```makefile
.PHONY: all clean

all:
    $(MAKE) -C src
    $(MAKE) -C docs

clean:
    $(MAKE) -C src clean
    $(MAKE) -C docs clean
```

### Passing Variables to Sub-makes

**`export` directive** — make a variable available to sub-processes:
```makefile
export CC = gcc
export CFLAGS = -Wall -O2

# Or inline:
export cooly = "visible in subdirectories"

all:
    $(MAKE) -C subdir
```

**`export` with no prerequisites** — export all variables:
```makefile
.EXPORT_ALL_VARIABLES:
# or
export   # Bare export exports everything
```

**`unexport`** — prevent a variable from being exported:
```makefile
unexport INTERNAL_VAR
```

**Passing on command line:**
```makefile
all:
    $(MAKE) -C subdir VERSION=$(VERSION) DEBUG=$(DEBUG)
```

### MAKEFLAGS Variable

Make automatically stores its command-line flags in `MAKEFLAGS` and passes it to recursive invocations via the environment. Sub-makes receive the parent's flags automatically — no explicit passing needed.

**Structure:** Single-letter flags without arguments appear first (without hyphens), followed by a space and any flags with arguments or long options.

**Example:** Invoking `make -ks` sets `MAKEFLAGS` to `ks`.

**What is NOT passed:** The `-C`, `-f`, `-o`, and `-W` options are intentionally excluded from `MAKEFLAGS` — they are not passed to sub-makes.

**Special `-j` handling:** The `-j` option is passed specially to coordinate parallel jobs across parent and child make processes.

**Precedence:** Environment-specified `MAKEFLAGS` takes precedence over makefile-specified versions — unique behavior among environment variables.

**Checking MAKEFLAGS in makefile:**
```makefile
all:
ifneq (,$(findstring i, $(MAKEFLAGS)))
    echo "i flag (ignore errors) was passed"
endif
```

**MFLAGS variable:** Legacy alias for `MAKEFLAGS`, kept for historical compatibility. Always begins with a hyphen when non-empty. Does not include command-line variable definitions. Use `MAKEFLAGS` in new makefiles.

**GNUMAKEFLAGS variable:** GNU-Make-specific flags for environments that use both GNU and non-GNU make. Parsed like `MAKEFLAGS` but prevents GNU-specific flags from being seen by other make implementations.

**Key special variables set by make:**
- `MAKEFLAGS` — flags passed to this invocation
- `MAKEOVERRIDES` — command-line variable assignments
- `MAKELEVEL` — recursion depth (0 = top level)
- `MAKEFILE_LIST` — list of makefiles read so far
- `CURDIR` — current working directory when make started
- `MAKE` — the name used to invoke make (for recursive calls)
- `MAKE_VERSION` — the version of GNU Make
- `MAKE_HOST` — the host triple make was compiled for
- `.SHELLSTATUS` — exit status of the most recent `$(shell ...)` call

### `$(MAKE)` Variable Details

`$(MAKE)` always refers to the make binary used to invoke the current makefile, including its path. It also adds flags to enable sub-makes to recognize they are being invoked recursively (sets `MAKELEVEL`).

Recipe lines containing `$(MAKE)` or `${MAKE}` execute even with `-n`, `-t`, or `-q` flags (same as the `+` prefix behavior).

### `CURDIR` Variable

Set to the absolute path of the current working directory when make starts. Remains constant even when processing included files from other directories:
```makefile
BUILD_DIR := $(CURDIR)/build
```

---

## Variable Scoping and define

### Multi-line Variables with `define`

```makefile
define two_lines
echo foo
echo $(bar)
endef
```

Use as a recipe (each line runs in a separate shell):
```makefile
define run_tests
cd tests && \
./run_all.sh
endef

test:
    $(run_tests)
```

### `define` with `endef`

The variable name follows `define`, optionally with an assignment operator:
```makefile
define NEWLINE


endef

define recursive_var =
value with $(other)
endef

define simple_var :=
value expanded now
endef
```

---

## vpath Directive

Specify directories to search for prerequisites:

```makefile
vpath %.h ../headers ../other-directory
vpath %.c src

# Search for .h files in ../headers, then ../other-directory
# Search for .c files in src/
```

**`vpath` with no pattern** — search all directories for all files:
```makefile
vpath ../headers
```

**`VPATH` variable** — colon or space-separated list of directories to search for all files (less specific than `vpath`):
```makefile
VPATH = src:../headers
```

---

## Options Summary

Key command-line options:

| Flag | Long form | Description |
|------|-----------|-------------|
| `-n` | `--just-print` | Dry run — print but don't execute |
| `-t` | `--touch` | Touch targets instead of rebuilding |
| `-q` | `--question` | Check if up to date, return exit code |
| `-k` | `--keep-going` | Continue despite errors |
| `-i` | `--ignore-errors` | Ignore all errors |
| `-s` | `--silent` | Suppress all recipe echoing |
| `-j N` | `--jobs=N` | Run N jobs in parallel |
| `-l N` | `--load-average=N` | Don't start new jobs if load > N |
| `-C dir` | `--directory=dir` | Change to dir before doing anything |
| `-f file` | `--file=file` | Use file as the makefile |
| `-I dir` | `--include-dir=dir` | Search dir for included makefiles |
| `-e` | `--environment-overrides` | Environment variables override makefile assignments |
| `-r` | `--no-builtin-rules` | Disable built-in implicit rules |
| `-R` | `--no-builtin-variables` | Disable built-in variables |
| `-p` | `--print-data-base` | Print the rule database |
| `-w` | `--print-directory` | Print working directory before/after processing |
| `--no-print-directory` | | Suppress `-w` (useful in recursive make) |
| `-B` | `--always-make` | Unconditionally rebuild all targets |
| `--warn-undefined-variables` | | Warn when undefined variable is referenced |

---

## Quick Reference: Assignment Operators

| Operator | Name | When Expanded | Notes |
|----------|------|---------------|-------|
| `=` | Recursive | At use time | Re-expands every reference; allows forward refs |
| `:=` | Simply expanded | At definition | Expands once; POSIX |
| `::=` | Simply expanded | At definition | Same as `:=`; POSIX syntax |
| `:::=` | Immediately expanded | At definition | Quotes `$` → `$$` after expansion; BSD compat |
| `?=` | Conditional | At definition | Only assigns if variable not yet defined |
| `!=` | Shell | At definition | Runs shell command, captures output |
| `+=` | Append | Depends on flavor | Appends with space; inherits existing flavor |

---

## Quick Reference: Recipe Line Prefixes

| Prefix | Effect |
|--------|--------|
| `@` | Don't echo the command |
| `-` | Ignore nonzero exit status (don't treat as error) |
| `+` | Execute even with `-n`/`-t`/`-q`; marks as recursive-make-aware |

---

*Sources: GNU Make Manual (https://www.gnu.org/software/make/manual/), makefiletutorial.com*
