# Anti-Patterns Catalog

Reference catalog for detecting and resolving anti-patterns in Java codebases.
Each entry includes identification criteria, consequences, and concrete fixes.
Severity levels: CRITICAL (block the review), WARNING (flag for fix), INFO (note for improvement).

---

## Singleton Pattern

**What it is:** A class that enforces a single instance via static state and private constructors, typically with a `getInstance()` method.

**Symptoms:**
- `private static` instance field with `public static getInstance()`.
- Double-checked locking or `synchronized` blocks around instance creation.
- Static `instance` field in production code (not in test utilities).
- Classes that are impossible to instantiate in tests without resetting static state.

**Why it's bad:** Singletons are hidden global state. They create tight coupling between every class that calls `getInstance()` and the Singleton itself. They block threads during initialization (synchronized access). They make unit testing painful because the static state persists across tests. They introduce concurrency hazards in multi-threaded environments. They violate the Dependency Injection principle because dependencies are pulled, not injected.

**What to do instead:** Define an interface for the behavior. Implement the interface in a normal class. Inject the instance via constructor injection. If you need exactly one instance, let the DI container or the application's `main()` manage the lifecycle. The result is testable, concurrent-safe, and explicit.

**Effective Java:** Item 3 covers singleton enforcement via enum, but our philosophy overrides: avoid the pattern entirely. Use DI.

**Severity:** CRITICAL

---

## Abstract Factory Overuse

**What it is:** Using the Abstract Factory pattern when a simple interface and DI would suffice.

**Symptoms:**
- Factory interfaces that produce only one type of object.
- Factory classes that are never swapped at runtime.
- `AbstractFooFactory`, `ConcreteFooFactory` pairs where `ConcreteFooFactory` is the only implementation.
- Factory hierarchies that mirror the class hierarchies they create.

**Why it's bad:** Abstract Factory adds an indirection layer without adding value when the use case is simple. It increases the number of classes, obscures control flow, and makes the codebase harder to navigate. The pattern is justified when object creation depends on a family of related types that vary together. It is not justified for single-type creation.

**What to do instead:** Define an interface for the object you need. Inject an instance of that interface via the constructor. If you need to create instances dynamically, inject a `Supplier<T>` or a simple factory method reference. Reserve Abstract Factory for genuine product-family variation.

**Effective Java:** N/A directly, but Item 64 (refer to objects by their interfaces) supports the simpler alternative.

**Severity:** WARNING

---

## Hibernate/ORM Bloat

**What it is:** Adopting Hibernate or another ORM when inline SQL would be simpler, clearer, and sufficient.

**Symptoms:**
- Hibernate entity mappings for simple CRUD operations.
- `@OneToMany`, `@ManyToMany` cascades that generate unexpected queries (N+1 problem).
- HQL or Criteria API queries that are harder to read than equivalent SQL.
- ORM-specific annotations dominating the data model classes.
- Debugging sessions that require understanding Hibernate's session cache, lazy loading, and flush behavior.

**Why it's bad:** ORMs impose a significant abstraction layer over SQL. For complex schemas, they generate unpredictable queries that are hard to optimize. They introduce framework-specific concepts (sessions, managed/detached entities, lazy proxies) that leak into business logic. They create vendor lock-in to the ORM itself. For most applications, the mapping complexity outweighs the boilerplate savings.

**What to do instead:** Use JDBC directly with statically defined inline SQL strings. Define SQL as `private static final String` constants in your repository classes. Use `PreparedStatement` for parameterized queries. Consider lightweight libraries like JDBI or jOOQ if you want some convenience without full ORM overhead. Evaluate the framework against the Frameworks Last principle: does it add value that justifies its cost?

**Effective Java:** N/A directly. Aligns with Item 59 (know and use the libraries) and the Frameworks Last principle.

**Severity:** WARNING

---

## Clever Code / Premature Abstraction

**What it is:** Code that prioritizes elegance, terseness, or design-pattern purity over readability and maintainability.

**Symptoms:**
- Methods that require extensive comments to explain their logic.
- Abstractions created before three concrete use cases exist.
- Design patterns applied because they exist, not because the code demands them.
- Builder chains spanning 10+ method calls.
- Deep inheritance hierarchies (more than 2 levels beyond `Object`).
- "Utility" classes full of static methods that each call one other method.
- Code that earns compliments from architects but confuses the next developer.

**Why it's bad:** Clever code is a maintenance liability. Every abstraction has a cost: indirection, learning curve, and future constraint. Premature abstractions are often wrong abstractions because they are based on insufficient evidence. Three similar lines of code that you can read top-to-bottom are better than a framework that requires understanding to modify.

**What to do instead:** Write the obvious, straightforward implementation first. Wait until you have three concrete uses before extracting an abstraction. Prefer flat control flow. If a method needs a paragraph of comments, rewrite the method, not the comments. Apply YAGNI ruthlessly.

**Effective Java:** Item 67 (Optimize judiciously) applies in spirit.

**Severity:** WARNING

---

## Mutable Shared State

**What it is:** Shared objects whose state can be modified by multiple threads or components without adequate synchronization or design justification.

**Symptoms:**
- Non-final fields in classes that are shared across threads.
- `public` or `protected` mutable fields.
- Collections returned from methods without defensive copying or wrapping in `Collections.unmodifiable*`.
- Setter methods on objects that are accessed from multiple contexts.
- `static` mutable fields (the most dangerous form).
- Concurrency bugs that appear intermittently under load.

**Why it's bad:** Mutable shared state is the root cause of race conditions, data corruption, and heisenbugs. These bugs are notoriously hard to reproduce, diagnose, and fix. Even with synchronization, the complexity and performance overhead are significant. Mutable shared state violates the Immutability principle and defeats the Shift-Left principle because these bugs cannot be caught at compile time.

**What to do instead:** Make the object immutable. Use `final` fields, return unmodifiable collections, use `record` types. If mutation is unavoidable, confine the mutable state to the narrowest possible scope and use `java.util.concurrent` utilities (ConcurrentHashMap, AtomicReference, etc.). Document why immutability is insufficient.

**Effective Java:** Item 17 (Minimize mutability), Item 78 (Synchronize access to shared mutable data).

**Severity:** CRITICAL

---

## Raw Types

**What it is:** Using generic types without type parameters (e.g., `List` instead of `List<String>`).

**Symptoms:**
- `List`, `Map`, `Set` without angle brackets in declarations or method signatures.
- `@SuppressWarnings("unchecked")` scattered throughout the code without justification comments.
- `ClassCastException` at runtime.
- Compiler warnings about unchecked or unsafe operations.

**Why it's bad:** Raw types bypass compile-time type checking. They defeat the Shift-Left principle by deferring type errors to runtime. They make APIs ambiguous: a `List` parameter tells the caller nothing about what it contains. They exist only for backward compatibility with pre-Java-5 code.

**What to do instead:** Always specify type parameters. Use `List<String>`, `Map<CustomerId, Order>`, etc. Use bounded wildcards (`<? extends T>`, `<? super T>`) for flexible method parameters. Use `@SuppressWarnings("unchecked")` only when you can prove type safety and always add a comment explaining the proof.

**Effective Java:** Item 26 (Don't use raw types), Item 27 (Eliminate unchecked warnings).

**Severity:** CRITICAL in public APIs (method signatures, return types, field types visible to other modules). WARNING in internal/private code.

---

## Checked Exception Abuse

**What it is:** Overusing checked exceptions for conditions that callers cannot meaningfully recover from.

**Symptoms:**
- Methods that declare `throws` clauses with 3+ checked exceptions.
- Catch blocks that log and re-throw, or log and swallow.
- Callers that catch checked exceptions only to wrap them in `RuntimeException`.
- Custom checked exceptions for infrastructure failures (database down, network timeout) that callers cannot fix.
- `throws Exception` as a catch-all declaration.

**Why it's bad:** Checked exceptions that callers cannot handle create boilerplate catch blocks that either swallow errors (hiding bugs) or wrap and re-throw (adding noise). They pollute method signatures up the call stack. They make APIs painful to use without adding safety.

**What to do instead:** Use checked exceptions only when the caller can take a meaningful recovery action (e.g., retry with different input, fall back to a default). For all other failures, use unchecked exceptions (subclass `RuntimeException`). Let unrecoverable failures propagate to a top-level handler. Prefer standard exceptions (`IllegalArgumentException`, `IllegalStateException`, `UnsupportedOperationException`).

**Effective Java:** Item 71 (Avoid unnecessary use of checked exceptions), Item 72 (Favor the use of standard exceptions), Item 70 (Use checked exceptions for recoverable conditions).

**Severity:** WARNING

---

## Finalizer/Cleaner Reliance

**What it is:** Using `finalize()` methods or `Cleaner` as the primary mechanism for resource cleanup.

**Symptoms:**
- Classes that override `Object.finalize()`.
- `Cleaner` registrations as the only cleanup path for native resources or file handles.
- Resources that leak when the GC does not run promptly.
- Performance degradation due to finalization overhead.

**Why it's bad:** Finalizers and cleaners have unpredictable timing. The JVM does not guarantee when (or if) they will run. They add GC overhead, create security vulnerabilities (finalizer attacks), and introduce subtle resource leak bugs. Since Java 9, `finalize()` is deprecated.

**What to do instead:** Implement `AutoCloseable` and use try-with-resources. This guarantees cleanup at a deterministic point. Use `Cleaner` only as a safety net (backstop) for cases where the client might forget to call `close()`, never as the primary cleanup mechanism.

**Effective Java:** Item 8 (Avoid finalizers and cleaners), Item 9 (Prefer try-with-resources to try-finally).

**Severity:** CRITICAL

---

## Inheritance Over Composition

**What it is:** Using class inheritance (extends) to reuse code when composition (has-a) would be safer and more flexible.

**Symptoms:**
- Deep class hierarchies (3+ levels).
- Subclasses that override methods only to add a small behavior tweak.
- `@Override` methods that call `super.method()` as their first or last line.
- Subclasses that depend on the implementation details of the parent (fragile base class problem).
- A change to the parent class breaks multiple subclasses unexpectedly.

**Why it's bad:** Inheritance exposes internal implementation details of the parent to the child. The child is coupled to the parent's behavior, not just its interface. When the parent changes, the child breaks. Inheritance hierarchies are rigid and hard to refactor. The fragile base class problem makes inheritance a source of bugs that the compiler cannot catch.

**What to do instead:** Use composition: hold a reference to the class you want to reuse and delegate to it. Implement a shared interface. Use the Decorator pattern when you need to add behavior. Reserve inheritance for genuine is-a relationships where the parent class is designed and documented for extension (Effective Java Item 19).

**Effective Java:** Item 18 (Favor composition over inheritance), Item 19 (Design and document for inheritance or else prohibit it).

**Severity:** WARNING

---

## God Object

**What it is:** A single class that accumulates too many responsibilities, becoming a central hub that most of the codebase depends on.

**Symptoms:**
- Classes with 500+ lines of code.
- Classes with 10+ fields or 15+ methods.
- Class names like `Manager`, `Handler`, `Processor`, `Utils` with no domain qualifier.
- Nearly every other class imports or depends on this class.
- Changes to this class require re-testing unrelated features.
- The class has mixed concerns: business logic, data access, validation, formatting.

**Why it's bad:** God Objects violate the Single Responsibility Principle. They create a coupling hub: every change risks breaking unrelated functionality. They are impossible to unit test in isolation. They resist refactoring because so much depends on them. They accumulate technical debt faster than any other anti-pattern.

**What to do instead:** Apply Extract Class refactoring. Identify the distinct responsibilities and move each to its own class with a focused interface. Each class should have one reason to change. Use the Data-Model First principle: if the God Object mixes data and behavior, separate them.

**Effective Java:** N/A directly. Aligns with Item 15 (Minimize accessibility) and general modular design.

**Severity:** CRITICAL

---

## Spaghetti Code

**What it is:** Code with tangled, unpredictable control flow that is impossible to follow by reading top to bottom.

**Symptoms:**
- Deeply nested conditionals (4+ levels).
- Methods with multiple return points scattered throughout.
- `goto`-like control flow using labeled breaks, exceptions for flow control, or flag variables.
- Methods longer than 30 lines with no clear structure.
- Circular method calls (A calls B calls C calls A).
- Logic spread across multiple methods that must be called in a specific, undocumented order.

**Why it's bad:** Spaghetti code cannot be understood, tested, or modified safely. Every change risks unintended side effects. New team members cannot onboard without extensive guidance. It resists automated analysis and refactoring tools.

**What to do instead:** Apply Extract Method refactoring to create small, focused methods with descriptive names. Flatten nested conditionals with early returns (guard clauses). Apply SRP: each method does one thing. Use the modular code principle: if a method is tangled, the module boundaries are probably wrong.

**Effective Java:** N/A directly. Aligns with simplicity principle.

**Severity:** CRITICAL

---

## Copy-Paste Programming

**What it is:** Duplicating code blocks instead of extracting shared logic into reusable methods or classes.

**Symptoms:**
- Two or more code blocks that are identical or nearly identical.
- Bug fixes that must be applied in multiple places.
- Inconsistent behavior between copies that have diverged over time.
- Search results for a function name or logic pattern returning multiple files with similar code.

**Why it's bad:** Every copy is a maintenance liability. When a bug is found, it must be fixed in every copy. Copies inevitably diverge, creating inconsistent behavior. The codebase grows without adding value.

**What to do instead:** Extract the shared logic into a method. If the logic varies slightly between uses, parameterize the method or use generics. If the pattern spans modules, create a shared utility in a common module. Apply DRY, but only after confirming the duplication is real (see Simplicity: wait for three uses before abstracting).

**Effective Java:** N/A directly. Aligns with generics-for-reuse principle.

**Severity:** WARNING

---

## Magic Numbers/Strings

**What it is:** Literal values (numbers, strings) embedded directly in code without explanation or named constants.

**Symptoms:**
- `if (status == 3)` or `if (role.equals("ADMIN"))` without a named constant or enum.
- Numeric literals in calculations: `total * 0.08` (what is 0.08?).
- String literals used as identifiers, keys, or configuration values scattered across methods.
- The same literal appearing in multiple places with the same meaning.

**Why it's bad:** Magic values are opaque. The reader cannot determine what `3` or `"ADMIN"` means without tracing the context. They are error-prone: typos in string literals are runtime bugs, not compile-time errors. They resist refactoring: changing a magic value requires finding every occurrence.

**What to do instead:** Define named constants as `private static final` fields in the class that uses them. Better yet, use enums for fixed sets of values (`Status.ACTIVE` instead of `3`). For configuration values, externalize to properties files. Apply the Shift-Left principle: enums and constants catch misuse at compile time.

**Effective Java:** Item 34 (Use enums instead of int constants).

**Severity:** WARNING

---

## Hard Coding

**What it is:** Embedding environment-specific or deployment-specific values (URLs, file paths, credentials, feature flags) directly in source code.

**Symptoms:**
- `String dbUrl = "jdbc:mysql://prod-db.example.com:3306/app"` in source code.
- File paths that assume a specific OS or directory structure.
- API keys, passwords, or tokens in source files.
- `if (environment.equals("production"))` conditionals scattered through business logic.

**Why it's bad:** Hard-coded values cannot be changed without a code change, rebuild, and redeployment. They leak secrets into version control. They break when the code moves to a different environment. They violate the separation of configuration from code.

**What to do instead:** Externalize all environment-specific values to configuration files (`application.yaml`, `application.properties`), environment variables, or a configuration service. Use the Reflection rule: load implementation classes from config when pluggability is needed. Never commit secrets to version control.

**Effective Java:** N/A directly. Aligns with Frameworks Last (configuration is infrastructure, not code).

**Severity:** WARNING

---

## Premature Optimization

**What it is:** Optimizing code for performance before profiling has identified an actual bottleneck.

**Symptoms:**
- Complex data structures chosen "for performance" without benchmarks.
- Inlined logic that sacrifices readability for microsecond savings.
- Custom caching layers added before measuring whether the cached operation is slow.
- Comments like "this is faster" without profiling data.
- Object pooling for cheap-to-create objects.
- Avoiding virtual threads or immutable objects "because they're slower" without evidence.

**Why it's bad:** Premature optimization produces complex, hard-to-maintain code that solves a problem that may not exist. It often makes the code slower by defeating JIT compiler optimizations that work best on simple, idiomatic code. It wastes development time on non-bottlenecks.

**What to do instead:** Write simple, clear, correct code first. Profile under realistic load. Optimize only the measured bottlenecks. Use JMH for microbenchmarks. Trust the JVM: HotSpot is exceptionally good at optimizing straightforward code.

**Effective Java:** Item 67 (Optimize judiciously).

**Severity:** WARNING

---

## Dead Code / Lava Flow

**What it is:** Unused code that remains in the codebase because no one is confident it can be safely removed.

**Symptoms:**
- Methods, classes, or fields with zero callers (IDE shows no usages).
- Commented-out code blocks with no explanation.
- `@Deprecated` annotations with no migration path or removal timeline.
- Code paths guarded by conditions that are always false.
- Import statements for unused classes.

**Why it's bad:** Dead code increases cognitive load. Every developer who reads the file must determine whether the dead code matters. It inflates the codebase, slows builds, and creates false positives in search results. It can mask real code by creating naming collisions or confusion.

**What to do instead:** Delete it. Version control remembers everything. If the code might be needed later, it can be retrieved from git history. Remove commented-out code, unused methods, unused imports, and unreachable branches. Run static analysis tools to identify dead code systematically.

**Effective Java:** N/A directly. Aligns with YAGNI and simplicity.

**Severity:** INFO

---

## Boat Anchor

**What it is:** Code written speculatively for a future requirement that has not materialized.

**Symptoms:**
- Classes or methods with names like `FutureUseHandler`, `PlaceholderService`.
- Abstract classes with a single concrete implementation and no plan for more.
- Interfaces with one implementation and no test double.
- TODO comments referencing future features with no timeline.
- Configuration options that are never used by any consumer.

**Why it's bad:** Boat anchors add complexity, increase maintenance burden, and constrain future design decisions — often incorrectly, because the speculated future requirement usually differs from reality when it arrives. They violate YAGNI.

**What to do instead:** Delete the speculative code. Implement features when they are needed, not before. If you must plan for extensibility, prefer an interface (cheap to add later) over a premature abstraction (expensive to change later).

**Effective Java:** N/A directly. Aligns with simplicity and YAGNI.

**Severity:** INFO

---

## Excessive Static

**What it is:** Overusing static methods and static utility classes as a substitute for object-oriented design and dependency injection.

**Symptoms:**
- Utility classes (`StringUtils`, `DateHelper`, `ValidationUtils`) with 10+ static methods.
- Business logic in static methods that cannot be overridden or injected.
- Static methods that access external resources (databases, file systems, HTTP).
- Test classes that require PowerMock or similar tools to mock static calls.
- Chains of static method calls that create hidden coupling.

**Why it's bad:** Static methods cannot be overridden, injected, or mocked without bytecode manipulation tools. They create tight coupling between the caller and the utility class. They violate the Interfaces and DI principle. When static methods access external resources, they make the calling code untestable without integration-level setup.

**What to do instead:** Convert stateful or side-effectful static methods to instance methods on an injected service. Keep static methods only for pure functions that depend solely on their parameters (e.g., `Math.max`, simple converters). For utility methods that access external resources, wrap them in an interface and inject.

**Effective Java:** N/A directly. Aligns with DI and testability principles.

**Severity:** WARNING

---

## Null Abuse

**What it is:** Using `null` as a sentinel value for "absent," "unknown," "default," or "error" instead of expressing these states through the type system.

**Symptoms:**
- `NullPointerException` in production logs.
- Defensive null checks (`if (x != null)`) scattered throughout the codebase.
- Methods that return `null` to indicate "not found."
- Fields that are sometimes null depending on the object's lifecycle stage.
- Null used as a default parameter or a "no value" marker in collections.

**Why it's bad:** Null is ambiguous. It can mean "not initialized," "not found," "not applicable," or "error" depending on context. The compiler cannot distinguish these cases. Every null return value imposes a null-check obligation on every caller, and missing one produces a `NullPointerException` at runtime. Null defeats the Shift-Left principle.

**What to do instead:** Use `Optional<T>` for methods that might not return a value. Use empty collections instead of null collections. Use the Null Object pattern for default behaviors. Design data classes so fields are never null after construction (use constructor validation). Annotate parameters and return types with `@Nullable` / `@NonNull` when working with code that predates Optional.

**Effective Java:** Item 55 (Return optionals judiciously), Item 54 (Return empty collections or arrays, not nulls).

**Severity:** WARNING

---

## Overengineering

**What it is:** Building a complex, generic, extensible system when a simple, specific solution would suffice.

**Symptoms:**
- Abstractions with one implementation and no evidence that more are coming.
- Multiple levels of indirection to do something straightforward.
- Configuration systems that are more complex than the feature they configure.
- Plugin architectures in applications that will never have plugins.
- Event-driven designs for synchronous, single-threaded workflows.
- Design documents that reference 5+ design patterns for a feature that processes data from A to B.

**Why it's bad:** Overengineered code is harder to read, harder to debug, harder to change, and slower to develop. It optimizes for a future that may never arrive while penalizing the present. It is the most common anti-pattern in enterprise Java.

**What to do instead:** Implement the simplest solution that works. Wait for concrete evidence (three uses) before abstracting. Apply YAGNI. Prefer composition over complex inheritance. Prefer direct method calls over event systems. Prefer explicit code over configuration-driven magic.

**Effective Java:** Item 67 in spirit: do not optimize (for flexibility, reuse, or extensibility) without evidence.

**Severity:** WARNING

---

## Golden Hammer

**What it is:** Applying a familiar technology, pattern, or framework to every problem regardless of fit.

**Symptoms:**
- Using Spring for a CLI tool that runs once and exits.
- Using Hibernate for a read-only reporting query.
- Using microservices for an internal tool with one user.
- Using the Observer pattern for a synchronous two-step workflow.
- Every class extending a common base class from an in-house framework.
- Dependency on a single library for tasks that the standard library handles.

**Why it's bad:** The Golden Hammer produces solutions that are more complex than the problem warrants. It introduces unnecessary dependencies, increases the learning curve, and creates vendor lock-in. It prevents the team from learning and applying better-fit alternatives.

**What to do instead:** Evaluate each problem independently. Ask: what is the simplest tool that solves this? Start with the Java standard library. Add dependencies only when they provide clear value. Apply the Frameworks Last principle.

**Effective Java:** Item 59 (Know and use the libraries) — the standard libraries are the first hammer to reach for.

**Severity:** WARNING

---

## Large Global Constants Class

**What it is:** A single monolithic class (typically `Constants.java` or `AppConstants.java`) that holds all constants for the entire application.

**Symptoms:**
- A class with 50+ `public static final` fields spanning unrelated domains.
- Constants for database configuration, UI labels, business rules, and error messages all in one file.
- Multiple teams editing the same constants file, creating merge conflicts.
- Importing `Constants.*` in most classes.

**Why it's bad:** A global constants class creates coupling between unrelated modules. Every class that imports it depends (at compile time) on every constant in the file, even the irrelevant ones. Changes to one constant trigger recompilation of everything that imports the class. It becomes a dumping ground that grows without bound.

**What to do instead:** Define constants in the class that uses them, as `private static final` fields. For constants shared within a module, create a focused constants class scoped to that module (e.g., `OrderConstants`, `AuthConstants`). For cross-module constants, define them in the API module's interface or as enums. Never use a single class for all constants.

**Effective Java:** N/A directly. Aligns with Item 15 (Minimize accessibility) and modular design.

**Severity:** WARNING

---

## Constant Interface Anti-Pattern

**What it is:** An interface that contains only constant definitions and no method declarations, used solely so implementing classes can access constants without qualification.

**Symptoms:**
- Interfaces with only `public static final` fields and no methods.
- Classes that `implements ConstantInterface` but never implement any behavior.
- Constants accessed without class qualification because the interface is implemented.

**Why it's bad:** Using an interface to hold constants pollutes the implementing class's API with irrelevant constants. It leaks implementation details into the public type hierarchy. It cannot be removed from the class without breaking binary compatibility. Interfaces are for defining types, not for holding constants.

**What to do instead:** Use a `final` class with a `private` constructor to hold constants. Access constants via the class name: `HttpStatus.OK` instead of implementing `HttpStatusConstants`. Use `static import` if you want unqualified access in a specific file.

**Effective Java:** Item 22 (Use interfaces only to define types).

**Severity:** WARNING

---

## Monolithic Coupling

**What it is:** A monolithic application where all code lives in a single module (or a flat package structure) with no enforced boundaries between logical components.

**Symptoms:**
- A single `build.gradle` with no subprojects.
- Any class can import any other class with no restriction.
- Package structure is flat or organized by technical layer (`controller`, `service`, `repository`) rather than by domain feature.
- Changes to one feature require re-testing unrelated features.
- Circular dependencies between packages.
- No `api` / `internal` package separation.

**Why it's bad:** Without enforced boundaries, coupling grows silently. Every new import creates a dependency that is invisible to the build system. Over time, the codebase becomes a tightly coupled ball of mud where nothing can change independently. This is the actual problem people attribute to monoliths, but the problem is the coupling, not the deployment model.

**What to do instead:** Use Gradle multi-project builds. Each logical module (orders, users, auth, payments) gets its own subproject with an explicit `build.gradle` that declares its dependencies. Modules expose interfaces in an `api` package and hide implementations in an `internal` package. If module A does not declare a dependency on module B, module A cannot use module B's classes. This is the monolithic deployment, modular code principle in action.

**Note:** Monolithic deployment is FINE. A single JAR or container is operationally simple. The anti-pattern is coupling without Gradle-enforced boundaries. Do not confuse this with a recommendation for microservices.

**Effective Java:** Item 15 (Minimize accessibility) at the module level.

**Severity:** CRITICAL

---

## Vendor Lock-In

**What it is:** Tight coupling to a specific vendor's APIs, libraries, or platform features such that switching vendors would require a substantial rewrite.

**Symptoms:**
- Direct use of vendor-specific APIs (AWS SDK classes) in business logic.
- Vendor-specific annotations on domain classes.
- No abstraction layer between business logic and infrastructure.
- Database queries using vendor-specific SQL extensions without standard SQL fallbacks.
- Cloud provider-specific deployment configurations embedded in application code.

**Why it's bad:** Vendor lock-in constrains future decisions. It makes cost negotiations asymmetric (the vendor knows you cannot leave). It makes migration to better alternatives prohibitively expensive. It couples business logic to infrastructure, violating the separation of concerns.

**What to do instead:** Define interfaces for all infrastructure interactions (storage, messaging, email, etc.). Implement the interface using the vendor's SDK, but keep the vendor SDK behind the interface. Use standard APIs where they exist: JDBC over vendor-specific database clients, Jakarta EE over proprietary frameworks, standard SQL over vendor extensions. Apply the Frameworks Last principle.

**Effective Java:** Item 64 (Refer to objects by their interfaces).

**Severity:** WARNING
