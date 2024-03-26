# Home
## Overview
Databus是一个低延迟的变更获取系统，是Linkedin的数据处理pipeline的一部分。Databus提供下面的特性
- sources/consumers之间的解耦
- 保证有序并至少一次传递
- 更改流中任意时间点的消耗，包括整个数据的完整引导功能。
- 分片消费
- 源一致性保护
## Architecture
### Databus Relays
1. 从源数据库中的 Databus 源读取更改的行，并将它们序列化为内存缓冲区中的 Databus 数据更改事件
2. 监听来自Databus Client（包括Bootstrap Producer）的请求并传输新的Databus数据更改事件
### Databus Clients
1. 检测relays上的新的变更事件，执行业务逻辑相关的回调
2. 如果已经落后relay太多，对引导服务器运行一个追赶查询
3. 新的Databus Client对引导服务器运行引导查询，然后切换到一个relay以获取最近的数据更改事件
4. 单个客户端可以处理整个数据总线流，也可以作为集群的一部分，其中每个消费者仅处理流的一部分
### Databus Bootstrap Producers
1. 一种特殊类型的Databus客户端
2. 检测relay上的新的数据变更事件
3. 存储这些事件到MySQL数据库中
4. MySQL数据库用来客户端启动与追赶使用
### Databus Bootstrap Servers
监听来自Databus Clients的请求，返回用于bootstrap和catchup的长 look-back数据更改事件
# Databus 2.0 Client Design
## Introduction
Databus Clients用于消费来自与Databus Relays的事件，
# Databus 2.0 Relay Design
## Introduction
Databus Relay负责:
- 

