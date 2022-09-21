---
layout: article  
alias: 
title: 【理解Spring】Spring启动
date: 2022-08-17 23:15
tags: []
extends:
---

# 【理解Spring】Spring启动

## 概览
通常所说的 Spring 启动，就是构造 ApplicationContext 对象以及调用 `refresh()` 方法的过程，其中最核心的内容是 [Spring扫描] 和 [加载Bean]。  

Spring 启动过程主要执行了：
1.  构造一个 BeanFactory 对象
2.  解析配置类，得到 BeanDefinition，并注册到 BeanFactory 中
    1.  解析 `@ComponentScan`，并完成扫描
    2.  解析 `@Import`
    3.  解析 `@Bean`
    4.  ...
3.  初始化 MessageSource 对象（ApplicationContext 支持国际化）
4.  初始化 ApplicationEventMulticaster 对象（ApplicationContext 支持事件机制）
5.  把用户定义的 ApplicationListener 对象添加到 ApplicationContext 中，等 Spring 启动完成需要发布事件
6.  创建**非懒加载的单例 Bean** 对象，并缓存到 BeanFactory 的单例池中
7.  调用 Lifecycle Bean 的 start()方法
8.  发布 **ContextRefreshedEvent** 事件

由于 Spring 启动过程中要创建非懒加载的单例 Bean 对象，那么就需要用到 BeanPostProcessor，所以 Spring 在启动过程中还会做两件事：
1.  生成默认的 BeanPostProcessor 对象，并添加到 BeanFactory 中
    1.  `AutowiredAnnotationBeanPostProcessor`：处理 `@Autowired`、`@Value`
    2.  `CommonAnnotationBeanPostProcessor`：处理 `@Resource`、`@PostConstruct`、`@PreDestroy`
    3.  `ApplicationContextAwareProcessor`：处理 `ApplicationContextAware` 等回调
2.  找到外部用户所定义的 BeanPostProcessor 对象（类型为 BeanPostProcessor 的 Bean 对象），并添加到 BeanFactory 中

在理解 Spring 启动的代码流程之前，需要先理解一些核心概念

### BeanFactoryPostProcessor

`BeanPostProcessor` 表示 Bean 的后置处理器，用来对 Bean 进行加工；类似的 `BeanFactoryPostProcessor` 是 BeanFactory 的后置处理器，用来对 BeanFactory 进行加工。  

Spring 支持用户自定义实现 BeanFactoryPostProcessor，来对 BeanFactory 进行加工，比如：

```java
@Component
public class Azh3ngBeanFactoryPostProcessor implements BeanFactoryPostProcessor {
    @Override 
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {  
        BeanDefinition beanDefinition = beanFactory.getBeanDefinition("userService");  
        beanDefinition.setAutowireCandidate(false); 
    }
}
```

以上代码，自定义了类 `Azh3ngBeanFactoryPostProcessor` 实现 `BeanFactoryPostProcessor`，在方法 `postProcessBeanFactory()` 中拿到 BeanFactory，然后通过 BeanFactory 获取某个 BeanDefinition 对象并进行修改。由于这一步发生在 Spring 启动时，创建单例 Bean 之前，所以此时对 BeanDefinition 修改会生效。 

**注意**：在 `ApplicationContext` 内部有一个核心的 `DefaultListableBeanFactory`，它实现了 `ConfigurableListableBeanFactory` 和 `BeanDefinitionRegistry` 接口；  
`ConfigurableListableBeanFactory` 不能注册 BeanDefinition，只能获取 BeanDefinition 后做修改。  
 `BeanDefinitionRegistry` 是 Spring 提供的一个 BeanFactoryPostProcessor 的子接口，可以注册 BeanDefinition 。

### BeanDefinitionRegistryPostProcessor

```java
public interface BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor { 
    void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException;
}
```

`BeanDefinitionRegistryPostProcessor` 继承了 `BeanFactoryPostProcessor` 接口，并新增了一个方法 `postProcessBeanDefinitionRegistry()`，方法的参数为 `BeanDefinitionRegistry` ，其子类在 `postProcessBeanDefinitionRegistry()` 方法中可以注册 BeanDefinition 。比如：  

```java
@Component
public class Azh3ngBeanDefinitionRegistryPostProcessor implements BeanDefinitionRegistryPostProcessor {
    @Override 
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException {
        AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder.genericBeanDefinition().getBeanDefinition();
        beanDefinition.setBeanClass(User.class);
        registry.registerBeanDefinition("user", beanDefinition); 
    }
    
    @Override 
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        BeanDefinition beanDefinition = beanFactory.getBeanDefinition("userService");
        beanDefinition.setAutowireCandidate(false);
    }
}
```

### 理解 ApplicationContext.refresh()

```java
/**
 * Load or refresh the persistent representation of the configuration,
 * which might an XML file, properties file, or relational database schema.
 * <p>As this is a startup method, it should destroy already created singletons
 * if it fails, to avoid dangling resources. In other words, after invocation
 * of that method, either all or no singletons at all should be instantiated.
 * @throws BeansException if the bean factory could not be initialized
 * @throws IllegalStateException if already initialized and multiple refresh
 * attempts are not supported
 */ 
void refresh() throws BeansException, IllegalStateException;
```

> 翻译：加载或刷新持久化的配置，可能是 XML 文件、属性文件或关系数据库中存储的。由于这是一个启动方法，如果失败，它应该销毁已经创建的单例，以避免暂用资源。换句话说，在调用该方法之后，应该实例化所有的单例，或者根本不实例化单例 。

有个理念需要注意：ApplicationContext 关闭之后不代表 JVM 也关闭了，ApplicationContext 只是 JVM 中的一个对象。

在 Spring 的设计中，提供了**允许重复刷新**的 ApplicationContext 和**不允许重复刷新**（如果重复会报错）的 ApplicationContext。如：

```java
// 允许重复刷新
AbstractRefreshableApplicationContext extends AbstractApplicationContext
// 不允许重复刷新
GenericApplicationContext extends AbstractApplicationContext
```

`AnnotationConfigApplicationContext` 继承 `GenericApplicationContext`，所以它**不允许重复刷新**    
`AnnotationConfigWebApplicationContext` 继承 `AbstractRefreshableWebApplicationContext`，所以它**允许重复刷新**


### BeanFactoryPostProcessor 的执行顺序简述

1.  执行**通过 ApplicationContext 添加进来的** BeanDefinitionRegistryPostProcessor 的 postProcessBeanDefinitionRegistry() 方法
2.  执行 BeanFactory 中**实现了 PriorityOrdered 接口的** BeanDefinitionRegistryPostProcessor 的 postProcessBeanDefinitionRegistry()方法
3.  执行 BeanFactory 中**实现了 Ordered 接口的** BeanDefinitionRegistryPostProcessor 的 postProcessBeanDefinitionRegistry()方法
4.  执行 BeanFactory 中**其他的** BeanDefinitionRegistryPostProcessor 的 postProcessBeanDefinitionRegistry()方法
5.  执行**上面所有的** BeanDefinitionRegistryPostProcessor 的 postProcessBeanFactory()方法
6.  执行**通过 ApplicationContext 添加的** BeanFactoryPostProcessor 的 postProcessBeanFactory()方法
7.  执行 BeanFactory 中**实现了 PriorityOrdered 接口**的 BeanFactoryPostProcessor 的 postProcessBeanFactory()方法
8.  执行 BeanFactory 中**实现了 Ordered 接口**的 BeanFactoryPostProcessor 的 postProcessBeanFactory()方法
9.  执行 BeanFactory 中**其他的** BeanFactoryPostProcessor 的 postProcessBeanFactory()方法

### Lifecycle 的使用

Lifecycle 表示的是 ApplicationContext 的生命周期，可以定义一个 SmartLifecycle 来监听 ApplicationContext 的启动和关闭：

```java
@Component  
public class Azh3ngLifecycle implements SmartLifecycle {  
    private boolean isRunning = false;  
  
    @Override  
    public void start() {  
        System.out.println("启动");  
        isRunning = true;  
    }  
  
    @Override  
    public void stop() {          
        // 要触发stop()，要调用context.close()，或者注册关闭钩子（context.registerShutdownHook();）
        System.out.println("停止");  
        isRunning = false;  
    }
  
    @Override  
    public boolean isRunning() {  
        return isRunning;  
    }  
}
```

## 代码流程
以 `AnnotationConfigApplicationContext` 举例分析 Spring 的启动流程

Spring 启动代码：
```java
AnnotationConfigApplicationContext applicationContext = new AnnotationConfigApplicationContext(AppConfig.class);
```
或者
```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext();  
context.register(AppConfig.class);
context.refresh();
```
上面两段代码作用相同，都是进行 Spring 启动，以第二段代码说明，分为三个步骤：
1. 实例化 `AnnotationConfigApplicationContext`
2. 注册 [[AppConfig.class]]
3. context 调用 `refresh()` 方法

## 实例化 AnnotationConfigApplicationContext
实例化 AnnotationConfigApplicationContext 中包含三个步骤：
1. 调用父类的构造方法（`new GenericApplicationContext()`），实例化 `DefaultListableBeanFactory` 赋值给 beanFactory 属性
2. 实例化 `AnnotatedBeanDefinitionReader` 赋值给 reader 属性（将 class 解析为 BeanDefinition 存储到 `beanDefinitionMap` 中）
    1. 构造 `ConditionEvaluator`（解析 `@Conditional` 注解）
    2. beanFactory 设置 `dependencyComparator` 属性为 `AnnotationAwareOrderComparator`（解析处理 `@Order` 和 `@Priority` 注解）
    3. beanFactory 设置 `autowireCandidateResolver` 属性为 `ContextAnnotationAutowireCandidateResolver`（解析判断 bean 是否能被注入到其他类中）
    4. 注册 `ConfigurationClassPostProcessor` 类型的 BeanDefinition
    5. 注册 `AutowiredAnnotationBeanPostProcessor` 类型的 BeanDefinition
    6. 注册 `CommonAnnotationBeanPostProcessor` 类型的 BeanDefinition
    7. 注册 `PersistenceAnnotationBeanPostProcessor` 类型的 BeanDefinition
    8. 注册 `EventListenerMethodProcessor` 类型的 BeanDefinition，用来处理 `@EventListener` 注解
    9. 注册 `DefaultEventListenerFactory` 类型的 BeanDefinition，用来处理 `@EventListener` 注解
3. 实例化 `ClassPathBeanDefinitionScanner` 赋值给 scanner 属性
    1. 添加默认的扫描 Filter 到 `includeFilters`（`@Component`）

## 注册 Config 类
`context.register(`[[AppConfig.class]]`);`
使用 `beanFactory.reader` 解析传入的 [[AppConfig.class]] 生成 BeanDefinition

## ApplicationContext.refresh()
`org.springframework.context.support.AbstractApplicationContext#refresh`

### 准备 refresh（prepareRefresh()）
`org.springframework.context.support.AbstractApplicationContext#prepareRefresh`
1. 记录启动时间
2. 初始化环境变量：可以允许子容器设置一些内容到 Environment 中
    例如：在 Web 项目中，会将 servlet 相关的配置解析为环境变量（`org.springframework.web.context.support.AbstractRefreshableWebApplicationContext#initPropertySources`）
3. 校验是否缺失了**必须**的环境变量（`org/springframework/context/support/AbstractApplicationContext.java:661` -> `org.springframework.core.env.AbstractEnvironment#validateRequiredProperties`）

### obtainFreshBeanFactory()
`org.springframework.context.support.AbstractApplicationContext#obtainFreshBeanFactory`
进行 BeanFactory 的 refresh，并获取 BeanFactory

#### refreshBeanFactory
`org.springframework.context.support.AbstractApplicationContext#refreshBeanFactory`
调用子类的 `refreshBeanFactory()` 方法，具体实现由子类完成

#### getBeanFactory
`org.springframework.context.support.AbstractApplicationContext#getBeanFactory`
调用子类的 `getBeanFactory()` 方法，重新得到一个 BeanFactory


### prepareBeanFactory(beanFactory)
`org.springframework.context.support.AbstractApplicationContext#prepareBeanFactory`
1.  设置 beanFactory 的类加载器
2.  设置表达式解析器：StandardBeanExpressionResolver，用来解析 Spring 中的 EL 表达式
3.  添加默认的类型转换器：PropertyEditorRegistrar：ResourceEditorRegistrar，PropertyEditor 类型转化器注册器，用来注册一些默认的 PropertyEditor
4.  添加 `ApplicationContextAwareProcessor`：执行 `EnvironmentAware`、`ApplicationEventPublisherAware` 等回调方法
5.  添加 **ignoredDependencyInterface**：向 `beanFactory` 的 `Set<Class<?>> ignoredDependencyInterfaces` 属性中添加接口类，使添加的接口类中的 `setXXX()` 方法在 `BY_TYPE` 类型的自动注入的时候不执行。例如：如果某个类实现 `EnvironmentAware` 接口，则必须实现它的 `setEnvironment()` 方法，而这个 set 方法 Spring 在自动注入时不会调用，在回调 Aware 接口时才调用（**注意**，这个功能仅限于 `BY_TYPE` 类型的自动注入，也即包括 1. xml 中 bean 标签设置为 `autowire="byType"`；2. `@Bean(autowire = Autowire.BY_TYPE)` 注解设置为 `BY_TYPE`。`@Autowired` 注解会忽略此属性，也就是说，继承了 `EnvironmentAware` 等这些类的 Bean 的 `setXXX` 方法在 Bean 的生命周期中会执行两次，一次是 `AutowiredAnnotationBeanPostProcessor` 执行注入，一次是 `ApplicationContextAwareProcessor` 执行 aware 回调）。添加的接口类包括：
     - EnvironmentAware
     - EmbeddedValueResolverAware
     - ResourceLoaderAware
     - ApplicationEventPublisherAware
     - MessageSourceAware
     - ApplicationContextAware
     - ApplicationStartupAware
     - 另外在构造 BeanFactory 的时候就已经提前添加了三个：
     - BeanNameAware
     - BeanClassLoaderAware
     - BeanFactoryAware
6. 向 **resolvableDependencies** 中添加基础类：将 Spring 基础对象添加到 `BeanFactory` 的 `Map<Class<?>, Object> resolvableDependencies` 属性中，在进行 `BY_TYPE` 类型的自动注入时，会先从这个 Map 中根据类型找 bean。添加的类包括：
    1.  BeanFactory.class：当前 BeanFactory 对象
    2.  ResourceLoader.class：当前 ApplicationContext 对象
    3.  ApplicationEventPublisher.class：当前 ApplicationContext 对象
    4.  ApplicationContext.class：当前 ApplicationContext 对象
7.  添加 `ApplicationListenerDetector`：是一个 BeanPostProcessor，用来判断 Bean 是不是 ApplicationListener，如果是则把这个 Bean 添加到 ApplicationContext 中去（注意 ApplicationListener 只能是单例的）
8.  添加 `LoadTimeWeaverAwareProcessor`：是一个 BeanPostProcessor，用来判断某个 Bean 是否实现了 `LoadTimeWeaverAware` 接口，如果是，则把 ApplicationContext 中的 `loadTimeWeaver` 回调 `setLoadTimeWeaver` 方法设置给该 Bean
9.  添加一些单例 bean 到单例池（如果没有就添加）（beanName: Bean 对象）：
    1.  `environment` ：Environment 对象
    2.  `systemProperties` ：System.getProperties() 返回的 Map 对象
    3.  `systemEnvironment` ：System.getenv() 返回的 Map 对象
 
### AbstractApplicationContext.postProcessBeanFactory(beanFactory)
使用*模板方法*的设计模式，提供给 AbstractApplicationContext 的子类进行扩展，调用子类的 `refreshBeanFactory()` 方法，具体实现由子类完成，子类可以继续向 BeanFactory 中再添加一些自定义的类，例如 `GenericWebApplicationContext` 中执行了
- `beanFactory.addBeanPostProcessor(new ServletContextAwareProcessor(this.servletContext));`
- `beanFactory.ignoreDependencyInterface(ServletContextAware.class);`

### ※invokeBeanFactoryPostProcessors(beanFactory)
- `org.springframework.context.support.AbstractApplicationContext#refresh`
    - `org.springframework.context.support.AbstractApplicationContext#invokeBeanFactoryPostProcessors` 
        - `org.springframework.context.support.PostProcessorRegistrationDelegate#invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory, List<BeanFactoryPostProcessor>)`

#### 概述
- 先执行所有 `BeanDefinitionRegistryPostProcessor`，扫描并将 BeanDefinition 添加到 BeanFactory 中
- 然后执行所有 `BeanDefinitionRegistryPostProcessor` 的 `postProcessBeanFactory()` 方法；
- 然后执行所有 `BeanFactoryPostProcessor` 的 `postProcessBeanFactory()`
- 同一对象的方法不会重复执行

#### 代码流程
1. 获取 ApplicationContext 中的 `beanFactoryPostProcessors`（除非在 [[#ApplicationContext refresh]] 之前向容器中添加了 BeanFactoryPostProcessor，否则一般情况下为空）
    1. 遍历获取到的 `beanFactoryPostProcessors` 
        1. 如果是 `BeanDefinitionRegistryPostProcessor` 则执行 `postProcessBeanDefinitionRegistry()`，并添加到缓存
        2. 否则添加到缓存
2. 从 beanFactory 中获取 `BeanDefinitionRegistryPostProcessor` 类型、并且实现了 `PriorityOrdered` 接口的 `postProcessorNames`
    1. 遍历 `postProcessorNames`
        1. 通过 beanFactory.[[AbstractBeanFactory.getBean()|getBean()]] 实例化 `BeanDefinitionRegistryPostProcessor`，并添加到缓存 `currentRegistryProcessors`（除非手动添加，否则通常此时只有 `ConfigurationClassPostProcessor` ）
3. 排序并执行 `PostProcessorRegistrationDelegate#invokeBeanDefinitionRegistryPostProcessors` 
    1. 执行 `BeanDefinitionRegistryPostProcessor#postProcessBeanDefinitionRegistry`
        1. 执行 `ConfigurationClassPostProcessor#postProcessBeanDefinitionRegistry`
            1. 执行 `org.springframework.context.annotation.`[[#※ConfigurationClassPostProcessor processConfigBeanDefinitions]]（**Spring扫描**）
4. 清除缓存 `currentRegistryProcessors`
5. 从 beanFactory 中获取 `BeanDefinitionRegistryPostProcessor` 类型的、实现了 `Ordered` 接口、**并且未执行过的**  `postProcessorNames`
    1. 遍历 `postProcessorNames`
        1. 通过 beanFactory.[[AbstractBeanFactory.getBean()|getBean()]] 实例化 `BeanDefinitionRegistryPostProcessor`，并添加到缓存 `currentRegistryProcessors`
6. 排序、执行 `BeanDefinitionRegistryPostProcessor.postProcessBeanDefinitionRegistry()`、清除缓存 `currentRegistryProcessors`
7. 循环判断 beanFactory 中是否还有**未执行**的 `BeanDefinitionRegistryPostProcessor`，如果有
    1. 从 beanFactory 中获取 `BeanDefinitionRegistryPostProcessor` 类型的 `postProcessorNames`
    2. 实例化（[[AbstractBeanFactory.getBean()|getBean()]]）
    3. 排序
    4. 执行 `postProcessBeanDefinitionRegistry`（执行过程中可能会继续向 beanFactory 中添加 `BeanDefinitionRegistryPostProcessor`，则会继续循环找到并执行）
    5. 清除缓存
8. 执行 `org.springframework.context.support.PostProcessorRegistrationDelegate#invokeBeanFactoryPostProcessors` 传入 所有 `BeanDefinitionRegistryPostProcessor`
    1. 循环执行所有 `BeanDefinitionRegistryPostProcessor` 的 `postProcessBeanFactory` 方法
        1. 执行 [[#ConfigurationClassPostProcessor.postProcessBeanFactory()]]
9. 执行 `org.springframework.context.support.PostProcessorRegistrationDelegate#invokeBeanFactoryPostProcessors` 传入 **手动添加的** `BeanFactoryPostProcessor`
    1. 循环执行所有 ``BeanFactoryPostProcessor`` 的 `postProcessBeanFactory` 方法
10. 从 beanFactory 中获取扫描得到的 `BeanFactoryPostProcessor`
11. 忽略已执行的 `BeanFactoryPostProcessor`
12. 根据类型分类：实现了 `PriorityOrdered` （直接实例化）、实现了 `Ordered` 、其他
13. 排序并执行 实现了 `PriorityOrdered` 的 `BeanFactoryPostProcessor`
14. 实例化、排序并执行 实现了 `Ordered` 的 `BeanFactoryPostProcessor`
15. 实例化并执行其他的 `BeanFactoryPostProcessor` 的 `postProcessBeanFactory()` 方法
16. 清除缓存

#### ※ConfigurationClassPostProcessor.processConfigBeanDefinitions()
`org.springframework.context.annotation.ConfigurationClassPostProcessor#processConfigBeanDefinitions`

简述：

代码流程：
1. 获取所有 BeanDefinition 遍历判断是否为配置类（`org.springframework.context.annotation.ConfigurationClassUtils#checkConfigurationClassCandidate`），是则添加到临时变量（判断 [[AppConfig.class]] 是否为配置类）
    1. 如果类上有 `@Configuration` 注解，并且 `proxyBeanMethods` 属性为 true（默认），则为 `CONFIGURATION_CLASS_FULL`（[[Full 配置类]]）
    2. 如果类上有`@Configuration` 注解，并且 `proxyBeanMethods` 属性为 false，则为 `CONFIGURATION_CLASS_LITE` （Lite 配置类）
    3. 如果类不是接口类，类上标注有 `@Component`、`@ComponentScan`、`@Import`、`@ImportResource` 其中任意一个，或者类中有 `@Bean` 注解的方法，则为 `CONFIGURATION_CLASS_LITE` （Lite 配置类）
2. 将临时变量通过 `@Order` 注解排序
3. 实例化 `ConfigurationClassParser`
4. 递归使用 `ConfigurationClassParser` 解析配置类（实际为 `do {} while (!candidates.isEmpty());`）
    1. 通过 `ConfigurationClassParser.parse()` 解析步骤 1 得到的配置类（[[#解析配置类]]）
    2. 拿到所有解析过的配置类，遍历
    3. 利用 reader 来进一步解析配置类（`reader.loadBeanDefinitions(configClasses)`）
        1. 如果配置类是通过 `@Import` 注解导入进来的，则把这个类生成一个 BeanDefinition，同时解析这个类上 `@Scope`，`@Lazy` 等注解信息，生成并注册 BeanDefinition
        2. 如果配置类中存在 `BeanMethod`（也就是定义了一些 @Bean 方法），则解析这些 `BeanMethod`，并生成对应的 BeanDefinition，并注册
        3. 如果配置类中导入了一些资源文件，比如 xx.xml，则解析这些xx.xml文件，得到并注册 BeanDefinition
        4. 如果配置类中导入了 `ImportBeanDefinitionRegistrar`，则执行对应的 `registerBeanDefinitions` 进行BeanDefinition 的注册
    4. 判断上一步执行完之后，是否有新增的 BeanDefinition，有则找出新增的 BeanDefinition，判断是否为配置类，是则继续解析（步骤4）

#### 解析配置类
`org.springframework.context.annotation.ConfigurationClassParser#parse(java.util.Set<org.springframework.beans.factory.config.BeanDefinitionHolder>)`  
-> `org.springframework.context.annotation.ConfigurationClassParser#parse(java.lang.String, java.lang.String)`  
-> `org.springframework.context.annotation.ConfigurationClassParser#processConfigurationClass`  
代码流程：  
1. `org.springframework.context.annotation.ConfigurationClassParser#processConfigurationClass`
2. 判断如果某个 Bean 被多次 `@Import` 导入，则合并 `importedBy` 属性
3. 调用 `doProcessConfigurationClass`，如果返回父类，则递归解析父类（`do {} while()`）
4. 解析配置类（`org.springframework.context.annotation.ConfigurationClassParser#doProcessConfigurationClass`）（解析 [[AppConfig.class]]）
    1. 判断类是否有 `@Component` 注解，有则解析类的内部类，判断是否是配置类，是则进一步解析（递归调用 `processConfigurationClass()`）
    2. 判断类是否有 `@PropertySources` 注解，有则解析指定的配置文件，并设置到 `environment` 中
    3. 判断类是否有 `@ComponentScans` 注解，有则进行 [[Spring扫描]]，得到 `BeanDefinition`，并注册到 BeanFactory 中；遍历得到的 `BeanDefinition` 判断是否为配置类，如果是继续解析配置类（递归调用 `ConfigurationClassParser.parse()`）
    4. 调用方法 `processImports()`，判断类是否有 `@Import` 注解，有则解析获取 `@Import` 中指定的类
        1. 判断指定类的类型
            1. 如果实现了 `ImportSelector` 接口
                1. 判断类如果实现了 `DeferredImportSelector` ，添加到缓存，在 [[#解析配置类]]（`ConfigurationClassParser.parse()`） 方法执行完毕后，执行缓存的 `DeferredImportSelector.selectImports()`
                2. 否则，执行 `selectImports()` 方法得到类名，然后将这个类传入 `processImports()` 进行解析（递归解析）
            2. 如果实现了 `ImportBeanDefinitionRegistrar` 接口，则生成一个 `ImportBeanDefinitionRegistrar` 实例对象，添加到配置类对象中的 `importBeanDefinitionRegistrars` 属性中
            3. 否则（没有实现上述两个接口），[[#解析配置类]]
    5. 如果配置类上存在 `@ImportResource` 注解，把标注的 Resource 路径填充后，存到配置类对象的 `importedResources` 属性中（未解析文件）
    6. 如果配置类中存在 `@Bean` 的方法，那么则把这些方法封装为 BeanMethod 对象，并添加到配置类对象中的 `beanMethods` 属性中。
    7. 递归向上查找实现的接口内是否有 `@Bean` 的 default 默认方法（`org.springframework.context.annotation.ConfigurationClassParser#processInterfaces`）
        1. ，判断如果配置类实现了接口，且接口内部包含被 `@Bean` 注解的 `defult` 方法，向配置类添加 BeanMethod 后续解析使用
        2. 继续向上查找父接口
    8. 如果配置类有父类，则将父类返回，继续执行步骤 1.1.1 ，将父类当做配置类进行解析
5. 将解析的配置类添加到缓存 `configurationClasses`

**注意**：在 Spring 扫描过程中，可能出现 Bean 覆盖
1. `@Component` 注解覆盖：当 `@Component` 注解指定了相同的 bean name 时，启动会报错
2. `@Bean` 注解覆盖：当 `@Bean` 注解了重载的方法，会进行[[Spring推断构造方法]]，只会生成一个 BeanDefinition
3. `@Component` 和 `@Bean` 注解同时存在：一般会先解析 `@Component` 的 Bean，后解析 `@Bean` 的方法，如果 BeanFactory 允许 BeanDefinition 覆盖（默认），则覆盖 BeanDefinition，所以最终 BeanDefinition 以 `@Bean` 方法为准

#### ConfigurationClassPostProcessor.postProcessBeanFactory()
1. 判断如果没有执行过 `processConfigBeanDefinitions()` 方法，则执行
2. 执行 `enhanceConfigurationClasses(beanFactory)`
    1. 找到并 [[增强 Full 配置类]]

### registerBeanPostProcessors(beanFactory)
前面的步骤完成了扫描，这一步就会把 BeanFactory 中所有的 BeanPostProcessor 找出来（包括自定义的 BeanPostProcessor）实例化，并添加到 BeanFactory 中去（属性**beanPostProcessors**），最后再重新添加一个 ApplicationListenerDetector 对象（其实添加了，这里是为了把 ApplicationListenerDetector 移动到最后）

### initMessageSource()
如果 BeanFactory 中存在一个叫做"**messageSource**"的 BeanDefinition，那么就会把这个 Bean 对象创建出来并赋值给 ApplicationContext 的 messageSource 属性，让 ApplicationContext 拥有**国际化**的功能，否则将创建 `DelegatingMessageSource` 作为默认值。

### initApplicationEventMulticaster()
如果 BeanFactory 中存在一个叫做"**applicationEventMulticaster**"的 BeanDefinition，那么就会把这个 Bean 对象创建出来并赋值给 ApplicationContext 的 applicationEventMulticaster 属性，让 ApplicationContext 拥有**事件发布**的功能，否则创建 `SimpleApplicationEventMulticaster` 当做默认的时间发布器

### onRefresh()
提供给 AbstractApplicationContext 的子类进行扩展

### registerListeners()
- 从 BeanFactory 中获取 ApplicationListener （事件监听器）类型的 beanName，添加到 ApplicationContext 中的事件广播器 `applicationEventMulticaster` 中，并将所有还未被调用 [getBean()](./AbstractBeanFactory.getBean().md) 方法创建 Bean 对象的 beanName 添加到 `ApplicationEventMulticaster` 中，后续在 `ApplicationEventMulticaster` 调用 `getApplicationListeners()` 方法时再根据 beanName 创建 Bean
- 判断是否有 `earlyApplicationEvents`，如果有就使用事件广播器发布 （`earlyApplicationEvents` 表示在事件广播器还没生成之前 ApplicationContext 所发布的事件）

### finishBeanFactoryInitialization(beanFactory)
- 添加 conversionService
- 添加占位符解析器（`${}`）:`beanFactory.addEmbeddedValueResolver()`
- 实例化所有 `LoadTimeWeaverAware`
- 停止使用临时 ClassLoader 进行类型匹配
- [[#初始化所有非懒加载单例Bean]]


### finishRefresh()
BeanFactory 初始化已经完成，这是 Spring 启动的最后一步
1. ApplicationContext 设置 lifecycleProcessor，默认情况下设置的是 DefaultLifecycleProcessor
2. 调用 lifecycleProcessor 的 onRefresh()方法，如果是 DefaultLifecycleProcessor，那么会获取所有类型为 Lifecycle 的 Bean 对象，分组，然后调用它的 start() 方法，这就是 ApplicationContext 的生命周期扩展机制 #Spring扩展点
3. 发布 **ContextRefreshedEvent** 事件


## 配置类的定义
在 Spring 中，当类满足以下特征，会被 Spring 当做配置类解析
1. 如果类上有`@Configuration` 注解，并且 `proxyBeanMethods` 属性为 true（默认），则为 `CONFIGURATION_CLASS_FULL`（Full 配置类）
2. 如果类上有`@Configuration` 注解，并且 `proxyBeanMethods` 属性为 false，则为 `CONFIGURATION_CLASS_LITE` （Lite 配置类）
3. 如果类不是接口类，类上标注有 `@Component`、`@ComponentScan`、`@Import`、`@ImportResource` 其中任意一个，或者类中有 `@Bean` 注解的方法，则为 `CONFIGURATION_CLASS_LITE` （Lite 配置类）
4. 被 `@Import` 标注的类

## 参考
- https://www.cnblogs.com/summerday152/p/13639896.html
- https://zhuanlan.zhihu.com/p/367076177
- https://blog.csdn.net/qq_35190492/article/details/110383213
- https://blog.csdn.net/a745233700/article/details/113761271


