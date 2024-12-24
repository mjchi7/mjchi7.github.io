---
title: "Spring Boot Nested JAR and Classloading Visibility Issues"
date: 2024-12-17T10:50:39+08:00
draft: false
summary: ForkJoinPool's commonPool Unable to Load Dependent Library JAR Classes in a Spring Boot JAR Application
---

## Overview
In this article, we'll explore the problem of using the `ForkJoinPool` in a Spring Boot JAR application. Specifically, we'll understand why **threads in the `ForkJoinPool` cannot load classes from dependent library JARs, while threads created using `ExecutorService` don't face the same issue in a Spring Boot JAR application**.

The root cause lies in the Spring Boot nested JAR structure and the class loaders used. We'll discuss how the `ForkJoinPool` uses the system class loader, why it lacks visibility into Spring Boot's nested JARs, and how Spring Boot's custom `LauncherURLClassLoader` helps.

By the end, we'll also learn why we don't face the same issue with `ForkJoinPool` when running our Spring Boot application without packaging it as a JAR file (i.e., `./mvnw spring-boot:run`).

## Problem Statement
Let's begin with a simple demonstration. Imagine a Spring Boot application that uses both `ForkJoinPool` and `ExecutorService` to load a class dynamically from a dependent library:

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

The simple class defines a Spring Boot application. On startup, the application first creates an `ExecutorService` and runs a task asynchronously to dynamically load the `com.example.dependency.SomeLibraryClass`. Later, it submits the same task to the `ForkJoinPool#commonPool`.

Notably, the `com.example.dependency.SomeLibraryClass` is a class that exists in a dependent library JAR file. 

When we package the application into a JAR file and run it, we get the following output:

```bash
ExecutorService ClassLoader: org.springframework.boot.loader.LaunchedURLClassLoader
ExecutorService Loaded: class com.example.dependency.SomeLibraryClass
ForkJoinPool ClassLoader: java.lang.ClassLoader$AppClassloader
java.lang.ClassNotFoundException: com.example.dependency.SomeLibraryClass
```

There are a few observations we can make from the output:

The `ExecutorService` thread uses the `LaunchedURLClassLoader` and successfully loads the class.
The `ForkJoinPool` common pool thread uses the `AppClassLoader`, a.k.a. system class loader, and fails to load the class.

Based on these observations, two prominent questions arise:

1. Why are two different [class loaders](https://www.reddit.com/r/java/comments/1f79jhr/java_classloaders_illustrated/) being used?
2. Why can't the [`AppClassLoader`](https://stackoverflow.com/questions/34650568/difference-between-appclassloader-and-systemclassloader) see the class in the dependent JAR file?

To answer these questions, we first need to understand the Spring Boot nested JAR structure.

## Spring Boot Nested JAR Structure
One of the longstanding problems with Java is that there isn't a standard way to load nested JAR files (e.g., when our application is a JAR file that contains additional JAR files for its dependencies).

Conventionally, many developers choose to package all the classes from all the JAR files into a single uber JAR. However, this approach can lead to filename conflicts and makes it difficult to determine which libraries are included in the application.

**Spring Boot opts for a different approach, known as a [nested JAR structure](https://docs.spring.io/spring-boot/specification/executable-jar/nested-jars.html)**. Specifically, Spring Boot packages applications into the following layout:

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

Notably, **all the dependent library JARs are placed in the Spring Boot-specific directory, `BOOT-INF`**.

Due to this unique structure, a Spring Boot application requires a custom class loader, `LaunchedURLClassLoader`, to load all the classes in the `BOOT-INF/lib` directory. This is necessary because **Java's `AppClassLoader` does not recognize the Spring Boot-specific `BOOT-INF` directory within the JAR file**.

## AppClassloader Visibility in Spring Boot JAR
In our earlier example involving the `ForkJoinPool#commonPool()` and the `ExecutorService`, we observed that the former uses the `AppClassLoader` while the latter uses the custom `LaunchedURLClassLoader`.

At this point, it becomes clear why the `AppClassLoader` used by the `ForkJoinPool`'s common pool cannot see the class in the dependent library JAR. To reiterate, this is because Spring Boot packages the dependent library JARs into the `BOOT-INF/lib` directory, which the Java `AppClassLoader` does not recognize.

## ForkJoinPool's Common Pool Initialization Sequence
**The reason why the `ForkJoinPool`'s common pool doesn't use the custom `LaunchedURLClassLoader` from Spring Boot is that the common pool in `ForkJoinPool` is instantiated in the static block of the class itself**.

For threads to inherit the `LaunchedURLClassLoader`, they must be created after the main method is executed. This is because the `LaunchedURLClassLoader` is set as the context class loader for the main thread after the `main` method is invoked.

## Why Doesn't This Affect `./mvnw spring-boot:run`?
If we run the application without first packaging it into a JAR file (i.e., invoking it on the terminal using `./mvnw spring-boot:run`), we can see that both code sections execute successfully.

**The reason is that when we run our Spring Boot application using `./mvnw spring-boot:run`, we're running the application in the exploded classpath mode**. In other words, the command specifically specifies the classpath using the `-cp` option to point to each of the JAR files we're depending on. Under this mode, the `AppClassloader` will not have problems finding the dependent class.

## Conclusion
In summary, Spring Boot JAR applications place the dependent JAR files into the custom `BOOT-INF/lib` folder within the JAR file. As these are Spring Boot-specific details, code that tries to load classes from the dependent JAR using `AppClassloader` will fail. This is because Java's `AppClassloader` will not know about the Spring Boot-specific details.

Subsequently, we've also learned that the common pool doesn't use the custom `LaunchedURLClassLoader` because it is instantiated way before the `main` method is invoked, which is when the custom class loader is set.

Finally, we've seen that the same problem won't occur if we don't run the application in the JAR file mode.