---
layout: article
title: 【理解Spring】系列前言
date: 2099-01-01 00:00
titleEn: Spring-introduction
tags: [Spring]
originFileName: "Spring.md"
---

在开发中，Spring 是我使用最多的框架，故而对它进行更深入的学习，可以更快的实现想要的功能，同时写出更优雅的代码。  
基于 [Spring Framework 5.3.10-SNAPSHOT](https://github.com/spring-projects/spring-framework/tree/v5.3.10) 学习，后续博文内容对应此版本

## 核心原理
- [[Spring核心接口]]
    - [BeanDefinition](/2022/01/02/Spring-BeanDefinition.html)
    - [抽象 BeanDefinition](/2022/01/08/Spring-AbstractBeanDefinition.html)
    - [BeanFactory](/2022/01/03/Spring-BeanFactory.html)
    - [ApplicationContext](/2022/01/04/Spring-ApplicationContext.html)
    - [BeanPostProcessor](/2022/01/05/Spring-BeanPostProcessor.html)
    - [FactoryBean](/2022/01/05/Spring-FactoryBean.html)
- [Spring启动](/2022/01/06/Spring-startup.html)
    - [Spring扫描](/2022/01/07/Spring-scan.html)
    - [Spring初始化所有非懒加载单例Bean](/2022/01/08/Spring-initializes-non-lazy-singleton-beans.html)
        - [合并 BeanDefinition](/2022/01/08/Spring-merge-BeanDefinition.html)
        - [BeanFactory.getBean()](/2022/01/10/Spring-BeanFactory-getBean.html)
- [Bean生命周期](/2022/01/12/Spring-Bean-lifecycle.html)
- [Spring推断构造方法](/2022/01/13/Spring-infer-constructor.html)
- [依赖注入](/2022/01/14/Spring-Dependency-Injection.html)
- [解决循环依赖](/2022/01/15/Spring-resolve-circular-dependencies.html)
- [Spring AOP](/2022/01/16/Spring-AOP.html)
    - [AOP](/2022/01/16/AOP.html)
    - [代理模式](/2022/01/16/Proxy-Pattern.html)
    - [JDK动态代理](/2022/01/16/JDK-Proxy.html)
    - [CGLIB动态代理](/2022/01/16/CGLIB-Proxy.html)
    - [ProxyFactory](/2022/01/16/ProxyFactory.html)
    - [TargetSource](/2022/01/16/TargetSource.html)
- [Spring事务](/2022/01/17/Spring-Transaction.html)

## 实战相关
- [@Qualifier使用](/2022/01/30/Spring-use-of-@Qualifier.html)
- [Spring动态获取Bean](/2022/02/01/Spring-dynamic-getBean.html)

