zookeeper可以帮助简化分布式系统构建的复杂性。
# 第一章 简介
zookeeper可以让开发人员实现通用的协作任务，包括选举主节点、管理组内成员关系、管理元数据等，zookeeper包含server与client端，使用zk时最好将应用数据与协同数据独立开。
## 1.1 ZK的使命
它可以在分布式系统中协作多个任务；这些任务比如向群首选举的竞争问题，有任务的协作问题，有任务的分配等开发人员使用Zookeeper开发时，这些应用可以认为是一组连接到ZK服务端的客户端，他们通过ZK的客户端API连接到Zookeeper服务器进行相应的操作，客户端API：
- 保障强一致性、有序性、持久性;
- 实现通用的同步原语的能力;
- 提供并发处理机制。


