---
layout: article  
title: CapsLockPlus | 魔改 CapsLock 键  
date: 2021-06-13  
tags: [Windows]  
---

# CapsLockPlus | 魔改 CapsLock 键

CapsLock，也就是键盘最左边一列中间那个大写锁定键，跟 shift 功能重复，需要输入大写字母的时候，一般都直接通过 Shift 输入了。  
在换了 Anne-pro2 键盘之后, 发现 CapsLock 键和其他按键组合使用十分方便， 然而这是键盘的驱动软件的效果, 于是希望找到一个通用的解决方案。    
试用过 [CapsLock+](https://cjkis.me/capslock+/) , 但是终究不如自定义来的顺心  
于是参考 [这篇文章](https://www.cnblogs.com/Vonng/p/4240219.html) ，编写 AutoHotKey 脚本, 魔改了 CapsLock, 自定义了 CapsLock 组合其他键的功能  
AutoHotKey 脚本可以编译成`.exe`的可执行文件, 不需要安装, 双击即可运行, 删除就是卸载   
`.exe`文件大小一共也就 1M 左右, 在github、网盘或邮箱备份一份, 在其他电脑上随用随下, 很方便，编译好的`.exe`文件可以加入开机启动, 不用每次开机都需要手动启动

可执行的 EXE 文件、`.ahk`脚本文件、生成 ahk 脚本文件的 Python 脚本都已上传到 github。  
地址：[https://github.com/azh3ng/CapsLockPlus](https://github.com/azh3ng/CapsLockPlus)

## 文件说明

| 文件名                         | 说明                                          | 备注                          |
| ------------------------------ | ------------------------------------------- | ---------------------------- |
| CapsLockPlus.ahk               | `ahk`脚本                                   | 脚本语法简单说明见下方             |
| CapsLockPlus.exe               | 通过`ahk`脚本编译的可直接执行的exe文件            | 无需安装, 使用方法见<使用说明>      | 
| Generate_CapsLockPlus_script.py  | 可以生成`ahk`脚本的 python 程序               | 运行 python 程序需要 python 环境  |

## CapsLockPlus 使用说明

CapsLockPlus.exe 无需安装，双击即可运行

### CapsLock 功能关闭（禁用 CapsLock）

CapsLockPlus.exe 启动后，CapsLock 功能关闭，单独按下 CapsLock 键没有任何效果

### 导航键

CapsLock + i/k/j/l 分别对应 方向键 上, 下, 左, 右  
CapsLock + u/o 分别对应 Home/End 键

可以结合 Ctrl/Shift/Alt 使用  
意即  
同时按下 `CapsLock + Shift + j` 相当于 同时按下 `Shift + 方向键左`(向左选中一个字母)  
同时按下 `CapsLock + Ctrl + Shift + j` 相当于 同时按下 `Ctrl + Shift + 方向键左`(向左选中一个单词)  
同时按下 `CapsLock + Ctrl + Shift + Alt + j` 相当于 同时按下 `Ctrl + Shift + Alt + 方向键左`

**以下所有组合都可以结合 Ctrl/Shift/Alt 使用**

### 删除键

CapsLock + n/m 分别对应 Backspace/Delete 键

### 功能键(F1~F12)

CapsLock + `1`/`2`/`3`...`9`/`0`/`-`/`=` 分别对应 F1~F12

### 菜单键

CapsLock + Enter 对应菜单键（Application key）

## python 脚本

Generate_CapsLockPlus_script.py 是一个使用 Python 语法编写的生成 AHK脚本的小程序, 运行需要 Python 3 环境  
程序使用 `map` 存储了 `CapsLock` + 其他按键的映射，遍历 `map` 生成 ahk 脚本  
如有需要可以自行修改

## 原生 AHK 脚本

AHK 语法简单说明

`#` 号代表 Win 键;  
`!` 号代表 Alt 键;  
`^` 号代表 Ctrl 键;  
`+` 号代表 shift 键;  
`::` 号(两个英文冒号)起分隔作用;  
`;` 号代表 注释后面一行内容;

`run`它的后面是要运行的程序完整路径 , 或者网址

如果想要运行本地安装的程序 , 可写 `run D:\Program Files (x86)\Sublime Text 3\sublime_text.exe`

如果想要打开指定网址 , 可写 `run www.baidu.com`(使用系统默认浏览器打开)

例1: 将 `Ctrl + J` 映射为 方向键左

```ahk
^j:: {Left}
```

例2: 将`Ctrl + Alt + Shift + Win + Q` 映射为启动 QQ

```ahk
`^!+#q::run QQ所在完整路径地址`
```

[AutoHotKey官网](https://www.autohotkey.com/docs/AutoHotkey.htm) 有`akh`语法的详细说明

### 运行 `AHK` 脚本

安装 AutoHotkey 右键自己的脚本文件 -> Run Script

### 编译 `ahk` 脚本为 exe 可执行文件

安装 AutoHotkey 选中自己创建的脚本(.ahk文件) -> 右键 -> Compile Script 即会生成一个与脚本同名的 .exe 文件，编译好的exe文件可以直接运行

