# Chapter 2: Creating and Destroying Objects

Items 1-9. How objects come into existence and how they leave. These items establish
foundational habits for object creation that align tightly with our immutability,
shift-left, and dependency injection principles.

---

### Item 1: Consider Static Factory Methods Instead of Constructors

**Takeaway:** Static factory methods give you named, flexible, cacheable object creation without committing to a public constructor.
**Maps to:** core-principles.md#immutability, core-principles.md#simplicity
**When to cite:** When a developer writes a public constructor for a class that could benefit from descriptive creation method names (e.g., `Color.fromRGB()`), when a class should cache instances (flyweight), when the return type should be an interface rather than the concrete class, or when the class offers multiple construction paths that would otherwise require overloaded constructors with confusing parameter lists.
**Source example:** No source example (Item 1 is prose-only in the source repository)

---

### Item 2: Consider a Builder When Faced with Many Constructor Parameters

**Takeaway:** The Builder pattern produces readable, immutable objects when constructors would otherwise require telescoping parameter lists or JavaBeans-style setters.
**Maps to:** core-principles.md#immutability, core-principles.md#simplicity
**When to cite:** When a class has four or more constructor parameters (especially optional ones), when a developer uses the JavaBeans pattern (setters on a mutable object) for construction, or when constructing immutable objects with complex initialization. Note: our simplicity principle warns against Builder chains when a record with two or three fields suffices. Cite this item only when the parameter count genuinely warrants it.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item2/builder/NutritionFacts.java` (Builder pattern), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item2/hierarchicalbuilder/Pizza.java` (hierarchical builder), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item2/telescopingconstructor/NutritionFacts.java` (anti-pattern), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item2/javabeans/NutritionFacts.java` (anti-pattern)

---

### Item 3: Enforce the Singleton Property with a Private Constructor or an Enum Type

**Takeaway:** If you must have a singleton, an enum with a single element is the most robust approach in Java -- but our principles consider Singleton an anti-pattern.
**Maps to:** core-principles.md#interfaces-and-di
**When to cite:** When a developer creates a Singleton (eager or lazy). The correct agent response is: "Our principles prohibit the Singleton pattern. Singletons hide global state, block threads, create concurrency hazards, and make testing painful. Prefer constructor injection and let the DI container manage lifecycle. If you genuinely must enforce single-instance semantics without a DI container, Bloch recommends the single-element enum approach as the least-bad option." Always redirect toward DI first.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item3/enumtype/Elvis.java` (enum singleton), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item3/field/Elvis.java` (public field), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item3/staticfactory/Elvis.java` (static factory)

---

### Item 4: Enforce Noninstantiability with a Private Constructor

**Takeaway:** Utility classes (collections of static methods) should have a private constructor to prevent instantiation and subclassing.
**Maps to:** core-principles.md#intent-through-keywords, core-principles.md#simplicity
**When to cite:** When a developer writes a class containing only static methods but leaves the default constructor accessible, when someone instantiates or subclasses a utility class, or when reviewing helper/utility classes that lack a private constructor.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item4/UtilityClass.java`

---

### Item 5: Prefer Dependency Injection to Hardwiring Resources

**Takeaway:** Pass dependencies through the constructor rather than hardwiring them inside the class; this makes the class flexible, testable, and reusable.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#testing
**When to cite:** When a class creates its own dependencies internally (e.g., `new DatabaseConnection()` inside a service), when a developer uses the Singleton or static utility pattern for something that depends on external resources, when reviewing any class that would be difficult to test because its dependencies are hardwired, or when discussing how to structure constructor parameters. This is one of the most important items for our codebase philosophy.
**Source example:** No source example (Item 5 is prose-only in the source repository)

---

### Item 6: Avoid Creating Unnecessary Objects

**Takeaway:** Reuse immutable objects rather than creating functionally identical new instances on every invocation; be alert to autoboxing and accidental object creation.
**Maps to:** core-principles.md#simplicity, core-principles.md#shift-left
**When to cite:** When a developer creates `new String("literal")` instead of using the string literal, when `Boolean.valueOf()` should replace `new Boolean()`, when a regex `Pattern` is compiled repeatedly inside a loop instead of being cached as a static final field, when autoboxing creates wrapper objects in a tight loop (e.g., using `Long` instead of `long` in a sum), or when reviewing performance-sensitive code paths.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item6/RomanNumerals.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item6/Sum.java`

---

### Item 7: Eliminate Obsolete Object References

**Takeaway:** Nulling out references when objects are no longer needed prevents memory leaks, especially in classes that manage their own memory (stacks, caches, listeners).
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer implements a collection-like class (stack, pool, cache) that retains references to elements after they are logically removed, when reviewing code that registers listeners or callbacks without corresponding deregistration, when discussing `WeakHashMap` for cache implementations, or when investigating `OutOfMemoryError` in a long-running application.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item7/Stack.java`

---

### Item 8: Avoid Finalizers and Cleaners

**Takeaway:** Finalizers are deprecated and dangerous; cleaners are only marginally better. Neither should be used for resource management -- use `try-with-resources` instead.
**Maps to:** core-principles.md#simplicity, core-principles.md#shift-left
**When to cite:** When a developer overrides `finalize()`, when a developer uses `Cleaner` for routine resource management instead of `AutoCloseable` + `try-with-resources`, when reviewing code that relies on garbage collection to release native resources (file handles, sockets, database connections), or when someone argues that finalizers provide a "safety net."
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item8/Room.java` (Cleaner example), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item8/Adult.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item8/Teenager.java`

---

### Item 9: Prefer try-with-resources to try-finally

**Takeaway:** `try-with-resources` is shorter, clearer, and produces better diagnostics than `try-finally` for any object implementing `AutoCloseable`.
**Maps to:** core-principles.md#simplicity, core-principles.md#shift-left
**When to cite:** When a developer uses `try-finally` to close a resource, when reviewing code that manages multiple closeable resources (where `try-finally` nesting becomes deeply ugly), when a resource class does not implement `AutoCloseable` but should, or when discussing exception masking (where `try-finally` suppresses the original exception in favor of the close exception).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item9/trywithresources/TopLine.java` (correct), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item9/trywithresources/Copy.java` (correct), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item9/tryfinally/TopLine.java` (anti-pattern), `repos/effective-java-3e-source-code/src/effectivejava/chapter2/item9/tryfinally/Copy.java` (anti-pattern)
