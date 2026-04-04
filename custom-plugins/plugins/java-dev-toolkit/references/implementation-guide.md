# Implementation Guide

Reference for the **java-developer** agent. Java 21+ / OpenJDK.

---

## Immutability Defaults

Default to immutable. Mutable state is a design decision that must be justified.

**Fields:** Always `private final`. No exceptions unless mutation is genuinely required and documented.

```java
public final class Account {
    private final long id;
    private final String name;
    private final BigDecimal balance; // BigDecimal is immutable

    public Account(final long id, final String name, final BigDecimal balance) {
        this.id = id;
        this.name = Objects.requireNonNull(name);
        this.balance = Objects.requireNonNull(balance);
    }
}
```

**Parameters:** Always `final`. Prevents accidental reassignment and signals intent.

```java
public Optional<User> findById(final long id) { ... }
```

**Local variables:** Always `final`. If a variable is assigned once, mark it `final`.

```java
final var user = userDao.findById(id);
final var response = new UserResponse(user.name(), user.email());
```

**Immutable collections:**
- Use `List.of()`, `Set.of()`, `Map.of()` for creation.
- Use `List.copyOf()`, `Set.copyOf()`, `Map.copyOf()` to create immutable copies of mutable collections.
- Use `Collections.unmodifiableList()` only when wrapping an existing mutable list you want to freeze.
- Never return a mutable collection from a method. Copy or wrap it.

```java
public List<String> getTags() {
    return List.copyOf(this.tags); // defensive copy, immutable
}
```

**Records:** Use for data carriers. Records are inherently immutable — all fields are `final`, no setters.

```java
public record OrderSummary(long orderId, BigDecimal total, Instant placedAt) {}
```

**When mutability is genuinely needed:**
- Builders (during construction only — the built object is immutable).
- Accumulating results in a loop where streams are not practical.
- Performance-critical paths where immutable copies are too expensive (profile first).
- Document the reason with a comment. Contain the mutable state to the smallest possible scope.

---

## Generics Patterns

Use generics aggressively to eliminate code duplication, enforce type safety at compile time, and avoid runtime casting.

**Type-safe containers:**

```java
// Generic DAO — one implementation pattern for all entities
public interface Dao<T, ID> {
    Optional<T> findById(ID id);
    List<T> findAll();
    T save(T entity);
    void deleteById(ID id);
}

public final class JdbcUserDao implements Dao<User, Long> {
    // Type-safe: compiler enforces User and Long
}
```

**Bounded wildcards (PECS: Producer-Extends, Consumer-Super):**

```java
// Producer: reads items of type T or subtypes
public double sum(final List<? extends Number> numbers) {
    return numbers.stream().mapToDouble(Number::doubleValue).sum();
}

// Consumer: adds items of type T or supertypes
public void addAll(final List<? super Integer> target, final int count) {
    for (int i = 0; i < count; i++) {
        target.add(i);
    }
}
```

**Generic service interfaces:**

```java
public interface CrudService<T, ID> {
    T create(T entity);
    Optional<T> read(ID id);
    T update(T entity);
    void delete(ID id);
}

// Concrete service inherits full CRUD without repeating signatures
public final class UserService implements CrudService<User, Long> { ... }
```

**Generic utility methods:**

```java
// Type-safe pair — avoids raw Object usage
public record Pair<A, B>(A first, B second) {}

// Generic factory method with bounded type
public static <T extends Comparable<T>> T max(final T a, final T b) {
    return a.compareTo(b) >= 0 ? a : b;
}
```

**Rules:**
- Never use raw types. `List` without a type parameter is always wrong. Use `List<?>` if the type is truly unknown.
- Prefer `List<? extends Foo>` in method parameters over `List<Foo>` when you only read from the list.
- Suppress `@SuppressWarnings("unchecked")` only with a comment explaining why it is safe.
- Effective Java Items 26-33 cover generics in depth.

---

## Inline SQL Conventions

Inline SQL is preferred over ORM. SQL is statically defined, explicit, and debuggable.

**Static final constants for SQL:**

```java
public final class UserJdbcDao implements UserDao {

    private static final String FIND_BY_ID = """
            SELECT id, name, email, created_at
            FROM users
            WHERE id = ?
            """;

    private static final String FIND_ALL = """
            SELECT id, name, email, created_at
            FROM users
            ORDER BY created_at DESC
            """;

    private static final String INSERT = """
            INSERT INTO users (name, email, created_at)
            VALUES (?, ?, ?)
            """;

    private static final String DELETE_BY_ID = """
            DELETE FROM users
            WHERE id = ?
            """;
}
```

**Parameterized queries — NEVER string concatenation:**

```java
// CORRECT: parameterized
try (var stmt = connection.prepareStatement(FIND_BY_ID)) {
    stmt.setLong(1, id);
    try (var rs = stmt.executeQuery()) {
        if (rs.next()) {
            return Optional.of(mapRow(rs));
        }
        return Optional.empty();
    }
}

// WRONG: string concatenation — SQL injection vulnerability
var sql = "SELECT * FROM users WHERE id = " + id; // NEVER DO THIS
```

**ResultSet to POJO mapping:**

```java
private User mapRow(final ResultSet rs) throws SQLException {
    return new User(
        rs.getLong("id"),
        rs.getString("name"),
        rs.getString("email"),
        rs.getTimestamp("created_at").toInstant()
    );
}
```

**Organization within a class:**
1. SQL constants at the top of the class, grouped by operation (queries, mutations).
2. Constructor with `DataSource` or `Connection` injection.
3. Public DAO methods implementing the interface.
4. Private `mapRow()` helper methods at the bottom.

**Text blocks** (Java 15+) for readable multi-line SQL. Triple-quote syntax preserves formatting and avoids string concatenation for complex queries.

**Transaction management:**

```java
public void transferFunds(final long fromId, final long toId, final BigDecimal amount)
        throws SQLException {
    try (var conn = dataSource.getConnection()) {
        conn.setAutoCommit(false);
        try {
            debit(conn, fromId, amount);
            credit(conn, toId, amount);
            conn.commit();
        } catch (final SQLException e) {
            conn.rollback();
            throw e;
        }
    }
}
```

---

## Annotation Usage

Annotations express intent. The compiler or tooling enforces what comments cannot.

**Standard annotations:**
- `@Override` — always use. Catches method signature mismatches at compile time. Effective Java Item 40.
- `@Deprecated(since = "x.y", forRemoval = true)` — mark obsolete APIs with replacement guidance.
- `@FunctionalInterface` — on interfaces intended as lambda targets. Compiler prevents adding abstract methods.
- `@SuppressWarnings("unchecked")` — only with a comment explaining safety. Smallest possible scope.

**Nullability annotations:**
- `@Nullable` and `@NonNull` (from `jakarta.annotation`, `org.jetbrains.annotations`, or `jspecify`).
- Annotate return types, parameters, and fields that interact with external data.
- Prefer `Optional` return types over `@Nullable` returns.

**Custom annotations for project intent:**

```java
// Marks a class as intentionally immutable — reviewer can verify
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Immutable {}

// Marks a method as requiring a database transaction
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Transactional {}
```

**Class-level vs method-level:**
- Class-level: `@Immutable`, `@ThreadSafe`, `@FunctionalInterface`.
- Method-level: `@Override`, `@Transactional`, `@Deprecated`.
- Parameter-level: `@NonNull`, `@Nullable`.

**Rules:**
- Annotations should be meaningful — they express intent to humans and tooling.
- Do not use annotations as a substitute for good design. `@Autowired` on a field is a code smell; use constructor injection.
- Keep annotation definitions in a shared module so all modules can use them.

---

## Reflection Rules

Reflection is permitted **only** for config-driven class loading from a root-level configuration file. No other use.

**The config-driven pattern:**

```properties
# application.properties
user.repository=com.example.user.UserJdbcDao
payment.gateway=com.example.payment.StripeGateway
```

```java
public final class ConfigLoader {

    private final Properties properties;

    public ConfigLoader(final Properties properties) {
        this.properties = Objects.requireNonNull(properties);
    }

    @SuppressWarnings("unchecked") // Safe: config file specifies implementations of known interfaces
    public <T> T loadImplementation(final String key, final Class<T> interfaceType) {
        final var className = properties.getProperty(key);
        if (className == null) {
            throw new IllegalArgumentException("No config entry for key: " + key);
        }
        try {
            final var clazz = Class.forName(className);
            final var instance = clazz.getDeclaredConstructor().newInstance();
            return interfaceType.cast(instance);
        } catch (final ReflectiveOperationException e) {
            throw new RuntimeException("Failed to load " + className + " for key " + key, e);
        }
    }
}
```

**Usage:**

```java
final var config = new ConfigLoader(loadProperties("application.properties"));
final UserDao userDao = config.loadImplementation("user.repository", UserDao.class);
```

**What is NOT allowed:**
- Reflection for dependency injection (use constructor injection).
- Reflection to access private fields or methods.
- Reflection for serialization/deserialization (use Jackson or manual mapping).
- Reflection for proxy generation or AOP.
- `setAccessible(true)` on anything.

**Why this restriction exists:** Reflection bypasses compile-time type safety. It breaks shift-left principles. The config-driven pattern is the one justified use case — it enables swapping implementations without recompiling.

---

## Virtual Thread Patterns

Java 21+ virtual threads are the default concurrency model. Combined with immutable data, most concurrency problems disappear.

**Creating virtual threads:**

```java
// One-off virtual thread
Thread.startVirtualThread(() -> processOrder(order));

// Named virtual thread (for debugging)
Thread.ofVirtual().name("order-processor").start(() -> processOrder(order));
```

**Virtual thread executor:**

```java
// Preferred: submit tasks to a virtual-thread-per-task executor
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    final var futures = orders.stream()
        .map(order -> executor.submit(() -> processOrder(order)))
        .toList();

    for (final var future : futures) {
        future.get(); // blocks the virtual thread, not the carrier
    }
}
```

**Structured concurrency (preview):**

```java
try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
    final var userTask = scope.fork(() -> userService.findById(userId));
    final var ordersTask = scope.fork(() -> orderService.findByUserId(userId));

    scope.join();           // wait for all subtasks
    scope.throwIfFailed();  // propagate first failure

    return new UserDashboard(userTask.get(), ordersTask.get());
}
```

**What NOT to do:**
- Do not pool virtual threads in fixed-size pools. Virtual threads are cheap — create one per task.
- Do not use `synchronized` for operations that block (I/O, database, network). `synchronized` pins the virtual thread to its carrier thread. Use `ReentrantLock` instead.
- Do not use `ThreadLocal` for request-scoped data. Virtual threads are numerous; `ThreadLocal` values accumulate. Use `ScopedValue` (preview).
- Do not use reactive frameworks just for async I/O. Virtual threads make blocking I/O performant without callback complexity.

**ReentrantLock over synchronized:**

```java
// WRONG with virtual threads — pins carrier thread during blocking
public synchronized String fetchData() {
    return httpClient.send(request, BodyHandlers.ofString()).body();
}

// CORRECT — ReentrantLock does not pin
private final ReentrantLock lock = new ReentrantLock();

public String fetchData() {
    lock.lock();
    try {
        return httpClient.send(request, BodyHandlers.ofString()).body();
    } finally {
        lock.unlock();
    }
}
```

---

## POJO Conventions

POJOs are the backbone of the data model. They should be immutable, validated, and well-defined.

**Constructor validation:**

```java
public final class Product {
    private final long id;
    private final String name;
    private final BigDecimal price;

    public Product(final long id, final String name, final BigDecimal price) {
        if (id <= 0) {
            throw new IllegalArgumentException("id must be positive: " + id);
        }
        this.id = id;
        this.name = Objects.requireNonNull(name, "name must not be null");
        if (name.isBlank()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        this.price = Objects.requireNonNull(price, "price must not be null");
        if (price.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("price must not be negative: " + price);
        }
    }

    // accessors only — no setters
    public long id() { return id; }
    public String name() { return name; }
    public BigDecimal price() { return price; }
}
```

**Immutable fields:** All fields `private final`. No setters. If you need a modified copy, return a new instance.

```java
public Product withPrice(final BigDecimal newPrice) {
    return new Product(this.id, this.name, newPrice);
}
```

**Builder pattern — only when genuinely needed:**
- Use when constructors have many parameters (5+) and several are optional.
- The builder itself is mutable; the built object is immutable.
- Prefer constructors or static factory methods for types with few required fields.

```java
public final class SearchCriteria {
    private final String query;
    private final int maxResults;
    private final boolean caseSensitive;
    private final Set<String> tags;

    private SearchCriteria(final Builder builder) {
        this.query = Objects.requireNonNull(builder.query);
        this.maxResults = builder.maxResults;
        this.caseSensitive = builder.caseSensitive;
        this.tags = Set.copyOf(builder.tags);
    }

    public static final class Builder {
        private String query;
        private int maxResults = 25;
        private boolean caseSensitive = false;
        private final Set<String> tags = new HashSet<>();

        public Builder query(final String query) { this.query = query; return this; }
        public Builder maxResults(final int max) { this.maxResults = max; return this; }
        public Builder caseSensitive(final boolean cs) { this.caseSensitive = cs; return this; }
        public Builder addTag(final String tag) { this.tags.add(tag); return this; }

        public SearchCriteria build() { return new SearchCriteria(this); }
    }
}
```

**equals, hashCode, toString:**
- Use records when possible — they generate all three automatically.
- For POJOs: implement based on the fields that define identity/equality.
- Use `Objects.equals()` and `Objects.hash()` helpers.
- `toString()` for debugging: include class name and key fields. Effective Java Item 12.

**Static factory methods:**

```java
public final class Money {
    private final BigDecimal amount;
    private final Currency currency;

    private Money(final BigDecimal amount, final Currency currency) {
        this.amount = amount;
        this.currency = currency;
    }

    public static Money of(final BigDecimal amount, final Currency currency) {
        // validation, caching, or subtype selection
        return new Money(amount, currency);
    }

    public static Money usd(final BigDecimal amount) {
        return new Money(amount, Currency.USD);
    }
}
```

---

## Constants Best Practices

Constants belong in the class that uses them. No global `Constants.java`.

**Single-class constants:**

```java
public final class HttpStatusCodes {
    public static final int OK = 200;
    public static final int CREATED = 201;
    public static final int NOT_FOUND = 404;

    private HttpStatusCodes() {} // prevent instantiation
}
```

Wait — if these constants are only used by one class, they should be in that class:

```java
public final class ApiResponseHandler {
    private static final int OK = 200;
    private static final int CREATED = 201;
    private static final int NOT_FOUND = 404;

    // ... methods that use these constants
}
```

**Package-level constants classes — when shared within a package:**
- `final` class, `private` constructor, `static final` fields.
- Named descriptively: `BillingConstants`, not `Constants`.
- Only constants genuinely shared across multiple classes in the package.

**Enums for enumerated sets:**

```java
public enum OrderStatus {
    PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
}
```

Enums are type-safe, exhaustive (switch expressions with sealed types), and self-documenting. Prefer enums over `static final String` or `int` constants for enumerated values. Effective Java Item 34.

**Rules:**
- NEVER create a global `Constants.java` or `AppConstants.java`. Constants scatter across an unrelated grab-bag class.
- NEVER use constant interfaces (interfaces with only constants). Classes that implement the interface inherit the constants, polluting their API. Effective Java Item 22.
- Keep constants close to usage. A SQL table name constant belongs in the DAO, not a global file.
- Use `private static final` for class-internal constants. Use `public static final` only for constants that are part of the module's public API.

---

## Error Handling

Exceptions are for exceptional conditions, not control flow.

**Unchecked exceptions for programming errors:**
- `IllegalArgumentException` — bad method arguments.
- `IllegalStateException` — object in wrong state for the operation.
- `NullPointerException` — null where non-null is required (prefer `Objects.requireNonNull()`).
- `UnsupportedOperationException` — method not implemented.
- These indicate bugs in the caller's code. The caller cannot reasonably recover.

**Checked exceptions — only when the caller can reasonably recover:**
- File not found and the caller can try an alternate path.
- Network timeout and the caller can retry.
- If the caller cannot do anything useful, use an unchecked exception or wrap in a runtime exception.
- Checked exception abuse (forcing callers to catch-and-rethrow) is an anti-pattern. Effective Java Item 71.

**Never swallow exceptions:**

```java
// WRONG: swallowed exception — silent failure
try {
    processOrder(order);
} catch (final Exception e) {
    // nothing here — the bug is now invisible
}

// CORRECT: at minimum, log it
try {
    processOrder(order);
} catch (final OrderProcessingException e) {
    logger.error("Failed to process order {}: {}", order.id(), e.getMessage(), e);
    throw e; // or handle it meaningfully
}
```

**Optional over null returns:**

```java
// WRONG: null return forces null checks everywhere
public User findById(final long id) {
    // ...
    return null; // not found
}

// CORRECT: Optional makes absence explicit
public Optional<User> findById(final long id) {
    // ...
    return Optional.empty(); // not found
}
```

**Custom exception hierarchy (when needed):**

```java
// Module-level base exception
public class BillingException extends RuntimeException {
    public BillingException(final String message) { super(message); }
    public BillingException(final String message, final Throwable cause) { super(message, cause); }
}

// Specific exceptions
public final class InvoiceNotFoundException extends BillingException {
    public InvoiceNotFoundException(final long invoiceId) {
        super("Invoice not found: " + invoiceId);
    }
}
```

Effective Java Items 69-75 cover exception usage in depth.

---

## Access Modifiers

Access modifiers are documentation that the compiler enforces. Use the most restrictive level possible.

**private by default.** Every field, method, and inner class starts private. Widen only when necessary.

**Package-private for intra-module sharing.** Classes in the same package can access package-private members. Use this for implementation classes that serve other classes in the same feature package.

```java
// Package-private — accessible within the package, invisible outside
final class InvoiceValidator {
    boolean isValid(final Invoice invoice) { ... }
}
```

**public only for the module's API surface.** Interfaces, DTOs, exceptions, and enums that other modules consume.

**protected — rarely needed.** Only for methods designed to be overridden in a class designed for inheritance. Most classes should be `final`. Effective Java Item 19.

**Sealed classes and interfaces:**

```java
// Only these classes can extend Shape — compiler enforces
public sealed class Shape permits Circle, Rectangle, Triangle {
    // ...
}

public final class Circle extends Shape { ... }
public final class Rectangle extends Shape { ... }
public final class Triangle extends Shape { ... }
```

Sealed types restrict hierarchies at compile time. Use them when you know the complete set of subtypes. Switch expressions over sealed types are exhaustive — the compiler ensures all cases are handled.

**Rules:**
- `final` on classes that are not designed for extension. Most classes should be `final`. Effective Java Item 19.
- `private` on all fields. Always. No exceptions.
- `public` methods only on interfaces and on classes that implement public API contracts.
- Package-private classes for internal implementations. If a class is only used within its package, it should not be `public`.
- Avoid `protected` unless the class is explicitly designed for inheritance (and document that design).
