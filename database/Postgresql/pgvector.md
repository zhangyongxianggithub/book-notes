为Postgres开发的开发的开源的向量相似度搜索插件。存储向量数据与其他的关系型数据，支持
- 精确的与近似的最近邻搜索
- single-precision, half-precision, binary, and sparse vectors
- L2距离、内积、余弦距离、L1距离、汉明距离, 杰卡德距离
- 任何语言的Postgres客户端

符合ACID、point-in-time recovery、JOINs等
# Installation
编译并安装扩展
```shell
cd /tmp
git clone --branch v0.7.0 https://github.com/pgvector/pgvector.git
cd pgvector
make
make install # may need sudo
```
如果遇到问题，参考[installation notes](https://github.com/pgvector/pgvector#installation-notes---linux-and-mac)。也可以通过Docker、Homebrew、PGXN、APT、Yum、pkg或者conda-forge安装。还有一些预安装的安装包[Postgres.app](https://github.com/pgvector/pgvector#postgresapp)
# Getting Started
在用到的数据库中开启扩展
```sql
CREATE EXTENSION vector;
```
创建一个3维度的向量列
```sql
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
```
写入向量
```sql
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
```
通过L2距离获取最近邻
```sql
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```
也支持内积(`<#>`)、余弦向量(`<=>`)、L1距离(`<+>`)。`<#>`返回负的内积，因为Postgres只支持ASC顺序索引扫描。
# Storing
建表
```sql
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
```
添加列
```sql
ALTER TABLE items ADD COLUMN embedding vector(3);
```
写入向量
```sql
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
```
使用`COPY`命令批量加载向量
```sql
COPY items (embedding) FROM STDIN WITH (FORMAT BINARY);
```
Upsert向量
```sql
INSERT INTO items (id, embedding) VALUES (1, '[1,2,3]'), (2, '[4,5,6]')
    ON CONFLICT (id) DO UPDATE SET embedding = EXCLUDED.embedding;
```
更新向量
```sql
UPDATE items SET embedding = '[1,2,3]' WHERE id = 1;
```
删除向量
```sql
DELETE FROM items WHERE id = 1;
```
# Querying
获取一个向量的最近邻
```sql
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```
获取某一行的最近邻
```sql
SELECT * FROM items WHERE id != 1 ORDER BY embedding <-> (SELECT embedding FROM items WHERE id = 1) LIMIT 5;
```
获取制定距离内的行
```sql
SELECT * FROM items WHERE embedding <-> '[3,1,2]' < 5;
```
获取距离
```sql
SELECT embedding <-> '[3,1,2]' AS distance FROM items;
```
对于内积来说，需要乘以-1，因为`<#>`返回负的内积
```sql
SELECT (embedding <#> '[3,1,2]') * -1 AS inner_product FROM items;
```
对于余弦相似度，使用1-cosine distance
```sql
SELECT 1 - (embedding <=> '[3,1,2]') AS cosine_similarity FROM items;
```
平均向量
```sql
SELECT AVG(embedding) FROM items;
```
按组平均
```sql
SELECT category_id, AVG(embedding) FROM items GROUP BY category_id;
```
# Indexing
缺省情况下，pgvector执行精确的最近邻搜索，提供了最完美的召回。你可以添加index来使用金丝的最近邻搜索，提供更快的召回性能，与传统的索引不同，在添加一个金丝索引后，查询的结果是不同的。支持的索引类型
- HNSW
- IVFFlat
## HNSW
HNSW索引会创建一个多层图，它比IVFFlat有更好的查询性能(根据速度-召回权衡)，但是构建较慢，而且需要更多的内存。可以在空表上创建索引，不像IVFFlat，不需要训练这个步骤。为每个计算距离的函数添加索引:
- L2 distance
  ```sql
  CREATE INDEX ON items USING hnsw (embedding vector_l2_ops);
  ```
  `halfvec`使用`halfvec_l2_ops`而`sparsevec`使用`sparsevec_l2_ops`
- Inner product
  ```sql
  CREATE INDEX ON items USING hnsw (embedding vector_ip_ops);
  ```
- Cosine distance
  ```sql
  CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops);
  ```
- L1 distance
  ```sql
  CREATE INDEX ON items USING hnsw (embedding vector_l1_ops);
  ```
- Hamming distance
  ```sql
  CREATE INDEX ON items USING hnsw (embedding bit_hamming_ops);
  ```
- Jaccard distance
  ```sql
  CREATE INDEX ON items USING hnsw (embedding bit_jaccard_ops);
  ```

支持的类型:
- `vector`最高2000维度
- `halfvec`最高4000维度
- `bit`最高64000维度
- `sparsevec`最高1000非0元素

### Index Options
指定HNSW参数
- m-每一层的最大连接数，默认是16
- ef_construction-用来构造图的动态候选者列表的大小，默认是64

```sql
CREATE INDEX ON items USING hnsw (embedding vector_l2_ops) WITH (m = 16, ef_construction = 64);
```
`ef_construction`的值越高就提供越好的召回，但是会消耗更多的索引构建时间与数据插入时间。
### Query Options
指定用于搜索的动态候选者列表的大小，默认是40
```sql
SET hnsw.ef_search = 100;
```
值越高召回效果越好但是速度越慢。可以在一个事务中设置单次查询的值
```sql
BEGIN;
SET LOCAL hnsw.ef_search = 100;
SELECT ...
COMMIT;
```
### Index Build Time
当图的大小在`maintenance_work_mem`范围内时，索引构建速度会显著提升。
```sql
SET maintenance_work_mem = '8GB';
```
当放不下时，一个notice会出现
```
NOTICE:  hnsw graph no longer fits into maintenance_work_mem after 100000 tuples
DETAIL:  Building will take significantly more time.
HINT:  Increase maintenance_work_mem to speed up builds.
```
注意不要设置太高，防止耗尽服务器的内存。与其他的索引类似一样，在加载初始数据后，创建索引会更快。从0.6.0版本开始，你可以通过提高并发来加快索引创建
```sql
SET max_parallel_maintenance_workers = 7; -- plus leader
```
当CPU核数较多时，您可能还需要增加`max_parallel_workers`参数(默认值为8)。
### Indexing Progress
检查索引创建的进度
```sql
SELECT phase, round(100.0 * blocks_done / nullif(blocks_total, 0), 1) AS "%" FROM pg_stat_progress_create_index;
```
HNSW的阶段有2个
- initializing
- loading tuples
## IVFFlat
IVFFlat索引将向量分成列表，然后搜索这些列表中的一部分，这一部分时最接近查询向量的。它有更快的构建时间而且需要较少的内存，但是查询性能差一些。如果要实现比较好的召回效果的3个关键点
- 在表已经有了一些数据后再创建索引
- 选择合适的list数量，在100万行内使用`rows / 1000`来决定，在100万行以上使用`sqrt(rows)`来决定
- 在查询时，指定合适的probes数，较高的值会有更好的召回效果，较低的值速度较快。一个好的值是`sqrt(lists)`

为每一个距离计算函数添加索引
- L2 distance
  ```sql
  CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
  ```
- Inner product
  ```sql
  CREATE INDEX ON items USING ivfflat (embedding vector_ip_ops) WITH (lists = 100);
  ```
- Cosine distance
  ```sql
  CREATE INDEX ON items USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
  ```
- Hamming distance 
  ```sql
  CREATE INDEX ON items USING ivfflat (embedding bit_hamming_ops) WITH (lists = 100);
  ```

支持的类型有
- `vector`最多2000维度
- `halfvec`最多4000维度
- `bit`最多64000维度

### Query Options
指定probes的数量，默认是1
```sql
SET ivfflat.probes = 10;
```
值越好，召回效果越好但是速度较慢，如果设置为lists的数量，那么就是精确的最近邻搜索，此时规划器不使用索引。在事务中也可以为单次查询设置值
```sql
BEGIN;
SET LOCAL ivfflat.probes = 10;
SELECT ...
COMMIT;
```
### Index Build Time
通过提高并发来加快索引创建默认是2
```sql
SET max_parallel_maintenance_workers = 7; -- plus leader
```
如果CPU核数较多，也可以提高`max_parallel_workers`参数，默认是8
### Indexing Progress
```sql
SELECT phase, round(100.0 * tuples_done / nullif(tuples_total, 0), 1) AS "%" FROM pg_stat_progress_create_index;
```
IVFFlat的阶段有:
- initializing
- performing k-means
- assigning tuples
- loading tuples

# Filtering
有几种方法来构建具有WHERE子句的最近邻查询的索引
```sql
SELECT * FROM items WHERE category_id = 123 ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```
索引创建于WHERE子句上的一个或者多个列
```sql
CREATE INDEX ON items (category_id);
```
或者创建一个向量列的不完全索引，用于近似搜索
```sql
CREATE INDEX ON items USING hnsw (embedding vector_l2_ops) WHERE (category_id = 123);
```
使用分片完成在WHERE条件列上的很多不同值的近似搜索
```sql
CREATE TABLE items (embedding vector(3), category_id int) PARTITION BY LIST(category_id);
```
# Half-Precision Vectors
使用`halfvec`来存储half-precision vectors
```sql
CREATE TABLE items (id bigserial PRIMARY KEY, embedding halfvec(3));
```
创建索引
```sql
CREATE INDEX ON items USING hnsw ((embedding::halfvec(3)) halfvec_l2_ops);
```
获取最近邻
```sql
SELECT * FROM items ORDER BY embedding::halfvec(3) <-> '[1,2,3]' LIMIT 5;
```
# Binary Vectors
使用`bit`类型来存储binary vectors
```sql
CREATE TABLE items (id bigserial PRIMARY KEY, embedding bit(3));
INSERT INTO items (embedding) VALUES ('000'), ('111');
```
通过汉明距离获得最近邻
```sql
SELECT * FROM items ORDER BY embedding <~> '101' LIMIT 5;
SELECT * FROM items ORDER BY bit_count(embedding # '101') LIMIT 5;
```
创建二进制量化的表达式索引
```sql
CREATE INDEX ON items USING hnsw ((binary_quantize(embedding)::bit(3)) bit_hamming_ops);
```
通过汉明距离获取最近邻
```sql
SELECT * FROM items ORDER BY binary_quantize(embedding)::bit(3) <~> binary_quantize('[1,-2,3]') LIMIT 5;
```
通过原始向量rerank来获取更好的召回效果
```sql
SELECT * FROM (
    SELECT * FROM items ORDER BY binary_quantize(embedding)::bit(3) <~> binary_quantize('[1,-2,3]') LIMIT 20
) ORDER BY embedding <=> '[1,-2,3]' LIMIT 5;
```
# Sparse Vectors
使用`sparsevec`类型来哦存储稀疏向量
```sql
CREATE TABLE items (id bigserial PRIMARY KEY, embedding sparsevec(5));
```
写入向量
```sql
INSERT INTO items (embedding) VALUES ('{1:1,3:2,5:3}/5'), ('{1:4,3:5,5:6}/5');
```
格式`{index1:value1,index2:value2}/dimensions`，下标从1开始。通过L2距离获取最紧邻
```sql
SELECT * FROM items ORDER BY embedding <-> '{1:3,3:1,5:2}/5' LIMIT 5;
```
# Hybird Search
