## 8.8 理解查询执行计划
依据表、列、索引的定义以及where子句的查询条件，MySQL优化器使用了多种技术手段来提升SQL查询中的查找性能，
大表查询可以不需要读取所有的行，或者多表的联合(join)也不需要对所有的行进行比较，MySQL的优化器的所有优化措施在MySQl中称为查询执行计划；
也叫做EXPLAIN计划，你需要做的就是通过EXPLAIN了解查询是否得到了良好的优化，并且学习SQL语法并使用索引技术来优化查询。
### 8.8.1 使用EXPLAIN优化查询
EXPLAIN提供了关于MySQL如何执行SQL语句的过程信息：
- EXPLAIN可以工作在SELECT、DELETE、INSERT、REPLACE、UPDATE语句上；
- 当使用EXPLAIN查询SQL语句的计划时，会给出MySQL是如何处理该SQL语句，比如语句中的表是如何连接的，以什么顺序连接的等，想要知道更多的信息，看8.8.2 EXPLAIN输出格式；
- 当EXPLAIN与FOR CONNECTION connection_id使用时，他会给出在连接中执行的SQL语句的执行计划，更多的信息可以看8.8.4 获取一个有名字的连接的查询计划信息；
- EXPLAIN会给SELECT语句产生更多的计划信息，使用SHOW WARNINGS可以展示这些信息，更多的信息看8.8.3 扩展的EXPLAIN输出；
- 对于分区表，EXPLAIN也是有效的，可以看23.3.5节 获取分区信息；
- FORMAT选项可以指定EXPLAIN的输出格式，TRADITIONAL是表格式的输出也是缺省的输出格式，JSON会输出JSON格式；

在EXPLAIN的帮助下，你就知道你应该加哪些索引，也能知道连表时的顺序是否合理；为了让优化器在SELECT语句中以表出现的顺序作为连接的顺序，使用SELECT STRAIGHT_JOIN;
这样做也有缺点就是可能会使用不到索引，因为禁用了半连接转换。
优化器处理痕迹可以作为EXPLAIN的补充信息，但是不同MySQL版本的优化器日志格式与内容都是不同的，详细的信息可以看https://dev.mysql.com/doc/internals/en/optimizer-tracing.html；
如果你觉得索引的使用有点问题，运行ANALYZE TABLE Statement 更新表的统计信息，比如健的基数，更多可以看13.7.3.1 ANALYZE TABLE Statement。
EXPLAIN也可以获得表的列信息，EXPLAIN tab-name与DESCRIBE tbl-name和SHOW COLUMNS FROM tbl-name是等价的。
### 8.8.2 EXPLAIN输出格式
EXPLAIN提供了关于MySQL是如何执行SQL语句的信息，EXPLAIN可以工作在SELECT、DELETE、INSERT、REPLACE、UPDATE语句上。
SELECT语句中的每个表都会是EXPLAIN中的一行，顺序是MySQL在处理语句时读到的顺序，这意味着，MySQL从第一个表中读取一行，然后在第二个表中查找匹配的行，
然后是第三个等等；当所有的表都处理了，MySQL输出选择的列，以回朔的方式查找与列匹配的表的内容，直到完全覆盖选择的列的内容，下一行从这个表开始处理并一直到最后。
#### EXPLAIN输出列
EXPLAIN的每一行都提供一个表的信息，行的内容总结在表8.1 EXPLAIN输出列中，在表后有更详细的说明，第一列是列名，第二列是等价的当指定FORMAT=JSON的JSON形式。
表8.1 
| 列名 | JSON 属性名 | 含义 |
|:-|:-|:-|
|id|select_id|select标识符，这是一个查询语句中的select子句的顺序号，当结果是union操作的结果时，这个值是NULL，在这个案例中，table列的值是<union M,N>表示是M子句与N子句的结果合并而成
|select_type|None|select类型｜
|table|table_name|表名|
|partitions|partitions|匹配的分区|
|type|access_type|联合的类型|
|possible_keys|possible_keys|合适的索引|
|key|key|实际选择的索引|
|key_len|key_length|选择的索引的长度|
|ref|ref|与索引比较的列|
|rows|rows|需要检查的预估行|
|filtered|filtered|根据条件过滤后剩余行的百分比|
|Extra|None|额外的信息|

- select_type,select的类型，值是下表中的，使用JSON表示时，除了SIMPLE与PRIMARY值外的其他值都是属性query_block的值。

|值 | json属性 | 含义 |
|:-|:-|:-|
|SIMPLE|None|简单的seclect，没有使用union与子查询|
|PRIMARY|None| 最外层的SELECT子句|
|UNION|None|在UNION中的第二个SECLECT子句|
|DEPENDENT UNION|dependent(true)| 在UNION中的第二个SECLECT子句,并且依赖外层的查询 |
|UNION RESULT | union_result|UNION的结果|
|SUBQUERY|None|子查询中的第一个SELECT|
|DEPENDENT SUBQUERY|dependent(true)|子查询中的第一个SELECT,依赖外层的查询|
|DERIVED|None|衍生表|
|DEPENDENT DERIVED|dependent (true)|衍生表,依赖另一个表|
|MATERIALIZED|materialized_from_subquery|不知道这词啥意思|
|UNCACHEABLE SUBQUERY|cacheable (false)|查询结果不能被缓存的子查询，每次关联外部行时都需要重新弄评估|
|UNCACHEABLE UNION|cacheable (false)|在UNION中的第二个SECLECT子句是一个不会缓存的子查询|

DEPENDENT通常表示使用了有关联的子查询，看13.2.11.7 关联子查询。
DEPENDENT SUBQUERY评估与UNCACHEABLE SUBQUERY是不同的，DEPENDENT SUBQUERY的子查询根据关联的外部值只会评估一次，而UNCACHEABLE SUBQUERY针对关联的每个外部行都要重新评估一次。
当你指定FORMAT=JSON的时候，没有等价与select_type的直接属性。

- table 行代表的表名，是下列中的值：

  - <unionM,N> union之后的表；
  - <derivedN> 衍生表；
  - <subqueryN> 不知道啥意思；
- partitions，查询涉及到的分区数；
- type, 连接类型；
- possible_keys,指出为了加快查找query指定的行，可以使用的合适的索引，这个列的值是与EXPLAIN中表的出现顺序完全无关的，这意味着possible_keys中的一些索引名实际上可能是不可用的，如果这个值是NULL，则没有可用的索引，这个时候，就可以通过添加列索引的方式来提升性能。
- key，指明MySQL实际用到的索引，一般是出现在possible_keys中的索引，也可能不是，这是因为可能possible_keys中的索引都不合适，只是因为查询选择的列是其他所以的定义列，所以覆盖了选择列，虽然没有用于筛选行，但是可以加快扫描；对于Inno DB来说，在查询结果有主键的情况下，
### 8.8.3 扩展的EXPLAIN输出
### 8.8.4 获取一个有名字的连接的查询计划信息
### 8.8.5 估算查询性能