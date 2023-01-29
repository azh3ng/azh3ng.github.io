---
layout: article  
title: 【理解Spring】合并 BeanDefinition
date: 2022-01-08 18:17
tags: [Spring]
---

代码入口：  
`AbstractBeanFactory.getMergedBeanDefinition()`  
通过 Bean Name 从缓存获取合并后的 BeanDefinition，如果为空，根据 [BeanDefinition继承](https://azh3ng.com/2022/01/09/Spring-BeanDefinition-inherit.html) 关系，判断是否有父级 BeanDefinition，有则递归向上找父级 BeanDefinition，并向下合并，子 BeanDefinition 的属性继承自父级 BeanDefinition，如果子级的属性不为空则覆盖父级的属性，生成 RootBeanDefinition，得到完整的 BeanDefinition。
将合并后的 RootBeanDefinition 加入缓存 `AbstractBeanFactory.mergedBeanDefinitions`