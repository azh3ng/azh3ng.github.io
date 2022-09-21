---
layout: article  
title: 【理解Spring】Bean生命周期
date: 2022-01-12 00:00
tags: [Spring]
---

# 【理解Spring】Bean生命周期

Spring 最重要的功能就是帮助程序员创建对象（也就是 IOC），而启动 Spring 就是为创建 Bean 对象做准备，所以我们先明白 Spring 到底是怎么去创建 Bean 的，也就是先弄明白 Bean 的生命周期。

Bean 的生命周期就是指：在 Spring 中，一个 Bean 是如何生成的，如何销毁的

Bean 生命周期流程图
![Bean生命周期流程图](./attachments/Bean生命周期-1641711003210.png)

## 生成 [[BeanDefinition]]

![[Spring扫描|Spring扫描并生成 BeanDefinition]]

## 合并 BeanDefinition

![[合并 BeanDefinition]]

## getBean() 获取 Bean
![[AbstractBeanFactory.getBean()|getBean()]]

## 创建 Bean
![[Bean 创建]]

## 执行 SmartInitializingSingleton.afterSingletonsInstantiated()
`DefaultListableBeanFactory.preInstantiateSingletons() // line 987`
加载了所有的非懒加载单例 Bean之后，找出继承 SmartInitializingSingleton 的Bean，并执行 afterSingletonsInstantiated() 方法

## Bean 销毁
Bean 销毁发生在在 Spring 容器关闭过程中。

在 Spring 容器关闭时，比如：
```java
AnnotationConfigApplicationContext context = new
AnnotationConfigApplicationContext(AppConfig.class);
UserService userService = (UserService) context.getBean("userService");
userService.test();
// 容器关闭，内部会调用 doClose() 方法
context.close();
```
或者
```java
AnnotationConfigApplicationContext context = new
AnnotationConfigApplicationContext(AppConfig.class);
// 注册关闭的 hook, 当程序执行完毕，会调用 hook 执行其中指定的 doClose() 方法
context.registerShutdownHook();
UserService userService = (UserService) context.getBean("userService");
userService.test();
```
会调用 doClose() 方法，执行 Bean 销毁


在 Bean 创建过程的最后（初始化之后），会判断当前创建的 Bean 是不是 DisposableBean，如果是则将其 [[#使用适配器模式对 Bean 进行适配|适配]] 成 `DisposableBeanAdapter` 对象，并存入 `disposableBeans` 中（一个 LinkedHashMap），在 Spring 容器关闭时，遍历调用 `destroy()` 方法执行 Bean 销毁。

判断 Bean 是否为 DisposableBean：
- 是否实现了 `DisposableBean` 接口
- 是否实现了 `AutoCloseable` 接口
- `BeanDefinition` 中是否指定了 `destroyMethod`
- 调用 `DestructionAwareBeanPostProcessor.requiresDestruction(bean)` 进行判断
    - ApplicationListenerDetector 中直接使得 ApplicationListener 是 DisposableBean
    - InitDestroyAnnotationBeanPostProcessor 中使得被 `@PreDestroy` 注解的方法就是 DisposableBean

Spring 容器关闭过程时：
1. 发布 ContextClosedEvent 事件
2. 调用 lifecycleProcessor 的 onCloese()方法
3. 销毁单例 Bean
4. 遍历 disposableBeans
5. 把每个 disposableBean 从单例池中移除
6. 调用 disposableBean 的 destroy()
7. 如果这个 disposableBean 还被其他 Bean 依赖了，那么也得销毁其他 Bean
8. 如果这个 disposableBean 还包含了 inner beans，将这些 Bean 从单例池中移除掉 (inner bean 参考 https://docs.spring.io/spring-framework/docs/current/spring-framework-reference/core.html#beans-inner-beans )
9. 清空 manualSingletonNames，是一个 Set，存的是用户手动注册的单例 Bean 的 beanName
10. 清空 allBeanNamesByType，是一个 Map，key 是 bean 类型，value 是该类型所有的 beanName 数组
11. 清空 singletonBeanNamesByType，和 allBeanNamesByType 类似，只不过只存了单例 Bean

### 使用适配器模式对 Bean 进行适配

在销毁时，Spring 会找出实现了 DisposableBean 接口的 Bean。

但是我们在定义一个 Bean 时，如果这个 Bean 实现了 DisposableBean 接口，或者实现了 AutoCloseable 接口，或者在 BeanDefinition 中指定了 destroyMethodName，那么这个 Bean 都属于“DisposableBean”，这些 Bean 在容器关闭时都要调用相应的销毁方法。

所以，这里就需要进行适配，将实现了 DisposableBean 接口、或者 AutoCloseable 接口等适配成实现了 DisposableBean 接口，所以就用到了 DisposableBeanAdapter。

会把实现了 AutoCloseable 接口的类封装成 DisposableBeanAdapter，而 DisposableBeanAdapter 实现了 DisposableBean 接口。