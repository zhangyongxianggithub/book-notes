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
通常，你只需要使用`getExecutionEnvironment()`即可，因为该方法会根据上下文做正确的处理: 如果你在IDE执行，你的程序或将作为一般的Java程序执行，那么它将创建一个本地环境，该环境将在你的本地机器上执行你的程序。如果你基于程序创建了一个JAR文件并通过命令行运行它，Flink集群管理器将执行程序的main方法，同时`getExecutionEnvironment()`方法会返回一个执行环境以在集群上执行你的程序。为了指定data sources，执行环境提供提供一些方法，支持使用各种方法从文件中读取数据，可以直接逐行读取或者使用第三方的source，如果你只是将一个文本文件作为一个行的序列来读取，那么可以使用：
```java
final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
DataStream<String> text = env.readTextFile("file:///path/to/file");
```
这将生成一个DataStream，然后你可以在上面应用转换（transformation）来创建新的派生DataStream。你可以调用 DataStream上具有转换功能的方法来应用转换。例如，一个map的转换如下所示:
```java
DataStream<String> input = ...;
DataStream<Integer> parsed = input.map(new MapFunction<String, Integer>() {
    @Override
    public Integer map(String value) {
        return Integer.parseInt(value);
    }
});
```
这将通过把原始集合中的每一个字符串转换为一个整数来创建一个新的 DataStream。一旦你有了包含最终结果的DataStream，你就可以通过创建sink把它写到外部系统。下面是一些用于创建sink的示例方法:
```java
writeAsText(String path);
print();
```
一旦指定了完整的程序，需要调用`StreamExecutionEnvironment.execute()`方法来触发程序执行，根据`ExecutionEnvironment`的类型，执行会在你的本地机器上触发或者将你的程序提交到某个集群上执行。`execute()`将等待作业完成，返回一个`JobExecutionResult`，其中包含执行时间和累加器结果。如果不想等待作业完成，可以通过调用`StreamExecutionEnvironment.executeAsync()`方法来触发作业异步执行，它会返回一个JobClient，你可以通过它与刚刚提交的作业进行通信，如下是例子:
```java
final JobClient jobClient = env.executeAsync();
final JobExecutionResult jobExecutionResult = jobClient.getJobExecutionResult().get();
```
程序如何执行最后一部分对于理解何时执行以及如何执行Flink算子是至关重要的。所有Flink程序都是延迟执行的: 当程序的main方法执行时，数据加载和转换不会直接发生，相反，每个算子都被创建并添加到dataflow形成的有向图。当执行被执行环境的execute()方法显示的触发时，这些算子才会真正的执行。程序是在本地执行还是在集群上执行取决于执行环境的类型。延迟计算允许你构建复杂的程序，Flink会将其作为一个整体的计划单元来执行。
## 示例程序