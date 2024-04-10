如何在Redis中使用pub/sub管道
SUBSCRIBE、UNSUBSCRIBE和PUBLISH实现了发布/订阅消息传递范式，其中（引用 Wikipedia）发送者（发布者）并不会将他们的消息发送给特定的接收者（订阅者）。相反，发布的消息被认为是一个管道，不需要知道存在哪些订阅者。订阅者对一个或多个管道表示兴趣，并且只接收感兴趣的消息，而不知道有什么（如果有的话）发布者。 发布者和订阅者的这种解耦可以实现更大的可扩展性和更动态的网络拓扑。
比如为了订阅管道foo与bar，客户端发送SUBSCRIBE命令，并且提供管道的名字。
> SUBSCRIBE foo bar

从其他客户端发送到管道的消息会被Redis推送到所有订阅该管道的所有订阅者，虽然客户端可以订阅或者取消订阅管道，订阅了管道的客户端不应该再发送命令，对订阅与取消订阅操作的结果会以消息的形式返回，1表示订阅或者取消订阅成功，0表示订阅失败，所以客户端可以读取消息流，消息的第一个元素指明消息的类型，订阅客户端上下文中允许的命令有SUBSCRIBE、SSUBSCRIBE、SUNSUBSCRIBE、PSUBSCRIBE、UNSUBSCRIBE、PUNSUBSCRIBE、PING、RESET 和 QUIT。
请注意使用redis-cli时，一单客户端处于订阅模式，将不可以发送任何命令，只能使用ctrl+c终止订阅。
## 消息格式
消息是带有3个元素的数组，第一个元素是消息的种类:
- subscribe: 意味着我们成功订阅了管道，管道的名字是第二个元素，第3个元素表示当前客户端订阅的管道的数量;
- unsubscribe: 成功取消了订阅管道，管道的名字是第二个元素，第3个元素表示当前客户端订阅的管道的数量，当为0时，表示没有订阅任何管道，此时客户端可以发送任何Redis命令，因为此时不在Pub/Sub状态;
- message: 从管道接口的消息，消息是由其他客户端publish的，第二个元素时管道的名字，第三个参数消息体;
## Database & Scoping
Pub/Sub与管道也就是key的空间没有关系，包括db编号；在db10发布，db的订阅者也可以接收到，如果你需要某些作用域限制，可以在管道的名字前面加上环境的名字前缀(test, staging, production)
## Wire protocol example
>SUBSCRIBE first second
*3
$9
subscribe
$5
first
:1
*3
$9
subscribe
$6
second
:2

## 模式匹配订阅
订阅支持模式匹配，客户端可以订阅glob-style格式的模式，接收所有符合模式的管道的消息。比如:
>PSUBSCRIBE news.*

客户端会接收所有发送到`news.art.figurative`、`news.music.jazz`等管道的消息，支持全部的glob-style模式。
>PUNSUBSCRIBE news.*

取消订阅模式，这个调用不会影响其他的订阅关系，模式匹配的结果的消息是一个不同的格式,消息的类型是pmessage，消息是其他客户端publish的，接收的消息就是这种类型，第二个元素是匹配的模式，第三个元素是管道的名字，最后是实际的消息负载。与SUBSCRIBE和UNSUBSCRIBE类似，系统会返回PSUBSCRIBE和 PUNSUBSCRIBE命令的结果消息，结果消息使用与订阅和取消订阅消息格式相同的格式，只不过消息类型是psubscribe和punsubscribe。
## Messages matching both a pattern and a channel subscription
如果发布的消息匹配多个订阅的模式，那么同一个消息会接收多次，或者发布的消息匹配订阅的模式或者管道，如下:
>SUBSCRIBE foo
>PSUBSCRIBE f*

在上面的例子中，如果一个消息发送到管道foo，客户端会受到2个消息，其中一个消息的类型是message，另一个是pmessage.
## The meaning of the subscription count with pattern matching
在 subscribe、unsubscribe、psubscribe 和 punsubscribe 消息类型中，最后一个参数是仍处于活动状态的订阅数。 这个数字实际上是客户端仍然订阅的频道和模式的总数。 因此，仅当由于取消订阅所有频道和模式而导致该计数降至零时，客户端才会退出 Pub/Sub 状态。
## Sharded Pub/Sub
从7.0开始，可以使用Pub/Sub的分片功能，分片管道分配给slot使用了分配key到slot的相同算法，分片管道的消息发送到一个节点，这个节点拥有分片管道hash到的slot，集群确保已发布的分片消息转发到分片中的所有nodes,因此客户端可以通过连接到负责插槽的主节点或其任何副本来订阅分片通道。 SSUBSCRIBE、SUNSUBSCRIBE 和 SPUBLISH 用于实现分片 Pub/Sub。
Sharded Pub/Sub 有助于在集群模式下扩展 Pub/Sub 的使用。 它将消息的传播限制在集群的分片内。 因此，与每条消息传播到集群中的每个节点的全局 Pub/Sub 相比，通过集群总线的数据量是有限的。 这允许用户通过添加更多分片来水平扩展 Pub/Sub 使用量。
因为接收到的所有消息都包含导致消息传递的原始订阅（消息类型的情况下是通道，而 pmessage 类型的情况下是原始模式）客户端库可能会将原始订阅绑定到回调（可以是匿名函数， 块，函数指针），使用哈希表。

当收到消息时，可以进行 O(1) 查找，以便将消息传递给注册的回调。

