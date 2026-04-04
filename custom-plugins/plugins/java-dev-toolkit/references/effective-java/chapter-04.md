# Chapter 4: Classes and Interfaces

Items 15-25. The core structural design decisions in Java: access control, mutability,
inheritance vs. composition, and interface design. This chapter is the most tightly
aligned with our core principles -- immutability, interface-driven design, and intent
through keywords are all grounded here.

---

### Item 15: Minimize the Accessibility of Classes and Members

**Takeaway:** Make every class and member as inaccessible as possible; well-designed components hide implementation details behind a clean API.
**Maps to:** core-principles.md#intent-through-keywords, core-principles.md#monolithic-deployment-modular-code
**When to cite:** When a class or field is `public` without justification, when a developer exposes internal implementation classes outside their package, when reviewing a Gradle multi-module project where module-internal classes leak into the public API, when a mutable field is not `private`, or when a class exposes an array field (arrays are always mutable -- return a defensive copy or unmodifiable list instead). This item underpins both the `private`-by-default keyword rule and the modular monolith architecture.
**Source example:** No source example (Item 15 is prose-only in the source repository)

---

### Item 16: In Public Classes, Use Accessor Methods, Not Public Fields

**Takeaway:** Expose fields through accessor methods in public classes to preserve encapsulation and the ability to change the internal representation later.
**Maps to:** core-principles.md#intent-through-keywords, core-principles.md#data-model-first
**When to cite:** When a public class has public mutable fields, when discussing the difference between public classes (accessors required) and package-private or private nested classes (direct field access acceptable), when reviewing DTOs that expose fields directly instead of using records (which provide accessors automatically), or when a developer argues that getters/setters are boilerplate. Note: Java `record` types solve this elegantly -- the fields are `private final` and the accessors are generated.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item16/Point.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item16/Time.java`

---

### Item 17: Minimize Mutability

**Takeaway:** Classes should be immutable unless there is a very good reason to make them mutable; immutable objects are simple, thread-safe, and can be shared freely.
**Maps to:** core-principles.md#immutability, core-principles.md#concurrency
**When to cite:** CRITICAL ITEM. Cite this whenever a developer: creates a class with non-final fields without justification, provides setters on a value object, uses a mutable class where a record would suffice, returns mutable internal state from a method (return defensive copies or unmodifiable views), designs a class that could be `final` but is not, or writes a class with mutable fields that will be shared across threads. This is the single most important Effective Java item for our codebase philosophy. The five rules: (1) no mutators, (2) class cannot be extended, (3) all fields final, (4) all fields private, (5) no access to mutable components.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item17/Complex.java`

---

### Item 18: Favor Composition Over Inheritance

**Takeaway:** Implementation inheritance (extending a concrete class) is fragile; use composition and forwarding (the Decorator pattern) to safely reuse existing classes.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#simplicity
**When to cite:** When a developer extends a concrete class to add behavior (especially from the JDK or a third-party library), when reviewing a class hierarchy deeper than two levels, when a subclass breaks because the superclass changed its self-use patterns, when discussing the fragile base class problem, or when introducing the Forwarding pattern as the correct alternative. The `InstrumentedSet` example from the source code is the canonical illustration.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item18/InstrumentedHashSet.java` (broken inheritance), `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item18/ForwardingSet.java` (composition wrapper), `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item18/InstrumentedSet.java` (correct composition)

---

### Item 19: Design and Document for Inheritance or Else Prohibit It

**Takeaway:** If a class is designed for inheritance, document the self-use patterns of overridable methods; otherwise, make the class `final` or give it only `private`/package-private constructors.
**Maps to:** core-principles.md#intent-through-keywords, core-principles.md#simplicity
**When to cite:** When a class is neither `final` nor explicitly designed for extension, when a developer overrides a method without understanding the superclass's self-use contract, when reviewing a class that calls overridable methods from its constructor (which exposes the subclass to uninitialized state), or when enforcing our default-to-`final` philosophy. The agent should recommend making classes `final` unless inheritance is a deliberate, documented design decision.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item19/Super.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item19/Sub.java` (demonstrates constructor calling overridable method)

---

### Item 20: Prefer Interfaces to Abstract Classes

**Takeaway:** Interfaces allow mixins, non-hierarchical type frameworks, and safe composition via default methods; use skeletal implementation classes when shared code is needed.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#frameworks-last
**When to cite:** When a developer creates an abstract class where an interface would suffice, when discussing Java's single inheritance limitation and how interfaces work around it, when introducing the skeletal implementation pattern (`AbstractList`, `AbstractSet`, etc.), when a developer needs to provide shared implementation code (use a default method or a package-private skeletal implementation, not an abstract class that forces a single inheritance slot), or when reviewing code that cannot implement multiple behaviors because it already extends a class.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item20/AbstractMapEntry.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item20/IntArrays.java`

---

### Item 21: Design Interfaces for Posterity

**Takeaway:** Adding default methods to existing interfaces can break implementations; design interfaces carefully from the start because they are hard to change.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#data-model-first
**When to cite:** When a developer adds a default method to a widely-implemented interface, when discussing backward compatibility of interface changes, when reviewing a new interface design (encourage the developer to think about future evolution), or when a default method's behavior conflicts with an existing implementation's invariants. This item is a reminder that "prefer interfaces" (Item 20) comes with the responsibility to get the interface right.
**Source example:** No source example (Item 21 is prose-only in the source repository)

---

### Item 22: Use Interfaces Only to Define Types

**Takeaway:** Do not use interfaces to export constants (the constant interface anti-pattern); use utility classes or enums instead.
**Maps to:** core-principles.md#interfaces-and-di, core-principles.md#intent-through-keywords
**When to cite:** When a developer creates an interface containing only `static final` constants with no methods, when a class implements an interface solely to access its constants (polluting the class's type hierarchy), when reviewing code that uses `import static` as a cleaner alternative to constant interfaces, or when discussing the difference between type-defining interfaces and namespace-providing utility classes.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item22/constantinterface/PhysicalConstants.java` (anti-pattern), `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item22/constantutilityclass/PhysicalConstants.java` (correct approach)

---

### Item 23: Prefer Class Hierarchies to Tagged Classes

**Takeaway:** Tagged classes (a single class with a type field and switch statements) are verbose, error-prone, and memory-wasteful; replace them with a proper class hierarchy.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer writes a class with a "type" or "kind" enum field and uses switch/if statements to branch on it, when reviewing code where adding a new variant requires modifying existing switch statements (violation of the open-closed principle), when introducing sealed classes/interfaces (Java 17+) as the modern refinement of this pattern, or when discussing pattern matching with sealed types for exhaustive switch expressions.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item23/taggedclass/Figure.java` (anti-pattern), `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item23/hierarchy/Figure.java` (correct hierarchy), `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item23/hierarchy/Circle.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item23/hierarchy/Rectangle.java`

---

### Item 24: Favor Static Member Classes Over Nonstatic

**Takeaway:** If a member class does not need access to its enclosing instance, declare it `static` to avoid retaining a hidden reference to the outer class.
**Maps to:** core-principles.md#intent-through-keywords, core-principles.md#simplicity
**When to cite:** When a developer writes a nonstatic inner class that does not reference the enclosing instance (wasted memory, potential memory leak), when discussing the four kinds of nested classes (static member, nonstatic member, anonymous, local), when reviewing `Map.Entry` implementations (which should always be static), when a nonstatic inner class prevents garbage collection of the enclosing instance, or when an anonymous class should be replaced with a lambda (Item 42).
**Source example:** No source example (Item 24 is prose-only in the source repository)

---

### Item 25: Limit Source Files to a Single Top-Level Class

**Takeaway:** Never put multiple top-level classes or interfaces in a single source file; it creates compilation-order dependencies and confusing build failures.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer puts two or more top-level classes in the same `.java` file, when reviewing a file that defines both a class and a "helper" class at the top level, or when discussing static member classes as the correct way to co-locate related classes in the same file.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item25/Dessert.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter4/item25/Test.java`
