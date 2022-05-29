---
title: "Jdbctemplate `queryForStream` Connection Leak"
date: 2022-05-29T12:17:13+08:00
draft: false
subtitle: "Java Stream and Resource Leak"
---
# Connection Leak in `queryForStream`
## tldr;

The method `queryForStream` provided by `JDBCTemplate` produce a `Stream` with database connection as sources and hence has to be closed explicitly. **Failure to do so would cause connection leak.**

## Stream with Resources

The Java `Stream` API can be backed by system resources or without. For the former, we’ll need to close the `Stream` explicitly once we are done in order to release the resources. The `JdbcTemplate.queryForStream` is one such example of method that produces `Stream` that are backed by system resources (database connection in this case).

### `JdbcTemplate.queryForStream` Documentation

In the [Javadoc](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/jdbc/core/JdbcTemplate.html#queryForStream-org.springframework.jdbc.core.PreparedStatementCreator-org.springframework.jdbc.core.PreparedStatementSetter-org.springframework.jdbc.core.RowMapper-), it is specifically mentioned that we’ll need to close the `Stream` once it’s fully processed:

> Returns:
the result Stream, containing mapped objects, needing to be closed once fully processed (e.g. through a try-with-resources clause)
> 

#### `JdbcTemplate.queryForStream` Code

Inspecting the code for `JdbcTemplate.queryForStream`, we can see that it will only call the `releaseConnection` method on `Stream` close:

```java
@Override
public Stream<T> doInStatement(Statement stmt) throws SQLException {
	ResultSet rs = stmt.executeQuery(sql);
	Connection con = stmt.getConnection();
	return new ResultSetSpliterator<>(rs, rowMapper).stream().onClose(() -> {
		JdbcUtils.closeResultSet(rs);
		JdbcUtils.closeStatement(stmt);
		DataSourceUtils.releaseConnection(con, getDataSource());
	});
}
```

## Experiment

To validate the finding, we can devise a simple experiment: 

### Methods With and Without Explicit Close

In a SpringBoot project, we implement 2 methods in a `UserRepository` class that call `JdbcTemplate.queryForStream`. 

Method 1: `getWithoutClose()` where we invoke `queryForStream` without closing the `Stream`.

```java
public User getWithoutClose() {
    String sql = "SELECT * FROM \"user\";";
    return jdbcTemplate.queryForStream(
            sql,
            pss -> {
                Array strs = pss.getConnection().createArrayOf("INTEGER", new Integer[]{1, 2});
                System.out.println(strs);
            },
            userMapper)
    .findFirst()
    .orElse(null);
}
```

Method 2: `getWithClose()` where we invoke `queryForStream` and close it when we’ve extracted the result

```java
public User getWithClose() {
    String sql = "SELECT * FROM \"user\";";
    Stream<User> s = jdbcTemplate.queryForStream(
            sql,
            pss -> {
                Array strs = pss.getConnection().createArrayOf("INTEGER", new Integer[]{1, 2});
                System.out.println(strs);
            },
            userMapper);

    User u = s.findFirst().orElse(null);
    s.close();
    return u;
}
```

### The Tests

With that 2 methods, we can write test to verify our initial hypothesis.  First, we set the maximum number of connection to 5 for our `DataSource`. 

```java
public DataSource getDataSource() {
    HikariConfig config = new HikariConfig();
    config.setJdbcUrl("jdbc:postgresql://localhost:5432/connleak");
    config.setUsername("postgres");
    config.setPassword("postgres");
    config.setConnectionTimeout(1000);
    config.setMaximumPoolSize(5);
    DataSource dataSource = new HikariDataSource(config);
    return dataSource;
}
```

Then we can write our **first test which calls the method `getWithoutClose()` for 6 times and we should see that it fails at the 6th call.** Specifically, we expect the underlying exception to be `SQLTransientConnectionException` that’s thrown by HikariCP when attempt to obtain connection fails.

```java
@Test
public void testGetWithoutClose() {
    // Call 5 times to exhaust the connection pool
    IntStream.range(0, 5).forEach(n -> {
        userRepository.getWithoutClose();
    });

    // Call the 6th time and expect error
    CannotGetJdbcConnectionException e = assertThrows(CannotGetJdbcConnectionException.class, () -> {
        userRepository.getWithoutClose();
    });
    Assertions.assertEquals(SQLTransientConnectionException.class, e.getCause().getClass());
    Assertions.assertTrue(
            () -> e.getCause().getMessage().toLowerCase().contains("connection is not available, request timed out after")
    );
}
```

Now, we write our 2nd test case which calls the `getWithClose()` method with the same `DataSource` settings. **Calling it for more than 5 times will all succeeded because the connection is always released once the method returns.**

```java
@Test
public void testGetWithClose() {
    // Call 5 times to exhaust the connection pool
    IntStream.range(0, 5).forEach(n -> {
        userRepository.getWithClose();
    });

    // Call more and still do not expect throws
    assertDoesNotThrow(() -> {
        userRepository.getWithoutClose();
        userRepository.getWithoutClose();
        userRepository.getWithoutClose();
    });
}
```

When both of the test cases passed, we can be sure our 

## Summary

In this article, we’ve seen how Java `Stream` can be backed by system resources. Then, we’ve looked at `JdbcTemplate.queryForStream` as an example of method that produce `Stream` that is backed by system resources. Finally, we’ve devised a simple reproducible experiment that prove our initial hypothesis.

