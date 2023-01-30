---
layout: article  
title: 【理解Spring】BeanFactory.getBean()
date: 2022-01-10 00:00
titleEn: Spring-BeanFactory-getBean
tags: [Spring]
alias: 
    - getBean()
    - getBean(beanName)
    - getBean(FACTORY_BEAN_PREFIX +beanName)
originFileName: "BeanFactory.getBean().md"
---

代码入口：`DefaultListableBeanFactory.preInstantiateSingletons()`  
Spring 在[合并 BeanDefinition](/2022/01/08/Spring-merge-BeanDefinition.html) 之后，调用 `AbstractBeanFactory.getBean()` 获取 Bean

`AbstractBeanFactory.getBean()` 有许多重载方法，其最终调用的是
```java
protected <T> T doGetBean(
    final String name, 
    @Nullable final Class<T> requiredType,        
    @Nullable final Object[] args, 
    boolean typeCheckOnly)
```

其目的是为了获取 Bean，先从缓存中获取，如果不存在就创建 Bean。

## 主体逻辑
1. 处理别名、处理 FactoryBean 的前缀，获取最终实际的 Bean name
2. 尝试从单例池 `singletonObjects` 中获取 Bean
3. 如果获取到 Bean 直接返回，否则继续执行
4. 如果当前 BeanFactory 中不包含此 Bean，则调用父 BeanFactory 执行 getBean 方法
5. 获取合并后的 [BeanDefinition](/2022/01/02/Spring-BeanDefinition.html)
    1. 判断如果是**抽象 BeanDefinition**，无法实例化，报错
6. 判断是否有 `@dependsOn` 注解，如果有：
    1. 有`@dependsOn` 注解指定依赖，判断是否循环依赖
        1. 是循环依赖，抛出异常
        2. 不是循环依赖
            1. Bean 依赖信息缓存到 `DefaultSingletonBeanRegistry.dependentBeanMap`
            2. 执行 `getBean()` 实例化被依赖的 Bean
7. 判断 Bean 的 Scope 属性
    1. 单例（Singleton）：从单例池中获取 Bean，如果没有，**创建 Bean**
    2. 多例（Prototype）：**创建 Bean**
    3. 其他（Request、Session 等）：判断各自的缓存池，获取 Bean，如果没有，则**创建 Bean**
8. [创建 Bean](/2022/01/11/Spring-BeanFactory-createBean.html)
   

## get FactoryBean
`getBean(FACTORY_BEAN_PREFIX + beanName)`
getBean 方法可以获取普通 Bean 和 [FactoryBean](/2022/01/05/Spring-FactoryBean.html)。  
如果传入参数 beanName 以“&”(`FACTORY_BEAN_PREFIX`) 开头（由于 FactoryBean 有多级继承关系，所以“&”可以有多个，例如“&&&demoService” ），表示希望获取 FactoryBean，则 Spring 将前缀的“&”去除，在单例池中获取到 FactoryBean 后直接返回；  
如果传入参数 beanName 不以“&”开头，但在单例池中获取的 bean 是 FactoryBean，表示希望获取 FactoryBean 生产的 bean，则到缓存 `factoryBeanObjectCache` 中获取，如果没有，则调用 `FactoryBean.getObject()` 获取 bean，放入缓存中后返回。  

