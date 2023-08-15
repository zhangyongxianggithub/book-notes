WebClient最简单的创建方式式通过静态工厂方法。
- `WebClient.create()`
- `WebClient.create(String baseUrl)`

你可以使用`WebClient.builder()`更细粒度的控制WebClient的创建
- uriBuilderFactory: 自定义`UriBuilderFactory`来生成base URL
- defaultUriVariables: URI模板中使用的变量的默认值
- defaultHeader: 每个请求的headers
- defaultCookie: 每个请求用的cookies
- defaultRequest: 修改request的修改器
- filter: 过滤器
- exchangeStrategies: HTTP 消息读写定制
- clientConnector: HTTP客户端库设置
- observationRegistry: 开启观察机制的注册点
- observationConvention: 

例子:
```java
WebClient client = WebClient.builder()
		.codecs(configurer -> ... )
		.build();
```
一旦构建，WebClient就是不可修改的。你可以拷贝并修改拷贝:
```java
WebClient client1 = WebClient.builder()
		.filter(filterA).filter(filterB).build();

WebClient client2 = client1.mutate()
		.filter(filterC).filter(filterD).build();

// client1 has filterA, filterB

// client2 has filterA, filterB, filterC, filterD
```
# MaxInMemorySize
编码器可以设置缓存数据的内存大小避免内存过大。默认情况下，设置为256KB，如果不够，你将收到下面的异常:
>org.springframework.core.io.buffer.DataBufferLimitException: Exceeded limit on max bytes to buffer

可以修改这个大小:
```java
WebClient webClient = WebClient.builder()
		.codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
		.build();
```
# Reactor Netty
