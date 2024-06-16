一个文档数据库，简化应用程序的开发，方便扩展而设计。有3个版本，atlas、企业版与开源版本。MongoDB中的记录时一个文档，有字段与值组成的数据结构，类似JSON对象，字段值包含其他文档、数组与文档数组。文档的优点:
- 文档对应于很多编程语言中的原生数据类型
- 嵌入式文档与数组可以减少成本高昂的链接操作
- 动态模式支持流畅的多态性

文档存储在集合中，类似关系数据库中的表。还支持视图、按需物化视图。
- 高性能，提供高性能数据持久性
  - 对嵌入式数据模型的支持减少了数据库系统的I/O活动
  - 索引支持更快的查询，并且可以包含嵌入式文档和数组的键
- 查询API，支持CRUD、聚合、文本搜索与地理空间查询
- 高可用性，复制工具提供(副本集时一组维护相同数据集的MongoDB服务器，可提供荣誉并提高数据可用性):
  - 自动故障转移
  - 数据冗余
- 横向可扩展性，
  - 分片将数据分布在机器集群上
  - 根据分片键创建数据区域，读取与写入在分片上
- 支持多种存储引擎
  - WiredTiger存储引擎
  - 内存存储引擎

# 数据库和集合
MongoDB将数据记录存储为文档，特别是BSON文档，文档聚集在集合中，数据库存储多个集合。
## 数据库
选择使用的数据库
```shell
use <db>
```
如果数据库不存在，首次存储数据时创建
```shell
use myNewDB
db.myNewCollection1.insertOne( { x: 1 } )
```
同时创建数据库与集合，名字需要符合MongoDB的[命名限制](https://www.mongodb.com/zh-cn/docs/manual/reference/limits/#std-label-restrictions-on-db-names)
## 集合
集合在第一次存储数据时创建，使用`db.createCollection()`方法显示创建集合。设置最大大小与文档验证规则，也可以在创建后修改集合。集合中的文档不要求具有相同的模式，不同的文档的相同字段也不要求具有相同的数据类型。可以在写入数据时设置文档验证规则。每个集合都有一个UUID，在副本与分片机器上集合的UUID都是相同的，运行[listCollections](https://www.mongodb.com/zh-cn/docs/manual/reference/command/listCollections/)与[db.getCollectionInfos()](https://www.mongodb.com/zh-cn/docs/manual/reference/method/db.getCollectionInfos/#mongodb-method-db.getCollectionInfos)命令查看集合。
## 视图
TODO
# 文档
MongoDB将数据记录存储为BSON文档，BSON是JSON文档的二进制表示形式，包含的数据类型比JSON更多，[BSON规范](http://bsonspec.org/)
由成对的字段与字段值组成
```json
{
   field1: value1,
   field2: value2,
   field3: value3,
   ...
   fieldN: valueN
}
```
值可以是任意的BSON数据类型，比如
```js
var mydoc = {
               _id: ObjectId("5099803df3f4948bd2f98391"),
               name: { first: "Alan", last: "Turing" },
               birth: new Date('Jun 23, 1912'),
               death: new Date('Jun 07, 1954'),
               contribs: [ "Turing machine", "Turing test", "Turingery" ],
               views : NumberLong(1250000)
            }
```
- `_id`包含一个`ObjectId`。
- `name`包含一个嵌入式文档，其中包含字段`first`和`last`。
- `birth`和`death`保存日期类型的值。
- `contribs`保存着一个字符串数组。
- `views`保存`NumberLong`类型的值

字段名称是字符串，有以下限制
- `_id`字段用作主键，在集合中必须唯一，不可变，可以是除数组与正则表达式外的任何类型，如果是嵌入式文档，则嵌入字段不能以`$`符号开头
- 字段名称不能包含`null`字符
- 允许存储包含`.`与`$`符号的字段名称

不支持文档内字段重复，MongoDB不会插入类似文档，驱动程序可能会排出重复字段。点符号访问数组元素与嵌入文档字段`"<array>.<index>"`
- `$[]`用于更新操作的所有位置操作符，
- `$[<identifier>]`用于更新操作的筛选后位置操作符，
- `$`用于更新操作的位置操作符，
- `$`当数组索引位置未知时的投影操作符
- [查询数组](https://www.mongodb.com/zh-cn/docs/manual/tutorial/query-arrays/#std-label-read-operations-arrays)以获取带有数组的点表示法示例。

要使用点符号指定或访问嵌入式文档的字段，请将嵌入式文档名称与点号和字段名称连接起来，并用引号引起来`"<embedded document>.<field>"`，文档具有以下属性
- BSON文档的大小限制为16MB，要存储超过最大文档大小的文档，使用GridFS API
- BSON文档中的字段为有序字段
- 写入操作MongoDB会保留文档字段的顺序，但是`_id`字段始终是文档中的第一个字段

在MongoDB中，每个文档都需要一个唯一的`_id`字段作为主键。如果插入的文档省略了`_id`字段，则MongoDB驱动程序会自动生成`ObjectId`类型的`_id`字段。也适用于`upsert: true`操作的文档。`_id`字段具有以下行为和约束:
- 默认情况下，MongoDB在创建集合期间会在`_id`字段上创建唯一索引
- `_id`字段始终是文档中的第一个字段，如果服务器收到文档`_id`不是第一个字段则服务器会将这个字段移动到开头。

常见的`_id`字段的类型
- `ObjectId`
- 自然唯一标识符，节省空间，避免附加索引
- 自动递增的数字
- UUID，通常存储为`BinData`类型
- `BinData`类型的索引键要使存储高效，有2个要求
  - 