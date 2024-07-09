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
  - 值的范围为0-7或者128-135
  - 字节数组的长度为0,1,2,3,4,5,6,7,8,10,12,14,16,20,24,32
- 使用驱动程序的BSON UUID工具生成UUID

## 文档结构的其他用途
除了作为数据记录外，文档结构还用于查询过滤器、更新规范文档与索引规范文档。
1. 查询过滤器文档: 指定条件，选择哪些记录进行读取、更新和删除操作，使用`<field>:<value>`表达式指定相等条件和查询运算符表达式
   ```json
    {
    <field1>: <value1>,
    <field2>: { <operator>: <value> },
    ...
    }
   ```
2. 更新规范文档: 更新规范文档使用更新操作符来指定在更新操作期间要对特定字段执行的数据修改
   ```json
    {
    <operator1>: { <field1>: <value1>, ... },
    <operator2>: { <field2>: <value2>, ... },
    ...
    }
   ```
3. 索引规范文档: 索引规范文档定义待索引的字段和索引类型
   ```json
    { <field1>: <type1>, <field2>: <type2>, ...  }
   ```
[MongoDB 应用程序现代化指南](https://www.mongodb.com/modernize?tck=docs_server)包含
- 使用MongoDB进行数据建模的方法
- 从RDBMS数据模型迁移到MongoDB的最佳实践和注意事项
- 饮用MongoDB模式及其RDBMS等效模式

# MongoDB查询API
Query API是用于与数据进行交互的机制。查询数据的2种方式:
- [增删改查操作](https://www.mongodb.com/zh-cn/docs/manual/crud/#std-label-crud)
- [聚合管道](https://www.mongodb.com/zh-cn/docs/manual/core/aggregation-pipeline/#std-label-aggregation-pipeline)

使用查询API执行:
- 即席查询，使用GUI或者MongoDB驱动程序探索MongoDB数据
- 数据转换，使用[聚合管道](https://www.mongodb.com/zh-cn/docs/manual/core/aggregation-pipeline/#std-label-aggregation-pipeline)重塑数据并执行计算
- 文档联接支持，使用`$lookup`和`$unionWith`组合来自不同集合的数据
- 图形与地理空间查询，使用`$geoWithin`与`$geoNear`等操作符分析地理空间数据，使用`$graphLookup`分析图形数据
- 全文搜索，使用`$search`阶段对数据执行高效文本搜索
- 索引，为您的数据架构使用正确的[索引类型](https://www.mongodb.com/zh-cn/docs/manual/indexes/#std-label-indexes)，提高查询性能
- 按需物化视图，使用`$out`和`$merge`创建常见查询的物化视图
- 时间序列分析，使用时间序列集合查询和聚合带时间戳的数据

# BSON类型
BSON是一种二进制序列化格式，用于在MongoDB中存储文档和进行远程过程调用。BSON支持整数与字符串作为标识符
|类型|数值|别名|注意|
|:---:|:---:|:---:|:---:|
|双精度|1|double||
|字符串|2|string||
|对象|3|object||
|阵列|4|array||
|二进制数据|5|binData||
|未定义|6|undefined|已弃用|
|ObjectId|7|objectId||
|布尔|8|bool||
|Date|9|date||
|null|10|null||
|正则表达式|11|regex||
|数据库指针|12|dbPointer|弃用|
|JavaScript|13|javascript||
|符号|14|symbol|弃用|
|32位整数|16|int||
|时间戳|17|timestamp||
|64位整数|18|long||
|Decimal128|19|decimal||
|最小键值|-1|minKey||
|Max key|127|maxKey||

- `$type`操作符支持使用这些值按BSON类型查询字段，`$type`还支持number别名，整数、十进制等
- `$type`聚合操作符返回其参数的BSON类型
- `$isNumber`聚合操作符的参数是BSON整数、十进制数、双精度或者长整型，则返回true

确定某一个字段的类型，参阅[类型检查](https://www.mongodb.com/zh-cn/docs/mongodb-shell/reference/data-types/#std-label-check-types-in-shell)
## 二进制数据
BSON二进制`binData`是字节数组，`binData`值有一个子类型，表示符合解释二进制数据，子类型如下:
- 0-通用二进制子类型
- 1-函数数据
- 2-二进制旧版
- 3-UUID旧版
- 4-UUID
- 5-MD5
- 6-加密的BSON值
- 7-压缩时间序列数据
- 128-自定义数据

## ObjectId
对象标识符，很小，可能是唯一的，生成速度快且是有序的，长度是12个字节
- 4字节的时间戳，表示创建时间，自UNIX纪元依赖的秒数时间
- 5字节随机值，对于进程唯一
- 3字节的递增计数器

对于时间戳与计数器值是大端字节序，其他BSON值是小端字节序。使用整数数值创建对象标识符，则整数替换时间戳。`_id`字段使用ObjectId带来以下好处
- 可以访问方法`ObjectId.getTimestamp()`获取创建时间
- 排序

`ObjectId`随着时间的推移而增加，但是不一定是单调的，因为仅有1秒的分辨率，可能由不同系统时钟的客户端生成。使用`ObjectId()`方法设置和检索ObjectId值。
## 字符串
UTF-8编码
## 时间戳
BSON有一种特殊的时间戳类型共MongoDB内部使用，与常规的日期类型无关。内部时间戳类型是一个64位值
- 最高32位是time_t值，自UNIX纪元以来的秒数
- 后32位是递增的ordinal，表示给定秒内的顺序

在单个mongod服务中，时间戳值始终是唯一的。供内部使用。如果插入时，时间戳字段位空，MongoDB会自动插入当前时间戳值，但是`_id`字段除外。
## Date
一个64位整数，表示自UNIX纪元以来的毫秒数，有符号值，负值表示纪元以前的日期
## MongoDB扩展JSON v2
JSON只能直接表示BSON支持的类型的子集，为了保留类型信息，MongoDB在JSON格式中添加了以下扩展
- 规范模式: 凸显类型保存的字符串格式，牺牲了可读性与互操作性
- 宽松模式: 字符串格式，强调可读性与互操作性，牺牲了类型保护。

以下驱动程序使用扩展JSON v2
- C
- Java
- PHPC
- C++
- Python
- GO
- Perl
- Scala

MongoDB为扩展JSON提供了以下方法:
- `serialize`: 序列化BSON对象并以扩展JSON格式返回数据
  ```javascript
  EJSON.serialize( db.<collection>.findOne() )
  ```
- `deserialize`: 将序列化文档转换为BSON对象
  ```javascript
  EJSON.deserialize( <serialized object> )
  ```
- `stringify`: 将反序列化对象中的元素和类型对转换为字符串
  ```javascript
  EJSON.stringify( <deserialized object> )
  ```
- `parse`: 将字符串转换为元素和类型对
  ```javascript
  EJSON.parse( <string> )
  ```

### MongoDB 数据库工具
### BSON 数据类型和相关表示形式
# 安全性
MongoDB提供各种功能，身份验证、访问控制、加密，保护MongoDB部署。安全功能:
|身份验证|授权|TLS/SSL|仅限Enterprise|加密|
|身份验证|基于角色的访问控制|TLS/SSL|Kerberos身份验证|可查询加密|
|SCRAM|启用访问控制|为TLS/SSL配置mongod和mongos|LDAP代理身份验证|客户端字段级加密|
|x.509|管理用户和角色|客户端的TLS/SSL配置|OpenID Connect身份验证|静态加密|

## 身份验证
身份验证事验证客户端身份的过程，启用访问控制后，MongoDB要求所有客户端对自身进行身份验证以确定其访问权限。身份验证与授权密切相关，但是与授权又有所不同
- 身份验证验证用户的身份
- 授权确定经过验证的用户对资源和操作的访问权限
### 身份验证机制
1. SCRAM(Salted Challenge Response Authentication, 加盐质询响应身份验证机制)身份验证: MongoDB的默认身份验证机制
2. 基于x.509证书的身份验证: 支持x.509证书身份验证，用于客户端身份验证以及副本集和分片集群成员的内部身份验证，x.509证书身份验证需要安全的TLS/SSL连接
3. Kerberos身份验证: 适用于大型客户端/服务器系统的行业标准身份验证协议，使用称为票证的短期令牌提供身份验证
4. LDAP代理身份验证
## 内部/成员身份验证
## 用户
要对MongoDB中的客户端进行身份验证，必须将相应用户添加到MongoDB。可以使用`db.createUser`添加用户，创建的第一个用户必须具有创建其他用户的特权，`userAdmin`与`userAdminAnyDatabase`角色均会赋予创建其他用户的特权。创建用户时为用户分配角色，用户由用户名和关联的身份验证数据库进行唯一标识，用户有一个唯一的`userId`相关联，添加用户时，应在特定数据库中创建该用户，创建用户的数据库是该用户的身份验证数据库。用户的特权不限于其身份验证数据库，用户可以拥有跨不同数据库的权限。用户名与身份验证数据库是用户的唯一标识符，如果两个用户有相同名称，但在不同的数据库中被创建，则他们是两个独立的用户。如果您希望得到一个具有多个数据库权限的用户，请创建一个用户并授予其多个角色，每个角色对应一个适用数据库。在Mongo中创建你的用户，MongoDB会将所有用户信息存储在`admin`数据库的`system.users`集合中。
### 列出用户
```shell
use admin
db.system.users.find()
```
### 创建一个用户
启用访问控制后，用户需要证明自己的身份，您必须授予用户一个或多个角色，角色授予用户对MongoDB资源执行某些操作的特权。MongoDB 系统的每个应用程序和用户都应映射到一个不同的用户。这种访问隔离原则有利于访问撤销和持续的用户维护。为确保系统的最小特权，请仅授予用户所需的最少特权。
自托管的数据库配置用户，执行的步骤
```shell
mongosh --port 27017  --authenticationDatabase "admin" -u "myUserAdmin" -p
```
向test数据库添加用户`myTester`，该用户具有test数据库的`readWrite`与`read`权限
```shell
use test
db.createUser(
  {
    user: "myTester",
    pwd:  passwordPrompt(),   // or cleartext password
    roles: [ { role: "readWrite", db: "test" },
             { role: "read", db: "reporting" } ]
  }
)
```
`passwordPrompt()`提示你输入密码，也可以直接写密码，直接写容易把密码暴露在屏幕上或者shell的history里面。test数据库就是用户的身份认证数据库，但是与哦那个户可以有涉及到其他数据库的角色，身份认证数据库与用户的权限无关。



