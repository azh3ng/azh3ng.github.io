---
layout: article
title: kiss-translator(简约翻译)配置 Gemini AI Studio
date: 2025-08-12
tags: [Windows,software, 浏览器插件]
---

由于[沉浸式翻译](https://immersivetranslate.com/zh-Hans/) 最近出现了许多负面消息，于是尝试寻找替代品。

看到有推荐 [kiss-translator](https://github.com/fishjar/kiss-translator) 于是尝试使用。

由于默认的 Gemini 配置与 Gemini AI Studio 不兼容，于是摸索在自定义接口中配置。

在【接口设置】中，点开一个Custom，接口名称填一个易于分别的名字。

URL填写：https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent

如果是自搭建的 GeminiBalance，填写 http://ip:port/v1beta/models/gemini-2.5-flash-lite:generateContent

模型这里选择的是 gemini-2.5-flash-lite，翻译效果足够，速度快，不容易触发请求限制。

Key填写自己的 API Key

重点是 Request Hook 和 Response Hook

Request Hook：
```js
(text, from, to, url, key) => [
  url,
  {
    headers: {
      "Content-type": "application/json",
      "x-goog-api-key": key,
    },
    method: "POST",
    body: JSON.stringify({
      contents: [
        {
          parts: [
            {
              text: `Translate the following source text from ${from} to ${to}.
              Output translation directly without any additional text.
              Source Text: ${text}`,
            }
          ]
        }
      ]
    })
  }
];
```
Response Hook:
```js
(res, text, from, to) => [res['candidates'][0]['content']['parts'][0]['text'], to === res.src]
```
点击【点击测试】按钮，提示测试成功表示配置正确
