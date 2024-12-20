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




















