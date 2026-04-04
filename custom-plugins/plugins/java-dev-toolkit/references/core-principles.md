# Core Principles

Non-negotiable engineering philosophy for all Java development. Every agent reads this
file on every invocation. These are not suggestions. They are the plugin's identity.

Blends the user's philosophy with Joshua Bloch's Effective Java (3rd Edition) into one
voice. Where both agree, stated once. Where the user is stronger, the user wins.

---

## Immutability

Default to immutable. Every field, parameter, and local variable `final` unless
mutability is a deliberate, justified design decision.

- All fields, method parameters, and local variables `final` by default.
- Return unmodifiable collections (`List.of()`, `Map.of()`, defensive copies).
- Use `record` types for value objects. Records are immutable by default.
- Mutable state confined to the narrowest scope; documented with justification.

Immutable objects are thread-safe, shareable, and cacheable (Item 17). Mutable shared
state is the root cause of most concurrency bugs. Eliminate it by default.

**Effective Java:** Item 17 (Minimize mutability), Item 15 (Minimize accessibility).

---

## Shift-Left

Errors surface as early as possible: compile-time > unit test > integration test > runtime.

- `final`, `private`, `static`, `sealed` give the compiler maximum information.
- Strong types over `String`/`int` for domain concepts. `CustomerId` catches misuse at
  compile time; `String` does not.
- Generics eliminate runtime `ClassCastException`. Enums replace string constants.
- Validate parameters at entry points (Item 49). Fail fast.
- Prefer type-level constraints over runtime validation wherever possible.

The compiler is the cheapest, fastest reviewer on the team. A compile error costs
seconds; a production bug costs hours, money, and trust.

**Effective Java:** Item 49, Item 52, Item 61.

---

## Interfaces and Dependency Injection

Program to interfaces. Constructor injection exclusively.

- Define behavior as interfaces. Classes implement interfaces.
- Constructor injection only. No field injection, no setter injection.
- No Singleton pattern. Ever. Singletons hide global state, block threads, create
  concurrency hazards, and make testing painful. Let the DI container manage lifecycle.
- No Abstract Factory when a simple interface + DI solves the problem.
- Interfaces enable testing: inject a test implementation, no mocking needed.

Constructor injection makes dependencies explicit, testable, and impossible to forget.
Interface-based design decouples modules. The combination is modular by construction.

**Effective Java:** Item 64, Item 18, Item 20.

---

## Data-Model First

Define the data model before writing business logic. Code follows from the model.

- POJOs (or records) for all DTOs and DAOs, defined before logic.
- Data model drives API design, validation, persistence, and test fixtures.
- Name after the domain concept: `Order`, not `OrderBean`.
- Data classes hold state; service classes hold behavior.
- If the code is not obvious, the data model is probably wrong.

The data model is the contract between layers, modules, and teams. Getting it right
first prevents ripple-effect rewrites.

---

## Frameworks Last

Libraries serve the codebase; the codebase does not serve libraries.

- No Hibernate when inline SQL works. Statically defined inline SQL is fine.
- No Spring when plain Java suffices. Manual wiring in `main()` is fine.
- Evaluate every dependency: what does it give me that I cannot write in fewer
  lines with fewer risks?
- Wrap adopted frameworks behind interfaces so they can be replaced.
- Prefer standard APIs (Jakarta EE, JDBC, java.net.http) over proprietary ones.

Frameworks impose constraints, transitive dependencies, upgrade cycles, and learning
curves. Frameworks last means logic first.

**Effective Java:** Item 59 (Know and use the libraries).

---

## Simplicity Over Cleverness

Dumb maintainable code over clever code. Three similar lines beat a premature
abstraction. YAGNI ruthlessly.

- Do not abstract until three concrete uses prove the abstraction correct.
- Do not introduce a design pattern because it exists; introduce it because
  the code demands it.
- Flat control flow over nested abstractions. Top-to-bottom readability.
- Avoid Builder chains, deep inheritance, and factory-of-factory patterns
  unless genuinely warranted.
- Delete speculative code. Version control remembers everything.

Java's ecosystem has a cultural bias toward overengineering. Simple code is readable,
debuggable, and changeable. Clever code is a maintenance liability.

**Effective Java:** Item 67 in spirit: do not optimize for reuse until need is proven.

---

## Generics for Reuse

Use generics aggressively for type-safe, modular, reusable components.

- No raw types. Ever. They exist only for pre-Java-5 backward compatibility.
- Bounded type parameters (`<T extends Comparable<T>>`) to express constraints.
- Wildcards (PECS: `<? extends T>`, `<? super T>`) for flexible method parameters.
- Prefer generic methods over generic classes for single-method type parameters.
- `@SuppressWarnings("unchecked")` only with a proof-of-safety comment.

Generics shift type checking to compile time, eliminate casts, prevent
`ClassCastException`, and make APIs self-documenting.

**Effective Java:** Items 26-33.

---

## Concurrency

Java 21+ virtual threads preferred. Immutability is the primary concurrency defense.

- Virtual threads (`Thread.ofVirtual()`, `Executors.newVirtualThreadPerTaskExecutor()`)
  for I/O-bound work. Lightweight, no pool sizing complexity.
- No platform threads for I/O concurrency without a measured performance reason.
- Immutable objects require no synchronization (see Immutability).
- When mutable shared state is unavoidable, use `java.util.concurrent` utilities
  over manual synchronization.
- Never swallow `InterruptedException`. Restore the flag or propagate.

Traditional thread pools and synchronized blocks are over-engineered for most I/O-bound
use cases. Virtual threads simplify the common case dramatically.

**Effective Java:** Items 78-84.

---

## Annotations and Reflection

Annotations express intent. Reflection is restricted to one use case.

- Annotations: `@Override`, `@Nullable`, `@Immutable`, `@FunctionalInterface`, custom
  domain-specific metadata.
- Reflection ONLY for loading class names from root-level config files (e.g., loading
  a `DataSource` implementation from `application.yaml`).
- No runtime reflection for DI, serialization hacking, private field access, or
  dynamic proxies in application code.
- Frameworks that use reflection internally (Jackson, JUnit) are acceptable.

Reflection bypasses compile-time safety. Every reflective call is a potential runtime
exception. The single permitted use case is narrow and auditable.

**Effective Java:** Item 65 (Prefer interfaces to reflection).

---

## Testing

Unit + integration + contract tests. JUnit 5. Mockito only at boundaries.

- JUnit 5 exclusively. No JUnit 4, no TestNG.
- Test behavior, not implementation.
- Real implementations for internal dependencies. If `OrderService` needs
  `OrderRepository`, use a real in-memory repository.
- Mockito for external boundaries only: HTTP clients, third-party APIs, databases
  you cannot run locally. Mock the boundary, not your own code.
- Contract tests verify module interfaces behave as promised.
- Naming: `methodName_condition_expectedResult` or descriptive `@DisplayName`.
- `assertThat` (AssertJ/Hamcrest) for readable assertions.
- Behavioral coverage over line coverage.

Tests that mock everything test nothing. Tests that use real dependencies catch real
bugs. Mockito at boundaries keeps tests fast while keeping them honest.

**Effective Java:** Aligns with Item 49 and the shift-left principle.

---

## Intent Through Keywords

Java keywords are compiler-enforced documentation. Use them deliberately.

- `final`: every field, parameter, and local variable that does not change.
- `private`: default access modifier. Widen only for a concrete use case.
- `static`: utility methods and constants without instance state.
- `sealed`: fixed set of known subtypes.
- `record`: immutable value objects.
- `var`: local variables only when the type is obvious from context.

`final` says "will not change." `private` says "implementation detail." `sealed` says
"only these subtypes." The compiler enforces these promises. Comments can lie; keywords cannot.

**Effective Java:** Item 15, Item 17.

---

## Monolithic Deployment, Modular Code

Monolithic deployment is fine. Monolithic coupling is the anti-pattern.

- Gradle multi-project builds enforce module boundaries at build time.
- Each module declares dependencies explicitly in `build.gradle`.
- Modules communicate through interfaces in shared API modules.
- No reaching into another module's internals. If Gradle does not expose it,
  you cannot use it.
- Package layout reflects modules: `com.example.orders.api`,
  `com.example.orders.internal`.
- Premature microservices is its own anti-pattern. Split only when operational
  needs (scaling, deployment, team autonomy) demand it.

Gradle-enforced boundaries are as real as network boundaries, with zero operational
overhead. A modularized monolith can split later. A coupled one cannot.

**Effective Java:** Item 15 at the module level: expose only what consumers need.

---

## Summary

| Principle | One-Line Rule |
|-----------|--------------|
| Immutability | `final` everything; mutable state requires justification |
| Shift-Left | Compile-time > test-time > runtime |
| Interfaces + DI | Constructor injection, program to interfaces, no Singleton |
| Data-Model First | Define POJOs/records before writing logic |
| Frameworks Last | No framework without proven value; inline SQL is fine |
| Simplicity | Dumb code over clever code; YAGNI ruthlessly |
| Generics | No raw types; type-safe reuse |
| Concurrency | Virtual threads + immutability |
| Annotations/Reflection | Annotations for intent; reflection only for config-driven class loading |
| Testing | JUnit 5, real dependencies, Mockito only at boundaries |
| Intent Through Keywords | `final`, `private`, `static`, `sealed` express design intent |
| Modular Monolith | Gradle multi-project enforces boundaries; deploy as one unit |
