---
layout: article
title: Git放弃(清除)本地所有修改，回到上次 commit 的初始状态
date: 2020-02-12 10:27
tags: [Git]
---

# Git放弃(清除)本地所有修改，回到上次 commit 的初始状态

若想要放弃(清除)本地所有修改，回到上次 commit 的初始状态，可以执行
```shell
git reset --hard
git clean -xdf
```

### git checkout .
此命令用来放弃所有还没有加入到缓存区（就是`git add`命令）的修改：内容修改与整个文件删除。
但是此命令不会删除掉刚新建的文件。
因为刚新建的文件还没已有加入到 git 的管理系统中。所以对于git是未知的，可以执行`git clean`命令删除。

### git clean -xdf
删除新增但没有被`git add`的文件

### git reset --hard
官网解释：Resets the index and working tree. Any changes to tracked files in the working tree since <commit> are discarded.
实际就是除了**新增但没有被`git add`的文件**，其余所有文件回到上次 commit 的初始状态  
相当于包含了`git checkout .`，并且把所有加入缓存区的修改还原

## 实验演示

一个文件对于 git 来说有三种状态：新增、修改、删除
对于没有被`git commit`的的文件，有两种状态：`git add`进了缓存区，没有被add进缓存区
故设计 6 个实验文件：
- add_new.txt
- add_modify.txt
- add_delete.txt
- not_add_new.txt
- not_add_modify.txt
- not_add_delete.txt

初始状态只有 4 个文件，并且被`git commit`
- add_modify.txt
- add_delete.txt
- not_add_modify.txt
- not_add_delete.txt

开始实验：
1. 新增文件 add_new.txt
2. 修改文件 add_modify.txt
3. 删除文件 add_delete.txt
4. 执行 `git add .` 将上述 3 个修改添加到缓存区
5. 新增文件 not_add_new.txt
6. 修改文件 not_add_modify.txt
7. 删除文件 not_add_delete.txt

此时当前状态（记为**实验开始状态**）为：
```shell
$ git status
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        deleted:    add_delete.txt
        modified:   add_modify.txt
        new file:   add_new.txt

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        deleted:    not_add_delete.txt
        modified:  not_add_modify.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        not_add_new.txt
```
---
若处于实验开始状态时，执行`git checkout . `，则
- not_add_modify.txt 被还原
- not_add_delete.txt 被还原

即：
```shell
$ git checkout .
$ git status
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        deleted:    add_delete.txt
        modified:   add_modify.txt
        new file:   add_new.txt

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        not_add_new.txt
```
---
若处于实验开始状态时，执行`git clean -xdf`，则
- not_add_new 被删除

即：
```shell
$ git clean -xdf
Removing not_add_new.txt
$ git status
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        deleted:    add_delete.txt
        modified:   add_modify.txt
        new file:   add_new.txt

Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        deleted:    not_add_delete.txt
        modified:  not_add_modify.txt
```
---
若处于实验开始状态时，执行`git reset --hard`，则除了 `not_add_new.txt` ， 其余所有文件回到初始状态
- add_new.txt        -> 还原
- add_modify.txt     -> 还原
- add_delete.txt     -> 还原
- not_add_new.txt    -> untracked file 不变
- not_add_modify.txt -> 还原
- not_add_delete.txt -> 还原
  即：
```shell
$ git reset --hard
HEAD is now at f46c8a2 commit
$ git status
On branch master
Untracked files:
  (use "git add <file>..." to include in what will be committed)

        not_add_new.txt
```
## 参考
Git 如何放弃所有本地修改：https://www.cnblogs.com/chenjo/p/11398357.html