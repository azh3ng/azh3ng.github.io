---
layout: article  
title: 【理解Spring】 FactoryBean  
date: 2022-01-08 23:26  
category:  
tags: [Spring]  
---

# 【理解Spring】 FactoryBean

代码示例：
```java
@Component
public class CustomerFactoryBean implements FactoryBean {

     @Override
     public Object getObject() throws Exception {
          return new UserService();
     }

     @Override
     public Class<?> getObjectType() {
          return UserService.class;
     }
}
```

自定义 `FactoryBean` 可以控制 Bean 的创建。  
在 Spring 的启动流程中, 会把 `CustomerFactoryBean` 当做一个 Bean 加入单例池，在`getBean()`被调用时, 会判断当前 Bean 是否是 FactoryBean, 如果是, 则返回 `FactoryBean.getObject()` 的结果。所以 `FactoryBean` 经历了完整的 Bean 的生命周期，而被 `FactoryBean` 创造出来的 Bean，在Spring的生命周期中, 只会经历 `初始化后`, 被切面指定时, 会产生代理对象, 可以实现 AOP，而其他生命周期步骤不会经过，比如初始化前的依赖注入。

**注意：** `@Bean` 方式创建的 Bean 会经历完整的 Bean 生命周期

获取 FactoryBean 创建的 Bean 对象, 和 FactoryBean 对象本身
```java
AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
// 获取打印 UserService
System.out.println(context.getBean("customerFactoryBean"));
// 获取打印 CustomerFactoryBean
System.out.println(context.getBean("&customerFactoryBean"));
```
