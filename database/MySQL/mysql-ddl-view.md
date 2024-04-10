```sql
CREATE
    [OR REPLACE]
    [ALGORITHM = {UNDEFINED | MERGE | TEMPTABLE}]
    [DEFINER = user]
    [SQL SECURITY { DEFINER | INVOKER }]
    VIEW view_name [(column_list)]
    AS select_statement
    [WITH [CASCADED | LOCAL] CHECK OPTION]
```
create view语句创建或者替换一个视图。
更多视图使用的限制，可以看视图的限制的章节。
select_statement是一个SELECT语句，它提供了视图的定义，从视图中select数据时实际是使用的这个定义的select语句，select_statement可以从你table或者其他视图中选择数据，从8.0.19版本后，也可以选择VALUES作为数据源。
视图定义在创建时冻结，后续来源表的变更不会影响视图的定义，如果新增了列，不影响，如果减少的列是视图定义时的列，则会造成视图错误。
algorithm子句会影响MYSQL如何处理视图，DEFINER与SQL SECURITY子句指定了访问的安全权限的内容，with check option子句对来源表的增改做了约束。
