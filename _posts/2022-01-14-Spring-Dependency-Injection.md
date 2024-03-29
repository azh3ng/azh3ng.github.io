---
layout: article  
alias: 依赖注入
title: 【理解Spring】依赖注入
date: 2022-01-14 00:00
titleEn: Spring-Dependency-Injection
tags: [Spring]
originFileName: "依赖注入.md"
---


Spring 依赖注入包含两种 [[依赖注入类型]]
1. [[依赖注入类型#手动注入]] ：手动指定属性的值
2. [[依赖注入类型#自动注入]] ：利用 Spring 自动寻找可能的 bean 对象，并赋值到属性

其中自动注入又分为三种类型：
1. [[依赖注入类型#XML 的 autowire 自动注入]]
2. [[依赖注入类型#Autowire 注解自动注入]]
3. [[依赖注入类型# `@Resource` 注解的自动注入]]


Spring 依赖注入过程大致为：
1. [寻找注入点](#寻找注入点)
2. [遍历注入点进行注入](#遍历注入点进行注入)
3. 注入过程中进行 [依赖查找](#依赖查找)

`@Autowire` 注解自动注入和 `@Resource` 注解的自动注入有些许区别，但大体相同。

## 寻找注入点

### @Autowire 寻找注入点

在创建 Bean 的过程中，Spring 执行
- `AutowiredAnnotationBeanPostProcessor.postProcessMergedBeanDefinition()` 
  - `AutowiredAnnotationBeanPostProcessor.findAutowiringMetadata()`
    - `AutowiredAnnotationBeanPostProcessor.buildAutowiringMetadata(Class<?>)`

找出 `@Autowire` 注解标注的注入点，并缓存。

---

**寻找注入点流程：** 寻找、创建注入点，并加入缓存（`AutowiredAnnotationBeanPostProcessor.buildAutowiringMetadata(Class<?>)`）  

1. java 包下的对象，不需要找注入点
2. 遍历当前类的所有的**属性**字段 Field
  1. 查看字段上是否存在 `@Autowired`、`@Value`、`@Inject` 中的其中任意一个，存在则认为该字段是一个注入点(`AutowiredAnnotationBeanPostProcessor.findAutowiredAnnotation(AccessibleObject)`)
  2. 如果字段是 static 的，则跳过，不进行注入，[原因](/2022/01/14/Spring-why-auto-injection-not-support-for-static-fields.html)
  3. 获取 `@Autowired` 中的 required 属性的值
  4. 将字段信息构造成一个 `AutowiredFieldElement` 对象，作为一个**注入点对象**，添加到 currElements 集合中。
3. 遍历当前类的所有**方法** `Method`
  1. 判断当前 Method 是否是 [[桥接方法]]，如果是，找到原方法
  2. 查看方法上是否存在 `@Autowired`、`@Value`、`@Inject` 中的其中任意一个，存在则认为该方法是一个注入点
  3. 如果方法是 static 的，则跳过，不进行注入，[原因](/2022/01/14/Spring-why-auto-injection-not-support-for-static-fields.html)
  4. 获取 `@Autowired` 中的 `required` 属性的值
  5. 将方法信息构造成一个 `AutowiredMethodElement` 对象，作为一个**注入点对象**
     添加到 `currElements` 集合中。
4. 遍历完当前类的字段和方法后，已近似**递归**的方式遍历父类，寻找注入点，直到没有父类
5. 最后将 `currElements` 集合封装成一个 `InjectionMetadata` 对象，作为当前 Bean 对于的注入点集合对象，并缓存。

### @Resource 寻找注入点
在创建 Bean 的过程中，Spring 执行 
- `CommonAnnotationBeanPostProcessor.postProcessMergedBeanDefinition()` 
  - `CommonAnnotationBeanPostProcessor.findResourceMetadata()`
    - `CommonAnnotationBeanPostProcessor.buildResourceMetadata(Class<?>)`
找出 `@Resource` 注解标注的注入点，并缓存。

---

### 寻找注入点流程 
寻找、创建注入点，并加入缓存（`CommonAnnotationBeanPostProcessor.buildResourceMetadata(Class<?>)`）

1. java 包下的对象，不需要找注入点
2. 遍历当前类的所有的**属性**字段 Field
    1. 判断字段上是否存在 `@Resource` 注解，是则继续判断，否则继续遍历
    2. 判断是否为 `static` 字段，如果字段是 `static` 的，抛出异常（[原因](/2022/01/14/Spring-why-auto-injection-not-support-for-static-fields.html)）
    3. 构造 `CommonAnnotationBeanPostProcessor.ResourceElement`，并将其添加到 `currElements` 集合中
3. 遍历当前类的所有的**方法** `method`
    1. 判断**方法**上是否存在 `@Resource` 注解，是则继续判断，否则继续遍历
    2. 判断是否为 `static` 方法，如果字段是 `static` 的，抛出异常（[原因](/2022/01/14/Spring-why-auto-injection-not-support-for-static-fields.html)）
    3. 判断方法参数有且仅有一个，否则报错
    4. [构造](#commonannotationbeanpostprocessorresourceelement-构造方法) `CommonAnnotationBeanPostProcessor.ResourceElement`，并将其添加到 `currElements` 集合中
4. 最后将 `currElements` 集合封装成一个 `InjectionMetadata` 对象，作为当前 Bean 对于的注入点集合对象，并缓存。

#### CommonAnnotationBeanPostProcessor.ResourceElement 构造方法

`ResourceElement` 是 `CommonAnnotationBeanPostProcessor` 中定义的私有类，在构造方法

```java
public ResourceElement(Member member, AnnotatedElement ae, @Nullable PropertyDescriptor pd)
```

中，获取 `@Resource` 的 `name` 属性的值，如果 `name` 的值为空，则取变量名，或者取方法名（去除 set 前缀 并将首字母小写）  
获取 `@Resource` 的 `type` 属性的值，判断与当前注入的类型是否一致，不一致则抛出异常；  
判断是否存在 `@Lazy` 注解  

## 遍历注入点进行注入

### `@Autowire` 注入点注入

Spring 在 `AutowiredAnnotationBeanPostProcessor.postProcessProperties()` 方法中，会遍历所找到的注入点依次进行注入（`InjectionMetadata.inject(Object, String beanName, PropertyValues)` ）

Spring 在 `AutowiredAnnotationBeanPostProcessor` 中自定义了私有类 `AutowiredFieldElement` （字段注入）和 `AutowiredMethodElement`（Set 方法注入），都继承了 `InjectionMetadata.InjectedElement`，并各自重写了 `inject()` 方法

```java
@Override  
protected void inject(Object bean, @Nullable String beanName, @Nullable PropertyValues pvs) throws Throwable
```

#### 字段注入
1. 获取到 `AutowiredFieldElement` 对象，调用其 `inject()` 方法
2. 将对应的字段封装为 `DependencyDescriptor` 对象。
3. 调用 BeanFactory 的 `resolveDependency()` 方法，传入 `DependencyDescriptor` 对象，进行[依赖查找](#依赖查找)，找到当前字段所匹配的 Bean 对象。
4. 将 `DependencyDescriptor` 对象和所找到的结果对象 beanName 封装成 `ShortcutDependencyDescriptor` 作为缓存，
   1. 如果当前 Bean 是原型 Bean，那么下次再来创建该 Bean 时，就可以直接拿缓存的结果对象 beanName 去 BeanFactory 中去拿 bean 对象了，不用再次进行查找了
5. 利用反射将结果对象赋值给字段。

#### Set 方法注入
1. 获取到 `AutowiredMethodElement` 对象，调用其 `inject(Object, String beanName, PropertyValues)` 方法
2. 遍历将对应的方法的参数，将**每个**参数封装成 `MethodParameter` 对象
3. 将 `MethodParameter` 封装为 `DependencyDescriptor`
4. 调用 BeanFactory 的 `resolveDependency()`，传入 `DependencyDescriptor`，进行[依赖查找](#依赖查找)，找到当前方法参数所匹配的 Bean 对象。
5. 将 `DependencyDescriptor` 对象和所找到的结果对象 beanName 封装成 `ShortcutDependencyDescriptor` 作为缓存，
   1. 如果当前 Bean 是原型 Bean，当下次再创建该 Bean 时，就可以直接拿缓存的结果对象 beanName 到 BeanFactory 中去拿 bean 对象了，不用再次进行查找
6. 利用反射将找到的所有结果对象传给当前方法，并执行。

### @Resource 注入点注入
Spring 在 `CommonAnnotationBeanPostProcessor.postProcessProperties()` 方法中，会遍历所找到的注入点依次进行注入（`InjectionMetadata.inject(Object, String beanName, PropertyValues)` ）

Spring 在 `CommonAnnotationBeanPostProcessor` 中自定义了私有类 `ResourceElement` 继承了 `InjectionMetadata.InjectedElement`，但没有重写 `inject()` 方法

无论字段注入还是 Set 方法注入，都会调用 `InjectionMetadata.inject()` -> `InjectedElement.inject()` -> `ResourceElement.getResourceToInject()` 方法寻找 bean 用来注入  
 `getResourceToInject()` 中调用 `getResource()`，再调用 `autowireResource()`   
 此中  
 1. 判断 `@Resource` 指定了 `name` 属性，或 field 字段名/Set 方法名 存在对应的 bean，则直接调用 `beanFactory.resolveBeanByName(name, descriptor)` 获取 bean
 2. 否则调用 `resolveDependency()` 进行[依赖查找](#依赖查找)
 

## 依赖查找 
入口：
DefaultListableBeanFactory.java
```java
Object resolveDependency(DependencyDescriptor descriptor, 
    @Nullable String requestingBeanName, 
    @Nullable Set<String> autowiredBeanNames, 
    @Nullable TypeConverter typeConverter) throws BeansException {
```
该方法表示，传入一个依赖描述（DependencyDescriptor），该方法会根据该依赖描述从 BeanFactory 中找出对应的唯一的一个 Bean 对象，并返回。

主要逻辑流程如下：
1. 如果 `DependencyDescriptor` 代表某方法的参数，则获取方法入参的实际参数名（方法参数名在编译后，原参数名无法直接获取，需要通过其他技术，例如字节码技术获取），后续在 [doResolveDependency()](#doresolvedependency) 内用作 beanName 的判断
2. 调用 `descriptor.getDependencyType()` 判断依赖类型
   1. 如果是 `Optional.class`，调用 `DefaultListableBeanFactory.doResolveDependency()`，将返回的对象包装成 `Optional` 对象
   2. 如果是 `ObjectFactory` 或者是 `ObjectProvider`，返回 `DependencyObjectProvider`，在 `ObjectFactory` 调用 `.getObject()` 时，执行 `doResolveDependency()` 找到真正的依赖对象
   3. 如果是其他类型
      1. 判断如果该依赖被 `@Lazy` 注解标注，返回代理对象，在调用代理对象中的方法时，调用 [doResolveDependency()](#doresolvedependency) 找到真正的依赖对象
      2. 否则，调用 [doResolveDependency()](#doresolvedependency)，找到真正的依赖对象

### doResolveDependency()
**寻找并筛选依赖的 bean**

DefaultListableBeanFactory.java
```java
Object doResolveDependency(DependencyDescriptor descriptor, @Nullable String beanName, @Nullable Set<String> autowiredBeanNames, @Nullable TypeConverter typeConverter)
```

1. 判断 `DependencyDescriptor` 是否存在缓存，是则直接返回缓存
2. 判断 `DependencyDescriptor` 是否存在 `@Value` 注解，是则解析 `@Value` 注解的值，处理占位符填充(`${}`)或 Spring 表达式(`#{}`)，并**返回**
3. 判断 `DependencyDescriptor` 依赖类型是否为 `Collection` 或 `Map`
   1. 如果依赖类型为 `Map<String, Object>`，
      1. 判断泛型类型，如果 key 的类型不为 String，则返回 null
      2. 调用 [findAutowireCandidates()](#findautowirecandidates)，将结果回
   2. 如果依赖类型为 `Collection` 或者数组，将 [findAutowireCandidates()](#findautowirecandidates) 返回的 `Map` 调用 ` values()` 返回所有 Bean
4. 调用 [findAutowireCandidates()](#findautowirecandidates) 根据类型查找 bean
5. 如果没有找到 bean，判断依赖是否被 `@Requried` 注解标注，是则报错，否则返回 null
6. 如果找到多个 bean，判断优先级
   1. `@Primary`
      1. 如果一个 bean 被 `@Primary` 标注，返回此 bean
      2. 如果有多个 bean 被 `@Primary` 标注，报错
   2. `@Priority` ：返回优先级最高的 bean（数字越小，优先级越高）
   3. 根据 beanName 确定 bean
      1. 如果找到一个 bean：
         1. 结果为 bean，直接返回；
         2. 结果为 class 对象，则调用 [BeanFactory.getBean()](/2022/01/10/Spring-BeanFactory-getBean.html) 生成 bean 对象并返回
      3. 否则：判断依赖是否必须，是则报错，否则返回 null
8. 如果找到一个 bean
   1. 结果为 bean，直接返回；
   2. 结果为 class 对象，则调用 [BeanFactory.getBean()](/2022/01/10/Spring-BeanFactory-getBean.html) 生成 bean 对象并返回

### findAutowireCandidates()
![流程图](./attachments/依赖注入-1657431124248.png)
根据类型获取 bean，返回 Map <String, Object>  
DefaultListableBeanFactory.java  
```java
/**
 * Find bean instances that match the required type.
 * Called during autowiring for the specified bean.
 * @param beanName the name of the bean that is about to be wired
 * @param requiredType the actual type of bean to look for
 * (may be an array component type or collection element type)
 * @param descriptor the descriptor of the dependency to resolve
 * @return a Map of candidate names and candidate instances that match
 */
Map<String, Object> findAutowireCandidates(@Nullable String beanName, Class<?> requiredType, DependencyDescriptor descriptor)
```

在查找 bean 时，对于没有被依赖的 bean 不需要立即被创建，所以 Spring 没有在此时创建 bean  

流程：
1. 找出 BeanFactory 中类型为 `requiredType` 的所有的 beanName（可以根据 BeanDefinition 判断和 `requiredType` 是否匹配，所以过程中无需生成 Bean 对象）
2. 把 `resolvableDependencies` 中 key 为 type 的对象找出来并添加到 result 中
3. 如果注入的 `class` 与被注入的 `class` 相同（`@Component class FooService {@Autowire FooService service;}`），同时这个类的 Bean 有多个，则优先判断其他 Bean 是否可以被用来注入，如果其他 Bean 不能被注入，则注入自己
4. 判断 Bean 是否可以被用来注入
   1. 先判断 beanName 对应的 BeanDefinition 中的 `autowireCandidate` 属性（默认为 true），如果为 false，表示不能用来进行自动注入，直接返回，如果为 true 则继续进行判断
   2. [泛型注入](#依赖注入中泛型注入的实现) ：判断当前 `requiredType` 是不是泛型，如果是泛型，则把容器中所有的 beanName 找出来的，并获取到泛型的真正类型，然后进行匹配，如果当前 beanName 和当前泛型对应的真实类型匹配，那么则继续判断
   3. [Qualifier 判断](#Qualifier 判断) ：如果当前 DependencyDescriptor 上存在 `@Qualifier` 注解，那么则要判断当前 beanName 上是否定义了 `@Qualifier`，并且是否和当前 DependencyDescriptor 上的 `@Qualifier` 的值相等，相等则匹配
5. 经过上述验证之后，当前 beanName 才能成为一个可注入的，添加到 result 中

### 依赖注入中泛型注入的实现
在 Java 反射中，有一个 `Type` 接口，表示类型，具体分类为：
1. raw types：也就是普通 Class
2. parameterized types：对应 `ParameterizedType` 接口，表示泛型
3. array types：对应 `GenericArrayType`，表示泛型数组
4. type variables：对应 `TypeVariable` 接口，表示类型变量，也就是所定义的泛型，比如 T、K
5. primitive types：基本类型，如 `int`、`boolean`

示例：
```java
public class TypeTest<T> {
   private int i;
   private Integer it;
   private int[] iarray;
   private List list;
   private List<String> slist;
   private List<T> tlist;
   private T t;
   private T[] tarray;

   public static void main(String[] args) throws NoSuchFieldException {
      test(TypeTest.class.getDeclaredField("i"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("it"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("iarray"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("list"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("slist"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("tlist"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("t"));
      System.out.println("=======");
      test(TypeTest.class.getDeclaredField("tarray"));
   }

   public static void test(Field field) {
      if (field.getType().isPrimitive()) {
         System.out.println(field.getName() + "是基本数据类型");
      } else {
         System.out.println(field.getName() + "不是基本数据类型");
      }
      if (field.getGenericType() instanceof ParameterizedType) {
         System.out.println(field.getName() + "是泛型类型");
      } else {
         System.out.println(field.getName() + "不是泛型类型");
      }
      if (field.getType().isArray()) {
         System.out.println(field.getName() + "是普通数组");
      } else {
         System.out.println(field.getName() + "不是普通数组");
      }
      if (field.getGenericType() instanceof GenericArrayType) {
         System.out.println(field.getName() + "是泛型数组");
      } else {
         System.out.println(field.getName() + "不是泛型数组");
      }
      if (field.getGenericType() instanceof TypeVariable) {
         System.out.println(field.getName() + "是泛型变量");
      } else {
         System.out.println(field.getName() + "不是泛型变量");
      }
   }
}
/* output
private int i;
i是基本数据类型
i不是泛型类型
i不是普通数组
i不是泛型数组
i不是泛型变量
=======
private Integer it;
it不是基本数据类型
it不是泛型类型
it不是普通数组
it不是泛型数组
it不是泛型变量
=======
private int[] iarray;
iarray不是基本数据类型
iarray不是泛型类型
iarray是普通数组
iarray不是泛型数组
iarray不是泛型变量
=======
private List list;
list不是基本数据类型
list不是泛型类型
list不是普通数组
list不是泛型数组
list不是泛型变量
=======
private List<String> slist;
slist不是基本数据类型
slist是泛型类型
slist不是普通数组
slist不是泛型数组
slist不是泛型变量
=======
private List<T> tlist;
tlist不是基本数据类型
tlist是泛型类型
tlist不是普通数组
tlist不是泛型数组
tlist不是泛型变量
=======
private T t;
t不是基本数据类型
t不是泛型类型
t不是普通数组
t不是泛型数组
t是泛型变量
=======
private T[] tarray;
tarray不是基本数据类型
tarray不是泛型类型
tarray是普通数组
tarray是泛型数组
tarray不是泛型变量
 */
```
在 Spring 中，当注入点是一个泛型时，例如：
```java
@Component
public class UserService extends BaseService<OrderService, StockService> {
   public void test() {
      System.out.println(o);
   }
}

public class BaseService<O, S> {
   @Autowired
   protected O o;
   @Autowired
   protected S s;
}
```
1. Spring 扫描时发现 UserService 是一个 Bean
2. 从父类 `BaseService` 找到注入点，`protected O o` 和 `protected S s`
3. 由于 o 和 s 都是泛型，所以 Spring 需要确定 o 和 s 的具体类型
4. 因为当前正在创建的是 UserService 的 Bean，所以可以通过 `String typeName = userService.getClass().getGenericSuperclass().getTypeName()` 获取到具体的泛型信息，比如 `System.out.println(typeName); // output: com.azh3ng.service.BaseService<com.azh3ng.service.OrderService, com.azh3ng.service.StockService>`
5. 然后再拿到 UserService 的父类 BaseService 的泛型变量： `List<TypeVariable<? extends Class<?>>> typeParameters = userService.getClass().getSuperclass().getTypeParameters()`，例如：`System.out.println(typeParameters); // output: O S`
6. 由上两个步骤获得的结果，可以推断 o 对应的具体是 OrderService，s 对应的具体类型是 StockService
7. 调用 `oField.getGenericType()` 就知道当前 field 使用的是哪个泛型，就能知道具体类型了

### Qualifier 判断
相关文章：[@Qualifier使用](/2022/01/30/Spring-use-of-@Qualifier.html)
`QualifierAnnotationAutowireCandidateResolver.isAutowireCandidate()` 中当父类的判断处理完成后，进行 `@Qualifier` 注解的判断：
1. 获取当前注入点上的所有注解
2. 进入 `QualifierAnnotationAutowireCandidateResolver.checkQualifiers()` 方法
3. 判断是否存在 `@Qualifier` 注解
4. 如果有则判断 `@Qualifier` 注解中的值与当前 BeanDefinition 中 `@Qualifier` 的值是否相等
5. 如果匹配则进行注入
