这一章包含Spring如何操作资源以及你如何使用资源，包含下面的主题:
- 简介
- `Resource`接口
- 内置的`Resource`接口实现
- `ResourceLoader`接口
- `ResourcePatternResoler`接口
- `ResourceLoaderAware`接口
- 资源依赖
- Application Contexts与资源路径

# Introduction
Java提供的标准`java.net.URL`类与不同的类型的URL标准处理器不能完全满足访问底层资源的需求。比如，没有一个标准化的URL处理器来访问classpath中的资源或者相对于`ServletContext`的资源。当然你可以微特定的URL前缀注册新的处理器(类似处理http:前缀的现在的处理器)。写这个处理器有点复杂并且可能会缺少某些想要的功能。比如检测资源的存在性。
# `Resource`接口
Spring的`Resource`接口位于`org.springframework.core.io`包下面，是用来表示底层资源访问操作的功能更强大的抽象接口。下面的代码是这个接口的概览，可以参考`Resource`的javadoc获取更多的细节信息。
```java
public interface Resource extends InputStreamSource {
	boolean exists();

	boolean isReadable();

	boolean isOpen();

	boolean isFile();

	URL getURL() throws IOException;

	URI getURI() throws IOException;

	File getFile() throws IOException;

	ReadableByteChannel readableChannel() throws IOException;

	long contentLength() throws IOException;

	long lastModified() throws IOException;

	Resource createRelative(String relativePath) throws IOException;

	String getFilename();

	String getDescription();
}
```
正如`Resource`接口所定义的那样，它继承了`InputStreamSource`接口，下面是这个接口的定义:
```java
public interface InputStreamSource {
	InputStream getInputStream() throws IOException;
}
```
`Resource`接口的几个重要的方法如下:
- `getInputStream()`: 定为与查找资源，返回一个用来读取资源的`InputStream`对象。期望的结果是每次调用都返回一个全新的`InputStream`，调用者负责关闭它
- `exists()`: 返回一个布尔值表示是否物理存在
- `isOpen()`: 返回一个布尔值表示资源是否是一个打开的stream持有的句柄。如果返回true，`InputStream`只能读取一次然后关闭避免内存泄漏。普通的资源实现都是返回false的，除了`InputStreamSource`类型的资源
- `getDescription()`: 返回资源的描述，用来做错误输出。通常是文件的路径名或者资源的实际URL


