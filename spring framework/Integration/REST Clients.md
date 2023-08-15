# WebClient
WebClient是一个执行HTTP请求的非阻塞的响应式的客户端。从5.0版本引入，是`RestTemplate`的替代。支持同步、异步与流式的场景。WebClient支持下面的特性:
- 非阻塞的I/O
- Reactive Streams back pressure
- High concurrency with fewer hardware resources.
- Functional-style, fluent API that takes advantage of Java 8 lambdas.
- Synchronous and asynchronous interactions.
- Streaming up to or streaming down from a server.
  
可以参考[WebClient](https://docs.spring.io/spring-framework/reference/web/webflux-webclient.html)获取更多的信息.
# RestTemplate
`RestTemplate`提供了HTTP客户端库的更高抽象的视角API。使得调用REST API更容易，它提供了下面几组重载的方法。`RestTemplate`目前处于维护状态，只接受BUG变更，请优先考虑使用WebClient。
| **Method group**                    | **Description** |
|-------------------------------------|-----------------|
| getForObject                        |通过GET检索资源                 |
| getForEntity                                    |检索ResponseEntity                 |
| headForHeaders |检索所有的headers                 |
|  postForLocation                                   |创建一个新的资源，并返回Location header                 |
| postForObject                        | 创建资源                |
|postForEntity|创建资源|
|put|创建或者更新资源|
|patchForObject|使用PATCH更新资源|
|delete|删除资源|
|optionsForAllow|使用ALLOW获取资源支持的HTTP methods|
|exchange|更通用的方法版本接受RequestEntity，返回ResponseEntity，接受`ParameterizedTypeReference`而不是Class来指定response的范型类型|
|execute|更通用的方法版本，可以执行更加底层的控制|
## Initialization
默认构造的`RestTemplate`使用`java.net.HttpURLConnection`来执行请求，你可以指定别的HTTP库，只要库实现了`ClientHttpRequestFactory`，内置支持:
- Apache HttpComponents
- Netty
- OkHttp

比如，切换到Apache HttpComponents，你可以这么设置:
```java
RestTemplate template = new RestTemplate(new HttpComponentsClientHttpRequestFactory());
```
每一种`ClientHttpRequestFactory`的实现都暴露了底层HTTP库的相关配置选项，可以用于配置证书、连接池等其他的细节。请注意，当访问表示错误的响应状态（例如401）时，HTTP请求的java.net实现可能会引发异常。如果这是一个问题，请切换到别的HTTP客户端库。
## URIs
`RestTemplate`方法接受URI模板与模板变量，或者是字符串变量或者是`Map<String,String>`。下面的例子使用了变量参数:
```java
String result = restTemplate.getForObject(
		"https://example.com/hotels/{hotel}/bookings/{booking}", String.class, "42", "21");
```
下面的例子使用`Map<String,String>`
```java
Map<String, String> vars = Collections.singletonMap("hotel", "42");
String result = restTemplate.getForObject(
		"https://example.com/hotels/{hotel}/rooms/{hotel}", String.class, vars);
```
URI模板会自动编码，比如下面的例子:
```java
restTemplate.getForObject("https://example.com/hotel list", String.class);
// Results in request to "https://example.com/hotel%20list"
```
你可以使用`RestTemplate`的`uriTemplateHandler`属性来自定义URI如何编码，或者你可以制作一个`java.net.URI`，传递它到接受的方法中。
## Headers
使用`exchange()`来指定headers
```java
String uriTemplate = "https://example.com/hotels/{hotel}";
URI uri = UriComponentsBuilder.fromUriString(uriTemplate).build(42);
RequestEntity<Void> requestEntity = RequestEntity.get(uri)
		.header("MyRequestHeader", "MyValue")
		.build();
ResponseEntity<String> response = template.exchange(requestEntity, String.class);
String responseHeader = response.getHeaders().getFirst("MyResponseHeader");
String body = response.getBody();
```
你可以通过`ResponseEntity`获得响应的header。
## Body
`RestTemplate`方法中的输入/输出对象，都会与HTTP的body完成转换，这种转换是通过`HttpMessageConverter`完成的。对于POST请求来说，输入对象被转换为request body，如下所示:
```java
URI location = template.postForLocation("https://example.com/people", person);
```
你不需要显式指定请求的Content-Type头，在大多数情况下，你可以根据输入对象类型来找到一个兼容的message converter，converter会设置这个头。如果有必要，你也可以通过exchange方法来设置这个头，当然这会影响到message converter的选择。对于get请求来说，响应的body会被反序列化为输出的对象类型，如下所示:
```java
Person person = restTemplate.getForObject("https://example.com/people/{id}", Person.class, 42);
```
请求的Accept头不需要显式的设置，在大多数场景下，根据响应的输出类型选择一个兼容的message converter，然后这个converter会设置Accept头信息，如果有必要，你可以使用exchange方法来显式的提供Accept头信息。默认情况下，`RestTemplate`会注册所有的内置的message converters。depending on classpath checks that help to determine what optional conversion libraries are present. You can also set the message converters to use explicitly.
## Message Conversion
spring-web模块提供了`HttpMessageConverter`用于读写HTTP的body。框架提供了每一种media type的具体实现。默认情况下，客户端部分会注册到`RestTemplate`中，在服务端，会注册到`RequestMappingHandlerAdapter`中。下面的表格描述了具体的实现，对于所有的converter，都提供了一个默认的media type。你可以可以设置supportedMediaType属性来改变它。
|MessageConverter|Description|
|:---|:---|
|StringHttpMessageConverter|读写字符串，支持所有的text media type，比如text/*|
|FormHttpMessageConverter|读写form data，默认支持application/x-www-form-urlencoded media type，数据被读写到一个`MultiValueMap<String, String>`对象中，这个converter也支持写multipart数据，默认也支持multipart/form-data media type|
|ByteArrayHttpMessageConverter|读写字节数组，支持所有的media type */*，写数据时使用application/octet-stream|
|MarshallingHttpMessageConverter|读写XML|
|MappingJackson2HttpMessageConverter||
|MappingJackson2XmlHttpMessageConverter||
|SourceHttpMessageConverter||
|BufferedImageHttpMessageConverter|读写`java.awt.image.BufferedImage`|
