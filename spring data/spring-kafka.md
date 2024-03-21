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
### Receiving Messages
接收消息需要首先配置一个`MessageListenerContainer`，然后提供一个messgae listener或者使用`@KafkaListener`注解。
#### Message Listeners
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
