Debezium连接器通常部署在Kafka Connect服务中，配置一个或者多个Connectors来监控上游的数据库并产生数据变更事件，这些数据变更事件被写入到Kafka，可以被很对独立的应用消费。Kafka Connect提供了极高的容错性与扩展性。因为它是一个分布式服务，保证了所有注册与配置的连接器始终在运行。比如，即使KafkaConnect的其中一个endpoint挂掉了，剩余的Kafka Connect endpoints会重新启动现在终止的endpoint上运行的所有的连接器。最小化减少宕机事件，消除人工干预的需要。不是每个应用都需要这种级别的容错性与可靠性，他们可能不想依赖外部的集群比如kafka或者Kafka Connect。相反，这些应用可能更想要直接嵌入Debezium连接器。直接获取数据变更事件而不是存入到Kafka。`debezium-api`模块定义了一组API。允许应用使用Debezium Engine来简单的配置并运行Debezium连接器。
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
创建了一个标准的`Proeprties`对象，设置了几个engine需要的属性。首先是engine的名字，将在连接器产生的源记录与内部状态中使用，所以使用一些有意义的名字。`connector.class`定义了一个类名，这个类需要继承自kafka connect的`org.apache.kafka.connect.source.SourceConnector`抽象类。在这个例子中，我们指定了Debezium的`MySqlConnector`类。当一个Kafka Connect连接器运行时，他从源中读读取信息并周期性的记录offset，这个offset定义了它已经处理了多少信息。当连接器从新启动时，它会使用最后记录的offset来知道它应该从源信息的哪里开始读。因为连接器不知道或者不关系offset是如何存储的。由engine来提供一种方式来存储与恢复这些offsets。后面的几个属性指定我们的engine应该使用`FileOffsetBackingStore`来存储offset到本地文件的`/path/to/storage/offset.dat`中，文件可以是任意的名字存在任意的地方。除此以外，虽然连接器记录每个source record的offset，engine是周期性的将offset刷新到后端存储，默认是一分钟。这些属性你可以根据你的应用情况调整。下面的几行属性是连接器专用的属性，每种连接器的属性在其自己的文档中
```java
/* begin connector properties */
    props.setProperty("database.hostname", "localhost")
    props.setProperty("database.port", "3306")
    props.setProperty("database.user", "mysqluser")
    props.setProperty("database.password", "mysqlpw")
    props.setProperty("database.server.id", "85744")
    props.setProperty("topic.prefix", "my-app-connector")
    props.setProperty("schema.history.internal",
          "io.debezium.storage.file.history.FileSchemaHistory")
    props.setProperty("schema.history.internal.file.filename",
          "/path/to/storage/schemahistory.dat")
```
这里，我们设置了主机名、端口、username、password等，用户必须具有下面的权限
- SELECT
- RELOAD
- SHOW DATABASES
- REPLICATION SLAVE
- REPLICATION CLIENT

前面的3个权限是用来读取快照的。后面的2个权限是用来读取binlog的，通常用在MySQL复制中。配置也包含了一个数字标识符`server.id`，因为MySQL binlog也是MySQL复制机制的一部分。为了读取Binlog，`MySqlConnector`必须加入到MySQL的服务组中，这意味着，server ID必须在构成服务组的所有进程中唯一可以是1到$2^{32}-1$中的任何整数。配置也为MySQL server指定了逻辑名。连接器会在每个它产生的source record的topic字段中包含逻辑名，启动应用来标识这些记录的来源。我们的例子使用`products`逻辑名。当`MySqlConnector`运行时，他从MySQL服务的binlog中读取数据，包含了所有的数据变更与schema变更，因为所有的数据变更都对应变更发生时其表的schema。连接器需要追踪所有的schema变更，这样可以合理的解码变更事件，连接器会记录schema信息，所以，当连接器重启并从最后的offset恢复读取时，它能精确的知道在每个offset时schema是什么，连接器记录schema历史在我们的最后面的2个属性中，其中表明，我们的连接器应该使用`FileSchemaHistory`类来存储schema历史变更到`/path/to/storage/schemahistory.dat`文件中，最后，使用`build()`方法来产生不可更改的配置，相比程序设置，我们可以从一个属性文件中读取配置，比如使用`Configuration.read(…​)`方法。现在我们创建engine，下面是相关的代码
```java
// Create the engine with this configuration ...
try (DebeziumEngine<ChangeEvent<String, String>> engine = DebeziumEngine.create(Json.class)
        .using(props)
        .notifying(record -> {
            System.out.println(record);
        })
        .build()) {
}
```
所有的变更事件都会传递给给定的handler方法，handler是`java.util.function.Consumer<R>`类，`R`必须匹配调用`create()`时指定的格式类型。应用的handler method不能抛出异常。如果抛出了，engine将会记录抛出的异常并继续处理下一个源记录。你的应用没有机会处理抛出异常的那个source record。此时我们有了配置好的`DebeziumEngine`，并准备运行，它还没有做任何事情，`DebeziumEngine`被设计为异步执行的。
```java
// Run the engine asynchronously ...
ExecutorService executor = Executors.newSingleThreadExecutor();
executor.execute(engine);

// Do something else or wait for a signal or an event
```
你的应用可以通过调用`close()`方法来安全平稳的关闭。
因为`DebeziumEngine`实现了`Closeable`接口，所以也支持try-with-resource的用法。engine的连接器将会停止从源系统中读取信息。将所有剩余的变更事件转发到你的handler函数，将最后的offsets刷新到存储中。只有在所有这些完成之后，引擎的`run()`方法才会返回。如果您的应用程序需要等待引擎完全停止后再退出，您可以使用ExcecutorService `shutdown`和`awaitTermination`方法来完成此操作:
```java
try {
    executor.shutdown();
    while (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
        logger.info("Waiting another 5 seconds for the embedded engine to shut down");
    }
}
catch ( InterruptedException e ) {
    Thread.currentThread().interrupt();
}
```
还有一种办法，你可以注册一个`CompletionCallback`作为engine终止时的回调。回想一下，当JVM关闭时，它只等待守护线程。 因此，如果您的应用程序退出，请务必等待引擎完成，或者在守护线程上运行引擎。您的应用程序应始终正确停止engine以确保engine正常且完全关闭，并且每条源记录都准确处理一次。例如，不要依赖于关闭`ExecutorService`，因为这会中断正在运行的线程。尽管`DebeziumEngine`在其线程被中断时确实会终止，但engine可能不会干净地终止，并且当您的应用程序重新启动时，它可能会看到一些与关闭之前处理过的相同源记录。
# Output Message Formats
`DebeziumEngine#create()`可以接受很多不同的参数来决定message的格式，允许的值有:
- `Connnect.class`: 输出是一个包含Kafka Connect `SourceRecord`的变更事件
- `Json.class`: 输出值是一对都适用JSON编码的字符串
- `JsonByteArray.class`: 输出值是一对都使用JSON格式化字符串，然后编码为UTF-8字节数组
- `Avro.class`: 输出值是一对通过Avro序列化的key-value
- `CloudEvents.class`:  

header的格式也可以指定，允许的值有:
- `Json.class`: header值被编码为JSON字符串
- `JsonByteArray.class`: header值被格式化为JSON，然后编码为UTF-8子节数组

从内部来说，engine使用一个合适的Kafka Connect converter实现底层转换。可以使用引擎属性对转换器进行参数化以修改其行为。一个`JSON`格式的输出的例子:
```java
final Properties props = new Properties();
...
props.setProperty("converter.schemas.enable", "false"); // don't include schema in message
...
final DebeziumEngine<ChangeEvent<String, String>> engine = DebeziumEngine.create(Json.class)
    .using(props)
    .notifying((records, committer) -> {

        for (ChangeEvent<String, String> r : records) {
            System.out.println("Key = '" + r.key() + "' value = '" + r.value() + "'");
            committer.markProcessed(r);
        }
```
