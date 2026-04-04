# Chapter 9: General Programming

Items 57-68. Practical advice for the nuts and bolts of everyday Java programming:
local variables, control structures, libraries, numeric types, strings, interfaces
as types, reflection, native methods, optimization, and naming. Several of these
items are deeply connected to our core principles.

---

### Item 57: Minimize the Scope of Local Variables

**Takeaway:** Declare local variables where they are first used, not at the top of the method; prefer `for` loops to `while` loops because `for` limits the loop variable's scope.
**Maps to:** core-principles.md#simplicity, core-principles.md#intent-through-keywords
**When to cite:** When a developer declares variables at the top of a method C-style, when a loop variable is declared outside the loop and leaks into the surrounding scope, when reviewing a method where a variable is declared far from its use (making it hard to understand the code), when a `while` loop with an index variable can be rewritten as a `for` loop, or when discussing the relationship between scope minimization and `final` local variables (a narrow scope makes it easier to reason about whether a variable is effectively final).
**Source example:** No source example (Item 57 is prose-only in the source repository)

---

### Item 58: Prefer for-each Loops to Traditional for Loops

**Takeaway:** The enhanced `for` loop (for-each) is clearer, less error-prone, and works with any `Iterable`; use it unless you need the iterator or index explicitly.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer writes a traditional indexed `for` loop over a `List` or array where the index is only used to access elements, when reviewing nested iteration over two collections (for-each avoids the classic "forgot to advance the outer iterator" bug), when discussing the three situations where for-each cannot be used (destructive filtering, transforming, and parallel iteration), or when a developer iterates with `Iterator` explicitly without needing `remove()`.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item58/Card.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item58/DiceRolls.java`

---

### Item 59: Know and Use the Libraries

**Takeaway:** Before writing utility code, check whether the JDK (or a well-established library like Guava) already provides it; library code is written by experts, tested by millions, and maintained for you.
**Maps to:** core-principles.md#frameworks-last, core-principles.md#simplicity
**When to cite:** When a developer writes a custom random number generator, string utility, or collection operation that already exists in the JDK, when discussing `java.util`, `java.util.concurrent`, `java.util.stream`, `java.nio`, `java.time`, and `java.net.http` as essential libraries to know, when a developer is unaware of `ThreadLocalRandom` (replaces `Random` in concurrent code), when reviewing hand-rolled HTTP client code that should use `java.net.http.HttpClient` (Java 11+), or when discussing the tension with our frameworks-last principle: know the standard libraries intimately so you do not need third-party frameworks.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item59/RandomBug.java` (flawed random), `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item59/Curl.java`

---

### Item 60: Avoid float and double If Exact Answers Are Required

**Takeaway:** `float` and `double` are designed for scientific and engineering calculations, not for monetary or other exact decimal values; use `BigDecimal`, `int`, or `long` for exact answers.
**Maps to:** core-principles.md#shift-left, core-principles.md#data-model-first
**When to cite:** When a developer uses `double` for money or any domain where rounding errors are unacceptable, when reviewing financial calculations that use floating-point arithmetic, when discussing the three approaches: `BigDecimal` (exact, with rounding control), `int` (store cents, not dollars), `long` (for larger amounts in minor currency units), when a developer is surprised by `0.1 + 0.2 != 0.3`, or when discussing `BigDecimal`'s performance cost versus correctness (correctness wins for financial calculations).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item60/Change.java` (broken float), `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item60/BigDecimalChange.java` (correct), `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item60/IntChange.java` (int-based)

---

### Item 61: Prefer Primitive Types to Boxed Primitives

**Takeaway:** Use primitives (`int`, `long`, `double`) over their boxed counterparts (`Integer`, `Long`, `Double`) to avoid autoboxing overhead, `NullPointerException` risks, and identity comparison bugs.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer uses `Integer` where `int` would suffice, when reviewing code that compares boxed primitives with `==` (identity comparison, not value comparison), when autoboxing in a tight loop creates millions of wrapper objects (see Item 6), when a boxed variable is uninitialized (`null`) and causes `NullPointerException` on unboxing, when discussing the three legitimate uses of boxed types (generics, reflection, and collections), or when reviewing the `Unbelievable` example where `(Integer)null` causes NPE.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item61/Unbelievable.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item61/BrokenComparator.java`

---

### Item 62: Avoid Strings Where Other Types Are More Appropriate

**Takeaway:** Strings are poor substitutes for other value types, enum types, aggregate types, or capability types; use a proper type instead.
**Maps to:** core-principles.md#shift-left, core-principles.md#data-model-first
**When to cite:** When a developer uses a `String` to represent a numeric value, a boolean, an enum-like value, or a structured aggregate (e.g., `"Jeff|42|true"` parsed by splitting on `|`), when reviewing code that uses string keys for type-unsafe maps (`Map<String, Object>`), when discussing the string-based permission pattern (a security vulnerability), when a developer uses a string thread ID instead of a proper `ThreadLocal`, or when recommending custom value types (`CustomerId`, `EmailAddress`, `Money`) that provide compile-time safety.
**Source example:** No source example (Item 62 is prose-only in the source repository)

---

### Item 63: Beware the Performance of String Concatenation

**Takeaway:** Using the `+` operator for repeated string concatenation in a loop is O(n^2); use `StringBuilder` or `String.join()` instead.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer concatenates strings in a loop with `+`, when reviewing code that builds large strings incrementally (log messages, SQL queries, HTML), when discussing the difference between compile-time constant concatenation (fine, the compiler handles it) and runtime loop concatenation (use `StringBuilder`), when a developer is unaware of `String.join()`, `StringJoiner`, or `Collectors.joining()` as cleaner alternatives, or when performance profiling reveals string concatenation as a bottleneck.
**Source example:** No source example (Item 63 is prose-only in the source repository)

---

### Item 64: Refer to Objects by Their Interfaces

**Takeaway:** If an appropriate interface type exists, declare variables, parameters, return types, and fields using the interface type, not the implementation type.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#frameworks-last
**When to cite:** When a developer declares a variable as `LinkedHashSet<String>` instead of `Set<String>`, when a method parameter or return type is a concrete class instead of an interface, when discussing the three cases where it is appropriate to use the implementation type (no appropriate interface exists, the code depends on implementation-specific behavior, or the implementation provides guarantees not in the interface contract), when reviewing code that uses `ArrayList` in method signatures instead of `List`, or when a developer switches implementations and discovers they must change declarations throughout the codebase (the cost of not using interface types).
**Source example:** No source example (Item 64 is prose-only in the source repository)

---

### Item 65: Prefer Interfaces to Reflection

**Takeaway:** Reflection is powerful but dangerous; use it only when you must, and access objects through their known interfaces rather than reflectively invoking methods.
**Maps to:** core-principles.md#annotations-and-reflection, core-principles.md#shift-left
**When to cite:** CRITICAL ITEM for our codebase. Our principles restrict reflection to a single use case: loading class names from a root-level configuration file. Cite this item whenever a developer uses reflection for dependency injection, serialization hacking, private field access, dynamic proxy generation, or any purpose other than config-driven class loading. The source example (`ReflectiveInstantiation`) demonstrates the one legitimate pattern: use reflection to instantiate a class by name, then access it through a known interface. The three costs of reflection: (1) loss of compile-time type checking, (2) verbose and clumsy code, (3) performance penalty. Every reflective call is a `ClassNotFoundException`, `NoSuchMethodException`, or `IllegalAccessException` waiting to happen at runtime.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter9/item65/ReflectiveInstantiation.java`

---

### Item 66: Use Native Methods Judiciously

**Takeaway:** Rarely if ever use JNI in modern Java; the JVM is fast enough for almost everything, and native code introduces platform dependencies, memory safety risks, and debugging difficulty.
**Maps to:** core-principles.md#simplicity, core-principles.md#frameworks-last
**When to cite:** When a developer proposes using JNI for performance (measure first -- the JVM's JIT compiler is extremely capable), when reviewing code that uses native methods to access platform-specific functionality (consider whether a pure Java alternative exists), when discussing the security and portability implications of native code, or when a developer inherits a codebase with JNI and needs to understand the risks. The three historic uses of JNI (platform-specific facilities, legacy code, performance-critical sections) are all much less compelling than they were a decade ago.
**Source example:** No source example (Item 66 is prose-only in the source repository)

---

### Item 67: Optimize Judiciously

**Takeaway:** Do not optimize prematurely; write good, clear code first, then measure, then optimize the specific bottleneck if one exists.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer complicates code for hypothetical performance gains without measurement, when reviewing "clever" code that sacrifices readability for speed, when a developer says "this is faster" without benchmark data, when discussing Jackson Amdahl's corollary (optimizing a non-bottleneck produces zero benefit), when introducing JMH (Java Microbenchmark Harness) as the correct way to measure, or when an API design decision has permanent performance implications (e.g., making a type mutable for performance when it could be immutable -- here optimization concerns are legitimate because API design is hard to change).
**Source example:** No source example (Item 67 is prose-only in the source repository)

---

### Item 68: Adhere to Generally Accepted Naming Conventions

**Takeaway:** Follow Java's established naming conventions for packages, classes, interfaces, methods, fields, type parameters, and local variables; violations make code harder to read and maintain.
**Maps to:** core-principles.md#simplicity, core-principles.md#intent-through-keywords
**When to cite:** When a developer violates standard naming conventions (camelCase for methods and variables, PascalCase for classes, UPPER_SNAKE_CASE for constants, single letters for type parameters), when reviewing non-standard method names (`getData` where `data()` follows modern conventions for accessor methods, especially in records), when a boolean method does not start with `is`, `has`, `can`, or `should`, when a conversion method does not follow the `toX`, `asX`, or `xOf` conventions, or when a class name is a verb instead of a noun.
**Source example:** No source example (Item 68 is prose-only in the source repository)
