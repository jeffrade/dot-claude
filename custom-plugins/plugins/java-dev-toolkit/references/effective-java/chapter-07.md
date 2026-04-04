# Chapter 7: Lambdas and Streams

Items 42-48. Java 8's functional programming features: lambdas, method references,
functional interfaces, and the Stream API. These items teach when and how to use
functional idioms effectively without sacrificing readability -- a critical balance
given our simplicity principle.

---

### Item 42: Prefer Lambdas to Anonymous Classes

**Takeaway:** Lambdas are more concise and readable than anonymous classes for functional interfaces; use them wherever a single-method interface instance is needed.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer writes an anonymous class for a functional interface (`Comparator`, `Runnable`, `Callable`, etc.), when discussing the limitations of lambdas (no access to `this` of the enclosing instance from the lambda, no serialization guarantees, not usable for abstract classes or multi-method interfaces), when a lambda exceeds three lines (consider extracting to a named method), or when reviewing old-style code that predates Java 8.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item42/SortFourWays.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item42/Operation.java` (enum with lambda-based strategy)

---

### Item 43: Prefer Method References to Lambdas

**Takeaway:** Where a lambda simply calls an existing method, a method reference is shorter and often clearer; use `ClassName::methodName` instead of `x -> className.methodName(x)`.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a lambda does nothing but delegate to a single method call, when discussing the five kinds of method references (static, bound instance, unbound instance, class constructor, array constructor), when a method reference is actually less clear than the lambda (in which case keep the lambda -- readability wins), or when reviewing stream pipelines where method references would make the chain more readable.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item43/Freq.java`

---

### Item 44: Favor Standard Functional Interfaces

**Takeaway:** Use the 43 standard functional interfaces in `java.util.function` before writing custom ones; if you must write a custom interface, annotate it with `@FunctionalInterface`.
**Maps to:** core-principles.md#simplicity, core-principles.md#frameworks-last
**When to cite:** When a developer creates a custom single-method interface that duplicates `Function<T,R>`, `Predicate<T>`, `Consumer<T>`, `Supplier<T>`, or their primitive specializations, when discussing the six basic functional interfaces (Operator, Function, Predicate, Supplier, Consumer and their binary variants), when a custom functional interface is justified (domain semantics, documented contract, or custom default methods like `Comparator`), when a custom interface is missing `@FunctionalInterface`, or when reviewing code that uses `Callable<Void>` where `Runnable` would suffice.
**Source example:** No source example (Item 44 is prose-only in the source repository)

---

### Item 45: Use Streams Judiciously

**Takeaway:** Streams are powerful but can be overused; use them when they clarify the code, not when they make it harder to read. Not every loop should be a stream, and not every stream should be a loop.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer writes a stream pipeline that would be clearer as a loop (especially with multiple side effects, try-catch blocks, or local variable mutation), when a developer avoids streams for code that would be dramatically clearer as a pipeline (filtering, mapping, collecting), when a stream pipeline exceeds a reasonable length without intermediate variable names, when discussing the things streams cannot do (access local variables that are not effectively final, return early from the enclosing method, throw checked exceptions), or when reviewing the anagram examples that show iterative, hybrid, and pure-stream approaches.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item45/anagrams/IterativeAnagrams.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item45/anagrams/HybridAnagrams.java` (recommended), `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item45/anagrams/StreamAnagrams.java` (overuse), `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item45/MersennePrimes.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item45/Card.java`

---

### Item 46: Prefer Side-Effect-Free Functions in Streams

**Takeaway:** Stream pipelines should be composed of pure functions (functions whose result depends only on their input); the terminal operation `forEach` should only be used to report results, not to compute them.
**Maps to:** core-principles.md#immutability, core-principles.md#simplicity
**When to cite:** When a developer uses `forEach` to mutate external state (adding to an external list, incrementing a counter), when a stream pipeline has side effects in `map`, `filter`, or other intermediate operations, when a developer is unaware of the `Collectors` API and uses `forEach` to manually build results, when introducing `Collectors.toList()`, `toSet()`, `toMap()`, `groupingBy()`, `joining()`, and other standard collectors, or when reviewing code that uses `stream().forEach()` where `stream().collect()` would be correct.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item46/Freq.java`

---

### Item 47: Prefer Collection to Stream as a Return Type

**Takeaway:** If a method's return value can reasonably be stored in memory, return a `Collection` (or appropriate subtype) rather than a `Stream`, because `Collection` supports both iteration and stream access.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#simplicity
**When to cite:** When a developer returns a `Stream` from a public API method that callers might want to iterate over (or vice versa), when discussing the `Collection` interface as the common ground between iteration and streaming, when a return type is too large for memory and a `Stream` is therefore appropriate, when reviewing a method that returns `Stream` but the caller immediately collects it into a list, or when introducing the adapter pattern for converting between `Stream` and `Iterable`.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item47/PowerSet.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item47/SubLists.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item47/Adapters.java`

---

### Item 48: Use Caution When Making Streams Parallel

**Takeaway:** Parallelizing a stream pipeline can silently produce wrong results or catastrophic performance; it is only beneficial on specific data sources (`ArrayList`, arrays, `IntRange`) with specific terminal operations (`reduce`, `collect`, `min`, `max`, `count`).
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a developer adds `.parallel()` to a stream without measuring, when a stream operates on `LinkedList`, `Stream.iterate`, or `BufferedReader.lines` (all terrible for parallelism), when the terminal operation is `forEach` with side effects (parallel `forEach` is nondeterministic), when discussing the fork/join framework that underlies parallel streams, when a developer assumes parallel streams are always faster, or when reviewing code where correctness depends on encounter order. Note: on Java 21+, for I/O-bound work, virtual threads are almost always a better choice than parallel streams.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item48/ParallelMersennePrimes.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter7/item48/ParallelPrimeCounting.java`
