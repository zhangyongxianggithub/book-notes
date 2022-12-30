本参考文档，你可以发现Redis Cluster算法的设计考虑，本文档一直跟随最新的Redis版本更新。
[TOC]
# 主要的设计考虑
## Redis Cluster目标
Redis Cluster是Redis的分布式实现，设计中的目标按照重要性考虑如下:
- 高性能，可线性扩展到1000个节点，没有代理，异步复制，不需要对key执行归并操作;
- 写入安全可接受度，系统尽最大努力尝试保留所有从客户端到master主要节点连接的写入操作。通常有一个小的窗口，在这个窗口时间内，acknowledged的写入操作可能会丢失，(即，在发生failover之前的小段时间窗内的写操作可能在failover中丢失)。而在(网络)分区故障下，对少数派master的写入，发生写丢失的时间窗会很大。
- 可用性，Redis Cluster在以下场景下集群总是可用：大部分master节点可用，并且对少部分不可用的master，每一个master至少有一个当前可用的slave。更进一步，通过使用 replicas migration 技术，当前没有slave的master会从当前拥有多个slave的master接受到一个新slave来确保可用性。
## Implemented subset
Redis Cluster支持所有的单个key的命令，执行复杂的多个key的操作的命令比如set并集或者交集的实现只支持操作中的所有的key都必须是hash到同一个slot中的所有的key。Redis Cluster实现了一个叫做hash tags的概念，可以用来强制特定的key存储到同一个hash slot中，然而，当人工重新切分分片时，多个key的操作可能会失效。Redis Cluster不支持多个数据库，只支持数据库0，select命令不可用。
## Redis Cluster协议中Clients与Servers角色
在Redis Cluster中，节点负责持有数据，构成集群的状态，还包括映射key到正确的节点，节点要能够自动发现其他节点，检测节点被删除，当master节点发生错误时，可以帮助slave节点切换为master节点以便可以继续执行操作。集群通信使用一个TCP bus与一个二进制协议，叫做Redis Cluster Bus，集群中的节点使用bus构成强连通图，节点使用gossip协议来广播集群变更信息可以实现发现新节点，发送ping心跳信息来保证所有的节点都正常工作，还会发送特定条件满足的集群信号。cluster bus也用来广播Pub/Sub信息或者触发人工故障恢复。因为cluster节点不会代理任何请求，客户端执行操作时可能会重定向到key所在的节点，理论上，客户端可以自由地向集群中的所有节点发送请求，如果需要则进行重定向，因此客户端不需要保存集群的状态。然而，能够缓存键和节点之间的映射的客户端可以提高性能。
## 写入安全
Redis Cluster节点间采用异步复制，最后一次故障恢复确定最终结果。这意味着最后选出的主数据集最终会替换所有其他副本。总有一个时间窗口可能会在分区期间丢失写入。然而，对于连接到大多数master的客户端和连接到少数master的客户端，这些窗口非常不同。与连接到少数master的连接执行的写入相比，Redis集群更努力地保留由连接到大多数master的客户端执行的写入。以下是导致故障期间大多数master中接收到的已确认写入丢失的场景示例：
- 写入会到达一个主节点，但虽然主节点可能能够回复客户端，但写入可能不会通过主节点和副本节点之间使用的异步复制传播到副本。如果master在写入未到达副本的情况下死亡，并且master在足够长的时间内无法访问，则集群将提升其副本之一成为master，则写入将永远丢失。这在主节点突然完全失效的情况下通常很难观察到，因为主节点试图几乎同时回复客户端（确认写入）和副本（传播写入）。然而，它是真实世界的故障模式;
- 写入丢失的另一种理论上可能的故障模式如下:
  - 因为网络分区，master节点不可达;
  - master的一个副本被提升为master故障恢复;
  - 一段时间后，原来的master节点又可达了;
  - 具有过时路由表的客户端可能会在路由表更新主副本节点转换之前写入旧master。

第二种故障模式不太可能发生，因为主节点无法在足够的时间内与大多数其他主节点通信以进行故障转移，将不再接受写入，并且当分区固定时，仍然会在一小段时间内拒绝写入以允许其他节点通知配置更改。这种故障模式还要求客户端的路由表尚未更新。
写入少数派master(minority side of a partition)会有一个更长的时间窗会导致数据丢失。因为如果最终导致了failover，则写入少数派master的数据将会被多数派一侧(majority side)覆盖（在少数派master作为slave重新接入集群后）。特别地，如果要发生failover，master必须至少在NODE_TIMEOUT时间内无法被多数masters(majority of maters)连接，因此如果分区在这一时间内被修复，则不会发生写入丢失。当分区持续时间超过NODE_TIMEOUT时，所有在这段时间内对少数派master(minority side)的写入将会丢失。然而少数派一侧(minority side)将会在NODE_TIMEOUT时间之后如果还没有连上多数派一侧，则它会立即开始拒绝写入，因此对少数派master而言，存在一个进入不可用状态的最大时间窗。在这一时间窗之外，不会再有写入被接受或丢失。
## Availability
Redis Cluster在少数派分区侧不可用。在多数派分区侧，假设由多数派masters存在并且不可达的master有一个slave，cluster将会在NODE_TIMEOUT外加重新选举所需的一小段时间(通常1～2秒)后恢复可用。这意味着，Redis Cluster被设计为可以忍受一小部分节点的故障，但是如果需要在大网络分裂(network splits)事件中(【译注】比如发生多分区故障导致网络被分割成多块，且不存在多数派master分区)保持可用性，它不是一个合适的方案(【译注】比如，不要尝试在多机房间部署redis cluster，这不是redis cluster该做的事)。假设一个cluster由N个master节点组成并且每个节点仅拥有一个slave，在多数侧只有一个节点出现分区问题时，cluster的多数侧(majority side)可以保持可用，而当有两个节点出现分区故障时，只有 1-(1/(N2-1)) 的可能性保持集群可用。 也就是说，如果有一个由5个master和5个slave组成的cluster，那么当两个节点出现分区故障时，它有 1/(52-1)=11.11%的可能性发生集群不可用。Redis cluster提供了一种成为 Replicas Migration 的有用特性特性，它通过自动转移备份节点到孤master节点，在真实世界的常见场景中提升了cluster的可用性。在每次成功的failover之后，cluster会自动重新配置slave分布以尽可能保证在下一次failure中拥有更好的抵御力。
## 性能(Performance)
Redis Cluster不会将命令路由到其中的key所在的节点，而是向client发一个重定向命令 (-MOVED) 引导client到正确的节点。最终client会获得一个最新的cluster(hash slots分布)展示，以及哪个节点服务于命令中的keys，因此clients就可以获得正确的节点并用来继续执行命令。因为master和slave之间使用异步复制，节点不需要等待其他节点对写入的确认（除非使用了WAIT命令）就可以回复client。同样，因为multi-key命令被限制在了临近的key(near keys)(【译注】即同一hash slot内的key，或者从实际使用场景来说，更多的是通过hash tag定义为具备相同hash字段的有相近业务含义的一组keys)，所以除非触发resharding，数据永远不会在节点间移动。普通的命令(normal operations)会像在单个redis实例那样被执行。这意味着一个拥有N个master节点的Redis Cluster，你可以认为它拥有N倍的单个Redis性能。同时，query通常都在一个round trip中执行，因为client通常会保留与所有节点的持久化连接（连接池），因此延迟也与客户端操作单台redis实例没有区别。在对数据安全性、可用性方面提供了合理的弱保证的前提下，提供极高的性能和可扩展性，这是Redis Cluster的主要目标。
## 避免合并操作
Redis Cluster设计上避免了在多个拥有相同key的节点上的版本冲突（及合并/merge），因为在redis数据模型下这是不需要的。Redis的值同时都非常大；一个拥有数百万元素的list或sorted set是很常见的。同样，数据类型的语义也很复杂。传输和合并这类值将会产生明显的瓶颈，并可能需要对应用侧的逻辑做明显的修改，比如需要更多的内存来保存meta-data等。这里(【译注】刻意避免了merge)并没有严格的技术限制。CRDTs或同步复制状态机可以塑造与redis类似的复杂的数据类型。然而，这类系统运行时的行为与Redis Cluster其实是不一样的。Redis Cluster被设计用来支持非集群redis版本无法支持的一些额外的场景。
# Redis Cluster的主要模块
## 哈希槽(Hash Slot)key分布模型
Redis Cluster没有使用一致性哈希，而是引入了哈希槽的概念，Redis-Cluster中有16384($2_14$)个哈希槽，每个key通过CRC16校验后对16384取模来决定放置在哪个槽，Cluster中的每个节点负责一部分hash槽(hash slot)。比如集群中存在3个节点，则可能存在的一种分配如下:
- 节点A包含0-5500号哈希槽;
- 节点B包含5501到11000号哈希槽;
- 节点C包含11001到16384号哈希槽;
key空间分为16384个槽，所以集群最大的大小是16384个主节点，但是建议的最大大小是1000个节点，每个主节点都处理16384个hash槽中的子集，当slot不需要再节点间移动时，表示集群是稳定的，当集群稳定时，单个哈希槽将由单个节点提供服务（但是，服务节点可以有一个或多个副本，在网络分裂或故障的情况下替换它，并且可以用于扩展 读取陈旧数据是可接受的操作）。将key映射到slot的基本算法如下:
```bash
HASH_SLOT = CRC16(key) mod 16384
```
CRC16会输出16bit的校验码，使用集中的14位校验码，这也就是为什么以16384为模的底，
## Hash tags
hash槽的计算有一种例外情况就是hash tags，hash tags是一种保证多个key位于同一个slot的方案，这是为了解决集群中的多key操作限制的，为了实现hash tags，slot的计算方式是不同的，如果key包含"{...}"这样的模式，在{}中间的子串会被用来计算hash slot，然而，因为可能可能出现多个{}，算法的的计算规则如下:
- 如果key包含{;
- 并且{有对应的};
- 并且在第一次遇到的{}中至少存在一个字符;
相比于通过完整的key计算hash slot，只有{}中的字串会被计算hash值。
比如:
- {user1000}.following与{user1000}.followers将会hash到同一个slot中，因为字串user1000会被用来计算hash槽;
- foo{}{bar}整个key会被用来计算hash，因为第一个{}中不含任何字符;
- foo{{bar}}zap中用来计算的是{bar字符串，因为截取是从第一次遇到{开始，到第一次遇到}结束;
- foo{bar}{zap}会使用bar计算hash，因为算法在找到满足的字串后就停止搜索了;
- 如果key以{}开头，那么肯定是通过完整的key来计算hash，通常用于二进制数据作为key的名字.
下面是HASH_SLOT函数的ruby与c实现:
```ruby
def HASH_SLOT(key)
    s = key.index "{"
    if s
        e = key.index "}",s+1
        if e && e != s+1
            key = key[s+1..e-1]
        end
    end
    crc16(key) % 16384
end
```
```c
unsigned int HASH_SLOT(char *key, int keylen) {
    int s, e; /* start-end indexes of { and } */

    /* Search the first occurrence of '{'. */
    for (s = 0; s < keylen; s++)
        if (key[s] == '{') break;

    /* No '{' ? Hash the whole key. This is the base case. */
    if (s == keylen) return crc16(key,keylen) & 16383;

    /* '{' found? Check if we have the corresponding '}'. */
    for (e = s+1; e < keylen; e++)
        if (key[e] == '}') break;

    /* No '}' or nothing between {} ? Hash the whole key. */
    if (e == keylen || e == s+1) return crc16(key,keylen) & 16383;

    /* If we are here there is both a { and a } on its right. Hash
     * what is in the middle between { and }. */
    return crc16(key+s+1,e-s-1) & 16383;
}
```
## Cluster节点属性
每个节点在集群中都有一个唯一的名字，node名字是随机的160bit的16进制表示，在节点第一次启动时生成，节点将会保存ID在节点的配置文件中，将会永远使用这个ID，或者管理员将配置文件删除，或者通过`CLUSTER RESET`执行重置操作。节点ID用来标识集群中的每个节点，更改节点的IP也不需要更改节点的ID，集群可以检测到节点的IP/PORT的变化，使用gossip协议重新配置集群。节点ID不是每个节点有关的唯一的信息，但是是唯一的全局一致的信息。每个节点也有下面的关联的信息，一些信息是关于这个特定节点的集群配置细节，并且最终在整个集群中是一致的。 一些其他信息，例如上次对节点执行 ping 操作的时间，对于每个节点都是本地的。每个节点包含下面的信息:
- ID;
- port;
- flags，如果节点被标记为replica，则节点是master节点;
- node被ping的最后时间;
- pong接收的最后时间;
- 节点当前配置的epoch;
- 连接状态;
- 节点持有的hash slots;
更多的节点的信息在`CLUSTER NODES`文档中。`CLUSTER NODES`命令可以被发送到集群中的任意节点，提供集群的状态还有每个节点的信息。下面是一个输出例子:
```bash
$ redis-cli cluster nodes
d1861060fe6a534d42d8a19aeb36600e18785e04 127.0.0.1:6379 myself - 0 1318428930 1 connected 0-1364
3886e65cc906bfd9b1f7e7bde468726a052d1dae 127.0.0.1:6380 master - 1318428930 1318428931 2 connected 1365-2729
d289c575dcbc4bdd2931585fd4339089e461a27d 127.0.0.1:6381 master - 1318428931 1318428931 3 connected 2730-4095
```
在上面的列表中，不同的字段按顺序排列：节点ID、地址:端口、标志、最后发送的ping、最后接收的pong、配置纪元、链路状态、插槽。当我们谈到Redis Cluster的特定部分时，将涵盖有关上述字段的详细信息。
## The cluster bus
每一个Redis Cluster节点都有一个额外的TCP端口，用于接收从其他集群节点发送的连接，端口是数据端口+10000，或者可以通过cluster-port配置指定。
- Example 1: 如果Redis本省监听6379端口，那么缺省的bus端口是16379;
- Example 2: 如果女子爱redis.conf中指定了端口是20000，那么bus的端口是20000;
  
节点与节点之间的通信只会使用Cluster bus以及Cluster bus协议: 这是一个二进制协议，由不同类型与大小的帧组成，Cluster Bus二进制协议并没有公开的文档介绍，因为这是Redis内部使用的协议，并不对外开放，你可以阅读cluster.h与cluster.c文件获得更多的协议细节。
## Cluster拓扑结构
Redis Cluster是一个强连通网络，在一个N个节点的集群中，每个节点都有N-1个输出连接与N-1个输入连接，TCP连接会一直保持活跃状态，不会按需创建。当节点发出ping请求并等待接收到pong返回时，如果没有连接会重新刷新连接，超过一定的时间后，将节点标记为unreachable。当Redis Cluster节点形成网络集群时，节点使用gossip协议和配置更新机制以避免在正常情况下节点之间交换过多的消息，因此交换的消息数量不是指数级的。
## 节点握手
节点会一直接受来自cluster bus port的连接并响应ping消息，即使发起ping消息的节点是不被信任的。然而，如果发送节点如果不是集群的一部分，那么接收节点接收的发送节点发送的所有的信息都会被丢弃。节点加入集群的2种方式:
- 如果节点发送了MEET消息(通过cluster meet命令)，meet消息类似PING消息，当时强制接收者接受发送者节点为集群的一部分，meet消息只会通过管理员操作节点发送，操作命令: CLUSTER MEET ip port
- 通过gossip协议传输的受信任的节点信息，也会自动接受为集群的节点，比如，A知道B，B知道C，通过gossip协议信息，A与C也会互相知道。

这意味着只要我们将节点加入到集群中，集群将会自动形成强连通图，这意味着集群能够自动发现其他节点。这种机制使集群更加健壮，但可以防止不同的 Redis 集群在 IP 地址更改或其他网络相关事件发生后意外混合。
# 重定向与重分片
## MOVED重定向
## Live reconfiguration
## Ask重定向
## 客户端连接与重定向处理
## 多key操作
## 使用副本节点扩展读操作
# 容错
## 心跳与gossip消息
## 心跳内容
## 故障检测
# 配置处理、广播与故障恢复
## 集群当前的epoch
## 配置epoch
## 副本选举与角色提升
## 副本排名
## Masters reply to replica vote request
## Practical example of configuration epoch usefulness during partitions
## Hash slots configuration propagation
## UPDATE messages, a closer look
## 节点如何重新加入到集群
## 副本迁移
## 副本迁移算法
## configEpoch conflicts resolution algorithm
## 节点重置
## 从集群中移除节点
## Pub/Sub
## 附录

