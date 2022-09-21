---
layout: article  
title: 【理解Spring】ApplicationContext
date: 2022-01-08 23:16
category:  
tags: [Spring]
---

# 【理解Spring】ApplicationContext

在 Spring 中 `ApplicationContext` 继承了 `ListableBeanFactory` 和 `HierarchicalBeanFactory`，而 `ListableBeanFactory` 和 `HierarchicalBeanFactory` 都继承至 `BeanFactory`, 所以可以认为 `ApplicationContext` 继承了 `BeanFactory`
```java
public interface ApplicationContext extends EnvironmentCapable, ListableBeanFactory, HierarchicalBeanFactory,
        MessageSource, ApplicationEventPublisher, ResourcePatternResolver {
}
```
不过 `ApplicationContext` 比 `BeanFactory` 更加强大，`ApplicationContext` 还基础了其他接口，比如 `MessageSource` 表示国际化，`ApplicationEventPublisher` 表示事件发布，`EnvironmentCapable` 表示获取环境变量，等等

ApplicationContext 有两个比较重要的实现类：
- [AnnotationConfigApplicationContext](#AnnotationConfigApplicationContext)
- [ClassPathXmlApplicationContext](#ClassPathXmlApplicationContext)

### AnnotationConfigApplicationContext
![ApplicationContext类继承结构](./attachments/Spring核心接口-1639837290449.png)
- `ConfigurableApplicationContext` ：继承了 ApplicationContext 接口，增加了，添加事件监听器、添加 BeanFactoryPostProcessor、设置 Environment，获取 ConfigurableListableBeanFactory 等功能
- `AbstractApplicationContext` ：实现了 `ConfigurableApplicationContext` 接口
- `GenericApplicationContext` ：继承了 `AbstractApplicationContext`，实现了 `BeanDefinitionRegistry` 接口，拥有了所有 `ApplicationContext` 的功能，并且可以注册 `BeanDefinition`，注意这个类中有一个属性(DefaultListableBeanFactory beanFactory)
- `AnnotationConfigRegistry` ：可以单独注册某个为类为 BeanDefinition（可以处理该类上的 `@Configuration` 注解、 `@Bean` 注解），同时可以扫描
- `AnnotationConfigApplicationContext` ：继承了 GenericApplicationContext，实现了 `AnnotationConfigRegistry` 接口，拥有了以上所有的功能

### ClassPathXmlApplicationContext
![ClassPathXmlApplicationContext类继承结构](./attachments/Spring核心接口-1639837764524.png)
它也是继承了 `AbstractApplicationContext`，但是不如 `AnnotationConfigApplicationContext` 强大，比如不能注册 BeanDefinition

### MessageSource 国际化

先定义一个 MessageSource:

```java
@Bean
public MessageSource messageSource(){
    ResourceBundleMessageSource messageSource = new ResourceBundleMessageSource();
    messageSource.setBasename("messages");
    return messageSource;
}
```

有了这个 Bean，你可以在你任意想要进行国际化的地方使用该 MessageSource。 同时，因为 ApplicationContext 也拥有国际化的功能，所以可以直接这么用：

```java
context.getMessage("test", null, new Locale("en_CN"))
```

### ResourceLoader 资源加载

ApplicationContext 的子类 `GenericApplicationContext` 持有 `ResourceLoader` 的成员变量, 拥有资源加载的功能，比如可以直接利用 ApplicationContext 获取某个文件的内容：

```java
public static void main(String[] args) {
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);

    Resource resource = context.getResource("file://D:\\demo\\src\\main\\java\\com\\azh3ng\\service\\UserService.java");
    System.out.println(resource.contentLength());
    System.out.println(resource.getFilename());

    Resource resource1 = context.getResource("https://www.baidu.com");
    System.out.println(resource1.contentLength());
    System.out.println(resource1.getURL());

    Resource resource2 = context.getResource("classpath:spring.xml");
    System.out.println(resource2.contentLength());
    System.out.println(resource2.getURL());
    
    // 一次性获取多个文件
    Resource[] resources = context.getResources("classpath:com/azh3ng/*.class");
    for (Resource resource : resources) {
        System.out.println(resource.contentLength());
        System.out.println(resource.getFilename());
    }
}
```

### 获取运行时环境

```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
// 获取操作系统层面环境变量
Map<String, Object> systemEnvironment = context.getEnvironment().getSystemEnvironment();
System.out.println(systemEnvironment);

System.out.println("=======");
// 获取执行 java 命令 -D 的 变量
Map<String, Object> systemProperties = context.getEnvironment().getSystemProperties();
System.out.println(systemProperties);

System.out.println("=======");
// 获取所有的变量运行时环境变量
MutablePropertySources propertySources = context.getEnvironment().getPropertySources();
System.out.println(propertySources);

System.out.println("=======");
// 快捷获取环境变量的值
System.out.println(context.getEnvironment().getProperty("NO_PROXY"));
System.out.println(context.getEnvironment().getProperty("sun.jnu.encoding"));
System.out.println(context.getEnvironment().getProperty("zhouyu"));
```

**注意**: 可以利用

```java
@PropertySource("classpath:spring.properties")
public class AppConfig {}
```

来指定某个 properties 文件中的参数添加到运行时环境中

### 事件发布

先定义一个事件监听器

```java
@Bean
public ApplicationListener applicationListener() {
    return new ApplicationListener() {
        @Override
        public void onApplicationEvent(ApplicationEvent event) {
            System.out.println("接收到了一个事件");
        }
    };
}
```

然后发布一个事件：

```java
context.publishEvent("foo");
```

事件发布后, 会触发 `ApplicationListener`. `onApplicationEvent()` 执行自定义的逻辑
