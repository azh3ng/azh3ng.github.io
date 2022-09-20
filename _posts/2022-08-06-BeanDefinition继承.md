---
layout: article  
title: 理解 BeanDefinition 继承  
date: 2022-01-08 23:17  
category:
tags: [Spring]
---

# [理解Spring]BeanDefinition 继承
BeanDefinition 可以通过继承获得父 BeanDefinition 的属性，开发中实际运用的比较少。

**非继承：**

```xml
<bean id="parent" class="com.azh3ng.service.Parent" cope="prototype"/>
<bean id="child" class="com.azh3ng.service.Child"/>
```

上述情况下，child 是单例 Bean。

**继承 BeanDefinition：**

```xml
<bean id="parent" class="com.azh3ng.service.Parent" cope="prototype"/>
<bean id="child" class="com.azh3ng.service.Child" parent="parent"/>
```

上述情况下，child 继承了 parent 的 `scope`，继承后，child 是原型 Bean。

child Bean 在生成 Bean 对象之前，需要进行**合并BeanDefinition**，得到完整的 child 的 BeanDefinition。