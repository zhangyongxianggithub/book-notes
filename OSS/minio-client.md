MinIO Client简称为mc
通常来说，`mc`的版本使用MinIO Server的后一个版本比较好，偏离太多或者使用之前的版本可能不兼容。
## 快速开始
- 安装mc,不同的环境不一样，自己安装就好
- 为一个S3存储服务设置别名，使用`mc alias set`命令添加s3服务到mc配置中`mc alias set ALIAS HOSTNAME ACCESS_KEY SECRET_KEY`。使用别名表示一个S3服务，`mc`命令通常都需要一个`ALIAS`来标识执行命令的S3服务
- 测试连接`mc admin info myminio`

## 命令参考
|Command|Description|
|:---|:---|
|mc alias list</br>mc alias remove</br>mc alias set</br>mc alias import</br>mc alias export|`mc alias`命令管理S3服务的|
|mc anonymous get</br>mc anonymous get-json</br>mc anonymous links</br>mc anonymous list</br>mc anonymous set</br>mc anonymous set-json|`mc anonymous`命令支持设置或者移除bucket的匿名策略，带有匿名策略的bucket允许公共访问，客户端可以不经过认证执行匿名策略授权的所有行为|
|mc batch describe</br>mc batch generate</br>mc batch list</br>mc batch start</br>mc batch status|`mc batch`命令允许运行一个或者多个MinIO上的job任务|
|`mc cat`|`mc cat`命令拼接一个或者多个文件的内容到另一个文件或者对象，你也可以使用这个命令显示文件的内容到STDOUT，与`cat`命令类似|
|mc cp|mc cp命令从/到一个MinIO服务拷贝对象|
|mc diff|计算2个文件系统目录或者2个bucket的差异，只会列出缺失的文件或者大小不同的文件，不会比较对象的内容|
|mc du|总结bucket或者目录的磁盘使用|
|mc encrypt clear</br>mc encrypt info</br>mc encrypt set|设置、更新或者禁用缺省的bucket服务端加密模式，MinIO自动使用指定的SSE模式加密对象|
|mc event add</br>mc event ls</br>mc event rm|添加、删除、列出bucket事件通知设置|
|mc find|搜索对象|
|mc get|下载文件到本地文件系统|
|mc head|显示对象的前`n`行|
|mc ls|列出bucket或者对象|