# Architecture Guide

Reference for the **java-architect** agent. Java 21+ / OpenJDK.

---

## Data Model Design

Start with the data model. Code follows from the model, not the other way around.

**POJOs for DAOs and DTOs:**
- DAOs encapsulate persistence access. One DAO per entity/aggregate root. Fields are `private final`. Constructor validates all invariants.
- DTOs carry data between layers or across module boundaries. No business logic. All fields `private final`, populated via constructor.

**Records for immutable data carriers:**
- Use `record` when the type is purely a data carrier with no mutable state and no custom behavior beyond accessors.
- Records auto-generate `equals()`, `hashCode()`, `toString()`, and canonical constructor.
- Records are implicitly `final` — they cannot be extended.

```java
// DTO as record — ideal for API responses, inter-module messages
public record UserSummary(long id, String name, String email) {}

// Entity as POJO — needs validation, business logic
public final class User {
    private final long id;
    private final String name;
    private final String email;
    private final Instant createdAt;

    public User(final long id, final String name, final String email, final Instant createdAt) {
        this.id = id;
        this.name = Objects.requireNonNull(name, "name must not be null");
        this.email = Objects.requireNonNull(email, "email must not be null");
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt must not be null");
    }
    // accessors, equals, hashCode, toString
}
```

**Entities, value objects, aggregates (without an ORM):**
- Entity: has identity (an ID). Two entities with the same field values but different IDs are different.
- Value object: defined by its attributes, not identity. Two value objects with the same fields are equal. Use records.
- Aggregate: a cluster of entities/value objects treated as a single unit for data changes. The aggregate root is the only entry point. Persist aggregates via DAOs that use inline SQL — no ORM.

**Design sequence:**
1. Identify entities and their relationships.
2. Define value objects for attribute groupings that lack independent identity.
3. Draw aggregate boundaries — each aggregate has one root entity.
4. Write the POJO/record for each type.
5. Define the DAO interface for each aggregate root.
6. Implement the DAO with inline SQL.

---

## Package Layout

Prefer **feature-based** within modules over layer-based. Layer-based (controller/service/dao packages) scatters related code. Feature-based groups everything for a feature together.

**Feature-based layout within a module:**

```
com.example.billing/
    invoice/
        Invoice.java             # entity
        InvoiceLineItem.java     # value object
        InvoiceDao.java          # interface
        InvoiceJdbcDao.java      # implementation
        InvoiceService.java      # interface
        InvoiceServiceImpl.java  # implementation
    payment/
        Payment.java
        PaymentDao.java
        PaymentJdbcDao.java
        PaymentService.java
        PaymentServiceImpl.java
    shared/
        Money.java               # shared value object (record)
        Currency.java            # enum
```

**Rules:**
- One top-level package per module, matching the module name.
- Feature packages underneath. Each feature package is self-contained.
- A `shared/` package for types used across features within the same module.
- Implementations are package-private when possible. Only interfaces and DTOs are `public`.
- No circular dependencies between feature packages.

**Layer-based is acceptable** at the top level of a small module or a module that is itself a single cohesive layer (e.g., a persistence module).

---

## Module Boundaries

Use **Gradle multi-project builds** to enforce module boundaries at compile time. A module cannot reach into another module's internals if the dependency is not declared.

**Structure:**

```
project-root/
    settings.gradle.kts
    build.gradle.kts           # root: shared config, dependency versions
    billing/
        build.gradle.kts       # declares dependencies on other modules
        src/main/java/...
    user-management/
        build.gradle.kts
        src/main/java/...
    common/
        build.gradle.kts       # shared types, interfaces
        src/main/java/...
```

**settings.gradle.kts:**

```kotlin
rootProject.name = "my-app"
include("common", "billing", "user-management")
```

**Module build.gradle.kts:**

```kotlin
dependencies {
    implementation(project(":common"))
    // billing depends on common, but NOT on user-management
}
```

**Enforcement rules:**
- Each module exposes interfaces (and DTOs/records) as its public API. Implementations are package-private or internal.
- Inter-module dependencies are explicit in `build.gradle.kts`. If module A does not declare a dependency on module B, it cannot import B's classes. The compiler enforces this.
- No circular module dependencies. If A depends on B and B needs something from A, extract a shared interface to `common`.
- A module's public API surface should be minimal: interfaces, DTOs, exceptions, enums. Not implementations.

**API vs implementation separation with Gradle:**

```kotlin
// In billing/build.gradle.kts
dependencies {
    // common's public API is available at compile time
    api(project(":common"))
    // guava is an implementation detail, not exposed to consumers
    implementation("com.google.guava:guava:33.0.0-jre")
}
```

Use `api` for dependencies that are part of your module's public API (types in method signatures). Use `implementation` for everything else.

---

## Interface Contract Design

Program to interfaces. Interfaces define behavior contracts.

**Principles:**
- Clients depend on interfaces, not implementations. Constructor injection wires the concrete class.
- Prefer small, focused interfaces (ISP). An interface with 10 methods is a code smell — split it.
- Interfaces define *what*, not *how*. No implementation details leak through.
- Use `default` methods sparingly — only for backward-compatible additions or template method patterns.

**Generics for type-safe contracts:**

```java
// Generic repository interface — reusable across entities
public interface Repository<T, ID> {
    Optional<T> findById(ID id);
    List<T> findAll();
    T save(T entity);
    void deleteById(ID id);
}

// Type-safe specialization
public interface UserRepository extends Repository<User, Long> {
    Optional<User> findByEmail(String email);
}
```

**Sealed interfaces for restricted hierarchies:**

```java
// Only these implementations exist — compiler enforces exhaustiveness
public sealed interface PaymentMethod
    permits CreditCard, BankTransfer, DigitalWallet {}

public record CreditCard(String number, String expiry) implements PaymentMethod {}
public record BankTransfer(String iban) implements PaymentMethod {}
public record DigitalWallet(String provider, String token) implements PaymentMethod {}
```

**Contract documentation:**
- Preconditions: what must be true before calling (parameter constraints).
- Postconditions: what is guaranteed after the call returns.
- Invariants: what is always true about the implementing class.
- Document these with Javadoc on the interface methods, not the implementations.

---

## Build Configuration

Gradle (Kotlin DSL) is the preferred build tool.

**Root build.gradle.kts — shared config:**

```kotlin
plugins {
    java
}

subprojects {
    apply(plugin = "java")

    java {
        toolchain {
            languageVersion = JavaLanguageVersion.of(21)
        }
    }

    repositories {
        mavenCentral()
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:all", "-Werror"))
    }

    tasks.withType<Test> {
        useJUnitPlatform()
    }
}
```

**Version catalogs (gradle/libs.versions.toml):**

```toml
[versions]
junit = "5.11.0"
mockito = "5.14.0"
assertj = "3.26.0"

[libraries]
junit-bom = { module = "org.junit:junit-bom", version.ref = "junit" }
junit-jupiter = { module = "org.junit.jupiter:junit-jupiter" }
mockito-core = { module = "org.mockito:mockito-core", version.ref = "mockito" }
mockito-junit = { module = "org.mockito:mockito-junit-jupiter", version.ref = "mockito" }
assertj-core = { module = "org.assertj:assertj-core", version.ref = "assertj" }

[bundles]
testing = ["junit-jupiter", "mockito-core", "mockito-junit", "assertj-core"]
```

**Module build.gradle.kts using catalogs:**

```kotlin
dependencies {
    implementation(project(":common"))

    testImplementation(platform(libs.junit.bom))
    testImplementation(libs.bundles.testing)
}
```

**Plugin conventions:**
- Use `java-library` plugin for modules that expose APIs to other modules.
- Use `application` plugin for the runnable module (the one with `main()`).
- Keep plugin versions in `settings.gradle.kts` via `pluginManagement`.

---

## Dependency Selection Criteria

Before adopting a library or framework, evaluate:

1. **Does it solve a real problem?** If plain Java 21+ solves it, skip the dependency. Virtual threads replace most async frameworks. Inline SQL replaces most ORMs. `java.net.http.HttpClient` replaces most HTTP libraries.
2. **What is the transitive dependency cost?** Run `gradle dependencies` and inspect. A library that pulls in 40 transitive dependencies is a liability.
3. **Is it actively maintained?** Check release frequency, open issues, response time. Abandoned libraries become security risks.
4. **Can you replace it?** If you wrap the library behind an interface, you can swap it later. If the library's types leak into your domain model, you are locked in.
5. **Does it force a programming model?** Frameworks that require annotations on your domain classes, force inheritance from framework base classes, or require specific package structures are coupling you to the framework.

**Frameworks-last philosophy:**
- No Hibernate/JPA when JDBC + inline SQL works. ORMs add complexity, obscure queries, and produce surprising SQL. Inline SQL is explicit, debuggable, and statically defined.
- No Spring when constructor injection + a config file works. Spring's DI container is useful at scale, but `Class.forName()` from a config file handles most cases.
- No Lombok. Java 16+ records and IDE generation handle what Lombok does, without the annotation processor dependency.

**Approved by default (no justification needed):**
- JUnit 5, Mockito, AssertJ (testing)
- SLF4J + Logback (logging)
- Jackson (JSON, when needed)
- Standard library: `java.net.http`, `java.sql`, `java.util.concurrent`, `java.time`

---

## API Design

REST conventions for HTTP APIs. Keep it simple.

**URL structure:**
- Nouns for resources: `/users`, `/users/{id}`, `/users/{id}/orders`
- HTTP verbs for actions: GET (read), POST (create), PUT (full update), PATCH (partial update), DELETE (remove)
- Plural nouns: `/users` not `/user`
- No verbs in URLs: `/users/{id}` with DELETE, not `/deleteUser/{id}`

**Error handling:**
- Use standard HTTP status codes. 400 for client errors, 404 for not found, 409 for conflict, 500 for server errors.
- Return a consistent error response body:

```java
public record ErrorResponse(int status, String error, String message, Instant timestamp) {}
```

- Never expose stack traces in API responses. Log them server-side.
- Validate request data at the API boundary. Return 400 with specific field-level errors.

**Versioning:**
- URL path versioning: `/api/v1/users`. Simple, explicit, cacheable.
- Increment major version only for breaking changes. Add new fields to responses without versioning (additive changes are non-breaking).

**Response conventions:**
- Single resource: return the object directly.
- Collection: return a JSON array (or a wrapper with pagination metadata).
- Create: return 201 with the created resource and a `Location` header.
- Delete: return 204 with no body.
- Use records for request/response DTOs.

---

## Concurrency Architecture

Virtual threads (Java 21+) are the default concurrency model.

**Why virtual threads:**
- Lightweight: millions of virtual threads vs. thousands of platform threads.
- No thread pool tuning. No thread starvation. No reactive programming complexity.
- Blocking I/O is fine — the virtual thread yields its carrier thread automatically.
- Combined with immutable data, most concurrency bugs are eliminated.

**Structured concurrency (Java 21+ preview):**

```java
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    Subtask<User> userTask = scope.fork(() -> userService.findById(userId));
    Subtask<List<Order>> ordersTask = scope.fork(() -> orderService.findByUserId(userId));

    scope.join();
    scope.throwIfFailed();

    final var user = userTask.get();
    final var orders = ordersTask.get();
    return new UserProfile(user, orders);
}
```

**Architecture rules:**
- Use `Executors.newVirtualThreadPerTaskExecutor()` for task submission. Never pool virtual threads.
- Prefer immutable data passed between threads. No shared mutable state.
- If mutable shared state is unavoidable, use `ReentrantLock`, not `synchronized`. Virtual threads can be pinned to carrier threads inside `synchronized` blocks during blocking operations.
- Design modules to be stateless where possible. State lives in the database, not in memory.
- For request-scoped data, use scoped values (`ScopedValue`, Java 21+ preview) instead of `ThreadLocal`.

**What NOT to do:**
- Do not pool virtual threads in a fixed-size pool. That defeats the purpose.
- Do not use `synchronized` for operations that may block (I/O, database calls). Use `ReentrantLock`.
- Do not use reactive frameworks (Project Reactor, RxJava) just for async I/O. Virtual threads handle blocking I/O efficiently without callback hell.
- Do not use `ThreadLocal` for request-scoped data in virtual thread contexts — virtual threads are cheap and numerous, making `ThreadLocal` a memory concern. Prefer `ScopedValue`.
