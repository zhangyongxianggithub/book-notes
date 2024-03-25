这个指南展示了如何使用Debenium来监控MySQL数据库。随着数据库数据库数据的变更，你将会看到行程的event stream。在这个指南中，你将会启动Debezium服务，运行一个MySQL服务，然后使用Debezium来监控数据库来获取变更。需要首先安装并运行Docker，这个指南使用Docker与Debezium容器镜像来运行需要的服务。你需要使用最新版本的Docker。
# Introduction to Debezium
Debezium是一个分布式平台，将数据库的数据信息转换为event stream使应用程序可以检测到这种变更并响应这种变更。Debezium基于Apache Kafka并提供了一组兼容[Kafka Connect](https://kafka.apache.org/documentation.html#connect)的连接器。每一种连接器都对应一个数据库系统。连接器检测数据库的数据变更并形成变更事件流到一个kafka的topic中。消费程序可以从Kafka的topic中读取事件记录。通过利用Kafka的可靠的流处理平台的优势，应用程序可以正确而完整的消费数据库的变更。即使你的应用意外终止或者丢失连接，也不会丢失事件。接下来的指南将会展示如何部署与使用MySQL连接器。
# Staring the services
使用Debezium需要3个不同的服务，Zookeeper、Kafka与Debezium连接器服务。在这个指南中，你会使用Docker镜像来创建这些服务的单机版本。
## Considerations for running Debezium with Docker
这个指南使用Docker与Debezium容器镜像来运行ZooKeeper, Kafka, Debezium，MySQL。每个服务运行在一个容器中将会简化部署，你也能随时看到发生的事情。生产中，你需要部署多个实例来提供性能、可靠性、复制与容错性。下面是你要提前知道的
- Zookeeper与Kafka的容器都是短命的，数据都是存在容器中，如果要持久性存储需要额外挂载Volume，否则容器停止时所有数据都不会存在
- 索引的容器都是前台的，这样可以直接在终端看到服务的输出
## Starting Zookeeper
```shell
docker run -it --rm --name zookeeper -p 2181:2181 -p 2888:2888 -p 3888:3888 quay.io/debezium/zookeeper:2.4
```
## Starting Kafka
```shell
docker run -it --rm --name kafka -p 9092:9092 --link zookeeper:zookeeper quay.io/debezium/kafka:2.4
```
## Starting a MySQL database
```shell
docker run -it --rm --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=debezium -e MYSQL_USER=mysqluser -e MYSQL_PASSWORD=mysqlpw quay.io/debezium/example-mysql:2.4
```
## Starting a MySQL command line client
```shell
docker run -it --rm --name mysqlterm --link mysql --rm mysql:8.2 sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD"'
```
## Starting Kafka Connect
```shell
docker run -it --rm --name connect -p 8083:8083 -e GROUP_ID=1 -e CONFIG_STORAGE_TOPIC=my_connect_configs -e OFFSET_STORAGE_TOPIC=my_connect_offsets -e STATUS_STORAGE_TOPIC=my_connect_statuses --link kafka:kafka --link mysql:mysql quay.io/debezium/connect:2.4
```
# Installing Debezium
有几种方式来安装并使用Debezium连接器。我们介绍几种最常用的方式。
## Installing a Debezium Connector
如果你已经安装了Zookeeper、Kafka与Kafka Connect。使用Debezium的连接器是很容易的。只需要下载连接器archive文件解压到Kafka Connect环境即可。将解压后的插件目录添加到Kafka Connect的plugin目录。还可以在worker配置(connect-distributed.properties)中使用`plugin.path`属性指定插件目录。比如，假设你下载了MySQL连接器，解压到`/kafka/connect/debezium-connector-mysql`目录。你需要指定下面的配置
>plugin.path=/kafka/connect

重新启动Kafka Connect来加载新的jar包。连接器插件可以在Maven中找到。

