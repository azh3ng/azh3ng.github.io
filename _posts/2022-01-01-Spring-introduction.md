---
layout: article
title: 【理解Spring】前言
date: 2022-01-01 00:00
tags: [Spring]
---

在开发中，Spring 算是我接触最多的框架了，故而想对它进行更深入的学习，可以更快的实现想要的功能，同时写出更优雅的实现。
后续所有的内容都基于 [Spring Framework 5.3.10-SNAPSHOT](https://github.com/spring-projects/spring-framework/tree/v5.3.10)。

## 核心原理
目前计划先学习 Spring 核心概念，再在此基础上不断扩充 
- Spring核心接口
  - [BeanDefinition]
  - [BeanFactory]
  - [ApplicationContext]
  - [BeanPostProcessor]
  - [FactoryBean]
- [Spring启动]
  - [Spring扫描]
  - [Spring初始化所有非懒加载单例Bean]
    - [合并BeanDefinition]
    - [BeanFactory.getBean()]
- [Bean生命周期]
- [Spring推断构造方法]
- [依赖注入]
- [解决循环依赖]
- [Spring AOP]
  - [代理模式]
  - [JDK动态代理]
  - [CGLIB代理]
- [Spring事务]



## Children
```dataview
LIST WHERE contains(extends, [[]])
```
