[Apache Kafka](https://kafka.apache.org/)通过`spring-kafka`项目提供的自动配置获得支持。kafka配置有`spring.kafka.*`空间下的外部配置属性控制。比如，你可能声明如下的配置:
```properties
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=myGroup
```
如果要在启动时创建一个topic，添加一个NewTopic类型的Bean，如果topic已经存在，bean会被忽略。查看[KafkaProperties](https://github.com/spring-projects/spring-boot/tree/v3.2.3/spring-boot-project/spring-boot-autoconfigure/src/main/java/org/springframework/boot/autoconfigure/kafka/KafkaProperties.java)了解更多的支持的选项。
# Sending a Message
Spring的`KafkaTemplate`是自动配置的，你可以在任意的地方注入它。比如下面的例子:
```java
@Component
public class MyBean {
    private final KafkaTemplate<String, String> kafkaTemplate;
    public MyBean(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }
    public void someMethod() {
        this.kafkaTemplate.send("someTopic", "Hello");
    }
}
```
如果定义了`spring.kafka.producer.transaction-id-prefix`属性，一个`KafkaTransactionManager`会自动配置，如果定义了一个`RecordMessageConverter`的bean，它会被自动关联到自动配置的`KafkaTemplate`。
# Receiving a Message
当classpath中存在Apache Kafka的基础包时，任何使用`@KafkaListener`注解标注的bean将会创建一个listener endpoint。如果没有`KafkaListenerContainerFactory`bean的定义，会自动创建一个默认的bean，其配置来源于`spring.kafka.listener.*`key空间下。下面的组件在`someTopic`上创建一个listener endpoint。
```java
@Component
public class MyBean {
    @KafkaListener(topics = "someTopic")
    public void processMessage(String content) {
    }
}
```
如果定义了`KafkaTransactionManager`bean，他会自动关联到container factory，类似的，如果定义了`RecordFilterStrategy`, `CommonErrorHandler`, `AfterRollbackProcessor`, `ConsumerAwareRebalanceListener`这些bean，也会被自动关联到默认的factory。依赖listener的类型，一个`RecordMessageConverter`或者一个`BatchMessageConverter`bean会关联到默认的factory。如果只有一个`RecordMessageConverter`bean被定义为batch listener的转换器，那么它会被包含在一个`BatchMessageConverter`中。一个自定义的`ChainedKafkaTransactionManager`bean必须使用`@Primary`标注，因为通常自动配置的`KafkaTransactionManager`会得到使用。
# Kafka Streams
# Additional Kafka Properties
自动配置支持的属性在附录的`Integration Properties`部分，注意，对于大部分属性来说，这些属性(连字符属性或者驼峰属性)都会直接映射到Kafka的点号分隔属性。可以参考Kafka的详细文档。不包含客户端类型(producer、consumer、admin、streams)的属性被认为是通用的属性。大部分通用属性可以被客户端内的属性覆盖。kafka把属性分为HIGH、MEDIUM、LOW几种重要级别。Spring Boot自动配置支持所有的HIGH级别的属性、一些特定的MEDIUM与LOW级别的属性，所有属性都没有默认值。`KafkaProperties`类只支持Kafka的部分属性。如果你想用不直接支持的额外属性配置客户端使用下面的方式:
```yaml
spring:
  kafka:
    properties:
      "[prop.one]": "first"
    admin:
      properties:
        "[prop.two]": "second"
    consumer:
      properties:
        "[prop.three]": "third"
    producer:
      properties:
        "[prop.four]": "fourth"
    streams:
      properties:
        "[prop.five]": "fifth"

```
这回设置Kafka属性`prop.one`为`first`(对producers, consumers, admins,streams都生效),属性`prop.two`对admin客户端生效，`rop.three`对consumer客户端生效，`prop.four`属性对producer的客户端生效。等等。我们也能配置Spring Kafka的`JsonDeserializer`,如下:
```yaml
spring:
  kafka:
    consumer:
      value-deserializer: "org.springframework.kafka.support.serializer.JsonDeserializer"
      properties:
        "[spring.json.value.default.type]": "com.example.Invoice"
        "[spring.json.trusted.packages]": "com.example.main,com.example.another"

```
类似的，你可以关闭JsonSerializer的默认行为，比如在headers中发送类型信息
```yaml
spring:
  kafka:
    producer:
      value-serializer: "org.springframework.kafka.support.serializer.JsonSerializer"
      properties:
        "[spring.json.add.type.headers]": false
```
这种方式设置的属性会覆盖Spring Boot明确定义的属性。