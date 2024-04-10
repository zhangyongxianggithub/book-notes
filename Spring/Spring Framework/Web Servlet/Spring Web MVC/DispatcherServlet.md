# Multipart Resolver
`MultipartResolver`定义在`org.springframework.web.multipart`包下面，用来解析包括我文件上传等的multipart请求的策略。有一个基于容器的`StandardServletMultipartResolver`实现用于Servlet multipart请求解析。请注意，从Spring Framework 6.0(基于新的Servlet 5.0+)开始，基于Apache Commons FileUpload的过时的`CommonsMultipartResolver`不再可用。要启用multipart请求处理，必须在DispatcherServlet的Spring Configuration中声明一个名叫multipartResolver的`MultipartResolver`Bean。DispatcherServlet检测到它就会使用它来处理请求。当接收到一个Content-Type=multipart/form-data的HTTP请求后，resolver解析将`HttpServletRequest`转型成`MultipartHttpServletRequest`，这样可以访问上传的文件并且可以使用请求参数的形式访问field。
## Servlet Multipart Parsing
Servlet multipart解析机制需要通过Spring容器配置开启。2种方式
- 在Servlet注册时设置`MultipartConfigElement`
- 在web.xml文件种，添加`<multipart-config>`到servlet声明中

下面的例子展示了如何开启机制:
```java
public class AppInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {

	// ...

	@Override
	protected void customizeRegistration(ServletRegistration.Dynamic registration) {

		// Optionally also set maxFileSize, maxRequestSize, fileSizeThreshold
		registration.setMultipartConfig(new MultipartConfigElement("/tmp"));
	}

}
```
上面的配置添加好后，然后声明一个名叫multipartResolver的MultipartResolver类型的Bean。这个Resolver变体实现底层实际是使用的Servlet容器的multipart请求解析器。也就是说不同的应用的Servlet容器不同，解析的结果也可能不同。默认情况下，它会解析任何Content-Type以mulipart/开头的任何请求。但是有时候底层的请求解析器可能不一定支持。