# 第2章 流处理基础
# 第3章 Apache Flink架构
## 系统架构
Flink是一个用于状态化并行流处理的分布式系统，挑战:
- 分配/管理集群计算资源;
- 进程协调;
- 持久且高可用的数据存储;
- 故障恢复
Flink专注做数据流处理，分布式资源通过第三方集群资源管理器实现，持久存储也是第三方，高可用使用zk完成领导选举.
### 搭建Flink所需的组件
需要4个组件:
- JobManager: 主进程，控制管理协调应用执行，每个应用属于一个JobManager管理，应用包含JobGraph(逻辑Dataflow图)与打包了所有文件的JAR文件，JobManager将JobGraph转化为ExecutionGraph(物理Dataflow图)，包含了可以并行执行的任务，JobManager从ResourceManager申请执行任务的必要资源(TaskManager处理槽)，然后将ExecutionGraph中的任务分给申请的TaskManager处理槽执行，还负责创建检查点等需要协调的操作.(管理应用层面上的操作)。
- ResourceManager: 针对不同的集群资源管理器，Flink提供了不同的ResourceManager，ResourceManager负责管理处理槽，当收到JobManager的申请时，分配空闲的TaskManager处理槽，如果没有向底层的集群资源管理器申请新的TaskManager进程，ResourceManager还负责终止空闲的TaskManager.
- TaskManager: 工作进程，多个，每个还包含多个处理槽，TaskManager启动时向ResourceManager注册处理槽，TaskManager接收JobManager发来的任务执行，运行同一个应用不同任务的TaskManager之间会产生数据交换.
- Dispatcher: REST接口，用于提交需要执行的应用，Dispatcher将提交的应用转给JobManager，还会启动一个Web UI。
交付过程图如下:
![Flink各组件的交互过程](pic/flink%E7%BB%84%E4%BB%B6%E5%85%B3%E7%B3%BB.png)

