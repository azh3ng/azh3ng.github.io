---
layout: article  
title: Spring MVC-GET请求参数下划线转驼峰映射实体类  
date: 2020-01-09  
category:  
tags: []  
---

# Spring MVC-GET请求参数下划线转驼峰映射实体类

环境: Spring MVC/Spring-Boot
项目开发统一规定, 前后端交互所有参数名的单词间需要使用下划线连接, 例如: user_id  
在 POST 请求交互时, 可以在实体类的字段上添加 JSON 注解, 使请求体中的 JSON 字符串直接映射为实体类, 转换步骤自动完成, 
如: `@JsonProperty("user_id") private String userId;`
但是在 GET 请求时, 对于下划线连接的参数无法直接映射封装为实体类(java 编程规范参数使用驼峰命名法), 需要编码接收参数并转换封装为实体对象, 过于繁琐, 如:
```java
@Controller
@RequestMapping("/user")
public class UserController {
    @GetMapping("")
    public void getList(@Param("user_id") String userId, @Param("user_name") String userName) {
       User user = new User();
       user.setId(userId);
       user.setName(userName);
    }
}
```
于是希望可以将此步骤自动完成  

思路: 
创建注解, 标注在需要处理的参数前
继承 ServletModelAttributeMethodProcessor, 将下划线参数转换成驼峰形式, 放入请求参数中, 使框架可以自动将参数映射到实体类上
将上述逻辑注册到 WebConfig 中

@interface ParameterModel
```java
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 实体映射注解
 * 配置该注解的参数会使用 UnderlineToCamelArgumentResolver 类完成装载
 */
@Target(value = ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface ParameterModel {
}
```

class UnderlineToCamelArgumentResolver
```java
import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.PropertyValues;
import org.springframework.core.MethodParameter;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ServletModelAttributeMethodProcessor;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 将请求参数带有下划线转驼峰命名
 */
public class UnderlineToCamelArgumentResolver extends ServletModelAttributeMethodProcessor {

    public UnderlineToCamelArgumentResolver(boolean annotationNotRequired) {
        super(annotationNotRequired);
    }

    @Override
    public boolean supportsParameter(MethodParameter methodParameter) {
        return methodParameter.hasParameterAnnotation(ParameterModel.class);
    }

    protected void bindRequestParameters(WebDataBinder binder, NativeWebRequest request) {
        // 将key-value封装为map，传给bind方法进行参数值绑定
        Map<String, String> map = new HashMap<>();
        Map<String, String[]> params = request.getParameterMap();

        for (Map.Entry<String, String[]> entry : params.entrySet()) {
            String name = entry.getKey();
            // 执行urldecode
            // String value = URLDecoder.decode(entry.getValue()[0], "UTF-8");
            String value = entry.getValue()[0];
            map.put(underLineToCamel(name), value);
        }

        PropertyValues propertyValues = new MutablePropertyValues(map);

        // 将K-V绑定到binder.target属性上
        binder.bind(propertyValues);
    }

    private String underLineToCamel(String source) {
        Matcher matcher = Pattern.compile("_(\\w)").matcher(source);
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            matcher.appendReplacement(sb, matcher.group(1).toUpperCase());
        }
        matcher.appendTail(sb);
        return sb.toString();
    }
}
```

class WebConfig
```java
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(new UnderlineToCamelArgumentResolver(true));
    }
}
```

class Controller
```java
@RestController
@RequestMapping("/api")
public class FooController {

	@GetMapping("/test")
    public void test(@ParameterModel FooRequest request) {
        
    }
}
```


## 参考
- <https://www.cnblogs.com/w-y-c-m/p/8443892.html> 
- <http://coderec.cn/2016/08/27/%E4%B8%80%E6%AD%A5%E4%B8%80%E6%AD%A5%E8%87%AA%E5%AE%9A%E4%B9%89SpringMVC%E5%8F%82%E6%95%B0%E8%A7%A3%E6%9E%90%E5%99%A8/>

- 经测试, 此方法无效 <https://stackoverflow.com/questions/18091936/spring-mvc-valid-validation-with-custom-handlermethodargumentresolver>