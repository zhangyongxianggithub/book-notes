[TOC]
# overview
Spring for Apache Kafka项目将Spring概念应用到基于Kafka的消息解决方案的开发中。我们提供一个一个`template`作为发送消息的高级抽象组件，我们也支持消息驱动的·POJOs。
# Introduction
参考文档的第一部分是Spring Kafka的概述，重要的概念与一些代码片段能帮助你启动项目并尽可能快速的运行。
## Quick Tour
**前提条件**: 你必须首先安装并运行Kafka，然后必须要Spring Kafka的相关jar出现在classpath中，添加依赖
```xml
<dependency>
  <groupId>org.springframework.kafka</groupId>
  <artifactId>spring-kafka</artifactId>
  <version>3.1.2</version>
</dependency>
```
当使用Spring Boot时，请忽略版本号，Spring Boot会自动选择一个与你的Boot兼容的版本。
```xml
<dependency>
  <groupId>org.springframework.kafka</groupId>
  <artifactId>spring-kafka</artifactId>
</dependency>
```
### Getting Started
下面时一个最小的消费者应用
```java
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public NewTopic topic() {
        return TopicBuilder.name("topic1")
                .partitions(10)
                .replicas(1)
                .build();
    }

    @KafkaListener(id = "myId", topics = "topic1")
    public void listen(String in) {
        System.out.println(in);
    }

}
```
application.properties的文件内容如下:
>spring.kafka.consumer.auto-offset-reset=earliest
`NewTopic`bean会创建topic，如果topic已经存在则不需要这个。
下面时一个Producer的程序
```java
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public NewTopic topic() {
        return TopicBuilder.name("topic1")
                .partitions(10)
                .replicas(1)
                .build();
    }

    @Bean
    public ApplicationRunner runner(KafkaTemplate<String, String> template) {
        return args -> {
            template.send("topic1", "test");
        };
    }

}
```
下面是一个不使用Spring Boot的应用的例子，它有一个`Consumer`与一个`Producer`:
```java
public class Sender {

    public static void main(String[] args) {
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(Config.class);
        context.getBean(Sender.class).send("test", 42);
    }

    private final KafkaTemplate<Integer, String> template;

    public Sender(KafkaTemplate<Integer, String> template) {
        this.template = template;
    }

    public void send(String toSend, int key) {
        this.template.send("topic1", key, toSend);
    }

}

public class Listener {

    @KafkaListener(id = "listen1", topics = "topic1")
    public void listen1(String in) {
        System.out.println(in);
    }

}

@Configuration
@EnableKafka
public class Config {

    @Bean
    ConcurrentKafkaListenerContainerFactory<Integer, String>
                        kafkaListenerContainerFactory(ConsumerFactory<Integer, String> consumerFactory) {
        ConcurrentKafkaListenerContainerFactory<Integer, String> factory =
                                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        return factory;
    }

    @Bean
    public ConsumerFactory<Integer, String> consumerFactory() {
        return new DefaultKafkaConsumerFactory<>(consumerProps());
    }

    private Map<String, Object> consumerProps() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "group");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, IntegerDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        // ...
        return props;
    }

    @Bean
    public Sender sender(KafkaTemplate<Integer, String> template) {
        return new Sender(template);
    }

    @Bean
    public Listener listener() {
        return new Listener();
    }

    @Bean
    public ProducerFactory<Integer, String> producerFactory() {
        return new DefaultKafkaProducerFactory<>(senderProps());
    }

    private Map<String, Object> senderProps() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.LINGER_MS_CONFIG, 10);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, IntegerSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        //...
        return props;
    }

    @Bean
    public KafkaTemplate<Integer, String> kafkaTemplate(ProducerFactory<Integer, String> producerFactory) {
        return new KafkaTemplate<>(producerFactory);
    }

}
```
# Reference
参考文档的这个部分详细描述了构成了Spring for kafka的不同的组件。[Using Spring for Apache Kafka](https://docs.spring.io/spring-kafka/reference/kafka.html)章节包含了使用Spring开发Kafka应用的核心类。
## Using Spring for Apache Kafka
这个章节提供了详细的使用Spring Kafka的重要部分的说明解释。
### Connecting to Kafka
- KafkaAdmin，see [Configuring Topics](https://docs.spring.io/spring-kafka/reference/kafka/configuring-topics.html)
- ProducerFactory, see [Sending Messages](https://docs.spring.io/spring-kafka/reference/kafka/sending-messages.html)
- ConsumerFactory, see [Receiving Messages](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages.html)

从2.5版本开始，他们都继承`KafkaResourceFactory`，这样可以在运行时动态更改bootstrap servers，只需要在他们的配置中添加一个`Supplier<String>`，比如`setBootstrapServersSupplier(() -> …​)`，每次建立新的连接时这个方法会被调用来获取服务器列表。 `Consumers`与`Producers`通常存活期是很长的，为了关闭`Producers`调用`DefaultKafkaProducerFactory`的`reset()`方法，关闭`Consumerss`调用`KafkaListenerEndpointRegistry`的`stop()`与`start()`方法，或者调用listener container bean的`stop()`与`start()`方法。为了方便，框架也提供了`ABSwitchCluster`支持2个服务器集合，其中之一在任何时刻都是active的，配置`ABSwitchCluster`通过调用`setBootstrapServersSupplier()`将其添加到producer、consumer工厂与KafkaAdmin内，当你想要切换时，调用producer工厂的`primary()`或者`second()`方法后调用`reset()`来建立新的连接。对于消费者，`stop()`/`start()`所有的listener容器，当使用`@KafkaListener`时，需要`stop()`/`start()``KafkaListenerEndpointRegistry`bean对象。
#### Factory Listeners
从2.5版本开始，`DefaultKafkaProducerFactory`与`DefaultKafkaConsumerFactory`可以配置一个`Listener`来接收producer或者consumer创建或者关闭的通知。
```java
interface Listener<K, V> {
    default void producerAdded(String id, Producer<K, V> producer) {
    }
    default void producerRemoved(String id, Producer<K, V> producer) {
    }
}
```
```java
interface Listener<K, V> {
    default void consumerAdded(String id, Consumer<K, V> consumer) {
    }
    default void consumerRemoved(String id, Consumer<K, V> consumer) {
    }
}
```
id=工厂bean的名字+.+client-id属性值构成。这些listeners可以用来为新创建的客户端创建并绑定一个Micrometer `KafkaClientMetrics`实例，在客户端关闭时，也需要同时关闭`KafkaClientMetrics`。框架已经提供了这种实现的listener，具体参考[Micrometer Native Metrics](https://docs.spring.io/spring-kafka/reference/kafka/micrometer.html#micrometer-native)
### Configuring Topics
如果你定义了一个`KafkaAdmin`的bean，它可以自动添加topics到broker，为了做到这一点，你可以为每个topic添加一个`NewTopic`Bean到上下文中，2.3版本引入了一个新的类`TopicBuilder`来更方便的创建这些Bean，下面是一个例子:
```java
@Bean
public KafkaAdmin admin() {
    Map<String, Object> configs = new HashMap<>();
    configs.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
    return new KafkaAdmin(configs);
}

@Bean
public NewTopic topic1() {
    return TopicBuilder.name("thing1")
            .partitions(10)
            .replicas(3)
            .compact()
            .build();
}

@Bean
public NewTopic topic2() {
    return TopicBuilder.name("thing2")
            .partitions(10)
            .replicas(3)
            .config(TopicConfig.COMPRESSION_TYPE_CONFIG, "zstd")
            .build();
}

@Bean
public NewTopic topic3() {
    return TopicBuilder.name("thing3")
            .assignReplicas(0, List.of(0, 1))
            .assignReplicas(1, List.of(1, 2))
            .assignReplicas(2, List.of(2, 0))
            .config(TopicConfig.COMPRESSION_TYPE_CONFIG, "zstd")
            .build();
}
```
从2.6版本开始，你可以忽略`partitions()`与`replicas()`，将会使用broker默认的配置。broker的版本至少是2.4.0来支持这一特性。
```java
@Bean
public NewTopic topic4() {
    return TopicBuilder.name("defaultBoth")
            .build();
}
@Bean
public NewTopic topic5() {
    return TopicBuilder.name("defaultPart")
            .replicas(1)
            .build();
}
@Bean
public NewTopic topic6() {
    return TopicBuilder.name("defaultRepl")
            .partitions(3)
            .build();
}
```
从2.7版本开始，你可以声明多个`NewTopic`
```java
@Bean
public KafkaAdmin.NewTopics topics456() {
    return new NewTopics(
            TopicBuilder.name("defaultBoth")
                .build(),
            TopicBuilder.name("defaultPart")
                .replicas(1)
                .build(),
            TopicBuilder.name("defaultRepl")
                .partitions(3)
                .build());
}
```
当使用Spring Boot时，会自动注册一个`KafkaAdmin`Bean，你只需要定义`NewTopic`的Bean。缺省情况下，如果broker不可用，一个message会打印到日志，但是程序会继续运行。你可以手动调用admin的`initialize()`方法来稍后重试，如果你想要终止程序，将admin的`fatalIfBrokerNotAvailable`属性设置为true，程序将会失败退出。从2.7版本开始，`KafkaAdmin`提供了方法在运行时创建并检验topics。
- `createOrModifyTopics`
- `describeTopics`

更多的高级特性，你可以直接使用`AdminClient`，下面是一个例子:
```java
@Autowired
private KafkaAdmin admin;
    AdminClient client = AdminClient.create(admin.getConfigurationProperties());
    client.close();
```
从2.9.10，3.0.9版本开始，你可以提供一个`Predicate<NewTopic>`可以用来是否要创建一个`NewTopic`，当你有多个指向不同集群的`KafkaAdmin`对象的时候，你可能希望每个admin创建其自己的topics。
```java
admin.setCreateOrModifyTopic(nt -> !nt.name().equals("dontCreateThisOne"));
```
## Sending Messages
如何发送消息
### Using `KafkaTemplate`
`KafkaTemplate`包含了一个生产者，提供了方便的方法发送数据到Kafka的topis，下面是相关的方法
```java
CompletableFuture<SendResult<K, V>> sendDefault(V data);

CompletableFuture<SendResult<K, V>> sendDefault(K key, V data);

CompletableFuture<SendResult<K, V>> sendDefault(Integer partition, K key, V data);

CompletableFuture<SendResult<K, V>> sendDefault(Integer partition, Long timestamp, K key, V data);

CompletableFuture<SendResult<K, V>> send(String topic, V data);

CompletableFuture<SendResult<K, V>> send(String topic, K key, V data);

CompletableFuture<SendResult<K, V>> send(String topic, Integer partition, K key, V data);

CompletableFuture<SendResult<K, V>> send(String topic, Integer partition, Long timestamp, K key, V data);

CompletableFuture<SendResult<K, V>> send(ProducerRecord<K, V> record);

CompletableFuture<SendResult<K, V>> send(Message<?> message);

Map<MetricName, ? extends Metric> metrics();

List<PartitionInfo> partitionsFor(String topic);

<T> T execute(ProducerCallback<K, V, T> callback);

<T> T executeInTransaction(OperationsCallback<K, V, T> callback);

// Flush the producer.
void flush();

interface ProducerCallback<K, V, T> {

    T doInKafka(Producer<K, V> producer);

}

interface OperationsCallback<K, V, T> {

    T doInOperations(KafkaOperations<K, V> operations);

}
```
在3.0版本，前面提到的返回`ListenableFuture`的方法已经改为返回`CompletableFuture`，2.9版本添加了一个方法`usingCompletableFuture()`这个会提供返回`CompletableFuture`的发送方法。`sendDefault`API需要提供一个缺省的topic。API支持一个叫做`timestamp`的参数并存储到record中，这个时间戳如何存储依赖topic配置中时间戳类型配置。如果topic配置使用`CREATE_TIME`,record携带用户提供的事件戳(不存在则自动生成)，如果topic配置使用`LOG_APPEND_TIME`，用户提供的时间戳会被忽略，broker添加本地的broker时间作为record的时间戳。`metrics`与`partitionsFor`方法实际就是底层库的Producer上的同样的方法，`executr`提供了对底层使用的Producer的访问接口。为了使用template，你可以配置一个producer factory，并在template的构造函数提供它，如下所示:
```java
@Bean
public ProducerFactory<Integer, String> producerFactory() {
    return new DefaultKafkaProducerFactory<>(producerConfigs());
}

@Bean
public Map<String, Object> producerConfigs() {
    Map<String, Object> props = new HashMap<>();
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, IntegerSerializer.class);
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    // See https://kafka.apache.org/documentation/#producerconfigs for more properties
    return props;
}

@Bean
public KafkaTemplate<Integer, String> kafkaTemplate() {
    return new KafkaTemplate<Integer, String>(producerFactory());
}
```
从2.5版本开始，你可以覆盖factory中的`ProducerConfig`属性，在创建template时使用不同的生产者属性
```java
@Bean
public KafkaTemplate<String, String> stringTemplate(ProducerFactory<String, String> pf) {
    return new KafkaTemplate<>(pf);
}

@Bean
public KafkaTemplate<String, byte[]> bytesTemplate(ProducerFactory<String, byte[]> pf) {
    return new KafkaTemplate<>(pf,
            Collections.singletonMap(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class));
}
```
记住，`ProducerFactory<?, ?>`类型的bean(比如Spring Boot自动创建的)，可以通过不同的泛型类型参数引用，你也可以使用标准的`<bean/>`定义配置template，当你使用带有`Message<?>`参数的方法时，需要在消息头提供topic、partition、key与时间戳信息。具体就是
- `KafkaHeaders.TOPIC`
- `KafkaHeaders.PARTITION`
- `KafkaHeaders.KEY`
- `KafkaHeaders.TIMESTAMP`

message的payload就是数据。可选的，你可以为`KafkaTemplate`配置一个`ProducerListener`来执行异步回调，不需要等待`Future`执行完，下面的列表是`ProducerListener`接口的定义:
```java
public interface ProducerListener<K, V> {

    void onSuccess(ProducerRecord<K, V> producerRecord, RecordMetadata recordMetadata);

    void onError(ProducerRecord<K, V> producerRecord, RecordMetadata recordMetadata,
            Exception exception);

}
```
缺省情况下，template已经配置了一个`LoggingProducerListener`，主要的作用就是发生错误时打印错误，成功时什么都不做。为了方便，接口都提供了默认实现，你可以只实现需要的方法逻辑。发送的方法都返回`CompletableFuture<SendResult>`你可以注册回调监听器来异步的接收发送的结果。下面是一个例子:
```java
CompletableFuture<SendResult<Integer, String>> future = template.send("myTopic", "something");
future.whenComplete((result, ex) -> {
    ...
});
```
`SendResult`有2个属性，一个`ProducerRecord`一个`RecordMetadata`。Throwable可以被转型成一个`KafkaProducerException`异常，它的`failedProducerRecord`属性包含了失败的record。如果你想要阻塞发送线程来等待结果，可以直接`get()`，如果你设置了`linger.ms`，在等待前需要调用`flush()`，或者template的构造函数支持一个`autoFlush`参数，可以设置为true，在每次send前template都会调用`flush()`，只有在设置`linger.ms`的情况下需要立即发送一个partial batch时才需要flush。下面是一个发送的例子:
```java
public void sendToKafka(final MyOutputData data) {
    final ProducerRecord<String, String> record = createRecord(data);

    CompletableFuture<SendResult<Integer, String>> future = template.send(record);
    future.whenComplete((result, ex) -> {
        if (ex == null) {
            handleSuccess(data);
        }
        else {
            handleFailure(data, record, ex);
        }
    });
}
public void sendToKafka(final MyOutputData data) {
    final ProducerRecord<String, String> record = createRecord(data);

    try {
        template.send(record).get(10, TimeUnit.SECONDS);
        handleSuccess(data);
    }
    catch (ExecutionException e) {
        handleFailure(data, record, e.getCause());
    }
    catch (TimeoutException | InterruptedException e) {
        handleFailure(data, record, e);
    }
}
```
注意，`ExecutionException`的cause是`KafkaProducerException`
### Using `RoutingKafkaTemplate`
从2.5版本开始，你可以使用`RoutingKafkaTemplate`在运行时基于destination topic 名字选择要使用的生产者。 routing template不支持事务、`execute`、`flush`、`metrics`操作，因为你topic是未知的，而这些操作需要topic。template需要一个`java.util.regex.Pattern`到`ProducerFactory<Object, Object>`的map对象，map应该是有序的，因为是按序遍历。下面是一个使用一个template发送不同的topic的例子，每个topic使用不同的value serializer。
```java
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public RoutingKafkaTemplate routingTemplate(GenericApplicationContext context,
            ProducerFactory<Object, Object> pf) {

        // Clone the PF with a different Serializer, register with Spring for shutdown
        Map<String, Object> configs = new HashMap<>(pf.getConfigurationProperties());
        configs.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class);
        DefaultKafkaProducerFactory<Object, Object> bytesPF = new DefaultKafkaProducerFactory<>(configs);
        context.registerBean("bytesPF", DefaultKafkaProducerFactory.class, () -> bytesPF);

        Map<Pattern, ProducerFactory<Object, Object>> map = new LinkedHashMap<>();
        map.put(Pattern.compile("two"), bytesPF);
        map.put(Pattern.compile(".+"), pf); // Default PF with StringSerializer
        return new RoutingKafkaTemplate(map);
    }

    @Bean
    public ApplicationRunner runner(RoutingKafkaTemplate routingTemplate) {
        return args -> {
            routingTemplate.send("one", "thing1");
            routingTemplate.send("two", "thing2".getBytes());
        };
    }

}
```
另一种技术可以实现类似的结果，还具有将不同类型发送到同一主题的额外能力。具体参考[Delegating Serializer and Deserializer](https://docs.spring.io/spring-kafka/reference/kafka/serdes.html#delegating-serialization)
### Using `DefaultKafkaProducerFactory`
发送消息需要一个`ProducerFactory`来创建生产者。如果不使用事务，`DefaultKafkaProducerFactory`会创建一个所有客户端使用的单例生产者。这是kafka官方推荐的方式。但是如果你调用template的`flush()`方法，这回造成使用同一个producer的其他线程的客户端阻塞。从2.3版本开始，`DefaultKafkaProducerFactory`有个新的属性`producerPerThread`，当设置为`true`，工厂将会为每个线程都创建一个生产者。当`producerPerThread=true`后，当生产者不在被需要，用户代码需要调用工厂上的`closeThreadBoundProducer()`方法，这会关闭生产者并从`ThreadLocal`中移除生产者。调用`reset()`或者`destroy()`不会清理这些生产者。当创建一个`DefaultKafkaProducerFactory`时，key/value的`Serializer`可以从配置中获取，也可以直接传递`Serializer`对象到`DefaultKafkaProducerFactory`的构造函数来创建，可以复用`Serializer`，你还可以提供`Supplier<Serializer>`用来为每个producer创建各自的`Serializer`对象。
```java
@Bean
public ProducerFactory<Integer, CustomValue> producerFactory() {
    return new DefaultKafkaProducerFactory<>(producerConfigs(), null, () -> new CustomValueSerializer());
}

@Bean
public KafkaTemplate<Integer, CustomValue> kafkaTemplate() {
    return new KafkaTemplate<Integer, CustomValue>(producerFactory());
}
```
从2.5.10版本开始，工厂创建后，你还可以更新生产者的属性。有时候有用，比如你要更新SSL的证书位置等情况。变更不会影响到已创建的生产者实例。调用`reset()`会关闭现有的生产者实例并使用新的属性创建信息的生产者。但是能不能将事务的生产者工厂转变为非事务的，也不能把非事务的转变为事务的。新的变更属性的方法
```java
void updateConfigs(Map<String, Object> updates);

void removeConfig(String configKey);
```
从2.8版本开始，如果你提供序列化对象到生产者，工厂会调用`configure()`方法来配置它们为相关的配置属性。
### Using `ReplyingKafkaTemplate`
2.1.3版本引入了一个`KafkaTemplate`的子类来提供request/reply语义。这个类被命名为`ReplyingKafkaTemplate`，有2个额外的方法:
```java
RequestReplyFuture<K, V, R> sendAndReceive(ProducerRecord<K, V> record);

RequestReplyFuture<K, V, R> sendAndReceive(ProducerRecord<K, V> record,
    Duration replyTimeout);
```
参考[Request/Reply with Message<?>](https://docs.spring.io/spring-kafka/reference/kafka/sending-messages.html#exchanging-messages)。结果是一个`CompletableFuture`，结果有一个`sendFuture`属性是`KafkaTemplate.send()`的结果。从3.0版本开始，从这些方法返回的futures变更为`CompletableFuture`而不是`ListenableFuture`。如果使用了第一个方法没有设置`replyTimeout`参数，那么会使用默认的`defaultReplyTimeout`属性设置的值(5秒)。从2.8.8版本开始，template有一个新方法`waitForAssignment`。当reply container配置为`auto.offset.reset=latest`这会很有用，可以to avoid sending a request and a reply sent before the container is initialized.当使用手动分区分配(无组管理)时，等待时间必须大于容器的`pollTimeout`属性，因为直到第一次轮询完成后才会发送通知。下面是一个使用的例子:
```java
@SpringBootApplication
public class KRequestingApplication {

    public static void main(String[] args) {
        SpringApplication.run(KRequestingApplication.class, args).close();
    }

    @Bean
    public ApplicationRunner runner(ReplyingKafkaTemplate<String, String, String> template) {
        return args -> {
            if (!template.waitForAssignment(Duration.ofSeconds(10))) {
                throw new IllegalStateException("Reply container did not initialize");
            }
            ProducerRecord<String, String> record = new ProducerRecord<>("kRequests", "foo");
            RequestReplyFuture<String, String, String> replyFuture = template.sendAndReceive(record);
            SendResult<String, String> sendResult = replyFuture.getSendFuture().get(10, TimeUnit.SECONDS);
            System.out.println("Sent ok: " + sendResult.getRecordMetadata());
            ConsumerRecord<String, String> consumerRecord = replyFuture.get(10, TimeUnit.SECONDS);
            System.out.println("Return value: " + consumerRecord.value());
        };
    }

    @Bean
    public ReplyingKafkaTemplate<String, String, String> replyingTemplate(
            ProducerFactory<String, String> pf,
            ConcurrentMessageListenerContainer<String, String> repliesContainer) {

        return new ReplyingKafkaTemplate<>(pf, repliesContainer);
    }

    @Bean
    public ConcurrentMessageListenerContainer<String, String> repliesContainer(
            ConcurrentKafkaListenerContainerFactory<String, String> containerFactory) {

        ConcurrentMessageListenerContainer<String, String> repliesContainer =
                containerFactory.createContainer("kReplies");
        repliesContainer.getContainerProperties().setGroupId("repliesGroup");
        repliesContainer.setAutoStartup(false);
        return repliesContainer;
    }

    @Bean
    public NewTopic kRequests() {
        return TopicBuilder.name("kRequests")
            .partitions(10)
            .replicas(2)
            .build();
    }

    @Bean
    public NewTopic kReplies() {
        return TopicBuilder.name("kReplies")
            .partitions(10)
            .replicas(2)
            .build();
    }

}
```
可以使用SpringBoot自动配置的容器工厂来创建reply container。如果你正在为reply使用一个deserializer，你可以使用`ErrorHandlingDeserializer`代理你的反序列化器。 这样，如果`RequestReplyFuture`异常结束，你可以获得`ExecutionException`异常，从2.6.7版本开始，除了检测`DeserializationException`，template也可以调用`replyErrorChecker`函数，如果它返回了一个异常，future就是异常结束的。下面是一个例子:
```java
template.setReplyErrorChecker(record -> {
    Header error = record.headers().lastHeader("serverSentAnError");
    if (error != null) {
        return new MyException(new String(error.value()));
    }
    else {
        return null;
    }
});

...

RequestReplyFuture<Integer, String, String> future = template.sendAndReceive(record);
try {
    future.getSendFuture().get(10, TimeUnit.SECONDS); // send ok
    ConsumerRecord<Integer, String> consumerRecord = future.get(10, TimeUnit.SECONDS);
    ...
}
catch (InterruptedException e) {
    ...
}
catch (ExecutionException e) {
    if (e.getCause instanceof MyException) {
        ...
    }
}
catch (TimeoutException e) {
    ...
}
```
template设置了一个header(`KafkaHeaders.CORRELATION_ID`)，由服务端透明返回的。下面使用`@KafkaListener`响应这个request/reply
```java
@SpringBootApplication
public class KReplyingApplication {

    public static void main(String[] args) {
        SpringApplication.run(KReplyingApplication.class, args);
    }

    @KafkaListener(id="server", topics = "kRequests")
    @SendTo // use default replyTo expression
    public String listen(String in) {
        System.out.println("Server received: " + in);
        return in.toUpperCase();
    }

    @Bean
    public NewTopic kRequests() {
        return TopicBuilder.name("kRequests")
            .partitions(10)
            .replicas(2)
            .build();
    }

    @Bean // not required if Jackson is on the classpath
    public MessagingMessageConverter simpleMapperConverter() {
        MessagingMessageConverter messagingMessageConverter = new MessagingMessageConverter();
        messagingMessageConverter.setHeaderMapper(new SimpleKafkaHeaderMapper());
        return messagingMessageConverter;
    }

}
```
`@KafkaListener`基础设施回显correlation ID并决定reply topic。查看[Forwarding Listener Results using @SendTo](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/annotation-send-to.html)获取sending replies的更多信息。template使用默认的header`KafKaHeaders.REPLY_TOPIC`来指出reply发送的topic。从2.2版本开始，template尝试检测reply容器中配置的topic与partition，如果容器配置坚挺一个topic或者监听一个`TopicPartitionOffset`，那么这些设置将会被用来设置reply headers。如果容器没有配置，开发者必须自己设置reply headers。在这个场景下，容器初始化时会打印一个`INFO`日志消息，下面的例子使用了`KafkaHeaders.REPLY_TOPIC`:
```java
record.headers().add(new RecordHeader(KafkaHeaders.REPLY_TOPIC, "kReplies".getBytes()));
```
如果你配置了一个reply的`TopicPartitionOffset`，你可以在多个templat中使用同一个reply topic，只需要他们监听不同的partition。如果配置了一个reply topic，每个实例必须使用不同的`group.id`，在这个场景下，所有的实例都接收每条reply，但是只有发送request的实例可以接收到correlation ID，在auto-scalling方面非常有用，但是会额外的消耗一些网络流量与丢弃不想要的reply的开销。当你使用这个设置，我们建议你设置`sharedReplyTopic=true`，这会将非预期的reply的logging level从，默认的ERROR降级为DEBUG。下面是一个配置reply容器来使用一共享的reply的topic的例子:
```java
@Bean
public ConcurrentMessageListenerContainer<String, String> replyContainer(
        ConcurrentKafkaListenerContainerFactory<String, String> containerFactory) {

    ConcurrentMessageListenerContainer<String, String> container = containerFactory.createContainer("topic2");
    container.getContainerProperties().setGroupId(UUID.randomUUID().toString()); // unique
    Properties props = new Properties();
    props.setProperty(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest"); // so the new group doesn't get old replies
    container.getContainerProperties().setKafkaConsumerProperties(props);
    return container;
}
```
如果你有多个client实例并且没有像前面章节讨论的那样进行配置，那么每个实例都需要一个专门的reply topic。还有一种方式是设置`KafkaHeaders.REPLY_PARTITION`并为每个实例使用不同的partition。header是一个4byte的整数，服务端必须使用这个header来将reply发送到正确的partition(在`@KafkaListener`中实现)，在这种场景下，reply容器不能使用Kafka的组管理特性并且必须配置为监听一个特定的partition(通过在`ContainerProperties`中使用`TopicPartitionOffset`)，`DefaultKafkaHeaderMapper`需要classpath中存在jackson库，如果没有，那么message converter中则没有header mapper，那么必须要使用一个`SimpleKafkaHeaderMapper`配置`MessagingMessageConverter`。默认情况下，会用到个header:
- `KafkaHeaders.CORRELATION_ID`: 用来将reply关联到一个request
- `KafkaHeaders.REPLY_TOPIC`: 用来通知server端，reply发送的topic
- `KafkaHeaders.REPLY_PARTITION`: 可选的，用来通知server端，reply发送的topic的partition

这些header都是`@KafkaListener`用来发送reply的，从2.3版本开始，你可以自定义这些header的name，template有3个属性`correlationHeaderName`, `replyTopicHeaderName`与`replyPartitionHeaderName`来设置自定义名字，当你的应用不是一个Spring应用或者不使用`@KafkaListener`时会很有用。如果request应用不是一个spring应用并且在header中设置了correlation信息，你可以在listener container factory配置一个自定义的`correlationHeaderName`属性。
#### Request/Reply with `Message<?>s`
2.7版本后，`ReplyingKafkaTemplate`添加了发送/接收spring-messaging的`Message<?>`抽象的功能:
```java
RequestReplyMessageFuture<K, V> sendAndReceive(Message<?> message);
<P> RequestReplyTypedMessageFuture<K, V, P> sendAndReceive(Message<?> message,
        ParameterizedTypeReference<P> returnType);
```
这会使用template默认的`replyTimeout`，所有的方法也有支持设置超时的方法重载版本。如果消费者的`Deserializer`或template的 `MessageConverter`可以无需任何附加信息(不论是配置的还是reply消息中的type metadata)转换payload，使用第一个方法。如果需要提供返回类型的类型信息以协助message converter，请使用第二个方法。这也允许template接收不同的类型的message，即使reply中没有type metadata，例如当服务器端不是Spring应用程序时。下面是后者的一个例子:
```java
@Bean
ReplyingKafkaTemplate<String, String, String> template(
        ProducerFactory<String, String> pf,
        ConcurrentKafkaListenerContainerFactory<String, String> factory) {

    ConcurrentMessageListenerContainer<String, String> replyContainer =
            factory.createContainer("replies");
    replyContainer.getContainerProperties().setGroupId("request.replies");
    ReplyingKafkaTemplate<String, String, String> template =
            new ReplyingKafkaTemplate<>(pf, replyContainer);
    template.setMessageConverter(new ByteArrayJsonMessageConverter());
    template.setDefaultTopic("requests");
    return template;
}
```
```java
RequestReplyTypedMessageFuture<String, String, Thing> future1 =
        template.sendAndReceive(MessageBuilder.withPayload("getAThing").build(),
                new ParameterizedTypeReference<Thing>() { });
log.info(future1.getSendFuture().get(10, TimeUnit.SECONDS).getRecordMetadata().toString());
Thing thing = future1.get(10, TimeUnit.SECONDS).getPayload();
log.info(thing.toString());

RequestReplyTypedMessageFuture<String, String, List<Thing>> future2 =
        template.sendAndReceive(MessageBuilder.withPayload("getThings").build(),
                new ParameterizedTypeReference<List<Thing>>() { });
log.info(future2.getSendFuture().get(10, TimeUnit.SECONDS).getRecordMetadata().toString());
List<Thing> things = future2.get(10, TimeUnit.SECONDS).getPayload();
things.forEach(thing1 -> log.info(thing1.toString()));
```
### Reply Type `Message<?>`
当`@KafkaListener`返回一个`Message<?>`，在2.5版本以前，你需要自己设置reply topic与correlation id头信息，比如下面的例子:
```java
@KafkaListener(id = "requestor", topics = "request")
@SendTo
public Message<?> messageReturn(String in) {
    return MessageBuilder.withPayload(in.toUpperCase())
            .setHeader(KafkaHeaders.TOPIC, replyTo)
            .setHeader(KafkaHeaders.KEY, 42)
            .setHeader(KafkaHeaders.CORRELATION_ID, correlation)
            .build();
}
```
从2.5版本开始，框架将会自动检测这些header是否存在并自动设置头信息，如果没有topic设置则检测`@SendTo`注解中的topic或者输入message的`KafkaHeaders.REPLY_TOPIC`头信息，如果输入的message中存在`KafkaHeaders.CORRELATION_ID`与`KafkaHeaders.REPLY_PARTITION`则自动设置到reply消息的消息头。
```java
@KafkaListener(id = "requestor", topics = "request")
@SendTo  // default REPLY_TOPIC header
public Message<?> messageReturn(String in) {
    return MessageBuilder.withPayload(in.toUpperCase())
            .setHeader(KafkaHeaders.KEY, 42)
            .build();
}
```
### Aggregating Multiple Replies
`ReplyingKafkaTemplate`严格适用于单个请求/回复场景。对于单个消息的多个接收者返回回复的情况，您可以使用 `AggregatingReplyingKafkaTemplate`。这是Scatter-Gather企业集成模式[https://www.enterpriseintegrationpatterns.com/patterns/messaging/BroadcastAggregate.html]的客户端实现。与`ReplyingKafkaTemplate`类似，`AggregatingReplyingKafkaTemplate`构造函数接收一个producer工厂与一个listener container(用来接收replies)，还有第三个参数`BiPredicate<List<ConsumerRecord<K, R>>, Boolean> releaseStrategy`，每次接收到一个reply的时候执行，当`predicate`返回true，ConsumerRecords将成为`sendAndReceive`方法返回的`Future`的结果。还有一个附加属性 `returnPartialOnTimeout`(默认false)。当此项设置为true时，部分结果将正常完成`future`(只要至少收到一条回复记录)，而不是使用 `KafkaReplyTimeoutException`来完成`future`。
## Receiving Messages
接收消息需要首先配置一个`MessageListenerContainer`，然后提供一个message listener或者使用`@KafkaListener`注解。
### Message Listeners
当你使用一个[message listener container](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/message-listener-container.html)时，你必须提供一个listener来接收数据，目前有8个接口用来做message listener，如下:
```java
public interface MessageListener<K, V> {// 使用这个接口来处理单个ConsumerRecord，ConsumerRecord是采用Kafka消费者的poll()操作接收到的，这个接口适用于使用auto-commit或者container-managed的commit methods的情况
    void onMessage(ConsumerRecord<K, V> data);
}
public interface AcknowledgingMessageListener<K, V> {
//使用manual commit methods时用来处理从Kafka消费者poll()操作接收的单个ConsumerRecord
    void onMessage(ConsumerRecord<K, V> data, Acknowledgment acknowledgment);
}
public interface ConsumerAwareMessageListener<K, V> extends MessageListener<K, V> {
//使用auto-commit或者container-managed commit methods其中之一时，用来处理从Kafka消费者poll()操作获取的单个ConsumerRecord，提供对Consumer对象的访问
    void onMessage(ConsumerRecord<K, V> data, Consumer<?, ?> consumer);
}
public interface AcknowledgingConsumerAwareMessageListener<K, V> extends MessageListener<K, V> {
//使用manual commit methods时用来处理从Kafka消费者poll()操作获取的单个ConsumerRecord，提供对Consumer对象的访问
    void onMessage(ConsumerRecord<K, V> data, Acknowledgment acknowledgment, Consumer<?, ?> consumer);
}
public interface BatchMessageListener<K, V> {
// 使用auto-commit或者container-managed commit methods其中之一时，用来处理从Kafka消费者的poll()操作接收的所有的ConsumerRecord实例，当使用这个接口时不支持AckMode.RECORD，因为listener获取的是完整的batch
    void onMessage(List<ConsumerRecord<K, V>> data);
}
public interface BatchAcknowledgingMessageListener<K, V> {
//使用manual commit methods时，用来处理从Kafka消费者的poll()操作接收的所有的ConsumerRecord实例
    void onMessage(List<ConsumerRecord<K, V>> data, Acknowledgment acknowledgment);
}
public interface BatchConsumerAwareMessageListener<K, V> extends BatchMessageListener<K, V> {
// 使用auto-commit或者container-managed commit methods其中之一时，用来处理从Kafka消费者的poll()操作接收的所有的ConsumerRecord实例，当使用这个接口时不支持AckMode.RECORD，因为listener获取的是完整的batch，提供对Consumer对象的访问
    void onMessage(List<ConsumerRecord<K, V>> data, Consumer<?, ?> consumer);
}
public interface BatchAcknowledgingConsumerAwareMessageListener<K, V> extends BatchMessageListener<K, V> {
// 使用manual commit methods时，用来处理从Kafka消费者的poll()操作接收的所有的ConsumerRecord实例，提供对Consumer对象的访问
    void onMessage(List<ConsumerRecord<K, V>> data, Acknowledgment acknowledgment, Consumer<?, ?> consumer);
}
```
`Consumer`对象不是线程安全的，必须在调用listener的线上上调用它的方法。你不应该执行任何可能影响到listener中消费者的positions或者committed offsets的`Consumer<?,?>`方法，container需要管理这些信息。
### Message Listener Containers
提供了2个`MessageListenerContainer`实现
- `KafkaMessageListenerContainer`
- `ConcurrentMessageListenerContainer`

## Serialization, Deserialization, Message Conversion
### Delegating Serializer and Deserializer
#### Using Headers
2.3版本引入了`DelegatingSerializer`与`DelegatingDeserializer`，允许生产与消费不同类型的key/value的records。生产者必须设置一个Header`DelegatingSerializer.VALUE_SERIALIZATION_SELECTOR`为一个selector value，用来选择使用哪一个serializer来序列化value，`DelegatingSerializer.KEY_SERIALIZATION_SELECTOR`用来选择key的序列化器。如果没有找到，则抛出`IllegalStateException`异常。消费records时，使用同样的头来选择反序列化器，如果没有找到或者没有相关的头，则返回`byte[]`。你可以配置一个selector到`Serializer/Deserializer`的映射，或者你可以通过Kafka的生产者与消费者属性`DelegatingSerializer.VALUE_SERIALIZATION_SELECTOR_CONFIG`或者`DelegatingSerializer.KEY_SERIALIZATION_SELECTOR_CONFIG`来配置，对于序列化器来说，生产者属性可以是一个`Map<String, Object>`，key是selector，value是`Serializer`实例对象、Serializer的Class或者就是Class的名字。属性可以是逗号分隔的map对。反序列化器与上面的配置方式类似。
```java
producerProps.put(DelegatingSerializer.VALUE_SERIALIZATION_SELECTOR_CONFIG,
    "thing1:com.example.MyThing1Serializer, thing2:com.example.MyThing2Serializer")

consumerProps.put(DelegatingDeserializer.VALUE_SERIALIZATION_SELECTOR_CONFIG,
    "thing1:com.example.MyThing1Deserializer, thing2:com.example.MyThing2Deserializer")
```
生产者将会设置`DelegatingSerializer.VALUE_SERIALIZATION_SELECTOR`为`thing1`或者`thing2`，这种技术支持将不同的类型的数据发送到同一个topic或者不同的topic。从2.5.1版本开始，如果类型(key/value)是受`Serdes`支持的标准类型就不需要设置selector header了，序列化器会设置header为类型的class名字，不需要为这些类型配置序列化器或者反序列化器，它们会被自动创建(只创建一次)。
#### By Type
从2.8版本开始引入了`DelegatingByTypeSerializer`
```java
@Bean
public ProducerFactory<Integer, Object> producerFactory(Map<String, Object> config) {
    return new DefaultKafkaProducerFactory<>(config,
            null, new DelegatingByTypeSerializer(Map.of(
                    byte[].class, new ByteArraySerializer(),
                    Bytes.class, new BytesSerializer(),
                    String.class, new StringSerializer())));
}
```
从2.8.3版本开始，你可以配置序列化器检测是否Map的key可赋值为目标对象，代理序列化器可以序列化化子类时很有用，如果存在key的匹配混乱，最好使用一个有序的Map。
#### By Topic
从2.8版本开始，`DelegatingByTopicSerializer`与`DelegatingByTopicDeserializer`允许基于topic名字选择一个`serializer/deserializer`，正则表达式Pattern用来寻找要使用的实例，map可以通过构造函数配置或者通过属性(`pattern:serializer`的逗号分隔列表)
```java
producerConfigs.put(DelegatingByTopicSerializer.VALUE_SERIALIZATION_TOPIC_CONFIG,
            "topic[0-4]:" + ByteArraySerializer.class.getName()
        + ", topic[5-9]:" + StringSerializer.class.getName());
...
ConsumerConfigs.put(DelegatingByTopicDeserializer.VALUE_SERIALIZATION_TOPIC_CONFIG,
            "topic[0-4]:" + ByteArrayDeserializer.class.getName()
        + ", topic[5-9]:" + StringDeserializer.class.getName());
        @Bean
public ProducerFactory<Integer, Object> producerFactory(Map<String, Object> config) {
    return new DefaultKafkaProducerFactory<>(config,
            new IntegerSerializer(),
            new DelegatingByTopicSerializer(Map.of(
                    Pattern.compile("topic[0-4]"), new ByteArraySerializer(),
                    Pattern.compile("topic[5-9]"), new StringSerializer())),
                    new JsonSerializer<Object>());  // default
}
```
你可以指定当没有模式匹配到时使用的默认的`serializer/deserializer`，通过`DelegatingByTopicSerialization.KEY_SERIALIZATION_TOPIC_DEFAULT`与`DelegatingByTopicSerialization.VALUE_SERIALIZATION_TOPIC_DEFAULT`指定。一个额外的属性`DelegatingByTopicSerialization.CASE_SENSITIVE`决定做topic匹配时是否需略大小写。

