Spring WebFlux提供了一个用于执行HTTP请求的客户端。WebClient具有函数式、流式的API特点。是基于Reactor开发的。支持声明式的异步组合逻辑，不需要处理线程或者并发相关的问题。它完全是非阻塞的。WebClient底层也需要一个HTTP客户端库。内置支持的客户端库包括:
- [Reactor Netty](https://github.com/reactor/reactor-netty)
- [JDK HttpClient](https://docs.oracle.com/en/java/javase/11/docs/api/java.net.http/java/net/http/HttpClient.html)
- [Jetty Reactive HttpClient](https://github.com/jetty-project/jetty-reactive-httpclient)
- [Apache HttpComponents](https://hc.apache.org/index.html)
- 其他可以通过ClientHttpConnector加载的库
