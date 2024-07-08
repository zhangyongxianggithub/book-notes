MinIO Client简称为mc
通常来说，`mc`的版本使用MinIO Server的后一个版本比较好，偏离太多或者使用之前的版本可能不兼容。
## 快速开始
- 安装mc,不同的环境不一样，自己安装就好
- 为一个S3存储服务设置别名，使用`mc alias set`命令添加s3服务到mc配置中`mc alias set ALIAS HOSTNAME ACCESS_KEY SECRET_KEY`。