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

从2.5版本开始，他们都继承`KafkaResourceFactory`，这样可以在运行时动态更改bootstrap servers，只需要在他们的配置中添加一个`Supplier<String>`。