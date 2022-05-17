
# 本地缓存
## LoadingCache
## Caffine
Caffeine是一个高性能的、近乎最佳命中率的缓存库，Caffeine是基于Java8开发的，与Map的区别是，Caffeine缓存会自动移除元素并且支持自动加载刷新元素；Caffeine内部使用了Google Guava的API来提供缓存的功能，吸收了Guava's cache与ConcurrentLinkedHashMap的设计经验。Caffeine创建缓存非常灵活，并且创建的缓存具有以下特点：
- 可以以异步/同步的方式自动加载数据到缓存中；
- 当达到最大容量时，有LFU/LRU的基于容量的驱逐机制；
- 有过期策略设置；
- 异步自动刷新机制；
- key自动包装为弱引用；
- value自动包装为弱引用或者软引用；
- 清除通知机制；
- 可以写入到外部资源；
- 精确的缓存访问统计功能；
- 符合JSR-107 JCache接口规范；
- 具有Guava的适配器;
### Population
有4种缓存Population策略：
- 手动加载
```java
Cache<Key, Graph> cache = Caffeine.newBuilder()
    .expireAfterWrite(10, TimeUnit.MINUTES)
    .maximumSize(10_000)
    .build();

// Lookup an entry, or null if not found
Graph graph = cache.getIfPresent(key);
// Lookup and compute an entry if absent, or null if not computable
graph = cache.get(key, k -> createExpensiveGraph(key));
// Insert or update an entry
cache.put(key, graph);
// Remove an entry
cache.invalidate(key);
```
Cache接口可以控制缓存的检索、更新与作废。可以通过put直接插入缓存，会覆盖之前的key，用cache.get(key, k -> value)的方式更好，这种方式执行缓存内容的原子计算完成后将结果插入到缓存中，这避免避免和其他写操作的竞争。值得注意的是，当缓存的元素无法生成或者在生成的过程中抛出异常而导致生成元素失败，cache.get会返回null。当然，也可以使用Cache.asMap()所暴露出来的ConcurrentMap的方法对缓存进行操作。
- 同步loading
```java
LoadingCache<Key, Graph> cache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .expireAfterWrite(10, TimeUnit.MINUTES)
    .build(key -> createExpensiveGraph(key));

// Lookup and compute an entry if absent, or null if not computable
Graph graph = cache.get(key);
// Lookup and compute entries that are absent
Map<Key, Graph> graphs = cache.getAll(keys);
```
- 手动异步加载
- 异步loading
### 计算
```java
Cache<Key, Graph> graphs = Caffeine.newBuilder()
    .evictionListener((Key key, Graph graph, RemovalCause cause) -> {
      // atomically intercept the entry's eviction
    }).build();

graphs.asMap().compute(key, (k, v) -> {
  Graph graph = createExpensiveGraph(key);
  ... // update a secondary store
  return graph;
});
```
在复杂的工作流中，当外部资源对key的操作变更顺序有要求的时候，Caffeine提供了实现的扩展点。对于手动操作，[Map][Concurrent Map]的compute方法提供了执行原子创建、原子更新与原子删除条目操作的能力，当一个元素被自动移除的时候，驱逐监听器可以根据映射关系计算扩展自定义操作。这意味着在缓存中，当一个key的写入操作在完成之前，后续其他写入操作都是阻塞的，同时在这段时间内，尝试获取这个key对应的缓存元素的时候获取到的也将都是旧值。
可能的使用场景
- 写模式
计算可以作为实现write-through和write-back2种模式的缓存的方式。
在一个write-throgh模式下的缓存里，操作都将是同步的并且缓存的变更只有在Writer中更新成功才会生效，这避免了缓存更新与外部资源更新都是独立的原子操作时候的资源竞争。在一个write-back模式下的缓存里，在缓存更新之后，将会异步执行外部数据源的更新，这会增加数据不一致的风险，比如在外部数据源更新失败的情况下缓存里的数据将会变得非法，这种方式在一定时间后延迟写，控制写的速率和批量写的场景下将会十分有效。
write-back模式下可以实现以下几种特性: 
* 批量和合并操作;
* 延迟操作指定的时间窗口;
* 如果批处理的数据量超过阈值大小，那么将在定期刷新之前提前执行批处理操作;
* 如果外部资源操作还没有刷新，则从write-behind缓存当中加载数据;
* 根据外部资源的特性控制重试、速率和并发度。
  
可以通过查看这2个demo参考[write-behind-rxjava](https://github.com/ben-manes/caffeine/tree/master/examples/write-behind-rxjava)与[RxJava](https://github.com/ReactiveX/RxJava)。
- 分层
- layered cache多级缓存支持从一个数据系统所支持的外部缓存中加载和写入，这允许构建一个数据量更小速度更快的缓存数据回落到一个数据量更大但是速度较慢的大缓存中，典型的多级缓存包含堆外缓存，基于文件的缓存与远程缓存。victim cache是多级缓存的一种变种，它将把被驱逐的数据写入到二级缓存当中去，delete(K,V,RemovalCause)方法支持查看被移除缓存的具体信息和移除原因。
- 同步监听器
一个 synchronous listener 同步监听器将会按照指定key的操作顺序接收到相应的事件。这个监听器可以用来阻塞该操作也可以把这次操作事件投入到队列中被异步处理。这种类型的监听器可以用来作为备份或者构造一个分布式缓存。
### 规范
```java
Interner<String> interner = Interner.newStrongInterner();
String s1 = interner.intern(new String("value"));
String s2 = interner.intern(new String("value"));
assert s1 == s2
```
一个Interner将会返回给定元素的标准规范形式，当调用intern(e)方法时，如果该interner已经包含一个由Object.equals方法确认相等的对象的时候，将会返回其中已经包含的对象，否则将会新添加该对象返回，这种重复数据删除通常用于共享规范实例来减少内存使用.
```java
LoadingCache<Key, Graph> graphs = Caffeine.newBuilder()
    .weakKeys()
    .build(key -> createExpensiveGraph(key));
Interner<Key> interner = Interner.newWeakInterner();

Key canonical = interner.intern(key);
Graph graph = graphs.get(canonical);
```
一个弱引用的interner允许其中的内部对象在没有别的强引用的前提下被GC回收，与caffeine的caffeine.weakKeys()不同的是，这里通过(==)来进行比较而不是equals()，这样可以确保应用程序所引用的interner中的值，正是缓存中的实际实例，否则在缓存当中的所持有的弱引用key很有可能是与应用程序所持有的实例不同的实例，这会导致这个key会在gc的时候被提早从缓存当中被淘汰。
### 清理
在默认情况下，当一个缓存元素过期的时候，Caffeine不会自动立即将其清理和驱逐，而它将会在写操作之后进行少量的维护工作，在写操作较少的情况下，也偶尔会在读操作之后进行，如果你的缓存吞吐量较高，那么你不用担心你的缓存的过期维护问题，但是如果你的缓存读写操作都很少，可以像下文描述的方式额外通过一个线程去通过Cache.cleanUp()方法在合适的时候出发清理操作。
```java
LoadingCache<Key, Graph> graphs = Caffeine.newBuilder()
    .scheduler(Scheduler.systemScheduler())
    .expireAfterWrite(10, TimeUnit.MINUTES)
    .build(key -> createExpensiveGraph(key));
```
Scheduler可以提前触发过期元素清理移除，在过期事件之间进行调度，以期在短时间内最小化连续的批处理操作的数量，这里的调度是尽可能做到合理，并不能保证在一个元素过期的时候就将其清除，Java9以上的用户可以通过Scheduler.systemScheduler()来利用专用的系统范围内的调度线程。
```java
Cache<Key, Graph> graphs = Caffeine.newBuilder().weakValues().build();
Cleaner cleaner = Cleaner.create();

cleaner.register(graph, graphs::cleanUp);
graphs.put(key, graph);
```
Java 9以上的用户也可以通过Cleaner去出发移除关于基于引用的元素（在使用了waekKeys、weakValues、softValues），只要将key或者缓存的元素Value注册到Cleaner上，就可以在程序运行中调用Cache.cleanUp()方法触发缓存的维护工作。
### 策略
策略的选择在缓存的构造中是灵活可选的，在程序的运行过程中，这些策略的配置也可以被检查并修改，策略通过Optional表明当前缓存是否支持其策略。
- 基于容量
```java
cache.policy().eviction().ifPresent(eviction -> {
  eviction.setMaximum(2 * eviction.getMaximum());
});
```
如果当前缓存容量是受最大权重所限制的，那么可以通过weightedSize()方法获得当前缓存，这与Cache.estimatedSize()区别在于，Cache.estimatedSize()将会返回当前缓存中存在的元素个数。缓存的最大容量或者总权重可以通过getMaximum()得到并且可以通过setMaximum(long)方法对其进行调整，缓存将会不断驱逐元素，直到符合最新的阈值。如果想要得到缓存中最有可能被保留或者最有可能被驱逐的元素子集，可以同难过hottest(int)和coldest(int)方法获得以上2个子集的元素快照。
- 基于时间
```java
cache.policy().expireAfterAccess().ifPresent(expiration -> ...);
cache.policy().expireAfterWrite().ifPresent(expiration -> ...);
cache.policy().expireVariably().ifPresent(expiration -> ...);
cache.policy().refreshAfterWrite().ifPresent(refresh -> ...);
```
ageOf(key,TimeUnit)方法提供了查看缓存元素在expireAfterAccess、expireAfterWrite、refreshAfterWrite策略下的空闲时间的途径，缓存中的元素最大可持续时间可以通过getExpiresAfter(TimeUnit)方法获取，并且可以通过setExpiresAfter(long, TimeUnit)方法来进行调整。如果需要查看最接近保留或者最接近过期的元素子集，那么需要调用youngest(int)和oldest(int)方法来得到以上2个子集的元素快照。
### 测试


## EhCache
## Map
# 分布式缓存
## redis
## memcached
## tair
tair提供快速访问内存（MDB引擎）/持久化（LDB引擎）存储服务，基于高性能、高可用的分布式集群架构，满足读写性能要求高与容量可弹性伸缩的业务需求。
### 架构
包含3个模块ConfigServer、DataServer与Client
### 优势
- 分布式架构，具备自动容灾与故障迁移能力，支持负载均衡，数据均匀分布，支持弹性拓展系统的存储空间与吞吐性能，突破海量数据高QPS性能瓶颈；
- 丰富易用的接口，数据结构丰富，支持数据过期与版本控制；
### 应用场景
- 数据库缓存，解决并发造成的数据库系统负载升高、响应延迟下降等问题；
- 临时数据存储，比如作为session manager使用；
- 数据存储，因为支持数据本地存储，可以支持离线数据；
- 黑白名单；
- 分布式锁。
## JetCache
