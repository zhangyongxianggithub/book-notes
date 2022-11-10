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
spring.application.name对Kubernetes中为应用程序注册的名称没有影响，SCK也可以监听K8s service变更，并及时调整`DiscoveryClient`的实现，为了开启这个功能，你需要添加`@EnableScheduling`。
# K8s native service discovery
k8s本身就有服务发现的能力，使用native k8s服务发现要确保与额外的工具，比如Istio等兼容，Istio具有负载均衡、熔断、故障恢复等能力。调用者服务只需要引用特定k8s集群中可解析的名字，一种简单的实现方式是，使用RestTemplate，它使用完全限定域名，比如{service-name}.{namespace}.svc.{cluster}.local:{service-port}，另外，你可以使用Hystrix：
- 在调用者端，通过添加注解`@EnableCircuitBreaker`;
- 降级功能，在对应的方法上添加`@HystrixCommand`。
# K8s PropertySource实现
配置Spring Boot应用程序的最常见方法是创建application.properties或application.yaml或application-profile.properties或application-profile.yaml文件，其中包含为应用程序或者starter提供的自定义键值对。 您可以通过指定系统属性或环境变量来覆盖这些属性。
## Using a ConfigMap PropertySource
K8s提供了一种名字叫做ConfigMap的资源，用于将参数以键值对或嵌入式application.properties或application.yaml文件的形式传递给您的应用程序。Spring Cloud Kubernetes Config项目可以让应用程序在引导期间访问Kubernetes ConfigMap实例，并在观察到ConfigMap实例变更改时触发bean或Spring Context的热重载。添加依赖后默认会基于Kubernetes ConfigMap创建 Fabric8ConfigMapPropertySource，ConfigMap的metadata.name值为Spring应用程序的名称（由其spring.application.name 属性定义）或bootstrap.properties中定义的自定义名称`spring.cloud.kubernetes.config.name`。可以使用多个ConfigMap实例进行更高级的配置。`spring.cloud.kubernetes.config.sources`列表可以实现这个。例如，您可以定义以下ConfigMap实例：
```yaml
spring:
  application:
    name: cloud-k8s-app
  cloud:
    kubernetes:
      config:
        name: default-name
        namespace: default-namespace
        sources:
         # Spring Cloud Kubernetes looks up a ConfigMap named c1 in namespace default-namespace
         - name: c1
         # Spring Cloud Kubernetes looks up a ConfigMap named default-name in whatever namespace n2
         - namespace: n2
         # Spring Cloud Kubernetes looks up a ConfigMap named c3 in namespace n3
         - namespace: n3
           name: c3
```
在上面的例子中，如果`spring.cloud.kubernetes.config.namespace`没有设置，名字为c1的ConfigMap实例会从当前应用运行的命名空间中查找，关于命名空间解析的逻辑可以看后面的文档。发现的所有的ConfigMap的处理过程如下:
- 应用任何单独的配置属性;
- 应用名字叫application.yaml的文件中属性内容;
- 应用application.properties属性中的内容.
上述流程的唯一例外是ConfigMap包含一个表示文件是YAML或属性文件的键。在这种情况下，键的名称不必是application.yaml或application.properties（它可以是任何东西）并且属性的值被正确处理。
此功能有助于使用以下内容创建ConfigMap的用例:
```bash
kubectl create configmap game-config --from-file=/path/to/app-config.yaml
```
假设我们有一个名为 demo 的 Spring Boot 应用程序，它使用以下属性来读取其线程池配置。
>pool.size.core
pool.size.maximum

以yaml的形式外化到ConfigMap的格式如下:
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo
data:
  pool.size.core: 1
  pool.size.max: 16
```
大多数情况下，单个属性都可以正常工作。但是，有时嵌入式yaml更方便。在这种情况下，我们使用一个名为application.yaml的属性来嵌入我们的yaml，如下所示：
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo
data:
  application.yaml: |-
    pool:
      size:
        core: 1
        max:16
```
下面的例子也可以:
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo
data:
  custom-name.yaml: |-
    pool:
      size:
        core: 1
        max:16
```
您还可以根据不同的active profile来配置Spring Boot应用程序。当读取ConfigMap时，这些内容会合并到一起，
您可以使用application.properties或application.yaml属性为不同的Profile提供不同的属性值，
指定profile，每个值都在自己的文档中（由 --- 序列指示），如下所示:
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo
data:
  application.yml: |-
    greeting:
      message: Say Hello to the World
    farewell:
      message: Say Goodbye
    ---
    spring:
      profiles: development
    greeting:
      message: Say Hello to the Developers
    farewell:
      message: Say Goodbye to the Developers
    ---
    spring:
      profiles: production
    greeting:
      message: Say Hello to the Ops
```
在上面的例子中，使用development profile加载的配置文件如下:
```yaml
  greeting:
    message: Say Hello to the Developers
  farewell:
    message: Say Goodbye to the Developers
```
如果profile=production，那么加载的配置:
```yaml
  greeting:
    message: Say Hello to the Ops
  farewell:
    message: Say Goodbye
```
如果profile都指定了，那么ConfigMap中后面出现的属性会覆盖前面的属性。另一种选择是为每个Profile创建不同的ConfigMap，spring boot将根据Profile自动获取它。
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo
data:
  application.yml: |-
    greeting:
      message: Say Hello to the World
    farewell:
      message: Say Goodbye
```
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo-development
data:
  application.yml: |-
    spring:
      profiles: development
    greeting:
      message: Say Hello to the Developers
    farewell:
      message: Say Goodbye to the Developers
```
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: demo-production
data:
  application.yml: |-
    spring:
      profiles: production
    greeting:
      message: Say Hello to the Ops
    farewell:
      message: Say Goodbye
```
要告诉Spring Boot应该在启动时激活哪个profile，您可以传递SPRING_PROFILES_ACTIVE环境变量。
为此，您可以使用环境变量启动Spring Boot应用程序，您可以在容器规范的PodSpec中定义它。部署资源文件，如下：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-name
  labels:
    app: deployment-name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deployment-name
  template:
    metadata:
      labels:
        app: deployment-name
    spec:
        containers:
        - name: container-name
          image: your-image
          env:
          - name: SPRING_PROFILES_ACTIVE
            value: "development"
```
您可能会遇到多个ConfigMap具有相同属性名称的情况。例如：
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: config-map-one
data:
  application.yml: |-
    greeting:
      message: Say Hello from one
```
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: config-map-two
data:
  application.yml: |-
    greeting:
      message: Say Hello from two
```
根据您在bootstrap.yaml|properties中放置它们的顺序，您最终可能会得到意想不到的结果（最后一个配置映射获胜）。例如：
```yaml
spring:
  application:
    name: cloud-k8s-app
  cloud:
    kubernetes:
      config:
        namespace: default-namespace
        sources:
         - name: config-map-two
         - name: config-map-one
```
将导致属性`greetings.message=Say Hello from one`。有一种方法可以通过指定`useNameAsPrefix`来更改此默认配置。例如：
```yaml
spring:
  application:
    name: with-prefix
  cloud:
    kubernetes:
      config:
        useNameAsPrefix: true
        namespace: default-namespace
        sources:
          - name: config-map-one
            useNameAsPrefix: false
          - name: config-map-two
```
这会导致2个同名属性的区别如下:
- greetings.message = Say Hello from one;
- config-map-two.greetings.message = Say Hello from two;
注意`spring.cloud.kubernetes.config.useNameAsPrefix`的优先级低于`spring.cloud.kubernetes.config.sources.useNameAsPrefix`。
这允许您为所有源设置默认策略，同时允许覆盖少数源。
如果属性中不想出现ConfigMap的名字，您可以指定属性名字的策略，使用配置`explicitPrefix`。
由于这是您选择的显式前缀，因此它只能提供给源级别。同时它具有比useNameAsPrefix更高的优先级。
假设我们有第三个ConfigMap，其中包含这些条目:
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: config-map-three
data:
  application.yml: |-
    greeting:
      message: Say Hello from three
```
```yaml
spring:
  application:
    name: with-prefix
  cloud:
    kubernetes:
      config:
        useNameAsPrefix: true
        namespace: default-namespace
        sources:
          - name: config-map-one
            useNameAsPrefix: false
          - name: config-map-two
            explicitPrefix: two
          - name: config-map-three
```
会导致生成的属性如下:
- greetings.message = Say Hello from one.
- two.greetings.message = Say Hello from two.
- config-map-three.greetings.message = Say Hello from three
  
