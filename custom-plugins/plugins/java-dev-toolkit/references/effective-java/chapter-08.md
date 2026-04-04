# Chapter 8: Methods

Items 49-56. How to design methods that are usable, robust, and flexible. Parameter
validation, defensive copying, method signatures, overloading, varargs, return types,
and documentation. These items connect directly to our shift-left, immutability, and
simplicity principles.

---

### Item 49: Check Parameters for Validity

**Takeaway:** Validate method parameters at entry points and fail fast with clear exceptions; the earlier you catch an invalid argument, the easier it is to diagnose.
**Maps to:** core-principles.md#shift-left, core-principles.md#testing
**When to cite:** When a method accepts parameters without validation (especially public and protected methods), when a developer throws a generic `RuntimeException` instead of `IllegalArgumentException`, `NullPointerException`, or `IndexOutOfBoundsException`, when discussing `Objects.requireNonNull()` as the standard null check, when a private method should use assertions instead of explicit checks, when reviewing constructors that do not validate their arguments, or when a developer argues that "the caller should just pass valid arguments" (defensive programming catches bugs at the source).
**Source example:** No source example (Item 49 is prose-only in the source repository)

---

### Item 50: Make Defensive Copies When Needed

**Takeaway:** When accepting or returning mutable objects, make defensive copies to protect the class's invariants; assume that clients will try to violate them.
**Maps to:** core-principles.md#immutability, core-principles.md#shift-left
**When to cite:** When a class stores a mutable parameter (like `Date`, `int[]`, or a mutable collection) without copying it, when a getter returns a reference to internal mutable state, when reviewing a `Period` or `DateRange` class that accepts `Date` objects (the classic example -- callers can mutate the dates after construction), when discussing the order of operations (copy first, then validate the copy -- never validate the original), when a developer argues that "no one would mutate my parameters" (security-sensitive code must assume adversarial callers), or when recommending immutable alternatives (`Instant` instead of `Date`, `List.of()` instead of `ArrayList`).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item50/Period.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item50/Attacks.java` (demonstrates the vulnerability)

---

### Item 51: Design Method Signatures Carefully

**Takeaway:** Choose method names carefully, avoid long parameter lists, prefer interfaces over classes for parameter types, and prefer two-element enums over boolean parameters.
**Maps to:** core-principles.md#simplicity, core-principles.md#interfaces-and-di
**When to cite:** When a method has more than three consecutive parameters of the same type (easy to transpose them), when a developer uses `boolean` flags to switch behavior (use an enum instead), when a method parameter type is a concrete class instead of an interface (`Map` instead of `HashMap`), when discussing techniques to shorten parameter lists (helper classes for parameter groups, Builder pattern, method decomposition), or when reviewing method names that do not follow Java conventions (`getValue` vs. `value`, `setSize` vs. `resize`).
**Source example:** No source example (Item 51 is prose-only in the source repository)

---

### Item 52: Use Overloading Judiciously

**Takeaway:** Overloaded methods are resolved at compile time based on the static type of the arguments, which leads to counterintuitive behavior; prefer distinct method names when the behavior differs.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer writes overloaded methods where the "wrong" overload could be selected based on the static type, when discussing the `CollectionClassifier` bug (where `classify(Set)`, `classify(List)`, `classify(Collection)` always dispatches to the `Collection` overload), when overloads have different behavior for the same runtime arguments, when reviewing `remove(int)` vs. `remove(Object)` in `List` (a confusing overload in the JDK itself), when a developer overloads a method with the same number of parameters where the types are not radically different, or when recommending descriptive method names (`writeInt`, `writeLong`) instead of overloading.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item52/CollectionClassifier.java` (broken), `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item52/FixedCollectionClassifier.java` (fixed), `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item52/Overriding.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item52/SetList.java` (List.remove ambiguity)

---

### Item 53: Use Varargs Judiciously

**Takeaway:** Varargs are great for methods that genuinely need a variable number of arguments, but be aware of the performance cost (array allocation on every call) and the API design implications.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer creates a varargs method that requires at least one argument (use the pattern `method(int first, int... rest)` to enforce at compile time), when varargs are used in a performance-sensitive method called millions of times (consider overloads for common arities), when reviewing `printf`-style formatting methods, or when a method accepts varargs but should actually take a `List` or `Set` parameter for type safety.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item53/Varargs.java`

---

### Item 54: Return Empty Collections or Arrays, Not Nulls

**Takeaway:** Never return `null` in place of an empty collection or array; return `Collections.emptyList()`, `List.of()`, or a zero-length array instead.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a method returns `null` to indicate "no results," when calling code has `if (result != null)` checks that would be unnecessary with empty collections, when discussing `Collections.emptyList()`, `Collections.emptySet()`, `Collections.emptyMap()` as shared immutable singletons (no allocation cost), when reviewing code that allocates a new empty array or list on every call (cache the empty array as a static constant), or when a developer argues that null is more efficient (it is not, and even if it were, premature optimization does not justify API pollution).
**Source example:** No source example (Item 54 is prose-only in the source repository)

---

### Item 55: Return Optionals Judiciously

**Takeaway:** Use `Optional<T>` as a return type for methods that might not have a value to return; never use `Optional` as a field, parameter, map key, or collection element.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a method returns `null` to indicate absence of a value (return `Optional.empty()` instead), when a developer uses `Optional` as a field or method parameter (anti-pattern -- optionals are not serializable and add overhead), when reviewing `optional.get()` without `isPresent()` (use `orElse()`, `orElseGet()`, `orElseThrow()`, `map()`, `flatMap()`, or `stream()` instead), when a developer wraps a collection in an `Optional` (return an empty collection per Item 54), when discussing primitive optional types (`OptionalInt`, `OptionalLong`, `OptionalDouble`), or when reviewing code that chains `.isPresent()` + `.get()` instead of using `map`/`flatMap`.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item55/Max.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item55/ParentPid.java`

---

### Item 56: Write Doc Comments for All Exposed API Elements

**Takeaway:** Every exported class, interface, constructor, method, and field should have a Javadoc comment that describes its contract; the method doc should cover preconditions, postconditions, side effects, and thread safety.
**Maps to:** core-principles.md#simplicity, core-principles.md#intent-through-keywords
**When to cite:** When a public API element lacks a Javadoc comment, when a method doc does not describe what happens when preconditions are violated (which exceptions are thrown), when `@param`, `@return`, and `@throws` tags are missing or incomplete, when discussing the `{@code}`, `{@literal}`, `{@index}`, and `{@implSpec}` tags, when reviewing an interface or abstract class whose documentation does not describe the contract implementations must satisfy, when `@throws` documentation uses `if` clauses (the standard convention), or when discussing self-use documentation for overridable methods (per Item 19).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter8/item56/DocExamples.java`
