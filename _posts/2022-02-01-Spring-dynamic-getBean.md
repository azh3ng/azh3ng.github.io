---
layout: article  
title: 【Spring实战】动态获取Bean  
date: 2022-02-01 00:00
tags: [Spring]  
extends: "[[Spring]]"
---

在开发中，常常会定义接口，后对接口进行实现。实现的方式可能有一种，也可能有多种，在不同的场景，需要调用不同的实现。

例如
```java
public interface Azh3ngService {
    void foo();
}
public class AaAzh3ngServiceImpl implements Azh3ngService {
    @Override
    public void foo() {
        System.out.println("aa");
    }
}
public class BbAzh3ngServiceImpl implements Azh3ngService {
    @Override
    public void foo() {
        System.out.println("bb");
    }
}
```
在实际业务中，往往根据某些参数区分调用实现。  
在 Spring 中可以使用以下几种方式完成。

## if/else方式
假设需要根据参数`code`区分，调用`Aa/BbAzh3ngServiceImpl`的具体实现
简单做法是
1. 直接注入两种不同的实现的 Bean
2. 使用`if{}else{}`区分调用具体 Bean
```java
@Component
public class Azh3ngController {
    
    @Resource private Azh3ngService aaAzh3ngServiceImpl;
    @Resource private Azh3ngService bbAzh3ngServiceImpl;
    
    public void test(String code) {
        if ("a".equals(code)) {
            return aaAzh3ngServiceImpl.foo();
        } else if ("b".equals(code)) {
            return bbAzh3ngServiceImpl.foo();
        } else {
            throw new RuntimeException("System Exception");
        }
    }
}
```
这种方式简单粗暴，但是缺点也非常明显，假如新增了一个实现类，所有用这种方式使用 Azh3ngService 的代码都需要修改。

## 使用Map接收Spring的自动注入
Spring 在自动注入时，会判断注入的对象是否为 `Collection` 或 `Map`，如果是，会继续判断其指定的泛型类型，进而找出所有匹配类型的 Bean 注入 `Collection` 或 `Map` 中。

```java

@Component
public class Azh3ngController {

    @Resource
    private Map<String, Azh3ngService> azh3ngServiceMap;

    public void test(String code) {
        Azh3ngService azh3ngService = azh3ngServiceMap.get(code + "Azh3ngServiceImpl");
        if (azh3ngService == null) {
            // throw Exception or return
            return;
        }
        azh3ngService.foo();
    }
}
```
当新增了一个实现类，无需再到所有使用的地方进行注入和添加 `if/else`，但缺点是：当参数异常导致无法获取到准确的 Bean 时，无法统一控制后续的逻辑。

## ApplicationContext动态获取Bean

Spring提供了`ApplicationContext`可以实现动态获取 Bean，无需到所有使用的地方进行注入和添加 `if/else`，也可以统一处理参数异常导致的 Bean 获取失败的情况

```java
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class ServiceFactory implements ApplicationContextAware {

    private static ApplicationContext applicationContext;

    /**
     * 实现 ApplicationContextAware 接口的回调方法，设置上下文环境
     *
     * @param applicationContext applicationContext
     */
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) {
        ServiceFactory.applicationContext = applicationContext;
    }

    public static <T> T getBean(Class<T> clazz, String code) {
        if (clazz == null) {
            return null;
        }
        String targetServiceName = code + clazz.getSimpleName() + "Impl";
        Map<String, T> beansOfType = applicationContext.getBeansOfType(clazz);
        T t = beansOfType.get(targetServiceName);
        if (t == null) {
            throw new NullPointerException("System Exception");
            // 或者返回默认实现
            // return beansOfType.get("default" + clazz.getSimpleName() + "Impl");
        }
        return t;
    }
}
```
```java
@Component
public class Azh3ngController {
    
    public void test(String code) {
        Azh3ngService azh3ngService = ServiceFactory.getBean(Azh3ngService.class, code);
        azh3ngService.foo();
    }
}
```

## 使用代理对象区分并执行具体实现

当参数存储在 `ThreadLocal` 或者某种缓存中，可以使用代理对象对参数进行判断并获取具体实现类，并执行相应的逻辑
假设参数存储在 Session 中：
```java
@Configuration
public class Azh3ngConfig {
    @Bean
    public ProxyFactoryBean azh3ngServiceProxy(BeanFactory beanFactory) {
        ProxyFactoryBean proxyFactoryBean = new ProxyFactoryBean();
        proxyFactoryBean.setTargetSource(new TargetSource() {
            @Override
            public Class<?> getTargetClass() {
                return Azh3ngService.class;
            }

            @Override
            public boolean isStatic() {
                return false;
            }

            @Override
            public Object getTarget() throws Exception {
                HttpServletRequest httpServletRequest = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();
                Object code = httpServletRequest.getSession().getAttribute("code");
                code == null ? "default" : (String) code;
                Azh3ngService azh3ngService = (Azh3ngService) beanFactory.getBean(code + getTargetClass().getSimpleName() + "Impl");
                return azh3ngService;
            }

            @Override
            public void releaseTarget(Object target) throws Exception {
            }
        });
        proxyFactoryBean.addInterface(Azh3ngService.class);
        return proxyFactoryBean;
    }
}
```

```java
@Component
public class Azh3ngController {
    
    @Resource private Azh3ngService azh3ngServiceProxy;
    
    public void test() {
        azh3ngServiceProxy.foo();
    }
}
```

