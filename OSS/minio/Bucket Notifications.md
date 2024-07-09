MinIO Bukect通知允许管理员发送特定事件通知到外部服务，MinIO支持bucket与object级别的S3事件，类似[Amazon S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)。MinIO支持发送通知到下面的目的地址
- Publish Events to AMQP (RabbitMQ)
- Publish Events to MQTT
- Publish Events to NATS
- Publish Events to NSQ
- Publish Events to Elasticsearch
- Publish Events to Kafka
- Publish Events to MySQL
- Publish Events to PostgreSQL
- Publish Events to Redis
- Publish Events to Webhook
# Publish Events to Kafka
MinIO使用[sarama](https://github.com/Shopify/sarama)来连接Kafka。可以参考[Compatibility and API stability](https://github.com/Shopify/sarama/#compatibility-and-api-stability)获得关于Kafka兼容性的问题。
## 添加Kafka服务
可以使用环境变量或者运行时配置属性来设置
### 环境变量
MinIO回自动应用环境变量的设置，下面你的例子设置了所有跟kafka相关的环境配置，`MINIO_NOTIFY_KAFKA_ENABLE`与`MINIO_NOTIFY_KAFKA_BROKERS`2个环境变量是必须的。
```shell
set MINIO_NOTIFY_KAFKA_ENABLE_<IDENTIFIER>="on"
set MINIO_NOTIFY_KAFKA_BROKERS_<IDENTIFIER>="<ENDPOINT>"
set MINIO_NOTIFY_KAFKA_TOPIC_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_SASL_USERNAME_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_SASL_PASSWORD_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_SASL_MECHANISM_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_TLS_CLIENT_AUTH_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_SASL_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_TLS_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_TLS_SKIP_VERIFY_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_CLIENT_TLS_CERT_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_CLIENT_TLS_KEY_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_QUEUE_DIR_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_QUEUE_LIMIT_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_VERSION_<IDENTIFIER>="<string>"
set MINIO_NOTIFY_KAFKA_COMMENT_<IDENTIFIER>="<string>"
```
- \<IDENTIFIER>表示为Kafka服务起的唯一的描述性的字符串名字，在所有环境变量中同一个Kafka服务使用相同的名字，下面的例子假设是PRIMARY，如果已经存在则配置覆盖，使用`mc admin config get notify_kafka`来获取当前配置的Kafka信息。
- 使用Kafka的brokers列表来替换\<ENDPOINT>，比如`kafka1.example.com:2021,kafka2.example.com:2021`

参考[ Kafka Service for Bucket Notifications](https://min.io/docs/minio/linux/reference/minio-server/settings/notifications/kafka.html#minio-server-envvar-bucket-notification-kafka)获取完整的每个环境变量用途的说明

### 配置设置
使用`mc admin config set`命令与`notify_kafka`配置key来配置Kafka，必须重启minio来应用修改后的配置。下面是完整的例子
```shell
mc admin config set ALIAS/ notify_kafka:IDENTIFIER \
   brokers="<ENDPOINT>" \
   topic="<string>" \
   sasl_username="<string>" \
   sasl_password="<string>" \
   sasl_mechanism="<string>" \
   tls_client_auth="<string>" \
   tls="<string>" \
   tls_skip_verify="<string>" \
   client_tls_cert="<string>" \
   client_tls_key="<string>" \
   version="<string>" \
   queue_dir="<string>" \
   queue_limit="<string>" \
   comment="<string>"
```
`IDENTIFIER`的规则与环境变量的类似，都是一样的作用，包括`ENDPOINT`。

## Restart the MinIO Server
必须重启MinIO来应用配置变更，使用命令如下:
```shell
mc admin service restart ALIAS
```
minio server将会在启动日志中打印配置的kafka信息，比如`SQS ARNs: arn:minio:sqs::primary:kafka`。当配置bucket通知时必须指定ARN。在前面配置Kafka时，你通过`IDENTIFIER`指定了ARN，下面的步骤返回ARN
- `mc admin info --json ALIAS`: 获取JSON化的服务信息
- 寻找`info.sqsARN`的key，在其中寻找key为`IDENTIFIER`的值，这个值就是ARN
## 配置bucket通知
使用`mc event add`命令
```shell
mc event add ALIAS/BUCKET arn:minio:sqs::primary:kafka \
  --event EVENTS
```
其中大写的占位符需要替换，`EVENTS`是事件的逗号分隔列表，具体的[事件](https://min.io/docs/minio/linux/reference/minio-mc/mc-event-add.html#mc-event-supported-events)参考
```shell
mc event ls ALIAS/BUCKET arn:minio:sqs::primary:kafka
```
## 验证配置的事件

## 更新Kafka配置
下面的步骤更新Kafka配置