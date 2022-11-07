路由是微服务架构中的必须的组成的部分，比如，/可能映射到web应用，/api/users可能映射到用户服务/api/shop可能映射到shop服务，Zuul是一个基于JVM的路由器与服务端的负载均衡器。Zuul的优势主要有：
- 验证/认证
- 测试相关的
- 路由相关的
Zuul的规则引擎让规则与过滤器可以使用JVM语言编写，内置支持Java与Groovy。
zuul.max.host.connections属性已经分解为zuul.host.maxTotalConnections与zuul.host.maxPerRouteConnections，默认是200与20，zuul.ribbonIsolationStrategyd属性是SEMAPHORE与THREAD。
# how to include Zuul
使用spring-cloud-starter-netflix-zuul
# 内嵌的Zuul反向代理
Spring Cloud已经为微服务的使用场景简化了网关的开发，这是使用内嵌的Zuul反向代理实现的。
为了开启反向代理，在主类上使用@EnableZuulProxy注解，然后，请求会被转发到合适的后端服务，按照约定，/users/**的请求会被转发到users服务（前缀被去掉了），网关使用Ribbon的服务发现机制选择一个服务实例转发，所有的请求都是在Hystrix中执行的，所以失败会出现在Hystrix中的指标中，一旦出现了循环调用，网关。
为了忽略自动新增加的服务，zuul.ignored-services中设置忽略的服务ID模式列表，如果一个服务匹配了模式会被忽略，但是如果显示配置在routes中的服务，不会被忽略，如下：
```yml
 zuul:
  ignoredServices: '*'
  routes:
    users: /myusers/**
```
增加路由规则
```yml
 zuul:
  routes:
    users: /myusers/**
```
上面配置会让/myusers/101 转发到users服务的，为了更细粒度的控制转发规则，可以分开写
```yml
zuul:
  routes:
    users:
      path: /myusers/**
      serviceId: users_service
```
上面的例子意味着/myusers下面的http请求都会被转发到users_service服务，path必须是ant风格的，/myusers/*只会匹配一级路径,/myusers/**会匹配全部的路径。后端的位置可以使用serviceId或者url指定，比如：
```yml
zuul:
  routes:
    users:
      path: /myusers/**
      url: https://example.com/users_service
```
基于url的转发不会被包含在HystrixCommand中，也不会使用到ribbon的负载均衡机制，为了实现这样的目标，你可以给一个serviceId指定静态的服务列表，如下：
```yml
zuul:
  routes:
    echo:
      path: /myusers/**
      serviceId: myusers-service
      stripPrefix: true

hystrix:
  command:
    myusers-service:
      execution:
        isolation:
          thread:
            timeoutInMilliseconds: ...

myusers-service:
  ribbon:
    NIWSServerListClassName: com.netflix.loadbalancer.ConfigurationBasedServerList
    listOfServers: https://example1.com,http://example2.com
    ConnectTimeout: 1000
    ReadTimeout: 3000
    MaxTotalHttpConnections: 500
    MaxConnectionsPerHost: 100
```
还有一个办法就是给serviceId配置一个Ribbon的客户端，这需要禁用ribbon的eureka功能，如下
```yml
zuul:
  routes:
    users:
      path: /myusers/**
      serviceId: users

ribbon:
  eureka:
    enabled: false

users:
  ribbon:
    listOfServers: example.com,google.com
```
你可以使用regexmapper接口提供一个serviceId到路径约定规则，它使用正则表达式中的命名组来从serviceId中解析出值，组成route路径，比如：
```java
@Bean
public PatternServiceRouteMapper serviceRouteMapper() {
    return new PatternServiceRouteMapper(
        "(?<name>^.+)-(?<version>v.+$)",
        "${version}/${name}");
}
```
上面的例子意味着serviceId=myusers-v1的请求会被映射到路径/v1/myusers/**，任何正则表达式都可以，但是只用命名组会出现在servicePattern与routePattern中,如果servicePattern与serviceId不匹配，会使用默认的行为。
为了给所有的映射加前缀，设置属性zuul.prefix=/api，默认情况下，前缀在转发时，都被移除了，可以设置zull.stripPrefix关闭这个行为，也可以关闭自动去除服务级别的前缀的行为，如下：
```yml
 zuul:
  routes:
    users:
      path: /myusers/**
      stripPrefix: false
```
zuul.stripPrefix只会移除zuul.prefix定义的前缀，不会移除path中的前缀。
zuul.routes中的实体实际是ZuulProperties类型的对象，里面有一个retryable的标志，设置为true可以让Ribbon的客户端自动重试失败的请求。默认情况下，X-Forwarded-Host的header会被添加到转发的请求中，想要关闭它，zuul.addProxyHeaders=false,缺省情况下，路径中的prefix会被忽略，但是转发的请求中X-Forwarded-Prefix会带有移除的前缀，如果你设置了一个默认的路由/，@EnableZuulProxy的应用可以作为一个单体服务器，比如设置了zuul.route.home: /，所有的请求都会发送到home服务。
如果需要更细粒度的忽略控制，你可以指定一个需要忽略的模式，这些模式会在路由位置处理的开始时考虑，这意味着此时路径上还有前缀，模式需要考虑前缀的情况，下面的例子是创建模式的例子
```yml
zuul:
  ignoredPatterns: /**/admin/**
  routes:
    users: /myusers/**
```
上面的例子代表/admin/路径不会被解析。
# Zuul Http Client
Zuul使用的HTTP客户端是Apache HTTP客户端，而不是RestClient，为了使用RestClient或者okhttp3，设置
ribbon.restclient.enabled=true,ribbon.okhttp.enabled=true;如果你想要自定义Apache HTTP client或者OK HTTP客户端，提供一个ClosableHttpClient或者OkHttpClient的bean。
# Cookies 与Sensitive Headers
可以在同一个系统中的服务间共享headers，但是你可能不想要敏感的header从下游系统暴漏给外部系统，你可以指定一个被忽略的headers的列表作为路由转发配置的一部分，Cookies就是敏感的headers，如果是浏览器访问网关，下游服务产生的cookies可能会给用户造成困恼，因为它们混杂在一起，看起来是来自于同一个地方。如果您仔细设计您的服务（例如，规定只有一个下游服务设置 cookie），您也许可以让它们从后端一直流到调用者。此外，如果您的代理设置了cookie，并且您的所有后端服务都是同一系统的一部分，那么简单地共享它们是很自然的（例如，使用Spring Session将它们指向到某个共享状态）。除此之外，由下游服务设置的任何cookie可能对调用者没有用，因此建议您（至少）将Set-Cookie和Cookie设置为不属于您的域的路由的敏感首部. 即使对于属于您的域的路由，在让cookie在下游服务和代理之间流动之前，请尝试仔细考虑它的含义。
```yml
zuul:
  routes:
    users:
      path: /myusers/**
      sensitiveHeaders: Cookie,Set-Cookie,Authorization
      url: https://downstream
```
上面是sensitiveHeaders的默认值，你可以不用显式设置它，除非你想要不同的值，sensitiveHeaders是一个黑名单默认还不是空的，因此，为了让Zuul发送除了ignored外的所有的header特别是想要传递cookie/Authorization等首部到后端服务，必须设置这个列表为空，
```yml
 zuul:
  routes:
    users:
      path: /myusers/**
      sensitiveHeaders:
      url: https://downstream
```
你也可以通过属性`zuul.sensitiveHeaders`设置敏感首部，在路由中的sensitiveHeaders配置会覆盖全局的sensitiveHeaders设置。
# ignored Headers
除了路由敏感首部之外，您还可以设置一个名为`zuul.ignoredHeaders`的全局属性，这个属性定义了网关在与下游服务交互期间应丢弃的首部（请求和响应）。默认情况下，如果Spring Security不在类路径中，则这些为空。否则，它们将被初始化为Spring Security指定的一组众所周知的“安全”相关的标头（例如，涉及缓存）。这种情况下的假设是下游服务也可能添加这些标头，但我们想要来自代理的值。 当 Spring Security 在类路径上时，为了不丢弃这些众所周知的安全标头，您可以将 zuul.ignoreSecurityHeaders 设置为 false。 如果您在 Spring Security 中禁用了 HTTP Security 响应标头并希望下游服务提供值，那么这样做会很有用。
# 管理endpints
如果@EnableZuuProxy中有Spring Boot Actuator，则会有2个end pints
- Routes， 返回路由信息，？format=details返回详细的路由信息。如果是POST会刷新路由信息。
- Filters
# 本地转发
