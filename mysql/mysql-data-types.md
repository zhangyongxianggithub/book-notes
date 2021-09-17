[TOC]
# JSON数据类型
MySQL支持RFC7159定义的Json数据类型，相比于存储string类型，json类型的优势如下：
- json格式自动校验；
- 存储格式优化，json文档是按照一种内部格式存储的，这种内部格式支持快速的访问内部节点，当服务需要读取一个json文档时，json文档不需要从一个文本表示的字符串中反序列化，json文档的二进制格式就支持查询子对象或者内嵌的值。
MySQL8支持JSON Merge Patch格式（使用JSON_MERGE_PATCH()函数），可以详细查看这个函数的描述。
json类型的存储空间==LONGBLOB与LONGTEXT的大小，可以看11.7节 数据类型的空间需求；需要记住的一点是，json文档的大小不能超过max_allow_packet系统变量的设置的上限，你可以使用函数json_storage_size()来确定json文档的存储空间大小。
在8.0.13之前的版本json列不支持默认值设置。json数据类型有很多支持的函数，分为3类，创建、操作、搜索；想要查看更多的函数的细节，可以看12.18节的JSON函数部分。
json列，与其他的二进制数据类型一样，是不能被直接索引的，你可以从json中的某个值上单独生成一列，在这个列上创建索引，可以看[Indexing a Generated Column to Provide a JSON Column Index](https://dev.mysql.com/doc/refman/8.0/en/create-table-secondary-indexes.html#json-column-indirect-index)获取更多的信息。
