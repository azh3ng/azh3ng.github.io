---
layout: article  
title: 【Spring实战】@Qualifier 注解的使用
date: 2022-01-30 00:00
titleEn: Spring-use-of-@Qualifier
tags: [Spring]
originFileName: @Qualifier使用.md
---


在使用 Spring 的过程中，当需要进行依赖注入时，往往会选用 `@Autowired` 注解进行自动装配，如果被  `@Autowired` 注解的类在 Spring 中有多个 Bean，则通过变量名称选取合适的 Bean，例如：
```java
@Component 
public class FooService implements BaseService {
}
@Component 
public class BarService implements BaseService {
}
@Component
public class SomeBean {
    @Autowired
    private BaseService barService; // 根据变量名称会找到 BarService
}
```
但是当 Spring 无法通过变量名确定一个 Bean 时，将会抛出 `NoUniqueBeanDefinitionException` 异常，如下：
```java
@Component
public class SomeBean {
    @Autowired
    private BaseService service; // Spring 启动抛出异常 NoUniqueBeanDefinitionException
}
```
通过 `@Qualifier` 注解的使用，可以解决此问题
## 基础使用
```java
@Component 
@Qualifier("foo")
public class FooService implements BaseService {
}
@Component 
@Qualifier("bar")
public class BarService implements BaseService {
}
```
```java
@Component
public class SomeBean {
    @Autowired
    @Qualifier("bar")
    private BaseService service; // 根据 @Qualifier("bar") 会找到 BarService
}
```

## 进阶使用
1. 定义两个注解：

```java
@Target({ElementType.TYPE, ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Qualifier("foo")
public @interface Foo {
}
```

```java
@Target({ElementType.TYPE, ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Qualifier("bar")
public @interface Bar {
}
```

2. 定义一个接口和两个实现类，表示负载均衡：

```java
@Component 
@Foo
public class FooService implements BaseService {
}
@Component 
@Bar
public class BarService implements BaseService {
}
```

3. 使用：

```java
@Component
public class SomeBean {
    @Autowired
    @Bar
    private BaseService service; // 通过注解 @Bar 找到 BarService
}
```

## 参考
<https://www.baeldung.com/spring-qualifier-annotation>
