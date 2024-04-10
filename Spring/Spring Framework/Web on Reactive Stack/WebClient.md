Spring WebFlux提供了一个用于执行HTTP请求的客户端。WebClient具有函数式、流式的API特点。是基于Reactor开发的。支持声明式的异步组合逻辑，不需要处理线程或者并发相关的问题。它完全是非阻塞的。WebClient底层也需要一个HTTP客户端库。内置支持的客户端库包括:
- [Reactor Netty](https://github.com/reactor/reactor-netty)
- [JDK HttpClient](https://docs.oracle.com/en/java/javase/11/docs/api/java.net.http/java/net/http/HttpClient.html)
- [Jetty Reactive HttpClient](https://github.com/jetty-project/jetty-reactive-httpclient)
- [Apache HttpComponents](https://hc.apache.org/index.html)
- 其他可以通过`ClientHttpConnector`加载的库
# Configuration
WebClient最简单的创建方式式通过静态工厂方法。
- `WebClient.create()`
- `WebClient.create(String baseUrl)`

你可以使用`WebClient.builder()`更细粒度的控制`WebClient`的创建
- `uriBuilderFactory`: 自定义`UriBuilderFactory`来生成base URL
- `defaultUriVariables`: URI模板中使用的变量的默认值
- `defaultHeader`: 每个请求的headers
- `defaultCookie`: 每个请求用的cookies
- `defaultRequest`: 修改request的修改器
- `filter`: 过滤器
- `exchangeStrategies`: HTTP消息读写定制
- `clientConnector`: HTTP客户端库设置
- `observationRegistry`: 开启[观察机制](https://docs.spring.io/spring-framework/reference/integration/observability.html#http-client.webclient)的注册点
- `observationConvention`: 一个可选的自定义的转换，用来解析元数据

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
## MaxInMemorySize
编码器可以设置缓存数据的内存大小避免内存过大。默认情况下，设置为256KB，如果不够，你将收到下面的异常:
>org.springframework.core.io.buffer.DataBufferLimitException: Exceeded limit on max bytes to buffer

可以修改这个大小:
```java
WebClient webClient = WebClient.builder()
		.codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
		.build();
```
## Reactor Netty
为了自定义`Reactor Netty`设置，需要提供一个自定义的`HttpClient`
```java
HttpClient httpClient = HttpClient.create().secure(sslSpec -> ...);

WebClient webClient = WebClient.builder()
		.clientConnector(new ReactorClientHttpConnector(httpClient))
		.build();
```
### Resources
默认情况下，`HttpClient`会共享全局的Reactor Netty资源，这些资源在`reactor.netty.http.HttpResources`中，包含事件轮询线程与一个连接池，这是推荐的模式，因为固定的共享资源更适合事件轮询并发。在此模式下，全局资源保持活动状态，直到进程退出。如果服务器与进程的生命周期相同，不需要明确的关闭资源，但是服务器可以在客户端连接中启动或者停止，则可以使用`globalResources=true`（默认值）声明 `ReactorResourceFactory`类型的bean，以确保Reactor当Spring ApplicationContext关闭时，Netty全局资源也会关闭，如下例所示:
```java
@Bean
public ReactorResourceFactory reactorResourceFactory() {
	return new ReactorResourceFactory();
}
```
你可以选择不使用全局的Reactor Netty资源，在这种模式下，你要负责确保Reactor Netty客户端端与服务端使用共享资源:
```java
@Bean
public ReactorResourceFactory resourceFactory() {
	ReactorResourceFactory factory = new ReactorResourceFactory();
	factory.setUseGlobalResources(false); 
	return factory;
}

@Bean
public WebClient webClient() {

	Function<HttpClient, HttpClient> mapper = client -> {
		// Further customizations...
	};

	ClientHttpConnector connector =
			new ReactorClientHttpConnector(resourceFactory(), mapper); 

	return WebClient.builder().clientConnector(connector).build(); 
}
```
### Timeouts
配置连接超时
```java
HttpClient httpClient = HttpClient.create()
		.option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10000);

WebClient webClient = WebClient.builder()
		.clientConnector(new ReactorClientHttpConnector(httpClient))
		.build();
```
配置读写超时
```java
HttpClient httpClient = HttpClient.create()
		.doOnConnected(conn -> conn
				.addHandlerLast(new ReadTimeoutHandler(10))
				.addHandlerLast(new WriteTimeoutHandler(10)));

// Create WebClient...
```
配置所有请求的响应超时
```java
HttpClient httpClient = HttpClient.create()
		.responseTimeout(Duration.ofSeconds(2));

// Create WebClient...
```
配置某个请求的响应超时
```java
WebClient.create().get()
		.uri("https://example.org/path")
		.httpRequest(httpRequest -> {
			HttpClientRequest reactorRequest = httpRequest.getNativeRequest();
			reactorRequest.responseTimeout(Duration.ofSeconds(2));
		})
		.retrieve()
		.bodyToMono(String.class);
```
### Timeouts
## JDK HttpClient
下面的例子展示了如何定制化JDK HttpClient
```java
HttpClient httpClient = HttpClient.newBuilder()
    .followRedirects(Redirect.NORMAL)
    .connectTimeout(Duration.ofSeconds(20))
    .build();

ClientHttpConnector connector =
        new JdkClientHttpConnector(httpClient, new DefaultDataBufferFactory());

WebClient webClient = WebClient.builder().clientConnector(connector).build();
```
## Jetty
如何自定义`Jetty HttpClient`设置
```java
HttpClient httpClient = new HttpClient();
httpClient.setCookieStore(...);

WebClient webClient = WebClient.builder()
		.clientConnector(new JettyClientHttpConnector(httpClient))
		.build();
```
缺省情况下，`HttpClient`会自动创建需要的资源(`Executor`、`ByteBufferPool`、`Scheduler`)等，在处理结束或者`stop()`调用前都保持active，你可以在多个Jetty Client对象间共享资源，要确保`ApplicationContext`关闭后，资源也要得到关闭释放，可以声明一个`JettyResourceFactory`类型的bean。
```java
@Bean
public JettyResourceFactory resourceFactory() {
	return new JettyResourceFactory();
}

@Bean
public WebClient webClient() {

	HttpClient httpClient = new HttpClient();
	// Further customizations...

	ClientHttpConnector connector =
			new JettyClientHttpConnector(httpClient, resourceFactory()); // 使用构造函数

	return WebClient.builder().clientConnector(connector).build(); // 
}
```
## HttpComponents
如何自定义` Apache HttpComponents HttpClient`设置
```java
HttpAsyncClientBuilder clientBuilder = HttpAsyncClients.custom();
clientBuilder.setDefaultRequestConfig(...);
CloseableHttpAsyncClient client = clientBuilder.build();

ClientHttpConnector connector = new HttpComponentsClientHttpConnector(client);

WebClient webClient = WebClient.builder().clientConnector(connector).build();
```
# `retrieve()`
`retrieve()`方法能够用来声明如何提取响应，比如:
```java
WebClient client = WebClient.create("https://example.org");

Mono<ResponseEntity<Person>> result = client.get()
		.uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
		.retrieve()
		.toEntity(Person.class);
```
或者只是获取响应体
```java
WebClient client = WebClient.create("https://example.org");

Mono<Person> result = client.get()
		.uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
		.retrieve()
		.bodyToMono(Person.class);
```
获得解码后的对象流
```java
Flux<Quote> result = client.get()
		.uri("/quotes").accept(MediaType.TEXT_EVENT_STREAM)
		.retrieve()
		.bodyToFlux(Quote.class);
```
缺省情况下，4xx/5xx响应会抛出`WebClientResponseException`异常，包含特定状态码对应的子类。为了自定义错误响应的处理，使用`onStatus`处理器:
```java
Mono<Person> result = client.get()
		.uri("/persons/{id}", id).accept(MediaType.APPLICATION_JSON)
		.retrieve()
		.onStatus(HttpStatus::is4xxClientError, response -> ...)
		.onStatus(HttpStatus::is5xxServerError, response -> ...)
		.bodyToMono(Person.class);
```
# Exchange
`exchangeToMono()`与`exchangeToFlux()`方法用在需要更多控制的高级场景，比如依赖响应码的不同决定如何解码响应。
```java
Mono<Person> entityMono = client.get()
		.uri("/persons/1")
		.accept(MediaType.APPLICATION_JSON)
		.exchangeToMono(response -> {
			if (response.statusCode().equals(HttpStatus.OK)) {
				return response.bodyToMono(Person.class);
			}
			else {
				// Turn to error
				return response.createError();
			}
		});
```
上面的例子，在`Mono`与`Flux`完成后，响应体会被检查，如果没有被消费，它会被释放避免内存泄漏或者连接泄漏。因此响应不能在下游解码，需要提供函数来声明如何解码响应。
# Request Body
请求体可以来自能够被`ReactiveAdapterRegistry`处理的所有的异步类型。如下:
```java
Mono<Person> personMono = ... ;

Mono<Void> result = client.post()
		.uri("/persons/{id}", id)
		.contentType(MediaType.APPLICATION_JSON)
		.body(personMono, Person.class)
		.retrieve()
		.bodyToMono(Void.class);
```
也可以使用编码对象流，如下:
```java
Flux<Person> personFlux = ... ;

Mono<Void> result = client.post()
		.uri("/persons/{id}", id)
		.contentType(MediaType.APPLICATION_STREAM_JSON)
		.body(personFlux, Person.class)
		.retrieve()
		.bodyToMono(Void.class);
```
另外，如果你有了全部的body，你可以使用`bodyValue`快捷方法，如下例子:
```java
Person person = ... ;

Mono<Void> result = client.post()
		.uri("/persons/{id}", id)
		.contentType(MediaType.APPLICATION_JSON)
		.bodyValue(person)
		.retrieve()
		.bodyToMono(Void.class);
```
## Form Data
为了发送form data，你可以提供一个`MultiValueMap<String, String>`对象作为body，记住，内容类型会被`FormHttpMessageWriter`自动设置为`application/x-www-form-urlencoded`，下面是一个例子:
```java
MultiValueMap<String, String> formData = ... ;

Mono<Void> result = client.post()
		.uri("/path", id)
		.bodyValue(formData)
		.retrieve()
		.bodyToMono(Void.class);
```
你还可以使用`BodyInserters`提供内联的form data，如下例子:
```java
Mono<Void> result = client.post()
		.uri("/path", id)
		.body(fromFormData("k1", "v1").with("k2", "v2"))
		.retrieve()
		.bodyToMono(Void.class);
```
## Multipart Data
为了发送multipart data，需要提供`MultiValueMap<String, ?>`作为body，它的value都是Object类型的对象表示part内容，如果是`HttpEntity`类型的对象，则表示part的内容与headers。`MultipartBodyBuilder`提供了方便的方式来构造multipart请求，下面例子:
```java
MultipartBodyBuilder builder = new MultipartBodyBuilder();
builder.part("fieldPart", "fieldValue");
builder.part("filePart1", new FileSystemResource("...logo.png"));
builder.part("jsonPart", new Person("Jason"));
builder.part("myPart", part); // Part from a server request

MultiValueMap<String, HttpEntity<?>> parts = builder.build();
```
在大多数场景下，你不需要指定每个part的`Content-Type`，`Content-Type`会基于使用的`HttpMessageWriter`序列化器自动决定，如果是一种资源，则基于文件扩展名自动决定。如果有必要，你可以通过重载的`part`方法明确提供媒体类型。例子如下:
```java
MultipartBodyBuilder builder = ...;

Mono<Void> result = client.post()
		.uri("/path", id)
		.body(builder.build())
		.retrieve()
		.bodyToMono(Void.class);
```
如果`MultiValueMap`包含至少一个非字符串的part，你不需要明确设置`Content-Type: multipart/form-data`，使用`MultipartBodyBuilder`时会始终设置。你也可以直接提供multipart内容，通过`BodyInserters`，如下所示:
```java
Mono<Void> result = client.post()
		.uri("/path", id)
		.body(fromMultipartData("fieldPart", "value").with("filePart", resource))
		.retrieve()
		.bodyToMono(Void.class);
```
## PartEvent
为了将multipart data流化，你可以通过`PartEvent`对象来i痛multipart内容。
- `FormPartEvent::create`创建form fields
- `FilePartEvent::create`创建File upload

你可以通过`Flux::conca`来拼接流，并为`WebClient`创建请求。下面是一个例子:
```java
Resource resource = ...
Mono<String> result = webClient
    .post()
    .uri("https://example.com")
    .body(Flux.concat(
            FormPartEvent.create("field", "field value"),
            FilePartEvent.create("file", resource)
    ), PartEvent.class)
    .retrieve()
    .bodyToMono(String.class);
```
在服务端，`PartEvent`对象会通过`@RequestBody`或者`ServerRequest::bodyToFlux(PartEvent.class)`接收，并且可以直接被`WebClient`转发给其他的服务。
# Filters
你可以通过`WebClient.Builder`注册一个客户端filter，`ExchangeFilterFunction`，如下所示:
```java
WebClient client = WebClient.builder()
		.filter((request, next) -> {

			ClientRequest filtered = ClientRequest.from(request)
					.header("foo", "bar")
					.build();

			return next.exchange(filtered);
		})
		.build();
```
在cross-cutting concerns上有用，比如认证，下面的例子使用filter来完成一个basic认证
```java
WebClient client = WebClient.builder()
		.filter(basicAuthentication("user", "password"))
		.build();
```
可以修改一个已存在的`WebClient`实例来添加或者移除filters，会形成一个新的`WebClient`
```java
WebClient client = webClient.mutate()
		.filters(filterList -> {
			filterList.add(0, basicAuthentication("user", "password"));
		})
		.build();
```
`WebClient`是一个围绕过滤器链的薄外观，后面是`ExchangeFunction`。它提供了一个工作流程来发出请求、对更高级别的对象进行编解码，并确保响应内容始终被使用。当过滤器以某种方式处理响应时，必须格外小心，始终使用其内容，或者以其他方式将其向下游传播到`WebClient`，以确保相同的效果。下面是一个过滤器，用于处理UNAUTHORIZED状态码，但确保任何响应内容（无论是否预期）都会被释放:
```java
public ExchangeFilterFunction renewTokenFilter() {
	return (request, next) -> next.exchange(request).flatMap(response -> {
		if (response.statusCode().value() == HttpStatus.UNAUTHORIZED.value()) {
			return response.releaseBody()
					.then(renewToken())
					.flatMap(token -> {
						ClientRequest newRequest = ClientRequest.from(request).build();
						return next.exchange(newRequest);
					});
		} else {
			return Mono.just(response);
		}
	});
}
```
下面的例子展示了如何使用`ExchangeFilterFunction`接口来创建一个自定义的filter，这个filter帮助计算`Content-Length`
```java
public class MultipartExchangeFilterFunction implements ExchangeFilterFunction {

    @Override
    public Mono<ClientResponse> filter(ClientRequest request, ExchangeFunction next) {
        if (MediaType.MULTIPART_FORM_DATA.includes(request.headers().getContentType())
                && (request.method() == HttpMethod.PUT || request.method() == HttpMethod.POST)) {
            return next.exchange(ClientRequest.from(request).body((outputMessage, context) ->
                request.body().insert(new BufferingDecorator(outputMessage), context)).build()
            );
        } else {
            return next.exchange(request);
        }
    }
    private static final class BufferingDecorator extends ClientHttpRequestDecorator {

        private BufferingDecorator(ClientHttpRequest delegate) {
            super(delegate);
        }

        @Override
        public Mono<Void> writeWith(Publisher<? extends DataBuffer> body) {
            return DataBufferUtils.join(body).flatMap(buffer -> {
                getHeaders().setContentLength(buffer.readableByteCount());
                return super.writeWith(Mono.just(buffer));
            });
        }
    }
}
```
# Attributes
你可以向请求添加attributes，如果你需要在filter chain之间传递信息这很有用，比如:
```java
WebClient client = WebClient.builder()
		.filter((request, next) -> {
			Optional<Object> usr = request.attribute("myAttribute");
			// ...
		})
		.build();

client.get().uri("https://example.org/")
		.attribute("myAttribute", "...")
		.retrieve()
		.bodyToMono(Void.class);

	}
```
注意，你可以在`WebClient.Builder`级别配置一个全局的`defaultRequest`回调，可以将attribute插入到所有的请求，例如，可以在Spring MVC应用程序中使用该回调来使用ThreadLocal数据填充请求属性。
# Context
Attributes提供了方便的方式将信息传递到filter chain，但是他们只会影响当前请求，如果你想要把信息广播到多个请求，比如通过`flatMap`, `concatMap`形成的嵌套请求，你需要使用`Reactor Context`，`Reactor Context`需要填充在反应链的末尾才能应用于所有操作。 例如：
```java
WebClient client = WebClient.builder()
		.filter((request, next) ->
				Mono.deferContextual(contextView -> {
					String value = contextView.get("foo");
					// ...
				}))
		.build();

client.get().uri("https://example.org/")
		.retrieve()
		.bodyToMono(String.class)
		.flatMap(body -> {
				// perform nested request (context propagates automatically)...
		})
		.contextWrite(context -> context.put("foo", ...));
```
# Synchronous Use
`WebClient`可以用同步的方式使用，也就输阻塞等待结果。
```java
Person person = client.get().uri("/person/{id}", i).retrieve()
	.bodyToMono(Person.class)
	.block();

List<Person> persons = client.get().uri("/persons").retrieve()
	.bodyToFlux(Person.class)
	.collectList()
	.block();
```
如果发出多个请求，要避免阻塞等待每个请求的结果，只需要等待最后所有请求的结果。
```java
Mono<Person> personMono = client.get().uri("/person/{id}", personId)
		.retrieve().bodyToMono(Person.class);

Mono<List<Hobby>> hobbiesMono = client.get().uri("/person/{id}/hobbies", personId)
		.retrieve().bodyToFlux(Hobby.class).collectList();

Map<String, Object> data = Mono.zip(personMono, hobbiesMono, (person, hobbies) -> {
			Map<String, String> map = new LinkedHashMap<>();
			map.put("person", person);
			map.put("hobbies", hobbies);
			return map;
		})
		.block();
```
上面仅仅只是一个例子，有很多模式与运算符来构件响应式管道。可以让多个远程调用不需要等待阻塞等待结束。通过`Flux`与`Mono`，你不需要在Spring MVC/Spring WebFlux的controller中阻塞，之需要返回响应式类型，对于Kotlin的协程也是如此。

