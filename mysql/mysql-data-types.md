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

