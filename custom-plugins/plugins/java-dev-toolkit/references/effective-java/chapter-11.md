# Chapter 11: Concurrency

Items 78-84. Thread safety, synchronization, and the `java.util.concurrent` library.
This chapter is foundational, but much of its advice on thread pools and low-level
synchronization is superseded by Java 21 virtual threads when combined with our
immutability-first philosophy.

> **Java 21+ Note:** Virtual threads (`Thread.ofVirtual()`,
> `Executors.newVirtualThreadPerTaskExecutor()`) fundamentally change the concurrency
> landscape for I/O-bound work. They are lightweight (millions can coexist), require
> no thread pool sizing, and eliminate the complexity of `ExecutorService` with fixed
> pools for most use cases. When combined with immutable data (no shared mutable state),
> virtual threads make most of the synchronization advice in this chapter unnecessary
> for typical application code. The items below remain essential for understanding the
> underlying model and for the cases where mutable shared state is unavoidable, but
> the default recommendation for new code is: **immutable data + virtual threads**.
> Use platform threads and manual synchronization only when you have a measured,
> CPU-bound workload that demands it.

---

### Item 78: Synchronize Access to Shared Mutable Data

**Takeaway:** Synchronization is needed not just for mutual exclusion but also for reliable communication between threads; without it, one thread's writes may never be visible to another.
**Maps to:** core-principles.md#concurrency, core-principles.md#immutability
**When to cite:** When a developer reads or writes a shared mutable field without synchronization or `volatile`, when reviewing a "stop" flag (boolean field checked by one thread and set by another) that lacks synchronization, when discussing the Java Memory Model and the happens-before relationship, when a developer uses `synchronized` for mutual exclusion but forgets that it also guarantees visibility, when recommending `volatile` for the simple case of a single field read/written atomically, or when reinforcing the primary defense: make the data immutable so synchronization is unnecessary. Note: on Java 21+, immutable data passed between virtual threads eliminates this concern entirely for most patterns.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item78/brokenstopthread/StopThread.java` (broken -- no synchronization), `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item78/fixedstopthread1/StopThread.java` (fixed with synchronized), `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item78/fixedstopthread2/StopThread.java` (fixed with volatile)

---

### Item 79: Avoid Excessive Synchronization

**Takeaway:** Inside synchronized regions, do not invoke alien methods (methods whose behavior you do not control); doing so risks deadlocks and data corruption. Move alien method calls outside the synchronized block.
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a developer calls a callback, listener, or overridable method from within a synchronized block, when reviewing an observable/observer pattern that notifies observers while holding a lock, when discussing the two approaches to fixing this (copy the list of observers before iterating, or use `CopyOnWriteArrayList`), when a developer synchronizes on a publicly accessible object (callers can cause deadlocks), when reviewing code where synchronization blocks contain more work than necessary, or when discussing the open-call principle (never hold a lock while calling into code you do not control).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item79/ObservableSet.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item79/SetObserver.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item79/ForwardingSet.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item79/Test1.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item79/Test2.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item79/Test3.java`

---

### Item 80: Prefer Executors, Tasks, and Streams to Threads

**Takeaway:** Do not work directly with `Thread`; use the `java.util.concurrent` executor framework which cleanly separates the unit of work (task) from the mechanism of execution.
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a developer creates `new Thread(runnable).start()` instead of submitting a task to an executor, when discussing the choice between `Executors.newCachedThreadPool()` (good for light loads), `Executors.newFixedThreadPool()` (good for heavy loads), and `Executors.newVirtualThreadPerTaskExecutor()` (good for I/O-bound work on Java 21+), when reviewing code that manually manages thread lifecycle, when a developer confuses threads (mechanism) with tasks (units of work), or when discussing `ForkJoinPool` for CPU-bound parallel decomposition. **Java 21+ update:** for I/O-bound work, `Executors.newVirtualThreadPerTaskExecutor()` is the default recommendation. It eliminates thread pool sizing decisions entirely.
**Source example:** No source example (Item 80 is prose-only in the source repository)

---

### Item 81: Prefer Concurrency Utilities to wait and notify

**Takeaway:** The higher-level concurrency utilities in `java.util.concurrent` (`ConcurrentHashMap`, `BlockingQueue`, `CountDownLatch`, `Semaphore`, `CyclicBarrier`) are strictly superior to `wait`/`notify`/`notifyAll`; use them instead.
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a developer uses `wait()` and `notify()` (use `CountDownLatch`, `Semaphore`, or `Phaser` instead), when reviewing code that uses `synchronized` + `wait` for thread coordination, when discussing `ConcurrentHashMap` vs. `Collections.synchronizedMap()` (the former is dramatically faster under contention), when introducing `CountDownLatch` for one-shot synchronization or `CyclicBarrier` for repeated synchronization, when reviewing code that uses `String.intern()` for concurrency (use `ConcurrentHashMap.computeIfAbsent()` instead), or when a developer needs to wait for multiple threads to complete (use a `CountDownLatch` or `ExecutorService.invokeAll()`).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item81/ConcurrentTimer.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item81/Intern.java`

---

### Item 82: Document Thread Safety

**Takeaway:** Every class should document its thread safety level: immutable, unconditionally thread-safe, conditionally thread-safe, not thread-safe, or thread-hostile.
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a class's Javadoc does not mention thread safety (callers cannot safely use it in concurrent code), when reviewing a class annotated with `@ThreadSafe` or `@NotThreadSafe` (or that should be), when a developer says "it's thread-safe" without specifying the lock protocol for conditionally thread-safe classes, when discussing the `synchronized` modifier on a method (which is an implementation detail, not a thread safety guarantee -- do not rely on it in documentation), when a class uses a private lock object (good practice) vs. synchronizing on `this` (allows denial-of-service by external code holding the lock), or when recommending `@Immutable`, `@ThreadSafe`, and `@NotThreadSafe` annotations from JSR-305 or similar.
**Source example:** No source example (Item 82 is prose-only in the source repository)

---

### Item 83: Use Lazy Initialization Judiciously

**Takeaway:** Do not use lazy initialization unless you need to; if you do, use the appropriate idiom: `synchronized` accessor for instance fields, holder class idiom for static fields, double-check idiom for performance-critical instance fields.
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a developer uses lazy initialization without a performance justification (eager initialization is simpler and usually sufficient), when reviewing a double-checked locking implementation (it must use `volatile`), when discussing the lazy initialization holder class idiom (the best approach for static fields -- the JVM guarantees thread-safe class initialization), when a developer writes broken double-checked locking without `volatile`, when a developer uses lazy initialization to break a circular dependency (a design smell -- fix the dependency, not the initialization order), or when reviewing `enum` lazy initialization (inherently thread-safe).
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item83/Initialization.java`, `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item83/FieldType.java`

---

### Item 84: Don't Depend on the Thread Scheduler

**Takeaway:** Programs that depend on the thread scheduler for correctness or performance are fragile and non-portable; use proper synchronization and do not rely on `Thread.yield()` or thread priorities.
**Maps to:** core-principles.md#concurrency, core-principles.md#simplicity
**When to cite:** When a developer uses `Thread.yield()` to fix a concurrency bug (it is a hint, not a guarantee), when reviewing code that sets thread priorities (priorities are platform-dependent and unreliable), when a developer uses busy-wait loops that spin until a condition becomes true (use proper synchronization primitives), when discussing the difference between a thread that has legitimate work to do and a thread that busy-waits consuming CPU, or when reviewing code that "works on my machine" but depends on timing that may not hold on different hardware or under load. **Java 21+ update:** virtual threads further reduce the relevance of thread scheduling concerns for I/O-bound work, since the runtime schedules them onto carrier threads transparently.
**Source example:** `repos/effective-java-3e-source-code/src/effectivejava/chapter11/item84/SlowCountDownLatch.java` (busy-wait anti-pattern)
