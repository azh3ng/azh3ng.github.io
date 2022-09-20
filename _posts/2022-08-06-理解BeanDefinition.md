---
layout: article  
title: 【理解Spring】 BeanDefinition
date: 2022-01-08 23:16
category:  
tags: [Spring]
---

# 【理解Spring】 BeanDefinition

> A BeanDefinition describes a bean instance, which has property values, constructor argument values, and further information supplied by concrete implementations.

BeanDefinition，表示 Bean 定义。
BeanDefinition 用于保存 Bean 的相关信息，包括
- Class，表示 Bean 类型
- Scope，表示 Bean 作用域，单例(Singleton)或原型(Prototype)等
- LazyInit：表示 Bean 是否是懒加载
- InitMethodName：表示 Bean 初始化时要执行的方法
- DestroyMethodName：表示 Bean 销毁时要执行的方法
等，它是实例化 Bean 的原材料，Spring 就是根据 BeanDefinition 中的信息实例化 Bean。

BeanDefinition 的常用子类包括：[RootBeanDefinition](#RootBeanDefinition)、[GenericBeanDefinition](#GenericBeanDefinition)

在 Spring 中，我们经常会通过以下几种方式来定义 Bean, 也叫**申明式定义 Bean**：
- Spring.Xml 的 `<bean/>`
- `@Bean`
- `@Component` (`@Service`, `@Controller`)

还可以**编程式定义 Bean**，那就是直接通过 BeanDefinition，比如：
```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);

// 生成一个BeanDefinition对象，并设置beanClass为User.class，并注册到ApplicationContext中
AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder.GenericBeanDefinition().GetBeanDefinition();
BeanDefinition.SetBeanClass(User.Class);
context.registerBeanDefinition("user", beanDefinition);

System.out.println(context.getBean("user"));
```
还可以通过 BeanDefinition 设置一个 Bean 的其他属性
```java
BeanDefinition.SetScope("prototype"); // 设置作用域
BeanDefinition.SetInitMethodName("init"); // 设置初始化方法
BeanDefinition.SetLazyInit(true); // 设置懒加载
```

和申明式事务、编程式事务类似，通过 `<bean/>`，`@Bean`，`@Component` 等申明式方式所定义的 Bean，最终都会被 Spring 解析为对应的 BeanDefinition 对象，并放入 Spring 容器中。

## RootBeanDefinition

TOOD

## GenericBeanDefinition

TODO
