---
layout: article  
title: Spring MCV-文件下载  
date: 2019-05-05  
category:  
tags: []  
---

在 springmvc 应用程序中下载文件有几种方法:
1. `HttpServletRespone`: 使用 HttpServletResponse 将文件直接写入 ServletOutputStream
2. `ResponseEntity<InputStreamResource>`: 返回包装在 ResponseEntity 中的 InputStreamResource 文件
3. `ResponseEntity<ByteArrayResource>`: 可以返回包装在 ResponseEntity 中的 ByteArrayResource 文件

## `HttpServletRespone`
```java
@GetMapping("/download")
public void download(HttpServletResponse resonse) {
    try{
        // get file as InputStream
        InputStream is=...;
        // copy it to response's OutputStream
        org.apache.commons.io.IOUtils.copy(is,response.getOutputStream());
        response.flushBuffer();
    }catch(IOException ex){
        log.info("Error writing file to output stream. Filename was '{}'",fileName,ex);
        throw new RuntimeException("IOError writing file to output stream");
    }
}
```

## [`ResponseEntity<InputStreamResource>`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/io/InputStreamResource.html)
> Resource implementation for a given InputStream.
> Should only be used if no other specific Resource implementation is > applicable. 
> In particular, prefer ByteArrayResource or any of the file-based Resource implementations where possible.
```java
@GetMapping("/download")
public ResponseEntity<InputStreamResource> download() throw FileNotFoundException {
	File file = service.generateFile();
	InputStreamResource resource = new InputStreamResource(new FileInputStream(file));
	return ResponseEntity.ok()
			.header(HttpHeaders.CONTENT_DISPOSITION, "attachment;filename=" + file.getName())
			.contentType(MediaType.TEXT_PLAIN) // or others
			.contentLength(file.length())
			.body(resource);
}
```

## [`ByteArrayResource`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/io/ByteArrayResource.html)
[`InputStreamResource`](#InputStreamResource ) 的文档建议使用 `ByteArrayResource`
```java
@GetMapping(path = "/download")
public ResponseEntity<Resource> download(String param) throws IOException {
    File file = // get file
    Path path = Paths.get(file.getAbsolutePath());
    ByteArrayResource resource = new ByteArrayResource(Files.readAllBytes(path));

    return ResponseEntity.ok()
            .headers(HttpHeaders.CONTENT_DISPOSITION, "attachment;filename=" + file.getName())
            .contentLength(file.length())
            .contentType(MediaType.APPLICATION_OCTET_STREAM)
            .body(resource);
}
```

## 参考
<https://www.boraji.com/spring-mvc-4-file-download-example?tdsourcetag=s_pcqq_aiomsg>
<https://stackoverflow.com/questions/5673260/downloading-a-file-from-spring-controllers>