- Scan Source: Bounded
- Lookup Source: Sync Mode
- Sink: Batch
- Sink: Streaming Append & Upsert Mode
JDBC连接器允许使用JDBC驱动向任意类型的关系型数据库读取或者写入数据，本文档描述了针对关系型数据库如何通过建立JDBC连接器来执行SQL查询。如果在DDL中定义了主键，JDBC sink将以upsert模式与外部系统交换UPDATE/DELETE消息；否则，它将以append模式与外部系统交换消息且不支持消息UPDATE/DELETE消息。
# 依赖
为了使用JDBC连接器，需要在项目中添加下面的依赖:
```xml
<dependency>
  <groupId>org.apache.flink</groupId>
  <artifactId>flink-connector-jdbc</artifactId>
  <version>1.16.0</version>
</dependency>
```
在连接到具体数据库时，也需要对应的驱动依赖，目前支持的驱动如下:

|Driver|Group Id|Artifact Id|
|:---|:---|:---|
|MySQL|mysql|mysql-connector-java|
|Oracle|com.oracle.database.jdbc|ojdbc8|
|PostgreSQL|org.postgresql|postgresql|
|Derby|org.apache.derby|derby|

# 如何创建JDBC表
```sql
-- 在 Flink SQL 中注册一张 MySQL 表 'users'
CREATE TABLE MyUserTable (
  id BIGINT,
  name STRING,
  age INT,
  status BOOLEAN,
  PRIMARY KEY (id) NOT ENFORCED
) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:mysql://localhost:3306/mydatabase',
   'table-name' = 'users'
);

-- 从另一张表 "T" 将数据写入到 JDBC 表中
INSERT INTO MyUserTable
SELECT id, name, age, status FROM T;

-- 查看 JDBC 表中的数据
SELECT id, name, age, status FROM MyUserTable;

-- JDBC 表在时态表关联中作为维表
SELECT * FROM myTopic
LEFT JOIN MyUserTable FOR SYSTEM_TIME AS OF myTopic.proctime
ON myTopic.key = MyUserTable.id;
```
# 连接器参数
|参数|是否必填|默认值|类型|描述|
|:---|:---|:---|:---|:---|
|connector|Y||String|jdbc，指定使用什么类型的连接器|
|url|Y||String|jdnc连接库url|
|table-name|Y||String|连接到JDBC表的名称|
|driver|N||String|用于连接到此URL的JDBC驱动类名，如果不设置，将自动从URL中推导|
|username|N||String|JDBC 用户名。如果指定了'username' 和'password'中的任一参数，则两者必须都被指定。|
|password|N||String|JDBC密码|
|connection.max-retry-timeout|N|60s|Duration|最大重试超时时间，以秒为单位且不应该小于1秒|
|scan.partition.column|N||String|用于将输入进行分区的列名。请参阅下面的分区扫描部分了解更多详情。|
|scan.partition.num|N||String|分区数|
|scan.partition.lower-bound|N||String|第一个分区的最小值|
|scan.partition.upper-bound|N||String|最后一个分区的最大值|
|scan.fetch-size|N|0|Integer|每次循环读取时应该从数据库中获取的行数。如果指定的值为'0'，则该配置项会被忽略|
|scan.auto-commit|N|true|Boolean|在JDBC驱动程序上设置 auto-commit标志，它决定了每个语句是否在事务中自动提交。有些 JDBC驱动程序，特别是Postgres，可能需要将此设置为false以便流化结果|
|lookup.cache|N|NONE|NONE/PARTIAL|维表的缓存策略。目前支持NONE（不缓存）和PARTIAL（只在外部数据库中查找数据时缓存）|
|ookup.cache.max-rows|N||Integer|维表缓存的最大行数，若超过该值，则最老的行记录将会过期。使用该配置时"lookup.cache"必须设置为"PARTIAL”。请参阅下面的Lookup Cache部分了解更多详情|
|lookup.partial-cache.expire-after-write|N||Duration|在记录写入缓存后该记录的最大保留时间。使用该配置时"lookup.cache"必须设置为"PARTIAL"。请参阅下面的Lookup Cache部分了解更多详情|
|lookup.partial-cache.expire-after-access|N||Duration|在缓存中的记录被访问后该记录的最大保留时间。使用该配置时"lookup.cache"必须设置为"PARTIAL"。请参阅下面的 Lookup Cache部分了解更多详情|
|lookup.partial-cache.caching-missing-key|N|true|Boolean|是否缓存维表中不存在的键，默认为true。使用该配置时 "lookup.cache"必须设置为"PARTIAL"|
|lookup.max-retries|N|3|Integer|查询数据库失败的最大重试次数|
|sink.buffer-flush.max-rows|N|100|Integer|flush前缓存记录的最大值，可以设置为'0'来禁用它|
|sink.buffer-flush.interval|N|1s|Duration|flush间隔时间，超过该时间后异步线程将flush数据。可以设置为'0'来禁用它。注意, 为了完全异步地处理缓存的flush事件，可以将'sink.buffer-flush.max-rows'设置为'0'并配置适当的flush时间间隔|
|sink.max-retries|N|3|Integer|写入记录到数据库失败后的最大重试次数|
|sink.parallelism|N||Integer|用于定义JDBC sink算子的并行度。默认情况下，并行度是由框架决定: 使用与上游链式算子相同的并行度|
# 特性
## 键处理
当写入数据到外部数据库时，Flink会使用DDL中定义的主键。如果定义了主键，则连接器将以upsert模式工作，否则连接器将以append模式工作。在upsert模式下，Flink将会根据主键判断插入新行或者更新已存在的行，这种方式可以确保幂等性。为了确保输出结果是符合预期的，推荐为表定义主键并且确保主键是底层数据库中表的唯一键或者主键。在append模式下，Flink会把所有记录解释为INSERT，如果违反了底层数据库中主键或者唯一约束，INSERT会插入失败。有关PRIMARY KEY语法的更多详细信息，请参见[CREATE TABLE DDL](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/dev/table/sql/create/#create-table)
## 分区扫描
为了在并行Source实例中加速读取数据，Flink为JDBCtable提供了分区扫描的特性。如果下述分区扫描参数中的任一项被指定，则下述所有的分区扫描参数必须都被指定。这些参数描述了在并行读取数据时如何对表进行分区。`scan.partition.column`必须是相关表中的数字、日期或时间戳列。注意，`scan.partition.lower-bound`和`scan.partition.upper-bound`用于决定分区的起始位置和过滤表中的数据。如果是批处理作业，也可以在提交 flink 作业之前获取最大值和最小值。
- scan.partition.column:输入用于进行分区的列名;
- scan.partition.num: 分区数;
- scan.partition.lower-bound: 第一个分区的最小值;
- scan.partition.upper-bound: 最后一个分区的最大值.

## Lookup Cache
JDBC连接器可以用在时态表关联中作为一个可lookup的source(也称为维表)，当前只支持同步的查找模式。默认情况下，lookup cache是未启用的，你可以设置`lookup.cache=PARTIAL`参数来启用。lookup cache的主要目的是用于提高时态表关联JDBC连接器的性能。默认情况下，lookup cache不开启，所以所有请求都会发送到外部数据库。当lookup cache被启用时，每个进程(即TaskManager)将维护一个缓存。Flink将优先查找缓存，只有当缓存未查找到时才向外部数据库发送请求，并使用返回的数据更新缓存。当缓存命中最大缓存行`lookup.partial-cache.max-rows`或者当行超过`lookup.partial-cache.expire-after-write`或者`lookup.partial-cache.expire-after-access`指定的最大存活时间，缓存中的行将被设备为过期，缓存中的记录可能不是最新的，用户可以将缓存记录超时设置为一个更小的值以获得更好的刷新数据，但这可能会增加发送到数据库的请求数，所以要做好吞吐量和正确性之间的平衡。默认情况下，flink会缓存主键的空查询结果，你可以通过将`lookup.partial-cache.caching-missing-key=false`来禁止行为。
## 幂等写入
如果在DDL中定义了主键，JDBC sink将使用upsert语义而不是普通的INSERT语句。upsert语义指的是如果底层数据库中存在违反唯一性约束，则原子的添加新行或更新现有行，这种方式确保了幂等性。如果出现故障，Flink作业会从上次成功的checkpoint恢复并重新处理，这可能导致在恢复过程中重复处理消息。强烈推荐使用upsert模式，因为如果需要重复处理记录，它有助于避免违反数据库主键约束和产生重复数据。除了故障恢复场景外，数据源(kafka topic)也可能随着时间的推移自然地包含多个具有相同主键的记录，这使得upsert模式是用户期待的。由于upsert没有标准的语法，因此下表描述了不同数据库的DML语法:
|database|upsert Grammar|
|:---|:---|
|MySQL|INSERT .. ON DUPLICATE KEY UPDATE ..|
|Oracle|MERGE INTO .. USING (..) ON (..)
WHEN MATCHED THEN UPDATE SET (..)
WHEN NOT MATCHED THEN INSERT (..)
VALUES (..)|
|PostgreSQL|INSERT .. ON CONFLICT .. DO UPDATE SET ..|

# JDBC Catalog


