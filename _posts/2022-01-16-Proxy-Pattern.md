---
layout: article  
alias: Proxy Pattern
title: 【理解设计模式】代理模式
date: 2022-01-16 00:00
tags: []
extends:
---

![[Pasted image 20220911133612.png]]

代理模式是一种常见的设计模式，代理往往是对*被实际调用类*的一种包装，使用代理可以简单的将调用转发到实际的对象，也可以提供额外的逻辑，对实际的类进行增强扩展，例如在实际逻辑之前或之后做一些参数权限校验，流的关闭和内存释放等操作。

代理模式如果**根据字节码的创建时机**来分类，可以分为静态代理和动态代理：
- [静态代理](#静态代理)：在**程序运行前**就已经存在代理类的**字节码文件**，代理类和真实主题角色的关系在运行前就确定了
- [动态代理](#动态代理)：在程序运行期间由**JVM**根据反射等机制**动态的生成**，所以在运行前并不存在代理类的字节码文件

## 静态代理
首先有一个接口，接口内有一个方法
```java
public interface FooService { 
    void foo();
}
```
`RealFoo` 实现接口并完成方法逻辑
```java
public class RealFoo {
    @Override
    public void foo() {
        System.out.println("do something...");
    }
}
```
创建一个代理类 `ProxyFoo`，继承相同的接口，并对 `FooService` 的实现类进行增强
```java
public class ProxyFoo {
    private FooService fooService;
    public ProxyFoo(FooService fooService) {
        this.fooService = fooService;
    }
    @Override
    public void foo() {
        System.out.println("before...");
        fooService.foo();
        System.out.println("after...");
    }
}
```
使用`main`方法进行测试

```java
public class Main {
    public static void main(String[] args) {
        RealFoo realFoo = new RealFoo();
        ProxyFoo proxyFoo = new ProxyFoo(realFoo);
        proxyFoo.foo();
        /**
         * output:
         * before...
         * do something...
         * after...
         */
    }
}
```
这就是静态代理，代理类提前定义并实现，其优点是：可以做到在不修改原对象的代码前提下，对目标功能扩展  
同时其缺点是：
1. 当需要代理多个类的时候，由于代理对象要实现与目标对象一致的接口，有两种方式：
   -  只维护一个代理类，由这个代理类实现多个接口，但是这样就导致**代理类过于庞大**
   -  新建多个代理类，每个目标对象对应一个代理类，但是这样会**产生过多的代理类**
2. 当接口需要增加、删除、修改方法的时候，目标对象与代理类都要同时修改，**不易维护**。

静态代理的缺点可以通过使用[动态代理](#动态代理)规避

## 动态代理

Java 动态代理本质上是通过动态生成类的字节码，然后加载到 JVM 中。JVM 的**类加载**（《深入理解Java虚拟机》7.3节 类加载的过程）过程主要分为五个阶段：加载、验证、准备、解析、初始化。其中**加载阶段**需要完成以下3件事情：
1.  通过一个类的全限定名来获取定义此类的**二进制字节流**
2.  将这个字节流所代表的静态存储结构转化为方法区的运行时数据结构
3.  在内存中生成一个代表这个类的 `java.lang.Class` 对象，作为方法区这个类的各种数据访问入口

由于虚拟机规范对这三点要求并不严格，所以可以通过各种形式**获取类的二进制字节流**（class 字节码）
-   从ZIP包获取，这是JAR、EAR、WAR等格式的基础
-   从网络中获取，典型的应用是 Applet
-   **运行时计算生成**，使用最多的是动态代理技术，在 java.lang.reflect.Proxy 类中，就是用了 ProxyGenerator.generateProxyClass 来为特定接口生成形式为 `*$Proxy` 的代理类的二进制字节流
-   由其它文件生成，典型应用是JSP，即由JSP文件生成对应的Class类
-   从数据库中获取等等

动态代理就是根据接口或目标对象，计算出代理类的字节码，加载到 JVM 中使用。

#### 常见的字节码操作类库

字节码的计算和生成比较复杂，[现有的方案](https://java-source.net/open-source/bytecode-libraries)包括：
- Apache BCEL (Byte Code Engineering Library)：是Java classworking广泛使用的一种框架，它可以深入到 JVM 汇编语言进行类操作的细节。
- ObjectWeb ASM：是一个Java 字节码操作框架。它可以用于直接以二进制形式动态生成stub根类或其他代理类，或者在加载时动态修改类。
- CGLIB(Code Generation Library)：是一个功能强大，高性能和高质量的代码生成库，用于扩展JAVA类并在运行时实现接口。
- Javassist：是Java的加载时反射系统，它是一个用于在Java中编辑字节码的类库; 它使Java程序能够在运行时定义新类，并在JVM加载之前修改类文件。
- ...

Java 中动态代理的实现方式：
- [[JDK动态代理]]：实现接口
- [[CGLIB动态代理]]：继承类
- [[ProxyFactory]]：[[Spring]] 对上述两种代理实现进行了一定程度的封装


## 参考
- [Proxy pattern - Wikipedia](https://en.wikipedia.org/wiki/Proxy_pattern)
- [Java 动态代理详解 - 掘金 (juejin.cn)](https://juejin.cn/post/6844903744954433544)