# 客户端
## 配置数据导入
Spring Boot 2.4 开始使用了一种新的方式加载配置数据，这是通过spring.config.import实现的，这是目前默认的从config server获取配置数据的方式，在application.properties中可选的连接config server的设置如下
>spring.config.import=optional:configserver:

y因为没有配置config server的地址，所以默认连接http://localhost:8888，不使用optional前缀，如果没有；连接上config server则会启动失败，为了改变默认的地址，可以设置spring.cloud.config.uri或者spring.config.import=optional:configserver:http://myhost:8888，这个配置的优先级比uri的方式高，通过import方式加载配置数据的方法不需要bootstrap文件。
## 配置Bootstrap
为了使用传统的bootstrap的方式连接到config server，需要添加spring-cloud-starter-bootstrap包或者设置属性spring.cloud.bootstrap.enabled=true，这个属性必须被设置为系统属性或者环境变量，bootstrap启用后，任何classpath里面有Config Client的应用按照下面操作连接到Config Server
- 当config client启动时，它连接config server（spring.cloud.config.uri，这是一个boostrap属性）;
- 使用远程的属性源初始化Environment；

这带来的结果就是所有的使用远程配置中心的应用都需要一个bootstrap.yml文件，并且里面要有spring.cloud.config.uri属性，配置远程配置中心的地址。
