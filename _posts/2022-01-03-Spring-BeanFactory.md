---
layout: article  
title: 【理解Spring】BeanFactory  
date: 2022-01-03 00:00
titleEn: Spring-BeanFactory
category:  
tags: [Spring]  
originFileName: "BeanFactory.md"
---



BeanFactory 顾名思义负责创建 Bean，并且提供了获取 Bean 的 API。

### DefaultListableBeanFactory
`DefaultListableBeanFactory` 继承 `BeanFactory`，同时支持很多其他功能，`DefaultListableBeanFactory` 在 Spring 中发挥非常重要的作用。  
`DefaultListableBeanFactory`的类继承实现结构：

![DefaultListableBeanFactory的类继承实现结构](https://github.com/azh3ng/azh3ng.github.io/blob/master/_posts/attachments/DefaultListableBeanFactory-hierarchy.png?raw=true)

`DefaultListableBeanFactory` 实现了很多接口，也即拥有很多功能：
- `AliasRegistry` ：支持别名功能，一个名字可以对应多个别名
- `BeanDefinitionRegistry` ：可以注册、保存、移除、获取某个 BeanDefinition
- `BeanFactory` ：Bean 工厂，可以根据某个 bean 的名字、或类型、或别名获取某个 Bean 对象
- `SingletonBeanRegistry` ：可以直接注册、获取某个单例 Bean
- `SimpleAliasRegistry` ：它是一个类，实现了 AliasRegistry 接口中所定义的功能，支持别名功能
- `ListableBeanFactory` ：在 BeanFactory 的基础上，增加了其他功能，可以获取所有 BeanDefinition 的 beanNames，可以根据某个类型获取对应的 beanNames，可以根据某个类型获取{类型：对应的 Bean}的映射关系
- `HierarchicalBeanFactory` ：在 BeanFactory 的基础上，添加了获取父 BeanFactory 的功能
- `DefaultSingletonBeanRegistry` ：它是一个类，实现了 SingletonBeanRegistry 接口，拥有了直接注册、获取某个单例 Bean 的功能
- `ConfigurableBeanFactory` ：在 `HierarchicalBeanFactory` 和 `SingletonBeanRegistry` 的基础上，添加了设置父 `BeanFactory`、类加载器（表示可以指定某个类加载器进行类的加载）、设置 Spring EL 表达式解析器（表示该 BeanFactory 可以解析 EL 表达式）、设置类型转化服务（表示该 BeanFactory 可以进行类型转化）、可以添加 `BeanPostProcessor`（表示该 BeanFactory 支持 Bean 的后置处理器），可以合并 BeanDefinition，可以销毁某个 Bean 等等功能
- `FactoryBeanRegistrySupport` ：支持了 FactoryBean 的功能
- `AutowireCapableBeanFactory` ：是直接继承了 BeanFactory，在 BeanFactory 的基础上，支持在创建 Bean 的过程中能对 Bean 进行自动装配
- `AbstractBeanFactory` ：实现了 `ConfigurableBeanFactory` 接口，继承了 `FactoryBeanRegistrySupport`，这个 BeanFactory 的功能已经很全面了，但是不能自动装配和获取 beanNames
- `ConfigurableListableBeanFactory` ：继承了 `ListableBeanFactory`、`AutowireCapableBeanFactory`、`ConfigurableBeanFactory`
- `AbstractAutowireCapableBeanFactory` ：继承了 `AbstractBeanFactory`，实现了 `AutowireCapableBeanFactory`，拥有自动装配的功能

`DefaultListableBeanFactory` ：继承了 `AbstractAutowireCapableBeanFactory`，实现了 `ConfigurableListableBeanFactory` 接口和 `BeanDefinitionRegistry` 接口，所以 DefaultListableBeanFactory 可以**完成 BeanDefinition 的注册**（`BeanDefinitionRegistry.registerBeanDefinition()`）、**实例化所有非懒加载的单例** Bean（`ConfigurableListableBeanFactory.preInstantiateSingletons()`）和**自动装配**（`AbstractAutowireCapableBeanFactory.autowireByType()`）等功能。
