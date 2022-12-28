本参考文档，你可以发现Redis Cluster算法的设计考虑，本文档一直跟随最新的Redis版本更新。
# 主要的设计考虑
## Redis Cluster目标
Redis Cluster是Redis的分布式实现，设计中的目标按照重要性考虑如下:
- 高性能，可线性扩展到1000个节点，没有代理，异步复制，不需要对key执行归并操作;
- 写入安全可接受度，系统尽最大努力尝试保留所有从客户端到master主要节点连接的写入操作。通常有一个小的窗口，在这个窗口时间内，acknowledged的写入操作可能会丢失，(即，在发生failover之前的小段时间窗内的写操作可能在failover中丢失)。而在(网络)分区故障下，对少数派master的写入，发生写丢失的时间窗会很大。
- 可用性，Redis Cluster在以下场景下集群总是可用：大部分master节点可用，并且对少部分不可用的master，每一个master至少有一个当前可用的slave。更进一步，通过使用 replicas migration 技术，当前没有slave的master会从当前拥有多个slave的master接受到一个新slave来确保可用性。
## Implemented subset
Redis Cluster支持所有的单个key的命令，执行复杂的多个key的操作的命令比如set并集或者交集的实现只支持操作中的所有的key都必须是hash到同一个slot中的所有的key。Redis Cluster实现了一个叫做hash tags的概念，可以用来强制特定的key存储到同一个hash slot中，然而，当人工重新切分分片时，多个key的操作可能会失效。Redis Cluster不支持多个数据库，只支持数据库0，select命令不可用。
# Redis Cluster协议中Clients与Servers角色
