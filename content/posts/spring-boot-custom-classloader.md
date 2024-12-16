---
title: "Spring Boot Nested JAR: When ForkJoinPool Misses the ClassLoader Party!"
date: 2024-12-14T10:50:39+08:00
draft: true
---

## Overview
In this article, we'll explore the problem when using the `ForkJoinPool` in a Spring Boot JAR application. Specifically, we'll understand why threads in the `ForkJoinPool` cannot load classes from dependent library JARs while threads created using `ExecutorService` don't face the same issue.

The root cause lies in the Spring Boot nested JAR structure and the class loaders used. We'll discuss how the `ForkJoinPool` uses the system class loader, why it lacks visibility into Spring Boot's nested JARs, and how the Spring Boot's custom `LauncherURLClassLoader` helps.

By the end, we'll also learn why we don't face the same issue with `ForkJoinPool` when running our Spring Boot application without packaging it as a JAR file (i.e. `./mvnw spring-boot:run`).

## Problem Statement
Let's start with a simple demonstration. Imagine a Spring Boot application that uses both `ForkJoinPool` and `ExecutorService` to load a class dynamically from a dependent library:

```java
@SpringBootApplication
public class ClassLoaderDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(ClassLoaderDemoApplication.class, args);

        // ExecutorService Test
        ExecutorService executorService = Executors.newFixedThreadPool(1);
        executorService.submit(() -> {
            try {
                System.out.println("ExecutorService ClassLoader: " + Thread.currentThread().getContextClassLoader());
                Class<?> clazz = Class.forName("com.example.dependency.SomeLibraryClass");
                System.out.println("ExecutorService Loaded: " + clazz);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });

        // ForkJoinPool Common Pool Test
        ForkJoinPool.commonPool().submit(() -> {
            try {
                System.out.println("ForkJoinPool ClassLoader: " + Thread.currentThread().getContextClassLoader());
                Class<?> clazz = Class.forName("com.example.dependency.SomeLibraryClass");
                System.out.println("ForkJoinPool Loaded: " + clazz);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }
}
```

The simple class define a simple Spring Boot application. The application on start up, first creates an `ExecutorService` and run a task asynchronously to dynamically load the `com.example.dependency.SomeLibraryClass`. Later, we submit the same task to the `ForkJoinPool#commonPool`. 

Notably, the `com.example.dependency.SomeLibraryClass` is a class that exists on a dependent library JAR file. 

When we package the application into a JAR file and run it, we'll get the following output:

```bash
ExecutorService ClassLoader: org.springframework.boot.loader.LaunchedURLClassLoader
ExecutorService Loaded: class com.example.dependency.SomeLibraryClass
ForkJoinPool ClassLoader: java.lang.ClassLoader$AppClassloader
java.lang.ClassNotFoundException: com.example.dependency.SomeLibraryClass
```

There are a few observations we can make from the output:

1. The `ExecutorService` thread uses the `LaunchedURLClassLoader` and successfully loads the class.
2. The `ForkJoinPool` common pool thread uses the `AppClassloader`, a.k.a. system class loader and fails to load the class. 

Based on these observations, two prominent questions pop up:
1. Why are two different classloader being used?
2. Why can't the `AppClassloader` sees the class in the dependent JAR file?

To answer the questions, we'll first need to understand the Spring Boot nested JAR structure

## Spring Boot Nested JAR Structure
One of the standing problem with Java is that there isn't a standard way to load nested JAR files (e.g. our application is a JAR file that contains more JAR files due to dependencies).

Conventionally, many developers choose to packages all the classes from all the JARs files into a single uber JAR. The problem with this approach is that it might cause filename conflicts and hard to see which libraries are actually in the application.

Spring Boot opt for a different approach. Specifically, Spring Boot packages applications into a nested JAR structure with the following structure.

```plain
my-app.jar
 |
 +-META-INF
 |  +-MANIFEST.MF
 +-org
 |  +-springframework
 |     +-boot
 |        +-loader
 |           +-<spring boot loader classes>
 +-BOOT-INF
    +-classes
    |  +-mycompany
    |     +-project
    |        +-YourClasses.class
    +-lib
       +-dependency1.jar
       +-dependency2.jar
```

Notably, all the dependent library JARs are in the Spring Boot specific directory, `BOOT-INF`.

Due to the unique structure, Spring Boot application requires a custom class loader, `LaunchedURLClassLoader` to loads all the classes in the `BOOT-INF/lib`. This is because the Java's `AppClassloader` wouldn't know about the Spring Boot specific's `BOOT-INF` directory within the JAR file.

## AppClassloader Visibility in Spring Boot JAR
In our earlier example that involves the `ForkJoinPool#commonPool()` and the `ExecutorService`, we can see that the former uses the `AppClassloader` and the latter uses the custom `LaunchedURLClassLoader`. 

At this point, it should become obvious why the `AppClassloader` that is used by the `ForkJoinPool`'s common pool cannot sees the class that is in the dependent library JAR. To re-iterate, it's because Spring Boot packages the dependent library JAR into the `BOOT-INF/lib` that the Java's `AppClassloader` doesn't know about.

## ForkJoinPool's Common Pool Initialization Sequence
The reason why the `ForkJoinPool`'s common pool doesn't use the custom `LaunchedURLClassLoader` from Spring Boot is because the common pool in `ForkJoinPool` is instantiated in the static block of the class itself. 

For thread to inherit the `LaunchedURLClassLoader`, they must be created after the `main` method is executed. This is because the `LaunchedURLClassLoader` is set as the context class loader for the main thread after the `main` method is invoked.

## Why Doesn't This Affect `./mvnw spring-boot:run`?
If we run the application without first package it into a JAR file (i.e. invoking it on the terminal using `./mvnw spring-boot:run`), we can see that both code section execute successfully. 

The reason is because when we run our Spring Boot application using `./mvnw spring-boot:run`, we're running the application in the exploded classpath mode. In other words, the command specifically specify the classpath using the `-cp` option to point to each of the JAR file we're depending on. Under this mode, the `AppClassloader` will not have problem finding the dependent class.

## Conclusion
In summary, Spring Boot JAR applications places the dependent JAR files into the custom `BOOT-INF/lib` folder within the JAR file. As this is a Spring Boot specific details, code that try to load class from the dependent JAR using `AppClassloader` will fail. This is because the Java's `AppClassloader` will not know about the Spring Boot specific details.

Subsequently, we've also learned that the common pool doesn't use the custom `LaunchedURLClassLoader` because it was instantiated way before the `main` method is being invoked, which is when the custom class loader is being set.

Finally, we've seen that the same problem won't happen if we don't run the application in the JAR file mode.