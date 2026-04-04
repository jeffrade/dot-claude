# Chapter 5: Generics

Items 26-33. Type safety at compile time. Generics are one of Java's most powerful
tools for the shift-left principle: every cast eliminated is a `ClassCastException`
that can never reach production. Our core principles mandate zero raw types and
aggressive use of bounded wildcards.

---

### Item 26: Don't Use Raw Types

**Takeaway:** Raw types exist only for backward compatibility with pre-generics code; using them forfeits all type-safety benefits of generics and defers errors to runtime.
**Maps to:** core-principles.md#generics, core-principles.md#shift-left
**When to cite:** When a developer uses `List` instead of `List<String>`, when a developer uses `Collection` instead of `Collection<?>` for an unknown element type, when reviewing code that contains `@SuppressWarnings("unchecked")` caused by raw type usage, when a developer argues "I don't know the type so I'll use the raw type" (use unbounded wildcard `<?>` instead), or when discussing the difference between `List`, `List<Object>`, and `List<?>`. Raw types are a non-negotiable violation in our codebase.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item26/Raw.java`

---

### Item 27: Eliminate Unchecked Warnings

**Takeaway:** Every unchecked warning represents a potential `ClassCastException` at runtime; eliminate the warning or, if you can prove the code is type-safe, suppress it with `@SuppressWarnings("unchecked")` at the narrowest possible scope with a comment explaining why.
**Maps to:** core-principles.md#generics, core-principles.md#shift-left
**When to cite:** When a developer ignores unchecked compilation warnings, when `@SuppressWarnings("unchecked")` is applied at class or method level instead of at the narrowest statement level, when a suppression lacks a comment proving type safety, when a developer uses a raw type to "get rid of" the warning instead of fixing the generic signature, or when reviewing any code that mixes generics with arrays (which inherently produces unchecked warnings).
**Source example:** No source example (Item 27 is prose-only in the source repository)

---

### Item 28: Prefer Lists to Arrays

**Takeaway:** Arrays are covariant and reified, generics are invariant and erased; mixing them produces confusing errors. Prefer `List<T>` over `T[]` for type-safe collections.
**Maps to:** core-principles.md#generics, core-principles.md#shift-left
**When to cite:** When a developer creates a generic array (`new T[]` or `new List<String>[]`, which are illegal), when discussing why `Object[]` can hold a `String[]` reference but `List<Object>` cannot hold a `List<String>` reference, when a developer uses arrays in a generic class and encounters unchecked warnings, when reviewing a `Chooser` or similar pattern that benefits from lists over arrays, or when discussing the tradeoff (arrays give slightly better runtime performance; lists give compile-time type safety).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item28/Chooser.java`

---

### Item 29: Favor Generic Types

**Takeaway:** When writing a class that operates on objects, make it generic rather than using `Object` and forcing clients to cast; the `Stack<E>` example demonstrates how.
**Maps to:** core-principles.md#generics, core-principles.md#shift-left
**When to cite:** When a developer writes a class that stores `Object` references and requires clients to cast, when converting an existing non-generic class to a generic class, when discussing the two techniques for generic arrays (casting `Object[]` to `E[]` vs. casting individual elements), or when a developer creates a collection-like class without type parameters.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item29/technqiue1/Stack.java` (cast array), `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item29/technqiue2/Stack.java` (cast elements)

---

### Item 30: Favor Generic Methods

**Takeaway:** Generic methods (like `Collections.sort`) are type-safe and don't require clients to cast; the type parameter can often be inferred by the compiler.
**Maps to:** core-principles.md#generics, core-principles.md#simplicity
**When to cite:** When a developer writes a static utility method that accepts `Object` parameters and returns `Object`, when discussing type inference with diamond operator and generic methods, when introducing the generic singleton factory pattern (for immutable function objects), when demonstrating recursive type bounds (`<E extends Comparable<E>>`), or when reviewing utility methods that operate on collections without type safety.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item30/Union.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item30/GenericSingletonFactory.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item30/RecursiveTypeBound.java`

---

### Item 31: Use Bounded Wildcards to Increase API Flexibility

**Takeaway:** Use `<? extends T>` for producers and `<? super T>` for consumers (PECS: Producer Extends, Consumer Super) to make APIs more flexible without sacrificing type safety.
**Maps to:** core-principles.md#generics
**When to cite:** When a generic method is less flexible than it could be because it uses a simple type parameter where a wildcard would work, when a developer writes `Iterable<T>` as a parameter type where `Iterable<? extends T>` would accept subtypes, when discussing the `Comparable<? super T>` pattern (allowing comparison against supertypes), when a developer writes a method that both produces and consumes a type parameter (use a helper method to capture the wildcard), or when reviewing APIs that will be used by third-party code (wildcards make the API easier to use correctly).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item31/Stack.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item31/Union.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item31/Chooser.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item31/Swap.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item31/RecursiveTypeBound.java`

---

### Item 32: Combine Generics and Varargs Judiciously

**Takeaway:** Generic varargs parameters are unsafe because they expose a generic array to the caller; use `@SafeVarargs` only when the method truly does not store into or expose the varargs array.
**Maps to:** core-principles.md#generics, core-principles.md#shift-left
**When to cite:** When a developer writes a method with a generic varargs parameter and gets a heap pollution warning, when deciding whether `@SafeVarargs` is appropriate (the method must not store into the array and must not expose it to untrusted code), when discussing the safer alternative of passing a `List` instead of varargs, when reviewing a method that returns its varargs array (always unsafe), or when distinguishing the rules for using `@SafeVarargs` (only on `static`, `final`, or `private` methods).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item32/Dangerous.java` (heap pollution), `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item32/FlattenWithVarargs.java` (safe usage with @SafeVarargs), `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item32/FlattenWithList.java` (list alternative), `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item32/PickTwo.java` (unsafe), `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item32/SafePickTwo.java` (safe)

---

### Item 33: Consider Typesafe Heterogeneous Containers

**Takeaway:** Use `Class<T>` as a key to build type-safe containers that can hold values of many different types without casting, as in the `Favorites` pattern.
**Maps to:** core-principles.md#generics, core-principles.md#shift-left
**When to cite:** When a developer needs a container that maps different types to different values (e.g., a configuration registry, a context object, or a service locator), when discussing `Class<T>` as a type token, when a developer resorts to `Map<String, Object>` with casting (this is the type-unsafe version of what Item 33 solves), when reviewing annotation processing code that uses `Class<? extends Annotation>`, or when discussing bounded type tokens and `asSubclass()`.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item33/Favorites.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter5/item33/PrintAnnotation.java`
