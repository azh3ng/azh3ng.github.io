---
layout: article  
title: 【理解Spring】BeanPostProcessor  
date: 2022-01-05 00:00
category:  
tags: [Spring]  
---

`BeanPostProcess`表示 Bean 的后置处理器
一个`BeanPostProcessor`可以在任意一个 Bean 的初始化之前以及初始化之后去额外的做一些用户自定义的逻辑
当然，也可以通过判断 beanName 来进行针对性处理（针对某个Bean，或某部分Bean）
可以通过定义`BeanPostProcessor`来干涉 Spring 创建 Bean 的过程
可以定义一个或多个 BeanPostProcessor，例如：
```java
@Component
public class CustomerBeanPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            System.out.println("初始化前");
        }

        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        if ("userService".equals(beanName)) {
            System.out.println("初始化后");
        }

        return bean;
    }
}
```