---
layout: article  
title: 【理解Spring】自动注入对 static 字段不支持的原因  
date: 2022-01-14 00:00
category:
tags: [Spring]
---

# 【理解Spring】自动注入对 static 字段不支持的原因

举个例子：
有一个原型类 `OrderService`
```java
@Component
@Scope("prototype")
public class OrderService {
}
```
和另一个原型类 `UserService`，`UserService` 中有一个静态属性 `OrderService orderService` 并被 `@Autowired` 标注
```java

@Component
@Scope("prototype")
public class UserService {
    @Autowired
    private static OrderService orderService;

    public void test() {
        System.out.println("test123");
    }
}
```

假设 Spring 支持 `static` 字段进行自动注入，如果调用两次
```java
UserService userService1 = context.getBean("userService")
UserService userService2 = context.getBean("userService")
```
当 `userService2` 创建时，会将属性 `orderService` 重新赋值并覆盖，导致 `userService1` 中的值发生变化，和预期不符，容易产生 bug。
