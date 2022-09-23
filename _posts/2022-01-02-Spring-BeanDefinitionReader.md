---
layout: article  
title: 【理解Spring】BeanDefinitionReader  
date: 2022-01-02 00:00
category:  
tags: [Spring]  
---

Spring 提供的 BeanDefinition 读取器（`BeanDefinitionReader`），在使用 Spring 开发时用得少，但在 Spring 源码中很常见，相当于 Spring 基础设施

## AnnotatedBeanDefinitionReader

可以直接把某个类转换为 BeanDefinition，并且会解析该类上的注解，比如
```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
AnnotatedBeanDefinitionReader annotatedBeanDefinitionReader = new AnnotatedBeanDefinitionReader(context);
// 将User.class解析为BeanDefinition
annotatedBeanDefinitionReader.register(User.class);
System.out.println(context.getBean("user"));
```
**注意**：它能解析的注解是：`@Conditional`，`@Scope`、`@Lazy`、`@Primary`、`@DependsOn`、`@Role`、`@Description`

## XmlBeanDefinitionReader

可以解析 `<bean/>` 标签
```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
XmlBeanDefinitionReader xmlBeanDefinitionReader = new XmlBeanDefinitionReader(context);
int i = xmlBeanDefinitionReader.loadBeanDefinitions("spring.xml");// i: 解析得到的 Bean 数量
System.out.println(context.getBean("user"));
```

## ClassPathBeanDefinitionScanner

ClassPathBeanDefinitionScanner 是扫描器，但是它的作用和 BeanDefinitionReader 类似，它可以进行扫描，扫描某个包路径，对扫描到的类进行解析，比如，扫描到的类上如果存在@Component 注解，那么就会把这个类解析为一个 BeanDefinition，比如：
```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext();
context.refresh();
ClassPathBeanDefinitionScanner scanner = new ClassPathBeanDefinitionScanner(context);
scanner.scan("com.azh3ng");
System.out.println(context.getBean("userService"));
```