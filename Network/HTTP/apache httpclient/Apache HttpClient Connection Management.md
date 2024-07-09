# overview
在这个学习指南中，我们会简单的讲述HttpClient5的基本连接管理的内容。我们将介绍如何使用`BasicHttpClientConnectionManager`和 `PoolingHttpClientConnectionManager`来强制适用安全、符合协议且高效地HTTP连接。
# The BasicHttpClientConnectionManager for a Low-Level, Single-Threaded Connection
`BasicHttpClientConnectionManager`自HttpClient 4.3.3起可用，作为HTTP连接管理器的最简单实现。我们使用它来创建和管理单个连接，一次只能有一个线程使用。
```java
BasicHttpClientConnectionManager connMgr = new BasicHttpClientConnectionManager();	
HttpRoute route = new HttpRoute(new HttpHost("www.baeldung.com", 443));	
final LeaseRequest connRequest = connMgr.lease("some-id", route, null);	
```
对于特定的要连接到的route，lease方法从连接池管理器中获取这个route的连接。路由参数指定到目标主机或目标主机本身的"代理跳"路由。可以直接使用`HttpClientConnection`运行请求。但是，请记住，这种低级方法非常冗长且难以管理。low-level连接对于访问套接字和连接数据（例如超时和目标主机信息）非常有用。但对于标准执行，HttpClient是一个更容易使用的API。对于4.5版本的相关 Javadoc，请检查此链接和结论部分中的 github 链接。
# Using the PoolingHttpClientConnectionManager to Get and Manage a Pool of Multithreaded Connections
`ClientConnectionPoolManager`维护一个`ManagedHttpClientConnections`对象池，并且能够为来自多个执行线程的连接请求提供服务。 管理器可以打开的并发连接池连接的默认大小是每个路由或目标主机5个，打开连接总数为25个。首先，让我们看一下如何在简单的HttpClient上设置此连接管理器:
```java
PoolingHttpClientConnectionManager poolingConnManager = new PoolingHttpClientConnectionManager();	
CloseableHttpClient client = HttpClients.custom()	
    .setConnectionManager(poolingConnManager)	
    .build();	
client.execute(new HttpGet("https://www.baeldung.com"));	
assertTrue(poolingConnManager.getTotalStats().getLeased() == 1);
```
接下来，我们会看到2个不同线程的2个HttpClients可以使用同一个连接管理器。
下面的例子是使用2个HttpClients来连接同一个目标Host:
```java
HttpGet get1 = new HttpGet("https://www.baeldung.com");	
HttpGet get2 = new HttpGet("https://www.google.com");	
PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();	
CloseableHttpClient client1 = HttpClients.custom()	
    .setConnectionManager(connManager)	
    .build();	
CloseableHttpClient client2 = HttpClients.custom()	
    .setConnectionManager(connManager)	
    .build();
MultiHttpClientConnThread thread1 = new MultiHttpClientConnThread(client1, get1);
MultiHttpClientConnThread thread2 = new MultiHttpClientConnThread(client2, get2); 
thread1.start(); 
thread2.start(); 
thread1.join(); 
thread2.join();
```
自定义的线程执行GET请求:
```java
public class MultiHttpClientConnThread extends Thread {	
    private CloseableHttpClient client;	
    private HttpGet get;	
    	
    // standard constructors	
    public void run(){	
        try {	
            HttpEntity entity = client.execute(get).getEntity();  	
            EntityUtils.consume(entity);	
        } catch (ClientProtocolException ex) {    	
        } catch (IOException ex) {	
        }	
    }	
}
```
注意`EntityUtils.consume(entity)`这个方法调用。这是消费响应的内容并会把连接返回给连接池。
# Configure the Connection Manager
池连接管理器的默认值经过精心选择。但是，根据我们的使用场景，它们可能太小。那么，让我们看看如何配置:
- 连接总数, total number of connections
- 每条（任何）路由的最大连接数， maximum number of connectionss per route
- 每条特定路由的最大连接数，the maximum number of connections per a single,specific route

```java
PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();
connManager.setMaxTotal(5);
connManager.setDefaultMaxPerRoute(4);
HttpHost host = new HttpHost("www.baeldung.com", 80);
connManager.setMaxPerRoute(new HttpRoute(host), 5);
```
让我们简要说明下API:
- setMaxTotal(int max): 设置总共可以打开连接的最大数量;
- setDefaultMaxPerRoute(int max): 每个route并发连接最大个数，默认是2个
- setMaxPerRoute(int max): Set the total number of concurrent connections to a specific route, which is two by default

因此，在不更改默认值的情况下，我们将很容易达到连接管理器的限制。让我们看看它是什么样子的:
```java
HttpGet get = new HttpGet("http://www.baeldung.com");	
PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();	
CloseableHttpClient client = HttpClients.custom()	
    .setConnectionManager(connManager)	
    .build();	
MultiHttpClientConnThread thread1 = new MultiHttpClientConnThread(client, get, connManager);	
MultiHttpClientConnThread thread2 = new MultiHttpClientConnThread(client, get, connManager);	
MultiHttpClientConnThread thread3 = new MultiHttpClientConnThread(client, get, connManager);	
MultiHttpClientConnThread thread4 = new MultiHttpClientConnThread(client, get, connManager);	
MultiHttpClientConnThread thread5 = new MultiHttpClientConnThread(client, get, connManager);	
MultiHttpClientConnThread thread6 = new MultiHttpClientConnThread(client, get, connManager);	
thread1.start();	
thread2.start();	
thread3.start();	
thread4.start();	
thread5.start();	
thread6.start();	
thread1.join();	
thread2.join();	
thread3.join();	
thread4.join();	
thread5.join();	
thread6.join();
```
请记住，默认情况下每个主机的连接限制为5个。因此，在此示例中，我们希望六个线程向同一主机发出六个请求，但只会并行分配三个连接。
# Connection Keep-Alive Strategy
根据HttpClient 5.2："如果响应中不存在Keep-Alive标头，则HttpClient假定连接可以保持活动状态3分钟"。为了解决这个问题并能够管理死连接，我们需要一个定制的策略实现并将其构建到HttpClient中。
```java
final ConnectionKeepAliveStrategy myStrategy = new ConnectionKeepAliveStrategy() {	
    @Override	
    public TimeValue getKeepAliveDuration(HttpResponse response, HttpContext context) {	
        Args.notNull(response, "HTTP response");	
        final Iterator<HeaderElement> it = MessageSupport.iterate(response, HeaderElements.KEEP_ALIVE);	
        final HeaderElement he = it.next();	
        final String param = he.getName();	
        final String value = he.getValue();	
        if (value != null && param.equalsIgnoreCase("timeout")) {	
            try {	
                return TimeValue.ofSeconds(Long.parseLong(value));	
            } catch (final NumberFormatException ignore) {	
            }	
        }	
        return TimeValue.ofSeconds(5);	
    }	
};
```
该策略将首先尝试应用标头中声明的主机的Keep-Alive策略。如果响应标头中不存在该信息，它将保持活动连接五秒钟。现在让我们使用此自定义策略创建一个客户端:
```java
PoolingHttpClientConnectionManager connManager 
  = new PoolingHttpClientConnectionManager();
CloseableHttpClient client = HttpClients.custom()
  .setKeepAliveStrategy(myStrategy)
  .setConnectionManager(connManager)
  .build();
```
# Connection Persistence/Reuse
HTTP/1.1规范规定，如果连接尚未关闭，我们可以复用连接。这称为连接持久性。一旦管理器释放连接，它就会保持打开状态以供重用。当使用只能管理单个连接的`BasicHttpClientConnectionManager`时，必须先释放该连接，然后才能再次租回:
```java
BasicHttpClientConnectionManager connMgr = new BasicHttpClientConnectionManager();	
HttpRoute route = new HttpRoute(new HttpHost("www.baeldung.com", 443));	
final HttpContext context = new BasicHttpContext();	
final LeaseRequest connRequest = connMgr.lease("some-id", route, null);	
final ConnectionEndpoint endpoint = connRequest.get(Timeout.ZERO_MILLISECONDS);	
connMgr.connect(endpoint, Timeout.ZERO_MILLISECONDS, context);	
connMgr.release(endpoint, null, TimeValue.ZERO_MILLISECONDS);	
CloseableHttpClient client = HttpClients.custom()	
    .setConnectionManager(connMgr)	
    .build();	
HttpGet httpGet = new HttpGet("https://www.example.com");	
client.execute(httpGet, context, response -> response);
```
让我们看看会发生什么。请注意，我们首先使用低级连接，这样我们就可以完全控制何时释放连接，然后使用HttpClient进行正常的高级连接。复杂的低级逻辑在这里不是很相关。我们唯一关心的是releaseConnection调用。这会释放唯一可用的连接并允许重用它。然后客户端再次运行GET请求，成功。如果我们跳过释放连接，我们将从HttpClient得到一个IllegalStateException:
>java.lang.IllegalStateException: Connection is still allocated
  at o.a.h.u.Asserts.check(Asserts.java:34)
  at o.a.h.i.c.BasicHttpClientConnectionManager.getConnection
    (BasicHttpClientConnectionManager.java:248)

请注意，现有连接并未关闭，只是被释放，然后由第二个请求重用。与上面的示例相反，`PoolingHttpClientConnectionManager`允许透明地重用连接，而无需隐式释放连接：
```java
HttpGet get = new HttpGet("http://www.baeldung.com");	
PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();	
connManager.setDefaultMaxPerRoute(6);	
connManager.setMaxTotal(6);	

CloseableHttpClient client = HttpClients.custom()	
    .setConnectionManager(connManager)	
    .build();	

MultiHttpClientConnThread[] threads = new MultiHttpClientConnThread[10];	
for (int i = 0; i < threads.length; i++) {	
    threads[i] = new MultiHttpClientConnThread(client, get, connManager);	
}	
for (MultiHttpClientConnThread thread : threads) {	
    thread.start();	
}	
for (MultiHttpClientConnThread thread : threads) {	
    thread.join(1000);	
}
```
上面的示例有10个线程运行10个请求，但仅共享6个连接。当然，这个例子依赖于服务器的Keep-Alive超时。为了确保连接在重用之前不会消失，我们应该使用Keep-Alive策略配置客户端（参见示例5.1）。对于4.5版本的相关Javadoc，请检查此链接和结论部分中的github链接。
# Configuring Timeouts – Socket Timeout Using the Connection Manager
配置连接管理器时我们可以设置的唯一超时是套接字超时:
```java
final HttpRoute route = new HttpRoute(new HttpHost("www.baeldung.com", 80));	
final HttpContext context = new BasicHttpContext();	
final PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();	
final ConnectionConfig connConfig = ConnectionConfig.custom()	
    .setSocketTimeout(5, TimeUnit.SECONDS)	
    .build();	
connManager.setDefaultConnectionConfig(connConfig);	
final LeaseRequest leaseRequest = connManager.lease("id1", route, null);	
final ConnectionEndpoint endpoint = leaseRequest.get(Timeout.ZERO_MILLISECONDS);	
connManager.connect(endpoint, null, context);	
connManager.close();
```
关于timeout的更多的讨论, [参考这里](https://www.baeldung.com/httpclient-timeout).
# Connection Eviction
我们使用连接eviction来检测空闲和过期的连接并关闭它们。 我们有两种可选项来做到这一点：
1. HttpClient提供`evictExpiredConnections()`，使用后台线程主动从连接池中逐出过期连接。
2. HttpClient提供了`evictIdleConnections(final TimeValue maxIdleTime)`，它使用后台线程主动从连接池中逐出空闲连接。
```java
final PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();	
connManager.setMaxTotal(100);	
try (final CloseableHttpClient httpclient = HttpClients.custom()	
    .setConnectionManager(connManager)	
    .evictExpiredConnections()	
    .evictIdleConnections(TimeValue.ofSeconds(2))	
    .build()) {	
    // create an array of URIs to perform GETs on	
    final String[] urisToGet = { "http://hc.apache.org/", "http://hc.apache.org/httpcomponents-core-ga/"};	
    for (final String requestURI : urisToGet) {	
        final HttpGet request = new HttpGet(requestURI);	
        System.out.println("Executing request " + request.getMethod() + " " + request.getRequestUri());	
        httpclient.execute(request, response -> {	
            System.out.println("----------------------------------------");	
            System.out.println(request + "->" + new StatusLine(response));	
            EntityUtils.consume(response.getEntity());	
            return null;	
        });	
    }	
    final PoolStats stats1 = connManager.getTotalStats();	
    System.out.println("Connections kept alive: " + stats1.getAvailable());	
    // Sleep 4 sec and let the connection evict or do its job	
    Thread.sleep(4000);	
    final PoolStats stats2 = connManager.getTotalStats();	
    System.out.println("Connections kept alive: " + stats2.getAvailable());
}
```
# Connection Closing
我们可以优雅地关闭连接（在关闭之前尝试刷新输出缓冲区），也可以通过调用shutdown方法强制关闭连接（不刷新输出缓冲区）。要正确关闭连接，我们需要执行以下所有操作：
- 消费并关闭响应（如果可关闭）
- 关闭客户端
- 关闭并关闭连接管理器

```java
PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();	
CloseableHttpClient client = HttpClients.custom()	
    .setConnectionManager(connManager)	
    .build();	
final HttpGet get = new HttpGet("http://google.com");	
CloseableHttpResponse response = client.execute(get);	
EntityUtils.consume(response.getEntity());	
response.close();	
client.close();	
connManager.close();
```
如果我们在没有关闭连接的情况下关闭管理器，则所有连接将被关闭并释放所有资源。重要的是要记住，这不会刷新现有连接可能正在进行的任何数据。
# Conclusion
在这篇文章中，我们讨论了如何使用HttpClient的HTTP连接管理API来处理管理连接的整个过程。这包括打开和分配它们、管理并发使用以及最后关闭它们。我们了解了`BasicHttpClientConnectionManager`如何成为处理单个连接的简单解决方案，以及它如何管理低级连接。我们还了解了 `PoolingHttpClientConnectionManager`如何与HttpClient API相结合，以高效且符合协议的方式使用HTTP连接。
