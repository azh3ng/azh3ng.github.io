---
layout: article  
title: 【理解Spring】扫描
date: 2022-01-07 00:00 
titleEn: Spring-scan
tags: [Spring]  
originFileName: "Spring扫描.md"
---


Spring 启动的时候会调用 
- `ClassPathBeanDefinitionScanner.scan(String... basePackages)`
    - `ClassPathBeanDefinitionScanner.doScan(String... basePackages)`
        - `ClassPathScanningCandidateComponentProvider.findCandidateComponents()`
            - `ClassPathScanningCandidateComponentProvider.scanCandidateComponents()`  
扫描某个包路径，筛选 `.class` 并得到 BeanDefinition 的 Set 集合。

## 扫描
1. 判断是否有 `src/resources/spring.components` 文件
    1. 如果有，则以此文件内指定的 class 和注解类型，判断扫描包路径和 `includeFilters` 是否匹配，继续判断 class 能否视作 Bean
    2. 如果没有，则执行 2
2. 通过 `ResourcePatternResolver` 获得指定包路径下的所有 `.class` 文件（Spring 将 `.class` 文件包装成 Resource 对象）
3. 遍历每个 `Resource` 对象

## 筛选并生成 BeanDefinition
1. 利用 `MetadataReaderFactory` 解析 `Resource` 对象得到 `MetadataReader`（MetadataReaderFactory 具体的实现类为 CachingMetadataReaderFactory，MetadataReader 的具体实现类为 SimpleMetadataReader）
2. 利用 `MetadataReader` 进行 `excludeFilters` 、`includeFilters` 和条件注解 `@Conditional` 的筛选（`ClassPathScanningCandidateComponentProvider.isCandidateComponent(MetadataReader)`）
   1. 先进行 `excludeFilters` 判定，如果匹配直接返回 false，表示不为 Bean
   2. 再进行 `includeFilters` 判定，
       1. 如果不匹配，返回 false，表示不为 Bean
       2. 如果匹配，再进行 `@Conditional` 匹配（条件注解：某个类上是否存在 `@Conditional` 注解，如果存在则调用注解中所指定的类的 match 方法进行匹配，匹配成功则通过筛选，匹配失败则 pass 掉。）
3. 筛选通过后，基于 `metadataReader` 生成 `ScannedGenericBeanDefinition`（`ClassPathScanningCandidateComponentProvider.java`）
4. 判断类是不是接口或抽象类，能否视作 Bean（`ClassPathScanningCandidateComponentProvider.isCandidateComponent(AnnotatedBeanDefinition)`）
   - 根据 `ClassMetadata.isIndependent()` 判断是否是顶级类或者静态内部类
       - 如果不是顶级类或者静态内部类，则不为 Bean，直接返回
       - 如果是，表示该类是“独立的”，即可以视作 Bean，继续判断
   - 根据 `ClassMetadata.isConcrete()` 判断
       - 如果类是抽象类，但存在被 `@Lookup` 注解的方法，可以视作 Bean，否则不为 Bean
       - 如果是接口，不能视作 Bean
5. 如果筛选通过，那么就表示扫描到了一个 Bean，将 `ScannedGenericBeanDefinition` 加入结果集 `Set<BeanDefinition>`

**注意**：`CachingMetadataReaderFactory` 解析某个 `.class` 文件得到 `MetadataReader` 对象是利用的 **ASM技术**，并没有加载这个类到 JVM。并且，最终得到的 `ScannedGenericBeanDefinition` 对象，`ScannedGenericBeanDefinition` 的 `beanClass` 属性存储的是当前类的名字，而不是 class 对象（beanClass 属性的类型是 Object，它即可以存储类的名字，也可以存储 class 对象）。

## 填充 BeanDefinition
9. 遍历 BeanDefinition 集合 `Set<BeanDefinition>`
   1. 设置 BeanDefinition 的 Scope 属性
   2. 生成并设置 BeanDefinition 的 beanName（`AnnotationBeanNameGenerator.generateBeanName(BeanDefinition, BeanDefinitionRegistry)`）
       1. 如果 `@Component` 注解指定了 value 属性，则 value 的值为 BeanName
       2. 否则使用 `Introspector.decapitalize(className)` 生成 BeanName
   4. 解析 Bean 的 `@Lazy`、`@Primary`、`DependsOn`、`@Role`、`@Description` 注解，给 BeanDefinition 赋值（`AnnotationConfigUtils.processCommonDefinitionAnnotations(AnnotatedBeanDefinition, AnnotatedTypeMetadata)`）
   5. 检查 Spring 容器中是否已经存在相同 beanName 的 Bean（`ClassPathBeanDefinitionScanner.checkCandidate()`）
      1. 如果不存在，**将当前 BeanDefinition 加入 BeanDefinitionMap 中**
      2. 如果存在，判断当前 BeanDefinition 是否被多次扫描
         1. 是则略过此 Bean
         2. 否则表示存在相同 beanName 的 Bean，抛出异常
      
    
