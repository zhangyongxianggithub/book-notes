## 10.8 理解查询执行计划
依据表、列、索引的定义以及where子句的查询条件，MySQL优化器使用了多种技术手段来提升SQL查询中的查找性能，
大表查询可以不需要读取所有的行，或者多表的联合(join)也不需要对所有的行进行比较，MySQL的优化器的所有优化措施在MySQl中称为查询执行计划；
也叫做EXPLAIN计划，你需要做的就是通过EXPLAIN了解查询是否得到了良好的优化，并且学习SQL语法并使用索引技术来优化查询。
### 8.8.1 使用EXPLAIN优化查询
EXPLAIN提供了关于MySQL如何执行SQL语句的过程信息：
- EXPLAIN可以工作在SELECT、DELETE、INSERT、REPLACE、UPDATE语句上；
- 当使用EXPLAIN查询SQL语句的计划时，会给出MySQL是如何处理该SQL语句，比如语句中的表是如何连接的，以什么顺序连接的等，想要知道更多的信息，看[10.8.2 EXPLAIN输出格式](https://dev.mysql.com/doc/refman/8.4/en/explain-output.html)；
- 当EXPLAIN与FOR CONNECTION connection_id使用时，他会给出在连接中执行的SQL语句的执行计划，更多的信息可以看[10.8.4 获取一个有名字的连接的查询计划信息](https://dev.mysql.com/doc/refman/8.4/en/explain-for-connection.html)；
- EXPLAIN会给SELECT语句产生更多的计划信息，使用SHOW WARNINGS可以展示这些信息，更多的信息看[10.8.3 扩展的EXPLAIN输出](https://dev.mysql.com/doc/refman/8.4/en/explain-extended.html)；
- 对于分区表，EXPLAIN也是有效的，可以看[26.3.5节 获取分区信息](https://dev.mysql.com/doc/refman/8.4/en/partitioning-info.html)；
- FORMAT选项可以指定EXPLAIN的输出格式，TRADITIONAL是表格式的输出格式也是缺省的输出格式，指定为JSON时会输出JSON格式；

在EXPLAIN的帮助下，你就知道你应该加哪些索引，也能知道连表时的顺序是否合理；为了让优化器在SELECT语句中以表出现的顺序作为连接的顺序，使用SELECT STRAIGHT_JOIN;
这样做也有缺点就是可能会使用不到索引，因为禁用了半连接转换。
优化器处理痕迹可以作为EXPLAIN的补充信息，但是不同MySQL版本的优化器日志格式与内容都是不同的，详细的信息可以看https://dev.mysql.com/doc/internals/en/optimizer-tracing.html；
如果你觉得索引的使用有点问题，运行ANALYZE TABLE Statement 更新表的统计信息，比如健的基数，更多可以看13.7.3.1 ANALYZE TABLE Statement。
EXPLAIN也可以获得表的列信息，EXPLAIN tbl-name与DESCRIBE tbl-name和SHOW COLUMNS FROM tbl-name是等价的。
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
- type, 连接类型，具体的类型见后文；
- possible_keys,指出为了加快查找query指定的行，可以使用的合适的索引，这个列的值是与EXPLAIN中表的出现顺序完全无关的，这意味着possible_keys中的一些索引名实际上可能是不可用的，如果这个值是NULL，则没有可用的索引，这个时候，就可以通过添加列索引的方式来提升性能。
- key，指明MySQL实际用到的索引，一般是出现在possible_keys中的索引，也可能不是，这是因为可能possible_keys中的索引都不合适，只是因为查询选择的列是其他索引的定义列，该索引覆盖了选择列，虽然没有用于筛选行，但是可以加快扫描；对于Inno DB来说，当选择的列有主键的时候，也会使用不包含主键的索引，因为InnoDB的所以总存储的是主键，如果key是NULL，MySQL则没有找到可以提升查询的索引；为了强制让MySQL使用/忽略possible_keys中的索引，使用FORCE INDEX，USE INDEX， IGNORE INDEX；更多的可以看8.9.4 Index Hints，对于MyISAM引擎来说，运行ANALYZE TABLE会帮助优化器选择更好的索引，myisamchk -analyze的功能一样。
- key_len, key_len的值代表的是MySQL决定使用的key中的索引的长度，通过key_len的值，你可以知道MySQL使用的联合索引中使用了哪些列，如果key列是NULL，则key_len列也是NULL，根据索引的存储格式，当列可以为NULL时会比不为NULL时大1；
- ref（JSON name：ref），ref列的内容是一些列名或者常量，这些值被用来与key中的索引比较以便从表中筛选行，如果值是func，那么使用的值是某些函数的结果，想知道是哪个函数的话，使用SHOW WARNINGS查看更多的输出内容，函数可能是类似数学运算符的简单运算；
- rows，rows列的内容是MySQL认为为了执行给定查询必须要检测的行的最小数量，对于InnoDB来说，行是预估的，不是精确的；
- filtered（JSON name：filtered），filtered列的内容是一个预估的百分比，这个百分比是根据表的条件过滤的行占rows值的百分比，最大值是100，意味着行没有经过任何过滤，从100减少的量代表的就是过滤的增加量，因为基数是rows数，rows*filtered就是满足条件的行，形成的临时表；
- EXtra，这个列的内容是查询执行计划的一些额外的信息，对于不同的值的含义，可以查看EXPLAIN 额外信息，JSON表达格式里面没有专门代表Extra的属性，因为Extra里面的信息被作为JSON中的属性了，或者出现在message属性的内容中。
#### EXPLAIN连接类型
type列描述的就是表是如何的join的，下面的列表是所有的join类型，讲述的顺序是最佳->最差：
- system，表中只有一行（= 系统表），这种类型是const连接类型的一种特殊情况；
- const，查询遇到的第一个表只有不超过一行的匹配行，因为你只有一行，所以这行中列的所有值都可以作为优化器后面优化使用的常量，常量表是非常快的，因为他们只读取一次，常量表常常是使用主键索引与唯一索引中的所有列的值查询的一种情况，实际就是主键查询，在下面的查询中，table_name就是一个常量表
>SELECT * FROM tbl_name WHERE primary_key=1;
>
>SELECT * FROM tbl_name
  WHERE primary_key_part1=1 AND primary_key_part2=2;

- eq_ref，在join的情况下，当前表只有一行用于与前面的表的每行来组成联合行，除了system与const类型，这是最好的join类型，典型的场景就是join时使用的条件是一个索引中的所有列，并且所以是主键索引与唯一索引，eq_ref连接类型被用于连接条件使用索引列匹配的情况，比较的值可以是一个常量，或者是一个根据前面的表的某些列的表达式计算出来的值，下面的实例中，MYSQL在处理ref_table表的时候使用的就是eq_ref
>SELECT * FROM ref_table,other_table
  WHERE ref_table.key_column=other_table.column;
>
>SELECT * FROM ref_table,other_table
  WHERE ref_table.key_column_part1=other_table.column
  AND ref_table.key_column_part2=1;

- ref，当前表通过索引完成连接条件与前面的表的每一行匹配并组合，通常连接条件使用的索引列是key的最左前缀列，或者使用的索引不是主键索引与唯一索引（换句话说，也就是不能通过key中的索引唯一定位一行 ），如果key使用的索引可以定位到表中的几行，那么这是一个比较好的连接类型，ref连接类型中的连接条件通常是对索引列的=或者<=>比较，下面的例子中，MySQL在处理ref_table时，使用的就是ref连接类型
>SELECT * FROM ref_table WHERE key_column=expr;
>
>SELECT * FROM ref_table,other_table
  WHERE ref_table.key_column=other_table.column;
>
>SELECT * FROM ref_table,other_table
  WHERE ref_table.key_column_part1=other_table.column
  AND ref_table.key_column_part2=1;

- fulltext，使用全文索引连接；
- ref_or_null，连接类型类似ref，除了在行包含NULL值时执行了一个额外的搜索操作，这个连接类型的优化同行用于解析子查询，在下面的例子中，MySQL使用ref_or_null连接类型来处理ref_table
>SELECT * FROM ref_table
  WHERE key_column=expr OR key_column IS NULL;
- index_merge，这个连接类型指定连接时进行了索引合并，在这个案例中，key中的值通常是多个索引，key_len是一个列表，里面是使用的索引部分的最大长度；
- unique_subquery，这个连接类型使用在IN子查询中，子查询类似eq_ref：
>value IN (SELECT primary_key FROM single_table WHERE some_expr)

- index_subquery, 类似于unique_subquery，也是用于IN子查询，只是子查询的列不是主键而是非唯一索引：
>value IN (SELECT key_column FROM single_table WHERE some_expr)

- range，只检索使用索引确定的给定范围的行，key中指定了使用的索引，key_len指定了使用索引的最大的长度，在这个连接类型中，ref是NULL，当key中的索引列于常量比较时，比如=、<>、>、>=、<、<=、IS NULL、BETWEEN、LIKE、IN()比较时：
>SELECT * FROM tbl_name
  WHERE key_column = 10;
>
>SELECT * FROM tbl_name
  WHERE key_column BETWEEN 10 and 20;
>
>SELECT * FROM tbl_name
  WHERE key_column IN (10,20,30);
>
>SELECT * FROM tbl_name
  WHERE key_part1 = 10 AND key_part2 IN (10,20,30);

- idnex，等同于ALL，但是会扫描索引树，2种情况下会发生：

  - 如果索引对一个查询来说是一个覆盖索引，并且包含查询需要的所有的数据，此时查询不会扫描表，只需要扫描索引树就可以了，在这种情况下，Extra列的内容是Using index，索引扫描比全表扫描会快一些，因为索引的大小还是比表数据小的；
  - 通过索引的顺序读取全表的内容，执行全表扫描，这个时候Extra的内容不是Useing index；
  
当MySQL在连表时通过一个所以的一部分列进行匹配的时候就是这种连接类型。

- ALL，与前面表的每一行的匹配组合需要读取当前表的全部行，如果当前表是第一个表并且不是常量，这样做性能比较差，通常来说，你都可以通过加索引的方式避免ALL连接类型。

#### EXPLAIN 额外信息
EXPLAIN的Extra列是有关于MySQL如何解析查询的额外信息，下面得了列表列出了可能出现的值，如果你想要你的查询尽可能的快，只需要看看Extra列的值是不是Using filesort或者Using temporary。
- Child of 'table' pushed join@1 (JSON: message text)，NDB集群使用；
- const row not found (JSON property: const_row_not_found)，对于一个简单查询来说，表是空的；
- Deleting all rows (JSON property: message)，对于DELETE语句来说，。某些存储引擎有一些简单快速删除所有行的方法，如果使用了这个方法，则值是这个；
- Distinct (JSON property: distinct)，对于一列有完全不同的值列，在行匹配中，MYSQL如果找到了匹配行，就不会搜索更多的行了；
- FirstMatch(tbl_name) (JSON property: first_match)，tbl_name使用了半连接短路策略；
- Full scan on NULL key (JSON property: message)，当优化器找不到通过索引进行的查询时，会使用的一种回退策略；
- Impossible HAVING (JSON property: message)，HAVING子句始终是false，没有筛选出任何行；
- Impossible WHERE (JSON property: message)，WHERE子句始终是false，没有筛选出任何行；
- Impossible WHERE noticed after reading const tables (JSON property: message)，MySQL已经读取了所有的常量表，但是WHERE子句始终是false；
- LooseScan(m..n) (JSON property: message)，正在使用半连接宽松扫描策略；
- No matching min/max row (JSON property: message)，No row satisfies the condition for a query such as SELECT MIN(...) FROM ... WHERE condition；
- no matching row in const table (JSON property: message)，对于一个使用连接的查询来说，表是空的，或者经过查询条件过滤后表是空的；
- No matching rows after partition pruning (JSON property: message)，对于DELETE与UPDATE语句来说，经过分区处理后，发现每有行需要处理；
- No tables used (JSON property: message)，查询没有FROM子句，或者有FROM DUAL子句，对于INSERT或者REPLACE语句来说，当没有使用SELECT时，EXPLAIN会显示这个值，例如，EXPLAIN INSERT INTO t VALUES(10)会出现，因为它等价于EXPLAIN INSERT INTO t SELECT 10 FROM DUAL；
- Not exists (JSON property: message)，MySQL能够对左连接优化，就是当它（这里没搞懂）;
- Plan isn't ready yet (JSON property: none)，这个值通常出现在EXPLAIN_FOR_CONNECTION语句中，这是因为优化器还没有对连接中的语句创建完查询计划；
- Range checked for each record (index map: N) (JSON property: message)，MySQL没有发现可用的索引，但是发现了一些索引在知道了前面表的列值的情况下可能会被使用到，对于每个与前面表的行组合来说，MySQL都会检查是否可以使用range或者index_merge的方式来检索行，这可能不是最快的，但是比执行没有索引的连表操作要快很多，适用的条件在8.2.1.2节 Range Optimization与8.2.1.3节 Index Merge Optimization， 索引内部是有编号的，从1开始，按照从小到大的顺序显示，index map value是一个位掩码，指出了哪些索引是候选的索引。
- Recursive (JSON property: recursive)；
- Rematerialize (JSON property: rematerialize)
- Zero limit, 查询有limit 0子句，所以返回的列数是0；
- Using where with pushed condition，只应用于NDB表；
- Using where，使用where子句筛选返回的结果行，如果表的连接类型是ALL或者index，并且extra不是Using where，除非你真的想要检测一个表的所有的行，否则，查询可能是有问题的；
- Using temporary，为了解析查询，MySQL需要创建一个临时表来保存结果，通常有GROUP BY与ORDER BY子句时候比较容易出现；
- Using sort_union(...), Using union(...), Using intersect(...)，当表的连接类型是index_merge时表示具体的merge算法；
- Using MRR，读表时使用了对个范围的读优化策略；
- Using join buffer (Block Nested Loop), Using join buffer (Batched Key Access), Using join buffer (hash join)，
- Using index for skip scan，扫描被忽略了；
- Using index for group-by，与Using index类似，代表索引可以用来检索GROUP BY子句或者DISYTINCT子句返回的所有的列，不需要读取表的数据；
- Using index condition，首先读取索引元组并检测是否需要读取全部的行，在这个模式下，索引信息可以推迟读取全部的行；
- Using index，列的信息只需要从索引中读取，不需要读取表数据，这个策略只适用与查询使用了索引的部分列的情况，对于InnoDB来说，即使Extra这里没有显示Using index，如果连接类型是index并且key是PRIMARY时，索引也是会被使用到；
- Using filesort，MySQL必须做一个额外的处理，以便按照指定顺序检索行，排序是通过遍历所有满足where子句的行的排序列，并存储他们与指向行的指针，然后对排序列根据值排序，按照排序列的顺序读取行；
- unique row not found，对于一个SELECT查询来说，没有行满足主键与唯一索引列的条件；
- Start temporary, End temporary，使用临时表做半连接；
- Skip_open_table, Open_frm_only, Open_full_table，当查询INFORMATION_SCHEMA是优化了文件打开；
- Select tables optimized away
#### EXPLAIN内容解释
从输出中的rows字段，你可以判断连接是否足够好，这可以错略的告诉你，SQL语句大约需要检测表的多少行，如果你设置了max_join_size系统变量，explain输出也能告诉你，MySQL是如何选择哪些表来连接，到哪个表终止的。
下面的例子展示了展示了一个多表联合可以通过EXPLAIN提供的信息进行逐步的优化的，假设你有下面的SQL语句：
>EXPLAIN SELECT tt.TicketNumber, tt.TimeIn,
               tt.ProjectReference, tt.EstimatedShipDate,
               tt.ActualShipDate, tt.ClientID,
               tt.ServiceCodes, tt.RepetitiveID,
               tt.CurrentProcess, tt.CurrentDPPerson,
               tt.RecordVolume, tt.DPPrinted, et.COUNTRY,
               et_1.COUNTRY, do.CUSTNAME
        FROM tt, et, et AS et_1, do
        WHERE tt.SubmitTime IS NULL
          AND tt.ActualPC = et.EMPLOYID
          AND tt.AssignedPC = et_1.EMPLOYID
          AND tt.ClientID = do.CUSTNMBR;

列的类型如下：
| Table | Column | Data Type |
|:-|:-|:-|
| tt | ActualPC | CHAR(10) |
|tt|AssignedPC|CHAR(10)|
|tt|ClientID|CHAR(10)|
|et|EMPLOYID|CHAR(10)|
|do|CUSTOMER|CHAR(10)|

表有下面的索引
|Table|Index|
|:-|:-|
|tt|ActualPC|
|tt|AssignedPC|
|tt|ClientID|
|et|EMPLOYID(主键)|
|do|CUSTOMER(主键)|
在优化前，EXPLAIN输出如下：
|table|type|possible_keys|key|key_len|ref|rows|Extra|
|:-|:-|:-|:-|:-|:-|:-|:-|
|et|ALL|PRIMART|NULL|NULL|NULL|74|NULL|
|do|ALL|PRIMARY|NULL|NULL|NULL|2135|NULL|
|et_1|ALL|PRIMARY|NULL|NULL|NULL|74|NULL|
|tt|ALL|AssignedPC,ClientID,ActualPC|NULL|NULL|NULL|3872|Range checked for each record(index map:0x23)|

因为每个表的连接类型是ALL，这说明MySQL对所有的表都是生成的笛卡尔积表，这会消耗很长时间，这意味着需要检测所有表行数乘积的行数，举例来说，乘积是74\*2135\*74\*3872=45,268,558,720行。
一个问题是，MySQL本可以使用列上（同样的类型，同样的大小）的索引更有效率的完成连接，如果VARCHAR定义的大小与CHAR一样大，算是同样的类型，tt.ActualPC是CHAR(10)类型，et.EMPLOYID是CHAR(15)类型，所以长度是不匹配的，为了解决长度上的问题，使用ALTER TABLE修改列的长度
>ALTER TABLE tt MODIFY ActualPC VARCHAR(15);

现在一样长了，使用呢EXPLAIN再次看下优化的效果
|table|type|possible_keys|key|key_len|ref|rows|Extra|
|:-|:-|:-|:-|:-|:-|:-|:-|
|tt|ALL|AssignedPC,ClientPC,ActualPC|NULL|NULL|NULL|3872|Using where|
|do|ALL|PRIMARY|NULL|NULL|NULL|2135|Range checked for each record (index map: 0x1)|
|et_1|ALL|PRIMARY|NULL|NULL|NULL|74|Range checked for each record (index map: 0x1)|
|et|eq_ref|PRIMARY|PRIMARY|15|tt.ACtualPV|1|NULL|NULL|

还可以优化，这样不是最完美的，et的函数远远小于上一次的值，这个SQL执行需要好几秒，第二步的优化还是长度不匹配的问题
>ALTER TABLE tt MODIFY AssignedPC VARCHAR(15),
                      MODIFY ClientID   VARCHAR(15);

然后再次查看查询计划：
|table|type|possible_keys|key|key_len|ref|rows|Extra|
|:-|:-|:-|:-|:-|:-|:-|:-|
|et|ALL|PRIMARY|NULL|NULL|NULL|74|NULL|
|tt|ref|AssignedPC,ClientID,ActualPC|ActualPC|15|et,EMPLOYID|52|Using where|
|et_1|eq_ref|PRIMARY|PRIMARY|15|tt.AssignedPC|1|NULL|
|do|eq_ref|PRIMARY|PRIMARY|15|tt.ClientId|1|NULL|

查询已经优化的比较好了。
### 8.8.3 扩展的EXPLAIN输出
EXPLAIN在标准输出之外，也会产生额外的信息，可以通过在EXPLAIN语句之后输入SHOWWARNINGS指令得到，MySQL8.0.12版本之后，SELECT、DELETE、INSERT、REPLACE、UPDATE语句有扩展信息，之前的版本只有SELECT语句才有扩展信息。
扩展输出中的Message列
### 8.8.4 获取一个有名字的连接的查询计划信息
### 8.8.5 估算查询性能
