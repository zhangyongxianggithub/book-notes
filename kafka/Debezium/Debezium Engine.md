Debezium连接器通常部署在Kafka Connect服务中，配置一个或者多个Connectors来监控上游的数据库并产生数据变更事件，这些数据变更事件被写入到Kafka，可以被很对独立的应用消费。Kafka Connect提供了极高的容错性与扩展性。因为它是一个分布时服务，保证了所有注册与配置的连接器始终在运行。比如，即使KafkaConnect的其中一个endpoint挂掉了，剩余的Kafka Connect endpoints会重新启动现在终止的endpoint上运行的所有的连接器。最小化减少宕机事件，消除人工干预的需要。不是每个应用都需要这种级别的容错性与可靠性，他们可能不想依赖外部的集群比如kafka或者Kafka Connect。相反，这些应用可能更想要直接嵌入Debezium连接器。直接获取数据变更事件而不是存入到Kafka。`debezium-api`模块定义了一组API。允许应用使用Debezium Engine来简单的配置并运行Debezium连接器。
# 依赖
为了使用Debezium Engine模块，添加`debezium-api`模块到你的应用依赖，也可以一个开箱即用的API实现`debezium-embedded`也应该添加到依赖中，对于maven来说，添加依赖如下:
```xml
<dependency>
    <groupId>io.debezium</groupId>
    <artifactId>debezium-api</artifactId>
    <version>${version.debezium}</version>
</dependency>
<dependency>
    <groupId>io.debezium</groupId>
    <artifactId>debezium-embedded</artifactId>
    <version>${version.debezium}</version>
</dependency>
```
这里`${version.debezium}`就是你要使用的debezium的版本，类似的，添加连接器依赖到你的应用中，比如，要使用MySQL连接器，添加依赖如下:
```xml
<dependency>
    <groupId>io.debezium</groupId>
    <artifactId>debezium-connector-mysql</artifactId>
    <version>${version.debezium}</version>
</dependency>
```
下面的章节描述了将MySQL连接器嵌入到应用中，其他连接器的用法是类似的。
# In the Code
你的应用需要为每个连接器实例建立一个内嵌的engine。`io.debezium.engine.DebeziumEngine<R>`类就是一个容易使用的连接器包装器。可以完整管理连接器的生命周期。你需要使用它的builder方法创建`DebeziumEngine`实例。
- 你想要接收messgae的格式。比如JSON、Avro、Kafka Connect `SourceRecord`
- 配置属性，定义了engine与连接器的环境
- 一个方法用来处理每个变更事件

下面是一个例子
```java
/ Define the configuration for the Debezium Engine with MySQL connector...
final Properties props = new Properties();
props.setProperty("name", "engine");
props.setProperty("connector.class", "io.debezium.connector.mysql.MySqlConnector");
props.setProperty("offset.storage", "org.apache.kafka.connect.storage.FileOffsetBackingStore");
props.setProperty("offset.storage.file.filename", "/tmp/offsets.dat");
props.setProperty("offset.flush.interval.ms", "60000");
/* begin connector properties */
props.setProperty("database.hostname", "localhost");
props.setProperty("database.port", "3306");
props.setProperty("database.user", "mysqluser");
props.setProperty("database.password", "mysqlpw");
props.setProperty("database.server.id", "85744");
props.setProperty("topic.prefix", "my-app-connector");
props.setProperty("schema.history.internal",
      "io.debezium.storage.file.history.FileSchemaHistory");
props.setProperty("schema.history.internal.file.filename",
      "/path/to/storage/schemahistory.dat");

// Create the engine with this configuration ...
try (DebeziumEngine<ChangeEvent<String, String>> engine = DebeziumEngine.create(Json.class)
        .using(props)
        .notifying(record -> {
            System.out.println(record);
        }).build()
    ) {
    // Run the engine asynchronously ...
    ExecutorService executor = Executors.newSingleThreadExecutor();
    executor.execute(engine);

    // Do something else or wait for a signal or an event
}
// Engine is stopped when the main code is finished
```
让我们更详细的观察这段代码，从前面的几行开始
```java
/ Define the configuration for the Debezium Engine with MySQL connector...
final Properties props = new Properties();
props.setProperty("name", "engine");
props.setProperty("connector.class", "io.debezium.connector.mysql.MySqlConnector");
props.setProperty("offset.storage", "org.apache.kafka.connect.storage.FileOffsetBackingStore");
props.setProperty("offset.storage.file.filename", "/tmp/offsets.dat");
props.setProperty("offset.flush.interval.ms", 60000);
```
创建了一个标准的`Proeprties`对象，设置了几个engine需要的属性。首先是engine的名字，将在连接器产生的源记录与内部状态中使用，所以使用一些有意义的名字。`connector.class`定义了一个类名，这个类需要继承自kafka connect的`org.apache.kafka.connect.source.SourceConnector`抽象类。在这个例子中，我们指定了Debezium的`MySqlConnector`类。当一个Kafka Connect连接器运行时，他从源中读读取信息并周期性的记录offset，这个offset定义了它已经处理了多少信息。当连接器从新启动时，它会使用最后记录的offset来知道它应该从源信息的哪里开始读。