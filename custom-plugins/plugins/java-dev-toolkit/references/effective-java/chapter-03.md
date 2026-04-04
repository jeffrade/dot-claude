# Chapter 3: Methods Common to All Objects

Items 10-14. The `Object` contract: `equals`, `hashCode`, `toString`, `clone`, and
`Comparable`. Getting these methods wrong produces subtle, hard-to-diagnose bugs.
Getting them right is foundational to correct Java programming.

---

### Item 10: Obey the General Contract When Overriding equals

**Takeaway:** Override `equals` only when logical equality matters, and when you do, satisfy all five properties: reflexive, symmetric, transitive, consistent, and non-null.
**Maps to:** core-principles.md#shift-left, core-principles.md#data-model-first
**When to cite:** When a developer overrides `equals` without satisfying the full contract (especially symmetry or transitivity), when a subclass extends a concrete class and adds a value component (which breaks the Liskov substitution property of `equals`), when `equals` is overridden but `hashCode` is not (always cite Item 11 alongside), when a class uses `==` where `.equals()` is needed for value comparison, or when reviewing a `record` type (records auto-generate correct `equals`).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item10/PhoneNumber.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item10/CaseInsensitiveString.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item10/Point.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item10/inheritance/ColorPoint.java` (broken equality), `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item10/composition/ColorPoint.java` (composition fix)

---

### Item 11: Always Override hashCode When You Override equals

**Takeaway:** If two objects are equal according to `equals`, they must return the same `hashCode`; violating this contract breaks hash-based collections.
**Maps to:** core-principles.md#shift-left, core-principles.md#data-model-first
**When to cite:** When a developer overrides `equals` without overriding `hashCode`, when reviewing any class used as a key in `HashMap` or element in `HashSet`, when a developer writes a custom `hashCode` that does not include all fields used in `equals`, when discussing performance of hash-based collections (poor hash functions cause bucket clustering), or when recommending `Objects.hash()` for convenience versus manual computation for performance.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item11/PhoneNumber.java`

---

### Item 12: Always Override toString

**Takeaway:** A good `toString` makes classes pleasant to use in logging, debugging, and error messages; it should return all interesting information contained in the object.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer relies on the default `Object.toString()` (which prints the class name and hash code), when reviewing log statements or exception messages that print objects, when discussing whether `toString` should specify a format (yes for value classes, with a matching static factory or constructor to parse it), or when reviewing `record` types (records auto-generate `toString` but the format may not be ideal for all use cases).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item12/PhoneNumber.java`

---

### Item 13: Override clone Judiciously

**Takeaway:** `Cloneable` is broken by design; prefer copy constructors or copy factory methods for object copying.
**Maps to:** core-principles.md#simplicity, core-principles.md#immutability
**When to cite:** When a developer implements `Cloneable` or overrides `clone()`, when discussing deep vs. shallow copying, when a class with mutable fields needs a copy mechanism, or when reviewing code that calls `clone()` on arrays (the one place where `clone()` is acceptable). The agent should recommend copy constructors (`public Foo(Foo other)`) or static copy factories (`public static Foo copyOf(Foo other)`) as the default approach. For immutable objects, no copying mechanism is needed at all since they can be shared freely.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item13/PhoneNumber.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item13/Stack.java`

---

### Item 14: Consider Implementing Comparable

**Takeaway:** Implement `Comparable` for value classes that have a natural ordering; use `Comparator` construction methods (Java 8+) to build comparators cleanly.
**Maps to:** core-principles.md#shift-left, core-principles.md#data-model-first
**When to cite:** When a value class needs to be sorted or used in sorted collections (`TreeSet`, `TreeMap`), when a developer writes a hand-rolled comparator with manual subtraction (which risks overflow), when reviewing `compareTo` for consistency with `equals`, when introducing `Comparator.comparing()` and `thenComparing()` chain methods as the modern approach, or when a developer uses `Comparable<Object>` instead of the proper generic type bound.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item14/PhoneNumber.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter3/item14/WordList.java`
