Amazon Simple Storage Service(Amazon S3)提供用于多种场景的云对象存储。S3可与Flink一起使用以读取/写入数据，并可与[流的State backends](https://nightlies.apache.org/flink/flink-docs-release-1.17/zh/docs/ops/state/state_backends/)相集合使用。通过以下格式指定路径，S3对象可类似于普通普通文件使用:
```shell
s3://<your-bucket>/<endpoint>
```
endpoint可以是一个文件或者目录，例如:
```java
// 读取 S3 bucket
env.readTextFile("s3://<bucket>/<endpoint>");
// 写入 S3 bucket
stream.writeAsText("s3://<bucket>/<endpoint>");
// 使用 S3 作为 FsStatebackend
env.setStateBackend(new FsStateBackend("s3://<your-bucket>/<endpoint>"));
```
注意这些例子并不详尽，S3同样可以用在其他场景，包括JobManager高可用配置或`RocksDBStateBackend`，以及所有Flink需要使用文件系统URI的位置。在大部分使用场景下，可使用`flink-s3-fs-hadoop`或`flink-s3-fs-presto`两个独立且易于设置的S3文件系统插件。然而在某些情况下，例如使用S3作为YARN的资源存储目录时，可能需要配置Hadoop S3文件系统。
# Hadoop/Presto S3文件系统插件
Flink提供2种文件系统用来与s3交互: `flink-s3-fs-presto`和`flink-s3-fs-hadoop`。2种实现都是独立的且没有依赖项，因此使用时无需将Hadoop添加至classpath。
- `flink-s3-fs-presto`: 通过s3://与s3p://2种schema使用，基于[Presto project](https://prestodb.io/)。可以使用和[Presto文件系统相同的配置项](https://prestodb.io/docs/0.272/connector/hive.html#amazon-s3-configuration)进行配置，方式为将配置添加到flink-conf.yaml文件中。如果要在s3中使用checkpoint，推荐用Presto S3文件系统;
- `flink-s3-fs-hadoop`: 通过s3://与s3a://2种schema使用，基于[Hadoop Project](https://hadoop.apache.org/)，本文件系统可以使用类似[Haddop S3A的配置项](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html#S3A)进行配置，方式为将配置添加到flink-conf.yaml。例如，Hadoop有`fs.s3a.connection.maximum`的配置选项。如果你想在Flink程序中改变该配置的值，你需要将配置`s3.connection.maximum: xyz`添加到 flink-conf.yaml文件中。Flink会内部将其转换成配置`fs.s3a.connection.maximum`。而无需通过Hadoop的XML配置文件来传递参数。另外，它是唯一支持[FileSystem](https://nightlies.apache.org/flink/flink-docs-release-1.17/zh/docs/connectors/datastream/filesystem/)的S3文件系统。

`flink-s3-fs-hadoop`和`flink-s3-fs-presto`都为s3://scheme注册了默认的文件系统包装器，`flink-s3-fs-hadoop`另外注册了s3a://，`flink-s3-fs-presto`注册了s3p://，因此二者可以同时使用。例如某作业使用了[FileSystem](https://nightlies.apache.org/flink/flink-docs-release-1.17/zh/docs/connectors/datastream/filesystem/)，它仅支持Hadoop，但建立checkpoint使用Presto。在这种情况下，建议明确地使用s3a://作为sink (Hadoop)的scheme，checkpoint(Presto)使用s3p://。这一点对于[FileSystem](https://nightlies.apache.org/flink/flink-docs-release-1.17/zh/docs/connectors/datastream/filesystem/)同样成立。在启动Flink之前，将对应的 JAR文件从opt复制到Flink发行版的plugins目录下，以使用`flink-s3-fs-hadoop`或`flink-s3-fs-presto`
```shell
mkdir ./plugins/s3-fs-presto
cp ./opt/flink-s3-fs-presto-1.17.0.jar ./plugins/s3-fs-presto/
```
# 配置访问凭据
在设置好S3文件系统包装器后，您需要确认Flink具有访问S3 Bucket的权限。
1. **Identity and Access Management (IAM)（推荐使用）**
建议通过Identity and Access Management (IAM)来配置AWS凭据。可使用IAM功能为Flink实例安全地提供访问S3 Bucket 所需的凭据。关于配置的细节超出了本文档的范围，请参考AWS用户手册中的IAM Roles部分。如果配置正确，则可在AWS中管理对 S3的访问，而无需为Flink分发任何访问密钥（Access Key）。
2. **访问密钥（Access Key）（不推荐）**
可以通过**访问密钥对（access and secret key）**授予S3访问权限。请注意，根据Introduction of IAM roles，不推荐使用该方法。`s3.access-key`和`s3.secret-key`均需要在Flink的flink-conf.yaml中进行配置:
```yaml
s3.access-key: your-access-key
s3.secret-key: your-secret-key
```
# 配置非S3访问点
S3文件系统还支持兼容S3的对象存储服务，如IBM’s Cloud Object Storage和Minio。可在flink-conf.yaml中配置使用的访问点:`s3.endpoint: your-endpoint-hostname`
# 配置路径样式的访问
某些兼容S3的对象存储服务可能没有默认启用虚拟主机样式的寻址。这种情况下需要在flink-conf.yaml中添加配置以启用路径样式的访问：`s3.path.style.access: true`
# S3文件系统的熵注入
内置的S3文件系统(`flink-s3-fs-presto`and`flink-s3-fs-hadoop`)支持熵注入。熵注入是通过在关键字开头附近添加随机字符，以提高AWS S3 bucket可扩展性的技术。如果熵注入被启用，路径中配置好的字串将会被随机字符所替换。例如路径s3://my-bucket/_entropy_/checkpoints/dashboard-job/将会被替换成类似于s3://my-bucket/gf36ikvg/checkpoints/dashboard-job/的路径。这仅在使用熵注入选项创建文件时启用！否则将完全删除文件路径中的entropy key。更多细节请参见 FileSystem.create(Path, WriteOption)。目前 Flink运行时仅对checkpoint数据文件使用熵注入选项。所有其他文件包括 checkpoint元数据与外部URI都不使用熵注入，以保证checkpoint URI的可预测性。
配置entropy key与entropy length参数以启用熵注入：
```yaml
s3.entropy.key: _entropy_
s3.entropy.length: 4 (default)
```
`s3.entropy.key`定义了路径中被随机字符替换掉的字符串。不包含entropy key路径将保持不变。如果文件系统操作没有经过 “熵注入”写入，entropy key字串将被直接移除。`s3.entropy.length`定义了用于熵注入的随机字母/数字字符的数量。


