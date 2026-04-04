# Testing Guide

Reference for the **java-tester** agent. Java 21+ / OpenJDK. JUnit 5 exclusively.

---

## JUnit 5 Conventions

**Core annotations:**

```java
import org.junit.jupiter.api.*;

class UserServiceTest {

    private UserService userService;
    private UserDao userDao;

    @BeforeEach
    void setUp() {
        userDao = new InMemoryUserDao();
        userService = new UserService(userDao);
    }

    @AfterEach
    void tearDown() {
        // clean up resources if needed
    }

    @Test
    @DisplayName("should return user when valid ID exists")
    void findById_existingId_returnsUser() {
        // ...
    }
}
```

**@Nested for grouping related tests:**

```java
class OrderServiceTest {

    @Nested
    @DisplayName("when creating orders")
    class CreateOrder {

        @Test
        @DisplayName("should create order with valid items")
        void validItems_createsOrder() { ... }

        @Test
        @DisplayName("should reject empty item list")
        void emptyItems_throwsException() { ... }
    }

    @Nested
    @DisplayName("when cancelling orders")
    class CancelOrder {

        @Test
        @DisplayName("should cancel pending order")
        void pendingOrder_cancelsSuccessfully() { ... }

        @Test
        @DisplayName("should reject cancellation of shipped order")
        void shippedOrder_throwsException() { ... }
    }
}
```

**Parameterized tests:**

```java
@ParameterizedTest
@ValueSource(strings = {"", " ", "  "})
@DisplayName("should reject blank names")
void create_blankName_throwsException(final String name) {
    assertThrows(IllegalArgumentException.class, () -> new User(1L, name, "a@b.com"));
}

@ParameterizedTest
@CsvSource({
    "100, 10, 10.00",
    "200, 15, 13.33",
    "0, 1, 0.00"
})
@DisplayName("should calculate average correctly")
void calculateAverage_variousInputs_returnsExpected(
        final int total, final int count, final BigDecimal expected) {
    assertEquals(expected, calculator.average(total, count));
}

@ParameterizedTest
@MethodSource("invalidEmailProvider")
@DisplayName("should reject invalid email formats")
void create_invalidEmail_throwsException(final String email) {
    assertThrows(IllegalArgumentException.class, () -> new User(1L, "name", email));
}

static Stream<String> invalidEmailProvider() {
    return Stream.of(null, "", "no-at-sign", "@no-local", "spaces in@email.com");
}
```

**Test lifecycle:**
- `@BeforeEach` runs before every `@Test` method. Use for per-test setup.
- `@AfterEach` runs after every `@Test` method. Use for cleanup.
- `@BeforeAll` / `@AfterAll` (static methods) run once per test class. Use for expensive setup (database containers, server startup). Avoid for mutable shared state.
- Each `@Test` method should be independently runnable. No test should depend on another test's execution.

---

## Test Naming

Two acceptable patterns. Be consistent within a project.

**Pattern 1: method_state_expected**

```java
findById_existingId_returnsUser()
findById_nonExistentId_returnsEmpty()
create_nullName_throwsIllegalArgument()
transfer_insufficientFunds_throwsException()
```

**Pattern 2: @DisplayName with descriptive method names**

```java
@Test
@DisplayName("should return user when valid ID exists")
void returnsUserForExistingId() { ... }

@Test
@DisplayName("should return empty when ID does not exist")
void returnsEmptyForNonExistentId() { ... }
```

**Rules:**
- Test names describe the behavior being verified, not the implementation.
- Avoid `test` prefix — JUnit 5 does not require it.
- Group related tests with `@Nested` classes and give the nested class a `@DisplayName`.

---

## When to Mock (Mockito)

Mock **only at boundaries**: external APIs, third-party services, infrastructure you do not own.

**Legitimate mock targets:**
- External HTTP APIs (payment gateways, email services, third-party REST endpoints).
- Message brokers you do not control.
- System clock (`Clock` — inject and mock for time-sensitive tests).
- File system operations when testing logic, not I/O.

**Mockito setup:**

```java
@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {

    @Mock
    private PaymentGateway paymentGateway; // external service — mock it

    @InjectMocks
    private PaymentService paymentService;

    @Test
    @DisplayName("should process payment via gateway")
    void processPayment_validCard_succeeds() {
        when(paymentGateway.charge(any(PaymentRequest.class)))
            .thenReturn(new PaymentResponse("txn-123", PaymentStatus.SUCCESS));

        final var result = paymentService.processPayment(card, amount);

        assertEquals(PaymentStatus.SUCCESS, result.status());
        verify(paymentGateway).charge(any(PaymentRequest.class));
    }
}
```

**mockStatic() — legacy code only:**

```java
try (var mockedStatic = Mockito.mockStatic(LegacyUtil.class)) {
    mockedStatic.when(() -> LegacyUtil.getCurrentTimestamp()).thenReturn(fixedTimestamp);
    // test code that calls LegacyUtil.getCurrentTimestamp()
}
```

`mockStatic` is a smell. It means the code under test has a static dependency that should be injected. Use it only when refactoring the legacy code is not in scope.

---

## When NOT to Mock

Do **not** mock your own classes, repositories, or services.

**Your own repositories:** Use in-memory implementations or real test databases.

```java
// In-memory implementation for tests — implements the same interface
public final class InMemoryUserDao implements UserDao {
    private final Map<Long, User> store = new HashMap<>();
    private long nextId = 1L;

    @Override
    public Optional<User> findById(final long id) {
        return Optional.ofNullable(store.get(id));
    }

    @Override
    public User save(final User user) {
        final var saved = new User(nextId++, user.name(), user.email(), Instant.now());
        store.put(saved.id(), saved);
        return saved;
    }

    @Override
    public void deleteById(final long id) {
        store.remove(id);
    }

    @Override
    public List<User> findAll() {
        return List.copyOf(store.values());
    }
}
```

**Your own services:** Wire them with real (or in-memory) dependencies.

```java
@BeforeEach
void setUp() {
    // Real service, real (in-memory) DAO — no mocks
    final var userDao = new InMemoryUserDao();
    final var emailValidator = new EmailValidator();
    userService = new UserService(userDao, emailValidator);
}
```

**Why no mocking of your own code:**
- Mocking your own code tests the interaction, not the behavior. The test passes even if the implementation is wrong.
- If your test requires mocking 5 of your own classes, the design needs improvement (too many dependencies, not enough interfaces).
- Real implementations catch real bugs. Mocks hide them.

---

## Unit Test Strategy

Fast, isolated, one behavior per test.

**Arrange-Act-Assert pattern:**

```java
@Test
@DisplayName("should calculate total with tax")
void calculateTotal_withTax_includesTaxAmount() {
    // Arrange
    final var item = new LineItem("Widget", new BigDecimal("10.00"), 3);
    final var taxRate = new BigDecimal("0.08");

    // Act
    final var total = calculator.calculateTotal(List.of(item), taxRate);

    // Assert
    assertEquals(new BigDecimal("32.40"), total);
}
```

**Test boundary conditions:**
- Empty collections, null inputs (when the API permits null), zero values.
- Minimum and maximum valid values.
- Off-by-one: first element, last element, one past the end.
- Single-element collections.

**Test error paths:**
- Invalid arguments throw expected exceptions.
- Missing data returns `Optional.empty()` or throws a specific exception.
- Failure conditions are handled, not swallowed.

```java
@Test
@DisplayName("should throw when user ID is negative")
void findById_negativeId_throwsIllegalArgument() {
    assertThrows(IllegalArgumentException.class, () -> userService.findById(-1L));
}

@Test
@DisplayName("should return empty when user does not exist")
void findById_nonExistentId_returnsEmpty() {
    final var result = userService.findById(999L);
    assertTrue(result.isEmpty());
}
```

**Rules:**
- One logical assertion per test. `assertAll()` is acceptable for verifying multiple fields of one result.
- No test should depend on another test's execution or state.
- Tests should be fast. If a unit test takes more than 100ms, something is wrong (probably I/O that should be replaced with an in-memory implementation).
- Do not test private methods. Test the public behavior that exercises them.

---

## Integration Test Strategy

Tests that verify multiple components work together through real infrastructure.

**Real databases — H2 or Testcontainers:**

```java
// H2 in-memory database for fast integration tests
class UserJdbcDaoIntegrationTest {

    private DataSource dataSource;
    private UserJdbcDao userDao;

    @BeforeEach
    void setUp() throws SQLException {
        dataSource = new org.h2.jdbcx.JdbcDataSource();
        ((org.h2.jdbcx.JdbcDataSource) dataSource).setURL("jdbc:h2:mem:test;DB_CLOSE_DELAY=-1");

        try (var conn = dataSource.getConnection();
             var stmt = conn.createStatement()) {
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    email VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP NOT NULL
                )
                """);
        }

        userDao = new UserJdbcDao(dataSource);
    }

    @AfterEach
    void tearDown() throws SQLException {
        try (var conn = dataSource.getConnection();
             var stmt = conn.createStatement()) {
            stmt.execute("DROP TABLE IF EXISTS users");
        }
    }

    @Test
    @DisplayName("should persist and retrieve a user")
    void saveAndFindById_roundTrip_succeeds() {
        final var saved = userDao.save(new User(0, "Alice", "alice@example.com", Instant.now()));
        final var found = userDao.findById(saved.id());
        assertTrue(found.isPresent());
        assertEquals("Alice", found.get().name());
    }
}
```

**Testcontainers for production-like databases:**

```java
@Testcontainers
class UserDaoPostgresTest {

    @Container
    static final PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine");

    private DataSource dataSource;

    @BeforeEach
    void setUp() {
        final var ds = new PGSimpleDataSource();
        ds.setUrl(postgres.getJdbcUrl());
        ds.setUser(postgres.getUsername());
        ds.setPassword(postgres.getPassword());
        dataSource = ds;
        // run migrations...
    }
}
```

**Full request path tests:**
- Start an embedded HTTP server (Javalin, Jetty, or `com.sun.net.httpserver`).
- Use `java.net.http.HttpClient` to send real HTTP requests.
- Verify the full path: HTTP request -> handler -> service -> DAO -> database -> response.

**Integration test organization:**
- Separate source set: `src/integrationTest/java/`.
- Separate Gradle task so they do not run with `test` (they are slower).
- Tag with `@Tag("integration")` for selective execution.

---

## Contract Test Design

Tests that verify interface contracts between modules.

**The problem:** Module A depends on interface `UserDao`. Module B provides `UserJdbcDao` implementing `UserDao`. How do you ensure B's implementation honors A's expectations?

**Abstract contract test:**

```java
// Lives in the module that defines the interface (or a shared test module)
public abstract class UserDaoContractTest {

    protected abstract UserDao createDao();

    @Test
    @DisplayName("save should assign an ID and persist the user")
    void save_newUser_assignsIdAndPersists() {
        final var dao = createDao();
        final var saved = dao.save(new User(0, "Alice", "alice@example.com", Instant.now()));

        assertTrue(saved.id() > 0);

        final var found = dao.findById(saved.id());
        assertTrue(found.isPresent());
        assertEquals("Alice", found.get().name());
    }

    @Test
    @DisplayName("findById should return empty for non-existent ID")
    void findById_nonExistent_returnsEmpty() {
        final var dao = createDao();
        assertTrue(dao.findById(999L).isEmpty());
    }

    @Test
    @DisplayName("deleteById should remove the user")
    void deleteById_existingUser_removesUser() {
        final var dao = createDao();
        final var saved = dao.save(new User(0, "Bob", "bob@example.com", Instant.now()));
        dao.deleteById(saved.id());
        assertTrue(dao.findById(saved.id()).isEmpty());
    }
}
```

**Concrete contract test in the implementing module:**

```java
// In the module that provides UserJdbcDao
class UserJdbcDaoContractTest extends UserDaoContractTest {

    private DataSource dataSource;

    @BeforeEach
    void setUp() throws SQLException {
        dataSource = createH2DataSource();
        runMigrations(dataSource);
    }

    @Override
    protected UserDao createDao() {
        return new UserJdbcDao(dataSource);
    }
}
```

**Also works for in-memory implementations:**

```java
class InMemoryUserDaoContractTest extends UserDaoContractTest {

    @Override
    protected UserDao createDao() {
        return new InMemoryUserDao();
    }
}
```

**When to write contract tests:**
- When a module defines an interface that another module implements.
- When you provide multiple implementations of the same interface (JDBC, in-memory, cache-backed).
- For API consumer/provider contracts: the provider must honor what the consumer expects.

---

## Test Fixtures

Setup patterns for test data.

**@BeforeEach for per-test setup:**

```java
@BeforeEach
void setUp() {
    userDao = new InMemoryUserDao();
    userService = new UserService(userDao);
}
```

Every test gets a fresh instance. No shared mutable state between tests.

**Test data builders for complex objects:**

```java
public final class TestUsers {

    private TestUsers() {}

    public static User alice() {
        return new User(1L, "Alice", "alice@example.com", Instant.parse("2025-01-01T00:00:00Z"));
    }

    public static User bob() {
        return new User(2L, "Bob", "bob@example.com", Instant.parse("2025-01-02T00:00:00Z"));
    }

    public static User withName(final String name) {
        return new User(0L, name, name.toLowerCase() + "@example.com", Instant.now());
    }
}
```

**Factory methods over @BeforeAll shared state:**
- `@BeforeAll` creates shared state across all tests in the class. If any test mutates it, other tests break.
- Factory methods create fresh objects per test. Immutability applies to test code too.
- If shared setup is expensive (database container), use `@BeforeAll` for infrastructure only, and reset data in `@BeforeEach`.

**Rules:**
- Never use mutable static fields in test classes.
- Prefer creating fresh test data in each test or in `@BeforeEach`.
- Test data builders should produce valid default objects. Tests override only the fields relevant to the test case.
- Keep fixture code in a dedicated test-support package or class (`TestUsers`, `TestOrders`).

---

## Assertions

**JUnit 5 assertions:**

```java
import static org.junit.jupiter.api.Assertions.*;

// Equality
assertEquals(expected, actual);
assertEquals(expected, actual, "message on failure");

// Boolean
assertTrue(condition);
assertFalse(condition);

// Null
assertNull(value);
assertNotNull(value);

// Exceptions
assertThrows(IllegalArgumentException.class, () -> service.process(null));

// Grouped assertions — all execute, all failures reported
assertAll(
    () -> assertEquals("Alice", user.name()),
    () -> assertEquals("alice@example.com", user.email()),
    () -> assertNotNull(user.createdAt())
);

// Timeout
assertTimeout(Duration.ofSeconds(2), () -> service.longRunningOperation());
```

**AssertJ for fluent assertions (when JUnit's are limiting):**

```java
import static org.assertj.core.api.Assertions.*;

// Collection assertions
assertThat(users).hasSize(3);
assertThat(users).extracting(User::name).containsExactly("Alice", "Bob", "Charlie");
assertThat(users).filteredOn(u -> u.isActive()).hasSize(2);

// String assertions
assertThat(result).startsWith("Error").contains("not found");

// Exception assertions
assertThatThrownBy(() -> service.process(null))
    .isInstanceOf(IllegalArgumentException.class)
    .hasMessageContaining("must not be null");

// Optional assertions
assertThat(userService.findById(1L)).isPresent().get().extracting(User::name).isEqualTo("Alice");
assertThat(userService.findById(999L)).isEmpty();
```

**Rules:**
- Never `assertTrue(a.equals(b))` — use `assertEquals(a, b)`. The former gives a useless failure message ("expected true, got false").
- Never `assertTrue(list.contains(x))` — use AssertJ's `assertThat(list).contains(x)` for a meaningful failure message.
- Use `assertAll()` when verifying multiple properties of one result. All assertions execute; all failures report.
- Put the expected value first in `assertEquals(expected, actual)`.

---

## Coverage Philosophy

Behavioral coverage over line coverage.

**What matters:**
- Every public behavior of the class is tested (happy path, edge cases, error paths).
- Critical business logic has thorough tests.
- Contract tests verify interface implementations honor their contracts.
- Error handling paths are tested (exceptions are thrown when expected, error responses are correct).

**What does NOT matter:**
- Hitting every line. A line touched by a test is not necessarily tested — the test might not assert anything meaningful about it.
- Getters/setters (for POJOs where accessors are trivial). Test them indirectly through behavior tests.
- 100% line coverage with bad tests is worse than 80% coverage with good tests. A test that calls a method and asserts nothing is worse than no test.

**Coverage as a signal, not a target:**
- Low coverage (below 60%) signals missing tests.
- High coverage (above 90%) does not signal quality — inspect what the tests actually verify.
- Use coverage reports to find untested behaviors, not to chase a number.

**What to test with high priority:**
1. Business logic and domain rules.
2. Data validation and transformation.
3. Error handling and edge cases.
4. Interface contract compliance.
5. Concurrency-sensitive code (if any mutable shared state exists).

**What to test with lower priority:**
1. Simple delegation methods (A calls B and returns the result).
2. Configuration and wiring (tested implicitly by integration tests).
3. Framework-generated code (records' `equals`/`hashCode` — trust the compiler).
