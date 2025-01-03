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
Redis Client可以向集群中的任意一个节点发送查询命令，包括副本节点。节点将会分析查询命令，如果它是合法的(查询中只涉及到一个key或者查询中涉及的key都位于一个hash slot中)，接收节点将会寻找key/keys所属的hash slot所在的节点。如果slot就是接收节点管理的，查询就会简单的直接处理否则，节点将会检查hash slot到节点的映射，并返回给客户端一个`MOVED error`，就像下面例子所示:
>GET x
>-MOVED 3999 127.0.0.1:6381

这个错误包括key所属的hash slot以及hash slot所对应的endpoint:port，客户端需要重新发起查询到返回中的endpoint:port地址，endpoint可以是一个IP地址、一个hostname或者是空的(比如: -MOVED 3999 :6380)，空的ednpoint意味着服务器节点有一个未知的endpoint，客户端需要重新发起到相同endpoint的给定端口的请求。
请注意，即使客户端在重新发出查询之前等待了很长时间，同时集群配置发生了变化，如果哈希槽3999现在由另一个节点提供服务，目标节点将再次回复`MOVED`错误。如果联系的节点没有更新信息，也会发生同样的情况。所以从由ID标识的集群节点的角度看，我们尝试简化我们客户端的接口，只暴露hash slot到endpoint:port表示的节点的映射。
客户端不需要但是应该尽量记住hash slot对endpoint:port的映射关系，一旦需要发起新的命令并根据key计算出hash slot，那么可以直接选择到正确的服务的目标节点。另一种方法是在收到MOVED重定向时使用`CLUSTER SHARDS`或已弃用的`CLUSTER SLOTS`命令刷新整个客户端集群布局。当遇到重定向时，很有可能需要重新配置多喝slot，所以最佳的策略是尽快更新客户端配置。
请注意，当集群稳定时（配置没有持续变化），最终所有客户端都将获得哈希槽->节点的映射，从而使集群高效，客户端直接寻址正确的节点而无需重定向、代理或其他单节点故障问题。
客户端还必须能够处理本文档后面描述的-ASK重定向，否则它不是一个完整的Redis集群客户端。
## Live reconfiguration
Redis Cluster支持在集群运行时添加/移除节点，添加或删除节点被抽象为相同的操作:将哈希槽从一个节点移动到另一个节点。这意味着可以使用相同的基本机制来重新平衡集群、添加或删除节点等。
- 当添加一个空节点到集群时，之前节点上上的一些hash slot会移动到新的节点上;
- 当从集群中移除一个节点时，分配给节点的hash slot会从当前节点中移出;
- 当重新平衡集群时，hash slots会在节点间互相移动.

核心要实现的操作是移动hash slots，从实际存储的角度看，一个hash slot就是一组key的集合，所以Redis Cluster在充分片(移动hash slot)时做的操作就是将一个实例节点的一组keys（属于该hash slot的所有的key）移动到另一个示例节点。为了理解它的工作过程，我们需要使用到`CLUSTER`子命令，这些子命令是用来操作集群节点中的槽转换表。
- `CLUSTER ADDSLOTS slot1 [slot2] ... [slotN]`
- `CLUSTER DELSLOTS slot1 [slot2] ... [slotN]`
- `CLUSTER ADDSLOTSRANGE start-slot1 end-slot1 [start-slot2 end-slot2] ... [start-slotN end-slotN]`;
- `CLUSTER DELSLOTSRANGE start-slot1 end-slot1 [start-slot2 end-slot2] ... [start-slotN end-slotN]`;
- `CLUSTER SETSLOT slot NODE node`;
- `CLUSTER SETSLOT slot MIGRATING node`;
- `CLUSTER SETSLOT slot IMPORTING node`

前面的4个命令，`ADDSLOTS`，`DELSLOTS`，`ADDSLOTSRANGE`，`DELSLOTSRANGE`用来分配(移除)节点的slot。分配slot到一个给定的master节点就意味着这个master节点要负责保存hash slot的内容，提供相关key的操作服务。分配完成后，这些信息会通过gossip协议在集群内传播，`ADDSLOTS`与`ADDSLOTSRANGE`命令通常用在一个新的集群初始创建时，这时候需要为master节点分配16384个slot的子集。`DELSLOTS`与`DELSLOTSRANGE`指令很少使用，主要用于集群配置的人工修改或者debug。`SETSLOT`指令主要用于将一个slot分配给一个特定的节点，这种模式下，slot可以被设置2种状态`MIGRATING`与`IMPORTING`，这2个特殊的状态主要用于在节点间的slot迁移。
- 当一个slot被设置为MIGRATING时，节点将接受所有关于这个slot的查询，但前提是存在键，否则查询将使用-ASK 重定向转发到作为迁移目标的节点;
- 当一个slot被设置IMPORTING状态时，节点将接受所有关于这个slot的查询，但前提是请求之前有一个ASKING命令。如果客户端没有给出ASKING命令，则查询将通过-MOVED重定向错误重定向到真正的slot所在的节点，这与正常情况一样;

看一个例子，假设我们有2个redis master节点，A与B，我们想要将slot-8从A移动到B，我们发送的命令如下:
- We send B: CLUSTER SETSLOT 8 IMPORTING A;
- We send A: CLUSTER SETSLOT 8 MIGRATING B;

所有其他的节点当接收到对slot8的查询时，仍然将客户端重定向到A，所以发生的事情是:
- 所有的已存在的key的查询都继续由A处理;
- A中不存在的key的查询由B处理，因为A将会把客户端重定向到B;

而且也不会再在A中创建新的key，与此同时，redis-cli可以查询迁移的key，如下命令:
>CLUSTER GETKEYSINSLOT slot count

上面的命令将会输出slot中keys，发送MIGRRATE命令，keys将会迁移，迁移的过程如下:
>MIGRATE target_host target_port "" target_database id timeout KEYS key1 key2 ...

MIGRATE命令将连接到目标实例，发送key的序列化版本，一旦收到OK代码，它自己数据集中的旧key将被删除。从外部客户端的角度来看，在任何一个给定时间点，key要么存在A中要么存在于B中。在Redis Cluster中不需要指定0以外的数据库，但是MIGRATE是一个通用命令，可以用于不涉及 Redis Cluster的其他任务。MIGRATE被优化为尽可能快，即使在移动复杂键（如长列表）时也是如此，但在Redis集群中，如果使用数据库的应用程序存在延迟要求，则重新配置存在大键的集群并不是一个明智的过程。当迁移过程最终完成时，SETSLOT \<slot> NODE \<node-id>命令被发送到迁移中涉及的两个节点，以便将slot再次设置为正常状态。相同的命令通常会发送到所有其他节点，以避免等待新配置在集群中自然传播。
## Ask重定向
在前面的章节，我们简单的讲述了ASK重定向，为什么我们不能简单的这用MOVED重定向，因为MOVED意味着我们认为hash slot已经永久的移动到新的节点，并且由新的节点提供服务，ASK重定向意味着将下一次查询重定向到指定的节点。这是必需的，因为关于slot-8的下一个查询的key仍在A，所以我们总是希望客户端先尝试A，然后在需要时尝试B。由于这仅发生在16384个可用哈希槽中的一个，因此对集群的性能影响是可以接受的。我们需要强制客户端行为，以确保客户端仅在尝试A之后尝试节点B，如果客户端在发送查询之前发送ASKING命令，则节点B将仅接受设置为IMPORTING状态的slot的查询。基本上，ASKING命令会在客户端设置一个一次性标志，强制节点为有关IMPORTING槽的查询提供服务。从客户端的视角来看，完整的ASK重定向语义如下:
- 如果接收到ASK重定向，下一次查询重定向到指定的节点查询，但是后面其他的查询还是向之前的节点发送;
- 使用ASKING命令重定向查询;
- 此时还不能更新本地客户端映射表，将slot 8映射到B节点.

一旦slot迁移完成，A将会发送一个MOVED消息，客户端将会更新本地slot-节点映射表。
## 客户端连接与重定向处理
为了提升性能，Redis Cluster客户端会持有当前slot配置映射，然而，这个配置没有要求要及时更新，当连接到一个错误的节点查询就会发生重定向，此时可以更新内部的slot映射。客户端通常在2种情况下需要拉取完整的slot列表以及节点映射地址:
- 启动时，更新出事的slot配置;
- 当接收到MOVED重定向时;

请注意，客户端可以通过仅更新其表中已移动的插槽来处理MOVED重定向；然而，这通常效率不高，因为通常会同时修改多个插槽的配置。例如，如果一个副本被提升为master角色，则旧master的所有槽都将被重新映射）。通过从头开始将插槽的完整映射获取到节点，对 MOVED 重定向做出反应要简单得多。客户端可以发送`CLUSTER SLOTS`命令检索slots还有相关的master节点以及副本节点。下面的例子就是`CLUSTER SLOTS`命令的例子.
>127.0.0.1:7000> cluster slots
1) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "127.0.0.1"
      2) (integer) 7001
   4) 1) "127.0.0.1"
      2) (integer) 7004
2) 1) (integer) 0
   2) (integer) 5460
   3) 1) "127.0.0.1"
      2) (integer) 7000
   4) 1) "127.0.0.1"
      2) (integer) 7003
3) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "127.0.0.1"
      2) (integer) 7002
   4) 1) "127.0.0.1"
      2) (integer) 7005

返回数组的每个元素的前两个子元素是slot范围的开始和结束。附加元素表示地址-端口对。第一个地址-端口对是服务于slot的master服务器，其他地址-端口对是服务于同一slot的副本。仅当不处于错误状态时（即未设置其FAIL标志时）才会列出副本。上面的输出中第一个元素指定slot从5461到10922（包括开始结束slot位置）由127.0.0.1:7001提供服务，可以通过副本127.0.0.1:7004进行读操作。如果集群配置错误，CLUSTER SLOTS 不能保证返回全部16384个槽，因此客户端应该初始化slot配置映射，用NULL对象填充目标节点，如果用户尝试执行有关key(属于未分配的slot)的命令，则报告错误 。在发现slot未分配时向调用者返回错误之前，客户端应尝试再次获取槽配置以检查集群现在是否已正确配置。
## 多key操作
使用hash tag，集群客户端也可以使用多key命令，比如，下面的操作时有效的:
>MSET {user:1000}.name Angela {user:1000}.surname White

当hash slot正在处于重分片过程中时，多key操作可能不可用。更具体地说，即使在重新分片期间，如果多key操作涉及的所有键都存在并且仍然散列到同一个槽（源节点或目标节点），那么多key操作就是仍是有效的。对不存在或在重新分片期间在源节点和目标节点之间拆分的键的操作将生成 -TRYAGAIN错误。 客户端可以在一段时间后尝试操作，或者报告错误。一旦指定哈希槽的迁移终止，所有多键操作就可以再次用于该哈希槽。
## 使用副本节点扩展读操作（Scaling reads using replica nodes）
正常情况下，副本节点会将客户端重定向到master节点处理命令，然而，客户端也可以使用副本处理命令，可以使用READONLY命令扩展读操作。READONLY会告诉Redis Cluster集群副本客户端可以从副本读取数据并且不关心任何写操作。当连接处于READONLY模式，只有当操作涉及的key不由master节点提供服务时，集群才会向客户端发送重定向。这可能是因为:
- 客户端发送的命令涉及的slot不由master节点提供服务;
- 集群重新配置(比如重分片)，副本不在提供指定的slot服务;

当上面的情况发生时，客户端需要更新本地的hash slot映射，连接的READONLY状态可以通过READWRITE命令清除。
# 容错
## 心跳与gossip消息
Redis Cluster节点之间会持续的交换ping/pong消息包，2种消息包具有相同的结构，都携带了重要的配置信息。唯一的不同就是字段可能不一样，这些消息包都统称为heartbeat包。通常来说，节点发送ping会触发接受者响应pong，这种情况却不一定，节点可以只发送pong数据包来向其他节点发送有关其配置的信息，而不会触发回复。 这很有用，例如，为了尽快广播新配置。通常一个节点每秒会 ping 几个随机节点，这样无论集群中有多少个节点，每个节点发送的 ping 数据包（和接收到的 pong 数据包）的总数都是一个常数。但是，每个节点都确保对未发送 ping 或未收到 pong 的时间超过 NODE_TIMEOUT 时间一半的所有其他节点执行 ping 操作。 在 NODE_TIMEOUT 过去之前，节点还尝试与另一个节点重新连接 TCP 链接，以确保不会仅因为当前 TCP 连接存在问题而认为节点无法访问。如果将 NODE_TIMEOUT 设置为一个小数字并且节点数 (N) 非常大，则全局交换的消息数量可能会很大，因为每个节点都会尝试每半年尝试 ping 其他没有最新信息的节点 NODE_TIMEOUT 时间。例如，在节点超时设置为 60 秒的 100 节点集群中，每个节点将尝试每 30 秒发送 99 个 ping，总计每秒 3.3 个 ping。 乘以 100 个节点，这就是整个集群中每秒 330 次 ping。有一些方法可以减少消息的数量，但是目前没有关于 Redis 集群故障检测使用的带宽问题的报告，所以现在使用明显和直接的设计。 请注意，即使在上面的示例中，每秒交换的 330 个数据包平均分配给 100 个不同的节点，因此每个节点接收的流量是可以接受的。
## 心跳内容
Ping/Pong消息包包含一个对于所有的类型的消息通用的header与一个特殊的gossip协议块，这个协议块是Ping/Pong消息包所特有的。通用的header包含下面的信息:
- Node ID，160 bit的伪随机字符串，在node第一次启动时分配，在节点存在期间保持不变;
- 发送节点的currentEpoch/configEpoch字段，在Redis Cluster使用的分布式算法中使用，下一节有详细的描述，如果节点是副本节点，configEpoch是master节点最近一个configEpoch;
- 节点flags，表示节点是一个副本、master或者其他信息;
- bitmap
- sender的TCP端口;
- Redis集群用来node-to-node通信的集群端口;
- sender认为的集群状态;
- 发送节点的master节点ID，如果它是一个副本。

Ping/Pong包也包括一个gossip部分，此部分向接收方提供发送方节点对集群中其他节点的方法。gossip部分集群节点中的一部分随机的节点，gossip部分包含的每一个节点信息如下:
- Node ID
- node的IP/port
- Node flags

Gossip部分允许接收节点从发送方的角度获取有关其他节点状态的信息。 这对于故障检测和发现集群中的新增节点都很有用。
## 故障检测
Redis Cluster故障检测用来识别一个master/replica节点是否不能被大多数的节点访问，此时集群就会提升一个副本为master节点，当节点提升失败，集群会设置一个error的状态，不在接受从客户端发来的查询。正如前面提到的，每个节点有持有其他已知节点的虽有的flags，有2个用于故障检测的flag，PFAIL与FAIL，PFAIL意味着可能的故障，是未确定的故障类型，FAIL意味着节点故障了。
- PFAIL flag:  当节点无法访问的状态持续超过NODE_TIMEOUT时间时，发起Ping的节点会用PFAIL标志标记这个节点。 无论其类型如何，主节点和副本节点都可以将节点标记为PFAIL。Redis集群节点的不可访问性的概念是我们有一个活动的ping（我们发送的ping，但我们还没有得到回复）等待的时间超过了NODE_TIMEOUT。 为了使该机制起作用，NODE_TIMEOUT必须比网络往返时间大。为了在正常操作期间增加可靠性，一旦NODE_TIMEOUT的一半过去而没有接收到ping的回复，节点将尝试重新连接集群中的其他节点。这种机制确保连接保持活动状态，因此断开的连接通常不会导致节点之间出现错误的故障报告。
- FAIL flag:  单独的PFAIL标志只是每个节点拥有的关于其他节点的本地信息，但不足以触发副本提升。对于要被视为关闭的节点，需要将PFAIL条件升级为FAIL条件。正如本文档的节点心跳部分所述，每个节点都会向其他每个节点发送gossip消息，包括一些随机已知节点的状态。 每个节点最终都会收到一组用于其他每个节点的节点标志。 这样每个节点都有一种机制来向其他节点发送有关它们检测到的故障情况的信号。

当下列条件满足时，PFAIL条件会升级为FAIL条件:
- 一些节点比如A，已经将B节点标识为PFAIL状态;
- 节点A通过gossip section收集集群中大多数master节点持有的节点B的状态;
- 大多数主机在NODE_TIMEOUT * FAIL_REPORT_VALIDITY_MULT时间内发出PFAIL或FAIL条件信号

如果上面所有的条件都是true，节点A会:
- 标记节点B为FAIL状态;
- 发送FAIL消息到其他的节点。

FAIL消息会强制所有接收的节点将节点标记为FAIL状态，记住，FAIL标记是单向的，也就是说，node可以从PFAIL状态切换到FAIL标记，FAIL标记只有在下面的条件满足才会清除:
 TODO 后续处理吧
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

