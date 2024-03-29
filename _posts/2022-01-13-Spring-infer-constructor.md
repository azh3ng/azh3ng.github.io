---
layout: article  
title: 【理解Spring】推断构造方法
date: 2022-01-13 00:00
titleEn: Spring-infer-constructor
tags: [Spring]
originFileName: "Spring推断构造方法.md"
---


代码入口：
```java
org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean
org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#createBeanInstance
org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#autowireConstructor
org.springframework.beans.factory.support.ConstructorResolver#autowireConstructor()
```

当 BeanDefinition 没有指定 Supplier，也没有指定工厂方法时，需要推断使用哪个构造方法进行 Bean 的初始化

Spring 的判断逻辑如下：

1. 类中所有构造方法上都没有 `@Autowired` 注解
    1. 只有一个无参构造方法，选用此构造方法
    2. 只有一个有参的构造方法，选用此构造方法，通过 [依赖注入#依赖查找](/2022/01/14/Spring-Dependency-Injection.html#依赖查找) 找到对应的入参 Bean
    3. 有一个无参构造方法，和一或多个有参构造方法，使用无参构造方法
    4. 只有多个有参构造方法，**抛异常**
2. 类中存在 `@Autowired` 注解的构造方法（`@Autowired` 的 `required` 属性默认为 true）
    1. 只有一个 `@Autowired` 的 `required` 为 true 的构造方法，选用此构造方法，通过 [依赖注入#依赖查找](/2022/01/14/Spring-Dependency-Injection.html#依赖查找) 找到对应的入参 Bean
    2. 有多个 `@Autowired` 标注的构造方法，其中一或多个构造方法的 `required` 属性默认为 true，**抛异常**
    3. 所有被  `@Autowired` 标注的构造方法的 `required` 属性都为 false，继续判断
        1. 先将所有构造方法排序，public 在前，private 在后，访问修饰符相同的以**参数多的在前**
        2. 当调用 [getBean()](/2022/01/10/Spring-BeanFactory-getBean.html) 时，有传入构造参数，或者在 BeanDefinition 中有设置构造参数，则确定构造参数个数，剔除所有参数个数小于此数量的构造方法
        3. 遍历判断每个构造方法的每个参数是否可以通过 [依赖注入#依赖查找](/2022/01/14/Spring-Dependency-Injection.html#依赖查找) 找到对应的 Bean，如果遍历结束，每个构造方法中都存在有无法找到的 Bean，**抛异常**
        4. 当多个构造方法参数个数相同，根据参数匹配度 [计分](#构造方法匹配度计分)，
            1. 有且仅有一个**分数最小**的构造方法，选用此方法
            2. 有多个分数最小且相同的构造方法，并且是 **严格模式** 时，**抛异常**

## 构造方法匹配度计分

计分方式分为 宽松模式（**默认**） 和 严格模式，可以在 BeanDefinition 设置（`AbstractBeanDefinition.lenientConstructorResolution` 默认为 true）

### 宽松模式

宽松模式会更细粒度的计分

对于查找到的依赖的 Bean，
- 如果 Bean 类型与参数类型完全相同，计 0 分
- 如果 Bean 实现（`implements`）了参数类型，计 1 分，每多一层 `implements` 加 1 分
- 如果 Bean 继承（`extends`）了参数类型，计 2 分，每多一层  `extends` 加 2 分

例如：
```java
@Component
class A extends B implements D {}
class B extends C {}

@Component
class Foo {
    Foo(A a) {}
    Foo(D d) {}
    Foo(B b) {}
    Foo(C c) {}
}
```
由于 Spring 进行依赖查找只能找到 A 作为构造方法的参数 bean 
构造方法 `Foo(A a) {}` 计 0 分，因为参数类型 A 和找到的 bean 类型完全相同，计 0 分
构造方法 `Foo(D d) {}` 计 1 分，因为参数类型 D 是 A 的上级接口，计 1 分
构造方法 `Foo(B b) {}` 计 2 分，因为参数类型 B 是 A 的上级类，计 2 分
构造方法 `Foo(C c) {}` 计 4 分，因为参数类型 C 是 B 的上级类，B 是 A 的上级类，计 2 + 2 = 4 分

### 严格模式

对于查找到的依赖的 Bean，如果 Bean 的类型与构造方法得参数类型相同，得分较小，如果类型不相同，则得分较大

## @Bean 方法重载
Spring 会把 `@Bean` 修饰的方法解析成 BeanDefinition：
例如：
```java
@Configuration
public class AppConfig {
    @Bean
    public static AService aService(){
        return new AService();
    }
    
    @Bean
    public AService aService(BService bService){
        return new AService();
    }
}
```
1. 如果方法不是 static 的，那么解析出来的 BeanDefinition 中：
    1. factoryBeanName 为 AppConfig 所对应的 beanName，比如"appConfig"
    2. factoryMethodName 为对应的方法名，比如 "aService"
    3. factoryClass为AppConfig.class
2. 如果方法是 static 的，那么解析出来的 BeanDefinition 中：
    1. factoryBeanName为null
    2. factoryMethodName 为对应的方法名，比如 "aService"
    3. factoryClass也为AppConfig.class

在由`@Bean`生成的 BeanDefinition 中，有一个重要的属性 `isFactoryMethodUnique`，用来表示 factoryMethod 是不是唯一。

当 `@Bean` 标注的方法不存在方法重载，则生成的 BeanDefinition 的 `isFactoryMethodUnique` 属性为 true，表示当前 Bean 的 factoryMethod 唯一。

当 `@Bean` 标注的方法出现了方法重载，比如两个 `@Bean` 的方法名相同，但参数不同，Spring 扫描到第一个 `@Bean` 方法时，会生成一个 aService 的 BeanDefinition，此时 `isFactoryMethodUnique` 为 true，当解析到第二个同名 `@Bean` 方法时，会判断出来 beanDefinitionMap 中已经存在一个 `aService` 的 BeanDefinition 了，则不会再创建一个 BeanDefinition，而会将之前的 BeanDefinition 的 `isFactoryMethodUnique` 修改为 false，表示该 Bean 的 factoryMethod 不唯一。

后续在根据 BeanDefinition 创建 Bean 时，会根据 `isFactoryMethodUnique` 判断
- 如果为 true，表示当前 BeanDefinition 只对应了一个 factoryMethod 方法，直接用这个方法来创建 Bean
- 如果为 false，表示当前 BeanDefinition 对应了多个 factoryMethod 方法，需要执行推断构造方法的逻辑，判断选择使用哪个方法来创建 Bean。

## 参考
- <https://www.cnblogs.com/zfcq/p/15938255.html>
