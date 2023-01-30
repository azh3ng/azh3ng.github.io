---
layout: article  
title: 【理解Spring】抽象 BeanDefinition
date: 2022-01-08 18:18
titleEn: Spring-AbstractBeanDefinition
tags: [Spring]
originFileName: AbstractBeanDefinition.md
---

抽象的 BeanDefinition 不会生成 Bean，由于 BeanDefinition 有继承关系（[BeanDefinition继承](https://azh3ng.com/2022/01/09/Spring-BeanDefinition-inherit.html)），所以可以定义抽象 BeanDefinition 作为其他 BeanDefinition 的父级，其中定义的属性（scope、lazy 等）可以作用到子级的 BeanDefinition 

定义抽象 BeanDefinition  
spring.xml  
```xml
<bean id="user" class="com.demo.User" abstract="true"/>
```
