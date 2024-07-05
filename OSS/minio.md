用于存储AI数据的对象存储。高性能、兼容S3协议的对象存储。用于存储大规模的AI/ML训练数据、数据库与数据库数据。可以运行在任意的环境上。有2种协议版本，一个是GNU AGPL v3，一个是商业化的企业版本。
- 简单:
- 高性能
- 云原生
- 面向AI

MinIO是一个对象存储解决方案。兼容S3协议支持所有的核心S3特性。你可以通过MinIO Console或者[play](https://play.min.io)公共环境来练手。
# 快速开始
单节点、单驱动的MioIO服务器用于开发与验证。
```shell
# 安装minio软件包，如果之前通过brew install minio的方式安装过，需要卸载重装
brew install minio/stable/minio
```
```shell
export MINIO_CONFIG_ENV_FILE=/etc/default/minio
# 启动，默认数据读写目录是~/data，可以指定
minio server --console-address :9001
```
分别出现S3 API的地址与WebUI的地址。用浏览器打开可以做MinIO Server的管理。这个就是MinIO的控制台。
MioIO Client支持在命令行与MinIO Server交互。
```shell
brew install minio/stable/mc
```
```shell
# mc alias set可以连接到一个server
mc alias set local http://127.0.0.1:9000 minioadmin minioadmin
mc admin info local
```

