Servlet3开始支持异步处理，异步处理是为了解决浏览器接受实时返回数据的问题。典型的使用场景是使用浏览器聊天、实时展示股票信息、状态更新、运动直播或者其他的内容。标准的HTTP是典型的请求-应答语义，但是服务端无法主动向客户端发送消息，解决方式有traditional polling、long polling、HTTP streaming、WebSocket。
## Traditional Polling
浏览器会持续不断的发送请求检查是否有新的返回信息，服务器每次都会立即响应，这适用于数据变化不是特别频繁的场景，比如，邮件客户端可以每隔10分钟检测一下新的消息，这很简单也很有效，然而，当信息的展示需求的实时性比较高，这种方法就会变的低效，因为轮询会比较频繁。
## Long Polling
浏览器持续发送请求，服务端只有在有信息需要发送时才会响应。从客户端视角来看，与传统的轮询是一样的，从服务端视角来看，这有点类似于一个long running请求，并且可以调整long的时间，response保持open的时间是多长？浏览器通常的配置是5分钟，网络中介的超时设置会更短。所以，即使没有新的信息要返回，浏览器也会定期的终止请求以便可以发起新的请求，IETF建议的超时时间是30～120秒。长轮询可以减少请求的发送次数，并且具有低延迟性，尤其是当新的数据的更新的时间间隔不规则时，更加有效，但是如果数据更新的越频繁，就越接近传统的轮询方式。
## HTTP Streaming
浏览器持续不断的发送请求到服务器，当服务器有信息要返回时响应请求。与长轮询不同，服务器会一直保持response的打开状态，当有数据要发送时，就写到response中，这种方式不需要轮询，但是严重背离了传统的HTTP的请求应答语义。客户端与服务端需要协商好如何解释response中的数据流，这样client就可以知道一条数据的开始与结束，但是，网络中介节点可能会缓存response stream，这可能会影响数据，这也是为什么长轮询是今天更常用的方式。
## WebSocket协议
浏览器发送一个HTTP请求到服务器握手，server确认后返回响应，然后切换到WebSocket协议，此时，浏览器与客户端在建立的tcp基础上双向传输数据，WebSocket不需要轮询，使用于客户端与服务之间需要高频的进行消息传递的场景，初始的握手的HTTP可以兼容历史的网络节点的防火墙。WebSocket允许双向传输消息，与HTTP不同，事实上WebSocket之上还有很多子协议，XMPP、AMQP、STOMP等。
WebSocket 协议已经被 IETF 标准化，而 WebSocket API 正处于被 W3C 标准化的最后阶段。 许多 Java 实现已经可用，包括像 Jetty 和 Tomcat 这样的 servlet 容器。 Servlet 3.1 规范可能会支持初始 WebSocket 升级请求，而单独的 JSR-356 将定义基于 Java 的 WebSocket API。回到 Spring MVC 3.2，Servlet 3 异步特性可用于长时间运行的请求，也可用于 HTTP 流，Filip Hanik 将技术称为“客户端 AJAX 调用的服务器版本”。 至于 WebSockets，Spring 3.2 中还没有支持，但它很可能会包含在 Spring 3.3 中。 您可以观看 SPR-9356 以了解进度更新。
