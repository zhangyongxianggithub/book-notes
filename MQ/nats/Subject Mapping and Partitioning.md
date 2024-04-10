Subject Mapping与Partitioning是NATS非常强大的特性。用来通过partitioning来扩展分布式消息处理系的形式，通常用于金丝雀发布、A/B测试，混沌测试或者subject迁移。2种场景应用subject mapping:
- 每个账户啊都有自己的subject mapping集合, 可以应用于客户端应用发布的任意消息，执行subject的mapping;
- 账户间导入导出使用subject mapping

如果不使用JWT安全方式，你可以在server配置文件中定义subject mapping，你只需要给nats-server发送一个信号来reload配置文件就可以让改变的mapping生效。当使用带有内置resolver的JWT安全机制时，你在账户中定义mapping与import/export，只要你把账户变更推送到服务器，变更就会生效。使用`nats server mapping`可以方便的测试subject mapping功能。

# Simple Mapping
`foo:bar`就是一个mapping的例子，server在foo主题上接收到的所有的消息都将会remapped到bar主题，订阅bar主题的客户端可以接收这些消息:`nats server mapping foo bar`
# Subject Token Reordering
通配符字符可以被位置编号引用，以便可以应用在目标subject中，使用的形式: `{{wildcard(position)}}`，比如`{{wildcard(1)}}`引用了第一个通配符字符，`{{wildcard(2)}}`引用了第二个通配符字符等等。你也可以使用传统的`$position`标记。比如`$1`引用第一个通配符字符等等。
比如: 一个mapping`"bar.*.*" : "baz.{{wildcard(2)}}.{{wildcard(1)}}"`，发送到`bar.a.b`的消息将会remapped到`baz.b.a`
# Splitting Tokens
可以分割通配符所代表的字符。有2种方式
## Splitting on a separator
你可以把标记字符通过一个特定的字符串分隔，这是通过`split(separator)`映射函数实现的。比如:
> Split on '-': nats server mapping "*" "{{split(1,-)}}" foo-bar returns foo.bar
> Split on '--': nats server mapping "*" "{{split(1,--)}}" foo--bar returns foo.bar.

## 固定偏移分拆
你也可以在一个固定的位置拆分token，使用`SplitFromLeft(wildcard index, offset)`与`SplitFromRight(wildcard index, offset)`，比如:
>Split the token at 4 from the left: nats server mapping "*" "{{splitfromleft(1,4)}}" 1234567 returns 1234.567.

>Split the token at 4 from the right: nats server mapping "*" "{{splitfromright(1,4)}}" 1234567 returns 123.4567.

# Slicing Tokens
你可以对token切片成多个部分，以一个特定的间隔。这是使用`SliceFromLeft(wildcard index, number of characters)`与`SliceFromRight(wildcard index, number of characters)`实现的。比如:
> Split every 2 characters from the left: nats server mapping "*" "{{slicefromleft(1,2)}}" 1234567 returns 12.34.56.7
> Split every 2 characters from the right: nats server mapping "*" "{{slicefromright(1,2)}}" 1234567 returns 1.23.45.67

# 确定性主题token分区
Deterministic token partitioning允许你使用使用基于主题的寻址方式，来将消息流分区，每个分区的key由subject中的一个或者多个token组成，这样将大的消息流分成较小的消息流。比如: 新的消费者订单被发布到`neworders.<customer id>`subject中，你可以把这些消息分成3个分区，使用`partition(number of partitions,wildcard token positions...)`函数功能，这个函数会返回一个分区编号(在0到分区数-1之间)，通过使用mapping，可以消息转发到具体的分区中，比如`"neworders.*" : "neworders.{{wildcard(1)}}.{{partition(3,1)}}"`需要注意的是，可以指定多个分区编号来形成一个partition key。比如，`foo.*.*`形式的subject，具有分区映射`foo.{{wildcard(1)}}.{{wildcard(2)}}.{{partition(5,1,2)}}`将会形成5个类似`foo.*.*.<n>`的分区形式，当计算分区编号时，将会计算2个token的hash值。这种特定的映射意味着，任何发布到`neworders.<customer id>`的消息，将会被mapped到`neworders.<customer id>.<a partition number 0, 1, or 2>`。mapping是确定性的，因为customer1将会始终得到相同的分区号码。mapping是基于hash计算的。它的分布是随机的，但是倾向于理想均衡的分布形式。你可以使用多个token来分区。确定性分区映射带来的效果是，从一个订阅者订阅的消息变成3个独立并行的的订阅者。
## 什么时候需要确定性分区
core NATS 队列组以及JetStream持久化消费者机制在处理消息时是无分区的以及是非确定性的。这意味着，一个subject上的2个顺序消息无法保证被同一个订阅者处理。虽然在大多数用例中，您需要一个完全动态的、需求驱动的分发，但这确实是以保证顺序为代价的，因为如果可以将两个后续消息发送给两个不同的订阅者，那么这两个订阅者将同时处理这些消息 以不同的速度（或者必须重新传输消息，或者网络速度慢等），这可能导致潜在的“乱序”消息传递。这意味着如果应用程序需要严格有序的消息处理，则需要将消息分发限制为“一次一个”（每个消费者/队列组，即使用“最大确认挂起”设置），这反过来会损害可伸缩性 因为这意味着无论您订阅了多少，一次只有一个人在做任何处理工作。
# Weighted Mappings
## For A/B Testing or Canary Release