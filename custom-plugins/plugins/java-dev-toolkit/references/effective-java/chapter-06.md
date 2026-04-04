# Chapter 6: Enums and Annotations

Items 34-41. Java's enum types are far more powerful than their C/C++ counterparts,
and annotations replace many fragile naming conventions. Both align with our shift-left
and intent-through-keywords principles: enums catch invalid values at compile time,
and annotations declare intent that tools can verify.

---

### Item 34: Use Enums Instead of int Constants

**Takeaway:** Java enum types are full-fledged classes that provide compile-time type safety, namespace isolation, and the ability to add methods and fields -- far superior to `int` or `String` constants.
**Maps to:** core-principles.md#shift-left, core-principles.md#intent-through-keywords
**When to cite:** When a developer uses `public static final int` or `String` constants for a fixed set of values, when discussing the int enum pattern's flaws (no type safety, no namespace, no iteration, brittle binary compatibility), when a developer needs behavior that varies by constant (use constant-specific method implementations), when introducing the strategy enum pattern (like `PayrollDay`), or when reviewing switch statements on int constants that should be an enum with methods.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item34/Planet.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item34/Operation.java` (constant-specific methods), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item34/PayrollDay.java` (strategy enum), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item34/WeightTable.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item34/Inverse.java`

---

### Item 35: Use Instance Fields Instead of Ordinals

**Takeaway:** Never derive a value from an enum's `ordinal()` method; store the value in an instance field instead, because ordinal values change when constants are reordered.
**Maps to:** core-principles.md#shift-left, core-principles.md#data-model-first
**When to cite:** When a developer calls `.ordinal()` on an enum to use as a value, when reviewing enum declarations where the order of constants matters for correctness (a fragility red flag), when a developer uses `ordinal()` as an array index (use `EnumMap` instead, per Item 37), or when discussing why `Enum.ordinal()` exists (it is for internal use by data structures like `EnumSet` and `EnumMap`, not for application code).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item35/Ensemble.java`

---

### Item 36: Use EnumSet Instead of Bit Fields

**Takeaway:** `EnumSet` provides all the performance benefits of bit fields with the type safety and readability of enums; there is no reason to use bit manipulation for enum flags.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer uses `int` bit fields (`STYLE_BOLD | STYLE_ITALIC`) for a set of flags, when reviewing code that uses bitwise operations to combine and test enum-like values, when discussing the performance of `EnumSet` (internally backed by a single `long` for enums with 64 or fewer constants), or when a developer is unaware that `EnumSet` exists and manually tracks sets of enum values with `HashSet<MyEnum>`.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item36/Text.java`

---

### Item 37: Use EnumMap Instead of Ordinal Indexing

**Takeaway:** Use `EnumMap` when you need a map keyed by enum values; it is faster, safer, and more readable than using `ordinal()` as an array index.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer uses `ordinal()` to index into an array, when reviewing code that uses `new Set[Planet.values().length]` or similar ordinal-indexed arrays, when a developer needs a map from one enum type to another (nested `EnumMap`), when discussing the `Plant` example (grouping plants by lifecycle using streams and `EnumMap`), or when a developer uses `HashMap<MyEnum, V>` where `EnumMap<MyEnum, V>` would be more efficient.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item37/Plant.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item37/Phase.java` (transition map with nested EnumMap)

---

### Item 38: Emulate Extensible Enums with Interfaces

**Takeaway:** While enum types cannot be directly extended, you can emulate extensibility by having enum types implement a common interface, allowing clients to define their own implementations.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#shift-left
**When to cite:** When a developer needs to add new constants to an existing enum (which is not possible), when designing an operation type that clients should be able to extend (like opcodes or operations), when discussing the tradeoff between closed enum sets (compile-time exhaustiveness) and open extension points (runtime flexibility), or when reviewing code that uses a "type" string field to represent extensible categories.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item38/Operation.java` (interface), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item38/BasicOperation.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item38/ExtendedOperation.java`

---

### Item 39: Prefer Annotations to Naming Patterns

**Takeaway:** Annotations (like `@Test`) are strictly superior to naming patterns (like methods starting with "test") because they are checked by the compiler, support parameters, and cannot be silently misspelled.
**Maps to:** core-principles.md#annotations-and-reflection, core-principles.md#shift-left
**When to cite:** When a developer relies on method naming conventions that the compiler cannot enforce, when introducing custom annotations for domain-specific metadata (e.g., `@Transactional`, `@Cacheable`, `@RequiresPermission`), when discussing annotation retention policies (`SOURCE`, `CLASS`, `RUNTIME`), when reviewing test frameworks that use naming conventions instead of annotations, or when explaining how annotation processors shift validation to compile time.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item39/markerannotation/Test.java` (annotation definition), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item39/markerannotation/Sample.java` (usage), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item39/markerannotation/RunTests.java` (processor), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item39/annotationwithparameter/ExceptionTest.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item39/repeatableannotation/ExceptionTest.java`

---

### Item 40: Consistently Use the Override Annotation

**Takeaway:** Use `@Override` on every method that overrides a superclass or interface method; the compiler will catch accidental overloads that look like overrides.
**Maps to:** core-principles.md#annotations-and-reflection, core-principles.md#shift-left
**When to cite:** When a developer overrides a method without `@Override` (the compiler will not catch the mistake if the method signature is wrong), when reviewing `equals(Foo other)` instead of `equals(Object other)` (a classic accidental overload caught by `@Override`), when discussing the one exception (concrete methods implementing abstract declarations -- `@Override` is optional but still recommended), or when a developer accidentally overloads instead of overrides due to a typo in the method signature.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item40/Bigram.java` (missing @Override), `repos/effective-java-3e-source-code/src/effectivejava/chapter6/item40/Bigram2.java` (with @Override)

---

### Item 41: Use Marker Interfaces to Define Types

**Takeaway:** If a marker conveys a type that enables compile-time checking (like `Serializable` enabling `ObjectOutputStream.writeObject`), use a marker interface; if it applies to program elements other than classes, or integrates into an annotation-based framework, use a marker annotation.
**Maps to:** core-principles.md#annotations-and-reflection, core-principles.md#shift-left
**When to cite:** When a developer debates between a marker annotation and a marker interface, when reviewing a `Serializable`-like contract that should be checked at compile time (marker interface is correct), when a developer creates a marker annotation that is only applied to classes and would benefit from compile-time type checking, or when discussing the advantages of marker interfaces (they define a type, enabling generic constraints and method parameter types that the compiler can verify).
**Source example:** No source example (Item 41 is prose-only in the source repository)
