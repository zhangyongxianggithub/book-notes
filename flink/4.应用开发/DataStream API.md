# 概览
Flink中的DataStream程序是对数据流进行转换的常规程序。数据流的起始时从各种源(消息队列、套接字流、文件)创建的。结果通过sink返回，例如可以将数据写入文件或者标准输出。Flink程序可以在各种上下文中运行，可以独立运行，也可以嵌入到其他程序中。任务执行可以运行在本地JVM也可以运行在多台机器的集群上。
## DataStream是什么?
DataStream API得名于特殊的DataStream类，该类用于表示flink程序中的数据集合。你可以认为 它们是可以包含重复项的不可变数据集合。这些数据可以是有界（有限）的，也可以是无界（无限）的，但用于处理它们的API是相同的。DataStream在用法上类似于常规的Java集合，但在某些关键方面却大不相同。它们是不可变的，这意味着一旦它们被创建，你就不能添加或删除元素。你也不能简单地察看内部元素，而只能使用DataStream API操作来处理它们，DataStream API操作也叫作转换（transformation）。你可以通过在Flink程序中添加source创建一个初始的DataStream。然后，你可以基于DataStream派生新的流，并使用map、filter等API方法把DataStream和派生的流连接在一起。
## Flink程序剖析
Flink程序看起来像一个转换DataStream的常规程序，每个程序由相同的基本部分组成:
- 获取一个执行环境(execution environment)
- 加载/创建初始数据;
- 指定数据相关的转换;
- 指定计算结果的存储位置;
- 触发程序执行。
现在我们将对这些步骤逐一进行概述，更多细节请参考相关章节。请注意，Java DataStream API的所有核心类都可以在[org.apache.flink.streaming.api](https://github.com/apache/flink/blob/release-1.16//flink-streaming-java/src/main/java/org/apache/flink/streaming/api)中找到。`StreamExecutionEnvironment`是所有Flink程序的基础。你可以使用`StreamExecutionEnvironment`的如下静态方法获取`StreamExecutionEnvironment`:
```java
getExecutionEnvironment();
createLocalEnvironment();
createRemoteEnvironment(String host, int port, String... jarFiles);
```
通常，你只需要使用`getExecutionEnvironment()`即可，因为该方法会根据上下文做正确的处理: 如果你在IDE执行，你的程序或将作为一般的Java程序执行，那么它将创建一个本地环境，该环境将在你的本地机器上执行你的程序。如果你基于程序创建了一个JAR文件并通过命令行运行它，Flink集群管理器将执行程序的main方法，同时`getExecutionEnvironment()`方法会返回一个执行环境以在集群上执行你的程序。