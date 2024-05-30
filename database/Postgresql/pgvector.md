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
与Postgresql的full-text搜索一起实现混合搜索
```sql
SELECT id, content FROM items, plainto_tsquery('hello search') query
    WHERE textsearch @@ query ORDER BY ts_rank_cd(textsearch, query) DESC LIMIT 5;
```
# Indexing Subvectors
使用表达式索引来索引子向量
```sql
CREATE INDEX ON items USING hnsw ((subvector(embedding, 1, 3)::vector(3)) vector_cosine_ops);
```
通过余弦向量距离获取最近邻
```sql
SELECT * FROM items ORDER BY subvector(embedding, 1, 3)::vector(3) <=> subvector('[1,2,3,4,5]'::vector, 1, 3) LIMIT 5;
```
通过full vectors来Re-rank获取更好的召回效果
```sql
SELECT * FROM (
    SELECT * FROM items ORDER BY subvector(embedding, 1, 3)::vector(3) <=> subvector('[1,2,3,4,5]'::vector, 1, 3) LIMIT 20
) ORDER BY embedding <=> '[1,2,3,4,5]' LIMIT 5;
```
# Performance
## Tuning
使用工具比如[PgTune](https://pgtune.leopard.in.ua/)来为Posgres服务参数设置初始值。比如，`shared_buffers`应该是服务器内存的25%，你可以查看配置文件
```sql
SHOW config_file;
```
或者检查单个的设置
```sql
SHOW shared_buffers;
```
记住为了让变更生效需要重启Postgres
## Loading
使用`COPY`来批量加载数据
```sql
COPY items (embedding) FROM STDIN WITH (FORMAT BINARY);
```
## Indexing
可以参考[HNSW](https://github.com/pgvector/pgvector?tab=readme-ov-file#index-build-time)或者[IVFFlat](https://github.com/pgvector/pgvector?tab=readme-ov-file#index-build-time-1)的索引构建时间，在生产环境，并发创建索引避免阻塞写
```sql
CREATE INDEX CONCURRENTLY ...
```
## Querying
使用`EXPLAIN ANALYZE`来debug性能情况
```sql
EXPLAIN ANALYZE SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```
为了提高没有使用索引的查询的性能，调高`max_parallel_workers_per_gather`参数
```sql
SET max_parallel_workers_per_gather = 4;
```
如果向量被normalized to length 1，比如[OpenAI embeddings](https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use), 使用内积来达到最好的性能
```sql
SELECT * FROM items ORDER BY embedding <#> '[3,1,2]' LIMIT 5;
```
为了提高使用IVFFlat索引的查询的性能，调大inverted lists的数量
```sql
CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 1000);
```
## Vacuuming
对HNSW索引进行真空清理可能需要一些时间。可以通过先进行重新索引来加快速度。
```sql
REINDEX INDEX CONCURRENTLY index_name;
VACUUM table_name;
```
# Monitoring
使用pg_stat_statements监控性能
```sql
CREATE EXTENSION pg_stat_statements;
```
获取慢查询
```sql
SELECT query, calls, ROUND((total_plan_time + total_exec_time) / calls) AS avg_time_ms,
    ROUND((total_plan_time + total_exec_time) / 60000) AS total_time_min
    FROM pg_stat_statements ORDER BY total_plan_time + total_exec_time DESC LIMIT 20;
```
通过对比来自近似搜索的结果与精确搜索的结果监控召回
```sql
BEGIN;
SET LOCAL enable_indexscan = off; -- use exact search
SELECT ...
COMMIT;
```
# Scaling
# Frequently Asked Questions
1. 一个表中能存储多少向量?取决于表的存储上线，表的存储上限是32TB
2. 支持主从复制吗?支持，使用write-ahead log，支持复制与point-in-time recovery
3. 如果我想要索引超过2000个维度的向量怎么办？你可以使用half-precision indexing支持最高4000维度，或者binary quantization支持最高64000维度，或者使用降维技术。
4. 我能否在一列中存储不同维度的向量?你可以使用`vector`类型而不是`vector(3)`
   ```sql
   CREATE TABLE embeddings (model_id bigint, item_id bigint, embedding vector, PRIMARY KEY (model_id, item_id));
   ```
   但是，你只能在具有相同维度向量的行上创建索引
   ```sql
   CREATE INDEX ON embeddings USING hnsw ((embedding::vector(3)) vector_l2_ops) WHERE (model_id = 123);
   ```
   或者使用查询
   ```sql
   SELECT * FROM embeddings WHERE model_id = 123 ORDER BY embedding::vector(3) <-> '[3,1,2]' LIMIT 5;
   ```
5. 向量的精度能否更高?你可以使用`double precision[]`与`numeric[]`类型来存储跟高精度的向量
   ```sql
  CREATE TABLE items (id bigserial PRIMARY KEY, embedding double precision[]);

  -- use {} instead of [] for Postgres arrays
  INSERT INTO items (embedding) VALUES ('{1,2,3}'), ('{4,5,6}');
   ```
   可选的，添加一个[check constraint](https://www.postgresql.org/docs/current/ddl-constraints.html)保证数据可以被转换为`vector`并且具有预期的维度
   ```sql
   ALTER TABLE items ADD CHECK (vector_dims(embedding::vector) = 3);
   ```
   使用表达式索引来构建索引
   ```sql
   CREATE INDEX ON items USING hnsw ((embedding::vector(3)) vector_l2_ops);
   ```
   或者使用下面的查询
   ```sql
   SELECT * FROM items ORDER BY embedding::vector(3) <-> '[3,1,2]' LIMIT 5;
   ```
6. 是否索引应该小于内存?不需要，与普通的索引一样，但是如果索引都在内存中那么性能会更好，你可以获取索引的大小
   ```sql
   SELECT pg_size_pretty(pg_relation_size('index_name'));
   ```
# Troubleshooting
- 为什么一个查询没有使用到索引?
  查询需要有一个`order by`与`limit`,并且`order by`的必须是距离计算的结果的升序
  ```sql
  -- index
  ORDER BY embedding <=> '[3,1,2]' LIMIT 5;

  -- no index
  ORDER BY 1 - (embedding <=> '[3,1,2]') DESC LIMIT 5;
  ```
  你可以告诉规划器对查询使用索引
  ```sql
  BEGIN;
  SET LOCAL enable_seqscan = off;
  SELECT ...
  COMMIT;
  ```
  同时，如果表很小，表扫描没准更快。
- 为什么一个查询没有使用到并行表扫描
  当前的计划工具没有将冷存储（out-of-line storage） 纳入成本估算，这可能会让串行扫描看起来更便宜。对于包含冷存储的查询，可以通过以下方式降低并行扫描的成本:
  ```sql
  BEGIN;
  SET LOCAL min_parallel_table_scan_size = 1;
  SET LOCAL parallel_setup_cost = 1;
  SELECT ...
  COMMIT;
  ```
- 为什么对于一个查询来说，添加HNSW索引后，结果反而变少了?
  搜索结果的数量会受到动态候选列表大小(`hnsw.ef_search`)的限制。由于无效元组或查询中的过滤条件，检索到的结果可能更少。我们建议将 `hnsw.ef_search`设置为查询`LIMIT`的至少两倍。如果您需要超过`500`个结果，请改用`IVFFlat`索引。另外请注意，空向量(`NULL` vectors)和零向量(zero vectors，针对余弦距离)不会被索引
- 为什么对于一个查询来说，添加IVFFlat索引后，结果反而变少了?
  该索引可能创建时数据量太少，不足以支持当前列表数量。请暂时删除此索引，等到表中数据量增加后再重建索引。`DROP INDEX index_name;`，结果数也会收到probes数量的限制，记住空向量是不会被索引的。
# Reference
## Vector
### 类型
每个向量占用`4*dimensions+8`byte的存储空间，每个元素都是一个单精度浮点数，类似Postgres中的`real`类型，所有的元素必须是有限的，向量最多支持16000维度。
### 操作符
|Operator|Description|
|:---:|:---:|
|+|逐元素加法|
|-|逐元素减法|
|*|逐元素乘法|
|\|\||拼接|
|<->|欧几里得距离|
|<#>|负内积|
|<=>|余弦距离|
|<+>|曼哈顿距离|

### Functions
|Function|Description|
|:---:|:---:|
|binary_quantize(vector)->bit|二进制量化|
|cosine_distance(vector,vector)->double precision|余弦距离|
|inner_product(vector,vector)->double precision|内积|
|l1_distance(vector, vector)->double precision|曼哈顿距离|
|l2_distance(vector, vector) → double precision|欧几里得距离|
|l2_normalize(vector) → vector|欧几里得范数归一化|
|subvector(vector, integer, integer) → vector|子向量|
|vector_dims(vector) → integer|向量的维度|
|vector_norm(vector) → double precision|欧几里得范数|

### Aggregate Functions
|Function|Description|
|:---:|:---:|
|avg(vector) → vector|平均值向量|
|sum(vector) → vector|累加向量|

## Halfvec
每个half向量消耗`2*dimensions+8`bytes空间，每个元素都是一个半精度浮点数，所有元素都是有限的，最多支持16000个维度。
### Operators
与vector的操作符都是一致的
### Functions
与vector的函数都是一致的
### Aggregate Functions
|Function|Description|
|:---:|:---:|
|avg(vector) → vector|平均值向量|
|sum(vector) → vector|累加向量|

## Bit
每个bit向量消耗`dimensions/8+8`个bytes空间
### Operators
|Operator|Description|
|:---:|:---:|
|<～>|汉明距离|
|<%>|杰卡德距离|
### Functions
|Function|Description|
|:---:|:---:|
|hamming_distance(bit,bit)->double precision|汉明距离|
|jaccard_distance(bit,bit)->double precision|杰卡德距离|

## Sparsevec
每一个稀疏向量都消耗`8 * non-zero elements + 16`个bytes空间，每一个元素都是一个单精度浮点数，所有元素都是有限的，稀疏向量最多支持16000个非0元素
### Operators
|Operator|Description|
|:---:|:---:|
|<->|欧几里得距离|
|<#>|负内积|
|<=>|余弦距离|
|<+>|曼哈顿距离|
### Functions
|Function|Description|
|:---:|:---:|
|cosine_distance(sparsevec,sparsevec)->double precision|余弦距离|
|inner_product(sparsevec,sparsevec)->double precision|内积|
|l1_distance(sparsevec, sparsevec)->double precision|曼哈顿距离|
|l2_distance(sparsevec, sparsevec) → double precision|欧几里得距离|
|l2_normalize(sparsevec) → vector|欧几里得范数归一化|
|l2_norm(sparsevec) → double precision|欧几里得范数|

# Installation Notes-Linux/Mac
如果你的机器上安装了多个Postgres，需要指定pg_config文件的路径。
```shell
export PG_CONFIG=/Library/PostgreSQL/16/bin/pg_config
```
然后重新运行安装命令，如果有需要可以在运行`make`前运行`make clean`，如果运行`make install`需要sudo权限，那么运行
```shell
sudo --preserve-env=PG_CONFIG make install
```
Mac上的路径设置如下:
- EDB installer - `/Library/PostgreSQL/16/bin/pg_config`
- Homebrew (arm64) - `/opt/homebrew/opt/postgresql@16/bin/pg_config`
- Homebrew (x86-64) - `/usr/local/opt/postgresql@16/bin/pg_config`

如果编译失败抛出`fatal error: postgres.h: No such file or directory`异常，需要确保Postgres开发文件已经安装到服务器上，对于Ubuntu或者Debian来说，使用
```shell
sudo apt install postgresql-server-dev-16
```
如果在Mac上编译失败并抛出`warning: no such sysroot directory`的异常，需要重新安装Xcode Command Line Tools。
默认情况下，为了最好的性能，pgvector会使用`-march=native`编译，然而，如果将编译后的结果和运行在别的机器上会导致`Illegal instruction`的错误。为了可移植性，编译时使用下面的命令
```shell
make OPTFLAGS=""
```
# Installation Notes-Windows
如果编译时，抛出`Cannot open include file: 'postgres.h': No such file or directory`异常，需要确保PGROOT是正确的。如果编译时抛出`Access is denied`错误信息，使用administrator用户安装。
# Additional Installation Methods
- Docker，获取Docker镜像`docker pull pgvector/pgvector:pg16`，添加了pgvector到Postgres本身的镜像中。你也可以自己构建镜像
  ```shell
  git clone --branch v0.7.0 https://github.com/pgvector/pgvector.git
  cd pgvector
  docker build --pull --build-arg PG_MAJOR=16 -t myuser/pgvector .
  ```
- Homebrew, `brew install pgvector`
- PGXN, 从[PostgreSQL Extension Network](https://pgxn.org/dist/vector)中安装，`pgxn install vector`
- APT, Debian与Ubuntu包在[PostgreSQL APT Repository](https://wiki.postgresql.org/wiki/Apt)中可用，执行下面的安装命令`sudo apt install postgresql-16-pgvector`
- Yum, RPM包在[PostgreSQL Yum Repository](https://yum.postgresql.org/)中可用，执行下面的安装命令
  ```shell
  sudo yum install pgvector_16
  # or
  sudo dnf install pgvector_16
  ```
- pkg
- conda-forge，`conda install -c conda-forge pgvector`
- Postgres.app, 直接从[github](https://postgresapp.com/downloads.html)上下载安装包

# Hosted Postgres
托管的Postgres，在[these providers](https://github.com/pgvector/pgvector/issues/54)中

# Upgrading
安装最新的版本，就是上面的安装命令，在每个数据库中升级，运行`ALTER EXTENSION vector UPDATE;`，你可以检查当前数据库使用的版本
```sql
SELECT extversion FROM pg_extension WHERE extname = 'vector';
```