[TOC]
# JSON数据类型
MySQL支持RFC7159定义的Json数据类型，相比于存储string类型，json类型的优势如下：
- json格式自动校验；
- 存储格式优化，json文档是按照一种内部格式存储的，这种内部格式支持快速的访问内部节点，当服务需要读取一个json文档时，json文档不需要从一个文本表示的字符串中反序列化，json文档的二进制格式就支持查询子对象或者内嵌的值。
MySQL8支持JSON Merge Patch格式（使用JSON_MERGE_PATCH()函数），可以详细查看这个函数的描述。
json类型的存储空间==LONGBLOB与LONGTEXT的大小，可以看11.7节 数据类型的空间需求；需要记住的一点是，json文档的大小不能超过max_allow_packet系统变量的设置的上限，你可以使用函数json_storage_size()来确定json文档的存储空间大小。
在8.0.13之前的版本json列不支持默认值设置。json数据类型有很多支持的函数，分为3类，创建、操作、搜索；想要查看更多的函数的细节，可以看12.18节的JSON函数部分。
json列，与其他的二进制数据类型一样，是不能被直接索引的，你可以从json中的某个值上单独生成一列，在这个列上创建索引，可以看[Indexing a Generated Column to Provide a JSON Column Index](https://dev.mysql.com/doc/refman/8.0/en/create-table-secondary-indexes.html#json-column-indirect-index)获取更多的信息。
MySQL优化器也会在匹配JSON表达式的虚拟列上寻找兼容的索引。
MySQL 8.0.17之后的版本，InnoDB存储引擎支持在JSON数组上建立多值索引。
MySQL NDB集群支持JSON数据类型与相关的函数，包括在有JSON列生成的列上建立索引，一个NDB表最多支持3个JSON列。
## JSON局部更新
在MySQL8.0中，优化器会局部更新JSON值，而不是采用的移除旧值再完整写入新值的的方式，满足以下条件的更新会使用到这个优化
- 被更新的列的类型是JSON;
- UPDTAE语句使用3个函数中的JSON_SET()、JSON_REPLACE()或者JSON_REMOVE()任意一个来更新列，json列值的直接赋值的方式不会执行局部更新，比如如下的SQL语句
```sql
UPDATE mytable SET jcol = '{"a": 10, "b": 25}'
```
在一个UPDATE语句中更新多个JSON列可以使用这种方式优化，MySQL可以对这些列执行局部更新，但是这有更新使用的是上面3个函数的情况下才可以。
- 输入列与目标列必须是同一个列，一个这样的UPDATE语句不能使用局部更新
```sql
UPDATE mytable SET jcol1 = JSON_SET(jcol2, '$.a', 100)
```
上面的更新的函数可以内嵌调用，或者组合调用，只要输入列与输出列是一个就行.
- 所有替换值的操作，比如替换对象或者替换数组；
- 替换的新值不能比以前的值大;
区分存储在表中的 JSON 列值的部分更新与将行的部分更新写入二进制日志很重要。 JSON 列的完整更新可以作为部分更新记录在二进制日志中。 当上一个列表中的最后两个条件中的一个（或两个）不满足但其他条件得到满足时，就会发生这种情况。
## Creating JSON Values
一个JSON的数组包含一些逗号分隔的值，使用[]符号包裹;如下：
```json
["abc", 10, null, true, false]
```
JSON对象是逗号分隔的key-value集合，使用()包裹,如下:
```json
{"k1": "value", "k2": 10}
```
正如例子中说明的那样，JSON数组与对象可以包含标量值，json对象中的key必须是字符串，标量值也包含时间类型的值.
```json
["12:18:29.000000", "2015-07-29", "2015-07-29 12:18:29.000000"]
```
json对象与json数组可以互相嵌套
```json
[99, {"id": "HK500", "cost": 75.99}, ["hot", "cold"]]
{"k1": "value", "k2": [10, 20]}
```
你可以通过MySQL的函数的到JSON值，或者通过CAST(value as JSON)函数把其他类型的值转换成JSON类型来获得json值，下面的几个例子将会讲述MySQL是如何操作输入的JSON值。
在MySQL中，JSON值是以字符串的方式存储的，在一个需要json的上下文中，MySQL会自动解析string成json值，如果string不是一个有效的json值，就会抛出异常；这些上下文宝库向一个json列写入值，向一个json函数传递参数等；正如下面的例子中所示：
- 向一个json类型的列写值
```sql
mysql> CREATE TABLE t1 (jdoc JSON);
Query OK, 0 rows affected (0.20 sec)

mysql> INSERT INTO t1 VALUES('{"key1": "value1", "key2": "value2"}');
Query OK, 1 row affected (0.01 sec)

mysql> INSERT INTO t1 VALUES('[1, 2,');
ERROR 3140 (22032) at line 2: Invalid JSON text:
"Invalid value." at position 6 in value (or column) '[1, 2,'.
```
此类错误消息中“在位置 N”的位置是基于 0 的，但应被视为值中问题实际发生位置的粗略指示。 
json_type()函数期望一个json参数并把参数解析成jsonvalue，它返回json的类型，如果不是有效的json，会返回一个错误.
```sql
mysql> SELECT JSON_TYPE('["a", "b", 1]');
+----------------------------+
| JSON_TYPE('["a", "b", 1]') |
+----------------------------+
| ARRAY                      |
+----------------------------+

mysql> SELECT JSON_TYPE('"hello"');
+----------------------+
| JSON_TYPE('"hello"') |
+----------------------+
| STRING               |
+----------------------+

mysql> SELECT JSON_TYPE('hello');
ERROR 3146 (22032): Invalid data type for JSON data in argument 1
to function json_type; a JSON string or JSON type is required.
```
MySQL 使用 utf8mb4 字符集和 utf8mb4_bin 排序规则处理 JSON 上下文中使用的字符串。 其他字符集中的字符串根据需要转换为 utf8mb4。 （对于 ascii 或 utf8 字符集中的字符串，不需要转换，因为 ascii 和 utf8 是 utf8mb4 的子集。
作为使用文字字符串编写 JSON 值的替代方法，存在用于从组件元素组合 JSON 值的函数。 JSON_ARRAY() 接受一个（可能是空的）值列表并返回一个包含这些值的 JSON 数组.
```sql
mysql> SELECT JSON_ARRAY('a', 1, NOW());
+----------------------------------------+
| JSON_ARRAY('a', 1, NOW())              |
+----------------------------------------+
| ["a", 1, "2015-07-27 09:43:47.000000"] |
+----------------------------------------+
```
json_object()根据key-value对生成json对象，
```sql
mysql> SELECT JSON_OBJECT('key1', 1, 'key2', 'abc');
+---------------------------------------+
| JSON_OBJECT('key1', 1, 'key2', 'abc') |
+---------------------------------------+
| {"key1": 1, "key2": "abc"}            |
+---------------------------------------+
```
json_merge_preserve()函数输入多个json，并组合到一起;
```sql
mysql> SELECT JSON_MERGE_PRESERVE('["a", 1]', '{"key": "value"}');
+-----------------------------------------------------+
| JSON_MERGE_PRESERVE('["a", 1]', '{"key": "value"}') |
+-----------------------------------------------------+
| ["a", 1, {"key": "value"}]                          |
+-----------------------------------------------------+
1 row in set (0.00 sec)
```
关于merge的更多的规则，可以参阅[Normalization, Merging, and Autowrapping of JSON Values](https://dev.mysql.com/doc/refman/8.0/en/json.html#json-normalization)
MySQL 8.0.3之后的版本也支持json_merge_patch函数，有一些不同的行为，阅读[JSON_MERGE_PATCH() compared with JSON_MERGE_PRESERVE()](https://dev.mysql.com/doc/refman/8.0/en/json-modification-functions.html#json-merge-patch-json-merge-preserve-compared)获得2个函数区别的信息.
json可以被分配给用户定义的变量
```sql
mysql> SET @j = JSON_OBJECT('key', 'value');
mysql> SELECT @j;
+------------------+
| @j               |
+------------------+
| {"key": "value"} |
+------------------+
```
但是，用户定义的变量不能是 JSON 数据类型，因此虽然前面示例中的 @j 看起来像一个 JSON 值并且具有与 JSON 值相同的字符集和排序规则，但它不具有 JSON 数据类型。 相反，JSON_OBJECT() 的结果在分配给变量时会转换为字符串。

通过转换 JSON 值生成的字符串具有 utf8mb4 字符集和 utf8mb4_bin 排序规则.
```sql
mysql> SELECT CHARSET(@j), COLLATION(@j);
+-------------+---------------+
| CHARSET(@j) | COLLATION(@j) |
+-------------+---------------+
| utf8mb4     | utf8mb4_bin   |
+-------------+---------------+
```
因为utf8mb4_bin是二进制的排序规则，所以JSON的比较是大小写敏感的。
```sql
mysql> SELECT JSON_ARRAY('x') = JSON_ARRAY('X');
+-----------------------------------+
| JSON_ARRAY('x') = JSON_ARRAY('X') |
+-----------------------------------+
|                                 0 |
+-----------------------------------+
```
区分大小写也适用于 JSON null、true 和 false 文字，它们必须始终以小写形式编写：
```sql
mysql> SELECT JSON_VALID('null'), JSON_VALID('Null'), JSON_VALID('NULL');
+--------------------+--------------------+--------------------+
| JSON_VALID('null') | JSON_VALID('Null') | JSON_VALID('NULL') |
+--------------------+--------------------+--------------------+
|                  1 |                  0 |                  0 |
+--------------------+--------------------+--------------------+

mysql> SELECT CAST('null' AS JSON);
+----------------------+
| CAST('null' AS JSON) |
+----------------------+
| null                 |
+----------------------+
1 row in set (0.00 sec)

mysql> SELECT CAST('NULL' AS JSON);
ERROR 3141 (22032): Invalid JSON text in argument 1 to function cast_as_json:
"Invalid value." at position 0 in 'NULL'.
```
JSON 文字的区分大小写与 SQL NULL、TRUE 和 FALSE 文字的区分大小写不同，后者可以写成任何字母。
```sql
mysql> SELECT ISNULL(null), ISNULL(Null), ISNULL(NULL);
+--------------+--------------+--------------+
| ISNULL(null) | ISNULL(Null) | ISNULL(NULL) |
+--------------+--------------+--------------+
|            1 |            1 |            1 |
+--------------+--------------+--------------+
```
有时可能需要或希望在 JSON 文档中插入引号字符（" 或 '）。假设在此示例中，您要插入一些包含字符串的 JSON 对象，这些字符串表示一些有关 MySQL 的一些事实的句子，每个对象与适当的关键字配对 , 到使用此处显示的 SQL 语句创建的表中：
```sql
mysql> CREATE TABLE facts (sentence JSON);
```
这些陈述的一个例子是:mascot: The MySQL mascot is a dolphin named "Sakila".
将其作为 JSON 对象插入到事实表中的一种方法是使用 MySQL JSON_OBJECT() 函数。 在这种情况下，您必须使用反斜杠对每个引号字符进行转义，如下所示：
如果您将值作为 JSON 对象文字插入，则这不会以相同的方式工作，在这种情况下，您必须使用双反斜杠转义序列，如下所示：
```sql
mysql> INSERT INTO facts VALUES
     >   ('{"mascot": "Our mascot is a dolphin named \\"Sakila\\"."}');
```
使用双反斜杠可以防止 MySQL 执行转义序列处理，而是使其将字符串文字传递给存储引擎进行处理。 以上述任一方式插入 JSON 对象后，您可以通过执行简单的 SELECT 看到反斜杠出现在 JSON 列值中，如下所示：
```sql
mysql> SELECT sentence FROM facts;
+---------------------------------------------------------+
| sentence                                                |
+---------------------------------------------------------+
| {"mascot": "Our mascot is a dolphin named \"Sakila\"."} |
+---------------------------------------------------------+
```
要使用mascot作为关键字查找这个特定的句子，您可以使用列路径运算符 ->，如下所示：
```sql
mysql> SELECT col->"$.mascot" FROM qtest;
+---------------------------------------------+
| col->"$.mascot"                             |
+---------------------------------------------+
| "Our mascot is a dolphin named \"Sakila\"." |
+---------------------------------------------+
1 row in set (0.00 sec)
```
这使反斜杠以及周围的引号保持完整。 要使用mascot作为键显示所需的值，但不包括周围的引号或任何转义符，请使用内联路径运算符 ->>，如下所示：
```sql
mysql> SELECT sentence->>"$.mascot" FROM facts;
+-----------------------------------------+
| sentence->>"$.mascot"                   |
+-----------------------------------------+
| Our mascot is a dolphin named "Sakila". |
+-----------------------------------------+
```
需要注意的地方:
如果启用了 NO_BACKSLASH_ESCAES 服务器 SQL 模式，则前面的示例将无法正常工作。 如果设置了此模式，则可以使用单个反斜杠而不是双反斜杠来插入 JSON 对象文字，并保留反斜杠。 如果在执行插入时使用 JSON_OBJECT() 函数并且设置了此模式，则必须交替使用单引号和双引号，如下所示：
```sql
mysql> INSERT INTO facts VALUES
     > (JSON_OBJECT('mascot', 'Our mascot is a dolphin named "Sakila".'));
```
## json值的Normalization、Merging、Autowrapping
当一个字符串被解析，并且是一个有效的JSON对象时，在这个过程中，它也被标注化处理了，这意味着重复的key的值会被覆盖，下面是一个例子
```sql
mysql> SELECT JSON_OBJECT('key1', 1, 'key2', 'abc', 'key1', 'def');
+------------------------------------------------------+
| JSON_OBJECT('key1', 1, 'key2', 'abc', 'key1', 'def') |
+------------------------------------------------------+
| {"key1": "def", "key2": "abc"}                       |
+------------------------------------------------------+
```
当json被写入到列时，也会执行标准化
```sql
mysql> CREATE TABLE t1 (c1 JSON);

mysql> INSERT INTO t1 VALUES
     >     ('{"x": 17, "x": "red"}'),
     >     ('{"x": 17, "x": "red", "x": [3, 5, 7]}');

mysql> SELECT c1 FROM t1;
+------------------+
| c1               |
+------------------+
| {"x": "red"}     |
| {"x": [3, 5, 7]} |
+------------------+
```
这种“最后一个重复键获胜”行为是由 RFC 7159 建议的，并且大多数 JavaScript 解析器都实现了。
在 MySQL 8.0.3 之前的版本中，具有与文档中较早找到的键重复的键的成员将被丢弃。 以下 JSON_OBJECT() 调用生成的对象值不包含第二个 key1 元素，因为该键名称出现在值的较早位置：
```sql
mysql> SELECT JSON_OBJECT('key1', 1, 'key2', 'abc', 'key1', 'def');
+------------------------------------------------------+
| JSON_OBJECT('key1', 1, 'key2', 'abc', 'key1', 'def') |
+------------------------------------------------------+
| {"key1": 1, "key2": "abc"}                           |
+------------------------------------------------------+
```
在 MySQL 8.0.3 之前，在将值插入 JSON 列时也会执行这种“第一个重复键获胜”规范化。
```sql
mysql> CREATE TABLE t1 (c1 JSON);

mysql> INSERT INTO t1 VALUES
     >     ('{"x": 17, "x": "red"}'),
     >     ('{"x": 17, "x": "red", "x": [3, 5, 7]}');

mysql> SELECT c1 FROM t1;
+-----------+
| c1        |
+-----------+
| {"x": 17} |
| {"x": 17} |
+-----------+
```
MySQL 还会丢弃原始 JSON 文档中的键、值或元素之间的额外空白，并在显示时在每个逗号 (,) 或冒号 (:) 后面留下（或在必要时插入）一个空格。 这样做是为了提高可读性。
生成 JSON 值的 MySQL 函数（请参阅第 12.18.2 节，“创建 JSON 值的函数”）始终返回规范化值。
为了提高查找效率，MySQL 还对 JSON 对象的键进行排序。 您应该知道，此排序的结果可能会发生变化，并且不能保证跨版本保持一致。
## Merging JSON Values
MySQL 8.0.3（及更高版本）支持两种合并算法，由函数 JSON_MERGE_PRESERVE() 和 JSON_MERGE_PATCH() 实现。 它们在处理重复键的方式上有所不同：JSON_MERGE_PRESERVE() 保留重复键的值，而 JSON_MERGE_PATCH() 丢弃除最后一个值之外的所有值。 接下来的几段将解释这两个函数中的每一个如何处理 JSON 文档（即对象和数组）的不同组合的合并。
JSON_MERGE_PRESERVE() 与 MySQL 以前版本中的 JSON_MERGE() 函数相同（在 MySQL 8.0.3 中重命名）。 JSON_MERGE() 在 MySQL 8.0 中仍受支持作为 JSON_MERGE_PRESERVE() 的别名，但已被弃用并在未来版本中被删除。
合并数组。 在组合多个数组的上下文中，数组合并为一个数组。 JSON_MERGE_PRESERVE() 通过将稍后命名的数组连接到第一个数组的末尾来做到这一点。 JSON_MERGE_PATCH() 将每个参数视为由单个元素组成的数组（因此将 0 作为其索引），然后应用“最后一个重复键获胜”逻辑以仅选择最后一个参数。 您可以比较此查询显示的结果：
```sql
mysql> SELECT
    ->   JSON_MERGE_PRESERVE('[1, 2]', '["a", "b", "c"]', '[true, false]') AS Preserve,
    ->   JSON_MERGE_PATCH('[1, 2]', '["a", "b", "c"]', '[true, false]') AS Patch\G
*************************** 1. row ***************************
Preserve: [1, 2, "a", "b", "c", true, false]
   Patch: [true, false]
```
合并后的多个对象会生成一个对象。 JSON_MERGE_PRESERVE() 通过组合数组中该键的所有唯一值来处理具有相同键的多个对象； 然后将此数组用作结果中该键的值。 JSON_MERGE_PATCH() 丢弃找到重复键的值，从左到右工作，因此结果只包含该键的最后一个值。 以下查询说明了重复键 a 的结果差异：
```sql
mysql> SELECT
    ->   JSON_MERGE_PRESERVE('{"a": 1, "b": 2}', '{"c": 3, "a": 4}', '{"c": 5, "d": 3}') AS Preserve,
    ->   JSON_MERGE_PATCH('{"a": 3, "b": 2}', '{"c": 3, "a": 4}', '{"c": 5, "d": 3}') AS Patch\G
*************************** 1. row ***************************
Preserve: {"a": [1, 4], "b": 2, "c": [3, 5], "d": 3}
   Patch: {"a": 4, "b": 2, "c": 5, "d": 3}
```
在需要数组值的上下文中使用的非数组值是自动包装的：该值由 [ 和 ] 字符包围以将其转换为数组。 在以下语句中，每个参数都自动包装为一个数组 ([1], [2])。 然后将它们合并以生成单个结果数组； 与前两种情况一样，JSON_MERGE_PRESERVE() 组合具有相同键的值，而 JSON_MERGE_PATCH() 丢弃除最后一个之外的所有重复键的值，如下所示：
```sql
mysql> SELECT
	  ->   JSON_MERGE_PRESERVE('1', '2') AS Preserve,
	  ->   JSON_MERGE_PATCH('1', '2') AS Patch\G
*************************** 1. row ***************************
Preserve: [1, 2]
   Patch: 2
```
数组和对象值通过将对象自动包装为数组并根据合并函数的选择（分别为 JSON_MERGE_PRESERVE() 或 JSON_MERGE_PATCH()）组合值或通过“最后一个重复键获胜”来合并数组，如可以 在这个例子中看到：
```sql
mysql> SELECT
	  ->   JSON_MERGE_PRESERVE('[10, 20]', '{"a": "x", "b": "y"}') AS Preserve,
	  ->   JSON_MERGE_PATCH('[10, 20]', '{"a": "x", "b": "y"}') AS Patch\G
*************************** 1. row ***************************
Preserve: [10, 20, {"a": "x", "b": "y"}]
   Patch: {"a": "x", "b": "y"}
```
## 搜索与更改JSON值
JSON路径表达式就是从JSON中选择一个值。


