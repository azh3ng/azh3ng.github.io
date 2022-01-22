---
layout: article
title: Spring-Boot 整合 DBUnit 使用笔记
date: 2019-01-12 10:27
category: UnitTest
tags: [UnitTest, Spring-Boot, DBUnit]
aside:
  toc: true
---

Spring-Boot 整合 DBUnit 对 Dao 层进行单元测试  
Dao 层查询方法的单元测试相对简单，将数据查询出来，再在代码中用 `assert` 方法进行测试即可  
但是 Dao 层的插入/更新/删除 方法的单元测试相对难写  
可以借助 DBUnit 辅助编写单元测试  

DBUnit 的测试流程是
1. 开启事务
2. 将数据库中的数据更新为期望的初始状态
3. 执行测试代码
4. 将数据库中的数据与预期结果（xml/csv/excel等文件）进行比对，与预期不符则测试失败
5. 事务回滚

对于不同的 `@Test` 测试方法，需要不同的初始状态及预期结果，DBUnit 提供了 `@DatabaseSetup` `@ExpectedDatabase` `@DatabaseTearDown`
等注解，作用于不同的测试方法，设置其初始状态和预期

DBUnit 中 IDataSet 接口对应数据库的表数据
IDataSet 的实现有很多，每一个都对应一个不同的数据源或加载机制。最常用的几种 IDataSet 实现为：
- FlatXmlDataSet：对应 xml 文件
- QueryDataSet：用 SQL 查询获得的数据
- DatabaseDataSet：数据库表本身内容的一种表示
- XlsDataSet ：对应 excel 文件
- CsvURLDataSet：对应 csv 文件

下面是实际工作中的使用示例

## 目录结构

- src
    - test
        - java
            - com.azh3ng
                - config
                    - DbUnitConfig.java
                    - XXXDataSetLoader.java
                - dao
                    - FooDaoTest.java
        - resources
            - com.azh3ng.dao
                - FooDao
                    - FooDao_expect.xls

## pom 文件

pom.xml
```xml
<!-- dbunit-->
<dependency>
   <groupId>org.dbunit</groupId>
   <artifactId>dbunit</artifactId>
   <version>2.6.0</version>
   <scope>test</scope>
</dependency>
<dependency>
   <groupId>com.github.springtestdbunit</groupId>
   <artifactId>spring-test-dbunit</artifactId>
   <version>1.3.0</version>
   <scope>test</scope>
</dependency>
```
## 代码

src/test/java/com/azh3ng/config/DbUnitConfig.java
解决异常: org.dbunit.database.AmbiguousTableNameException: XXX_TABLE_NAME

> 当一个数据库中有多个 scheme，并且不同 scheme 中有相同表名时，会抛出异常：AmbiguousTableNameException: XXX_TABLE_NAME
> 设置 DBUnitConnection 可以解决这个问题

```java
import com.github.springtestdbunit.bean.DatabaseConfigBean;
import com.github.springtestdbunit.bean.DatabaseDataSourceConnectionFactoryBean;
import org.dbunit.ext.mysql.MySqlMetadataHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class DbUnitConfig {
    @Bean("dbUnitConnection")
    public DatabaseDataSourceConnectionFactoryBean getTestConnection(DataSource dataSource) {
        DatabaseDataSourceConnectionFactoryBean bean = new DatabaseDataSourceConnectionFactoryBean();
        bean.setDataSource(dataSource);
        DatabaseConfigBean databaseConfigBean = new DatabaseConfigBean();
        databaseConfigBean.setMetadataHandler(new MySqlMetadataHandler());
        databaseConfigBean.setAllowEmptyFields(true);
        bean.setDatabaseConfig(databaseConfigBean);
        bean.setSchema("schema_name");
        return bean;
    }
}
```

---

src/test/java/com/azh3ng/config/XXXDataSetLoader.java

用于加载解析`csv`/`xml`/`xls`文件为 `IDataSet`，供 DBUnit 变更数据库数据或作为预期结果对比数据库既存数据

```java
import com.github.springtestdbunit.dataset.AbstractDataSetLoader;
import org.apache.commons.lang3.StringUtils;
import org.dbunit.dataset.IDataSet;
import org.dbunit.dataset.csv.CsvURLDataSet;
import org.dbunit.dataset.excel.XlsDataSet;
import org.dbunit.dataset.xml.FlatXmlDataSetBuilder;
import org.springframework.core.io.Resource;

import java.io.FileNotFoundException;
import java.io.InputStream;

public class XXXDataSetLoader extends AbstractDataSetLoader {
    protected IDataSet createDataSet(Resource resource) throws Exception {
        String filename = resource.getFilename();
        if (StringUtils.isEmpty(filename)) {
            throw new FileNotFoundException("File name cannot be empty:" + resource.getURL());
        }
        if (filename.endsWith(".csv")) {
            return new CsvURLDataSet(resource.getURL());
        } else if (filename.endsWith(".xml")) {
            FlatXmlDataSetBuilder builder = new FlatXmlDataSetBuilder();
            builder.setColumnSensing(true);
            try {
                return builder.build(resource.getURL());
            } catch (Exception ex) {
                try (InputStream inputStream = resource.getInputStream()) {
                    return builder.build(inputStream);
                }
            }
        } else if (filename.endsWith(".xls")) {
            return new XlsDataSet(resource.getFile());
        } else {
            throw new IllegalArgumentException("Unsupported file type: " + filename);
        }
    }
}
```

---

src/test/java/com/azh3ng/dao/FooDaoTest.java

测试类

```java
import com.github.springtestdbunit.DbUnitTestExecutionListener;
import com.github.springtestdbunit.annotation.DbUnitConfiguration;
import com.azh3ng.config.XXXDataSetLoader;
import lombok.extern.slf4j.Slf4j;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockitoTestExecutionListener;
import org.springframework.test.annotation.Rollback;
import org.springframework.test.context.TestExecutionListeners;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.context.support.DependencyInjectionTestExecutionListener;
import org.springframework.test.context.support.DirtiesContextTestExecutionListener;
import org.springframework.test.context.transaction.TransactionalTestExecutionListener;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@RunWith(SpringRunner.class)
@Slf4j
@Transactional
@Rollback(true)
/*
  配置数据加载器为自定义的 XXXDataSetLoader.class
  即可 以 Excel文件(仅支持 xls文件, 不支持 xlsx 文件), csv文件， xml文件作为初始化数据和验证结果
 */
@DbUnitConfiguration(dataSetLoader = XXXDataSetLoader.class, databaseConnection = "dbUnitConnection")
@TestExecutionListeners({DependencyInjectionTestExecutionListener.class,
        DirtiesContextTestExecutionListener.class,
        TransactionalTestExecutionListener.class,
        MockitoTestExecutionListener.class,
        DbUnitTestExecutionListener.class})
public class FooDaoTest {
    @Autowired
    private FooDao dao;

    @Test
    /*
      配置事务
      前置条件:需要 @TestExecutionListeners 中包含 TransactionalTestExecutionListener.class
      事务会在 @DatabaseSetup 之前启动，在 @DatabaseTearDown 和 @ExpectedDatabase 之后结束, 并回滚
     */
    @Transactional
    /*
      初始化数据
      1.到当前类的包下找 "FooDao" 包下的 Excel 文件 "FooDao_setup.xls",
        （文件中 sheet 名即为表名, 多 sheet 页即多表 , sheet 页内, 第一行为字段名）
      2.清空数据库中的 Excel 文件中包含的表 的数据,
      3.将 Excel 中的数据插入到数据库
     */
    @DatabaseSetup("FooDao/FooDao_setup.xls")
    /*
      验证结果
      1.当测试代码执行完成后，到当前类的包下找 "FooDao" 包下的 Excel 文件 "FooDao_expect.xls"
      2.比对数据库中数据和 Excel 中数据是否相同
      assertionMode = NON_STRICT_UNORDERED 表示比对时忽略 Excel 中没有的表和字段, 并且比对时忽略数据行的顺序
     */
    @ExpectedDatabase(value = "FooDao/FooDao_expect.xls", assertionMode = NON_STRICT_UNORDERED)
    /*
      teardown
      1.到当前类的包下找 "FooDao" 包下的Excel文件 "FooDao_setup.xls"
      2.清空数据库中的 Excel 文件中包含的表 的数据
      type = DatabaseOperation.DELETE_ALL 表示删除数据库中的 Excel文件中包含的表 的所有数据
     */
    @DatabaseTearDown(value = "FooDao/FooDao_setup.xls", type = DatabaseOperation.DELETE_ALL)
    public void test() {
        dao.doTest();
    }
}
```

## 参考
http://www.blogjava.net/liuzheng/articles/190128.html
