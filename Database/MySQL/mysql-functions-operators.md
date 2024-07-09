# JSON函数
本节中描述的函数对 JSON 值执行操作。 有关 JSON 数据类型的讨论以及显示如何使用这些函数的额外的示例，请参阅第 11.5 节“JSON 数据类型”；对于使用JSON 参数的函数，如果参数不是有效的 JSON 值，则会发生错误。 解析为 JSON 的参数由 参数名json_doc 表示； 不解析为JSON的参数由val表示；返回 JSON 值的函数始终对这些值执行规范化（请参阅 JSON 值的规范化、合并和自动包装），从而对它们进行排序。 排序的精确结果随时可能发生变化； 不要依赖它在版本之间保持一致; 
## 函数概览
json函数表
|name|描述|
|:---|:---|
|->|返回json某个路径下的值,等价于json_extract()|
|->>|返回json某个路径下的值,并且去掉双引号,等价于json_unquote(json_extract())|
|json_array()|创建一个json数组|
|json_array_append()|向json数组追加数据|
|json_array_insert()|向json数组中插入数据|
|json_contains()|json文档中某个路径存在某些值|
|json_contains_path()|json文档中存在某个路径|
|json_depth()|json文档的深度|
|json_extract()|返回json文档中的数据|
|json_insert()|向json文档中插入数据|
|json_keys()|json文档中key的数组|
|json_length()|json文档中元素的成员数量|
|json_merge()|合并json文档，保留重复的key|
|json_merge_patch()|合并json文档，覆盖重复的key|
|json_merge_preserve()|合并json文档，保留重复的key|
|json_object()|创建json对象|
|json_overlaps()|比较2个json文档，如果他们有任何相同的key-value或者数组元素就返回true，否则返回false|
|json_pretty()|更好的打印json文档|
|json_quote()|引用json文档|
|json_remove()|从json文档中移除数据|
|json_replace()|替换json文档中的值|
|json_schema_valid()|匹配json文档的模式，匹配了返回true，否则返回false|
|json_schema_valid_report()|匹配json文档的模式，返回json格式的报告|
|json_search()|在json文档中搜索值|
|json_set()|向json中插入数据|
|json_storage_free()|json的空闲空间|
|json_table()|从json表达式中返回关系表格式的数据|
|json_type()|json值的类型|
|json_unquote()|移除json值的双引号|
|json_valid()|判断json值是否是有效的|
|json_value()|从json文档中获得某个路径下的值|
|member_of()|如果是是json数组中的元素，返回true，否则返回false|
MySQL 支持两个聚合 JSON 函数 JSON_ARRAYAGG() 和 JSON_OBJECTAGG()。 有关这些的说明，请参见第 12.20 节，“聚合函数”。

MySQL 还支持使用 JSON_PRETTY() 函数以易于阅读的格式“漂亮地打印”JSON 值。 您可以分别使用 JSON_STORAGE_SIZE() 和 JSON_STORAGE_FREE() 查看给定的 JSON 值占用了多少存储空间，以及剩余多少空间用于额外存储。 有关这些函数的完整说明，请参阅第 12.18.8 节，“JSON 实用程序函数”。
# SUM([DISTINCT] expr)[over_clause]
返回expr的总数，如果返回的集合没有行，SUM()返回NULL。DISTINCT用于计算不同的expr值的总数。如果空行或者expr是NULL，则函数返回NULL。如果出现了over_clause,则函数是作为窗口函数运行的。
# Flow Control Functions




