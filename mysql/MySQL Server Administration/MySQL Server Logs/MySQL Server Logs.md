MySQL有几种日志用来记录MySQL的日常行为。
|Log Type|日志的信息|
|:---|:---|
|Error log|启动、运行、终止mysqld时遇到的错误|
|General query log|来自与客户端的连接与statements信息|
|Binary log|变更数据的Statements信息，也用于复制|
|Relay log|从一个source server接受到的数据变更，在slave MySQL中|
|Slow query log|记录慢查询|
|DDL log(metadata log)|记录有DDL statements执行metadata变更|

