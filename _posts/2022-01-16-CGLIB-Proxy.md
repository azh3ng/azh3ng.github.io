---
layout: article  
alias: CGLIB动态代理
title: 理解 CGLIB 动态代理
date: 2022-01-16 01:01
tags: []
---

CGLIB 是一个功能强大，高性能的代码生成包。它为没有实现接口的类提供代理，为 JDK 的动态代理提供了很好的补充。通常可以使用 Java 的动态代理创建代理，但当要代理的类没有实现接口或者为了更好的性能，CGLIB 是一个好的选择。  
CGLIB 被广泛的运用在许多 AOP 的框架中，例如 Spring AOP 和 dynaop。Hibernate 使用 CGLIB 来代理单端 single-ended(多对一和一对一)关联。  

CGLIB 作为一个开源项目，其代码托管在 github，地址为：[https://github.com/cglib/cglib](https://github.com/cglib/cglib)  

**CGLIB 的原理**是动态生成一个被代理类的子类，子类重写被代理的类的所有**非** `final` 的方法。在子类中采用方法拦截的技术拦截所有父类方法的调用，织入横切逻辑。  
**CGLIB 底层**使用字节码处理框架 ASM，来转换字节码并生成新的类。不鼓励直接使用 ASM，因为它要求必须对 JVM 内部结构包括 class 文件的格式和指令集都很熟悉。  
**CGLIB 优点**：比 JDK 动态代理效率更高  
**CGLIB 缺点**：对于 `final` 类和方法，无法进行代理。  

## 代码示例
有一个原始类，没有实现任何接口
```java
public class Azh3ngService {
    public String method1(String param) {
        return param;
    }
    public String method2(String param) {
        return param;
    }
    public String method3(String param) {
        return param;
    }
}
```

### 拦截器
定义一个拦截器，在调用目标方法时，CGLib 会回调 `MethodInterceptor` 接口方法拦截，来实现自定义的代理逻辑，类似于 [JDK](https://azh3ng.com/2022/01/16/JDK-Proxy.html) 中的 `InvocationHandler` 接口
```java
import java.lang.reflect.Method;
import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;
/**
 * 自定义目标对象拦截器
 */
public class Azh3ngInterceptor implements MethodInterceptor{

    /**
     * 重写方法拦截在方法前和方法后加入业务
     * Object obj为目标对象
     * Method method为目标方法
     * Object[] params 为参数，
     * MethodProxy proxy CGlib方法代理对象
     */
    @Override
    public Object intercept(Object obj, Method method, Object[] params, MethodProxy proxy) throws Throwable {
        System.out.println("before...");
        Object result = proxy.invokeSuper(obj, params);
        System.out.println("after...");
        return result;
    }
}
```
参数：`Object obj` 为由 CGLib 动态生成的代理类实例；`Method method` 为上文中实体类所调用的被代理的方法引用；`Object[] params` 是参数值列表；`MethodProxy proxy` 是生成的代理类对方法的代理引用。  
返回：从代理实例的方法调用返回的值。  
其中，`proxy.invokeSuper(obj,arg)` 表示调用代理类实例的父类的方法（即实体类 `Azh3ngService` 中对应的方法）

### 生成代理类
使用`main`方法进行测试
```java
import net.sf.cglib.proxy.Callback;
import net.sf.cglib.proxy.CallbackFilter;
import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.NoOp;

public class TestCglibProxy {
    public static void main(String[] args) {
        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(Azh3ngService.class);
        enhancer.setCallback(new Azh3ngInterceptor());
        Azh3ngService azh3ngService = (Azh3ngService) enhancer.create();
        System.out.println(azh3ngService);
        System.out.println("result: " + azh3ngService.method1("test"));
        /*
          output:
          before...
          result: test
          after...
         */
    }
}
```
`Enhancer` 类是 CGLib 中的一个字节码增强器。  
首先将被代理类 `Azh3ngService` 设置成父类，然后设置拦截器 `Azh3ngInterceptor`，最后执行 `enhancer.create()` 动态生成一个代理类，并强制转型成父类 `Azh3ngService`，最后，在代理类上调用方法

### 回调过滤器CallbackFilter
CallbackFilter 的作用：在 CGLib 回调时可以设置对不同方法执行不同的回调逻辑，或者不执行回调。  
在 JDK 动态代理中没有类似的功能，对 InvocationHandler 接口方法的调用对代理类内的所以方法都有效。  
**代码示例**：  
定义实现过滤器 `CallbackFilter` 接口的类：  
```java
import java.lang.reflect.Method;
import net.sf.cglib.proxy.CallbackFilter;
/**
 * 回调方法过滤
 */
public class TargetMethodCallbackFilter implements CallbackFilter {

    /**
     * 过滤方法
     * 返回的值为数字，代表了 Callback 数组中的索引位置，要到用的 Callback
     */
    @Override
    public int accept(Method method) {
        if(method.getName().equals("method1")){
            System.out.println("filter method1 == 0");
            return 0;
        }
        if(method.getName().equals("method2")){
            System.out.println("filter method2 == 1");
            return 1;
        }
        if(method.getName().equals("method3")){
            System.out.println("filter method3 == 2");
            return 2;
        }
        return 0;
    }
}
```
其中 return 值为被代理类的各个方法在回调数组 `Callback[]` 中的位置索引

使用 `main` 方法测试  
```java
import net.sf.cglib.proxy.Callback;
import net.sf.cglib.proxy.CallbackFilter;
import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.NoOp;
import net.sf.cglib.proxy.FixedValue;

public class TestCglib {
    public static void main(String[] args) {
        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(Azh3ngService.class);
        CallbackFilter callbackFilter = new TargetMethodCallbackFilter();

        /*
         * 1. callback1：方法拦截器
         * 2. NoOp.INSTANCE：这个NoOp表示 no operator，即什么操作也不做，代理类直接调用被代理的方法不进行拦截。
         * 3. FixedValue：表示锁定方法返回值，无论被代理类的方法返回什么值，回调方法都返回固定值。
         */
        Callback azh3ngInterceptor = new Azh3ngInterceptor();
        Callback noopCb = NoOp.INSTANCE;
        Callback fixedValue = new TargetResultFixed();
        Callback[] cbArray = new Callback[]{azh3ngInterceptor, noopCb, fixedValue};
        enhancer.setCallbacks(cbArray);
        enhancer.setCallbackFilter(callbackFilter);
        Azh3ngService azh3ngService = (Azh3ngService) enhancer.create();
        System.out.println(azh3ngService);
        // method1 方法会被 callbackFilter 匹配到 cbArray 索引为 0 的 azh3ngInterceptor
        System.out.println(azh3ngService.method1("test"));
        // method2 方法会被 callbackFilter 匹配到 cbArray 索引为 1 的 noopCb
        System.out.println(azh3ngService.method2("1"));
        // method3 方法会被 callbackFilter 匹配到 cbArray 索引为 2 的 fixedValue
        System.out.println(azh3ngService.method3("1"));
        System.out.println(azh3ngService.method3("2"));
        /*
          output:
          filter method1 == 0
          before...
          result: test
          after...
          result: 1
          锁定结果
          result: 999
          锁定结果
          result: 999
         */
    }

    public class TargetResultFixed implements FixedValue {
        /**
         * 实现 FixedValue 接口，锁定回调值为 999
         * (整型，CallbackFilter中定义的使用FixedValue型回调的方法为 getConcreteMethodFixedValue，该方法返回值为整型)
         */
        @Override
        public Object loadObject() throws Exception {
            System.out.println("锁定结果");
            return 999;
        }
    }
}
```

## 参考
- [CGLIB(Code Generation Library) 介绍与原理 - 菜鸟教程 (runoob.com)](https://www.runoob.com/w3cnote/cglibcode-generation-library-intro.html)