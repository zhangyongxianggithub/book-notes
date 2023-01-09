MySQL CDC 连接器允许从 MySQL 数据库读取快照数据和增量数据。本文描述了如何设置 MySQL CDC 连接器来对 MySQL 数据库运行 SQL 查询。
# 如何创建 MySQL CDC 表
```sql
-- 每 3 秒做一次 checkpoint，用于测试，生产配置建议5到10分钟                      
Flink SQL> SET 'execution.checkpointing.interval' = '3s';   

-- 在 Flink SQL中注册 MySQL 表 'orders'
Flink SQL> CREATE TABLE orders (
     order_id INT,
     order_date TIMESTAMP(0),
     customer_name STRING,
     price DECIMAL(10, 5),
     product_id INT,
     order_status BOOLEAN,
     PRIMARY KEY(order_id) NOT ENFORCED
     ) WITH (
     'connector' = 'mysql-cdc',
     'hostname' = 'localhost',
     'port' = '3306',
     'username' = 'root',
     'password' = '123456',
     'database-name' = 'mydb',
     'table-name' = 'orders');
  
-- 从订单表读取全量数据(快照)和增量数据(binlog)
Flink SQL> SELECT * FROM orders;
```
# 数据类型映射
|MySQL type|Flink SQL type|NOTE|
|:---|:---|:---|
|TINYINT|TINYINT||
|SMALLINT<br>TINYINT UNSIGNED<br>TINYINT UNSIGNED ZEROFILL|SMALLINT||
|INT<br>MEDIUMINT<br>SMALLINT UNSIGNED<br>SMALLINT UNSIGNED ZEROFILL|INT||
|BIGINT<br>INT UNSIGNED<br>INT UNSIGNED ZEROFILL<br>MEDIUMINT UNSIGNED<br>MEDIUMINT UNSIGNED ZEROFILL|BIGINT||
|BIGINT UNSIGNED<br>BIGINT UNSIGNED ZEROFILL<br>SERIAL|DECIMAL(20, 0)	||
|FLOAT<br>FLOAT UNSIGNED<br>FLOAT UNSIGNED ZEROFILL|FLOAT||
|REAL<br>REAL UNSIGNED<br>REAL UNSIGNED ZEROFILL<br>DOUBLE<br>DOUBLE UNSIGNED<br>DOUBLE UNSIGNED ZEROFILL<br>DOUBLE PRECISION<br>DOUBLE PRECISION UNSIGNED<br>DOUBLE PRECISION UNSIGNED ZEROFILL|DOUBLE||
|NUMERIC(p, s)<br>NUMERIC(p, s) UNSIGNED<br>NUMERIC(p, s) UNSIGNED ZEROFILL<br>DECIMAL(p, s)<br>DECIMAL(p, s) UNSIGNED<br>DECIMAL(p, s) UNSIGNED ZEROFILL<br>FIXED(p, s)<br>FIXED(p, s) UNSIGNED<br>FIXED(p, s) UNSIGNED ZEROFILL<br>where p <= 38|DECIMAL(p, s)||
|NUMERIC(p, s)<br>NUMERIC(p, s) UNSIGNED<br>NUMERIC(p, s) UNSIGNED ZEROFILL<br>DECIMAL(p, s)<br>DECIMAL(p, s) UNSIGNED<br>DECIMAL(p, s) UNSIGNED ZEROFILL<br>FIXED(p, s)<br>FIXED(p, s) UNSIGNED<br>FIXED(p, s) UNSIGNED ZEROFILL<br>where 38 < p <= 65|STRING|在 MySQL 中，十进制数据类型的精度高达65，但在Flink中，十进制数据类型的精度仅限于38。所以，如果定义精度大于 38 的十进制列，则应将其映射到字符串以避免精度损失|
|BOOLEAN<br>TINYINT(1)<br>BIT(1)|BOOLEAN||
|DATE|DATE||
|TIME [(p)]|TIME [(p)]||
|TIMESTAMP [(p)]<br>DATETIME [(p)]|TIMESTAMP [(p)]||
|CHAR(n)|CHAR(n)||
|VARCHAR(n)|VARCHAR(n)||
|BIT(n)|BINARY(⌈n/8⌉)||
|BINARY(n)|BINARY(n)||
|VARBINARY(N)|VARBINARY(N)||
|TINYTEXT<br>TEXT<br>MEDIUMTEXT<br>LONGTEXT|STRING||
|TINYBLOB<br>BLOB<br>MEDIUMBLOB<br>LONGBLOB|BYTES|目前，对于 MySQL 中的 BLOB 数据类型，仅支持长度不大于 2147483647（2**31-1）的 blob。|
|YEAR|INT||
|ENUM|STRING||
|JSON|STRING|JSON 数据类型将在 Flink 中转换为 JSON 格式的字符串|
|SET|ARRAY<STRING>|因为 MySQL 中的 SET 数据类型是一个字符串对象，可以有零个或多个值 它应该始终映射到字符串数组|
|GEOMETRY<br>POINT<br>LINESTRING<br>POLYGON<br>MULTIPOINT<br>MULTILINESTRING<br>MULTIPOLYGON<br>GEOMETRYCOLLECTION|STRING|MySQL 中的空间数据类型将转换为具有固定 Json 格式的字符串。 请参考 MySQL 空间数据类型映射 章节了解更多详细信息。|

