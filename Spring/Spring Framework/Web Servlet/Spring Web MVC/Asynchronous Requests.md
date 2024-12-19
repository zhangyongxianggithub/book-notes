Spring MVC支持Servlet异步请求处理。
- 在Conrtoller方法中的`DeferredResult`与`Callable`返回值类型提供了异步结果的功能
- 控制器可以讲多个返回值变成流，包括SSE机制或者原始二进制数据机制
- 控制器可以使用反应式客户端，返回反应式类型用于响应处理

与Spring WebFlux的区别，请参考[Async Spring MVC compared to WebFlux](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-async.html#mvc-ann-async-vs-webflux)。
# DeferredResult
如果Servlet容器开启了异步请求完成处理功能，控制器方法可以将所有支持的返回值wrap到`DeferredResult`中，如下所示:
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
