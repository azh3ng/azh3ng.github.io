---
layout: article  
title: 【理解Spring】Bean 创建  
date: 2022-01-08 23:26  
category:  
tags: [Spring]
---
# 【理解Spring】Bean 创建

在 [AbstractBeanFactory.getBean()](https://azh3ng.com/2022/01/08/%E7%90%86%E8%A7%A3AbstractBeanFactory.getBean().html) 中，如果从单例池没有获取到 Bean，则创建 Bean

代码入口：
`AbstractAutowireCapableBeanFactory.createBean(String beanName, RootBeanDefinition, Object[] args)`

> Central method of this class: creates a bean instance,  populates the bean instance, applies post-processors, etc.

此方法主要目的：创建 Bean 实例，填充 Bean 实例，应用/执行 Post-Processor 等

## 概览
1. Spring扫描并生成BeanDefinition
2. [合并 BeanDefinition](#合并-BeanDefinition)
3. [加载类](#加载类)
4. [实例化前 InstantiationAwareBeanPostProcessor](#实例化前(InstantiationAwareBeanPostProcessor))
5. [实例化 new出对象](#实例化-new出对象)
   1. [Supplier 创建对象](#Supplier-创建对象)
   2. [工厂方法创建对象](#工厂方法创建对象)
   3. [推断构造方法](#推断构造方法)
6. [BeanDefinition 的后置处理](#BeanDefinition-的后置处理)
7. [实例化后](#实例化后)
8. [自动注入](#自动注入)
9. [处理属性](#处理属性)
10. [执行 Aware](#执行-Aware)
11. [初始化前](#初始化前)
12. [初始化(Initializing)](#初始化)
13. [初始化后](#初始化后)

## 加载类

`BeanDefinition` 合并之后，就可以创建 Bean 对象了。 创建 Bean 必须先实例化对象，实例化就必须先加载当前 `BeanDefinition` 所对应的类（Class）  
在 `AbstractAutowireCapableBeanFactory.createBean()` 方法中调用：

```java
Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
```

去加载类，如果 beanClass 属性的类型是 Class，那么就直接返回；
如果不是，则会根据类名进行加载（doResolveBeanClass()），代码如下：

```java
if(mbd.hasBeanClass()){
    return mbd.getBeanClass();
}
if(System.getSecurityManager()!=null){
    return AccessController.doPrivileged((PrivilegedExceptionAction<Class<?>>)()->
        doResolveBeanClass(mbd,typesToMatch),getAccessControlContext());
} else {
    return doResolveBeanClass(mbd,typesToMatch);
}
```

```java
public boolean hasBeanClass(){
    return(this.beanClass instanceof Class);
}
```

Spring 会利用 `BeanFactory` 所设置的类加载器来加载类，如果没有设置，则使用 `ClassUtils.getDefaultClassLoader()` 所返回的默认类加载器来加载。

```java
// 1. 优先返回当前线程中的 ClassLoader
// 2. 线程中类加载器为null的情况下，返回ClassUtils类的类加载器
// 3. 如果ClassUtils类的类加载器为空，表示 ClassUtils 是被 Bootstrap 类加载器加载的，那么则返回系统类加载器
ClassUtils.getDefaultClassLoader()
```

## 实例化前(InstantiationAwareBeanPostProcessor)

当前 `BeanDefinition` 对应的类成功加载后，就可以实例化对象了。
在实例化对象之前，Spring 提供了一个扩展点，允许在实例化之前做一些启动动作，这个扩展点叫 `InstantiationAwareBeanPostProcessor.postProcessBeforeInstantiation()`

例如：假设希望在 userService 这个 Bean 实例化前做某些操作

```java
@Component
public class Azh3ngBeanPostProcessor implements InstantiationAwareBeanPostProcessor {
    @Override
    public Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            System.out.println("实例化前.doSomeThing...");
        }
        return null;
    }
}
```

**注意**：`postProcessBeforeInstantiation()` 方法有返回值：如果返回值不为空，表示返回的对象即为这个 Bean，不需要 Spring 实例化，并且后续 Spring 依赖注入也不会进行，直接执行[初始化后](#初始化后)  

## 实例化(new 出对象)
`AbstractAutowireCapableBeanFactory.doCreateBean` ->
`AbstractAutowireCapableBeanFactory.createBeanInstance()` 

根据 `BeanDefinition` 创建对象

### Supplier 创建对象

首先判断 BeanDefinition 中是否设置了 Supplier，如果设置了则调用 Supplier 的 get() 得到对象。

直接使用 BeanDefinition 对象来设置 Supplier，比如：

```java
AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder.genericBeanDefinition().getBeanDefinition();
beanDefinition.setInstanceSupplier(new Supplier<Object>() {
    @Override
    public Object get() {
        return new UserService();
    }
});
context.registerBeanDefinition("userService", beanDefinition);
```

### 工厂方法创建对象

如果没有设置 Supplier，则检查 BeanDefinition 中是否设置了 factoryMethod，也就是工厂方法，有两种方式可以设置 factoryMethod，比如：

**方式一**：`factory-method` 标签指定静态方法作为 factoryMethod

```xml
<bean id="userService" class="com.azh3ng.service.UserService" factory-method="createUserService" />
```

对应的 UserService 类为：

```java
public class UserService {

    public static UserService createUserService() {
        System.out.println("执行createUserService()");
        UserService userService = new UserService();
        return userService;
    }

    public void test() {
        System.out.println("test");
    }

}
```

**方式二**：`factory-bean` 和 `factory-method` 指定其他 Bean 的方法作为 factoryMethod

```xml
<bean id="commonService" class="com.azh3ng.service.CommonService"/>
<bean id="userService1" factory-bean="commonService" factory-method="createUserService" />
```

对应的 CommonService 的类为：

```java
public class CommonService {
    public UserService createUserService() {
        return new UserService();
    }
}
```

Spring 发现当前 BeanDefinition 设置了工厂方法后，就会区分这两种方式，然后调用工厂方法得到对象。

**注意**：通过 `@Bean` 所定义的 `BeanDefinition`，是存在 `factoryMethod` 和 `factoryBean` 的
也就是和上面的方式二非常类似，`@Bean` 所注解的方法就是 `factoryMethod`
`AppConfig` 对象就是 factoryBean。如果 `@Bean` 所注解的方法是 `static` 的，那么对应的就是方式一

### 推断构造方法

[Spring推断构造方法](https://azh3ng.com/2021/12/15/理解Spring推断构造方法.html)

#### @Lookup

额外的，在推断构造方法中除了会 选择构造方法 以及 查找入参对象，会还判断是否在对应的类中是否存在使用 `@Lookup` 注解的方法。如果存在则把该方法封装为 `LookupOverride` 对象并添加到 `BeanDefinition` 中。

在实例化时，如果判断出来当前 BeanDefinition 中没有 LookupOverride，那就直接用构造方法反射得到一个实例对象。如果存在 LookupOverride 对象，也就是类中存在被 `@Lookup` 注解的方法，就会生成一个代理对象。

@Lookup 注解就是**方法注入**，使用 demo 如下：

```java
@Component
public class UserService {

    private OrderService orderService;

    public void test() {
        OrderService orderService = createOrderService();
        System.out.println(orderService);
    }

    @Lookup("orderService")
    public OrderService createOrderService() {
        return null;
    }

}
```

## BeanDefinition 的后置处理

Bean 对象实例化出来之后，接下来就需要给对象的属性赋值（依赖注入）了。但在给属性赋值之前，Spring 提供了一个扩展点
`MergedBeanDefinitionPostProcessor.postProcessMergedBeanDefinition()` 可以对此时的 BeanDefinition 进行加工，比如：

```java
@Component
public class DemoMergedBeanDefinitionPostProcessor implements MergedBeanDefinitionPostProcessor {

    @Override
    public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
        if ("userService".equals(beanName)) {
            beanDefinition.getPropertyValues().add("orderService", new OrderService());
        }
    }
}
```

在 Spring 中，`AutowiredAnnotationBeanPostProcessor` 继承 `MergedBeanDefinitionPostProcessor`，
它的 `postProcessMergedBeanDefinition()` 中会去查找注入点，并缓存在 Map 中（`injectionMetadataCache`），用于后续的依赖注入。

## 实例化后

在 Bean 实例化后，Spring 提供了一个扩展点：`InstantiationAwareBeanPostProcessor.postProcessAfterInstantiation()`，但是 Spring 中使用很少。
比如：

```java
@Component
public class DemoInstantiationAwareBeanPostProcessor implements InstantiationAwareBeanPostProcessor {

    @Override
    public boolean postProcessAfterInstantiation(Object bean, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            UserService userService = (UserService) bean;
            userService.test();
        }
        return true;
    }
}
```

上述代码就是对 userService 所实例化出来的对象进行处理。

## 自动注入

[理解 Spring 依赖注入](https://azh3ng.com/2021/12/15/%E4%BE%9D%E8%B5%96%E6%B3%A8%E5%85%A5.html)

## 处理属性(InstantiationAwareBeanPostProcessor.postProcessProperties())

Spring 在 `InstantiationAwareBeanPostProcessor.postProcessProperties()` 扩展点处理 `@Autowired`、`@Resource`、`@Value` 等注解。
开发者可以实现一个自定义的自动注入功能，比如：

```java
@Component
public class DemoInstantiationAwareBeanPostProcessor implements InstantiationAwareBeanPostProcessor {

    @Override
    public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            for (Field field : bean.getClass().getFields()) {
                if (field.isAnnotationPresent(DemoInject.class)) {
                    field.setAccessible(true);
                    try {
                        field.set(bean, "123");
                    } catch (IllegalAccessException e) {
                        e.printStackTrace();
                    }
                }
            }
        }

        return pvs;
    }
}
```

## 执行 Aware

完成了属性赋值之后，Spring 会执行一些回调，包括：

1. `BeanNameAware` ：回传 beanName 给 bean 对象。
2. `BeanClassLoaderAware` ：回传 classLoader 给 bean 对象。
3. `BeanFactoryAware` ：回传 beanFactory 给对象。

## 初始化前

Spring 提供 `BeanPostProcessor.postProcessBeforeInitialization()` 作为**初始化前**的扩展点

比如:

```java
@Component
public class Azh3ngBeanPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            System.out.println("初始化前");
        }
        return bean;
    }
}
```

利用初始化前，可以对完成了依赖注入的 Bean 进行处理。

在 Spring 中：
1. `InitDestroyAnnotationBeanPostProcessor` 会在初始化前这个步骤中执行 `@PostConstruct` 的方法，
2. `ApplicationContextAwareProcessor` 会在初始化前这个步骤中进行其他 Aware 的回调：
   1. `EnvironmentAware` ：回传环境变量
   2. `EmbeddedValueResolverAware` ：回传占位符解析器
   3. `ResourceLoaderAware` ：回传资源加载器
   4. `ApplicationEventPublisherAware` ：回传事件发布器
   5. `MessageSourceAware` ：回传国际化资源
   6. `ApplicationStartupAware` ：回传应用其他监听对象，可忽略
   7. `ApplicationContextAware` ：回传 Spring 容器 ApplicationContext

## 初始化(Initializing)

1. 查看当前 Bean 对象是否实现了 `InitializingBean` 接口，如果实现了就调用其 `afterPropertiesSet()` 方法
2. 执行 `BeanDefinition` 中指定的初始化方法

## 初始化后

Spring 提供的 `BeanPostProcessor.postProcessAfterInitialization()` 是 Bean 创建生命周期中的最后一个步骤

比如：
```java
@Component
public class Azh3ngBeanPostProcessor implements BeanPostProcessor {
    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            System.out.println("初始化后");
        }

        return bean;
    }
}
```

可以在这个步骤中，对 Bean 最终进行处理，Spring 中的 [[AOP]] 就是基于初始化后实现的，**初始化后返回的对象才是最终的 Bean 对象**。

## BeanPostProcessor 小结

- 加载类（`AbstractAutowireCapableBeanFactory.resolveBeanClass()`）
- 实例化前（`AbstractAutowireCapableBeanFactory.resolveBeforeInstantiation()`）
    - `AbstractAutowireCapableBeanFactory.java#applyBeanPostProcessorsBeforeInstantiation()`
        - `InstantiationAwareBeanPostProcessor.postProcessBeforeInstantiation()`
            - 此时如果方法返回不为空，则直接执行初始化后
- 创建 Bean（`AbstractAutowireCapableBeanFactory.doCreateBean()`）
    - 实例化（`AbstractAutowireCapableBeanFactory.createBeanInstance()`）
        - ==TODO==
    - 修改BeanDefinition（`AbstractAutowireCapableBeanFactory.applyMergedBeanDefinitionPostProcessors`）
        - `MergedBeanDefinitionPostProcessor.postProcessMergedBeanDefinition()`
          - 寻找[[依赖注入#自动注入]]的注入点（[[依赖注入#寻找注入点]]），并缓存 
          - 可以自定义 PostProcessor 继承`MergedBeanDefinitionPostProcessor`，在方法`postProcessMergedBeanDefinition()`中修改 BeanDefinition，执行`addPropertyValue()`等操作
    - 属性填充（`AbstractAutowireCapableBeanFactory.populateBean()`）
        - 实例化后（`InstantiationAwareBeanPostProcessor.postProcessAfterInstantiation()`）
        - 自动注入/属性赋值
            - `AutowireCapableBeanFactory.AUTOWIRE_BY_NAME` 或 `AutowireCapableBeanFactory.AUTOWIRE_BY_TYPE`
            - 执行 Spring 自带的依赖注入 `org.springframework.beans.factory.annotation.Autowire`
        - 依赖注入（`AbstractAutowireCapableBeanFactory.java#1430`）
            - 执行 `AutowiredAnnotationBeanPostProcessor.postProcessProperties()`处理 `@Autowire`、`@Value` 等注解
                - 注意，当**修改 BeanDefinition**时对bean属性赋值过，则 Autowire 不会再次赋值
    - 初始化（`AbstractAutowireCapableBeanFactory.initializeBean()`）
        - 调用 Aware 接口的方法（`AbstractAutowireCapableBeanFactory.invokeAwareMethods()`）
        - 初始化前（`AbstractAutowireCapableBeanFactory.applyBeanPostProcessorsBeforeInitialization`）
            - 执行 `BeanPostProcessor.postProcessBeforeInitialization()`
            - `@PostConstruct` 标注的方法在此执行（`CommonAnotationBeanPostProcessor`）
            - `ApplicationContextAwareProcessor.invokeAwareInterfaces()` 在此执行注入
                - EnvironmentAware
                - EmbeddedValueResolverAware
                - ResourceLoaderAware
                - ApplicationEventPublisherAware
                - MessageSourceAware
                - ApplicationContextAware
        - 初始化（`AbstractAutowireCapableBeanFactory.invokeInitMethods()`）
            - 执行`InitializingBean.afterPropertiesSet()` 
            - 反射调用初始化方法（`AbstractAutowireCapableBeanFactory.invokeCustomInitMethod()`）
                - `initMethod.invoke(bean)`
        - 初始化后（`applyBeanPostProcessorsAfterInitialization()`）
            - 调用 `BeanPostProcessor.postProcessAfterInitialization()`
- 注册 Bean 销毁（`AbstractAutowireCapableBeanFactory.registerDisposableBeanIfNecessary()`）
