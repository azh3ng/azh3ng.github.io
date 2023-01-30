---
layout: article  
title: 【理解Spring】Spring初始化所有非懒加载单例Bean
date: 2022-01-08 00:00
titleEn: Spring-initializes-non-lazy-singleton-beans
tags: [Spring]
originFileName: "Spring初始化所有非懒加载单例Bean.md"
---



代码入口：  
`org.springframework.beans.factory.support.DefaultListableBeanFactory#preInstantiateSingletons`
```java
@Override  
public void preInstantiateSingletons() throws BeansException {  
   if (logger.isTraceEnabled()) {  
      logger.trace("Pre-instantiating singletons in " + this);  
   }  
  
   // Iterate over a copy to allow for init methods which in turn register new bean definitions.  
   // While this may not be part of the regular factory bootstrap, it does otherwise work fine.   
   List<String> beanNames = new ArrayList<>(this.beanDefinitionNames);  
  
   // Trigger initialization of all non-lazy singleton beans...  
   for (String beanName : beanNames) {  
      RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);  
      if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {  
         if (isFactoryBean(beanName)) {  
            Object bean = getBean(FACTORY_BEAN_PREFIX + beanName);  
            if (bean instanceof FactoryBean) {  
               FactoryBean<?> factory = (FactoryBean<?>) bean;  
               boolean isEagerInit;  
               if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {  
                  isEagerInit = AccessController.doPrivileged(  
                        (PrivilegedAction<Boolean>) ((SmartFactoryBean<?>) factory)::isEagerInit,  
                        getAccessControlContext());  
               }  
               else {  
                  isEagerInit = (factory instanceof SmartFactoryBean &&  
                        ((SmartFactoryBean<?>) factory).isEagerInit());  
               }  
               if (isEagerInit) {  
                  getBean(beanName);  
               }  
            }  
         }  
         else {  
            getBean(beanName);  
         }  
      }  
   }  
  
   // Trigger post-initialization callback for all applicable beans...  
   for (String beanName : beanNames) {  
      Object singletonInstance = getSingleton(beanName);  
      if (singletonInstance instanceof SmartInitializingSingleton) {  
         StartupStep smartInitialize = this.getApplicationStartup().start("spring.beans.smart-initialize")  
               .tag("beanName", beanName);  
         SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;  
         if (System.getSecurityManager() != null) {  
            AccessController.doPrivileged((PrivilegedAction<Object>) () -> {  
               smartSingleton.afterSingletonsInstantiated();  
               return null;  
            }, getAccessControlContext());  
         }  
         else {  
            smartSingleton.afterSingletonsInstantiated();  
         }  
         smartInitialize.end();  
      }  
   }  
}
```

## 代码流程
1. 遍历 `beanDefinitionNames`
2. 根据 beanName 获取 BeanDefinition
	1. [合并 BeanDefinition](/2022/01/08/Spring-merge-BeanDefinition.html)
3. 判断合并后的 RootBeanDefinition
    1. 如果是**抽象BeanDefinition**，或者**不是单例**，或者**是懒加载**，不加载 Bean
    2. 如果是**非** [[抽象BeanDefinition]] 并且**是单例**并且是**非懒加载**的，继续执行
4. 判断 beanName 对应的 Bean 是否是 [FactoryBean](/2022/01/05/Spring-FactoryBean.html)
    1. 是 FactoryBean，调用 [getBean(FACTORY_BEAN_PREFIX +beanName)](/2022/01/10/Spring-BeanFactory-getBean.html#get-facorybean)，初始化此 FactoryBean
        1. 判断是否继承 SmartFactoryBean
            1. 如果是，调用 `isEagerInit()` 方法取 isEagerInit 的值
            2. 如果不是，isEagerInit 为 false
        2. 判断 isEagerInit 是否为 true
            1. 如果为 true，调用 [getBean(beanName)](/2022/01/10/Spring-BeanFactory-getBean.html) 初始化 FactoryBean 生产的 Bean
    2. 不是 FactoryBean，直接调用 [getBean(beanName)](/2022/01/10/Spring-BeanFactory-getBean.html)，初始化普通 Bean                 
5. 遍历 beanNames
    1. 根据 beanName 获取单例 bean
    2. 判断是否继承 `SmartInitializingSingleton`
       1. 是则执行 `afterSingletonsInstantiated()`

