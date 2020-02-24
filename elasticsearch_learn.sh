#搜索
curl 'localhost:9200/get-together/group/_search?q=elasticsearch&fields=name,location&size=1&pretty'
#在多个类型中查询
curl 'localhost:9200/get-together/group,event/_search?q=elasticsearch&pretty'
#在所有的类型中查询
curl 'localhost:9200/get-together/_search?q=sample&pretty'
#在多个索引中查询
curl 'localhost:9200/get-together,other-index/_search?q=elasticsearch&pretty&ignore_unavailable'
#在所有的索引中搜索
curl 'localhost:9200/_search?q=elasticsearch&pretty'
#测试超时时间
curl 'localhost:9200/_search?q=elasticsearch&pretty&timeout=3ms'

#更复杂的查询
curl 'localhost:9200/get-together/group/_search?pretty' -d '{
"query": {
"query_string": {
"query": "elasticsearch"
}
}
}'
#测试更多的查询参数，缺省是or
curl 'localhost:9200/get-together/group/_search?pretty' -d '{
"query": {
"query_string": {
"query": "elasticsearch san francisco",
"default_field": "name",
"default_operator": "AND"
}
}
}'
#在字段中查找一个词的快捷方式
curl 'localhost:9200/get-together/group/_search?pretty' -d '{
"query": {
"term": {
"name": "elasticsearch"
}
}
}'
#过滤查询，不对搜索结果进行相关性得分排序
curl 'localhost:9200/get-together/group/_search?pretty' -d '{
"query": {
"filtered": {
"filter": {
"term": {
"name": "elasticsearch"
}
}
}
}
}'
#聚集统计查询
curl 'localhost:9200/get-together/group/_search?pretty' -d '{
"aggregations" : {
"organizers" : {
"terms" : { "field" : "organizer" }
}
}
}'
#根据ID获取文档
curl 'localhost:9200/get-together/group/1?pretty'
#文档不存在
curl 'localhost:9200/get-together/group/doesnt-exist?pretty'