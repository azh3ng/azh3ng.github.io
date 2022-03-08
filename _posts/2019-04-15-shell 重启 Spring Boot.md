---
layout: article  
title: shell 重启 Spring Boot  
date: 2022-03-08 16:54  
category:  
tags: []  
---

# shell 重启 Spring Boot

```shell
# 通过端口号获取旧线程的 pid
pid=`lsof -i:8080 | grep -v COMMAND | awk '{print $2}'`

# 结束旧线程
echo "旧应用进程id:$pid"
if [ -n "$pid" ]
then
kill -9 $pid
fi

# 启动新线程
nohup java -jar /path/service-1.0-SNAPSHOT.jar &

# 查询新线程的 pid
npid=`lsof -i:8080 | grep -v COMMAND | awk '{print $2}'`
echo "新的进程 $npid"
echo "启动成功＿"

sleep 2

# 显示 log
tail -f /path/logs/service.log
```
