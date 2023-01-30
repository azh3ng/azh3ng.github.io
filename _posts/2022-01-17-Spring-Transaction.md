---
layout: article  
alias: 
title: 【理解Spring】事务
date: 2022-01-17 00:00
titleEn: Spring-Transaction
tags: [Spring]
originFileName: "Spring事务.md"
---



在 Spring 中，事务有两种实现方式：
1. **编程式事务管理**：编程式事务管理使用 TransactionTemplate 可实现细粒度的事务控制  
2. **声明式事务管理**：基于 Spring AOP 实现。其本质是对方法前后进行拦截，然后在目标方法开始之前创建或者加入一个事务，在执行完目标方法之后根据执行情况提交或者回滚事务  

开发中更常使用声明式事务，因为不会入侵代码，通过 `@Transactional` 注解即可以完成事务管理  
声明式事务基于 Spring AOP 实现：向 Spring 中添加 BeanPostProcessor 扫描被 `@Transactional` 注解的类，生成代理对象，通过代理对象完成事务管理  

## 使用示例

### 编程式事务使用示例
使用 `TransactionTemplate` 进行编程式事务管理的示例代码：
```java
@Autowired
private TransactionTemplate transactionTemplate;
public void testTransaction() {
    transactionTemplate.execute(new TransactionCallbackWithoutResult() {
        @Override
        protected void doInTransactionWithoutResult(TransactionStatus transactionStatus) {
            try {
                // ....  业务代码
            } catch (Exception e){
                //回滚
                transactionStatus.setRollbackOnly();
            }
        }
    });
}
```

使用 `TransactionManager` 进行编程式事务管理的示例代码：
```java
@Autowired
private PlatformTransactionManager transactionManager;

public void testTransaction() {

  TransactionStatus status = transactionManager.getTransaction(new DefaultTransactionDefinition());
          try {
               // ....  业务代码
              transactionManager.commit(status);
          } catch (Exception e) {
              transactionManager.rollback(status);
          }
}
```

### 声明式事务使用示例

`@Transactional` 注解标注在类上，则相当于类中每个方法都添加了此注解；当方法上标注了 `@Transactional` 注解，则方法的事务属性会覆盖类中的事务属性  
```java
@Transactional
public class TestTransactional {
    public void testTransactional1() {}
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void testTransactional2() {}
}
```

## 核心接口/类

### TransactionAttributeSource
`TransactionAttributeSource` 接口用于判断类是否被事务管理，常见实现类为 `AnnotationTransactionAttributeSource`，解析 `@Transactional` 注解得到相应的事务属性。

### TransactionManager
`TransactionManager` 是 Spring 事务事务管理的主要接口，常见子类包括 `PlatformTransactionManager` 和 `ReactiveTransactionManager`。  
`PlatformTransactionManager` 的常见实现类为 `DataSourceTransactionManager`，提供了获取 DataSource、获取事务、开启、挂起、恢复、提交、回滚等各类事务操作的具体实现。

### TransactionSynchronizationManager
`TransactionSynchronizationManager` 是一个事务管理的核心类，通过 `TransactionSynchronizationManager` 可以管理当前线程的事务，可以获取当前事务的信息，包括事务名，事务传播机制等。    
还可以在事务结束或者开始之前实现自定义逻辑（[TransactionSynchronization](#transactionsynchronization)）  
代码示例：  
```java
// Return the name of the current transaction, or {@code null} if none set.
TransactionSynchronizationManager.getCurrentTransactionName();
// Return the isolation level for the current transaction, if any.
TransactionSynchronizationManager.getCurrentTransactionIsolationLevel();
```

### TransactionSynchronization
TransactionSynchronization 可以监听当前 Spring 事务所处于的状态，在事务提交，回滚、挂起、恢复时执行自定义逻辑  
代码示例：  
```java
@Component
public class UserService {
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private UserService userService;

    @Transactional
    public void test() {
        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    @Override
                    public void suspend() {
                        System.out.println("test被挂起了");
                    }

                    @Override
                    public void resume() {
                        System.out.println("test被恢复了");
                    }

                    @Override
                    public void beforeCommit(boolean readOnly) {
                        System.out.println("test准备要提交了");
                    }

                    @Override
                    public void beforeCompletion() {
                        System.out.println("test准备要提交或回滚了");
                    }

                    @Override
                    public void afterCommit() {
                        System.out.println("test提交成功了");
                    }

                    @Override
                    public void afterCompletion(int status) {
                        System.out.println("test提交或回滚成功了");
                    }
                });
        jdbcTemplate.execute("insert into t1 values(1,1,1,1,'1')");
        System.out.println("test");
        userService.a();
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void a() {
        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    @Override
                    public void suspend() {
                        System.out.println("a被挂起了");
                    }

                    @Override
                    public void resume() {
                        System.out.println("a被恢复了");
                    }

                    @Override
                    public void beforeCommit(boolean readOnly) {
                        System.out.println("a准备要提交了");
                    }

                    @Override
                    public void beforeCompletion() {
                        System.out.println("a准备要提交或回滚了");
                    }

                    @Override
                    public void afterCommit() {
                        System.out.println("a提交成功了");
                    }

                    @Override
                    public void afterCompletion(int status) {
                        System.out.println("a提交或回滚成功了");
                    }
                });
        jdbcTemplate.execute("insert into t1 values(2,2,2,2,'2')");
        System.out.println("a");
    }
}
```

## 事务传播机制

在 Spring 中对于事务的传播行为定义了七种类型分别是：REQUIRED、SUPPORTS、MANDATORY、REQUIRES_NEW、NOT_SUPPORTED、NEVER、NESTED  
Spring 源码中这七种类型的枚举定义在 `org.springframework.transaction.annotation.Propagation`  

### REQUIRED
Propagation.REQUIRED 是 Spring 默认的事务传播机制；如果当前存在事务，则加入当前事务，如果不存在则创建新事务。  
**注意**：当事务方法 1 Propagation.REQUIRED 调用事务方法 2 Propagation.REQUIRED 时，如果事务方法 2 抛出异常，在事务方法 1 中捕获异常后不向外抛出，但整个事务依旧会回滚。  
因为在事务方法 2 回滚时，会判断 globalRollbackOnParticipationFailure = true(默认)，则会在数据库连接上**设置回滚标记**，当事务方法 1 执行完成后，执行[提交事务](#提交事务) 时，会**判断回滚标记**，如果为 ture，则执行回滚事务  

### REQUIRES_NEW
不论当前是否存在事务，总是会新建一个事务，如果存在当前事务，则挂起当前事务  
创建的新事务独立存在，独立提交和回滚不会影响其他事务  

### NESTED
如果当前事务存在，则在开启一个嵌套事务，在嵌套事务中执行，否则开启一个事务  
**注意**：REQUIRES_NEW 是新建一个事务并且新开启的这个事务与原有事务无关，而 NESTED 则是当前存在事务时（暂且把当前事务称之为父事务）会开启一个嵌套事务（称之为一个子事务）。  
在 NESTED 情况下父事务回滚时，子事务也会回滚，而在 REQUIRES_NEW 情况下，原有事务回滚，不会影响新开启的事务。  
同时 NESTED 提供 savepoint 机制，当数据库支持 savepoint 则可以实现内嵌的事务失败时，仅回滚到 savepoint，而不是回滚整个事务  

### SUPPORTS
如果当前存在事务，则加入事务；如果当前不存在事务，则以非事务方式运行，这个和不写效果一样  

### MANDATORY
当前存在事务，则加入当前事务，如果当前事务不存在，则抛出异常。  

### NOT_SUPPORTED
始终以非事务方式执行，如果当前存在事务，则挂起当前事务  

### NEVER
不使用事务，如果当前事务存在，则抛出异常  

## Spring 整合事务 
在 Spring 中使用声明式事务，往往是添加 `@EnableTransactionManagement` 注解启用 Spring 事务。  
`@EnableTransactionManagement` 注解向 Spring 中添加了两个 Bean：
1. `AutoProxyRegistrar`
2. `ProxyTransactionManagementConfiguration`

### AutoProxyRegistrar
`org.springframework.context.annotation.AutoProxyRegistrar`  
`AutoProxyRegistrar` 向 Spring 容器中注册了 `InfrastructureAdvisorAutoProxyCreator` 类型的 Bean。  
`InfrastructureAdvisorAutoProxyCreator` 继承 [Spring AOP#AbstractAdvisorAutoProxyCreator](/2022/01/16/Spring-AOP.html#abstractadvisorautoproxycreator)，也即它是个 BeanPostProcessor，并且相当于开启了 Spring AOP。  

### ProxyTransactionManagementConfiguration
`org.springframework.transaction.annotation.ProxyTransactionManagementConfiguration`  
`ProxyTransactionManagementConfiguration` 是一个配置类，内部定义了三个 Bean：  
1. `BeanFactoryTransactionAttributeSourceAdvisor` ：一个 [Spring AOP#Advisor](/2022/01/16/Spring-AOP.html#advisor)
2. `AnnotationTransactionAttributeSource` ：相当于 `BeanFactoryTransactionAttributeSourceAdvisor` 中的 [Spring AOP#Pointcut](/2022/01/16/Spring-AOP.html#pointcut)  
3. `TransactionInterceptor` ：相当于 `BeanFactoryTransactionAttributeSourceAdvisor` 中的 [Spring AOP#Advice](/2022/01/16/Spring-AOP.html#advice)

### AnnotationTransactionAttributeSource  
`AnnotationTransactionAttributeSource` 可以判断类或者方法上是否存在 `@Transactional` 注解

### TransactionInterceptor 
`TransactionInterceptor` 是 Spring 定义的事务方法拦截器，也就是事务的代理逻辑  
当某个类中存在 `@Transactional` 注解时，会产生创建代理对象作为 Bean，代理对象在执行某个方法时，会进入到 `TransactionInterceptor.invoke()` 方法  

## Spring 事务详细执行流程
- `org.springframework.transaction.interceptor.TransactionInterceptor#invoke`
    - （事务执行详细）`org.springframework.transaction.interceptor.TransactionAspectSupport#invokeWithinTransaction`
        - （获取 TransactionManager）`org.springframework.transaction.interceptor.TransactionAspectSupport#determineTransactionManager`
        - （开启事务）`org.springframework.transaction.interceptor.TransactionAspectSupport#createTransactionIfNecessary`
        - 执行目标对象的方法
        - （回滚事务）`org.springframework.transaction.interceptor.TransactionAspectSupport#completeTransactionAfterThrowing`
        - （清除事务信息）`org.springframework.transaction.interceptor.TransactionAspectSupport#cleanupTransactionInfo`
        - （提交事务）`org.springframework.transaction.interceptor.TransactionAspectSupport#commitTransactionAfterReturning`

### 开启事务
- `TransactionAspectSupport.createTransactionIfNecessary()`
  - `AbstractPlatformTransactionManager.getTransaction()`
    - `AbstractPlatformTransactionManager.startTransaction()`
  - `TransactionAspectSupport.prepareTransactionInfo()`  

**简述**：  
- 判断当前是否存在事务  
  - 是则根据事务传播机制做出相应处理；  
  - 否则继续判断事务传播机制，或抛出异常，或挂起并新建事务  
- 将挂起的事务缓存到新建的事务中  

**详述**：  
1. 调用 `TransactionManager.getTransaction()`
   1. 尝试获取当前线程的事务（`DataSourceTransactionManager.doGetTransaction()`）
   2. 判断当前线程是否存在事务(`DataSourceTransactionManager.isExistingTransaction()`)
      1. 如果有，判断当前事务的传播机制（`AbstractPlatformTransactionManager.handleExistingTransaction()`）做出相应处理，并返回结果
      2. 否则继续执行
   3. 判断事务传播机制
      1. 如果是 [MANDATORY](#mandatory)，抛出异常
      2. 如果是 [REQUIRED](#required) 或 [REQUIRES_NEW](#requires_new) 或 [NESTED](#nested)
         1. [挂起空事务](#挂起事务)
         2. 开启事务（ `TransactionManager.startTransaction()`）
            1. 缓存事务的状态信息（当前事务信息、挂起的事务信息等)
            2. 创建数据库连接（`DataSourceTransactionManager.doBegin()`））
               2. 如果当前线程中所使用的 DataSource 还没有创建过数据库连接，则**新建**数据库连接
               3. 设置事务隔离级别
               4. 设置 readOnly 属性
               5. 设置 AutoCommit 为 false
               6. 设置数据库连接的过期时间
               7. 把**新建**的数据库连接缓存到 TreadLocal （TransactionSynchronizationManager）中
            3. 将**新建的**数据库连接信息（当前事务名、readOnly、隔离级别、wasActive）缓存到 TreadLocal（`TransactionSynchronizationManager`）中（`AbstractPlatformTransactionManager.prepareSynchronization()`）
2. 构建 TransactionInfo 并返回（`TransactionAspectSupport.prepareTransactionInfo()`）
   1. 新建 TransactionInfo（包含事务管理器、事务属性、连接点信息(方法名)）
   2. TransactionInfo 设值 transactionStatus
   3. 组装事务链
      1. 将当前线程中的 TransactionInfo 设值到新建的 TransactionInfo.oldTransactionInfo
      2. 将新建的 TransactionInfo 设置到当前线程中

### 挂起事务
`org.springframework.transaction.support.AbstractPlatformTransactionManager#suspend`  
**简述**：  
如果存在 `TransactionSynchronization`（代表存在事务），则执行其 `suspend()` 方法，并挂起当前事务，将被挂起的事务信息打包并返回  

**详述**：  
1. 判断 `TransactionSynchronization` 是否处于激活状态，如果是：
    1. 执行所有事务同步器的 `suspend()` 方法（`AbstractPlatformTransactionManager.doSuspendSynchronization()`）
       1. **获取**并**清空**线程中的 `List<TransactionSynchronization>`
       2. 返回 `List<TransactionSynchronization>`
    2. 挂起事务（`DataSourceTransactionManager.doSuspend()`）
       1. 移除并返回线程中（TransactionSynchronizationManager）中的数据库连接
    3. **获取**并**清空**当前线程中（TransactionSynchronizationManager）的设置(当前事务名、readOnly、隔离级别、wasActive)
    4. 将被挂起的事务属性打包成 `SuspendedResourcesHolder` 
    5. 返回
2. 如果不存在事务同步器，但存在事务
    1. 挂起当前事务（`DataSourceTransactionManager.doSuspend()`）
        1. 移除并返回线程中（TransactionSynchronizationManager）中的数据库连接
    2. 将被挂起的事务属性打包成 SuspendedResourcesHolder
    3. 返回
3. 如果即不存在事务同步器，又不存在事务
    1. 返回空

### 提交事务
`org.springframework.transaction.interceptor.TransactionAspectSupport#commitTransactionAfterReturning`  
**简述**：判断事务是否需要回滚，如果是，则执行 [回滚事务](#回滚事务)，根据事务状态执行事务提交、关闭数据库连接、将被挂起的事务恢复  

**详述**：  
- 判断事务是否被设置为强制回滚，是则执行 [回滚事务](#回滚事务)，返回
- 判断事务是否被标记为需要回滚，是则执行 [回滚事务](#回滚事务)，返回
- 判断如果存在 TransactionSynchronization，执行其 `beforeCommit()` 和 `beforeCompletion()` 方法
- 判断事务是否有 savepoint，如果有则释放 savepoint
- 否则判断是否为新事务
  - 如果是，获取数据库连接，执行提交（`DataSourceTransactionManager#doCommit`）
- 判断如果存在 TransactionSynchronization，执行其 `afterCompletion()` 方法

### 回滚事务
`org.springframework.transaction.interceptor.TransactionAspectSupport#completeTransactionAfterThrowing`  
**简述**：判断抛出的异常是否与回滚异常相同，相同则执行回滚，根据事务传播机制判断执行回滚 savepoint 或 回滚事务 或 标记事务需要回滚  

**详述**：  
- 判断抛出的异常是否与回滚异常相同  
  - 是则执行回滚（`AbstractPlatformTransactionManager.rollback()` -> `AbstractPlatformTransactionManager.processRollback()`）
    - 判断
      - 存在 savepoint，则回滚至 savepoint
      - 是新事务，则执行回滚
      - 否则将事务标记为需要回滚，在事务提交时执行回滚
    - 如果存在 `TransactionSynchronization`，执行其 `afterCompletion()` 方法
  - 否则执行提交（`AbstractPlatformTransactionManager.commit()`）

## Spring 事务强制回滚
如果在方法中增加这一行代码：  
`TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();`  
在提交事务时会做判断，如果为 true，则会执行事务回滚操作  
