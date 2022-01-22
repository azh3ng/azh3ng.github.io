---
layout: article
title: 数据库表备份
date: 2018-12-21 12:00
category: Mysql
tags: [Mysql, SQL]
---

# 数据库表备份

`create table ... as ...` 语法可以备份表结构和数据
`insert into ... select ...` 语法可以备份表数据

---

将表 t_table 的**表结构**及**数据**备份到 t_table_bk
```sql
create table t_table
as
select * from t_table_bk
```

将表 t_table 的**表结构**备份到 t_table_bk
```sql
create table t_table
as
select * from t_table_bk
where 1=2
```
**注意：备份的表没有原表的主键信息， 所以不能直接改表名当作原表使用**

将插入备份表
```sql
insert into t_table_bk
select * from t_table
[where field = 'some value']
```
或
```sql
insert into t_table_bk(field1,field2,field3)
select field1,field2,field3 from t_table
[where field = 'some value']
```

## 参考
https://www.cxyzjd.com/article/xuehongyou/108751197
