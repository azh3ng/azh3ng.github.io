---
layout: article  
title: thymeleaf替换回车为br标签  
date: 2019-03-12
tags: []  
---

项目中使用 thymeleaf 生成邮件信息，当数据中有换行符时，邮件内容无法正常显示换行（特别是使用 Outlook）  
尝试通过设置`style="white-space: pre-wrap;word-wrap: break-word;"`让其显示换行  
邮箱查看邮件内容，换行符生效，Outlook 查看邮件内容，换行符无效  

通过搜索得知`<br>`可以正常显示换行，故需要将数据中的换行替换为`<br>`  
可以通过代码将换行字符串替换为`<br>`，后 thymeleaf 中将`th:text`替换为`th:utext`即可，如下：
```html
<dir th:utext="${content}"></dir>
```

或者使用 thymeleaf 的语法将换行符替换为`<br>`
```
<dir th:utext="${#strings.unescapeJava(#strings.replace(#strings.escapeJava(content),'\n','&lt;br/&gt;'))}"></dir>
```

## 参考
<https://blog.csdn.net/xielinrui123/article/details/87979352>
