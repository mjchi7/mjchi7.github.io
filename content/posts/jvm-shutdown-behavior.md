---

title: "JVM Shutdown Sequence and Spring Boot's Shutdown Hook"

date: 2025-11-15T11:26:25+08:00

tags: []

draft: false

summary: JVM shutdown behavior and how Spring Boot ensure destroy methods are invoked during shutdown

---

## Overview

In this article, we'll look at the JVM shutdown behavior. Specifically, we'll learn about the specific process the JVM undertakes during a graceful shutdown. Additionally, we'll learn how Spring Boot hooks into this behavior to ensure beans are properly cleaned up during graceful shutdown.

## Graceful vs. Non-graceful Shutdown
Generally speaking, applications can be shut down in a graceful and non-graceful (a.k.a. forceful shutdown) way. 

Visually:

![graceful-vs-nongraceful-shutdown](../../images/jvm-shutdown-behavior/graceful-vs-nongraceful-shutdown.png)

### Graceful Shutdown
During a graceful shutdown, the application process itself is made aware that there’s an intention to shut down. Then, it initiates a series of processes to stop accepting new tasks and finalize the running tasks. 

To trigger a graceful shutdown, we typically send POSIX signals, such as `SIGINT` and `SIGTERM`, to the application process.

Crucially, **graceful shutdown prevents any partially processed tasks that might lead to data corruption**. Concretely, it gives the application process an opportunity to run cleanup tasks before yielding to the kernel for the final cleanup. 

In most cases, a graceful shutdown comes with a timeout. Beyond the graceful duration, a non-graceful shutdown will be initiated.

### Non-graceful Shutdown
Non-graceful shutdown of an application means that the **application process get terminated immediately without a chance to run its usual shutdown sequence**. 

For instance, we can instantly kill off an application process in Linux using the `kill -9 $PID` command. The command sends the `SIGKILL` signal to the process.

Upon receiving the `SIGKILL` signal, the kernel stops scheduling the target process. Subsequently, it begins reclaiming all the resources of the application process.

**Importantly, the application proess is entirely unaware of the termination throughout the entire forceful shutdown**. As a result, the application process cannot anticipate the signal and run any cleanup processes. 

## JVM Shutdown Sequence
In the JVM Runtime specification, the documentation clearly defines the trigger for the shutdown, as well as the shutdown sequence itself.

Visually:

![jvm-shutdown-sequence-and-triggers](../../images/jvm-shutdown-behavior/jvm-shutdown-sequence-and-triggers.png)

### Triggers
When one of the following events happens, the JVM initiates the shutdown sequence:

1. When there aren't any live non-daemon threads.
2. When the `System.exit` is invoked
3. When the JVM processes receive signals from the OS. In a POSIX system, signals like `SIGINT` and `SIGTERM` trigger the shutdown process.

### Shutdown Sequence
1. Starts all shutdown hooks concurrently
2. Wait for all the shutdown hooks to return.
3. Calls `Runtime.halt()`
4. Kernel-level process termination (i.e., clearing scheduling queue, reclaiming resources).

## Thread Interruption During Shutdown?
A commonly misunderstood aspect of the JVM shutdown sequence is that the JVM Runtime will interrupt (using the `interrupt()` method) all the living, non-daemon threads as part of the shutdown process.

However, as we can see from the documentation, the shutdown process does not interrupt the non-daemon threads during its shutdown sequence.

If we have running threads that needs to be interrupted during the shutdown so that it can be cleaned up, it's important to ensure that a shutdown hook is installed that invoke the `interrupt` method on the thread.

### Interrupting Threads Using Shutdown Hook
To visualize the difference, we'll create two examples.

The first example shows that without installing a shutdown hook, no `InterruptedException` will be thrown in our processing during shutdown:

```java
public class NoShutdownHookDemo {

    public static void main(String[] args) throws Exception {

        Thread worker = new Thread(() -> {
            try {
                System.out.println("[Worker] Started. Going to sleep...");
                Thread.sleep(10_000);
                System.out.println("[Worker] Woke up normally.");
            } catch (InterruptedException e) {
                System.out.println("[Worker] Interrupted!");
            }
        });
        worker.start();
        System.out.println("[Main] Press Ctrl+C now...");
        worker.join();
    }
}
```
Running the code above, we'll get the following output:

```text
[Main] Press Ctrl+C now...
[Worker] Started. Going to sleep...
```

Next, we'll register a shutdown hook that interrupts our worker thread:

```java
public class WithShutdownHookDemo {

    public static void main(String[] args) throws Exception {
        Thread worker = new Thread(() -> {
            try {
                System.out.println("[Worker] Started. Going to sleep...");
                Thread.sleep(10_000);
                System.out.println("[Worker] Woke up normally.");
            } catch (InterruptedException e) {
                System.out.println("[Worker] Interrupted! Cleaning up...");
            }
        });

        // Register shutdown hook that interrupts worker thread
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            System.out.println("[ShutdownHook] JVM shutting down. Interrupting worker...");
            worker.interrupt();
        }));
        worker.start();
        System.out.println("[Main] Press Ctrl+C now...");
        worker.join();
    }
}
```

Subsequently, when we run the program and send a `SIGINT` signal using `CTRL+C`, we'll observe the following output:

```text
[Main] Press Ctrl+C now...
[Worker] Started. Going to sleep...
^C[ShutdownHook] JVM shutting down. Interrupting worker...
[Worker] Interrupted! Cleaning up...
```

## Spring Boot Shutdown and JVM Shutdown Hook
To the application context in Spring Boot is aware of the shutdown, [Spring Boot registers a JVM shutdown hook](https://docs.spring.io/spring-boot/reference/features/spring-application.html#features.spring-application.application-exit) for each of the `SpringApplication`. The shutdown hook registered will invoke the appropriate destruction lifecycle methods when the shutdown hook is invoked during the JVM shutdown sequence.

For example, the Spring Boot shutdown logic will call the `destroy` method on beans that implement the [`DisposableBean`](https://docs.spring.io/spring-framework/docs/6.2.x/javadoc-api/org/springframework/beans/factory/DisposableBean.html) interface.  

Besides that, the shutdown hook also invokes the methods that are annotated with the [`@PreDestroy`](https://jakarta.ee/specifications/annotations/2.1/apidocs/jakarta/annotation/PreDestroy.html) annotation.

## Conclusion
In this article, we've learned that JVM invokes and wait on all the shutdown hooks as part of its shutdown process. Importantly, we've seen that non-daemon threads by default are not interrupted by the Runtime during the usual shutdown sequence.

Additionally, we've learned that in Spring application registers a shutdown hook with the JVM so that they gets notified about the JVM shutdown event. This hook, in turn, initiates the context shutdown process, which includes invoking methods annotated with the `@PreDestory` annotation, and calling the `destroy` method on classes that implement the `DisposableBean` interface.