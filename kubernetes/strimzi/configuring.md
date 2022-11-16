[TOC]
# 配置概览
## 配置自定义资源
## 使用ConfigMap添加配置
## 配置要连接到Kafka Broker使用的监听器
Listeners用来连接到Kafka brokers，Strimzi提供了一个通用的`GenericKafkaListener`用来配置Kafka资源的listeners。`GenericKafkaListener`提供了灵活的配置方式，你可以指定属性来配置内部访问(集群内连接)/外部访问(集群外连接)。listener以[数组](https://strimzi.io/docs/operators/0.31.1/configuring.html#proc-config-kafka-str)的形式配置，你可以配置任意数量的listener，只要他们的名字与端口是唯一的。例如，您可能想要配置多个external listeners来处理来自网络中需要不同认证机制的访问。或者您可能需要假如Kubernetes网络。在这种情况下，您可以配置internal listener（使用useServiceDnsDomain属性），以便不使用 KubernetesDNS服务（通常为 .cluster.local）。关于listeners可以使用的配置，可以参考[GenericKafkaListener schema reference](https://strimzi.io/docs/operators/0.31.1/using.html#type-GenericKafkaListener-reference)。
你可以配置listener使用安全连接更多的信息参考[Securing access to Kafka brokers](https://strimzi.io/docs/operators/0.31.1/configuring.html#assembly-securing-kafka-str)。你可以为外部访问设置extenal listener，需要指定特定的连接机制，比如loadbalancer，更多的配置请参考[Accessing Kafka from external clients outside of the Kubernetes cluster.](https://strimzi.io/docs/operators/0.31.1/configuring.html#assembly-accessing-kafka-outside-cluster-str)。
你可以提供自己的服务器证书，叫做*Kafka listener certificates*，可以在TLS listener或者开启了TLS加密的external listener中使用，更多的信息，参考[Kafka listener certificates](https://strimzi.io/docs/operators/0.31.1/configuring.html#kafka-listener-certificates-str)

## 文档约定
## 额外的资源
# Strimzi部署配置
## Kafka集群配置
## Kafka Connect集群配置
## Kafka MirrorMaker集群配置
## Kafka MirrorMaker 2.0集群配置
## Kafka Bridge集群配置
## 自定义Kubernetes资源
## 配置pod调度
## 日志配置
# 从外部源加载配置
## 从ConfigMap加载配置
## 从环境变量加载配置
# 向Strimzi pods/containers添加安全功能
## 如何配置安全上下文
## 开启Cluster Operator的严格模式
## 实现自定义Pod安全提供者
## 由K8s处理安全上下文
# 从k8s集群外部访问Kafka
使用external listener曝露你的Kafka集群到k8s外，需要指定`type`配置:
- nodeport, 使用NodePort类型的Service曝露;
- loadbalancer, 使用Loadbalancer类型的Service曝露;
- ingress，使用k8s的Ingress与 NGINX Ingress Controller for Kubernetes曝露;
- route，使用Openshift的Routes与HAProxy router曝露.
更多listener配置的信息，参考[ GenericKafkaListener schema reference](https://strimzi.io/docs/operators/0.31.1/configuring.html#type-GenericKafkaListener-reference)。如果你想知道每种连接类型的优势与劣势，请参考[Accessing Apache Kafka in Strimzi](https://strimzi.io/2019/04/17/accessing-kafka-part-1.html)
## 使用node端口访问Kafka
下面的过程描述了外部的客户端如何使用node port访问Kafka集群，为了连接到broker，你需要一个hostname/port来标识Kafka bootstrap地址，还有用于认证的证书。
- 设置Kafka资源的listener类型=nodeport
  ```yaml
    apiVersion: kafka.strimzi.io/v1beta2
    kind: Kafka
    spec:
    kafka:
        # ...
        listeners:
        - name: external
            port: 9094
            type: nodeport
            tls: true
            authentication:
            type: tls
            # ...
        # ...
    zookeeper:
        # ...
  ``` 
- 创建或者更新资源
  ```bash
  kubectl apply -f <kafka_configuration_file>
  ```
  每一个Kafka的broker都会创建一个NodePort类型的service还有一个外部的bootstrap service，bootstrap service将外部的访问路由到Kafka brokers，用于连接的Node地址会广播到Kafka自定义资源的状态中。用来验证kafka broker身份的的集群的CA证书也会在secret的**<cluster_name>-cluster-ca-cert**中创建;
- 在Kafka资源的status中检索出可以访问Kafka的boostrap地址
  ```bash
  kubectl get kafka <kafka_cluster_name> -o=jsonpath='{.status.listeners[?(@.name=="<listener_name>")].bootstrapServers}{"\n"}'
  ```
- 如果开启了TLS，extract the public certificate of the broker certification authority.
  ```bash
  kubectl get secret KAFKA-CLUSTER-NAME-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
  ```
  使用解析出来的证书放在你的Kafka客户端来配置TLS连接，如果你开启了任何的认证机制，你也需要配置SASL/TSL认证
## 使用loadbalancers访问Kafka
## 使用ingress访问Kafka
## 使用OpenShift访问Kafka
# 管理安全的Kafka访问
## Kafka安全选项
## Kafka客户端的安全选项
## 对Kafka Brokers的安全访问

## 使用基于token的OAuth 2.0认证
## 使用基于token的OAuth 2.0授权
# 使用Strimzi Operators
## Strimzi Operators监听命名空间
## 使用Cluster Operator
## 使用Topic Operator
## 使用User Operator
## 配置特性阀门
## 使用Prometheus监控Operators
# 集群平衡的平滑控制
## 为什么使用平滑控制
## 优化目标概览
## 优化建议概览
## 平衡性能调节概览
## 配置/发布Kafka的平滑控制
## 生成优化建议
## 评审优化建议
## 停止集群再平衡
## 使用KafkaRebalance解决问题
# 分布式追踪
## Strimzi如何支持追踪
## 过程大纲
## OpenTracing/Jaeger概览
## 设置Kafka客户端的追踪
## 使用tracers度量Kafka客户端
## 为MirrorMaker，Kafka Connect与Kafka Briidge设置追踪
# 管理TLS证书
## 证书权限
## Secrets
## 重新认证与校验周期
## TLS连接
## 配置外部客户端信任cluster CA
## Kafka listener认证
# 管理Strimzi
## 使用自定义资源
## 暂停自定义资源协调
## 使用Strimzi Drain Cleaner清除pods
## Kafka/Zookeeper的滚动更新
## 使用labels/annotations做服务发现
## 从PV恢复集群
## 使用Kafka Static Quota插件设置brokers的限制
## 一些频繁问的问题
# 调整Kafka配置
## 用于调整的工具
## 管理broker配置
## Kafka broker配置调整
## Kafka producer配置调整
## Kafka consumer配置调整
## 处理大量消息
# 自定义资源API参考
## 通用配置属性
## 模式属性
### GenericKafkaListener schema reference
在KafkaClusterSpec中使用，[Full list of GenericKafkaListener schema properties](https://strimzi.io/docs/operators/0.31.1/configuring.html#type-GenericKafkaListener-schema-reference)，配置listener，一个例子
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    #...
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
        authentication:
          type: tls
      - name: external1
        port: 9094
        type: route
        tls: true
      - name: external2
        port: 9095
        type: ingress
        tls: true
        authentication:
          type: tls
        configuration:
          bootstrap:
            host: bootstrap.myingress.com
          brokers:
          - broker: 0
            host: broker-0.myingress.com
          - broker: 1
            host: broker-1.myingress.com
          - broker: 2
            host: broker-2.myingress.com
    #...
```
- listeners: 一个listener的数组
  ```yaml
  listeners:
  - name: plain
    port: 9092
    type: internal
    tls: false
  ```
  name/port必须在Kafka集群中唯一，name最长25个小写数字字符构成，允许的端口号>9092, 但是不允许事9404/9999，这2个端口被prometheus/JMX用了
- type: 是internal、route、loadbalancer、nodeport或者ingress中的一个
  - internal，可以不需要加密
    ```yaml
    #...
    spec:
    kafka:
        #...
        listeners:
        #...
        - name: plain
          port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
        authentication:
          type: tls
    #...
    ```
  - route: 
  - ingress:
  - loadbalancer:
  - nodeport: 曝露Kafka为一个NodePort类型的Service，Kafka客户端直接连接node，会直接创建一个NodePort类型的Service作为kafka bootstrap address，当给Kafka broker pod配置了建议地址时，Strimzi会使用pod所在的node地址，你可以使用`preferredNodePortAddressType`属性类配置first address type checked as the node address。
  ```yaml
  #...
    spec:
  kafka:
    #...
    listeners:
      #...
      - name: external4
        port: 9095
        type: nodeport
        tls: false
        configuration:
          preferredNodePortAddressType: InternalDNS
    #...
  ```
  - port: 
