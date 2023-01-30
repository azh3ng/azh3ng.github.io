---
layout: article  
alias: 解决循环依赖
title: 【理解Spring】解决循环依赖
date: 2022-01-15 00:00
titleEn: Spring-resolve-circular-dependencies
tags: [Spring]
originFileName: "解决循环依赖.md"
---

## 什么是循环依赖？
举个例子：
```java
@Component
public class ObjectA {
    @Autowired
    private ObjectB b;
}
@Component
public class ObjectB {
    @Autowired
    private ObjectA a;
}
```
以上示例表示在 Spring 容器中定义了两个**单例** bean：ObjectA 和 ObjectB，这两个 bean 相互依赖对方，都需要对方的实例注入到自己的属性中，这就属于循环依赖。同理，当 ObjectA 依赖 ObjectB 依赖 ObjectC ... ObjectX 依赖 ObjectA 也属于循环依赖。

## 为什么要解决循环依赖
Spring 启动时，在 [Bean 创建](/2022/01/11/Spring-BeanFactory-createBean.html) 的过程中，`PostProcessor` 执行 `postProcessProperties()` 时，会进行自动注入，自动注入时会去寻找依赖的 Bean，当 Bean 不存在或者还没有被创建时，会尝试创建 Bean，当被依赖的 Bean 中又依赖了正在创建的 Bean，正在创建中的 Bean 还没有完成初始化，由于是单例模式，无法再创建一个新的 Bean，所以可能导致 Bean 的创建无法继续下去
举个例子：
1. ObjectA 依赖 ObjectB
2. ObjectA 进行 Bean 创建
3. ObjectA 在 Bean 创建的过程中发现依赖 ObjectB
4. ObjectB 进行 Bean 创建
5. ObjectB 在 Bean 创建 的过程中发现依赖 ObjectA
6. ObjectA 正在创建中还未完成，需要注入依赖 ObjectB 才能创建完成，导致无法继续 Bean 的创建

Spring 是通过**三级缓存**的方式解决 Spring 的循环依赖问题  
简单来说，当 Spring 在寻找依赖的过程中，先去缓存中查看依赖是否已经存在，如果已经存在就直接获取，如果不存在就创建依赖的 Bean  
对应代码在：  
DefaultSingletonBeanRegistry.java  
```java
protected Object getSingleton(String beanName, boolean allowEarlyReference)
```

## 一级缓存（singletonObjects）
在 `DefaultSingletonBeanRegistry` 类中持有缓存：  
```java
// 一级缓存，保存的都是已经创建完成的 bean
/** Cache of singleton factories: bean name to ObjectFactory. */
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);
```
这个缓存中保存的是所有已经创建完成的 Bean，Bean 中的依赖已经被正确解决

一级缓存**不能**解决循环依赖问题，但却是 Spring 中一个重要的缓存池，单例 Bean 在创建好之后，需要有一个地方缓存起来，避免重复创建，所以有了一级缓存（singletonObjects）

## 二级缓存（earlySingletonObjects）
在 `DefaultSingletonBeanRegistry` 类中持有缓存：  
```java
//二级缓存，保存的是未完成创建的bean
/** Cache of early singleton objects: bean name to bean instance. */
private final Map<String, Object> earlySingletonObjects = new HashMap<>(16);
```
顾名思义，`earlySingletonObjects` 表示**早期单例对象**，这个缓存中保存的是**未完成**的 Bean，或者说是依赖未被解决的 Bean  

二级缓存可以**部分**解决循环依赖问题，当被创建的 Bean 不需要 AOP 创建代理对象时，可以解决循环依赖问题  

已上述 ObjectA 和 ObjectB 相互依赖举例：  
1. ObjectA 依赖 ObjectB
2. ObjectA 进行 Bean 创建
3. 在 ObjectA 实例化后（未完成依赖注入状态），将其加入二级缓存（earlySingletonObjects）
4. ObjectA 在 Bean 创建的过程中发现依赖 ObjectB
5. 先到一级缓存中查询 ObjectB，发现不存在
6. 再到二级缓存中查询 ObjectB，发现也不存在
7. ObjectB 进行 Bean 创建
8. ObjectB 实例化后，将其加入二级缓存（earlySingletonObjects）
9. ObjectB 在 Bean 创建 的过程中发现依赖 ObjectA
10. 先到一级缓存中查询 ObjectA，发现不存在
11. 再到二级缓存中查询 ObjectA，获取到 ObjectA（未完成依赖注入状态），注入到 ObjectB 中
12. ObjectB 完成创建并返回
13. 将 ObjectB 注入到 ObjectA 中
14. ObjectA 和 ObjectB 都完成创建

此时 ObjectB 持有的 ObjectA 对象的引用不变，而 ObjectA 中已经完成了 ObjectB 的依赖注入，是创建完成的状态，所以循环依赖被解决  

## 三级缓存（singletonFactories）
在 `DefaultSingletonBeanRegistry` 类中持有缓存：  
```java
// 三级缓存，保存的是 key: beanName, value: 创建bean的beanFactory
/** Cache of singleton factories: bean name to ObjectFactory. */  
private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);
```
顾名思义，`singletonFactories` 表示**单例 Bean 工厂对象**，这个缓存中保存的是可以创建 Bean 的工厂对象  

### 问题

在上述二级缓存解决循环依赖的过程中，没有考虑 AOP 导致的代理对象和原始对象不同的问题  

举个例子：
启用 `@EnableAspectJAutoProxy` 注解
```java
@Aspect
@Component
public class Azh3ngAspect {
    @Before("execution(public void ObjectA.test())")
    public void testBefore(JoinPoint joinPoint) {System.out.println("before")}
}

@Component
public class ObjectA {
    @Autowired
    private  ObjectB b;

    public void test() {}
}
@Component
public class ObjectB {
    @Autowired
    private  ObjectA a;
}
```
ObjectA 中有一个切点，Spring 会生成 ObjectA 的原始对象和一个代理对象 ObjectAProxy，ObjectAProxy 中持有 ObjectA 的原始对象，所有依赖 ObjectA 的 Bean 中注入的都应该是 ObjectAProxy。在执行 `test()` 方法前，ObjectAProxy 中会先调用 `testBefore()` 方法，再调用 ObjectA 原始对象中的 test() 方法。  

此时如果只有一级、二级缓存，创建过程如下：  
1. ObjectA 依赖 ObjectB
2. ObjectA 进行 Bean 创建
3. 在 ObjectA 实例化后（未完成依赖注入状态），将其加入二级缓存（earlySingletonObjects）
4. ObjectA 在 Bean 创建的过程中发现依赖 ObjectB
5. 先到一级缓存中查询 ObjectB，发现不存在
6. 再到二级缓存中查询 ObjectB，发现也不存在
7. ObjectB 进行 Bean 创建
8. ObjectB 实例化后，将其加入二级缓存（earlySingletonObjects）
9. ObjectB 在 Bean 创建 的过程中发现依赖 ObjectA
10. 先到一级缓存中查询 ObjectA，发现不存在
11. 再到二级缓存中查询 ObjectA，获取到 ObjectA（未完成依赖注入状态），注入到 ObjectB 中
12. ObjectB 完成创建并返回
13. 将 ObjectB 注入到 ObjectA 中
14. **ObjectA 在完成依赖注入后，创建代理对象 ObjectAProxy**
15. 将 ObjectAProxy 返回加入一级缓存 `singletonObjects` 中，移除二级缓存中的 ObjectA 原始对象

此时 Spring 单例池中持有的 ObjectA 是 **ObjectAProxy**，而 ObjectB 持有的 ObjectA 对象是**原始 ObjectA**，出现错误  

### 解决

Spring 通过加入三级缓存解决这个问题：  

1. ObjectA 创建 Bean
2. 将 ObjectA 的 beanName、BeanDefinition、原始 bean，传入并生成一个 `ObjectFactory`，将其加入三级缓存（singletonFactories）
3. ObjectA 在 Bean 创建的过程中发现依赖 ObjectB
4. 在一级缓存、二级缓存、三级缓存中查询 ObjectB，均不存在
5. ObjectB 进行 Bean 创建
6. ObjectB 实例化后，将其加入二级缓存（earlySingletonObjects）
7. ObjectB 在 Bean 创建 的过程中发现依赖 ObjectA
8. 在一级缓存、二级缓存中查询 ObjectA，发现不存在
9. 在三级缓存中查询 ObjectA，获取到 `ObjectFactory`
10. 执行 `ObjectFactory` 的 `getBean()` 方法，判断 ObjectA 是否需要进行 AOP 创建代理对象
11. ObjectA 需要 AOP，创建代理对象 ObjectAProxy
12. 将 ObjectAProxy 加入二级缓存，移除三级缓存中的 `ObjectFactory`
13. 将 ObjectAProxy 注入 ObjectB 中
14. ObjectB 完成创建
15. 将 ObjectB 注入到 ObjectA 中
16. ObjectA 完成创建
17. ObjectA 执行初始化后步骤：判断 ObjectA 是否需要 AOP，以及是否已经创建代理对象
18. ObjectA 已经创建了代理对象 ObjectAProxy，返回
19. 将 ObjectAProxy 返回加入一级缓存 `singletonObjects` 中，移除二级缓存中的 ObjectA 原始对象

## 扩展问题

**问**：原形 bean 的循环依赖是否能解决？  
**答**：由上述流程可以推断，当原形 bean 在创建过程中出现循环依赖，如果整个依赖链路中存在一个单例 bean，则此单例 bean 可以被缓存，从而完成 bean 的创建，使整个依赖链路正常创建返回；如果整个链路中所有的 bean 都是原形 bean，则无法解决循环依赖。

**问：** 为什么 `@Async` 注解会导致 Spring 解决循环依赖失效？而 `@Transactional` 注解不会？  
**答：** 因为 `@Async` 注解会向 Spring 中 加入一个新的 BeanPostProcessor（`AsyncAnnotationBeanPostProcessor`），会对原始对象生成新的代理对象，与 AOP 的代理对象不同，导致 Spring 在创建过程中会出现两个不同的代理对象，导致错误。`@Async` 的代理对象不是在 `getEarlyBeanReference()` 中创建的，是在 `postProcessAfterInitialization` 创建的代理，而 `@Transactional` 使用的是 `BeanFactoryTransactionAttributeSourceAdvisor`，而不是 BeanPostProcessor，也就不会在 Bean 创建的过程中创建新的代理对象。

**问：** 上述例证中都是使用字段注入，Set 方法注入和构造方法注入导致的循环依赖能解决吗？  
**答：** Set 方法注入和字段注入类似，是在 **Bean 创建之后**再解决依赖问题，所以 Bean 可以被缓存，所以可以解决循环依赖。但是**构造方法注入导致的循环依赖无法被解决**，因为 Bean1 在创建前，发现需要依赖 Bean2，于是尝试获取依赖 Bean2，此时 Bean1 还没有被创建出来，无法被缓存，当 Bean2 也依赖了 Bean1，而 Bean1 没有缓存，导致两个 Bean 都无法被正确创建，也就无法解决循环依赖问题，最终会抛出 `BeanCurrentlyInCreationException` 异常。  

**问：** 当出现 Spring 无法解决的循环依赖时，如何解决？  
**答：** 可以通过 `@Lazy` 注解解决构造方法、`@Async`等导致的循环依赖，因为 `@Lazy` 注解的 Bean 无需立刻创建，可以在需要时再创建，也即构造方法的调用不会被卡住，代理对象实例化的延后也可以避免注入错误的对象。

## 参考
- <https://blog.csdn.net/f641385712/article/details/92797058>
- <https://juejin.cn/post/6985337310472568839>
- <https://zhuanlan.zhihu.com/p/163031798>
- <https://zhuanlan.zhihu.com/p/84267654>
