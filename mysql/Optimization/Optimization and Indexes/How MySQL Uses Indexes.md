索引用来快速的查找具有特定列值的行。没有索引，MySQL必须从首行开始遍历整个表来查找相关的行。表越大，需要的时间越长。如果表有某些列的索引，MySQL将能够快速的在数据文件中定位到行的位置，不需遍历整个数据，这更快速。大多数的MySQL索引(PRIMARY KEY，UNIQUE，INDEX，FULLTEXT)都使用B-树的形式存储。几种列外的情况:
- 空间数据索引使用R-树
- MEMORY存储引擎也支持hash indexes
- InnoDB使用反转链表存储FULLTEXT索引。

下面的讨论将会使用索引，hash index的特性在[Section 8.3.9 Comparsion of B-Tree and Hash Indexes](https://dev.mysql.com/doc/refman/8.0/en/index-btree-hash.html)描述。下面的操作可以使用索引:
- 快速的发现匹配where子句的所有行;
- 快速的筛选行，如果存在多个索引，MySQL会使用具有最小行数查询结果的索引，也就是最具选择性的索引;
- 如果表有多列索引，优化器可以使用索引的最左前缀匹配的方式查找行，比如，如果你有一个3c索引在`(col1,col2,col3)`上，你就在(col1)，(col1,col2),(col1,col2,col3)上有了索引化的搜索能力。更多的信息，可以参考[Section 8.3.6 Multiple-Column Indexes](https://dev.mysql.com/doc/refman/8.0/en/multiple-column-indexes.html);
- 当执行join需要从其他表中检索行时，如果2个表的索引定义的列的类型与大小一致则使用索引会更加高效，在这里，入锅VARCHAR与CHAR定义的大小一样则被认为是同样的类型。对于非二进制字符串之间的比较，2个列的character set要一致，比如，一个utf8mb4的列与一个latin1列的比较不会使用索引;比较相异类型的列，如果列值不能直接比较，也就是需要转换的情况下则不会使用索引.对于数字列中的给定值（例如1），它可能与字符串列中的任意数量的值（例如'1'、' 1'、'00001'或'01.e1'）等价。 这排除了对字符串列使用任何索引;
- 想找到一个特殊的索引化的列key_col的MIN()/MAX()值。 This is optimized by a preprocessor that checks whether you are using WHERE key_part_N = constant on all key parts that occur before key_col in the index. In this case, MySQL does a single key lookup for each MIN() or MAX() expression and replaces it with a constant. If all expressions are replaced with constants, the query returns at once. For example:
  ```sql
  SELECT MIN(key_part2),MAX(key_part2)
  FROM tbl_name WHERE key_part1=10;
  ```
- 排序或者group一个表，如果排序或者group的条件符合一个可用索引的最左前缀比如ORDER BY key_part1, key_part2。如果所有的key都是desc顺序的，那么key将以相反的顺序读取，或者index是一个降序索引，key将以顺序的方式读取。详细参考[Section 8.2.1.16, ORDER BY Optimization](https://dev.mysql.com/doc/refman/8.0/en/order-by-optimization.html),[Section 8.2.1.17, GROUP BY Optimization](https://dev.mysql.com/doc/refman/8.0/en/group-by-optimization.html),[Section 8.3.13, Descending Indexes](https://dev.mysql.com/doc/refman/8.0/en/descending-indexes.html);
- 在一些场景下，查询会被优化，检索值时不会查询数据行（这种情况下存在一个索引提供了查询所需要的所有必要的结果，这种索引称为覆盖索引）。如果一个查询只使用到了索引中的列，查询的结果只需要从索引树中检索就行了。
  ```sql
  SELECT key_part3 FROM tbl_name
  WHERE key_part1=1
  ```

对较小的表的查询来说，索引没那么重要。对于大表来说，处理几乎所有数据的查询，索引也没什么用。当查询需要访问大多数行，顺序读取还比使用索引读取更快。顺序读取减少了磁盘寻道的时间。
