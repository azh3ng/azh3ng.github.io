---
layout: article  
alias: ProxyFactory
title: 【理解Spring】ProxyFactory
date: 2022-01-16 02:00
tags: []
---

Spring 对 [JDK动态代理](https://azh3ng.com/2022/01/16/JDK-Proxy.html) 和 [CGLIB动态代理](https://azh3ng.com/2022/01/16/CGLIB-Proxy.html) 进行了一定程度的封装，提供一个类 ProxyFactory，更加方便的创建代理对象。

## 创建代理对象
代码示例：  
```java
public interface Azh3ngInterface {
    void test();
}

public static class Azh3ngInterfaceImpl implements Azh3ngInterface {
    public void test() {
        System.out.println("test...");
    }
}

public class TestProxyFactory {
    public static void main(String[] args) {
        Azh3ngInterfaceImpl target = new Azh3ngInterfaceImpl();
        ProxyFactory proxyFactory = new ProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.addAdvice(new MethodInterceptor() {
            @Override
            public Object invoke(MethodInvocation invocation) throws Throwable {
                System.out.println("before...");
                Object result = invocation.proceed();
                System.out.println("after...");
                return result;
            }
        });
        Azh3ngInterface azh3ngService = (Azh3ngInterface) proxyFactory.getProxy();
        azh3ngService.test();
        /*
          output:
          before...
          test...
          after...
         */
    }
}
```
通过使用 ProxyFactory，可以不再关心用 CGlib 还是 jdk 动态代理，ProxyFactory 会自动判断，如果 Azh3ngInterfaceImpl 实现了接口，那么 ProxyFactory 底层就会用 JDK 动态代理，如果没有实现接口，就会用 CGlib 技术，上面的代码，就是由于 Azh3ngInterfaceImpl 实现了 Azh3ngInterface 接口，所以最后产生的代理对象是 Azh3ngInterface 类型

## Advice
Advice 可以理解为自定义的代理逻辑。
在调用 `proxyFactory.addAdvice()` 时可以传入各式的 Advice，可以分类为：
- Before Advice（`org.springframework.aop.MethodBeforeAdvice`）：方法之前执行
- After returning advice（`com.tuling.aop.advice.Azh3ngAfterReturningAdvice`）：方法 return 后执行
- After throwing advice（`org.springframework.aop.ThrowsAdvice`）：方法抛异常后执行
    - `ThrowsAdvice` 接口没有定义方法，需要开发者根据规范自定义方法，可以区分控制不同的异常处理不同逻辑
- After (finally) advice（``）：方法执行完 finally 之后执行，这是最后的，比 return 更后
- Around advice（`org.aopalliance.intercept.MethodInterceptor`）：功能最强大的 Advice，可以自定义执行顺序
  在添加 Advice 后，ProxyFactory 生成的代理对象，会根据添加的顺序执行所有 Advice（[[责任链模式]]）

## Pointcut
Pointcut 中文译为切点，可以理解为通过一些过滤条件，筛选出需要被代理的方法

## Advisor
Advisor 是 [Pointcut](#Pointcut) 和 [Advice](#Advice) 的组合，通过 Pointcut 指定（筛选）被代理的方法，通过 Advice 自定义代理逻辑  
在单独使用 Advice 时无法细粒度的控制不同方法执行不同的逻辑，Advisor 可以做到。  
假设一个 Azh3ngInterfaceImpl 类中有两个方法，按上面的例子，这两个方法都会被代理和增强，通过使用 Advisor，可以控制到具体代理某个或某些方法，比如：
```java

public class Azh3ngInterfaceImpl {
    public void test1() {
        System.out.println("test1...");
    }
    public void test2() {
        System.out.println("test2...");
    }
}

public class TestProxyFactory {
    public static void main(String[] args) {
        Azh3ngInterfaceImpl target = new Azh3ngInterfaceImpl();
        ProxyFactory proxyFactory = new ProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.addAdvisor(new PointcutAdvisor() {
            @Override
            public Pointcut getPointcut() {
                return new StaticMethodMatcherPointcut() {
                    @Override
                    public boolean matches(Method method, Class<?> targetClass) {
                        // 仅当方法名为 “test1” 时，才执行 Advice
                        return method.getName().equals("test1");
                    }
                };
            }

            @Override
            public Advice getAdvice() {
                return new MethodInterceptor() {
                    @Override
                    public Object invoke(MethodInvocation invocation) throws Throwable {
                        System.out.println("before...");
                        Object result = invocation.proceed();
                        System.out.println("after...");
                        return result;
                    }
                };
            }

            @Override
            public boolean isPerInstance() {
                return false;
            }
        });
        Azh3ngInterfaceImpl azh3ngInterfaceImpl = (Azh3ngInterfaceImpl) proxyFactory.getProxy();
        azh3ngInterfaceImpl.test1();
        azh3ngInterfaceImpl.test2();
        /*
           output:
           before...
           test1...
           after...
           test2
         */
    }
}
```

## 选择 cglib 或 jdk 动态代理
ProxyFactory 在生成代理对象之前需要决定使用 JDK 动态代理还是 CGLIB 技术
- `org.springframework.aop.framework.ProxyFactory#getProxy()`
    - `org.springframework.aop.framework.ProxyCreatorSupport#createAopProxy`
        - `org.springframework.aop.framework.AopProxyFactory#createAopProxy`
            - `org.springframework.aop.framework.DefaultAopProxyFactory#createAopProxy`
```java
// config就是ProxyFactory对象
// optimize为true,或proxyTargetClass为true,或用户没有给ProxyFactory对象添加interface
if (config.isOptimize() || config.isProxyTargetClass() || hasNoUserSuppliedProxyInterfaces(config)) {
    Class<?> targetClass = config.getTargetClass();
    if (targetClass == null) {
        throw new AopConfigException("TargetSource cannot determine target class: " + "Either an interface or a target is required for proxy creation.");
    }
    // targetClass是接口，直接使用Jdk动态代理
    if (targetClass.isInterface() || Proxy.isProxyClass(targetClass)) {
        return new JdkDynamicAopProxy(config);
    }
    // 使用Cglib
    return new ObjenesisCglibAopProxy(config);
} else {
    // 使用Jdk动态代理
    return new JdkDynamicAopProxy(config);
}
```
`createAopProxy(AdvisedSupport config)` 方法接受的参数类型为 `AdvisedSupport extends ProxyConfig`，同时 `ProxyFactory extends ProxyCreatorSupport extends AdvisedSupport`，实际传入的也是 ProxyFactory。  

**1. 选择 CGLIB：**
- 运行环境不是 GraalVM
- 并且
    - ProxyFactory 的 `optimize` 为 true（是否优化，默认为 false。在以前 CGLIB 代理方式运行效率比 JDK 动态代理高，当设置了 optimize = true 则使用 CGLIB，但随着 JDK 版本升级，效率逐渐提升）
    - 或
    - ProxyFactory 的 `proxyTargetClass` 为 true（是否**直接代理指定类**，默认为 false，当设置为 true，则不再关心当前类是否有实现接口）
    - 或
    - `hasNoUserSuppliedProxyInterfaces(config) == true`（开发者没有具体指定代理的接口，通常为 true）
- 并且被代理的类不是接口
- 并且被代理的类不是由 JDK 生成的代理对象

**2. 选择 JDK 动态代理**
- 运行环境是 GraalVM
- 或 
- `optimize == false && proxyTargetClass == false && hasNoUserSuppliedProxyInterfaces(config) == false`
- 或
- 被代理的类是接口
- 或被代理的类是由 JDK 生成的代理对象

**小结：** 除非被代理的类是接口，或者被代理的类是由 JDK 生成的代理对象，否则 ProxyFactory 默认会选择使用 CGLIB 代理方式生成代理对象。

