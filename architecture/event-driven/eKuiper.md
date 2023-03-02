[TOC]
ekuiper，超轻量物联网的边缘数据分析软件。它是一款可以运行在各类资源受限硬件上的轻量级物联网边缘分析、流式处理开源软件。ekuiper的一个主要目标在边缘端提供一个实时流式计算框架，与Flink类似，eKuiper的规则引擎允许用户使用基于SQL方式，或者Graph方式的规则，快速创建边缘端的分析应用。
功能:
- 超轻量，核心服务安装包4.5M，首次运行内存使用10MB
- 跨平台，各种CPU架构，各种Linux，各种容器，这个边缘设备
- 完整的数据分析，数据抽取转换过滤，聚合分组各种函数，各种窗口
- 高可扩展性，通过Golang/Python开发自定义的Source/Sink/SQL函数
- 管理能力，免费的可视化管理，通过CLI、REST API等管理
- 与KubeEdge、OpenYurt、K3s、Baetyl等基于边缘Kubernetes框架的继承能力
- EMQX集成
```shell
docker run -p 9082:9082 -d --name ekuiper-manager -e DEFAULT_EKUIPER_ENDPOINT="http://172.25.104.177:9081" emqx/ekuiper-manager:latest
```
```shell
docker run -p 9081:9081 -d --name kuiper -e MQTT_SOURCE__DEFAULT__SERVER="tcp://broker.emqx.io:1883" lfedge/ekuiper:1.8-alpine
```
# 安装与部署
- Docker方式，可以使用`docker compose`来部署eKuiper/eKuiper manager
  ```yaml
   version: '3.4'

   services:
   manager:
      image: emqx/ekuiper-manager:x.x.x
      container_name: ekuiper-manager
      ports:
      - "9082:9082"
      restart: unless-stopped
      environment: 
      # setting default eKuiper service, works since 1.8.0
      DEFAULT_EKUIPER_ENDPOINT: "http://ekuiper:9081"
   ekuiper:
      image: lfedge/ekuiper:x.x.x
      ports:
      - "9081:9081"
      - "127.0.0.1:20498:20498"
      container_name: ekuiper
      hostname: ekuiper
      restart: unless-stopped
      user: root
      volumes:
      - /tmp/data:/kuiper/data
      - /tmp/log:/kuiper/log
      - /tmp/plugins:/kuiper/plugins
      environment:
      MQTT_SOURCE__DEFAULT__SERVER: "tcp://broker.emqx.io:1883"
      KUIPER__BASIC__CONSOLELOG: "true"
      KUIPER__BASIC__IGNORECASE: "false"
  ```
- 裸机软件包安装
- Helm/K8s/K3s
  ```shell
   $ helm repo add emqx https://repos.emqx.io/charts # 添加仓库
   $ helm repo update
   $ helm search repo emqx # 搜索仓库内容
   $ helm install my-ekuiper emqx/ekuiper #安装
  ```
# 开发方式
2种方式创建/管理规则（流处理作业），其实还有REST API方式，Web UI本质就是这种方式。
eKuiper规则由SQL和多个动作组成。eKuiper SQL是一种类SQL语言，指定规则的逻辑，是标准SQL的子集。
1. Web UI
   - 创建订阅的流与数据结构
   - 编写规则`SELECT count(*), avg(temperature) AS avg_temp, max(hum) AS max_hum FROM demo GROUP BY TUMBLINGWINDOW(ss, 5) HAVING avg_temp > 30`，记住这里的规则的名字
   - 添加动作，可以由多个
   - 管理规则，有运行状态与指标
2. CLI
   - 指定MQTT服务器地址
   ```yaml
   default:
      qos: 1
      sharedsubscription: true
      server: "tcp://127.0.0.1:1883"
   ```
   - 创建流`$ bin/kuiper create stream demo '(temperature float, humidity bigint) WITH (FORMAT="JSON", DATASOURCE="demo")'`
   - `bin/kuiper query`
   - `select count(*), avg(humidity) as avg_hum, max(humidity) as max_hum from demo where temperature > 30 group by TUMBLINGWINDOW(ss, 5);`SQL语句验证
   - 编写规则:
     - 规则名称: 规则ID必须是唯一的
     - sql: 针对规则运行的查询
     - 动作: 规则的输出动作
   ```shell
   bin/kuiper create rule myRule -f myRule
   ```
   文件内的内容
   ```json
   {
      "sql": "SELECT count(*), avg(temperature) as avg_temp, max(humidity) as max_hum from demo group by TUMBLINGWINDOW(ss, 5) HAVING avg_temp > 30;",
      "actions": [{
         "mqtt":  {
            "server": "tcp://127.0.0.1:1883",
            "topic": "result/myRule",
            "sendSingle": true
         }
      }]
   }
   ```
   这个命令也可以管理规则`bin/kuiper stop rule myRule`
# 机构设计
LF Edge eKuiper是物联网数据分析和流式计算引擎。是一个通用的边缘计算服务或中间件，为资源有限的边缘网关或者设备而设计。采用Go语言编写。架构如下:
![eKuiper架构设计](./arch.png)
作为规则引擎，用户可以通过REST API或CLI提交计算作业即规则。eKuiper规则/SQL解析器或图规则解析器将解析、规划和优化规则，使其成为一系列算子的流程，如果需要的话，算子可以利用流式运行时和状态存储。算子之间是松耦合的，通过Go通道进行异步通信。受益于Go的并发模型，规则运行时可以做到: 
- 以异步和非阻塞的方式进行通信;
- 充分利用多核计算;
- 算子层可伸缩;
- 规则之间相互隔离。
这些有助于eKuiper实现低延迟和高吞吐量的数据处理。 在eKuiper种，计算工作以规则的形式呈现。规则以流的数据源为输入，通过SQL定义计算逻辑，将结果输出到动作/sink中。规则定义提交后，它将持续运行。它将不断从源获取数据，根据SQL逻辑进行计算，并根据结果触发行动。
## 关键概念
### 规则
每条规则都代表了在eKuiper中运行的一项计算工作。它定义了连续流数据源作为输入，计算逻辑和结果sink作为输出。
1. 规则生命周期
   目前，eKuiper只支持流处理规则，这意味着至少有一个规则源必须是连续流。规则一旦启动就会连续运行，只有在用户明确发送停止命令时才会停止。规则可能会因为错误或eKuiper实例退出而异常停止；
2. 规则关系
   同时运行多个规则是很常见的。由于eKuiper是一个单一的实例进程，这些规则在同一个内存空间中运行。规则在运行时上是分开的，一个规则的错误不应该影响其他规则。关于工作负载，所有的规则都共享相同的硬件资源。每条规则可以指定算子缓冲区，以限制处理速度，避免占用所有资源；
3. 规则流水线
   多个规则可以通过指定sink/源的联合点形成一个处理管道。例如，第一条规则在内存sink中产生结果，其他规则在其内存源中订阅该主题。除了一对内存sink/源，用户还可以使用mqtt或其他sink/源对来连接规则。
### Sources源
源（source）用于从外部系统中读取数据。数据源既可以是无界的流式数据，即流；也可以是有界的批量数据，即表。在规则中使用时，至少有一个源必须为流。源定义了如何连接到外部资源，然后采用流式方式获取数据。获取数据后，通常源还会根据定义的数据模型进行数据解码和转换。
1. 定义和运行
   在eKuiper中，定义数据源的流或者表之后，系统实际上只是创建了一个数据源的逻辑定义而非真正物理运行的数据输入。此逻辑定义可在多个规则的 SQL的from子句中使用。只有当使用了该定义的规则启动之后，数据流才会真正运行。默认情况下，多个规则使用同一个源的情况下，每个规则会启动一个独立的源的运行时，与其他规则中的同名源完全隔离。若多个规则需要使用完全相同的输入数据或者提高性能，源可定义为共享源，从而在多个规则中共享同一个实例;
2. 解码
   用户可以在创建源时通过指定format属性来定义解码方式。当前只支持json和binary两种格式。若需要支持其他编码格式，用户需要开发自定义源插件;
3. 数据结构
   用户可以像定义关系数据库表结构一样定义数据源的结构。部分数据格式本身带有数据结构，例如protobuf格式。用户在创建源时可以定义 schemaId来指向模式注册表(Schema Registry)中的数据结构定义。其中，模式注册表中的定义为物理数据结构，而数据源定义语句中的数据结构为逻辑数据结构。若两者都有定义，则物理数据结构将覆盖逻辑数据结构。此时，数据结构的验证和格式化将有定义的格式负责，例如protobuf。若只定义了逻辑结构而且设定了strictValidation，则在eKuiper的运行时中，数据会根据定义的结构进行验证和类型转换。若未设置验证，则逻辑数据结构主要用于编译和加载时的SQL语句验证。若输入数据为预处理过的干净数据或者数据结构未知或不固定，用户可不定义数据结构，从而也可以避免数据转换的开销；
4. 流
   源定义了与外部系统的连接方式。在规则中，根据数据使用逻辑，数据源可作为流或者表使用。详细信息请参见流和表。在eKuiper中，流指的是数据源的一种运行时形态。流定义需要指定其数据源类型以定义与外部资源的连接方式。数据源作为流使用时，源必须为无界的。在规则中，流的行为类似事件触发器。每个事件都会触发规则的一次计算;
5. 表
   表是源数据在当前时间的快照。我们支持两种类型的表：扫描表（Scan Table）和查询表（Lookup Table）。
   - 扫描表: 消费流数据作为变化日志，并持续更新表。与常见的代表批处理数据的静态表相比，扫描表可以随时间变化。所有的流数据源如MQTT、 Neuron源等都可以是扫描表源。扫描表从 v1.2.0 版本开始支持。
   - 查询表: 一个外部表，其内容通常不会被完全读取，仅在必要时进行查询。我们支持将实体表绑定为查询表，并根据需要生成查询命令（例如，数据库上的SQL）。请注意，不是所有的源类型都可以成为查询表源，只有像SQL源这样的有外部存储的源可以成为查询源。我们从v1.7.0版本开始支持查询表。
   - 扫描表: 表的数据源既可以是无界的也可以是有界的。对于有界数据源来说，其表的内容为静态的。若表的数据源为无界数据流，则其内容会动态变化。当前，扫描表的内容更新仅支持追加。用户创建表时，可以指定参数限制表的大小，防止占用过多内存。扫描表不能在规则中单独使用，必须与流搭配，通常用于与流进行连接。扫描表可用于补全流数据或作为计算的开关。
   - 查询表: 查询表不在内存中存储表的内容，而是引用外部表。显然，只有少数源适合作为查询表，这需要源本身是可查询的。支持的源包括：
     - 内存源：如果内存源被用作表类型，我们需要在内存中把数据积累成表。它可以作为一个中间环节，将任何流转换为查询表。
     - Redis：支持按Redis键查询。
     - SQL源：这是最典型的查询源。我们可以直接使用SQL来查询。
   与扫描表不同，查询表将与规则分开运行。因此，所有使用查询表的规则实际上可以查询同一个表的内容.
### Sinks动作
动作是用来向外部系统写入数据的。动作可以用来写控制数据以触发一个动作，还可以用来写状态数据并保存在外部存储器中。一个规则可以有多个动作，不同的动作可以是同一个动作类型。动作的结果是一个字符串。默认情况下，它将被编码为json字符串。用户可以通过设置dataTemplate来改变格式，它利用go模板语法将结果格式化为字符串。为了更详细地控制结果的格式，用户可以开发一个动作扩展。
### SQL查询
eKuiper中的SQL语言支持包括数据定义语言（DDL）、数据操作语言（DML）和查询语言。eKuiper中的SQL支持是ANSI SQL的一个子集，并有一些定制的扩展。当创建和管理流或表源时，SQL DDL和DML被用来作为命令的有效载荷。查看流和表以了解详情。在规则中，SQL查询被用来定义业务逻辑。请查看SQL参考了解详情。
### 扩展
eKuiper提供了内置的源、动作和函数作为规则的构建模块。然而，它不可能覆盖所有外部系统的源/动作连接，例如用户的私有系统与私有协议的连接。此外，内置的功能不能涵盖所有用户需要的所有计算。因此，在很多情况下，用户需要定制源、动作和功能。eKuiper提供了扩展机制，让用户可以定制这三个方面。
我们支持3种扩展点。
- 源: 为eKuiper添加新的源类型，以便从中获取数据。新的扩展源可以在流/表定义中使用。
- 动作Sink: 为eKuiper增加新的 sink 类型来发送数据。新的扩展 sink 可以在规则动作定义中使用。
- 函数: 为eKuiper添加新的函数类型来处理数据。新的扩展函数可以在规则 SQL 中使用。
我们支持3种类型的扩展。
- Go原生: 作为Go插件扩展。它是性能最好的，但在开发和部署方面有很多限制。
- Portable插件: 用Go或Python语言，以后会支持更多语言。它简化了开发和部署，限制较少。
- 外部服务: 通过配置将现有的外部REST或RPC服务包装成eKuiper SQL函数。这是一种快速的方式来扩展现有的服务，但它只支持函数扩展。
## 流式处理
### 概览
流数据是随着时间的推移而产生的数据元素序列，流处理是对流数据的处理。与批处理不同，流数据会在产生后立即被逐一处理。流处理具有下面的特点:
- 无界数据: 流数据是一种不断增长的、无限的数据集，不能作为一个整体来操作;
- 无界的数据处理: 由于适用于无界数据，流处理本身也是无界的，工作负载可以均匀的分布在不同的时间;
- 低延迟、尽实时: 流处理可以在数据产生后就进行处理，以极低的延迟获得结果。
流处理将应用与分析统一起来。简化了整个基础设施，许多系统可以建立在一个共同的架构上，允许开发人员建立应用程序，使用分析结果来响应数据中的洞察力，采取行动。
在边缘侧，大部分的数据都是以连续流的形式诞生，如传感器事件等。随着物联网的广泛应用。越来越多的边缘计算节点需要访问云网络并产生大量的数据。为了降低通信成本，减少云端的数据量，同时提高数据处理的实时性，达到本地及时响应的目的，同时在网络断开的情况下进行本地及时数据处理，有必要在边缘引入实时流处理。
有状态的流处理是流处理的子集，计算保持上下文状态。有状态流处理的例子包括:
- 聚合事件以计算总和、计数或平均值时;
- 检测事件的变化;
- 在一系列事件中搜索一个模式。
状态信息可以通过窗口/状态API管理
### 时间属性
流数据一个随时间变化的数据序列，时间是数据䣌一个固有属性。流处理中，时间在计算中起着重要的作用。比如做基于时间段的聚合。时间的概念很重要。时间有2种类型:
- 事件时间，事件实际发生的时间
- 处理时间，在系统中观察到事件的时间
ekuiper2种时间概念都支持。一个支持事件时间的流处理器需要一种方法来衡量事件时间的进展，比如，创建一个小时的时间窗口时，内部的算子需要在事件时间超过一个小时后得到通知，算子可以发布正在进行的窗口。ekuiper衡量事件时间的进展的机制就是watermark，watermark作为数据流的一部分，带有一个时间戳$t$，一个watermark声明事件时间在该数据流种已经达到了时间$t$，意味着该数据流种不应该再有时间戳<=t的元素，在ekuiper中，watermark是在规则层面上的，这意味着当从多个数据流中读取数据时，水印将在所有输入流中流动。
### 窗口
由于流媒体数据是无限的，因此不可能将其作为一个整体来处理。窗口提供了一种机制，将无界的数据分割成一系列连续的有界数据来计算。内置的窗口2种:
- 时间窗口: 按时间分割的窗口，支持事件时间与处理时间;
- 计数窗口: 按元素计数分割的窗口
### 连接
连接是ekuiper中合并多个数据源的唯一方法。它需要一种方法来对其多个来源并触发连接结果。支持的连接包括:
- 多流的连接: 必须在一个窗口中进行
- 流和表的连接: 流将是连接操作的触发器。
支持的连接类型包括LEFT、RIGHT、FULL、CROSS。
# 配置
配置是基于yaml文件的，允许通过更新文件、环境变量和REST API进行配置。
## 配置范围
- etc/kuiper.yaml: 全局配置文件，对其修改需要重新启动eKuiper实例;
- etc/sources/${source_name}.yaml: 每个源的配置文件，用于定义默认属性，mqtt_source.yaml除外，它直接在etc目录下;
- etc/connections/connection.yaml: 共享连接配置文件。
## 配置方法
yaml 文件通常被用来设置默认配置。在裸机上部署时，用户可以很容易地访问文件系统，因此通常通过配置修改配置文件来更改配置。当在docker或k8s中部署时，操作文件就不容易了，少量的配置可以通过环境变量来设置或覆盖。而在运行时，终端用户将使用管理控制台来动态地改变配置。eKuiper 管理控制台中的"配置"页面可以帮助用户直观地修改配置。
## 环境变量的语法
从环境变量到配置yaml文件之间有一个映射。当通过环境变量修改配置时，环境变量需要按照规定的格式来设置，例如: 
>KUIPER__BASIC__DEBUG => basic.debug in etc/kuiper.yaml
>MQTT_SOURCE__DEMO_CONF__QOS => demo_conf.qos in etc/mqtt_source.yaml
>EDGEX__DEFAULT__PORT => default.port in etc/sources/edgex.yaml
>CONNECTION__EDGEX__REDISMSGBUS__PORT => edgex.redismsgbus.port int etc/connections/connection.yaml

环境变量用__分隔2个下划线，分隔后的第一部分内容与配置文件的文件名匹配，其余内容与不同级别的配置项匹配。文件名可以是etc文件夹中的KUIPER和MQTT_SOURCE；或etc/connection文件夹中的CONNECTION。其余情况，映射文件应在etc/sources文件夹下。
## 全局配置文件
eKuiper的配置文件位于$eKuiper/etc/kuiper.yaml中。配置文件为yaml格式。应用程序可以通过环境变量进行配置。环境变量优先于yaml文件中的对应项。
```yaml
basic:
  # true|false, with debug level, it prints more debug info
  debug: false
  # true|false, if it's set to true, then the log will be print to console
  consoleLog: false
  # true|false, if it's set to true, then the log will be print to log file
  fileLog: true
  # How many hours to split the file
  rotateTime: 24
  # Maximum file storage hours
  maxAge: 72
  # Whether to ignore case in SQL processing. Note that, the name of customized function by plugins are case-sensitive.
  ignoreCase: true
```
# 用户指南
## 流: 无界的事件序列
流是eKuiper中数据源连接器的运行形式，他必须指定一个源类型来定义如何连接到外部资源。当作为一个流使用时，源必须是无界的，流的作用就像规则的触发器，每个事件都会触发规则中的计算。eKuiper不需要一个预先建立的模式。
```sql
CREATE STREAM   
    stream_name   
    ( column_name <data_type> [ ,...n ] )
    WITH ( property_name = expression [, ...] );
```
由2部分组成:
- 流的模式定义，模式是可选的;
- WITH子句中定义连接器类型和行为的属性，如序列化格式
流可以设置为共享的
## 表: 事件序列的快照
### 表
Table用于表示流的当前状态。它可以被认为是流的快照。用户可以使用 table 来保留一批数据进行处理。
- 扫描表(Scan Table): 内存中积累数据，适用于较小的数据集，表的内容不需要再规则之间共享
- 查询表(Lookup Table): 绑定外部表并按需查询，适用于较大的数据集，规则之间共享表的内容
与创建流的语法一样。
```sql
CREATE TABLE   
    table_name   
    ( column_name <data_type> [ ,...n ] )
    WITH ( property_name = expression [, ...] );
```
表支持与流相同的数据类型。表还支持所有流的属性。因此，表中也支持所有源类型。许多源不是批处理的，它们在任何给定时间点都有一个事件，这意味着表将始终只有一个事件。一个附加属性RETAIN_SIZE来指定表快照的大小，以便表可以保存任意数量的历史数据。
查询表的创建:
```sql
CREATE TABLE alertTable() WITH (DATASOURCE="0", TYPE="redis", KIND="lookup")
```
memory/redis/sql3种方式可以创建查询表
表是保留较为大量的状态的方法。扫描表将状态保存在内存中，而查找表将它们保存在外部，并可能是持久化的。扫描表更容易设置，而查找表可以很容易地连接到存在的持久化的状态。这两种类型都适用于流式批量综合计算。
### 扫描表
通常，表将流连接。与流连接时，表数据不会影响下游更新数据，它被视为静态引用数据，尽管它可能会在内部更新。2种使用场景:
- 数据补全
- 按历史状态过滤
典型用法是查找表:
```sql
CREATE TABLE table1 (
		id BIGINT,
		name STRING
	) WITH (DATASOURCE="lookup.json", FORMAT="JSON", TYPE="file");

SELECT * FROM demo INNER JOIN table1 on demo.id = table1.id
```
```sql
CREATE TABLE stateTable (
		id BIGINT,
		triggered bool
	) WITH (DATASOURCE="myTopic", FORMAT="JSON", TYPE="mqtt");

SELECT * FROM demo LEFT JOIN stateTable on demo.id = stateTable.id WHERE triggered=true
```
在此示例中，创建了一个表 stateTable 来记录来自 mqtt 主题 myTopic 的触发器状态。在规则中，会根据当前触发状态来过滤 demo 流的数据。
### 查询表
并非所有的数据都会经常变化，即使在实时计算中也是如此。在某些情况下，你可能需要用外部存储的静态数据来补全流数据。例如，用户元数据可能存储在一个关系数据库中，流数据中只有实时变化的数据，需要连接流数据与数据库中的批量数据才能补全出完整的数据。在早期的版本中，eKuiper支持了Table概念，用于在内存中保存较少数量的流数据，作为数据的快照供其他的流进行连接查询。这种 Table 适用于状态较少，状态实时性要求很高的场景。在 1.7.0及之后的版本中，eKuiper添加了新的查询表（Lookup Table）的概念，用于绑定外部静态数据，可以处理大量的批数据连接的需求。
#### 动态预警场景
预警功能是边缘计算中最常见的场景之一。当告警标准固定时，我们通常可以通过简单的 WHERE 语句进行告警条件的匹配并触发动作。然而在更复杂的场景中，告警条件可能是动态可配置的，并且根据不同的数据维度，例如设备类型会有有不同的预警值。接下来，我们将讲解如何针对这个场景创建规则。当采集到数据后，规则需要根据动态预警值进行过滤警告。场景输入
本场景中，我们有两个输入:
- 采集数据流，其中包含多种设备的实时采集数据;
- 预警值数据，每一类设备有对应的预警值，且预警值可更新
针对这两种输入，我们分别创建流和查询表进行建模。
创建数据流。假设数据流写入MQTT Topic scene1/data 中，则我们可通过以下REST API创建名为demoStream的数据流:
```json
 {"sql":"CREATE STREAM demoStream() WITH (DATASOURCE=\"scene1/data\", FORMAT=\"json\", TYPE=\"mqtt\")"}
```
创建查询表。假设预警值数据存储于Redis数据库0中，创建名为 alertTable的查询表。此处，若使用其他存储方式，可将type替换为对应的source类型，例如sql。
```json
{"sql":"CREATE TABLE alertTable() WITH (DATASOURCE=\"0\", TYPE=\"redis\", KIND=\"lookup\")"}
```
##### 预警值动态更新
动态预警值存储在Redis或者Sqlite等外部存储中。用户可通过应用程序对其进行更新也可通过eKuiper提供的Updatable Sink功能通过规则进行自动更新。本教程将使用规则，通过Redis sink对上文的Redis查询表进行动态更新。预警值规则与常规规则无异，用户可接入任意的数据源，做任意数据计算，只需要确保输出结果中包含更新指令字段action，例如`{"action":"upsert","id":1,"alarm":50}`。本教程中，我们使用 MQTT输入预警值更新指令通过规则更新Redis数据。创建MQTT流，绑定预警值更新指令数据流。假设更新指令通过MQTT topic scene1/alert发布。`{"sql":"CREATE STREAM alertStream() WITH (DATASOURCE=\"scene1/alert\", FORMAT=\"json\", TYPE=\"mqtt\")"}`
创建预警值更新规则。其中，规则接入了上一步创建的指令流，规则SQL只是简单的获取所有指令，然后在action中使用支持动态更新的redis sink。配置了redis的地址，存储数据类型；key使用的字段名设置为id，更新类型使用的字段名设置为action。这样，只需要保证指令流中包含id和 action字段就可以对Redis进行更新了。
```json
{
  "id": "ruleUpdateAlert",
  "sql":"SELECT * FROM alertStream",
  "actions":[
   {
     "redis": {
       "addr": "127.0.0.1:6379",
       "dataType": "string",
       "field": "id",
       "rowkindField": "action",
       "sendSingle": true
     }
  }]
}
```
接下来，我们可以向发送MQTT主题scene1/alert发送指令，更新预警值。例如：
```json
{"action":"upsert","id":1,"alarm":50}
{"action":"upsert","id":2,"alarm":80}
{"action":"upsert","id":3,"alarm":20}
{"action":"upsert","id":4,"alarm":50}
{"action":"delete","id":4}
{"action":"upsert","id":1,"alarm":55}
``` 
查看Redis数据库，应当可以看到数据被写入和更新。该规则为流式计算规则，后续也会根据订阅的数据进行持续的更新。
##### 根据设备类型动态预警
前文中，我们已经创建了采集数据流，并且创建了可动态更新的预警条件查询表。接下来，我们可以创建规则，连接采集数据流与查询表以获取当前设备类型的预警值，然后判断是否需要预警。
```json
{
  "id": "ruleAlert",
  "sql":"SELECT device, value FROM demoStream INNER JOIN alertTable ON demoStream.deviceKind = alertTable.id WHERE demoStream.value > alertTable.alarm",
  "actions":[
    {
      "mqtt": {
        "server": "tcp://myhost:1883",
        "topic": "rule/alert",
        "sendSingle": true
      }
    }
  ]
}
```
在规则中，我们根据采集数据流中的deviceKind字段与查询表中的id字段（此处为Redis中的key）进行连接，获得查询表中对应设备类型的预警值 alarm。接下来在WHERE语句中过滤出采集的数值超过预警值的数据，并将其发送到MQTT的rule/alert主题中进行告警。发送MQTT指令到采集数据流的主题scene1/data，模拟采集数据采集，观察规则告警结果。例如下列数据，虽然采集值相同，但因为不同的设备类型告警阈值不同，它们的告警情况可能有所区别。
```json
{"device":"device1","deviceKind":1,"value":54}
{"device":"device12","deviceKind":2,"value":54}
{"device":"device22","deviceKind":3,"value":54}
{"device":"device2","deviceKind":1,"value":54}
```
#### 数据补全场景
流数据变化频繁，数据量大，通常只包含需要经常变化的数据；而不变或者变化较少的数据通常存储于数据库等外部存储中。在应用处理时，通常需要将流数据中缺少的静态数据补全。例如，流数据中包含了设备的ID，但设备的具体名称，型号的描述数据存储于数据库中。本场景中，我们将介绍如何将流数据与批数据结合，进行自动数据补全。

##### SQL插件安装和配置
本场景将使用MySQL作为外部表数据存储位置。eKuiper提供了预编译的 SQL source插件，可访问MySQL数据并将其作为查询表。因此，在开始教程之前，我们需要先安装SQL source插件。使用eKuiper manager管理控制台，可直接在插件管理中，点击创建插件，如下图选择SQL source插件进行安装。本场景将以MySQL为例，介绍如何与关系数据库进行连接。用户需要启动MySQL实例。在MySQL中创建表devices, 其中包含id, name, deviceKind等字段并提前写入内容。在管理控制台中，创建SQL source 配置，指向创建的MySQL实例。由于SQL数据库IO延迟较大，用户可配置是否启用查询缓存及缓存过期时间等。
```yaml
lookup:
   cache: true # 启用缓存
   cacheTtl: 600 # 缓存过期时间
   cacheMissingKey: true # 是否缓存未命中的情况
```
##### 场景输入
本场景中，我们有两个输入:
- 采集数据流，与场景1相同，包含多种设备的实时采集数据。本教程中，采集的数据流通过 MQTT 协议进行实时发送。
- 设备信息表，每一类设备对应的名字，型号等元数据。本教程中，设备信息数据存储于 MySQL 中。
针对这两种输入，我们分别创建流和查询表进行建模。
创建数据流。假设数据流写入MQTT Topic scene2/data中，则我们可通过以下REST API创建名为demoStream2的数据流。
```json
{"sql":"CREATE STREAM demoStream2() WITH (DATASOURCE=\"scene2/data\", FORMAT=\"json\", TYPE=\"mqtt\")"}
```
创建查询表。假设设备数据存储于MySQL数据库devices中，创建名为 deviceTable的查询表。CONF_KEY设置为上一节中创建的SQL source配置。
```json
{"sql":"CREATE TABLE deviceTable() WITH (DATASOURCE=\"devices\", CONF_KEY=\"mysql\",TYPE=\"sql\", KIND=\"lookup\")"}
``` 
##### 数据补全规则
流和表都创建完成后，我们就可以创建补全规则了。
```json
{
  "id": "ruleLookup",
  "sql": "SELECT * FROM demoStream2 INNER JOIN deviceTable ON demoStream.deviceId = deviceTable.id",
  "actions": [{
    "mqtt": {
      "server": "tcp://myhost:1883",
      "topic": "rule/lookup",
      "sendSingle": true
    }
  }]
}
``` 
在这个规则中，通过流数据中的deviceId字段与设备数据库中的id进行匹配连接，并输出完整的数据。用户可以根据需要，在select语句中选择所需的字段。
#### 总结
本教程以两个场景为例，介绍了如何使用查询表进行流批结合的计算。我们分别使用了Redis和MySQL作为外部查询表的类型并展示了如何通过规则动态更新外部存储的数据。用户可以使用查询表工具探索更多的流批结合运算的场景。
## 规则: 查询和动作
### 规则
规则由JSON定义
```json
{
  "id": "rule1",
  "sql": "SELECT demo.temperature, demo1.temp FROM demo left join demo1 on demo.timestamp = demo1.timestamp where demo.temperature > demo1.temp GROUP BY demo.temperature, HOPPINGWINDOW(ss, 20, 10)",
  "actions": [
    {
      "log": {}
    },
    {
      "mqtt": {
        "server": "tcp://47.52.67.87:1883",
        "topic": "demoSink"
      }
    }
  ]
}
```
| **参数名** | **是否可选**              | **说明**                           |
|---------|-----------------------|----------------------------------|
| id      | 否                     | 规则 id, 规则 id 在同一 eKuiper 实例中必须唯一 |
| name    | 是                     | 规则显示的名字或者描述                      |
| sql     | 如果 graph 未定义，则该属性必须定义 | 为规则运行的 sql 查询                    |
| actions | 如果 graph 未定义，则该属性必须定义 | Sink 动作数组                        |
| graph   | 如果 sql 未定义，则该属性必须定义   | 规则有向无环图的 JSON 表示                 |
| options | 是                     | 选项列表                             |

一个规则代表了一个流处理流程，定义了从将数据输入流的数据源到各种处理逻辑，再到将数据输入到外部系统的动作。有两种方法来定义规则的业务逻辑。要么使用SQL/动作组合，要么使用新增加的图API。选项支持:

| **选项名**            | **类型和默认值** | **说明 **                                                                                         |
|--------------------|------------|-------------------------------------------------------------------------------------------------|
| isEventTime        | bool:false | 使用事件时间还是将时间用作事件的时间戳。 如果使用事件时间，则将从有效负载中提取时间戳。 必须通过 stream 定义指定时间戳记。                              |
| lateTolerance      | int64:0    | 在使用事件时间窗口时，可能会出现元素延迟到达的情况。 LateTolerance 可以指定在删除元素之前可以延迟多少时间（单位为 ms）。 默认情况下，该值为0，表示后期元素将被删除。    |
| concurrency        | int: 1     | 一条规则运行时会根据 sql 语句分解成多个 plan 运行。该参数设置每个 plan 运行的线程数。该参数值大于1时，消息处理顺序可能无法保证。                       |
| bufferLength       | int: 1024  | 指定每个 plan 可缓存消息数。若缓存消息数超过此限制，plan 将阻塞消息接收，直到缓存消息被消费使得缓存消息数目小于限制为止。此选项值越大，则消息吞吐能力越强，但是内存占用也会越多。  |
| sendMetaToSink     | bool:false | 指定是否将事件的元数据发送到目标。 如果为 true，则目标可以获取元数据信息。                                                        |
| sendError          | bool: true | 指定是否将运行时错误发送到目标。如果为 true，则错误会在整个流中传递直到目标。否则，错误会被忽略，仅打印到日志中。                                     |
| qos                | int:0      | 指定流的 qos。 值为0对应最多一次； 1对应至少一次，2对应恰好一次。 如果 qos 大于0，将激活检查点机制以定期保存状态，以便可以从错误中恢复规则。                  |
| checkpointInterval | int:300000 | 指定触发检查点的时间间隔（单位为 ms）。 仅当 qos 大于0时才有效。                                                           |
| restartStrategy    | 结构         | 指定规则运行失败后自动重新启动规则的策略。这可以帮助从可恢复的故障中回复，而无需手动操作。请查看规则重启策略了解详细的配置项目。                                |

### 规则管道
我们可以通过将先前规则的结果导入后续规则来形成规则管道。这可以通过使用中间存储或MQ（例如mqtt消息服务器）来实现。通过同时使用内存源和目标，我们可以创建没有外部依赖的规则管道。规则管道将是隐式的。每个规则都可以使用一个内存目标/源。这意味着每个步骤将使用现有的api单独创建（示例如下所示）。
```json
# 1 创建源流
{"sql" : "create stream demo () WITH (DATASOURCE=\"demo\", FORMAT=\"JSON\")"}
# 2 创建规则和内存目标
{
  "id": "rule1",
  "sql": "SELECT * FROM demo WHERE isNull(temperature)=false",
  "actions": [{
    "log": {
    },
    "memory": {
      "topic": "home/ch1/sensor1"
    }
  }]
}
#3 从内存主题创建一个流
{"sql" : "create stream sensor1 () WITH (DATASOURCE=\"home/+/sensor1\", FORMAT=\"JSON\", TYPE=\"memory\")"}
#4 从内存主题创建另一个要使用的规则
{
  "id": "rule2-1",
  "sql": "SELECT avg(temperature) FROM sensor1 GROUP BY CountWindow(10)",
  "actions": [{
    "log": {
    },
    "memory": {
      "topic": "analytic/sensors"
    }
  }]
}
{
  "id": "rule2-2",
  "sql": "SELECT temperature + 273.15 as k FROM sensor1",
  "actions": [{
    "log": {
    }
  }]
}
```
通过使用内存主题作为桥梁，我们现在创建一个规则管道:rule1->{rule2-1, rule2-2}。管道可以是多对多的，而且非常灵活。请注意，内存目标可以与其他目标一起使用，为一个规则创建多个规则动作。并且内存源主题可以使用通配符订阅过滤后的主题列表。
### 状态与容错
eKuiper支持有状态的规则流，有2种状态:
- 窗口操作和可回溯源的内部状态
- 对流上下文扩展公开的用户状态，可以参考状态存储。

默认情况下，所有状态仅驻留在内存中，这意味着如果流异常退出，则状态将消失。为了使状态容错，Kuipler需要将状态检查点放入永久性存储中，以便在发生错误后恢复。将规则选项qos设置为1或2将启用检查点。通过设置checkpointInterval选项配置检查点间隔时间。当在流处理应用程序中出现问题时，可能会造成结果丢失或重复。对于qos的3个选项，其对应行为将是：
- 最多一次（0）: eKuiper 不会采取任何行动从问题中恢复
- 至少一次（1）: 没有任何结果丢失，但是您可能会遇到重复的结果
- 恰好一次（2）: 没有丢失或重复任何结果

考虑到eKuiper通过回溯和重播源数据流从错误中恢复，将理想情况描述为恰好一次时，并不意味着每个事件都会被恰好处理一次。相反，这意味着每个事件将只会对由eKuiper管理的状态造成一次影响。如果您不需要恰好一次，则可以通过使用AT_LEAST_ONCE配置eKuiper，进而获得一些更好的效果。
## 数据源
有内置源和扩展源。源连接器提供了与外部系统的连接，以便将数据加载进来。有2种数据加载机制:
- 扫描: 像一个由事件驱动的流一样，一个一个地加载数据事件。这种模式的源可以用在流或者扫描表中。
- 查找: 在需要时引用外部内容，只用于查找表。

每个源将支持一种或者2种模式。
1. 内置源
   - [MQTT](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/mqtt.html)
   - [Neuron](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/neuron.html)
   - [EdgeX](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/edgex.html)
   - [HTTP PULL](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/http_pull.html)
   - [HTTP PUSH](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/http_push.html)
   - [Memory](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/memory.html)
   - [File](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/file.html)
   - [Redis](https://ekuiper.org/docs/zh/latest/guide/sources/builtin/redis.html)
2. 预定义的源插件
   还有一些额外的源插件，可以使用，托管在https://packages.emqx.net/kuiper-plugins/$version/$os/sources/$type_$arch.zip，预定义的有:
   - [Zero MQ](https://ekuiper.org/docs/zh/latest/guide/sources/plugin/zmq.html)
   - [Random](https://ekuiper.org/docs/zh/latest/guide/sources/plugin/random.html)
   - [SQL](https://ekuiper.org/docs/zh/latest/guide/sources/plugin/sql.html)

用户通过流或者表的方式使用源。
## 数据汇
在eKuiper中叫做动作，有内置的和扩展的。
1. 内置动作
   - [MQTT](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/mqtt.html)
   - [Neuron](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/neuron.html)
   - [EdgeX](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/edgex.html)
   - [Rest](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/rest.html)
   - [Memory](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/memory.html)
   - [Log](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/log.html)
   - [Nop](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/nop.html)
   - [Redis](https://ekuiper.org/docs/zh/latest/guide/sinks/builtin/redis.html)
2. 预定义动作插件
   - [Zero MQ](https://ekuiper.org/docs/zh/latest/guide/sinks/plugin/zmq.html)
   - [File](https://ekuiper.org/docs/zh/latest/guide/sinks/plugin/file.html)
   - [InfluxDB](https://ekuiper.org/docs/zh/latest/guide/sinks/plugin/influx.html)
   - [InfluxDBV2](https://ekuiper.org/docs/zh/latest/guide/sinks/plugin/influx2.html)
   - [Tdengine](https://ekuiper.org/docs/zh/latest/guide/sinks/plugin/tdengine.html)
   - [Image](https://ekuiper.org/docs/zh/latest/guide/sinks/plugin/image.html)
### 更新
默认情况下，Sink将数据附加到外部系统中。一些外部系统，如SQL DB本身是可更新的，允许更新或删除数据。与查找源类似，只有少数Sink是天然"可更新"的。可更新的 Sink必须支持插入、更新和删除。产品自带的Sink种，可更新的包括:
- Memory Sink
- Redis Sink
- SQL Sink
为了激活更新功能，Sink必须设置rowkindField 属性，以指定数据中的哪个字段代表要采取的动作。在下面的例子中，rowkindField被设置为`action`:
```json
{"redis": {
  "addr": "127.0.0.1:6379",
  "dataType": "string",
  "field": "id",
  "rowkindField": "action",
  "sendSingle": true
}}
```
流入的数据必须有一个字段来表示更新的动作，`action`字段是要执行的动作。动作可以是插入、更新、upset和删除。
```sql
{"action":"update", "id":5, "name":"abc"}
```
### 公共属性
每个sink都有基于共同的属性的属性集。每个动作可以定义自己的属性。当前有以下的公共属性:

| **属性名**              | **类型和默认值**                       | **描述**                                                                                                                                                                                                                                   |
|----------------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| concurrency          | int: 1                           | 设置运行的线程数。该参数值大于1时，消息发出的顺序可能无法保证。                                                                                                                                                                                                         |
| bufferLength         | int: 1024                        | 设置可缓存消息数目。若缓存消息数超过此限制，sink将阻塞消息接收，直到缓存消息被消费使得缓存消息数目小于限制为止。                                                                                                                                                                               |
| runAsync             | bool:false                       | 设置是否异步运行输出操作以提升性能。请注意，异步运行的情况下，输出结果顺序不能保证。                                                                                                                                                                                               |
| omitIfEmpty          | bool: false                      | 如果配置项设置为 true，则当 SELECT 结果为空时，该结果将不提供给目标运算符。                                                                                                                                                                                             |
| sendSingle           | bool: false                      | 输出消息以数组形式接收，该属性意味着是否将结果一一发送。 如果为false，则输出消息将为{"result":"${the string of received message}"}。 例如，{"result":"[{\"count\":30},"\"count\":20}]"}。否则，结果消息将与实际字段名称一一对应发送。 对于与上述相同的示例，它将发送 {"count":30}，然后发送{"count":20}到 RESTful 端点。默认为 false。 |
| dataTemplate         | string: ""                       | golang 模板 (opens new window)格式字符串，用于指定输出数据格式。 模板的输入是目标消息，该消息始终是映射数组。 如果未指定数据模板，则将数据作为原始输入。                                                                                                                                               |
| format               | string: "json"                   | 编码格式，支持 "json" 和 "protobuf"。若使用 "protobuf", 需通过 "schemaId" 参数设置模式，并确保模式已注册。                                                                                                                                                              |
| schemaId             | string: ""                       | 编码使用的模式。                                                                                                                                                                                                                                 |
| delimiter            | string: ","                      | 仅在使用 delimited 格式时生效，用于指定分隔符，默认为逗号。                                                                                                                                                                                                      |
| enableCache          | bool: 默认值为etc/kuiper.yaml 中的全局配置 | 是否启用sink cache。缓存存储配置遵循 etc/kuiper.yaml 中定义的元数据存储的配置。                                                                                                                                                                                    |
| memoryCacheThreshold | int: 默认值为全局配置                    | 要缓存在内存中的消息数量。出于性能方面的考虑，最早的缓存信息被存储在内存中，以便在故障恢复时立即重新发送。这里的数据会因为断电等故障而丢失。                                                                                                                                                                   |
| maxDiskCache         | int: 默认值为全局配置                    | 缓存在磁盘中的信息的最大数量。磁盘缓存是先进先出的。如果磁盘缓存满了，最早的一页信息将被加载到内存缓存中，取代旧的内存缓存。                                                                                                                                                                           |
| bufferPageSize       | int: 默认值为全局配置                    | 缓冲页是批量读/写到磁盘的单位，以防止频繁的IO。如果页面未满，eKuiper 因硬件或软件错误而崩溃，最后未写入磁盘的页面将被丢失。                                                                                                                                                                      |
| resendInterval       | int: 默认值为全局配置                    | 故障恢复后重新发送信息的时间间隔，防止信息风暴。                                                                                                                                                                                                                 |
| cleanCacheAtStop     | bool: 默认值为全局配置                   | 是否在规则停止时清理所有缓存，以防止规则重新启动时对过期消息进行大量重发。如果不设置为true，一旦规则停止，内存缓存将被存储到磁盘中。否则，内存和磁盘规则会被清理掉                                                                                                                                                      |

有些情况下，用户需要按照数据把结果发送到不同的目标中。例如，根据收到的数据，把计算结果发到不同的mqtt主题中。使用基于数据模板格式的动态属性，可以实现这样的功能。在以下的例子中，目标的topic属性是一个数据模板格式的字符串从而在运行时会将消息发送到动态的主题中。
```json
{
  "id": "rule1",
  "sql": "SELECT topic FROM demo",
  "actions": [{
    "mqtt": {
      "sendSingle": true,
      "topic": "prefix/{{.topic}}"
    }
  }]
}
```
### 缓存
动作用于将处理结果发送到外部系统中，存在外部系统不可用的情况，特别是在从边到云的场景中。例如，在弱网情况下，边到云的网络连接可能会不时断开和重连。因此，动作提供了缓存功能，用于在发送错误的情况下暂存数据，并在错误恢复之后自动重发缓存数据。动作的缓存可分为内存和磁盘的两级存储。用户可配置内存缓存条数，超过上限后，新的缓存将离线存储到磁盘中。缓存将同时保存在内存和磁盘中，这样缓存的容量就变得更大了；它还将持续检测故障恢复状态，并在不重新启动规则的情况下重新发送。离线缓存的保存位置根据etc/kuiper.yaml里的store配置决定，默认为sqlite 。如果磁盘存储是sqlite，所有的缓存将被保存到data/cache.db文件。每个sink将有一个唯一的sqlite表来保存缓存。缓存的计数添加到sink的指标中的 buffer length部分。
每个sink都可以配置自己的缓存机制。每个sink的缓存流程是相同的。如果启用了缓存，所有sink的事件都会经过两个阶段：首先是将所有内容保存到缓存中；然后在收到ack后删除缓存:
- 错误检测：发送失败后，sink应该通过返回特定的错误类型来识别可恢复的失败（网络等），这将返回一个失败的ack，这样缓存就可以被保留下来。对于成功的发送或不可恢复的错误，将发送一个成功的 ack 来删除缓存。
- 缓存机制：缓存将首先被保存在内存中。如果超过了内存的阈值，后面的缓存将被保存到磁盘中。一旦磁盘缓存超过磁盘存储阈值，缓存将开始rotate，即内存中最早的缓存将被丢弃，并加载磁盘中最早的缓存来代替。
- 重发策略：目前缓存机制仅可运行在默认的同步模式中，如果有一条消息正在发送中，则会等待发送的结果以继续发送下个缓存数据。否则，当有新的数据到来时，发送缓存中的第一个数据以检测网络状况。如果发送成功，将按顺序链式发送所有内存和磁盘中的所有缓存。链式发送可定义一个发送间隔，防止形成消息风暴.

Sink缓存的配置有两个层次。etc/kuiper.yaml中的全局配置，定义所有规则的默认行为。还有一个规则sink层的定义，用来覆盖默认行为A: 
- enableCache：是否启用sink cache。缓存存储配置遵循etc/kuiper.yaml中定义的元数据存储的配置;
- memoryCacheThreshold：要缓存在内存中的消息数量。出于性能方面的考虑，最早的缓存信息被存储在内存中，以便在故障恢复时立即重新发送。这里的数据会因为断电等故障而丢失;
- maxDiskCache: 缓存在磁盘中的信息的最大数量。磁盘缓存是先进先出的。如果磁盘缓存满了，最早的一页信息将被加载到内存缓存中，取代旧的内存缓存;
- bufferPageSize。缓冲页是批量读/写到磁盘的单位，以防止频繁的IO。如果页面未满，eKuiper 因硬件或软件错误而崩溃，最后未写入磁盘的页面将被丢失;
- resendInterval: 故障恢复后重新发送信息的时间间隔，防止信息风暴;
- cleanCacheAtStop：是否在规则停止时清理所有缓存，以防止规则重新启动时对过期消息进行大量重发。如果不设置为true，一旦规则停止，内存缓存将被存储到磁盘中。否则，内存和磁盘规则会被清理掉.

在以下规则的示例配置中，log sink没有配置缓存相关选项，因此将会采用全局默认配置；而mqtt sink进行了自身缓存策略的配置.
```json
{
  "id": "rule1",
  "sql": "SELECT * FROM demo",
  "actions": [{
    "log": {},
    "mqtt": {
      "server": "tcp://127.0.0.1:1883",
      "topic": "result/cache",
      "qos": 0,
      "enableCache": true,
      "memoryCacheThreshold": 2048,
      "maxDiskCache": 204800,
      "bufferPageSize": 512,
      "resendInterval": 10
    }
  }]
}
```
### 资源引用
动作支持配置复用。用户只需要在sinks文件夹中创建与目标动作同名的yaml文件并按照源一样的形式写入配置。例如，针对MQTT动作场景， 用户可以在sinks目录下创建mqtt.yaml文件，并写入如下内容:
```yaml
test:
  qos: 1
  server: "tcp://broker.emqx.io:1883"
```
```yaml
 {
      "mqtt": {
        "resourceId": "test",
        "topic": "devices/demo_001/messages/events/",
        "protocolVersion": "3.1.1",
        "clientId": "demo_001",
        "username": "xyz.azure-devices.net/demo_001/?api-version=2018-06-30",
        "password": "SharedAccessSignature sr=*******************",
        "retained": false
      }
}
```
## 序列化
eKuiper计算过程中使用的是基于Map的数据结构，因此source/sink连接外部系统的过程中，通常需要进行编解码以转换格式。在source/sink中，都可以通过配置参数format和schemaId来指定使用的编解码方案。编解码的格式分为2种:
- 有模式
- 无模式
当前支持的格式有json\binary\delimiter\protobuf\custom，protobuf是有模式的格式。有模式的格式需要先注册模式，然后再设置格式的同时，设置引用的模式，例如，在使用MQTT sink时，可以配置格式和模式
```json
{
  "mqtt": {
    "server": "tcp://127.0.0.1:1883",
    "topic": "sample",
    "format": "protobuf",
    "schemaId": "proto1.Book"
  }
}
```
所有的格式都提供了编解码的能力，也可选的提供了数据结构的定义，及模式。编解码的计算可内置，如JSON解析，可动态解析模式进行编解码，如Protobuf解析*ptotobuf.也可以使用用户自定义的静态插件(*.so)进行解析。静态解析的性能最好。动态解析使用更为灵活。

| **格式**    | **编解码**              | **自定义编解码** | **模式** |
|-----------|----------------------|------------|--------|
| json      | 内置                   | 不支持        | 不支持    |
| binary    | 内置                   | 不支持        | 不支持    |
| delimiter | 内置，必须配置 delimiter 属性 | 不支持        | 不支持    |
| protobuf  | 内置                   | 支持         | 支持且必需  |
| custom    | 无内置                  | 支持且必需      | 支持且可选  |

当用户使用custom/protobuf格式时，可采用go语言插件的形式自定义格式的编解码和模式。其中protobuf仅支持自定义编解码，模式需要通过*.proto文件定义，自定义格式的步骤如下:
- 实现编解码相关接口: 其中Encode是编码函数，将传入的数据(当前总是为`map[string]interface{}`)编码为字节数组。而Decode解码函数则相反，将字节数组解码为`map[string]interface{}`。解码函数在source中被调用，编码函数在sink中被调用。
  ```go
  // Converter converts bytes & map or []map according to the schema
  type Converter interface {
      Encode(d interface{}) ([]byte, error)
      Decode(b []byte) (interface{}, error)
  }
  ```
- 实现数据结构描述接口(格式为custom时可选): 若自定义的格式为强类型，可实现该接口。接口返回一个类JSON schema的字符串，供source使用。返回的数据结构将作为一个物理schema使用，帮助eKuiper实现编译解析阶段的SQL验证和优化等能力
  ```go
  type SchemaProvider interface {
      GetSchemaJson() string
  }
  ```
- 编译为插件so文件: 通常格式的扩展无需依赖eKuiper的主项目。由于Go语言插件系统的限制，插件的编译仍然需要在eKuiper主程序相同的编译环境中进行，包括操作相同，Go语言版本等。若需要部署到官方docker中，则可使用对应的docker镜像进行编译。
  ```shell
  go build -trimpath --buildmode=plugin -o data/test/myFormat.so internal/converter/custom/test/*.go
  ```
- 通过REST API进行模式注册: 
  ```shell
  ###
  POST http://{{host}}/schemas/custom
  Content-Type: application/json

  {
    "name": "custom1",
    "soFile": "file:///tmp/custom1.so"
  }
  ```
- 在source/sink中，通过format/schemaId参数使用自定义格式。
### 模式
模式是一套元数据，用于定义数据结构。例如, Protobuf格式中使用.proto文件作为模式定义传输的数据格式，eKuiper仅支持protobuf/custom2种模式。模式采用文件的形式存储，用户可以通过配置文件或者API进行模式的注册。模式的存储位置位于data/schemas/${type},protobuf格式的模式文件，位于data/schemas/protobuf.eKuiper启动时，将会扫描该配置文件夹并自动注册里面的模式。若需要再运行中注册和管理模式。可以通过模式注册表API来完成。API的操作会作用到文件系统中。用户可以使用模式注册表API再运行时对模式进行增删改查。
## AI/ML
### 使用原生插件实现AI函数
