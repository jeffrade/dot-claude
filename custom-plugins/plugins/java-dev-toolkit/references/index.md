# Index — Keyword to Reference Lookup

Keyword-to-file lookup table. Agents use this for O(1) reference resolution.
Multiple keywords point to the same content so any reasonable search term works.

---

## Core Principles

- **Immutability** → core-principles.md#immutability, effective-java/chapter-04.md (Item 17), anti-patterns.md#mutable-shared-state
- **Final keyword** → core-principles.md#immutability, core-principles.md#intent-through-keywords
- **Mutable state** → core-principles.md#immutability, anti-patterns.md#mutable-shared-state, effective-java/chapter-11.md (Item 78)
- **Shift-Left** → core-principles.md#shift-left, effective-java/chapter-08.md (Item 49)
- **Compile-time safety** → core-principles.md#shift-left, core-principles.md#generics-for-reuse
- **Strong types** → core-principles.md#shift-left, core-principles.md#generics-for-reuse
- **Interfaces** → core-principles.md#interfaces-and-dependency-injection, effective-java/chapter-04.md (Items 20, 64)
- **DI** / **Dependency Injection** / **Constructor Injection** → core-principles.md#interfaces-and-dependency-injection, architecture-guide.md#interface-contract-design
- **Data model** → core-principles.md#data-model-first, architecture-guide.md#data-model-design
- **POJO** / **DTO** / **DAO** → core-principles.md#data-model-first, implementation-guide.md#pojo-conventions
- **Record types** → core-principles.md#immutability, core-principles.md#intent-through-keywords, implementation-guide.md#pojo-conventions
- **Frameworks Last** → core-principles.md#frameworks-last, anti-patterns.md#hibernateorm-bloat
- **Inline SQL** / **SQL conventions** → core-principles.md#frameworks-last, implementation-guide.md#inline-sql-conventions
- **Simplicity** → core-principles.md#simplicity-over-cleverness, anti-patterns.md#clever-code--premature-abstraction
- **YAGNI** → core-principles.md#simplicity-over-cleverness, anti-patterns.md#boat-anchor, anti-patterns.md#overengineering
- **Generics** → core-principles.md#generics-for-reuse, effective-java/chapter-05.md (Items 26-33), implementation-guide.md#generics-patterns
- **PECS** / **Wildcards** → core-principles.md#generics-for-reuse, effective-java/chapter-05.md (Item 31)
- **Concurrency** → core-principles.md#concurrency, effective-java/chapter-11.md (Items 78-84)
- **Virtual Threads** → core-principles.md#concurrency, implementation-guide.md#virtual-thread-patterns
- **Thread safety** → core-principles.md#concurrency, core-principles.md#immutability, effective-java/chapter-11.md (Item 78)
- **Annotations** → core-principles.md#annotations-and-reflection, effective-java/chapter-06.md (Item 39)
- **Reflection** → core-principles.md#annotations-and-reflection, effective-java/chapter-09.md (Item 65)
- **Testing** → core-principles.md#testing, testing-guide.md
- **JUnit 5** → core-principles.md#testing, testing-guide.md#junit-5-conventions
- **Mockito** → core-principles.md#testing, testing-guide.md#when-to-mock-mockito
- **Contract tests** → core-principles.md#testing, testing-guide.md#contract-test-design
- **Integration tests** → core-principles.md#testing, testing-guide.md#integration-test-strategy
- **Intent Through Keywords** / **Access modifiers** → core-principles.md#intent-through-keywords, effective-java/chapter-04.md (Item 15)
- **Sealed classes** → core-principles.md#intent-through-keywords
- **Modular monolith** / **Module boundaries** → core-principles.md#monolithic-deployment-modular-code, architecture-guide.md#module-boundaries
- **Gradle** / **Build config** → core-principles.md#monolithic-deployment-modular-code, architecture-guide.md#build-configuration
- **Package layout** → core-principles.md#monolithic-deployment-modular-code, architecture-guide.md#package-layout

---

## Anti-Patterns

- **Singleton** / **Singleton pattern** → anti-patterns.md#singleton-pattern, core-principles.md#interfaces-and-dependency-injection, effective-java/chapter-02.md (Item 3)
- **Abstract Factory** / **Abstract Factory overuse** → anti-patterns.md#abstract-factory-overuse, core-principles.md#simplicity-over-cleverness
- **Hibernate bloat** / **ORM** → anti-patterns.md#hibernateorm-bloat, core-principles.md#frameworks-last
- **Clever code** / **Premature abstraction** → anti-patterns.md#clever-code--premature-abstraction, core-principles.md#simplicity-over-cleverness
- **Mutable shared state** → anti-patterns.md#mutable-shared-state, core-principles.md#immutability, effective-java/chapter-04.md (Item 17)
- **Raw types** → anti-patterns.md#raw-types, core-principles.md#generics-for-reuse, effective-java/chapter-05.md (Items 26-27)
- **Checked exception abuse** → anti-patterns.md#checked-exception-abuse, effective-java/chapter-10.md (Item 71)
- **Finalizer** / **Cleaner** → anti-patterns.md#finalizercleaner-reliance, effective-java/chapter-02.md (Item 8)
- **Inheritance over composition** → anti-patterns.md#inheritance-over-composition, effective-java/chapter-04.md (Item 18)
- **God Object** → anti-patterns.md#god-object, review-checklist.md#god-object-5-unrelated-responsibilities
- **Spaghetti Code** → anti-patterns.md#spaghetti-code
- **Copy-Paste Programming** → anti-patterns.md#copy-paste-programming
- **Magic Numbers** / **Magic Strings** → anti-patterns.md#magic-numbersstrings, implementation-guide.md#constants-best-practices
- **Hard Coding** → anti-patterns.md#hard-coding
- **Premature Optimization** → anti-patterns.md#premature-optimization, effective-java/chapter-09.md (Item 67)
- **Dead Code** / **Lava Flow** → anti-patterns.md#dead-code--lava-flow
- **Boat Anchor** → anti-patterns.md#boat-anchor, core-principles.md#simplicity-over-cleverness
- **Excessive Static** → anti-patterns.md#excessive-static
- **Null Abuse** → anti-patterns.md#null-abuse, effective-java/chapter-08.md (Item 55)
- **Overengineering** → anti-patterns.md#overengineering, core-principles.md#simplicity-over-cleverness
- **Golden Hammer** → anti-patterns.md#golden-hammer
- **Constants class** → anti-patterns.md#large-global-constants-class, implementation-guide.md#constants-best-practices
- **Constant Interface** → anti-patterns.md#constant-interface-anti-pattern, effective-java/chapter-04.md (Item 22)
- **Monolithic Coupling** → anti-patterns.md#monolithic-coupling, core-principles.md#monolithic-deployment-modular-code
- **Vendor Lock-In** → anti-patterns.md#vendor-lock-in, core-principles.md#frameworks-last

---

## Effective Java Quick Reference

- **Static factories** → effective-java/chapter-02.md (Item 1)
- **Builders** → effective-java/chapter-02.md (Item 2)
- **Singleton enforcement** → effective-java/chapter-02.md (Item 3), anti-patterns.md#singleton-pattern
- **Avoid finalizers** → effective-java/chapter-02.md (Item 8), anti-patterns.md#finalizercleaner-reliance
- **try-with-resources** → effective-java/chapter-02.md (Item 9)
- **equals / hashCode / toString / Comparable** → effective-java/chapter-03.md (Items 10-14)
- **Minimize accessibility** → effective-java/chapter-04.md (Item 15), core-principles.md#intent-through-keywords
- **Minimize mutability** → effective-java/chapter-04.md (Item 17), core-principles.md#immutability
- **Composition over inheritance** → effective-java/chapter-04.md (Item 18), anti-patterns.md#inheritance-over-composition
- **Design for inheritance or prohibit it** → effective-java/chapter-04.md (Item 19)
- **Interfaces over abstract classes** → effective-java/chapter-04.md (Item 20)
- **No raw types** / **Bounded wildcards** → effective-java/chapter-05.md (Items 26, 31)
- **Type-safe heterogeneous containers** → effective-java/chapter-05.md (Item 33)
- **Enums over int constants** → effective-java/chapter-06.md (Item 34)
- **Annotations over naming patterns** → effective-java/chapter-06.md (Item 39)
- **Lambdas** / **Streams** → effective-java/chapter-07.md (Items 42, 45)
- **Parameter validation** → effective-java/chapter-08.md (Item 49), core-principles.md#shift-left
- **Defensive copies** → effective-java/chapter-08.md (Item 50)
- **Return optionals judiciously** → effective-java/chapter-08.md (Item 55), anti-patterns.md#null-abuse
- **Know the libraries** → effective-java/chapter-09.md (Item 59), core-principles.md#frameworks-last
- **Prefer interfaces to reflection** → effective-java/chapter-09.md (Item 65)
- **Optimize judiciously** → effective-java/chapter-09.md (Item 67), anti-patterns.md#premature-optimization
- **Exceptions for exceptional conditions** → effective-java/chapter-10.md (Item 69)
- **Checked exceptions** / **Standard exceptions** → effective-java/chapter-10.md (Items 71-72)
- **Synchronize shared mutable data** → effective-java/chapter-11.md (Item 78), core-principles.md#concurrency
- **Prefer executors and tasks** / **Concurrency utilities** → effective-java/chapter-11.md (Items 80-81)

---

## Implementation Concepts

- **Constants** / **Enums** → implementation-guide.md#constants-best-practices, effective-java/chapter-06.md (Item 34), anti-patterns.md#magic-numbersstrings
- **Generics patterns** → implementation-guide.md#generics-patterns, core-principles.md#generics-for-reuse
- **SQL** → implementation-guide.md#inline-sql-conventions, core-principles.md#frameworks-last
- **POJO conventions** → implementation-guide.md#pojo-conventions, core-principles.md#data-model-first
- **Virtual thread patterns** → implementation-guide.md#virtual-thread-patterns, core-principles.md#concurrency
- **Annotation usage** / **Reflection rules** → implementation-guide.md#annotation-usage, core-principles.md#annotations-and-reflection

---

## Architecture Concepts

- **Data model design** → architecture-guide.md#data-model-design, core-principles.md#data-model-first
- **Interface contracts** → architecture-guide.md#interface-contract-design, core-principles.md#interfaces-and-dependency-injection
- **Dependency injection** → architecture-guide.md#interface-contract-design, core-principles.md#interfaces-and-dependency-injection
- **Dependency selection** → architecture-guide.md#dependency-selection-criteria, core-principles.md#frameworks-last
- **Monolith vs microservices** → core-principles.md#monolithic-deployment-modular-code, anti-patterns.md#monolithic-coupling

---

## Testing Concepts

- **JUnit 5 conventions** → testing-guide.md#junit-5-conventions, core-principles.md#testing
- **Mock boundaries** → testing-guide.md#when-to-mock-mockito, core-principles.md#testing
- **Contract test design** → testing-guide.md#contract-test-design, core-principles.md#testing
- **Integration test strategy** → testing-guide.md#integration-test-strategy, core-principles.md#testing
- **Test naming** / **Fixture patterns** → testing-guide.md#test-naming, testing-guide.md#test-fixtures
- **Behavioral coverage** → core-principles.md#testing, testing-guide.md
