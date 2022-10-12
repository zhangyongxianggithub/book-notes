#### INSERT...ON DUPLICATE KEY UPDATE Statement
如果你明确指明了`ON DUPLICATE KEY UPDATE`SQL子句，当要插入的行遇到`UNIQUE`所以或者`PRIMARY KEY`索引造成的重复值异常时，此时就会更新旧行，比如，如果`a`列被声明未唯一索引列，且值存在1，下面的2个语句有相同的效果:
```sql
INSERT INTO t1 (a,b,c) VALUES (1,2,3)
  ON DUPLICATE KEY UPDATE c=c+1;
UPDATE t1 SET c=c+1 WHERE a=1;
```
效果并不完全相同，对于InnoDB引擎的表来说，如果`a`列是自增的，INSERT语句会自增值，但是UPDATE语句不会.
如果列`b`也是唯一的，INSERT语句等价于下面的UPDATE语句:
```sql
UPDATE t1 SET c=c+1 WHERE a=1 OR b=2 LIMIT 1;
```
如果`a=1 or b=2`匹配了2行，分别是a=1的行或者b=2的行，那么只有一行会被更新，通常来说，您应该尽量避免在具有多个唯一索引的表上使用`ON DUPLICATE KEY UPDATE`子句。使用`ON DUPLICATE KEY UPDATE`，如果将行作为新行插入，则受影响行为1，如果更新现有行，则为2，如果将现有行已为当前值，则为0。如果在连接到mysqld时为mysql_real_connect()C API函数指定CLIENT_FOUND_ROWS标志，如果现有行为其当前值，则受影响的行值为1（而不是 0）。如果表包含 `AUTO_INCREMENT`列并且`INSERT ... ON DUPLICATE KEY UPDATE`插入或更新行，则`LAST_INSERT_ID()`函数返回 `AUTO_INCREMENT`值。`ON DUPLICATE KEY UPDATE`子句可以包含多个赋值列，以逗号分隔。在`ON DUPLICATE KEY UPDATE`子句中的赋值表达式中，您可以使用`VALUES(col_name)`函数来引用来自`INSERT ... ON DUPLICATE KEY UPDATE`语句的`INSERT`部分的列值。换句话说，`ON DUPLICATE KEY UPDATE`子句中的`VALUES(col_name)`引用的是要被插入的没有发生重复键冲突的`col_name`的值。此函数在多行插入时特别有用。VALUES()函数仅在`ON DUPLICATE KEY UPDATE`子句或`INSERT`语句中有意义否则返回 NULL。比如:
```sql
INSERT INTO t1 (a,b,c) VALUES (1,2,3),(4,5,6)
  ON DUPLICATE KEY UPDATE c=VALUES(a)+VALUES(b);
```
这个语句等价于下面的2条语句:
```sql
INSERT INTO t1 (a,b,c) VALUES (1,2,3)
  ON DUPLICATE KEY UPDATE c=3;
INSERT INTO t1 (a,b,c) VALUES (4,5,6)
  ON DUPLICATE KEY UPDATE c=9;
```
从MySQL 8.0.20开始不推荐使用VALUES()来引用新的行和列，并且在未来的MySQL版本中可能会被删除。 相反，请使用行和列别名，如本节接下来的几段所述。
从MySQL 8.0.19开始，可以为行使用别名，使用AS关键字开头指定别名，可以在VALUES或SET子句之后插入一个或多个列时就可以使用行的别名指定，使用行别名new，前面显示的使用VALUES() 访问新列值的语句可以写成如下所示的形式:
```sql
INSERT INTO t1 (a,b,c) VALUES (1,2,3),(4,5,6) AS new
  ON DUPLICATE KEY UPDATE c = new.a+new.b;
```
也可以为列指定别名，如果您使用列别名m、n 和 p，则可以在赋值子句中省略行别名并编写相同的语句，如下所示:
```sql
INSERT INTO t1 (a,b,c) VALUES (1,2,3),(4,5,6) AS new(m,n,p)
  ON DUPLICATE KEY UPDATE c = m+n;
```
以这种方式使用列别名时，您仍然必须在`VALUES`子句之后使用行别名，即使您没有在赋值子句中直接使用它。从MySQL 8.0.20开始，一个在`UPDATE`子句中使用`VALUES()`的`INSERT ... SELECT ... ON DUPLICATE KEY UPDATE`语句，像下面这个，会抛出一个警告:
```sql
INSERT INTO t1
  SELECT c, c+d FROM t2
  ON DUPLICATE KEY UPDATE b = VALUES(b);
```
你可以通过子查询的方式消除这个警告:
```sql
INSERT INTO t1
  SELECT * FROM (SELECT c, c+d AS e FROM t2) AS dt
  ON DUPLICATE KEY UPDATE b = e;
```
如前所述，您还可以在SET子句中使用行和列别名。在刚刚显示的两个`INSERT ... ON DUPLICATE KEY UPDATE`语句中使用`SET`而不是`VALUES`可以如下所示完成:
```sql
INSERT INTO t1 SET a=1,b=2,c=3 AS new
  ON DUPLICATE KEY UPDATE c = new.a+new.b;

INSERT INTO t1 SET a=1,b=2,c=3 AS new(m,n,p)
  ON DUPLICATE KEY UPDATE c = m+n;
```
行别名不能与表名相同。如果不使用列别名，或者如果它们与列名相同，则必须使用`ON DUPLICATE KEY UPDATE`子句中的行别名来区分它们。列别名对于它们所应用的行别名必须是唯一的（即，引用同一行的列的列别名不能相同）。对于`INSERT ... SELECT`语句，这些规则适用于可接受形式的`SELECT`查询表达式，你可以在`ON DUPLICATE KEY UPDATE`子句中引用`SELECT`查询表达式的内容，可以引用的内容如下:
- 对单个表(可能是派生表)的查询中的列的引用;
- 对多个表的连接查询中的列的引用;
- 对DISTINCT查询中的列的引用;
- 对其他表中的列的引用，只要`SELECT`不使用`GROUP BY`，一个副作用是您必须限定对非唯一列名的引用;
不支持对来自`UNION`的列的引用。要解决此限制，请将`UNION`重写为派生表，以便可以将其行视为单表结果集。例如，此语句会产生错误:
```sql
INSERT INTO t1 (a, b)
  SELECT c, d FROM t2
  UNION
  SELECT e, f FROM t3
ON DUPLICATE KEY UPDATE b = b + c;
```
相反，请使用将 UNION 重写为派生表的等效语句:
```sql
INSERT INTO t1 (a, b)
SELECT * FROM
  (SELECT c, d FROM t2
   UNION
   SELECT e, f FROM t3) AS dt
ON DUPLICATE KEY UPDATE b = b + c;
```
将查询重写为派生表的技术还允许引用来自`GROUP BY`查询的列。因为`INSERT ... SELECT`语句的结果取决于`SELECT`中行的顺序，并且不能保证顺序的一致性，所以在记录源和副本的`INSERT ... SELECT ON DUPLICATE KEY UPDATE`语句时可能会出现分歧. 因此，`INSERT ... SELECT ON DUPLICATE KEY UPDATE`语句被标记为对基于语句的复制不安全。此类语句在使用statement-based模式时会在错误日志中产生警告，并在使用`MIXED`模式时使用 row-based格式写入二进制日志。针对具有多个唯一键或主键的表的`INSERT ... ON DUPLICATE KEY UPDATE`语句也被标记为不安全。