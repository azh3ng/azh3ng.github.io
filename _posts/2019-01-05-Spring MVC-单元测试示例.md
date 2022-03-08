---
layout: article  
title: Spring MVC-单元测试示例  
date: 2019-01-05  
category:  
tags: []  
---

# Spring MVC-单元测试示例

记录 Spring Boot 中 Spring MVC 的单体测试样例, 方便以后写单体测试直接复制粘贴
包括:
- GET 请求
- GET 请求文件下载
- POST 请求
- POST 请求文件上传

## 环境准备（Prerequisite）
- JDK 1.8
- Maven 3.5.4

## 设置（Configuration）
- Maven 依赖
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <version>${spring.boot.version}</version>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>com.vaadin.external.google</groupId>
            <artifactId>android-json</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.12</version>
    <scope>test</scope>
</dependency>
```

## 实例详解
单元测试执行过程:
1. 准备测试环境
2. 通过MockMvc执行请求
3.1. 添加验证断言
3.2. 添加结果处理器
3.3. 得到MvcResult进行自定义断言/进行下一步的异步请求
3. 卸载测试环境

### 被测试类示例
```java
@RestController
@RequestMapping("/foo")
public class FooController {

    @Autowired
    private FooService fooService;
    
    // HTTP method GET
    @GetMapping("/get")
    public FooResponse get(@RequestParam(value = "offset") int offset,
                           @RequestParam(value = "limit") int limit) {
        return fooService.get(offset, limit);
    }
    
    // HTTP method GET File download
    @GetMapping("/get/fileDownload")
    public ResponseEntity<InputStreamResource> getFile() throws FileNotFoundException {
        File file = fooService.getFile();
        InputStreamResource resource = new InputStreamResource(new FileInputStream(file));
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment;filename=" + file.getName())
                .contentType(MediaType.TEXT_PLAIN)
                .contentLength(file.length())
                .body(resource);
    }

    // HTTP method POST
    @PostMapping("/post")
    public FooResponse post(FooRequest fooRequest) {
        return fooService.post(fooRequest);
    }
    
    // HTTP method POST File Upload
    @PostMapping("/post/fileUpload")
    public FooResponse postFile(@RequestParam("file") MultipartFile multipartFile) {
        if (multipartFile == null || multipartFile.isEmpty())
            throw new IllegalArgumentException();
        return fooService.postFile(multipartFile);
    }
}
```

### Spring MVC 单元测试类示例
```java
@RunWith(SpringRunner.class)
@SpringBootTest
@AutoConfigureMockMvc
public class ControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    FooService fooService;

    /**
     * 【备选】调用接口获取 token
     * @throws Exception
     */
    @Before
    public void setUp() throws Exception {
        MvcResult mvcResult = mockMvc.perform(post("/oauth/token")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED_VALUE)
                .content("username=oauth_admin&password=123456&grant_type=password&redirect_uri=http://www.azh3ng.com&client_id=login&client_secret=secret;")
        ).andReturn();
        UnitTestOAuth2AccessToken oAuth2Token = JsonUtils.deserializeWithNoError(mvcResult.getResponse().getContentAsString(), UnitTestOAuth2AccessToken.class);
        token = oAuth2Token.getValue();
    }
    
    @After
    public void tearDown() throws Exception {
    }

    private String token;

    // HTTP method GET
    @Test
    public void testHTTPGet() {
        FooResponse expectResponse = new FooResponse();
        expectResponse.setCode("0");
        expectResponse.setMsg("OK");
        when(fooService.get(eq("0"), eq("10"))).thenReturn(expectResponse);
        
        
        try {
            MvcResult mvcResult = mockMvc.perform(get("/foo")
                    .param("offset", "0")
                    .param("limit", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk()).andReturn();

            verify(this.fooService, times(1)).get(eq("0"), eq("10"));
            Assert.assertEquals(JsonUtils.serializeWithNoError(expectResponse), mvcResult.getResponse().getContentAsString());
        } catch (Exception e) {
            e.printStackTrace();
            Assert.fail();
        }
    }
    
    // HTTP method GET File download
    @Test
    public void testFileDownload() throws IOException {
        File file = new File("download.csv");
        if (!file.exists()) {
            file.createNewFile();
        }
        when(fooService.getFile()).thenReturn(file);
        try {
            MvcResult mvcResult = mockMvc.perform(get("/get/fileDownload")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk()).andReturn();

            verify(fileService, times(1)).getFile();
            MockHttpServletResponse response = mvcResult.getResponse();
            Assert.assertEquals(HttpStatus.OK.value(), response.getStatus());
            Assert.assertEquals("attachment;filename=download.csv", response.getHeader(HttpHeaders.CONTENT_DISPOSITION));
            Assert.assertEquals(MediaType.TEXT_PLAIN_VALUE, response.getContentType());
        } catch (Exception e) {
            e.printStackTrace();
            Assert.fail();
        } finally {
            file.delete();
        }
    }

    // HTTP method POST
    @Test
    public void testHTTPPost() {
        FooResponse expectResponse = new FooResponse();
        expectResponse.setCode("0");
        expectResponse.setMsg("OK");

        when(this.fooService.post(any(FooRequest.class))).thenReturn(expectResponse);

        /* Map<String, String> map = new HashMap<>();
        map.put("id", "001");
        map.put("name", "tom");
        String content = JsonUtils.serializeWithNoError(map); */
        FooRequest fooRequest = new FooRequest();
        fooRequest.setId("001");
        fooRequest.setName("tom");
        String content = JsonUtils.serializeWithNoError(fooRequest);
        try {
            MvcResult mvcResult = this.mockMvc.perform(
                    post("/post")
                            .content(content)
                            .contentType(MediaType.APPLICATION_JSON_UTF8)).andExpect(status().isOk())
                    .andReturn();
            verify(this.fooService, times(1)).post(any(FooRequest.class));
            Assert.assertEquals(JsonUtils.serialize(expectResponse), mvcResult.getResponse().getContentAsString());
        } catch (Exception e) {
            e.printStackTrace();
            Assert.fail();
        }
    }
    
    // HTTP method POST File Upload
    @Test
    public void testFileUpload() {
        FooResponse expectResponse = new FooResponse();
        expectResponse.setCode("0");
        expectResponse.setMsg("OK");
        when(fooService.postFile(any(MultipartFile.class))).thenReturn(expectResponse);

        try {
            MvcResult mvcResult = mockMvc.perform(
                    MockMvcRequestBuilders
                            .fileUpload("/post/fileUpload")
                            .file(
                                    new MockMultipartFile("file", "upload.csv", ",multipart/form-data", "fileContent".getBytes(StandardCharsets.UTF_8))
                            )
                            .header("Authorization", "Bearer " + token)
            ).andExpect(status().isOk())
                    .andReturn();
            verify(this.fooService, times(1)).postFile(any(MultipartFile.class));
            Assert.assertEquals(JsonUtils.serializeWithNoError(expectResponse), mvcResult.getResponse().getContentAsString());
        } catch (Exception e) {
            e.printStackTrace();
            Assert.fail();
        }
    }
}
```