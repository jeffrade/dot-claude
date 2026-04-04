# Chapter 10: Exceptions

Items 69-77. Exception handling done right: when to throw, what to throw, how to
document, and how to recover. Exceptions are a powerful mechanism for shifting error
detection left, but only when used according to their intended purpose.

---

### Item 69: Use Exceptions Only for Exceptional Conditions

**Takeaway:** Never use exceptions for ordinary control flow; they are designed for unexpected conditions, and using them otherwise obscures intent and degrades performance.
**Maps to:** core-principles.md#simplicity, core-principles.md#shift-left
**When to cite:** When a developer uses try-catch as a control flow mechanism (e.g., catching `ArrayIndexOutOfBoundsException` to terminate a loop instead of checking the array length), when reviewing code that uses exceptions to implement iteration termination, state machine transitions, or conditional branching, when discussing the performance cost of exception creation (capturing the stack trace), when a developer relies on exceptions from an API that should provide a state-testing method (like `Iterator.hasNext()`) or an optional return value, or when an API forces callers to use try-catch for non-exceptional conditions (poor API design).
**Source example:** No source example (Item 69 is prose-only in the source repository)

---

### Item 70: Use Checked Exceptions for Recoverable Conditions and Runtime Exceptions for Programming Errors

**Takeaway:** Checked exceptions signal recoverable conditions the caller should handle; runtime exceptions signal programming errors (bugs) that the caller cannot reasonably recover from.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer throws a checked exception for a programming error (e.g., checked exception for invalid arguments), when a developer throws a runtime exception for a recoverable condition (e.g., `RuntimeException` for "file not found" when the caller could retry or prompt the user), when reviewing custom exception classes to verify they extend the correct base class, when discussing the three kinds of throwables (checked exceptions, runtime exceptions, errors) and when to use each, or when a developer creates a throwable that extends `Error` (never do this -- `Error` is reserved for JVM-level problems like `OutOfMemoryError`).
**Source example:** No source example (Item 70 is prose-only in the source repository)

---

### Item 71: Avoid Unnecessary Use of Checked Exceptions

**Takeaway:** If the caller cannot reasonably recover from the exception, or if the only possible response is logging and moving on, use an unchecked exception; checked exceptions are only justified when the API provides sufficient information for meaningful recovery.
**Maps to:** core-principles.md#simplicity, core-principles.md#shift-left
**When to cite:** When every catch block in the codebase for a given checked exception just wraps it in a `RuntimeException` and rethrows (a sign the exception should have been unchecked), when a developer adds a checked exception to a method that is used in streams or lambdas (checked exceptions and functional interfaces do not mix well), when reviewing an API that throws checked exceptions the caller has no way to handle, when discussing the two-question test: (1) can the caller recover? and (2) does the exception carry enough information for recovery?, or when a single-method interface with a checked exception cannot be used as a lambda target.
**Source example:** No source example (Item 71 is prose-only in the source repository)

---

### Item 72: Favor the Use of Standard Exceptions

**Takeaway:** Reuse the standard JDK exception types (`IllegalArgumentException`, `IllegalStateException`, `NullPointerException`, `UnsupportedOperationException`, `ConcurrentModificationException`, `IndexOutOfBoundsException`) instead of creating custom exceptions for common error conditions.
**Maps to:** core-principles.md#simplicity
**When to cite:** When a developer creates a custom exception for a condition already covered by a standard exception, when reviewing which standard exception to use (illegal argument vs. illegal state -- if no argument value would have worked, it is illegal state), when discussing `UnsupportedOperationException` for optional operations in collection implementations, when a developer creates `InvalidParameterException` instead of using `IllegalArgumentException`, or when recommending the table of standard exceptions and their conventional uses.
**Source example:** No source example (Item 72 is prose-only in the source repository)

---

### Item 73: Throw Exceptions Appropriate to the Abstraction

**Takeaway:** Higher layers should translate lower-level exceptions into exceptions appropriate to their abstraction level (exception translation); include the original exception as the cause (exception chaining).
**Maps to:** core-principles.md#monolithic-deployment-modular-code, core-principles.md#simplicity
**When to cite:** When a low-level exception (e.g., `SQLException`) propagates through a service layer to the API layer (leaking implementation details), when reviewing exception handling that loses the original cause (always use `new HighLevelException(lowLevelCause)`), when a developer catches and rethrows without wrapping, when discussing the tension between exception translation (correct) and mindless exception tunneling (wrapping everything in `RuntimeException` without thought), or when a module boundary leaks internal exception types that callers should not know about.
**Source example:** No source example (Item 73 is prose-only in the source repository)

---

### Item 74: Document All Exceptions Thrown by Each Method

**Takeaway:** Use `@throws` Javadoc tags to document every exception a method can throw, both checked and unchecked; document the conditions under which each exception is thrown.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a public method's Javadoc does not document its exceptions, when a developer uses `@throws` for checked exceptions but omits unchecked ones (document both), when reviewing API documentation for completeness, when the conditions triggering each exception are not specified (just listing the type is insufficient -- explain when it is thrown), or when a developer uses `throws Exception` in the method signature (never throw or declare the generic `Exception` class).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter10/item74/IndexOutOfBoundsException.java`

---

### Item 75: Include Failure-Capture Information in Detail Messages

**Takeaway:** Exception detail messages should contain the values of all parameters and fields that contributed to the failure, enabling diagnosis without reproducing the problem.
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When an exception message says "invalid input" without specifying what the input was, when reviewing `IndexOutOfBoundsException` that does not include the index, lower bound, and upper bound, when a developer throws `IllegalArgumentException` without including the invalid argument value in the message, when discussing the distinction between user-facing error messages (localized, friendly) and exception detail messages (technical, diagnostic), or when reviewing log output that contains exception messages lacking actionable information.
**Source example:** No source example (Item 75 is prose-only in the source repository, though Item 74's source demonstrates the pattern)

---

### Item 76: Strive for Failure Atomicity

**Takeaway:** A failed method invocation should leave the object in the state it was in before the invocation; this is easiest to achieve with immutable objects (which are failure-atomic by nature).
**Maps to:** core-principles.md#immutability, core-principles.md#shift-left
**When to cite:** When a method mutates an object's state before validating that the operation can succeed (partial mutation followed by exception = inconsistent state), when reviewing methods on mutable objects that do not restore state on failure, when discussing the four approaches to failure atomicity (immutable objects, check before mutation, temporary copy, recovery code), when a developer's code leaves an object in an inconsistent state after throwing an exception, or when reinforcing the immutability principle (immutable objects achieve failure atomicity for free).
**Source example:** No source example (Item 76 is prose-only in the source repository)

---

### Item 77: Don't Ignore Exceptions

**Takeaway:** An empty catch block defeats the purpose of exceptions; at minimum, log the exception with a comment explaining why it is safe to ignore (if it truly is).
**Maps to:** core-principles.md#shift-left, core-principles.md#simplicity
**When to cite:** When a developer writes an empty catch block, when reviewing catch blocks that swallow exceptions without logging or rethrowing, when a `catch (Exception e) {}` hides bugs that would otherwise surface immediately, when discussing the rare cases where ignoring an exception is truly justified (closing a read-only stream where failure has no consequence -- and even then, log at debug level), or when a developer catches `InterruptedException` and does nothing (restore the interrupt flag with `Thread.currentThread().interrupt()`).
**Source example:** No source example (Item 77 is prose-only in the source repository)
