---
layout: article
title: 外部参数传入awk后不一致问题
date: 2019-07-11 12:00
category: Shell
tags: [Shell, awk]
---

# 外部参数传入awk后不一致问题

## 问题描述

在编写shell时, 需要向shell 中传递外部定义的参数, Google到这篇文章
<https://blog.csdn.net/rj042/article/details/72860177>

里面介绍了四种方法向 `awk` 中传递外部参数 , 于是直接参考文章的方法一使用
发现出现问题

于是写了一个简单的 shell 验证其中四个方法的正确性

shell 如下:

```shell
lot_num=$(date '+%Y%m%d%H%M%S%N'|cut -b 1-17)

export lot_num;

echo "$lot_num"

awk 'BEGIN{print "method 1,"'$lot_num'}'

awk 'BEGIN{print "method 2,"'"$lot_num"'}'

awk 'BEGIN{print "method 3,"ENVIRON["lot_num"]}'

awk -v _lot_num="$lot_num" 'BEGIN{print "method 4,"_lot_num}'
```

第 4 行和第 5 行的 `awk` 命令中 , 可以传入外部参数 `$lot_num` ,
但是运行后打印的值可能和 `lot_num` 原来的值不一致, 可能会比原 `lot_num`
的时间多或少几毫秒

实际输出如下:

```

20180321165826371

method 1,20180321165826372

method 2,20180321165826372

method 3,20180321165826371

method 4,20180321165826371

20180321165827380

method 1,20180321165827380

method 2,20180321165827380

method 3,20180321165827380

method 4,20180321165827380

20180321165828396

method 1,20180321165828396

method 2,20180321165828396

method 3,20180321165828396

method 4,20180321165828396

20180321165829405

method 1,20180321165829404

method 2,20180321165829404

method 3,20180321165829405

method 4,20180321165829405

20180321165830413

method 1,20180321165830412

method 2,20180321165830412

method 3,20180321165830413

method 4,20180321165830413

20180321165831422

method 1,20180321165831424

method 2,20180321165831424

method 3,20180321165831422

method 4,20180321165831422

20180321165832431

method 1,20180321165832432

method 2,20180321165832432

method 3,20180321165832431

method 4,20180321165832431

20180321165833439

method 1,20180321165833440

method 2,20180321165833440

method 3,20180321165833439

method 4,20180321165833439

```

## 解决方法

向 `awk` 传递外部参数可以参考上面文章的方法 3 和方法 4 , 不建议使用方法 1
和方法 2

方法三：export变量，然后在`awk`中使用`ENVIRON["var"]`形式获取环境变量的值

方法四：使用`awk -v`选项
