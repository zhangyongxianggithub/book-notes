Spring MVC支持Servlet异步请求处理。
- 在Conrtoller方法中的`DeferredResult`与`Callable`返回值类型提供了异步结果的功能
- 控制器可以将多个返回值变成流，包括SSE机制或者原始二进制数据机制
- 控制器可以使用反应式客户端，返回反应式类型用于响应处理

与Spring WebFlux的区别，请参考[Async Spring MVC compared to WebFlux](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-async.html#mvc-ann-async-vs-webflux)。
# DeferredResult
如果Servlet容器开启了异步请求处理功能，控制器方法可以将所有支持的返回值wrap到`DeferredResult`中，如下所示:
```java
@GetMapping("/quotes")
@ResponseBody
public DeferredResult<String> quotes() {
	DeferredResult<String> deferredResult = new DeferredResult<>();
	// Save the deferredResult somewhere..
	return deferredResult;
}
// From some other thread...
deferredResult.setResult(result);
```
控制器可以异步的产生的返回值，返回值可以来自另外的线程，比如JMS消息、调度任务或者其他事件
# Callable
返回`java.util.concurrent.Callable`包含实际的返回数据
```java
@PostMapping
public Callable<String> processUpload(final MultipartFile file) {
	return () -> "someView";
}
```
配置的`AsyncTaskExecutor`会运行这个`Callable`然后计算返回值。
# Processing
Servlet异步请求处理流程
- `ServletRequest`通过调用`request.startAsync()`进入异步请求模式，主要的影响就是Servlet与相关的Filters可以终止，但是response处于打开状态等待处理完成
- 调用`request.startAsync()`会返回`AsyncContext`对象，你可以用它来深入的控制异步处理。比如，它提供了`dispatch`方法，类似额Servlet API中的forward方法，不同之处在于它允许应用在Servlet容器线程上恢复请求处理
- 通过`ServletRequest`可以获取当前的`DispatcherType`，您可以使用它来区分处理初始请求、异步调度、转发和其他调度类型。

`DeferredResult`处理过程如下:
- 控制器方法返回一个`DeferredResult`，将它保存到某个内存队列或者列表中
- Spring MVC调用`request.startAsync()`方法
- 与此同时，`DispatcherServlet`与所有配置的filters终止请求处理线程，但是response仍然处于打开状态
- 应用从其他线程设置`DeferredResult`，Spring MVC派发请求回到Servlet容器
- `DispatcherServlet`再次被调用，请求处理通过异步生成的返回值恢复运行

`Callable`处理过程如下:
- 控制器方法返回`Callable`
- Spring MVC调用`request.startAsync()`，并且提交`Callable`到`AsyncTaskExecutor`来执行
- 与此同时，`DispatcherServlet`与所有配置的filters终止请求处理线程，但是response仍然处于打开状态
- 最终`Callable`产生结果，Spring MVC派发请求回到Servlet容器完成处理
- `DispatcherServlet`再次被调用，请求处理通过异步生成的返回值恢复运行

更多的背景知识与上下文，可以阅读这里的[博文](https://spring.io/blog/2012/05/07/spring-mvc-3-2-preview-introducing-servlet-3-async-support)，里面介绍了Spring MVC3.2中异步请求处理机制
## Exception Handling
当你使用`DeferredResult`时，你可以选择调用`setResult`或者`setErrorResult`，这2种方式都会让Spring MVC派发请求到Servlet容器从而完成请求处理，如果是通过`setErrorResult`调用，那么异常会经过常规的异常处理机制处理，比如调用`@EceptionHandler`的方法。`Callable`也是类似的处理逻辑，主要的不同是要么`Callable`返回结果，要么引发异常。
## Interception
`HandlerInterceptor`实例可以是`AsyncHandlerInterceptor`类型，可以接收到开启异步处理的原始请求的`afterConcurrentHandlingStarted`回调，而不是`postHandle`或者`afterCompletion`回调。`HandlerInterceptor`也可以注册为`CallableProcessingInterceptor`或者`DeferredResultProcessingInterceptor`，深度集成异步请求的生命周期事件，参考[Async
HandlerInterceptor](https://docs.spring.io/spring-framework/docs/6.2.1/javadoc-api/org/springframework/web/servlet/AsyncHandlerInterceptor.html)，`DeferredResult`提供了`onTimeout(Runnable)`与`onCompletion(Runnable)`回调，参考[DeferredResult](https://docs.spring.io/spring-framework/docs/6.2.1/javadoc-api/org/springframework/web/context/request/async/DeferredResult.html)的javadoc获取详细的信息，`Callable`可以使用`WebAsyncTask`替换，这个类为`timeout`与`completion`回调提供了方法。
## Spring MVC的异步请求处理与WebFlux的对比
Servlet API最初是为通过Filter-Servlet链进行单次传递而构建的。异步请求处理允许应用退出Filter-Servlet链，但保留响应以供进一步处理。Spring MVC异步支持是围绕该机制构建的。当控制器返回`DeferredResult`时，将退出Filter-Servlet链，并释放Servlet容器线程。稍后，当`DeferredResult`值被设置时，将进行`ASYNC`分发(到相同的URL)，在此期间再次调用控制器，但不是调用它，而是使用 `DeferredResult`值(就像控制器返回它一样)来恢复处理。相比之下，Spring WebFlux既不是基于Servlet API构建的，也不需要这样的异步请求处理功能，因为它在设计上就是异步的。异步处理内置于所有框架约定中，并且在请求处理的所有阶段都受到内在支持。从编程模型的角度来看，Spring MVC和Spring WebFlux都支持异步和反应类型作为控制器方法的返回值。 Spring MVC甚至支持流式传输，包括反应式背压。但是，对响应的单次写入仍处于阻塞状态(并在单独的线程上执行)，这与WebFlux不同，WebFlux依赖于非阻塞I/O，并且每次写入都不需要额外的线程。另一个根本区别是Spring MVC不支持控制器方法参数中的异步或反应类型(例如`@RequestBody`、`@RequestPart`等），也不明确支持将异步和反应类型作为模型属性。Spring WebFlux支持所有这些。最后，从配置角度来看，必须在Servlet容器级别启用异步请求处理功能。
# HTTP Streaming
你可以使用`DeferredResult`与`Callable`作为单次异步请求返回值，如果你想要产生多个异步生成值并写入到响应中。
## Objects
你可以使用`ResponseBodyEmitter`返回值来生成对象流，每个对象都会使用一个`HttpMessageConverter`序列化并写入到响应中，如下面的例子所示:
```java
@GetMapping("/events")
public ResponseBodyEmitter handle() {
	ResponseBodyEmitter emitter = new ResponseBodyEmitter();
	// Save the emitter somewhere..
	return emitter;
}

// In some other thread
emitter.send("Hello once");

// and again later on
emitter.send("Hello again");

// and done at some point
emitter.complete();
```
也可以在`ResponseEntity`设置`ResponseBodyEmitter`为body，这样你可以定制响应的status与headers。当`emitter`抛出`IOException`异常，比如远程客户端断开连接，应用不会清理连接，此时应用不应该调用`emitter.complete`与`emitter.completeWithError`，相反，Servlet容器会自动实例化一个`AsyncListener`，进行错误通知，其中，Spring MVC会调用`completeWithError`，这个调用会执行最后一次ASYNC派发，在此期间，Spring MVC 会调用配置的异常解析器并完成请求。



















