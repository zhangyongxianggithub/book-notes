# 前言
## SDI（spring data integration）的简短的历史
数据整合开始于Spring Integration项目，它可以使用Spring编程模型提供的一致的开发体验来构造企业级的整合应用，这种整合遵循一定的模式，按照模式，可以连接很对外部的系统，比如数据库，消息中心或者其他的系统。
随着云时代的到来，企业级应用中逐渐转变成微服务的形式，Spring Boot项目大大提高了开发者开发引用的效率；使用Spring的编程模型以及Spring Boot的运行时责任托管，开发生产级别的基于Spring的微服务就成为自然而然的选择。
为了让Spring整合数据集成的工作，Spring Integration与Spring Boot项目组合起来变成了一个新的项目Spring Cloud Stream。
使用Spring Cloud Stream，开发者可以：
- 独立构建、测试、部署以数据为中心的应用;
- 应用现代的微服务架构模式，特别是使用消息系统整合应用;
- 使用事件机制解耦应用责任，一个事件可以表示某个时间发生的某件事情，下游的消费应用可以在不知到事件起源的情况对事件作出响应;
- 将业务逻辑移植到消息节点上;
- 依靠框架对常见用例的自动内容类型支持。 可以扩展到不同的数据转换类型;
## 快速开始
你可以在5分钟内通过3个步骤快速的熟悉Spring Cloud Stream。我们会向你展示如何创建一个Spring Cloud Stream应用，这个应用可以接受来自消息中间件的消息并打印消息，我们叫它LoggingConsumer，当然这个消费者不具有实际的意义，但是通过它，我们可以快速了解一些主要的概念与对象的定义，对于后续章节的阅读帮助很大.
3个步骤是：
- 使用Spring Initializer创建一个简单的应用;
- 导入应用到你的IDE
- 添加消息处理器，构建&运行。
### 使用Spring Initializer创建一个简单的应用
### 导入应用到你的IDE
### 添加消息处理器，构建&运行
```java
@SpringBootApplication
public class LoggingConsumerApplication {

	public static void main(String[] args) {
		SpringApplication.run(LoggingConsumerApplication.class, args);
	}

	@Bean
	public Consumer<Person> log() {
	    return person -> {
	        System.out.println("Received: " + person);
	    };
	}

	public static class Person {
		private String name;
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
		public String toString() {
			return this.name;
		}
	}
}
```
正如你在上面的列表中看到的：
- 我们正在使用函数式编程模型（可以看[Spring Cloud FUnction suppert](https://docs.spring.io/spring-cloud-stream/docs/3.2.1/reference/html/spring-cloud-stream.html#spring_cloud_function)）来定义一个单个的消息处理器作为Consumer;
- 依赖框架约定，绑定消息处理器到指定的输入地址上;
这使用了框架的一个和行人特性：它会自动把输入的message转换成Person类型的消息体。
# 重要的丢弃
- 基于注解的编程模型，基本上，@EnableBinding、@StreamListener还有其他相关的注解都被遗弃了，现在使用的是函数式编程模型，可以看Spring Cloud Function support章节获取更多的信息;
- Reactive模块（spring-cloud-stream-reactive）停止使用了并且不在分发，使用来了spring-cloud-function的内置支持实现reactive;
- spring-cloud-stream-test-support不在支持了，使用了新的test binder;
- @StreamMessageConverter 不在被使用;
- original-content-type被移除了;
- BinderAwareChannelResolver不在使用，使用了spring.cloud.stream.sendto.destination属性，这主要是为了使用函数式编程模式，对于StreamListener来说，它仍是需要哦的，完全遗弃StreamListener与基于注解的编程模型后，这个类也不会再被使用了.
# 在流数据上下文中使用SpEL
在整个参考文档中，非常多的地方或者案例会使用到SpEL，在使用它前，你需要了解一下SpEL的边界限制。
SpEL 使您可以访问当前消息以及您正在运行的应用程序上下文。但是，了解 SpEL 可以看到什么类型的数据非常重要，尤其是在传入消息的上下文中。来自代理的消息以字节 [] 的形式到达。然后它被绑定器转换为 Message\<byte[]> ，您可以看到消息的有效负载保持其原始形式。消息的标头是 \<String, Object>，其中值通常是一个基本类型的数据或基本类型数据的集合/数组，因此类型是 Object。这是因为 binder并不知道所需的输入类型，因为它无法访问用户代码（函数）。因此，绑定器会接收到带有消息体与消息header的消息，就像通过邮件传递的信件一样。这意味着虽然可以访问消息的有效负载，但您只能以原始数据（即字节 []）的形式访问它。虽然开发人员想要使用SpEL访问作为具体类型（例如 Foo、Bar 等）的有效负载对象的字段的场景可能很常见，但您可以看到实现它是多么困难甚至不可能。这是一个演示问题的示例；想象一下，您有一个路由表达式可以根据负载类型路由到不同的函数。此要求意味着将有效负载从 byte[] 转换为特定类型，然后应用 SpEL。然而，为了执行这样的转换，我们需要知道要传递给转换器的实际类型，而这来自我们不知道是哪一个的函数签名。解决此要求的更好方法是将类型信息作为消息头（例如 application/json;type=foo.bar.Baz ）传递。您将获得一个清晰易读的字符串值，该值可以在一年内访问和评估，并且易于阅读 SpEL 表达式。
另外，使用消息负载做路由决策是不好的实践，因为负载时敏感数据，这种数据只应该被它的最终的接收者读取；而且，如果类比下邮件投递，你不想邮差打开你的信件，通过阅读信件里面的内容来决定投递策略；同样的概念在这里也是适用的，尤其是发送消息相对比较容易包含一些敏感的信息。
# Spring Cloud Stream简介
SCS是一个用于构建消息驱动的微服务应用的框架，SCS基于Spring Boot来构建独立的、生产级别的Spring应用，使用Spring Integration提供连接消息节点的能力，它提供了来自多个供应商的中间件的通用的配置，介绍了持久化的发布订阅语义、消费者组和分区的概念。
通过添加spring-cloud-stream依赖到你应用程序1的classpath下，你可以使用spring-cloud-stream的binder能力来连接到消息节点，你可以实现你自己的函数逻辑，它是以java.util.function.Function的形式运行的。
下面的代码是一个例子：
```java
@SpringBootApplication
public class SampleApplication {

	public static void main(String[] args) {
		SpringApplication.run(SampleApplication.class, args);
	}

    @Bean
	public Function<String, String> uppercase() {
	    return value -> value.toUpperCase();
	}
}
```
下面的列表是相关的测试
```java
@SpringBootTest(classes =  SampleApplication.class)
@Import({TestChannelBinderConfiguration.class})
class BootTestStreamApplicationTests {

	@Autowired
	private InputDestination input;

	@Autowired
	private OutputDestination output;

	@Test
	void contextLoads() {
		input.send(new GenericMessage<byte[]>("hello".getBytes()));
		assertThat(output.receive().getPayload()).isEqualTo("HELLO".getBytes());
	}
}
```
# 主要的概念
SCS提供了很多的抽象与定义来简化编写消息驱动的微服务的应用，这个章节主要讲一下的内容
- SCS引用模型;
- Binder抽象定义;
- 持久化的发布-订阅支持
- 消费者组支持;
- 分片支持;
- 可插拔的Binder SPI
## 应用模型
一个SCS应用由一个中间件中立的核心组成，在应用中通过创建绑定关系与外部系统通信，绑定关系有2方组成，其中一方是外部消息节点暴漏的destination，另一方是代码中的input/output参数，建立绑定所需的消息节点特定细节由特定的Binder中间件实现处理。
![scs 应用模型](spring-cloud-stream/scs-application.png)
scs应用可以以单体的方式运行，为了在生产环境上使用SCS，你可以创建一个Fat JAR。
## Binder抽象
Spring Cloud Stream为Kafka与Rabbit MQ提供了Binder实现，框架也包含一个test binder的实现用于集成测试，可以看Testing章节获得更多详细的信息。Binder抽象也是框架的扩展点之一，这意味着，你可以基于Spring Cloud Stream实现你自己的binder，在[How to create a Spring Cloud Stream Binder from scratch](https://medium.com/@domenicosibilio/how-to-create-a-spring-cloud-stream-binder-from-scratch-ab8b29ee931b)部分有社区成员文档的地址例子等，只需要几个简单的步骤就可以实现一个自定义的binder，详细的步骤在实现自定义的Binders章节。
Spring Cloud Stream使用SpringBoot机制来配置，并且Binder抽象定义让Spring Cloud Stream应用连接中间件更加灵活，比如，开发者可以在运行时动态选择destination与消息处理器的绑定关系，这样的配置可以通过外部配置提供，只要是Spring Boot支持的外部配置方式都可以，在sink例子章节，设置
`spring.cloud.stream.bindings.input.destination=raw-sensor-data`会让引用读取名为raw-sensor-data的kafka topic或者对应的Rabbit
MQ交换队列；Spring Cloud Stream会自动检测并使用classpath下的binder，你可以在同样一份代码的基础上使用不同的中间件，只需要在构建时加载不同的binder实现；对于更复杂的使用场景，你也可以在应用内打包多个binders，在运行时动态选择binder。
## 持久化的pub-sub支持
应用间的pub-sub通信模式，也就是数据通过共享的topic广播，下面的插图中可以看到这样的通信方式。
![pub-sub](spring-cloud-stream/scs-pub-sub.png)
由传感器上报的数据传输到一个HTTP的端点，然后被发送到一个叫做raw-sensor-data的目的地址，2个微服务应用独立的消费这个目的地址的消息，其中一个执行时间窗口的平均值计算，一个写入原始数据到HDFS（Hadoop Distributed File System）,为了可以处理到数据，2个应用都在运行时声明了这个topic作为输入。pub-sub通信模式可以减少发送者与消费者的复杂性，可以在不破坏历史数据流拓扑的情况下添加新的应用；比如：作为计算平均值应用的下游应用，你可以添加一个应用，你可以添加一个应用计算温度的最大值用于展示与监控，你可以再添加一个应用，用于检测平均值流中的错误；通过共享的topic通信做这些相比比点对点队列解耦了微服务之间的依赖关系.
虽然发布订阅消息的概念并不新鲜，但 Spring Cloud Stream 采取了额外的步骤，使其成为其应用程序模型的一个非常棒的选择。 通过使用原生中间件支持，Spring Cloud Stream 还简化了跨平台发布订阅模型的使用。
## 消费者组
pub-sub模式使得通过共享的topic连接应用更加的简单，引用扩容的能力的是非常重要的，当这样的做的时候，应用的不同的实例是一个竞争的消费者的关系，对于一个给定的message来说，只有一个实例可以处理它。
SCS为了实现这种消费方式，提出了消费者组的概念（这是收到了Kafka消费者组概念的启发，也与之类似）；每一个绑定的消费者都可以使用`spring.cloud.stream.bindings.<bindingName>.group`属性来指定消费者组的名字，对于下图中的消费者来说，属性定义是`spring.cloud.stream.bindings.<bindingName>.group=hdfsWrite`或者`spring.cloud.stream.bindings.<bindingName>.group=average`
![消费者组的概念](spring-cloud-stream/consumer-group.png)
订阅给定的destination的消费者组都会收到消息的一个副本，但是每个消费者组中只有有个消费者会处理它；默认情况下，当没有指定消费者组的时候，SCS会给应用分配一个匿名的带序号的消费者组名。
## 消费者类型
支持2种消费者类型：
- 消息驱动的（有时候也叫做异步消费者）
- 轮询驱动的（也叫做同步消费者类型）
在2.0版本以前，只支持异步的消费者类型，一个message只要发送了就会尽快的传递到目的地，一个线程会处理它。
当你想要控制处理的速率，你可能就想要使用同步消费者。
### durability持久性
与SCS的编程模型一脉相承，消费者组的订阅关系是持久的，也就是说，binder实现需要确保组订阅关系被持久存储，一旦，一个组订阅关系被创建，组就开始接收消息，及时消费者此时全部是停止的状态，消息会正常投递到组。
通常来说，当绑定应用与destination的时候，更建议始终指定一个消费者组，当扩容的时候，你必须为它的每个输入的binding指定消费者组，这么做可以防止引用的多个实例都会接收到同样一条消息。
## 分片支持
SCS提供了一个应用的多个实例间的数据分片的支持，在分片场景下，物理通信媒介被视为由多个分片组成；消息的生产者发送消息到多个消费者，分片可以确保，带有没有通用字符特征的数据只会被同一个消费者处理。
SCS为分区场景提供的统一的抽象定义，底层的实现可以是支持分区的也可以不支持分区。分区抽象都可以使用。
![分区抽象](spring-cloud-stream/partitioning.png)
分区在有状态的处理领域是需要重点关注的概念，需要确保所有相关的数据按顺序得到处理是很难的（因为性能或者一致性的原因），比如，在时序窗口均值计算的案例中，从一个给定的传感器得到的所有的观测的数据都由一个应用实例来处理是很重要的。为了设置分区处理场景，你必须在数据的生产者与消费者部分都配置分区支持.
# 编程模型
为了理解编程模型，你应该首先了解下面的核心概念
- Destination Binders: 负责与外部的消息系统整合的组件
- Bindings: 外部消息系统与生产者与消费者之间的桥，它是由Destination Binder创建的。
- Message: 生产者发送给Destination binder的数据接口，消费者从Destination binder消费的数据结构.
![编程模型](spring-cloud-stream/program-model.png)
## Destination Binders
Destination Binders是Spring Cloud Stream组件的扩展，负责为整合外部的消息系统提供必要的配置与实现。整合的过程涉及连接、代理、消息路由、数据类型转换、用户代码调用等等。
Binders处理了很多的样板任务，然而，为了实现功能，binder仍然会需要用户的一些的指令，这些指令通常是binding的配置属性。
讨论所有的binder超出了本节的范围。
## Bindings
早先说明的，Bindings提供了外部消息系统与生产者消者的桥，下面的例子展示了一个配置完全可以运行的Spring Cloud Stream应用，它接受String类型的message，并打印到控制台，转换成大写后发送到下游。
```java
@SpringBootApplication
public class SampleApplication {

	public static void main(String[] args) {
		SpringApplication.run(SampleApplication.class, args);
	}

	@Bean
	public Function<String, String> uppercase() {
	    return value -> {
	        System.out.println("Received: " + value);
	        return value.toUpperCase();
	    };
	}
}
```
上面的例子看起来与一个普通的spring-boot应用没有任何区别，它定义了一个Function类型的bean，所以，它如何成为一个spring cloud stream应用呢？只需要classpath中出现spring-cloud-stream包与bidner的相关的依赖，还有classpath中出现自动配置的相关的类，这样就为spring-boot添加了spring cloud stream的上下文，在这个上下文中的所有的Supplier、Function、Consumer类型的bean都会被认为是消息处理器；这些消息处理器会一句规定的名字转换规则绑定到binder提供的destination上，规则是为了避免多余的配置。
### Binding与Binding names
绑定是一个用来表示源与目标之间的一个桥的抽象定义，绑定又个名字，我们尽力使用较少的配置就可以运行SCS应用，对于约定配置的场景，我们知道名字的生成规则是必要的；在这个整个手册的讲述中，你会一直看到类似于`spring.cloud.stream.bindings.input.destination=myQueue`这种属性配置的例子，这里的input就是我们🈯️的绑定名，它的生成有几种机制；下面的小节讲述了名字的生成规则还有一些有关名字的配置属性。
### Functional binding names
传统的基于注解的编程模式会明确的指定binding的名字，函数式编程模型默认使用一种简单的转换，因而简化了应用的配置，下面让我们看一个例子：
```java
@SpringBootApplication
public class SampleApplication {

	@Bean
	public Function<String, String> uppercase() {
	    return value -> value.toUpperCase();
	}
}
```
在前面这个例子中，我们的应用中定义了一个Function作为消息处理器，它有输入与输出，输入与输出的绑定的名字生成规则如下：
- input-<functionName>-in-<index>
- output-<functionName>-out-<index>
`in`与`out`类似于binding的类型（比如输入与输出），`index`表示的是输入与输出绑定的编号，对于单个的input/output的Function来说，它始终是0。
所以，如果你想把function的输入映射到一个远程的destination比如叫my-topic，你需要配置如下的属性：
> spring.cloud.stream.bindings.uppercase-in-0.destination=my-topic
有时候，为了提高可读性，你可能想要binding的名字更加具有描述性，实现的方式是，你可以把隐含的banding名字映射成一个明确指定的binding名字，你可以通过属性`spring.cloud.stream.function.bindings.<binding-name>`来实现，也可以用于升级以前的基于接口的绑定名方式。
比如
> spring.cloud.stream.function.bindings.uppercase-in-0=input
在前面的例子中，你把uppercase-in-0绑定名映射成input，现在属性配置中的绑定名就变成了input，比如：
> spring.cloud.stream.bindings.input.destination=my-topic
当然，描述性的绑定名会提升可读性，
## 生产与消费消息
SCS应用就是简单的声明Function类型bean，当让在较早的版本中，你可以使用基于注解的配置，从3.x版本开始支持函数式的方式。
### 函数式支持
自从Spring Cloud Stream 2.1版本后，定义stream处理器改为使用内置的spring cloud function，他们可以被表示成Function、Supplier、Consumer类型的bean，为了指出哪些bean是绑定外部destination的，你必须提供`spring.cloud.function.definition`属性。
如果你只有Supplier、Function、Consumer类型的唯一的bean，你可以忽略`spring.cloud.function.definition`属性，因为这样的函数式的bean会被自动发现，最佳实践是，使用这个属性来避免混乱，有时候，自动发现的机制会出错，因为唯一的函数式的bean可能不是用于处理消息的，但是此时因为自动发现机制，它被绑定了，对于这种极少的场景，你可以禁用自动发现机制`spring.cloud.stream.function.autodetect`。
下面是一个例子
```java
@SpringBootApplication
public class MyFunctionBootApp {

	public static void main(String[] args) {
		SpringApplication.run(MyFunctionBootApp.class);
	}

	@Bean
	public Function<String, String> toUpperCase() {
		return s -> s.toUpperCase();
	}
}
```
在前面的例子中，我们定义了一个Function类型的bean，这个bean的名字叫做toUpperCase，作为一个消息处理器，它的输入与输入必须被绑定到外部binder的destination；默认情况下，绑定的名字分别是toUpperCase-in-0与toUpperCase-out-0；下面是几个简单的例子
使用Supplier作为source语义
```java
@SpringBootApplication
public static class SourceFromSupplier {

	@Bean
	public Supplier<Date> date() {
		return () -> new Date(12345L);
	}
}
```
使用Consumer作为sink语义
```java
@SpringBootApplication
public static class SinkFromConsumer {

	@Bean
	public Consumer<String> sink() {
		return System.out::println;
	}
}
```
### Suppliers(Sources)
Function与Consumer是的触发时机是非常清晰明了了的；它们是基于发送给他们绑定的destination的数据触发的，换句话说，它们是传统的事件驱动的组件。
然而，Supplier的触发方式是完全不同呢的，因为根据定义，它是数据的源头，它没有订阅任何输入的destination，因此，必须通过其他的机制触发；也存在一个Supplier实现的问题，Supplier的实现还存在一个问题，就是它是命令式（imperative）还是反应式（reactive）的会与supplier的触发方式直接相关。
考虑下面的例子：
```java
@SpringBootApplication
public static class SupplierConfiguration {

	@Bean
	public Supplier<String> stringSupplier() {
		return () -> "Hello from Supplier";
	}
}
```
前面的例子中的Supplier的bean在每次调用get()方法的时候都会返回一个字符串，然而，谁调用get方法呢？什么时候调用get方法呢？框架提供了一个默认的polling机制（这回答了who的问题），这个轮训机制会触发supplier的调用，并且默认情况下，每秒就会触发一次（回答了触发的时机），换句话说，上面的配置每秒就会产生一条消息，并且，每条消息都会被发送到output的destination中，想要了解更多的轮训机制的细节或者需要定制轮训的一些机制，可以仔细阅读Polling Configuration Propeties章节.
考虑一个不同的例子:
```java
@SpringBootApplication
public static class SupplierConfiguration {

    @Bean
    public Supplier<Flux<String>> stringSupplier() {
        return () -> Flux.fromStream(Stream.generate(new Supplier<String>() {
            @Override
            public String get() {
                try {
                    Thread.sleep(1000);
                    return "Hello from Supplier";
                } catch (Exception e) {
                    // ignore
                }
            }
        })).subscribeOn(Schedulers.elastic()).share();
    }
}
```
前面的Supplier bean采用了reactive的编程模式；与命令式的supplier不同，假设get方法的调用产生的是连续的消息流而不是一个单一的消息的话，它只会被触发一次。框架会识别到这种编程方式的不同并确保这样的supplier只会被触发一次。
然而，想象一个场景，你想从数据源拉取一些数据，并返回有限数量的数据流来表示结果集，reactive的编程模式对于这样的Supplier是完美的匹配机制，然而，由于结果集的有限的特性，这样的Supplier仍然需要周期性的调用。考虑下面的产生有限流的例子
```java
@SpringBootApplication
public static class SupplierConfiguration {

	@PollableBean
	public Supplier<Flux<String>> stringSupplier() {
		return () -> Flux.just("hello", "bye");
	}
}
```
bean本身被PollableBean注解（@Bean注解的子集）修饰，这个注解会通知框架，虽然Supplier是reactive的，但是仍然需要polled。
@PollableBean注解中有个splittable属性，这个属性会通知注解处理器，组件产生的结果必须被分片，因为这个属性默认是true，这意味着框架将拆分返回发送每个项目作为单独的消息。 如果这不是他想要的行为，您可以将其设置为 false，此时供应商将简单地返回生成的 Flux 而不会拆分它。
到目前为止，Supplier因为没有外部的事件驱动，所以是通过一个完全不同的poller机制推动的，这样可能具有一些无法预测的多线程的行为，虽然大多数时候线程机制的细节与函数的下游执行无关，但在某些情况下可能会出现问题，尤其是对于可能对线程亲和性有一定期望的集成框架。 例如，Spring Cloud Sleuth 依赖于存储在线程本地的跟踪数据。 对于这些情况，我们通过 StreamBridge 有另一种机制，用户可以在其中更好地控制线程机制。 您可以在将任意数据发送到输出（例如外部事件驱动源）部分中获得更多详细信息。
### Consumer(Reactive)
Reactive消费者有点特别，因为它有一个void的返回类型，leaving framework with no reference to subscribe to。你不需要写`Consumer<Flux<?>>`，而是写`Function<Flux<?>, Mono<Void>>`，在流的最后调用then操作。
```java
public Function<Flux<?>, Mono<Void>>consumer() {
	return flux -> flux.map(..).filter(..).then();
}
```
因为没有写Consumer，所以你需要记得订阅输入的Flux。
### Polling配置属性
下面是poll机制的相关的配置属性，这些属性都是以spring.cloud.stream.poller开头的：
- fixedDelay: 默认poller的固定的延迟，默认是1000ms;
- maxMessagesPerPoll: 默认poller每次轮询拉取的最大的消息数量，默认是1L
- cron: Cron Trigger的Cron表达式，默认是none
- initialDelay: 周期行的触发器的初始延迟，默认是0;
- timeUnit: 延迟的单位，默认是ms
比如`--spring.cloud.stream.poller.fixed-delay=2000`的设置表示poller的间隔是2s。
这些属性在3.2版本被遗弃了，转而使用Spring Integration的相关的配置，可以看`org.springframework.boot.autoconfigure.integration.IntegrationProperties.Poller`中细节。
### sending arbitrary data to an output（外部事件驱动源）
存在一些场景，实际的数据源可能是一些外部的系统，而不是binder，比如，数据产生的来源是一个REST API；我们如何为这样的数据源与函数式编程机制建立桥？SCS提供了2种机制，让我们详细了解下。
对于这2种机制，我们都是用一个标准的MVC API，通过StreamBridge机制将输入的请求转换成消息流。
```java
@SpringBootApplication
@Controller
public class WebSourceApplication {

	public static void main(String[] args) {
		SpringApplication.run(WebSourceApplication.class, "--spring.cloud.stream.source=toStream");
	}

	@Autowired
	private StreamBridge streamBridge;

	@RequestMapping
	@ResponseStatus(HttpStatus.ACCEPTED)
	public void delegateToSupplier(@RequestBody String body) {
		System.out.println("Sending " + body);
		streamBridge.send("toStream-out-0", body);
	}
}
```
这里，我们注入了一个StreamBridge类型的bean，这个bean可以让我们发送数据到output的binding，记住，前面的例子没有定义任何的源supplier；框架不需要事先就创建source binding；在函数式配置的应用中，binding都是启动时触发创建的；这样做也是OK的，这是因为，StreamBridge将会初始化不存在的output binding的创建工作（如有必要，自动配置destination），初始化是在第一次调用send(...)操作时发生，完成后会缓存binding，用于后续的复用（可以阅读[StreamBridge and Dynamic Destinations](https://docs.spring.io/spring-cloud-stream/docs/3.2.1/reference/html/spring-cloud-stream.html#_streambridge_and_dynamic_destinations)得到更详细的信息）。
然而，如果你想要在启动时就预先创建output binding，你可以使用`spring.cloud.stream.source`属性，你可以声明你的source的名字，提供的名字将会被作为创建一个source binding的触发器，所以在前面的那个例子里面，output binding的名字是toStream-out-0是与binding名字约定规则是一致的，你可以使用;号来表示多个source，比如`spring.cloud.stream.source=foo;bar`。
同时，streamBridge.send(...)方法发送的Object就是要发送的数据，这意味着，你可以发送POJO或者Message对象，发送的过程与使用Function或者Supplier的方式的发送过程是一致的，也就是说，output的类型转换，分区等都是一样的得到处理。
### StreamBridge and Dynamic Destinations
StreamBridge也可以用在这样的场景，output 的destination事先不知道是哪个。下面是一个例子
```java
@SpringBootApplication
@Controller
public class WebSourceApplication {

	public static void main(String[] args) {
		SpringApplication.run(WebSourceApplication.class, args);
	}

	@Autowired
	private StreamBridge streamBridge;

	@RequestMapping
	@ResponseStatus(HttpStatus.ACCEPTED)
	public void delegateToSupplier(@RequestBody String body) {
		System.out.println("Sending " + body);
		streamBridge.send("myDestination", body);
	}
}
```
正如你在前面的例子中看到的，这个例子与上上一个例子差不多，这个没有提供`spring.cloud.stream.source`属性，这里我们发送数据到myDestination，这个binding还不存在，因此这样的名字会被认为是动态destination。
Caching 动态的destination可能会造成内存泄漏，因为动态的destination可能非常多，为了控制这个，我们提供的自清除机制，默认去的缓存的大小是10个，这意味着，如果动态destination的大小超过10，那么超过的动态destination会被清除。你可以使用`spring.cloud.stream.dynamic-destination-cache-size`属性来设置cache的大小。
### StreamBridge中的Output Content Type
如果有必要，你可以提供自己的content type，send的重载方法可以设置content type，如果你发送Message类型的数据，它的content type将会是一致的.
### StreamBridge中使用特定的binder类型
SCS支持多种binder，比如，你可以从kafka接收数据或者发送数据到RabbitMQ。
对于多个binders场景的更多的信息，