---
layout: article  
title: Spring MVC 路径参数和路径冲突  
date: 2019-02-04  
category:  
tags: []  
---

# Spring MVC 路径参数和路径冲突

SpringMVC可以对 `@RequestMapping` 中的URL进行匹配, 转发到相应的`Controller`方法

也可以获取 `URL` 中的值作为参数

例如

```java
@GetMapping(value = "/test/{pathValue}")
public String test(@PathVariable("pathValue") String aa) {
    return "PathVariable Value: " + aa;
}

@GetMapping(value = "/test/aa")
public String test1() {
    return "Path: /aa";
}
```

当访问 `/test/aa` 时, 返回 `Path: /aa`

当访问 `/test/aaa` 或者其他时, 返回 `PathVariable Value: aaa`

