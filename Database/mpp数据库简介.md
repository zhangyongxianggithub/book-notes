# OLAP与OLTP
- OLTP全名是Online Transaction Processing，联机事务处理，擅长事务处理，在数据操作中有很强的一致性与原子性，支持频繁的数据插入与修改，数据量很大时，体现不出优势，比如MySQL数据库；
- OLAP全名是Online Analytical Processing，联机分析处理，不关心单一数据的输入与修改等事务处理，主要是做大量数据的多维度的复杂的分析。
# 什么是MPP数据库
MPP叫做 Massively Parallel Processing，大规模并行处理，简单的思想就是将任务分成子任务到多个节点并行执行，然后汇总节点执行的结果，采用这种思想的就是MPP数据库。
# 为什么需要MPP数据库
- 海量数据分分析需求（海量数据、分析）
- 支持复杂的结构化查询（大量数据）
- Hadoop技术先天的不足（竞品太差）
# MPP数据库应用领域
- 大数据分析