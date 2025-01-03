[TOC]
Cloud Native(云原生)是一种应用程序开发风格，它鼓励在应用的持续交付与价值驱动方面采用简单的最佳实践。需要做的就是构建12-因素应用程序，具有2-因素的应用程序开发过程中始终与交付目标保持一致。比如，通过使用声明式编程、管理、监控的方式开发。Spring Cloud通过很多手段增强了这种开发风格；一个分布式系统中的所有组件的入门都必须是简单易用的。这些特性大部分都是Spring Boot实现的，这是Spring Cloud的基石。一些分布式相关的特性由Spring Cloud发布为2个lib：Spring Cloud Context与Spring Cloud Commons。Spring Cloud Context提供了一些实用工具以及与Spring Cloud应用的ApplicationContext（bootstrap context，encryption、refresh scope、environment endpoints）相关的一些特殊服务；Spring Cloud Commons包含了很多的抽象类定义，这些定义通常是Spring Cloud所有组件（比如Spring Cloud Netflix，Spring Cloud Consul）都会用到并且实现的类。
如果你正在使用Sun’s JDK并且出现了一个由“Illegal key size”造成的异常，你需要安装Java Cryptography Extension（JCE）Unlimited Strength Jurisdiction Policy Files. 将文件解压到/JDK/jre/lib/security目录下。Spring Cloud 在非限制性 Apache 2.0 许可下发布。 如果您想对文档的这一部分做出贡献或发现错误，您可以在 {docslink}[github] 上找到该项目的源代码和问题跟踪器。
# Spring Cloud Context: Application Context Services
Spring Boot 对如何使用 Spring 构建应用程序有自己的看法。 例如，它由自己常规的公共配置文件的位置，也具有自己的用于管理与监控任务的端点（end point）。 Spring Cloud 建立在此之上，并添加了分布式系统中许多组件会使用或偶尔需要的一些特性。
## the Bootstrap Application Context
Spring Cloud应用通过创建一个bootstrap上下文开始运行，它是main上下文的父上下文；这个上下文负责加载外部来源的配置属性与对本地外部配置文件中的属性解码。bootstrap上下文与main上下文共享同一个Environment，Environment对任意的Spring应用来说都是默认的外部属性的来源，默认情况下，bootstrap属性（不是指的bootstrap.properties属性，是在bootstrap阶段加载的所有属性）具有更高的加载优先级，所以他们不能被本地配置属性覆盖。bootstrap上下文使用一个特殊的约定方式来定位外部配置属性源地址，与main上下文加载外部配置属性源的方式是不同的。bootstrap上下文不使用典型的application.yml，而是bootstrap.yml，这让用于boostrap与main上下文的外部配置区分开，下面的列表是一个例子
```yml
spring:
  application:
    name: foo
  cloud:
    config:
      uri: ${SPRING_CONFIG_URI:http://localhost:8888}
```
如果你的应用需要加载来自于远程服务器的应用外部配置，你需要在bootstrap.yml或者applicaiton.yml中设置spring.application.name属性，当spring.application.name属性被用来做应用上下文的ID时，你必须在bootstrap.yml中设置它。如果你想加载应用的特定的profile的配置，你可能还需要在你boostrap.yml中设置spring.profiles.active属性。你可以通过设置spring.cloud.bootstrap.enabled=false（比如系统属性）完全关闭boostrap处理过程。
## Application Context体系结构
如果你使用SpringApplication 或者 SpringApplicationBuilder 构建应用程序上下文，则bootstrap 上下文会以parent的身份被添加到当前应用的上下文中。 Spring的一个特性是子上下文会继承父上下文的属性源与profiles，因此应用上下文与相比于没有使用Spring Cloud Config创建的上下文相比，会包含一些额外的属性源（继承的），这些额外的属性源有：
- bootstrap，如果boostrap上下文中发现了任意的PropertySourceLocators对象并且对象所表示的属性源的属性不是空的，那么一个CompositePropertySource对象会以较高的优先级出现在当前应用上下文中，常见的情况下是来自于远程Spring Cloud Config Server的属性，可以参考[Customizing the Bootstrap Property Sources](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/index.html#customizing-bootstrap-property-sources)章节来自定义这种属性源的内容。
- applicationConfig:[classpath:bootstrap.yml] 或者与任何激活的profile相关的文件，如果你有一个bootstrap.yml或者.properties文件，文件里面的属性会被用来配置bootstrap上下文，然后以parent的身份被添加到子上下文环境中，他们比application.yml的优先级低，也比其他被添加到子上下文的属性源属性的优先级低；可以参考[Changing the Location of Bootstrap Properties](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/#customizing-bootstrap-properties)来自定义这些属性源的内容。
因为属性源的排序规则的原因，含有bootstrap单词相关的属性体具有更高的优先级，然而，这并不包括任何来自于bootstrap.yml中的任何的数据，它们的优先级更低，可以被用来设置默认值。你可以扩展上下文的层次结构，只需要对你创建的ApplicationContext设置parent上下文，比如，通过使用ApplicationContext接口的方法或者使用SpringApplicationBuilder的方便的方法（parent()、child()、sibling()）。bootstrap上下文是大部分的上下文的parent。体系结构中的每个上下文都有他自己的bootstrap属性源to avoid promoting values inadvertently from parents down to their descendants。如果有一个配置服务器，体系结构中的上下文都可以有不同的spring.application.name，因而可以有不同的远程属性源。普通的Spring Application上下文属性解析规则如下：从子上下文中的属性会覆盖父上下文中出现的属性。
## 1.3 改变Bootstrap属性的位置
Bootstrap.yml文件的名字可以通过spring.cloud.bootstrap.name属性（默认是bootstrap）、spring.cloud.bootstrap.location(默认是空的)、spring.cloud.bootstrap.addidional-location(默认是空的)指定。这些属性的的行为类似于同名的spring.config.*属性，`spring.cloud.bootstrap.location`的默认的位置被替换后，将使用替换后的位置，想要添加缺省加载的位置，使用spring.cloud.bootstrap.additional-location属性，事实上，通过将这些属性设置到Environment中，来构建初始的bootstrap ApplicationContext上下文，如果存在active profile（来自spring.profiles.active或者来自Environment），profile相对应的配置文件里面的属性也会加载，就像一个普通的Spring Boot app那样，比如，从bootstrap-development.properties文件中加载。
## 覆盖远程配置源中的属性值
通过bootstrap上下文添加到应用中的属性源通常是远程的（比如，来自于Spring Cloud Config Server），缺省情况下，他们不能被本地的属性覆盖，如果你想要应用可以覆盖远程属性，远程属性服务必须开启属性`spring.cloud.config.allowOverride=true`来获得授权（在本地设置是没用的），一旦设置了这个标志，2个细粒度的设置可以控制远程属性源于系统属性于应用本地配置属性的覆盖关系
- `spring.cloud.config.overrideNone=true`覆盖所有的本地属性源
- `spring.cloud.config.overrideSystemProperties=false`只有系统属性、命令行参数和环境变量（而不是本地配置文件）应该覆盖远程设置。
## 1.5 自定义Bootstrap配置
可以设置boostrap上下文环境做任何你想要做的事，只需要添加key-value到`/META-INF/spring.factories`文件中，实体的key的名字是`org.springframework.cloud.bootstrap.BootstrapConfiguration`，valu是一些逗号分隔的类，这些类都是Spring的@Configuration注解的类，任何你想要在main application context阶段使用的bean都可以在这里创建。对ApplicationContextInitializer类型的bean会有特殊的处理，如果你想要控制启动顺序，你可以使用@Order注解类，默认的order值是last。当你添加自定义的BootstrapConfiguration，需要注意你添加的类，不会被错误的组件扫描到你的main application context中，最好的办法是使用另外的包存放boot configuration类，并且这些包不在被@ComponentScan与@SpringBootApplication注解所在类的包下面。
引导过程最后会把初始化器注入到main方方法所在的SpringApplication对象中，不断程序是单独启动还是部署到服务器中都是这么启动的，首先，根据spring.factories文件中的类来创建bootstrap上下文，然后，所有ApplicationContextInitializer类型的bean在启动前添加到main所在的SpringApplication对象中。
## 1.6 定制化Bootstrap属性源
Boostrap过程默认添加的外部配置的属性源是Spring Cloud Config Server。但是你也可以添加额外的属性源，只需要在bootstrap context中添加PropertySourceLocator类型的bean（通过sspring.factories）就可以了，比如，你可以添加从其他的服务器或者从一个数据库中来的额外的属性。
比如，你可以下面自定义的定位器
```java
@Configuration
public class CustomPropertySourceLocator implements PropertySourceLocator {

    @Override
    public PropertySource<?> locate(Environment environment) {
        return new MapPropertySource("customProperty",
                Collections.<String, Object>singletonMap("property.from.sample.custom.source", "worked as intended"));
    }
}
```
参数Environment就是即将创建的ApplicationContext要使用的环境，换句话说，也是我们要提供额外属性源的环境，它早已经有了有关Spring Boot提供的相关的属性源，所以你可以那些属性源来定位一个当前魂惊使用的属性源，比如，通过spring.application.name属性。如果您在其中创建一个包含此类的 jar，然后添加包含以下设置的 META-INF/spring.factories，则 customProperty PropertySource 将出现在其类路径中包含该 jar 的任何应用程序中：
>org.springframework.cloud.bootstrap.BootstrapConfiguration=sample.custom.CustomPropertySourceLocator

## 1.7 Logging Configuration
如果你要配置日志设置，你可以把日志相关的配置放到bootstrap[.yml|.properties]文件中。
## 1.8 Environment Changes
应用监听一个EnvironmentChangeEvent类型的事件，有几种操作可以响应这种变更（最普遍的方法就是添加ApplicationListeners类型的bean），当观察到一个EnvironmentChangeEvent事件时，通常是有属性发生了变更，应用使用这些变更的属性做一下的事情：
- 重新绑定上下文中的@ConfigurationProperties注解的bean的属性内容;
- 设置logging.level.*中的属性的日志级别。
需要注意，Spring Cloud Config Client缺省情况下，不会自动探查Environment中的属性变更，通常来说，我们不建议你去检测任何属性的变更（比如通过@Scheduled的方式），如果你有一个需要横向扩展的客户端应用，最好的办法就是广播EnvironmentChangeEvent事件到所有的实例中，而不是让它们去探询变更（比如，可以使用Spring Cloud Bus）。
EnvironmentChangeEvent可以适用于非常多的刷新场景，只要您可以实际更改Environment中扽诶容并并发布事件即可，需要注意的是，这些API是public的，是核心 Spring 的一部分。你可以通过访问/configprops验证@ConfigurationProperties注解bean是否产生了变更（这是标准的spring Boot Actuator提供的功能）。例如，DataSource类型的对象可以在运行时更改其 maxPoolSize（Spring Boot 创建的默认 DataSource 是 @ConfigurationProperties bean）并动态增加容量。 重新绑定@ConfigurationProperties注解bean只是其中一个使用场景，在其他的使用场景中，你需要对刷新进行更多控制，并且需要对整个 ApplicationContext 进行原子更改。 为了解决这些问题，可以使用@RefreshScope。
## 1.9 Refresh Scope
当存在配置发生变更时，被@RefreshScope标记的bean会被特殊的处理，这解决了有状态的bean的配置发生需要发生变更并跟随变更的问题，因为大部署的bean只会在初始化时才会注入配置相关的内容。比如，当一个DataSource已经打开了一个连接，此时，Environment中的database的url发生了变更，你可能想要终止所有的连接并且下一次从pool中取出新的连接时，你可能想要连接使用新的URL。有时候，一些只会初始化一次的bean可能需要强制应用@RefreshScope，如果一个bean是不可变更的，你必须使用注解@RefreshScope或者在属性`spring.cloud.refresh.extra-refreshable`中指定classname。如果你有一个DataSource，它是HikariDataSource类型的，它是不能被刷新的，它是属性`spring.cloud.refresh.never-refreshable`的默认值，如果你需要datasource可以被刷新，选择一个其他类型的DataSource实现。
@RefreshScope注解的bean会使用一种呢懒惰代理机制，也就是只有真正的方法调用发生时，才会根据初始的属性值的缓存生成被代理的对象，为了在下一次方法调用时，重新初始化对象，你需要将属性缓存配置为过期。这时会从Environment中重新加载。
整个Spring Cloud应用的上下文中会存在一个RefreshScope类型的bean，它由一个公共的refreshAll()方法，这个方法会通过清空目标对象的cache的方法刷新范围内的所有的bean。/refresh端点暴漏了这种功能(通过HTTP或者JMX)，为了通过bean的名字来刷新一个单独的bean，也可以使用refresh(String)方法。为了暴漏/refresh端点，你需要添加如下的配置到你的应用中
```yaml
management:
  endpoints:
    web:
      exposure:
        include: refresh
```
从技术上来说，@RefreshScope工作在@Configuration类上，这可能导致一些未知的行为，比如，@Configuration注解类中定义的@Bean本身是不在@RefreshScope作用范围内，比较特别的是，任何依赖这些bean的bean不能只依赖它们被初始化时的对象，除非它本身在@RefreshScope中，具体来说，任何依赖于这些 bean 的东西都不能依赖它们在启动刷新时被更新，除非它本身在 @RefreshScope 中。 在这种情况下，它会在刷新时重建，并重新注入其依赖项。 此时，它们会从刷新的@Configuration 重新初始化）。
## 1.10 encryption与decryption
Spring Cloud 有一个 Environment 预处理器，用于在本地解密属性值。Spring Cloud 有一个 Environment 预处理器，用于在本地解密属性值。 它遵循与 Spring Cloud Config Server 相同的规则，并具有相同的外部配置encrypt.*。因此，您可以使用 {cipher}* 形式的加密值，并且只要存在有效密钥，它们就会在主应用程序上下文获取环境设置之前被解密。要在应用程序中使用加密功能，您需要在类路径中包含 Spring Security RSA。maven坐标org.springframework.security:spring-security-rsa，并且您还需要 JVM 中的全强度 JCE 扩展 。如果由于“非法密钥大小”而出现异常并且使用 Sun 的 JDK，则需要安装 Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files。 有关更多信息，请参阅以下链接：将文件解压缩到您使用的 JRE/JDK x64/x86 版本的 JDK/jre/lib/security 文件夹中。
## 1.11 endpoints
对于Spring Boot Actuator应用来说，可以使用一些额外添加的用于管理的端点(endpoints)，你可以用的如下:
- POST /actuator/env，可以用来更新Environment，重新绑定@ConfigurationProperties对象与log levels，为了开启这个端点功能，你必须设置management.endpoint.env.post.enabled=true；
- /actuator/rfefresh 用来重载bootstrap上下文，刷新@RefreshScope注解的bean;
- /actuator/restart 关闭ApplicationContext并重新启动它(默认是关闭的)
- /actuator/pause 与/actuator/resume，用来调用ApplicationContext的生命周期回调方法，（stop()与start()）。
如果你禁用 /actuator/restart 端点，那么 /actuator/pause 和 /actuator/resume 端点也将被禁用，因为它们只是 /actuator/restart 的一个特例。
# Spring Cloud Commons: 通用抽象
服务发现、负载平衡和断路器等模式适用于一个公共抽象层，所有 Spring Cloud 客户端都可以使用该抽象层，独立于实现（例如，使用 Eureka 或 Consul 进行发现）。
## @EnableDiscoveryClient注解
Spring Cloud Commons 提供了 @EnableDiscoveryClient 注解。 这会寻找带有 META-INF/spring.factories 的 DiscoveryClient 和 ReactiveDiscoveryClient 接口的实现。 发现客户端的实现在 org.springframework.cloud.client.discovery.EnableDiscoveryClient 键下的 spring.factories 中添加了一个配置类。 DiscoveryClient 实现的示例包括 Spring Cloud Netflix Eureka、Spring Cloud Consul Discovery 和 Spring Cloud Zookeeper Discovery。
Spring Cloud默认回提供阻塞与响应式的服务发现客户端，你可以通过设置
```properties
spring.cloud.discovery.blocking.enabled=false
spring.cloud.discovery.reactive.enabled=false
```
关闭客户端功能，想要完全的关闭服务发现功能，可以直接设置`spring.cloud.discovery.enabled=false`。
默认情况下，DiscoveryClient接口的实现回自动当前的Spring Boot服务到远程的服务注册中心，可以通过@EnableDiscoveryClient中的autoRegister=false来关闭这个行为。@EnableDiscoveryClient不在需要了，你可以直接把一个DiscoveryClient接口的实现放到classpath下面，spring boot应用会自动扫描并注册服务到服务注册中心。
### 健康指标
Spring Cloud Commons 自动配置了下面的Spring Boot健康指标
1. DiscoveryClientHealthIndicator
这个健康指示器基于当前注册的DiscoveryClient实现
- 想要完全禁止这个指示器，设置`spring.cloud.discovery.client.health-indicator.enabled=false`
- 要禁用描述字段，请设置 spring.cloud.discovery.client.health-indicator.include-description=false;
- 要禁用服务检索，请设置`spring.cloud.discovery.client.health-indicator.use-services-query=false`。 默认情况下，指示器调用客户端的`getServices`方法。 在具有许多注册服务的部署中，每次检查都检索所有服务的成本可能太高。 设置这个属性将会跳过服务检索，而是使用客户端的`probe`方法;

2. DiscoveryCompositeHealthContributor
此复合健康指标基于所有已注册的 DiscoveryHealthIndicator bean。 要禁用，请设置 spring.cloud.discovery.client.composite-indicator.enabled=false
### DiscoveryClient实例排序
DiscoveryClient 接口扩展了 Ordered接口。 这在使用多个发现客户端时很有用，因为它允许您定义返回的发现客户端的顺序，类似于Spring 应用程序加载的 bean 加载排序。 默认情况下，任何 DiscoveryClient 的 order 设置为 0。如果您想为自定义 DiscoveryClient 实现设置不同的 order，只需覆盖 getOrder() 方法，以便它返回适合您设置的值。 除此之外，您可以使用属性来设置 Spring Cloud 提供的 DiscoveryClient 实现的顺序，其中包括 ConsulDiscoveryClient、EurekaDiscoveryClient 和 ZookeeperDiscoveryClient。 为此，您只需将 spring.cloud.{clientIdentifier}.discovery.order （或 Eureka 的 eureka.client.order ）属性设置为所需的值。
如果类路径中没有 Service-Registry 支持的 DiscoveryClient，则将使用 SimpleDiscoveryClient 实例，该实例使用属性来获取有关服务和实例的信息。
### SimpleDiscoveryClient
有关可用实例的信息应通过以下格式的属性传递：spring.cloud.discovery.client.simple.instances.service1[0].uri=http://s11:8080，其中 spring.cloud.discovery .client.simple.instances 是公共前缀，那么 service1 代表该服务的 ID，而 [0] 表示实例的索引号（如示例中可见，索引以 0 开头），然后 uri 的值是实例可用的实际 URI。
## ServiceRegistry
Spring Cloud Commons提供了ServiceRegistry接口，这个接口提供了`register(Registration)`与`deregister(Registration)`2个方法，这可以让你实现自定义的服务注册逻辑，Registration是一个标记接口，下面是一个使用ServiceRegistry接口的例子
```java
@Configuration
@EnableDiscoveryClient(autoRegister=false)
public class MyConfiguration {
    private ServiceRegistry registry;

    public MyConfiguration(ServiceRegistry registry) {
        this.registry = registry;
    }

    // called through some external process, such as an event or a custom actuator endpoint
    public void register() {
        Registration registration = constructRegistration();
        this.registry.register(registration);
    }
}

```
每个ServiceRegistry实现都有它自己的Registry实现
- ZookeeperServiceRegistry使用ZookeeperRegistration;
- EurekaServiceRegistry使用EurekaRegistration;;
- ConsulServiceRegistry使用ConsulRegistration;

如果你正在使用ServiceRegistry接口，你需要传递正确的Registry实现。
### ServiceRegistry自动注册
缺省情况下，ServiceRegistry实现会自动注册运行的服务，要禁用该行为，您可以设置： * @EnableDiscoveryClient(autoRegister=false) 永久禁用自动注册。 * spring.cloud.service-registry.auto-registration.enabled=false 通过配置禁用行为。服务自动注册时将触发两个事件。 第一个事件称为 InstancePreRegisteredEvent，在服务注册之前触发。 第二个事件称为 InstanceRegisteredEvent，在服务注册后触发。 您可以注册一个 ApplicationListener(s) 来监听这些事件并做出反应。
### Service Registry Actuator Endpoint
Spring Cloud Commons 提供了一个 /service-registry actuator端点。 这个端点的信息依赖于 Spring Application Context 中的 Registration bean中的状态信息。 使用 GET方式 调用 /service-registry 会返回注册状态。 使用带有 JSON 正文的同一端点的 POST 会将当前注册的状态更改为新值。 JSON 正文必须包含具有首选值的状态字段。 请参阅您在更新状态时使用的 ServiceRegistry 实现的文档以及为状态返回的值。 例如，Eureka 支持的状态是 UP、DOWN、OUT_OF_SERVICE 和 UNKNOWN。
## Spring RestTemplate as a Load Balancer Client
您可以将 RestTemplate 配置为使用负载均衡器客户端。 要创建负载平衡的 RestTemplate，请创建一个 RestTemplate @Bean 并使用 @LoadBalanced 限定符，如以下示例所示：
```java
@Configuration
public class MyConfiguration {

    @LoadBalanced
    @Bean
    RestTemplate restTemplate() {
        return new RestTemplate();
    }
}

public class MyClass {
    @Autowired
    private RestTemplate restTemplate;

    public String doOtherStuff() {
        String results = restTemplate.getForObject("http://stores/stores", String.class);
        return results;
    }
}
```
## Spring WebClient as a Load Balancer Client
你也可以将WebClient配置自动复杂均衡的客户端，为了创建一个具有复杂均衡特性的WebClient，使用下面的代码:
```java
@Configuration
public class MyConfiguration {

    @Bean
    @LoadBalanced
    public WebClient.Builder loadBalancedWebClientBuilder() {
        return WebClient.builder();
    }
}

public class MyClass {
    @Autowired
    private WebClient.Builder webClientBuilder;

    public Mono<String> doOtherStuff() {
        return webClientBuilder.build().get().uri("http://stores/stores")
                        .retrieve().bodyToMono(String.class);
    }
}
```
### 失败请求的重试机制
可以给RestTemplate设置重试机制，默认情况下，这种机制是关闭的，对于非响应式版本（RestTemplate），只要你的classpath中存在spring retry库，那么重试机制会自动开启，对于响应式版本（WebClient），你需要设置`spring.cloud.loadbalancer.retry.enabled=true`如果你想要关闭重试机制，那么设置属性
`spring.cloud.loadbalancer.retry.enabled=false`，对于非反应式实现，如果您想在重试中实现 BackOffPolicy，则需要创建 LoadBalancedRetryFactory 类型的 bean 并覆盖 createBackOffPolicy() 方法。对于响应式实现，您只需将 spring.cloud.loadbalancer.retry.backoff.enabled 设置为 false 即可启用它。你可以设置以下的属性做一些定制化:
- spring.cloud.loadbalancer.retry.maxRetriesOnSameServiceInstance，指示应在同一个 ServiceInstance 上重试请求的次数（针对每个选定实例单独计算）
- spring.cloud.loadbalancer.retry.maxRetriesOnNextServiceInstance，表示新选择的 ServiceInstance 应重试请求的次数
- spring.cloud.loadbalancer.retry.retryableStatusCodes，始终重试失败请求的状态代码;
对于响应式实现，您可以额外设置： - spring.cloud.loadbalancer.retry.backoff.minBackoff - 设置最小回退持续时间（默认情况下，5 毫秒） - spring.cloud.loadbalancer.retry.backoff.maxBackoff - 设置 最大退避持续时间（默认情况下，毫秒的最大长值） - spring.cloud.loadbalancer.retry.backoff.jitter - 设置用于计算每个调用的实际退避持续时间的抖动（默认情况下，0.5）.对于响应式实现，您还可以实现自己的 LoadBalancerRetryPolicy 以更详细地控制负载平衡调用重试。前缀是 spring.cloud.loadbalancer.clients.<clientId>.* 的属性可以设置单个负载均衡器客户端，其中 clientId 是负载均衡器的名称之外，属性的内容与通用的属性基本相同。
对于负载平衡重试，默认情况下，我们使用 RetryAwareServiceInstanceListSupplier 包装 ServiceInstanceListSupplier bean，以从先前选择的实例中选择不同的实例（如果可用）。 您可以通过将 spring.cloud.loadbalancer.retry.avoidPreviousInstance 的值设置为 false 来禁用此行为。
```java
@Configuration
public class MyConfiguration {
    @Bean
    LoadBalancedRetryFactory retryFactory() {
        return new LoadBalancedRetryFactory() {
            @Override
            public BackOffPolicy createBackOffPolicy(String service) {
                return new ExponentialBackOffPolicy();
            }
        };
    }
}

```
如果要向重试功能添加一个或多个 RetryListener 实现，则需要创建 LoadBalancedRetryListenerFactory 类型的 bean 并返回要用于给定服务的 RetryListener 数组，如以下示例所示：
```java
@Configuration
public class MyConfiguration {
    @Bean
    LoadBalancedRetryListenerFactory retryListenerFactory() {
        return new LoadBalancedRetryListenerFactory() {
            @Override
            public RetryListener[] createRetryListeners(String service) {
                return new RetryListener[]{new RetryListener() {
                    @Override
                    public <T, E extends Throwable> boolean open(RetryContext context, RetryCallback<T, E> callback) {
                        //TODO Do you business...
                        return true;
                    }

                    @Override
                     public <T, E extends Throwable> void close(RetryContext context, RetryCallback<T, E> callback, Throwable throwable) {
                        //TODO Do you business...
                    }

                    @Override
                    public <T, E extends Throwable> void onError(RetryContext context, RetryCallback<T, E> callback, Throwable throwable) {
                        //TODO Do you business...
                    }
                }};
            }
        };
    }
}

```
## 2.5 Multiple RestTemplate Objects
如果您想要一个非负载平衡的 RestTemplate，请创建一个 RestTemplate bean 并注入它。 要访问负载平衡的 RestTemplate，请在创建 @Bean 时使用 @LoadBalanced 限定符，如以下示例所示：
```java
@Configuration
public class MyConfiguration {

    @LoadBalanced
    @Bean
    RestTemplate loadBalanced() {
        return new RestTemplate();
    }

    @Primary
    @Bean
    RestTemplate restTemplate() {
        return new RestTemplate();
    }
}

public class MyClass {
@Autowired
private RestTemplate restTemplate;

    @Autowired
    @LoadBalanced
    private RestTemplate loadBalanced;

    public String doOtherStuff() {
        return loadBalanced.getForObject("http://stores/stores", String.class);
    }

    public String doStuff() {
        return restTemplate.getForObject("http://example.com", String.class);
    }
}

```
请注意，在前面的示例中，在普通的 RestTemplate 声明上使用了 @Primary 注释来消除未限定的 @Autowired 注入的歧义。如果看到 java.lang.IllegalArgumentException: Can not set org.springframework.web.client.RestTemplate field com.my.app.Foo.restTemplate to com.sun.proxy.$Proxy89 等错误，请尝试注入 RestOperations 或设置 spring .aop.proxyTargetClass=true。
## 2.6 Multiple WebClient Objects
如果您想要一个非负载平衡的 WebClient，请创建一个 WebClient bean 并注入它。 要访问负载平衡的 WebClient，请在创建 @Bean 时使用 @LoadBalanced 限定符，如以下示例所示：
```java
@Configuration
public class MyConfiguration {

    @LoadBalanced
    @Bean
    WebClient.Builder loadBalanced() {
        return WebClient.builder();
    }

    @Primary
    @Bean
    WebClient.Builder webClient() {
        return WebClient.builder();
    }
}

public class MyClass {
    @Autowired
    private WebClient.Builder webClientBuilder;

    @Autowired
    @LoadBalanced
    private WebClient.Builder loadBalanced;

    public Mono<String> doOtherStuff() {
        return loadBalanced.build().get().uri("http://stores/stores")
                        .retrieve().bodyToMono(String.class);
    }

    public Mono<String> doStuff() {
        return webClientBuilder.build().get().uri("http://example.com")
                        .retrieve().bodyToMono(String.class);
    }
}
```
RestTemplate对象不会自动创建，每个应用都必须手动创建他。
URI 需要使用虚拟主机名（即服务名，而不是主机名）。 BlockingLoadBalancerClient 用于创建完整的物理地址。要使用负载平衡的 RestTemplate，您需要在classpath中存在负载平衡实现类。将 Spring Cloud LoadBalancer starter 等相关的库添加到您的项目中就可以使用了。
## 2.7 Spring WebFlux WebClient 作为负载均衡器客户端
如主题所述，Spring WebFlux 可以与反应式和非反应式 WebClient 配置一起使用。
### Spring WebFlux WebClient with ReactorLoadBalancerExchangeFilterFunction
您可以将 WebClient 配置为使用 ReactiveLoadBalancer。 如果将 Spring Cloud LoadBalancer starter 添加到项目中，并且 spring-webflux 在类路径上，则会自动配置 ReactorLoadBalancerExchangeFilterFunction。 以下示例显示了如何配置 WebClient 以使用反应式负载平衡器：
```java
public class MyClass {
    @Autowired
    private ReactorLoadBalancerExchangeFilterFunction lbFunction;

    public Mono<String> doOtherStuff() {
        return WebClient.builder().baseUrl("http://stores")
            .filter(lbFunction)
            .build()
            .get()
            .uri("/stores")
            .retrieve()
            .bodyToMono(String.class);
    }
}
```
### Spring WebFlux WebClient with a Non-reactive Load Balancer Client
如果 spring-webflux 在类路径上，则 LoadBalancerExchangeFilterFunction 是自动配置的。 但是请注意，这在后台使用了非反应式客户端。 以下示例显示了如何配置 WebClient 以使用负载平衡器：
```java
public class MyClass {
    @Autowired
    private LoadBalancerExchangeFilterFunction lbFunction;

    public Mono<String> doOtherStuff() {
        return WebClient.builder().baseUrl("http://stores")
            .filter(lbFunction)
            .build()
            .get()
            .uri("/stores")
            .retrieve()
            .bodyToMono(String.class);
    }
}

```
## 2.8 Ignore Network Interfaces
有时，忽略某些命名的网络接口很有用，这样它们就可以从服务发现注册中排除（例如，在 Docker 容器中运行服务时）。可以设置正则表达式列表忽略想要顾虑的网络接口，以下配置忽略了 docker0 接口和所有以 veth 开头的接口：
```yml
spring:
  cloud:
    inetutils:
      ignoredInterfaces:
        - docker0
        - veth.*
```
您还可以通过使用正则表达式列表强制仅使用指定的网络地址，如以下示例所示：
spring:
  cloud:
    inetutils:
      preferredNetworks:
        - 192.168
        - 10.0
您还可以强制仅使用站点本地地址，如以下示例所示：
```java
spring:
  cloud:
    inetutils:
      useOnlySiteLocalInterfaces: true
```
## HTTP Client Factoris
Spring Cloud Commons 提供了用于创建 Apache HTTP 客户端 (ApacheHttpClientFactory) 和 OK HTTP 客户端 (OkHttpClientFactory) 的 工厂bean。仅当 OK HTTP jar在classpath里面时才会创建 OkHttpClientFactory bean。此外，Spring Cloud Commons 提供了用于创建两个客户端使用的连接管理器的工厂bean，分别是ApacheHttpClientConnectionManagerFactory与OkHttpClientConnectionPoolFactory，如果您想自定义如何在下游项目中创建 HTTP 客户端，您可以提供自己的这些 bean 实现。此外，如果您提供 HttpClientBuilder 或 OkHttpClient.Builder 类型的 bean，则默认工厂使用这些构建器作为构建器的基础构建器返回给下游的应用使用，您还可以通过将 spring.cloud.httpclientfactories.apache.enabled 或 spring.cloud.httpclientfactories.ok.enabled 设置为 false 来禁用这些 bean 的创建。
## 当前启用特性
Spring Cloud Commons 提供了一个 /features 执行器端点。 此端点返回类路径上可用的功能以及它们是否已启用。 返回的信息包括功能类型、名称、版本和供应商。
### Feature types
有两种类型的“特征”：抽象的和命名的。

抽象特性是定义接口或抽象类并创建实现的特性，例如 DiscoveryClient、LoadBalancerClient 或 LockService。 抽象类或接口用于在上下文中查找该类型的 bean。 显示的版本是 bean.getClass().getPackage().getImplementationVersion()。

命名特征是没有它们实现的特定类的特征。 这些功能包括“断路器”、“API 网关”、“Spring Cloud Bus”等。 这些功能需要名称和 bean 类型。
### Declaring features
任何模块都可以声明任意数量的 HasFeature bean，如以下示例所示：
```java
@Bean
public HasFeatures commonsFeatures() {
  return HasFeatures.abstractFeatures(DiscoveryClient.class, LoadBalancerClient.class);
}

@Bean
public HasFeatures consulFeatures() {
  return HasFeatures.namedFeatures(
    new NamedFeature("Spring Cloud Bus", ConsulBusAutoConfiguration.class),
    new NamedFeature("Circuit Breaker", HystrixCommandAspect.class));
}

@Bean
HasFeatures localFeatures() {
  return HasFeatures.builder()
      .abstractFeature(Something.class)
      .namedFeature(new NamedFeature("Some Other Feature", Someother.class))
      .abstractFeature(Somethingelse.class)
      .build();
}

```
## Spring CloudCompatibility Verification
由于部分用户在设置 Spring Cloud 应用时存在问题，我们决定添加兼容性验证机制。 如果您当前的设置与 Spring Cloud 要求不兼容，它将中断，并附上一份报告，显示究竟出了什么问题。
目前，我们验证将哪个版本的 Spring Boot 添加到您的类路径中。报告示例。要禁用此功能，请将 spring.cloud.compatibility-verifier.enabled 设置为 false。 如果要覆盖兼容的 Spring Boot 版本，只需使用逗号分隔的兼容 Spring Boot 版本列表设置 spring.cloud.compatibility-verifier.compatible-boot-versions 属性。
# Spring Cloud LoadBalancer
Spring Cloud 提供了自己的客户端侧的负载均衡器抽象和实现。 对于负载平衡机制，Spring Cloud添加了ReactiveLoadBalancer抽象接口，并提供了基于 Round-Robin 和 Random 的实现类。 为了实现实例选择机制提供了响应式的ServiceInstanceListSupplier接口抽象。 目前支持基于服务发现方式的ServiceInstanceListSupplier实现，这种方式使用classpath中存在的客户端从远程注册中心中检索可用的服务实例。通过设置`spring.cloud.loadbalancer.enabled=false`可以关闭负载均衡。
## 负载均衡算法
默认使用的 ReactiveLoadBalancer 实现是 RoundRobinLoadBalancer。 要为选定的服务或所有服务使用不同的算法，你可以自定义 LoadBalancer 配置机制。例如下面的配置可以通过@LoadBalancerClient注解来切换到使用RandomLoadBalancer。
```java
public class CustomLoadBalancerConfiguration {

    @Bean
    ReactorLoadBalancer<ServiceInstance> randomLoadBalancer(Environment environment,
            LoadBalancerClientFactory loadBalancerClientFactory) {
        String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
        return new RandomLoadBalancer(loadBalancerClientFactory
                .getLazyProvider(name, ServiceInstanceListSupplier.class),
                name);
    }
}
```
您作为 @LoadBalancerClient 或 @LoadBalancerClients 配置参数传递的类不应使用 @Configuration 注释或超出组件扫描范围。
## Spring Cloud LoadBalancer Integrations
为了便于使用 Spring Cloud LoadBalancer，我们提供了可与 WebClient 一起使用的 ReactorLoadBalancerExchangeFilterFunction 和与 RestTemplate 一起使用的 BlockingLoadBalancerClient。 您可以在以下部分中查看更多信息和使用示例：
- Spring RestTemplate 作为负载均衡器客户端
- Spring WebClient 作为负载均衡器客户端
- 带有 ReactorLoadBalancerExchangeFilterFunction 的 Spring WebFlux WebClient。
## Caching
每次必须选择实例时，除了最基本 ServiceInstanceListSupplier 实现（每次都向注册中心检索实例列表）之外，我们还提供了两个缓存实现。
### Caffeine
如果classpath中存在com.github.ben-manes.caffeine:caffeine库，则将使用基于 Caffeine 的缓存实现。 有关如何配置它的信息，请参阅 LoadBalancerCacheConfiguration 部分。

如果你使用Caffeine，您还可以通过使用`spring.cloud.loadbalancer.cache.caffeine.spec`属性设置您自己的caffeine规范来覆盖 LoadBalancer 的默认caffeine缓存设置。

警告：设置您自己的 Caffeine 规范将覆盖任何其他 LoadBalancerCache 设置，包括通用的LoadBalancer 缓存配置，比如 ttl 和与capacity。
### default LoadBalancer cache Implementation
如果classpath中不存在 Caffeine，将使用 spring-cloud-starter-loadbalancer 依赖内置的的 DefaultLoadBalancerCache缓存实现。 有关如何配置它的信息，请参阅 LoadBalancerCacheConfiguration 部分。要使用 Caffeine 而不是默认缓存，请将 com.github.ben-manes.caffeine:caffeine 依赖项添加到classpath中。
### LoadBalancer Cache Configuration
你可以设置ttl时间（实体过期时间），类似于Duration语法的表达式字符串，以 Duration 表示。 作为 spring.cloud.loadbalancer.cache.ttl 属性的值。 你还可以通过设置 spring.cloud.loadbalancer.cache.capacity 属性的值来设置自己的 LoadBalancer 缓存初始容量。默认设置包括 ttl 设置为 35 秒，默认初始容量为 256。您还可以通过将 spring.cloud.loadbalancer.cache.enabled 的值设置为 false 来完全禁用 loadBalancer 缓存。
尽管基本的、非缓存的实现对于原型设计和测试很有用，但它的效率远低于缓存版本，因此我们建议始终在生产中使用缓存版本。 如果缓存已经由 DiscoveryClient 实现完成，例如 EurekaDiscoveryClient，则应禁用负载均衡器缓存以防止双重缓存。
## 基于Zone的load-balancing
为了启用基于区域的负载平衡，我们提供了 ZonePreferenceServiceInstanceListSupplier类。 我们使用具有域配置相关功能DiscoveryClient（例如，eureka.instance.metadata-map.zone）来选择指定区域内可用的服务实例。您还可以通过设置 spring.cloud.loadbalancer.zone 属性的值来覆盖 DiscoveryClient 特定的区域设置。目前，只有 Eureka Discovery Client 会检测LoadBalancer区域设置。 对于其他发现客户端，设置 spring.cloud.loadbalancer.zone 属性没有什么用，未来更多的客户端实现将会支持这个功能。为了确定检索到的 ServiceInstance 的zone，我们检查其元数据映射中“zone”键下的值。ZonePreferenceServiceInstanceListSupplier 过滤检索到的实例并仅返回同一区域内的实例。 如果区域为空或同一区域内没有实例，则返回所有检索到的实例。为了使用基于区域的负载平衡方法，您必须在自定义配置中实例化 ZonePreferenceServiceInstanceListSupplier bean。我们使用委托来处理 ServiceInstanceListSupplier bean。 我们建议在 ZonePreferenceServiceInstanceListSupplier 的构造函数中传递 DiscoveryClientServiceInstanceListSupplier 委托，然后用 CachingServiceInstanceListSupplier 包装后者以利用 LoadBalancer 缓存机制。
```java
public class CustomLoadBalancerConfiguration {

    @Bean
    public ServiceInstanceListSupplier discoveryClientServiceInstanceListSupplier(
            ConfigurableApplicationContext context) {
        return ServiceInstanceListSupplier.builder()
                    .withDiscoveryClient()
                    .withZonePreference()
                    .withCaching()
                    .build(context);
    }
}

```
## 3.5 Instance Health-Check for LoadBalancer
可以为 LoadBalancer开启预定的 HealthCheck。 为此Spring提供了 HealthCheckServiceInstanceListSupplier类。 它定期验证 ServiceInstanceListSupplier 委托提供的实例是否仍然还活着，并且只返回健康的实例，如果没有设置健康检查 ，那么它返回所有检索到的实例。此机制在使用SimpleDiscoveryClient时特别有用。 对于由实际 Service Registry 支持的客户端，没有必要使用，因为我们在查询外部 ServiceDiscovery 后已经获得了健康的实例。此机制在使用 SimpleDiscoveryClient时特别有用。 对于实际访问 Service Registry的客户端客户端，没有必要使用健康检查，因为我们在查询外部 ServiceDiscovery 后已经获得了健康的实例。当每个服务的实例数比较少的时候也建议设置健康检查，这是为了避免频繁发生重复调用失败实例。如果使用任何真实的服务注册组件，通常不需要添加这种健康检查机制，因为我们直接从服务注册中检索实例的健康状态。HealthCheckServiceInstanceListSupplier 依赖于一个委托的flux提供最新的实例。 在极少数情况下，当您想使用一个不刷新实例的委托时，即使实例列表可能发生变化（例如我们提供的 DiscoveryClientServiceInstanceListSupplier），你也可以设置 spring.cloud.loadbalancer.health-check.refetch-instances 为 true 以使 HealthCheckServiceInstanceListSupplier 刷新实例列表。 然后，您还可以通过修改 spring.cloud.loadbalancer.health-check.refetch-instances-interval 的值来调整刷新间隔，并通过设置 spring.cloud.loadbalancer.health-check.repeat-health-check=false来关闭额外的重复的健康检查。因为每个实例重新获取也会触发健康检查。HealthCheckServiceInstanceListSupplier 使用以 spring.cloud.loadbalancer.health-check 为前缀的属性。 您可以为调度程序设置初始延迟和间隔。 您可以通过设置 spring.cloud.loadbalancer.health-check.path.default 属性的值来设置健康检查 URL 的默认路径。您还可以通过设置 spring.cloud.loadbalancer.health-check.path.[SERVICE_ID] 属性的值来为任何给定服务设置特定值，将 [SERVICE_ID] 替换为您的服务的正确 ID。 如果未指定 [SERVICE_ID]，则默认使用 /actuator/health。 如果 [SERVICE_ID] 设置为 null 或空值，则不会执行健康检查。 您还可以通过设置 spring.cloud.loadbalancer.health-check.port 的值来为健康检查请求设置自定义端口。 如果没有设置，则在服务实例上请求的服务可用的端口。如果您依赖默认路径（/actuator/health），请确保将 spring-boot-starter-actuator 添加到协作者的依赖项中，除非您打算自己添加这样的端点。为了使用健康检查调度器方式，您必须在自定义配置中实例化 HealthCheckServiceInstanceListSupplier bean。我们使用委托来处理 ServiceInstanceListSupplier bean。 我们建议在 HealthCheckServiceInstanceListSupplier 的构造函数中传递一个 DiscoveryClientServiceInstanceListSupplier 委托。
```java
public class CustomLoadBalancerConfiguration {

    @Bean
    public ServiceInstanceListSupplier discoveryClientServiceInstanceListSupplier(
            ConfigurableApplicationContext context) {
        return ServiceInstanceListSupplier.builder()
                    .withDiscoveryClient()
                    .withHealthChecks()
                    .build(context);
        }
    }

```
## 3.6 Same instance preference for LoadBalancer
您可以设置 LoadBalancer，使其更喜欢选择前一次选择的实例（如果该实例可用）。您可以设置 LoadBalancer，使其更喜欢先前选择的实例（如果该实例可用）。

为此，您需要使用 SameInstancePreferenceServiceInstanceListSupplier。 您可以通过将 spring.cloud.loadbalancer.configurations 的值设置为 same-instance-preference 或提供自己的 ServiceInstanceListSupplier bean 来配置它 — 例如：
```java
public class CustomLoadBalancerConfiguration {

    @Bean
    public ServiceInstanceListSupplier discoveryClientServiceInstanceListSupplier(
            ConfigurableApplicationContext context) {
        return ServiceInstanceListSupplier.builder()
                    .withDiscoveryClient()
                    .withSameInstancePreference()
                    .build(context);
        }
    }
```
## 3.7 Request-based Sticky Session for LoadBalancer
您可以设置 LoadBalancer，使其使用cookie中通过实例ID指定的实例。 我们目前支持请求通过 ClientRequestContext 或 ServerHttpRequestContext 传递给 LoadBalancer，这样SC LoadBalancer 会在交换过滤器函数和过滤器使用它们完成实例选择，为此，您需要使用 RequestBasedStickySessionServiceInstanceListSupplier。 您可以通过将 spring.cloud.loadbalancer.configurations 的值设置为 request-based-sticky-session 或提供自己的 ServiceInstanceListSupplier bean 来配置它 — 例如：
```java
public class CustomLoadBalancerConfiguration {

    @Bean
    public ServiceInstanceListSupplier discoveryClientServiceInstanceListSupplier(
            ConfigurableApplicationContext context) {
        return ServiceInstanceListSupplier.builder()
                    .withDiscoveryClient()
                    .withRequestBasedStickySession()
                    .build(context);
        }
    }
```
对于该功能，在转发请求之前更新所选服务实例（如果该服务实例不可用，则该服务实例可能与原始请求 cookie 中的服务实例不同）是有用的。 为此，请将 spring.cloud.loadbalancer.sticky-session.add-service-instance-cookie 的值设置为 true。默认情况下，cookie 的名称是 sc-lb-instance-id。 您可以通过更改 spring.cloud.loadbalancer.instance-id-cookie-name 属性的值来修改它。This feature is currently supported for WebClient-backed load-balancing.
## 3.8 Spring Cloud LoadBalancer Hints
Spring Cloud LoadBalancer 允许您设置字符串提示，这些提示在 Request 对象中传递给 LoadBalancer，以后可以在可以处理它们的 ReactiveLoadBalancer 实现中使用。Spring Cloud LoadBalancer 允许您设置字符串提示，这些提示在 Request 对象中传递给 LoadBalancer，以后可以在可以处理它们的 ReactiveLoadBalancer 实现中使用。您可以通过设置 spring.cloud.loadbalancer.hint.default 属性的值来为所有服务设置默认提示。 您还可以通过设置 spring.cloud.loadbalancer.hint.[SERVICE_ID] 属性的值，将 [SERVICE_ID] 替换为您的服务的正确 ID，为任何给定服务设置特定值。 如果用户未设置提示，则使用默认值。
## 3.9  Hint-Based Load-Balancing
我们还提供了一个 HintBasedServiceInstanceListSupplier，它是一个 ServiceInstanceListSupplier 实现，用于实现基于hint的实例选择的功能。HintBasedServiceInstanceListSupplier 检查提示请求标头（默认标头名称为 X-SC-LB-Hint，但您可以通过更改 spring.cloud.loadbalancer.hint-header-name 属性的值来修改它），如果它找到一个提示请求头，使用头中传递的提示值来过滤服务实例。如果未添加任何提示标头，则 HintBasedServiceInstanceListSupplier 将使用属性中的提示值来过滤服务实例。如果没有通过标头或属性设置提示，则返回委托提供的所有服务实例。在过滤时，HintBasedServiceInstanceListSupplier 会查找在其 metadataMap 中的提示键下设置了匹配值的服务实例。如果没有找到匹配的实例，则返回委托提供的所有实例。
您可以使用以下示例配置进行设置：
```java
public class CustomLoadBalancerConfiguration {

    @Bean
    public ServiceInstanceListSupplier discoveryClientServiceInstanceListSupplier(
            ConfigurableApplicationContext context) {
        return ServiceInstanceListSupplier.builder()
                    .withDiscoveryClient()
                    .withHints()
                    .withCaching()
                    .build(context);
    }
}
```
## 3.10 Transform the load-balanced HTTP request
您可以使用选定的 ServiceInstance 来转换负载均衡的 HTTP 请求。对于 RestTemplate，您需要实现和定义 LoadBalancerRequestTransformer，如下所示：
```java
@Bean
public LoadBalancerRequestTransformer transformer() {
    return new LoadBalancerRequestTransformer() {
        @Override
        public HttpRequest transformRequest(HttpRequest request, ServiceInstance instance) {
            return new HttpRequestWrapper(request) {
                @Override
                public HttpHeaders getHeaders() {
                    HttpHeaders headers = new HttpHeaders();
                    headers.putAll(super.getHeaders());
                    headers.add("X-InstanceId", instance.getInstanceId());
                    return headers;
                }
            };
        }
    };
}
```
对于 WebClient，您需要实现和定义 LoadBalancerClientRequestTransformer，如下所示：
```java
@Bean
public LoadBalancerClientRequestTransformer transformer() {
    return new LoadBalancerClientRequestTransformer() {
        @Override
        public ClientRequest transformRequest(ClientRequest request, ServiceInstance instance) {
            return ClientRequest.from(request)
                    .header("X-InstanceId", instance.getInstanceId())
                    .build();
        }
    };
}
```
如果定义了多个转换器，它们将按照定义 Bean 的顺序应用。 或者，您可以使用 LoadBalancerRequestTransformer.DEFAULT_ORDER 或 LoadBalancerClientRequestTransformer.DEFAULT_ORDER 来指定顺序。
## 3.11 Spring Cloud LoadBalancer Starter
我们还提供了一个启动器，允许您在 Spring Boot 应用程序中轻松添加 Spring Cloud LoadBalancer。 为了使用它，只需将 org.springframework.cloud:spring-cloud-starter-loadbalancer 添加到构建文件中的 Spring Cloud 依赖项中。Spring Cloud LoadBalancer starter 包括 Spring Boot Caching 和 Evictor
## 3.12. Passing Your Own Spring Cloud LoadBalancer Configuration
您还可以使用@LoadBalancerClient 注解来传递您自己的负载均衡器客户端配置，传递负载均衡器客户端的名称和配置类，如下所示：
```java
@Configuration
@LoadBalancerClient(value = "stores", configuration = CustomLoadBalancerConfiguration.class)
public class MyConfiguration {

    @Bean
    @LoadBalanced
    public WebClient.Builder loadBalancedWebClientBuilder() {
        return WebClient.builder();
    }
}
```
为了使您自己的 LoadBalancer 配置工作更容易，我们在 ServiceInstanceListSupplier 类中添加了一个 builder() 方法。您还可以使用我们的替代预定义配置来代替默认配置，方法是将 spring.cloud.loadbalancer.configurations 属性的值设置为 zone-preference 以使用 ZonePreferenceServiceInstanceListSupplier 缓存或健康检查以使用 HealthCheckServiceInstanceListSupplier 缓存。您可以使用此功能来实例化 ServiceInstanceListSupplier 或 ReactorLoadBalancer 的不同实现，这些实现可以由您编写，也可以由我们作为替代方案提供（例如 ZonePreferenceServiceInstanceListSupplier），以覆盖默认设置。您可以在此处查看自定义配置的示例。您还可以通过 @LoadBalancerClients 注释传递多个配置（用于多个负载均衡器客户端），如以下示例所示：
```java
@Configuration
@LoadBalancerClients({@LoadBalancerClient(value = "stores", configuration = StoresLoadBalancerClientConfiguration.class), @LoadBalancerClient(value = "customers", configuration = CustomersLoadBalancerClientConfiguration.class)})
public class MyConfiguration {

    @Bean
    @LoadBalanced
    public WebClient.Builder loadBalancedWebClientBuilder() {
        return WebClient.builder();
    }
}
```
您作为 @LoadBalancerClient 或 @LoadBalancerClients 配置参数传递的类不应使用 @Configuration 注释或超出组件扫描范围。
## Spring Cloud LoadBalancer Lifecycle
使用自定义的LoadBalancer配置时，经常使用的一种类型的bean是LoadBalancerLifecycle，也就是负载均衡器的生命周期方法，LoadBalancerLifecycle bean 提供名为 onStart(Request<RC> request)、onStartRequest(Request<RC> request, Response<T> lbResponse) 和 onComplete(CompletionContext<RES, T, RC> completionContext) 的回调方法，您应该实现这些方法以指定在负载平衡之前和之后应该执行的操作。onStart(Request<RC> request) 将 Request 对象作为参数。它包含用于选择适当实例的数据，包括下游客户端请求和提示。 onStartRequest 还将 Request 对象和另外的 Response<T> 对象作为参数。另一方面，将 CompletionContext 对象提供给 onComplete(CompletionContext<RES, T, RC> completionContext) 方法。它包含 LoadBalancer 响应，包括所选服务实例、针对该服务实例执行的请求的状态和（如果可用）返回给下游客户端的响应，以及（如果发生异常）相应的 Throwable。supports(Class requestContextClass, Class responseClass, Class serverTypeClass) 方法可用于确定相关处理器是否处理提供类型的对象。如果没有被用户覆盖，则返回 true。在上述方法调用中，RC 表示 RequestContext 类型，RES 表示客户端响应类型，T 表示返回的服务器类型。
## Spring Cloud LoadBalancer Statistics
我们提供了一个名为 MicrometerStatsLoadBalancerLifecycle 的 LoadBalancerLifecycle bean，它使用 Micrometer 提供负载平衡调用的统计信息。为了将此 bean 添加到您的应用程序上下文中，请将 spring.cloud.loadbalancer.stats.micrometer.enabled 的值设置为 true 并有一个可用的 MeterRegistry（例如，通过将 Spring Boot Actuator 添加到您的项目中）。MicrometerStatsLoadBalancerLifecycle 在 MeterRegistry 中注册以下仪表：
- loadbalancer.requests.active：允许您监视任何服务实例的当前活动请求数量的量规（通过标签提供的服务实例数据）；

- loadbalancer.requests.success：一个计时器，用于测量任何负载平衡请求的执行时间，这些请求以将响应传递给底层客户端而结束；

- loadbalancer.requests.failed：一个计时器，用于测量任何以异常结束的负载平衡请求的执行时间；

- loadbalancer.requests.discard：测量丢弃的负载平衡请求数量的计数器，即 LoadBalancer 尚未检索到运行请求的服务实例的请求。

在可用时，通过标签将有关服务实例、请求数据和响应数据的附加信息添加到指标中。
对于某些实现，例如 BlockingLoadBalancerClient，请求和响应数据可能不可用，因为我们从参数建立泛型类型并且可能无法确定类型并读取数据。
## Configuring Individual LoadBalancerClients
单个负载均衡器客户端可以单独配置，使用不同的前缀 spring.cloud.loadbalancer.clients.<clientId>就可以实现 。 其中 clientId 是负载均衡器的名称。 默认配置值可以在 spring.cloud.loadbalancer 中设置。 配置最终会被合并到一起并且，客户端的独立配置的优先级更高。比如下面的例子:
```yml
spring:
  cloud:
    loadbalancer:
      health-check:
        initial-delay: 1s
      clients:
        myclient:
          health-check:
            interval: 30s

```
上面的示例将生成一个合并的健康检查@ConfigurationProperties 对象，初始延迟=1s 和间隔=30s。除以下全局属性外，每个客户端的配置属性适用于大多数属性：
- spring.cloud.loadbalancer.enabled，全局开启/关闭负载均衡
- spring.cloud.loadbalancer.retry.enabled，开启/关闭全局负载均衡重试;
- spring.cloud.loadbalancer.cache.enabled，开启/关闭全局负载均衡缓存;
- spring.cloud.loadbalancer.stats.micrometer.enabled
# 4 Spring Cloud Circuit Breaker
Spring Cloud断路器提供了断路器的统一抽象，底层可以使用其他已有的框架/库来实现， 它提供了一致的API，让您（开发人员）选择最适合您的应用程序需求的断路器实现。
## 4.1 简介
Spring Cloud支持以下的断路器实现
- Resilience4j
- Sentinel
- Spring Retry
## Core Concepts
要在代码中创建断路器，您可以使用 CircuitBreakerFactory API。 当classpath中包含 Spring Cloud Circuit Breaker starter时，会自动为您创建实现此 API 的 bean。 以下示例显示了如何使用此 API 的简单示例：
```java
@Service
public static class DemoControllerService {
    private RestTemplate rest;
    private CircuitBreakerFactory cbFactory;

    public DemoControllerService(RestTemplate rest, CircuitBreakerFactory cbFactory) {
        this.rest = rest;
        this.cbFactory = cbFactory;
    }

    public String slow() {
        return cbFactory.create("slow").run(() -> rest.getForObject("/slow", String.class), throwable -> "fallback");
    }

}
```
CircuitBreakerFactory.create API 创建一个 CircuitBreaker类型的实例。 run 方法接受一个Supplier和一个Function。 Supplier是您要包装在断路器中的代码。 Function是在断路器跳闸时运行的后备。 该函数被传递引发次后备被触发的 Throwable。 如果您不想提供回退，您可以选择排除回退。
如果 Project Reactor 在classpath中，您还可以将 ReactiveCircuitBreakerFactory 用于您的反应式代码。 以下示例显示了如何执行此操作：
```java
@Service
public static class DemoControllerService {
    private ReactiveCircuitBreakerFactory cbFactory;
    private WebClient webClient;


    public DemoControllerService(WebClient webClient, ReactiveCircuitBreakerFactory cbFactory) {
        this.webClient = webClient;
        this.cbFactory = cbFactory;
    }

    public Mono<String> slow() {
        return webClient.get().uri("/slow").retrieve().bodyToMono(String.class).transform(
        it -> cbFactory.create("slow").run(it, throwable -> return Mono.just("fallback")));
    }
}
```
ReactiveCircuitBreakerFactory.create API 创建一个名为 ReactiveCircuitBreaker 的类的实例。 run 方法采用 Mono 或 Flux 并将其包装在断路器中。 您可以选择分析一个回退函数，如果断路器跳闸并传递导致故障的 Throwable 将调用该函数。
## Configuration
您可以通过创建Customizer类型的 bean 来配置您的断路器。 Customizer 接口有一个方法（称为customize），它接受Object 进行自定义。有关如何自定义给定实现的详细信息，请参阅以下文档：
- [Resilience4J](https://docs.spring.io/spring-cloud-commons/spring-cloud-circuitbreaker/current/reference/html/spring-cloud-circuitbreaker.html#configuring-resilience4j-circuit-breakers)
- [Sentinel](https://github.com/alibaba/spring-cloud-alibaba/blob/master/spring-cloud-alibaba-docs/src/main/asciidoc/circuitbreaker-sentinel.adoc#circuit-breaker-spring-cloud-circuit-breaker-with-sentinel%E2%80%94%E2%80%8Bconfiguring-sentinel-circuit-breakers)
- [Spring Retry](https://docs.spring.io/spring-cloud-circuitbreaker/docs/current/reference/html/spring-cloud-circuitbreaker.html#configuring-spring-retry-circuit-breakers)
每次调用 CircuitBreaker#run 时，一些 CircuitBreaker 实现（例如 Resilience4JCircuitBreaker）都会调用自定义方法。 它可能效率低下。 在这种情况下，您可以使用 CircuitBreaker#once 方法。在无需多次调用自定义方法的情况下很有用，例如，在消费Resilience4j 的事件的场景。下面的例子展示了每个 io.github.resilience4j.circuitbreaker.CircuitBreaker 消费事件的方式
```java
Customizer.once(circuitBreaker -> {
  circuitBreaker.getEventPublisher()
    .onStateTransition(event -> log.info("{}: {}", event.getCircuitBreakerName(), event.getStateTransition()));
}, CircuitBreaker::getName)
```
# CachedRandomPropertySource
Spring Cloud Context 提供了一个 PropertySource，它基于 key 缓存随机值。 在缓存功能之外，它的工作方式与 Spring Boot 的 RandomValuePropertySource 相同。 如果您想要一个即使在 Spring 应用程序上下文重新启动后仍保持一致的随机值，此随机值可能很有用。 属性值采用 cachedrandom.[yourkey].[type] 的形式，其中 yourkey 是缓存中的键。 类型值可以是 Spring Boot 的 RandomValuePropertySource 支持的任何类型。
```java
myrandom=${cachedrandom.appname.value}
```
# Security
## SSO
所有 OAuth2 SSO 和资源服务器功能都在 1.3 版中移至 Spring Boot。 您可以在 Spring Boot 用户指南中找到文档。
如果您的应用是面向 OAuth2 客户端的用户（即已声明 @EnableOAuth2Sso 或 @EnableOAuth2Client），那么它在 Spring Boot 的请求范围内具有 OAuth2ClientContext。 您可以从此上下文和自动连接的 OAuth2ProtectedResourceDetails 创建自己的 OAuth2RestTemplate，然后上下文将始终将访问令牌转发到下游，如果访问令牌过期，也会自动刷新访问令牌。 （这些是 Spring Security 和 Spring Boot 的特性。）
