SCK实现了Spring Cloud接口，允许开发者在K8S上构建运行Spring Cloud应用。当你想构建云原生应用时这个项目很有帮助，当然部署Spring Boot应用到k8s上不是必须这个组件，如果您正要开始学习如何在Kubernetes上运行Spring Boot应用程序，那么您只需一个基本的Spring Boot应用程序和Kubernetes本身就可以完成很多工作。要了解更多信息，您可以阅读有关Spring Boot参考文档中有关部署K8S的部分以及学习研讨会材料。特性:
- k8s感知;
- DiscoveryClient实现;
- 通过ConfigMaps配置的PropertySource对象;
- 通过Netflix Ribbon实现的客户端负载均衡;
最简单首要的步骤是包含Spring Cloud BOM，然后将`spring-cloud-starter-kubernetes-all`添加到应用程序的类路径中。如果您不想包含所有`Spring Cloud Kubernetes`功能，您可以为您想要的功能添加单独的starter。默认情况下，Spring Cloud Kubernetes将在检测到它在Kubernetes集群中运行时自动启用kubernetes配置文件。所以您可以创建一个K8s应用的属性配置这些属性只会应用到K8s环境。 一旦启动器在类路径上，应用程序应该像任何其他Spring Cloud应用程序一样运行。
# DiscoveryClient for Kubernetes
这个项目提供了K8s的Discovery Client实现，这个客户端可以让你根据名字查询Kubernetes的endpoints（也就是services）。一个service通常是由k8s API server暴露的端点集合，这些端点表示的是http或者https的地址，当Spring Boot作为一个Pod运行时，可以通过客户端访问这些地址。可以添加下面的依赖，你会免费获得这些能力:
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-discoveryclient</artifactId>
</dependency>
```
`spring-cloud-starter-kubernetes-discoveryclient`被设计为与`Spring Cloud Kubernetes DiscoveryServer`一起使用```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-fabric8</artifactId>
</dependency>
```
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client</artifactId>
</dependency>
```

为了可以加载`DiscoveryClient`，需要添加注解`@EnableDiscoveryClient`，如下:
```java
@SpringBootApplication
@EnableDiscoveryClient
public class Application {
  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
}
```
你可以注入客户端，如下代码所示:
```java
@Autowired
private DiscoveryClient discoveryClient;
```
你可以通过在application.properties文件中设置下面的属性，开启所有命名空间的服务发现:
```proeprties
spring.cloud.kubernetes.discovery.all-namespaces=true
```
为了发现还没有被标记为ready的service endpoint，可以设置如下属性:
```properties
spring.cloud.kubernetes.discovery.include-not-ready-addresses=true
```
如果你的服务暴露了多个端口，你可能需要指定`DiscoveryClient`使用的端口号，端口号选择的逻辑如下:
- 如果server有一个primary-port-name标签，`DiscoveryClient`会使用标签指定的端口号;
- 如果没有标签，则使用属性`spring.cloud.kubernetes.discovery.primary-port-name`指定的名字;
- 如果上面都没指定，则使用命名为https的端口;
- 如果上面都没指定，则使用命名为http的端口;
- 如果上面都没，则使用端口列表的第一个端口。
最后一个选项可能会导致不确定的行为。确保合理地配置您的服务或应用程序。
