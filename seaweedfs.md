# 组件
SeaweedFS包含3个概念性的组件：
- master service，提供分布式的对象存储，用户可以配置复制与副本等；
- volume service，提供分布式的对象存储；用户可以配置复制与副本等机制;
- 可选的filer与s3service是对象存储之上的额外的组件。
这些组件服务都可以运行在不同的服务器上，也可以运行在一个或者不同的实例中。
## Master service
轻量级运行，它标识seaweedfs集群，并且与集群中的所有的参与者通信，通过Raft协议选举一个leader。master服务的数量必须是奇数的，这会确保选举总能达成共识，master服务的数量最好不要太多。
leader是通过raft协议定期选举得到的，负责分配文件id，指定存储的volume，也会决定哪些节点是集群的一部分。fs中的所有的volume都向leader发送心跳，leader根据volume的状态发送文件存储请求。
## Volume service
实际的文件存储服务，它把很多的对象（比如文件或者文件快）打包成一个大的独立的卷，卷可以是任意大小的，数据复制与副本是在卷的层面的，而不是对象层面。
## Filer service
filer服务是做增强服务的。
它会组织fs的卷与对象到机器上的文件系统中，Filer提供了方面的对与对象的操作，比如按照文件系统的方式操作对象，也提供了web APIs用于上传与下载。
## S3 service
提供了对AWS的S3桶的支持。
## Volume
fs中的卷实际就是一个较大的文件，里面包含了很多的小文件，当master启动时，会配置卷的大小，缺省是30GB，并且启动时会初始化8个卷，每个卷都有自己的ttl与复制机制。
## Collection
每个集合世纪是卷的分组，最开始，如何集合中没有卷，就回创建一个卷，集合删除很快，只是简单的把卷从集合中移除。
# Getting Started
## 安装Seaweedfs
下载github中release中的包
解压出weed可执行程序。
``` weed -h``` 查看可用的选项；
``` weed master -h``` 查看master的可用的选项；
如果不需要复制机制，这也足够了，使用mdir选项配置生成的顺序文件ID保存的路径。
```weed master -mdir="."```
```weed master -mdir="." -ip=xxx.xxx.xxx.xxx``` 指定IP，默认是localhost
设置volume service
```weed volume -h```
通常volume server分布在不同的机器上，你可以指定可用的disk space master服务的地址与存储的目录
```weed volume -max=100 -mserver="localhost:9333" -dir=".data"```
可以吧master与volume放在一个实例中启动
```weed server -master.port=9333 -volume.port=8080 -dir="./data"```
master与volume安装好了后，使用以下命令测试
```weed upload -dir="/some/big/folder"```
上面的命令会递归的上传所有的文件，你可以指定一些包含规则
```weed upload -dir="/some/big/folder" -include=*.txt```
## 以Docker的方式运行
# Master Server API
所有的API都可以通过加上&pretty=y的参数来格式化json输出。
- 分配一个文件key，
```shell
curl 'yuhan.bestzyx.com:9333/dir/assign?pretty=y'
```
返回的结果
| Parameter | 描述 | 默认值 |
|:-|:-|:-|
|count|分配了多少个文件ID，使用<fid>_1,<fid_2>的方式表示多个文件ID|1|
|collection|集合的名字|empty|
|dataCenter||empty|
|rack||empty|
|dataNode|volume server地址|empty|
|replication|复制替换策略|默认|
|ttl|文件过期设置，m，h，d,w,m,y|never expire|
|preallocate|如果没有配置的卷，在新的卷上预先分配preallocate大小的空间|master preallocateSize|
|memoryMapMaxSizeMb||0|
|writableVolumeCount|创建新的卷的个数|master preallocateSize|
- 查询volume
```shell
curl "http://localhost:9333/dir/lookup?volumeId=3&pretty=y"
{
  "locations": [
    {
      "publicUrl": "localhost:8080",
      "url": "localhost:8080"
    }
  ]
}
# Other usages:
# You can actually use the file id to lookup, if you are lazy to parse the file id.
curl "http://localhost:9333/dir/lookup?volumeId=3,01637037d6"
# If you know the collection, specify it since it will be a little faster
curl "http://localhost:9333/dir/lookup?volumeId=3&collection=turbo"
```

# Volume Server API


