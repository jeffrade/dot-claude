# Review Checklist

Violation catalog for the **java-reviewer** agent. Java 21+ / OpenJDK.

Organized by severity: CRITICAL (must fix), WARNING (should fix), INFO (nice to fix).

---

## CRITICAL Violations

### Mutable Shared State Without Justification
**Severity:** CRITICAL
**Detection:** Non-final fields accessed by multiple threads. Fields modified after construction without synchronization. Mutable static fields. Collections exposed without defensive copies.
**Principle:** Immutability at All Costs (core-principles.md#immutability)
**Fix:** Make fields `private final`. Use immutable collections (`List.of()`, `List.copyOf()`). If mutation is genuinely needed, document the justification and protect with `ReentrantLock`.
**Effective Java:** Item 17 (Minimize mutability)

### Singleton Pattern Usage
**Severity:** CRITICAL
**Detection:** `private static` instance of own class. `getInstance()` method. Enum used as a service locator. `static` fields holding service instances.
**Principle:** Interfaces and Dependency Injection (core-principles.md#interfaces-and-di)
**Fix:** Replace with interface + constructor injection. The object's lifecycle is managed by the caller, not by itself. Test with different implementations by passing them through the constructor.
**Effective Java:** Item 3 (Enforce the singleton property — but our principles reject this pattern entirely due to concurrency risks and hidden global state)

### Raw Types in Public APIs
**Severity:** CRITICAL
**Detection:** `List`, `Map`, `Set`, `Collection`, `Iterable` without type parameters in public method signatures. `Class` without a type parameter. Grep for `List ` (List followed by space, not `List<`).
**Principle:** Generics for Reuse (core-principles.md#generics)
**Fix:** Add type parameters. `List<User>`, `Map<String, Order>`, `Class<? extends Dao>`. If the type is truly unknown, use `<?>`.
**Effective Java:** Item 26 (Don't use raw types)

### Unchecked Reflection Outside Config-Driven Pattern
**Severity:** CRITICAL
**Detection:** `Class.forName()` not in a `ConfigLoader` or config-reading class. `Method.invoke()`. `Field.setAccessible(true)`. `Constructor.newInstance()` outside the config-driven pattern. Grep for `\.forName\(`, `\.invoke\(`, `setAccessible`.
**Principle:** Annotations and Reflection (core-principles.md#reflection)
**Fix:** Remove reflection. Use interfaces + constructor injection for polymorphism. Use Jackson for serialization. The only permitted reflection pattern is loading implementation class names from a root-level configuration file.
**Effective Java:** Item 65 (Prefer interfaces to reflection)

### SQL Injection (String Concatenation in Queries)
**Severity:** CRITICAL
**Detection:** SQL strings built with `+` operator containing variable references. `"SELECT ... WHERE id = " + id`. String.format() in SQL. Grep for `"SELECT.*" \+` or `"INSERT.*" \+` or `"UPDATE.*" \+` or `"DELETE.*" \+`.
**Principle:** Frameworks Last / Inline SQL Conventions (implementation-guide.md#inline-sql-conventions)
**Fix:** Use `PreparedStatement` with `?` parameter placeholders. SQL strings should be `static final` constants. Never concatenate user input into SQL.

### Swallowed Exceptions (Empty Catch Blocks)
**Severity:** CRITICAL
**Detection:** `catch` blocks with empty bodies. `catch` blocks containing only a comment. `catch (Exception e) {}`. Grep for `catch\s*\(.*\)\s*\{\s*\}` or review catch blocks with no statements.
**Principle:** Shift-Left (core-principles.md#shift-left)
**Fix:** At minimum, log the exception. Preferably, handle it meaningfully or rethrow. If the exception is genuinely ignorable (extremely rare), add a comment explaining why AND log at debug level.
**Effective Java:** Item 77 (Don't ignore exceptions)

### God Object (5+ Unrelated Responsibilities)
**Severity:** CRITICAL
**Detection:** Class with methods spanning multiple unrelated domains. Class importing from many different feature packages. Class exceeding 500 lines with diverse functionality. Fields representing different concerns (database, HTTP, validation, business logic all in one class).
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Extract classes by responsibility. One class, one reason to change. Each extracted class gets its own interface if it will be a dependency for other classes.

### Missing Module Boundary Enforcement
**Severity:** CRITICAL
**Detection:** Single `build.gradle` for the entire project with no subprojects. All code in one Gradle module. No `settings.gradle.kts` with `include()` statements for subprojects. Packages depending on other packages' internal classes with no compile-time enforcement.
**Principle:** Monolithic Deployment, Modular Code (core-principles.md#modular-code)
**Fix:** Set up Gradle multi-project build. Each logical module gets its own `build.gradle.kts`. Inter-module dependencies are declared explicitly. A module's internal classes are package-private.

### Public Mutable Fields
**Severity:** CRITICAL
**Detection:** `public` non-final fields. `public` fields of mutable types (arrays, mutable collections). Grep for `public\s+(?!static\s+final)` on field declarations.
**Principle:** Immutability at All Costs (core-principles.md#immutability), Intent Through Keywords (core-principles.md#keywords)
**Fix:** Make fields `private final`. Provide accessor methods. For arrays, return defensive copies. For collections, return `List.copyOf()` or `Collections.unmodifiableList()`.
**Effective Java:** Item 16 (In public classes, use accessor methods, not public fields)

---

## WARNING Violations

### Missing Final on Fields/Parameters/Locals
**Severity:** WARNING
**Detection:** Instance fields without `final`. Method parameters without `final`. Local variables assigned once without `final`. Grep for field declarations missing `final` (after access modifier, before type).
**Principle:** Immutability at All Costs (core-principles.md#immutability), Intent Through Keywords (core-principles.md#keywords)
**Fix:** Add `final` to all fields, parameters, and local variables that are assigned once. Only omit `final` when reassignment is genuinely needed and justified.
**Effective Java:** Item 17 (Minimize mutability)

### Raw Type Usage (Even Internal)
**Severity:** WARNING
**Detection:** Any use of `List`, `Map`, `Set`, `Collection`, `Optional`, `Class` without type parameters, even in private/internal code. Compiler warnings about raw types.
**Principle:** Generics for Reuse (core-principles.md#generics)
**Fix:** Add type parameters everywhere. Use `<?>` when the type is genuinely unknown. Suppress `@SuppressWarnings("unchecked")` only with an explanatory comment.
**Effective Java:** Item 26 (Don't use raw types), Item 27 (Eliminate unchecked warnings)

### Checked Exception Abuse
**Severity:** WARNING
**Detection:** Checked exceptions that callers always catch-and-rethrow or catch-and-wrap in RuntimeException. Custom checked exceptions for conditions the caller cannot recover from. Methods with `throws` clauses containing more than 2 checked exceptions.
**Principle:** Shift-Left (core-principles.md#shift-left)
**Fix:** Use unchecked exceptions for programming errors. Reserve checked exceptions for conditions where the caller can take a meaningful recovery action. Wrap checked exceptions from third-party libraries in module-specific unchecked exceptions.
**Effective Java:** Item 71 (Avoid unnecessary use of checked exceptions)

### Methods Exceeding 30 Lines
**Severity:** WARNING
**Detection:** Count non-blank, non-comment lines in method bodies. Methods exceeding 30 lines of logic.
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Extract helper methods. Each method should do one thing. Long methods often contain multiple responsibilities that can be separated.

### Missing Interface Abstraction (Concrete Dependencies)
**Severity:** WARNING
**Detection:** Constructor parameters typed as concrete classes instead of interfaces. Fields typed as `UserJdbcDao` instead of `UserDao`. `new ConcreteClass()` inside a class that should receive its dependencies.
**Principle:** Interfaces and Dependency Injection (core-principles.md#interfaces-and-di)
**Fix:** Define an interface for the dependency. Type the field/parameter as the interface. Pass the concrete implementation via constructor injection.
**Effective Java:** Item 64 (Refer to objects by their interfaces)

### Abstract Factory / Complex Pattern Where DI Suffices
**Severity:** WARNING
**Detection:** Factory classes that create factories. Multiple levels of abstraction for object creation. Builder chains longer than 3 steps for simple objects. Visitor pattern for simple conditionals. Strategy pattern with only one implementation.
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity), Interfaces and Dependency Injection (core-principles.md#interfaces-and-di)
**Fix:** Replace with interface + constructor injection. A factory method or static factory is fine for object creation. Complex factory hierarchies are almost never needed.

### ORM Where Inline SQL Suffices
**Severity:** WARNING
**Detection:** Hibernate/JPA annotations (`@Entity`, `@Table`, `@Column`, `@OneToMany`). `EntityManager` usage. HQL/JPQL queries. `persistence.xml`. Gradle dependencies on `hibernate-core` or `jakarta.persistence-api`.
**Principle:** Frameworks Last (core-principles.md#frameworks-last)
**Fix:** Replace with JDBC + inline SQL. Define SQL as `static final String` constants. Use `PreparedStatement` for queries. Map `ResultSet` to POJOs manually. This is explicit, debuggable, and avoids the N+1 query problem entirely.

### Magic Numbers/Strings
**Severity:** WARNING
**Detection:** Numeric literals in logic (other than 0, 1, -1). String literals used for comparison or configuration. Hardcoded URLs, file paths, or port numbers in source code.
**Principle:** Intent Through Keywords (core-principles.md#keywords)
**Fix:** Extract to named constants (`private static final`). Use enums for enumerated values. Externalize configuration values to properties files.

### Large Global Constants Class
**Severity:** WARNING
**Detection:** A class named `Constants`, `AppConstants`, `GlobalConstants`, or similar containing unrelated constants from multiple domains. A constants class exceeding 50 constants.
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Move constants to the classes that use them. If multiple classes share a constant, create a focused package-level constants class (e.g., `BillingConstants`, not `Constants`).

### Constant Interface Pattern
**Severity:** WARNING
**Detection:** Interfaces containing only `static final` fields and no abstract methods. Classes implementing interfaces solely to inherit constants. Grep for `interface.*\{` followed by only constant declarations.
**Principle:** Intent Through Keywords (core-principles.md#keywords)
**Fix:** Replace with a `final` class with a `private` constructor containing `public static final` fields. Or move constants to the classes that use them.
**Effective Java:** Item 22 (Use interfaces only to define types)

### Copy-Paste Code Duplication
**Severity:** WARNING
**Detection:** Identical or near-identical code blocks in multiple classes. Methods with the same logic but different types (candidate for generics). Duplicated SQL queries across DAOs.
**Principle:** Generics for Reuse (core-principles.md#generics), Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Extract shared logic to a common method, generic class, or shared utility. For SQL, extract common query fragments to shared constants if the queries truly share structure.

### Excessive Static Methods
**Severity:** WARNING
**Detection:** Utility classes with many static methods that could be instance methods. Static methods that take an object as a parameter and operate on it (should be an instance method on that object's type). More than 5 static methods in a non-utility class.
**Principle:** Interfaces and Dependency Injection (core-principles.md#interfaces-and-di)
**Fix:** Convert to instance methods on an interface. Inject the implementation. Static methods are appropriate for pure utility functions (math, string manipulation) and static factory methods. They are not appropriate for service logic.

### Null Returns Where Optional Is Appropriate
**Severity:** WARNING
**Detection:** Methods returning `null` for "not found" cases. Lookup methods with return types of entities/DTOs (not `Optional`). Callers checking `if (result == null)` after calling a method.
**Principle:** Shift-Left (core-principles.md#shift-left)
**Fix:** Return `Optional<T>` instead of `T` for methods that may not find a result. The caller is forced to handle absence explicitly.
**Effective Java:** Item 55 (Return optionals judiciously)

### Missing @Override Annotation
**Severity:** WARNING
**Detection:** Methods that override a superclass or interface method without `@Override`. IDE or compiler can flag these if `-Xlint:all` is enabled.
**Principle:** Shift-Left (core-principles.md#shift-left), Intent Through Keywords (core-principles.md#keywords)
**Fix:** Add `@Override` to every method that overrides or implements. This catches method signature mismatches at compile time.
**Effective Java:** Item 40 (Consistently use the Override annotation)

### Synchronized Blocks (Prefer ReentrantLock)
**Severity:** WARNING
**Detection:** `synchronized` keyword on methods or blocks, especially those containing I/O or blocking operations. Grep for `synchronized`.
**Principle:** Concurrency via Virtual Threads (core-principles.md#concurrency)
**Fix:** Replace `synchronized` with `ReentrantLock`. Virtual threads can be pinned to carrier threads inside `synchronized` blocks during blocking operations, negating the benefit of virtual threads. `ReentrantLock` does not pin.

---

## INFO Violations

### Naming Convention Violations
**Severity:** INFO
**Detection:** Classes not in PascalCase. Methods/variables not in camelCase. Constants not in UPPER_SNAKE_CASE. Packages not in lowercase. Single-letter variable names outside of lambdas and loop indices.
**Principle:** Intent Through Keywords (core-principles.md#keywords)
**Fix:** Rename to follow standard Java naming conventions. Names should be descriptive and self-documenting.

### Import Organization
**Severity:** INFO
**Detection:** Wildcard imports (`import java.util.*`). Unused imports. Imports not grouped (standard library, third-party, project).
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Use explicit imports. Remove unused imports. Group imports: `java.*`, `javax.*`/`jakarta.*`, third-party, project packages. Configure IDE to enforce.

### Missing @DisplayName on Tests
**Severity:** INFO
**Detection:** `@Test` methods without `@DisplayName`. Test methods relying solely on method names for test output readability.
**Principle:** Testing Philosophy (core-principles.md#testing)
**Fix:** Add `@DisplayName("should ...")` to all test methods and `@Nested` classes. This produces readable test reports.

### Dead Code / Unused Imports
**Severity:** INFO
**Detection:** Methods never called. Variables assigned but never read. Imports not referenced. Commented-out code blocks. Unreachable code after return/throw statements.
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Delete it. Trust version control. Dead code adds noise, confuses readers, and may cause false positives in search results. If it was important, it is in git history.

### Boat Anchor Code (Speculative Unused Abstractions)
**Severity:** INFO
**Detection:** Interfaces with only one implementation and no testing/extension point justification. Abstract classes with only one subclass. Methods that are "ready for future use" but unused. Generic parameters that are always the same concrete type.
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Delete the abstraction. Keep the concrete class. If a second implementation is needed later, introduce the interface then. YAGNI.

### Javadoc on Non-Public Methods
**Severity:** INFO
**Detection:** Javadoc comments on `private` or package-private methods. Verbose documentation on internal implementation details.
**Principle:** Simplicity Over Cleverness (core-principles.md#simplicity)
**Fix:** Remove Javadoc from non-public methods. Use brief inline comments only when the code is genuinely non-obvious. Public API methods should have Javadoc; internal methods should be self-documenting through good naming.
