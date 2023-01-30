---
layout: article  
alias: TargetSource
title: 【理解Spring】TargetSource
date: 2022-01-16 02:00
titleEn: TargetSource
tags: [Spring]
originFileName: "TargetSource.md"
---

`org.springframework.aop.TargetSource`

## TargetSource的使用
在 Spring AOP 中，通常被代理对象就是 Bean 对象，由 BeanFactory 创建。  
同时 Spring AOP 中提供了 TargetSource 接口，可以自定义逻辑创建被代理对象。例如 `@Lazy` 注解，当加在属性上时，会产生一个代理对象赋值给这个属性，产生代理对象的代码为：
`org.springframework.context.annotation.ContextAnnotationAutowireCandidateResolver#buildLazyResolutionProxy`
```java
public class ContextAnnotationAutowireCandidateResolver {
    protected Object buildLazyResolutionProxy(final DependencyDescriptor descriptor, final @Nullable String beanName) {
        BeanFactory beanFactory = getBeanFactory();
        Assert.state(beanFactory instanceof DefaultListableBeanFactory,
                "BeanFactory needs to be a DefaultListableBeanFactory");
        final DefaultListableBeanFactory dlbf = (DefaultListableBeanFactory) beanFactory;
        TargetSource ts = new TargetSource() {
            @Override
            public Class<?> getTargetClass() {
                return descriptor.getDependencyType();
            }

            @Override
            public boolean isStatic() {
                return false;
            }

            @Override
            public Object getTarget() {
                Set<String> autowiredBeanNames = (beanName != null ? new LinkedHashSet<>
                        (1) : null);
                Object target = dlbf.doResolveDependency(descriptor, beanName,
                        autowiredBeanNames, null);
                if (target == null) {
                    Class<?> type = getTargetClass();
                    if (Map.class == type) {
                        return Collections.emptyMap();
                    } else if (List.class == type) {
                        return Collections.emptyList();
                    } else if (Set.class == type || Collection.class == type) {
                        return Collections.emptySet();
                    }
                    throw new
                            NoSuchBeanDefinitionException(descriptor.getResolvableType(),
                            "Optional dependency not present for lazy injection point");
                }
                if (autowiredBeanNames != null) {
                    for (String autowiredBeanName : autowiredBeanNames) {
                        if (dlbf.containsBean(autowiredBeanName)) {
                            dlbf.registerDependentBean(autowiredBeanName, beanName);
                        }
                    }
                }
                return target;
            }

            @Override
            public void releaseTarget(Object target) {
            }
        };
        ProxyFactory pf = new ProxyFactory();
        pf.setTargetSource(ts);
        Class<?> dependencyType = descriptor.getDependencyType();
        if (dependencyType.isInterface()) {
            pf.addInterface(dependencyType);
        }
        return pf.getProxy(dlbf.getBeanClassLoader());
    }
}
```
上述代码利用 ProxyFactory 生成代理对象，使用了 TargetSource，以达到代理对象在执行某个方法时，调用 TargetSource 的 getTarget() 方法实时得到一个被代理对象。

## 利用 TargetSource 动态获取 Bean
[Spring动态获取Bean#使用代理对象区分并执行具体实现](/2022/02/01/Spring-dynamic-getBean.html#使用代理对象区分并执行具体实现)
