一个可靠的分布式远程配置中心。携程开发的，集中化管理应用不同环境，不通集群的配置。具备实时推送功能，权限管控等特定。服务端用Spring Cloud开发。特性
- 统一管理不同环境、不通集群的配置
  - 提供WebUI管理不同的environment、cluster、namespace的配置
  - 支持应用具有不通的配置
  - 通过命名空间支持应用共享配置，可以对共享配置覆盖
- 配置修改实时生效
- 版本发布管理，恶意方便回滚
- 支持灰度发布
- 配置项搜索
- 权限管理、发布审核、操作审计
- 客户端配置信息监控
- 提供java/.net的客户端，支持Spring占位符、注解与Spring Boot的`ConfigurationProperties`的方式使用，需要Spring 3.1.1+
- 提供API
- 部署简单外部依赖少，只依赖MySQL

# 系统设计
下面是基础模型
- 用户在配置中心对配置进行修改并发布
- 配置中心通知Apollo客户端有配置中心
- Apollo客户端从配置中心拉取最新的配置，更新本地配置并通知到应用

![Apollo基础模型](pic/basic-architecture.png)
下图是Apollo架构模块的设计
![Apollo架构](pic/overall-architecture.png)
- Config Service提供配置的读取、推送等功能，服务对象是Apollo客户端
  ![Config Service](pic/config-service.png)
- Admin Service提供配置的修改、发布等功能，服务对象是Apollo Portal（管理界面）
  ![Admin Service](pic/admin-service.png)
- Config Service和Admin Service都是多实例、无状态部署，所以需要将自己注册到Eureka中并保持心跳
- 在Eureka之上我们架了一层Meta Server用于封装Eureka的服务发现接口
  ![Meta Server](pic/meta-server.png)
- Client通过域名访问Meta Server获取Config Service服务列表（IP+Port），而后直接通过IP+Port访问服务，同时在Client侧会做load balance、错误重试
  ![Client访问流程](pic/client-meta-config.png)
- Portal通过域名访问Meta Server获取Admin Service服务列表（IP+Port），而后直接通过IP+Port访问服务，同时在Portal侧会做load balance、错误重试
  ![Portal访问流程](pic/port-meta-admin.png)
- 为了简化部署，我们实际上会把Config Service、Eureka和Meta Server三个逻辑角色部署在同一个JVM进程中
  ![jvm](pic/config-eureka-meta.png)

为什么用eureka作为注册中心?
- 功能完整，netflix出的
- 方便集成Spring Cloud与Spring Boot，可以与其他服务集成在一个容器中启动
- 开源
## Config Service
- 提供配置获取接口
- 提供配置更新推送接口(Http long polling)
  - 服务端使用[Spring DeferedResult](http://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/web/context/request/async/DeferredResult.html)实现异步化，大大增加长连接的数量
  - 默认10000连接，4c8g可以支持10000个连接，也就是支持10000个进程或者应用
- 接口服务对象为Apollo客户端
![Config Service的设计](pic/config-service-design.png)
## Admin Service
- 提供配置管理接口
- 提供配置修改、发布、检索等接口
- 接口服务对象为Portal
## Meta Server
- Portal通过域名访问Meta Server获取Admin Service服务列表
- Client通过域名访问Meta Server获取Config Service服务列表
- Meta Server从Eureka获取Config Service和Admin Service的服务信息，相当于是一个Eureka Client
- 增设一个Meta Server的角色主要是为了封装服务发现的细节，对Portal和Client而言，永远通过一个Http接口获取Admin Service和Config Service的服务信息，而不需要关心背后实际的服务注册和发现组件
- Meta Server只是一个逻辑角色，在部署时和Config Service是在一个JVM进程中的，所以IP、端口和Config Service一致
## Eureka
- 基于Eureka和Spring Cloud Netflix提供服务注册和发现
- Config Service和Admin Service会向Eureka注册服务，并保持心跳
- 为了简单起见，目前Eureka在部署时和Config Service是在一个JVM进程中的（通过Spring Cloud Netflix）
## Portal
- 提供Web界面供用户管理配置
- 通过Meta Server获取Admin Service服务列表（IP+Port），通过IP+Port访问服务
- 在Portal侧做load balance、错误重试
## Client
- Apollo提供的客户端程序，为应用提供配置获取、实时更新等功能
- 通过Meta Server获取Config Service服务列表（IP+Port），通过IP+Port访问服务
- 在Client侧做load balance、错误重试
## E-R图
![ER图](./pic/apollo-erd.png)
- APP: App信息
- AppNamespace: App下的Namespace的元信息
- Cluster: 集群信息
- Namespace: 集群下的namespace
- Item: Namepace的配置，每个item都是key,value组合
- Release: Namespace发布的配置，每个发布包含发布时该Namespace的所有配置
- Commit: Namespace下的配置更改记录
- Audit: 审计信息，记录用户在何时使用何种方式操作了哪个实体
### 权限相关的ER图
![权限相关的E-R图](./pic/apollo-erd-role-permission.png)
- User: Apollo portal用户
- UserRole: 用户与角色的关系
- Role: 角色
- RolePermission: 角色和权限的关系
- Permission: 权限，具体的实体资源和操作
- Consumer: 第三方应用
- Consumer: 第三方应用的token
- ConsumerRole: 第三方应用和角色的关系
- ConsumerAudit: 第三方应用访问审计
## 服务端设计
### 配置发布后的实时推送设计
配置发布后实时推送到客户端的设计与实现
![配置变更实时推送设计](./pic/release-message-notification-design.png)
- 用户在Portal操作配置发布
- Portal调用Admin Service的接口操作发布
- Admin Service发布配置后，发送`ReleaseMessage`给各个Config Service
- Config Service收到`ReleaseMessage`后，通知对应的客户端

Admin Service通知Config Service配置变更，为了避免引入消息队列的额外依赖，使用数据库实现了简单的消息队列
- Admin Service在配置发布后会往ReleaseMessage表插入一条消息记录，消息内容就是配置发布的AppId+Cluster+Namespace，参见[DatabaseMessageSender](https://github.com/apolloconfig/apollo/blob/master/apollo-biz/src/main/java/com/ctrip/framework/apollo/biz/message/DatabaseMessageSender.java)
- Config Service有一个线程会每秒扫描一次ReleaseMessage表，看看是否有新的消息记录，参见[ReleaseMessageScanner](https://github.com/apolloconfig/apollo/blob/master/apollo-biz/src/main/java/com/ctrip/framework/apollo/biz/message/ReleaseMessageScanner.java)
- Config Service如果发现有新的消息记录，那么就会通知到所有的消息监听器[ReleaseMessageListener](https://github.com/apolloconfig/apollo/blob/master/apollo-biz/src/main/java/com/ctrip/framework/apollo/biz/message/ReleaseMessageListener.java)，如[NotificationControllerV2](https://github.com/apolloconfig/apollo/blob/master/apollo-configservice/src/main/java/com/ctrip/framework/apollo/configservice/controller/NotificationControllerV2.java)，消息监听器的注册过程参见[ConfigServiceAutoConfiguration](https://github.com/apolloconfig/apollo/blob/master/apollo-configservice/src/main/java/com/ctrip/framework/apollo/configservice/ConfigServiceAutoConfiguration.java)
- NotificationControllerV2得到配置发布的AppId+Cluster+Namespace后，会通知对应的客户端，实现方式如下:
  - 客户端会发起一个Http请求到Config Service的notifications/v2接口，也就是NotificationControllerV2，参见RemoteConfigLongPollService
  - NotificationControllerV2不会立即返回结果，而是通过Spring DeferredResult把请求挂起
  - 如果在60秒内没有该客户端关心的配置发布，那么会返回Http状态码304给客户端
如果有该客户端关心的配置发布，NotificationControllerV2会调用DeferredResult的setResult方法，传入有配置变化的namespace信息，同时该请求会立即返回。客户端从返回的结果中获取到配置变化的namespace后，会立即请求Config Service获取该namespace的最新配置。
## 客户端设计
![客户端设计](./pic/client-architecture.png)
- 客户端和服务端保持了一个长连接，第一时间获取配置更新的推送，通过Http Long Polling实现
- 客户端定时从配置中心拉取应用的最新配置
  - fallback机制，防止推送机制失效导致配置不更新
  - 拉取时会上报本地的版本，与服务端版本一致则返回304-Not Modified
  - 定时频率为5分钟一次，也可以通过在运行时制定系统属性`apollo.refreshInterval`来覆盖，单位为分钟
- 客户端从Apollo配置中心服务端获取到应用的最新配置后，会保存在内存中
- 客户端会把从服务端获取到的配置在本地文件系统缓存一份
  - 在遇到服务不可用或者网络不通的时候，依然能从本队恢复配置
- 应用程序可以从Apollo客户端获取最新的配置、订阅配置更新通知
### 和Spring集成的原理
Apollo除了支持API方式获取配置，也支持和Spring/Spring Boot集成。集成原理简述如下:
Spring从3.1版本开始增加了`ConfigurableEnvironment`和`PropertySource`:
- Spring的`ApplicationContext`会包含一个`Environment`(实现`ConfigurableEnvironment`接口)，`ConfigurableEnvironment`自身包含了很多个`PropertySource`
- `PropertySource`: 属性源，多个key-value的属性配置

运行时的结构如下图:


































