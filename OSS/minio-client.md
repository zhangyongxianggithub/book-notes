MinIO Client简称为mc，类似UNIX环境的命令`ls`、`cat`、`cp`、`mirror`与`diff`等，支持文件系统与兼容S3协议的云存储服务。`mc`命令兼容AWS S3 API，在MinIO与AWS S3上都经过了测试并符合预期的行为。`mc`可能不兼容其他的S3服务实现，虽然你可以使用，但是使用的风险你需要自己承担。 语法形式: `mc [GLOBALFLAGS] COMMAND --help`.
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
|mc mb|创建新的bucket或者创建目录|
|mc mirror|将其他源的内容同步到minio，类似`rsync`命令，自持的源包括文件系统、minio或者其他S3服务|
|mc mv|移动一个对象，在minio之间或者在不同的bucket之间，也支持在文件系统与minio之间|
|mc od|拷贝文件到远程的某个位置，分为指定大小的块，返回上传的时间|
|mc ping|执行活跃检查|
|mc pipe|将STDIN的输入流输入到一个对象|
|mc put|上传对象|
|mc quota clear</br>mc quota info</br>mc quota set|配置、显示、移除一个bucket的额度限制|
|mc rb|移除bucket如果只删除bucket中的内容，使用`mc rm`|
|mc ready|检查集群的状态|
|mc replicate add</br>mc replicate backlog</br>mc replicate export</br>mc replicate import</br>mc replicate ls</br>mc replicate resync</br>mc replicate rm</br>mc replicate status</br>mc replicate update|配置管理服务端的Bucket复制|
|mc retention clear</br>mc retention info</br>mc retention set|为bucket中的对象配置Write-Once与Read Many锁设置，你可以为bucket设置默认的对象锁设置，没有明确指定对象锁设置的对象都继承bucket的默认设置|
|mc rm|从bucket中移除对象|
|mc share download</br>mc share ls</br>mc share upload|管理上传与下载对象的带签名URL|
|mc sql|提供一个S3 Select接口，执行SQL查询|
|mc stat|显示bucket中的对象信息，包含对西藏元数据信息|
|mc support callhome</br>mc support diag</br>mc support inspect</br>mc support perf</br>mc support profile</br>mc support proxy</br>mc support top api</br>mc support top disk</br>mc support top locks</br>mc support upload|一些工具，分析部署的健康度、性能等|
|mc tag list</br>mc tag remove</br>mc tag set|添加、移除、列出跟一个bucket或者对象关联的tags|
|mc tree|按照树的形式列出bucket的所有对象|
|mc undo|撤销指定文件前面做的PUT/DELETE操作|
|mc update|自动更新mc命令|
|mc version enable</br>mc version info</br>mc version suspend|启用、禁用、检索bucket的版本信息|
|mc watch|观察指定bucket或者本地文件系统路径上的事件，对于S3服务来说，使用mc event add来配置bucket的事件通知|
|mc idp ldap accesskey</br>mc idp ldap add</br>mc idp ldap disable</br>mc idp ldap enable</br>mc idp ldap info</br>mc idp ldap ls</br>mc idp ldap policy</br>mc idp ldap rm</br>mc idp ldap update|allow you to manage configurations to 3rd party Active Directory or LDAP Identity and Access Management (IAM) integrations.|
|mc idp openid add</br>mc idp openid disable</br>mc idp openid enable</br>mc idp openid info</br>mc idp openid ls</br>mc idp openid rm</br>mc idp openid update| allow you to manage configurations to 3rd party OpenID Identity and Access Management (IAM) integrations.|
|mc idp ldap policy attach</br>mc idp ldap policy detach</br>mc idp ldap policy entities|展示策略与相关用户或者用户组的映射关系|
|mc ilm restore</br>mc ilm rule add</br>mc ilm rule edit</br>mc ilm rule export</br>mc ilm rule import</br>mc ilm rule ls</br>mc ilm rule rm</br>mc ilm tier add</br>mc ilm tier check</br>mc ilm tier info</br>mc ilm tier ls</br>mc ilm tier rm</br>mc ilm tier update|管理对象的生命周期管理规则|
|mc legalhold clear</br>mc legalhold info</br>mc legalhold set|设置、移除与检索对象的legal hold设置|
|mc license info</br>mc license register</br>mc license update|使用命令来注册部署、取消注册部署、显示有关集群当前许可证的信息或更新集群的许可证密钥|

## 配置文件
mc使用JSON格式的配置文件，存储了一些配置信息，比如S3服务的别名映射信息。对于*nix类的操作系统。路径是`~/.mc/config.json`
## Certificates
mc把证书存储在下面的路径中
```
~/.mc/certs/ # certificates
~/.mc/certs/CAs/ # Certificate Authorities
```
## Pattern Matching
一些命令或者标志支持模式匹配，当开启后，模式可以包含下面的通配符
- **\***: 标识符一串字符，只能在中间或者末尾
- **?**: 标识一个字符
## Global Options
所有的命令都支持下面的全局选项，你也可以使用哲学选项的环境变量形式
- --debug: 开始详细输出，环境变量`MC_DEBUG`
- --config-dir: JSON配置文件的路径，环境变量形式`MC_CONFIG_DIR`
- --disable-pager --dp: 禁止分页
- --json: 开始json格式输出，环境变量`MC_JSON`
- --no-color: 禁用内置的彩色主题
- --quiet: 禁用输出
- --insecure: 禁用TLS/SSL认证
- --version: mc版本
- --help: 

# mc admin
`mc admin`用于管理MinIO服务，不能管别的，语法`mc admin [FLAGS] COMMAND [ARGUMENTS]`, 简要命令参考
|**Command**|**Description**|
|:---|:---|
|mc admin bucket remote|`mc admin bucket remote`命令管理ARN资源|
通常来说，`mc`的版本使用MinIO Server的后一个版本比较好，偏离太多或者使用之前的版本可能不兼容。