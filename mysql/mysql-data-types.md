[TOC]
# JSON数据类型
MySQL支持RFC7159定义的Json数据类型，相比于存储string类型，json类型的优势如下：
- json格式自动校验；
- 存储格式优化，json文档是按照一种内部格式存储的，这种内部格式支持快速的访问内部节点，当服务需要读取一个json文档时，json文档不需要从一个文本表示的字符串中反序列化，json文档的二进制格式就支持查询子对象或者内嵌的值。
MySQL8支持JSON Merge Patch格式（使用JSON_MERGE_PATCH()函数），可以详细查看这个函数的描述。
