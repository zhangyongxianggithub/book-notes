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
为Kafka Cluster设置安全机制，安全连接可以保证数据加密、认证与授权等。怎么设置安全连接
## Kafka安全选项
在Kafka资源对象中定义安全机制。
### Listener authentication
集群内访问可以使用plain/tls机制的listener，外部访问需要指定连接机制，在这些连接机制的基础上你可以指定连接的认证机制：
   - TLS认证
   - SCRAM-SHA-512认证
   - OAuth 2.0认证
   - 自定义认证
Listener的authentication属性指定认证机制。如果没有指定authentication，则listener不会认证任何客户端，listener会不加认证的接受所有的连接。当使用User Operator来管理KafkaUsers必须配置Authentication，下面是一个例子:
```yaml
# ...
listeners:
  - name: plain
    port: 9092
    type: internal
    tls: true
    authentication:
      type: scram-sha-512
  - name: tls
    port: 9093
    type: internal
    tls: true
    authentication:
      type: tls
  - name: external
    port: 9094
    type: loadbalancer
    tls: true
    authentication:
      type: tls
# ...
```
1. Mutual TLS authentication
  Mutual TLS authentication总是用于Kafka broker与Zookeeper pod之间的通信。Strimzi 可以将 Kafka 配置为使用 TLS（传输层安全性）在 Kafka 代理和客户端之间提供加密通信，无论是否有相互身份验证。 对于相互或双向身份验证，服务器和客户端都提供证书。 配置相互身份验证时，代理对客户端进行身份验证（客户端身份验证），客户端对代理进行身份验证（服务器身份验证）。TLS 身份验证更常见的是单向身份验证，即一方验证另一方的身份。 例如，当 Web 浏览器和 Web 服务器之间使用 HTTPS 时，浏览器将获得 Web 服务器的身份证明。
2. SCRAM-SHA-512 authentication
  SCRAM（Salted Challenge Response Authentication Mechanism）是一种可以使用密码建立相互认证的认证协议。Strimzi可以将Kafka配置为使用SASL（简单身份验证和安全层）SCRAM-SHA-512为未加密和加密的客户端连接提供身份验证。当 SCRAM-SHA-512 身份验证与 TLS 客户端连接一起使用时，TLS 协议提供加密，但不用于身份验证。SCRAM 的以下属性使得即使在未加密的连接上也可以安全地使用 SCRAM-SHA-512：
  - 密码不会通过通信通道以明文形式发送。取而代之的是，客户端和服务器各自受到对方的质询，要求对方提供证据证明他们知道进行身份验证的用户的密码。
  - 服务器和客户端分别为每个身份验证交换生成一个新的质询。这意味着交易所可以抵御重放攻击。
  当 KafkaUser.spec.authentication.type 配置为 scram-sha-512 时，User Operator 将生成一个随机的 12 字符密码，由大写和小写 ASCII 字母和数字组成
3. Network policies
   默认情况下，Strimzi会自动为Kafka broker上启用的每个listener创建NetworkPolicy资源。 此NetworkPolicy允许应用程序连接到所有名称空间中的listener。使用网络策略作为listener配置的一部分。如果要将对listener的网络级别的访问限制为仅选定的应用程序或名称空间，请使用networkPolicyPeers属性。每个listener都可以有不同的[networkPolicyPeers](https://strimzi.io/docs/operators/latest/configuring.html#configuration-listener-network-policy-reference)配置。有关网络策略对等点的更多信息，请参阅[NetworkPolicyPeer API 参考](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#networkpolicypeer-v1-networking-k8s-io)。如果要使用自定义网络策略，可以在Cluster Operator配置中将STRIMZI_NETWORK_POLICY_GENERATION环境变量设置为false。有关更多信息，请参阅[Cluster Operator配置](https://strimzi.io/docs/operators/latest/configuring.html#ref-operator-cluster-str)。
4. 额外的listener配置选项
   你可以使用[GenericKafkaListenerConfiguration schema](https://strimzi.io/docs/operators/latest/configuring.html#type-GenericKafkaListenerConfiguration-reference)的属性添加listener的更多的配置。
### Kafka Authorization
## Kafka客户端的安全选项
使用KafkaUser资源配置Kafka客户端的认证机制、授权机制以及访问权限，根据安全配置，用户代表客户端。你可以认证/授权用户访问Kafka brokers，认证允许访问，授权限制访问。你也可以创建不受限制的超级用户。
### 标识Kafka机群
一个KafkaUser资源包含一个标签，标签定义了Kafka机群的名字，也就是定义了KafkaUser属于哪个Kafka集群资源。
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: my-user
  labels:
    strimzi.io/cluster: my-cluster
```
标签会被User Operator使用来识别KafkaUser资源，创建用户以及后续的操作用户，如果标签不能匹配Kafka机群，那么User Operator不会KafkaUser，user也不会被创建。如果KafkaUser资源的状态是空的，请检查你的标签定义。
### User Authentication
用户认证使用KafkaUser.spec中的authentication属性指定，认证机制使用type字段描述，指定就会启用认证。支持的认证类型:
- tls
- tls-external使用外部证书的TLS客户端认证
- scram-sha-512认证
如果指定了tls或scram-sha-512，则User Operator会在创建用户时创建身份验证凭据。如果指定了tls-external，用户也使用TLS客户端身份验证，但不会创建任何身份验证凭据。当您提供自己的证书时使用此选项。如果未指定身份验证类型，则User Operator不会创建用户或其凭据。tls-external可以用于User Operator外部颁发的证书通过TLS客户端身份验证进行身份验证。User Operator不生成TLS证书或密钥。您仍然可以通过User Operator以与使用tls机制时相同的方式管理ACL规则和配额。 这意味着您在指定ACL规则和配额时使用CN=USER-NAME格式。USER-NAME是TLS证书中给出的通用名称。
1. tls客户端认证
为了使用TLS认证机制，你需要设置type=tls，一个例子如下:
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: my-user
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: tls
  # ...
```
当User Operator创建用户时，它会创建与KafkaUser同名的新的secret，secret包含一个private/public密钥，用于TLS客户端认证，公钥包含在用户证书中，由护短的CA认证中心签名。如果你正在使用由Cluster Operator生成的客户端CA，当客户端CA被Cluster Operator更新时，用户证书也会被User Operator更新。所有的key都是X.509格式的，Secrets提供PEM/PKCS#12格式的私钥与证书。一个例子如下:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-user
  labels:
    strimzi.io/kind: KafkaUser
    strimzi.io/cluster: my-cluster
type: Opaque
data:
  ca.crt: # Public key of the client CA
  user.crt: # User certificate that contains the public key of the user
  user.key: # Private key of the user
  user.p12: # PKCS #12 archive file for storing certificates and keys
  user.password: # Password for protecting the PKCS #12 archive file
```
2. TLS client authentication using a certificate issued outside the User Operator
   如果不用User Operator生成的证书认证，你可以设置type=tls=external，不会生成secret与凭证。例子如下:
   ```yaml
   apiVersion: kafka.strimzi.io/v1beta2
    kind: KafkaUser
  metadata:
  name: my-user
  labels:
    strimzi.io/cluster: my-cluster
  spec:
  authentication:
    type: tls-external
  # ...
   ```
3. SCRAM-SHA-512认证
   ```yaml
   apiVersion: kafka.strimzi.io/v1beta2
  kind: KafkaUser
  metadata:
    name: my-user
    labels:
      strimzi.io/cluster: my-cluster
  spec:
    authentication:
      type: scram-sha-512
    # ...
   ```

## 对Kafka Brokers的安全访问
为了建立对Kafka broker的安全访问，你需要配置:
- Kafka机群资源
  - 创建指定特定认证类型的listener;
  - w为整个Kafka机群配置授权;
- 用于通过listener安全访问Kafka brokers的KafkaUser资源。
配置Kafka资源需要设置:
- Listener认证
- 访问listener的网络策略
- Kafka授权
- 用于不受限制的访问broker的超级用户
每个listener可以独立配置认证，授权是为整个Kafka机群配置的。Cluster Operator创建listener，设置证书开启认证。你可以替换Cluster Operator创建的证书，具体参考[installing your own certificates](https://strimzi.io/docs/operators/latest/using.html#installing-your-own-ca-certificates-str)，你可以识别[外部的认证中心管理的证书](https://strimzi.io/docs/operators/latest/using.html#kafka-listener-certificates-str)，证书支持PKCS#12与PEM格式，KafkaUser开启认证授权机制，客户端使用这个机制访问Kafka，配置KafkaUser需要设置:
- 认证;
- 授权;
- 资源限额。
User Operator基于认证类型创建代表客户端的用户与客户端认证需要使用的安全凭证。
### Securing Kafka brokers
客户端设置的安全配置要与kafka broker的安全配置兼容，也就是:
- Kafka.spec.kafka.listeners[*].authentication兼容KafkaUser.spec.authentication;
- Kafka.spec.kafka.authorization兼容KafkaUser.spec.authorization.
过程如下:
- 配置listener的authorization属性，比如:
  ```yaml
  apiVersion: kafka.strimzi.io/v1beta2
  kind: Kafka
  spec:
  kafka:
    # ...
    authorization: (1)
      type: simple
      superUsers: (2)
        - CN=client_1
        - user_2
        - CN=client_3
    listeners:
      - name: tls
        port: 9093
        type: internal
        tls: true
        authentication:
          type: tls (3)
    # ...
  zookeeper:
    # ...
  ```
  (1) [enables simple authorization on the Kafka broker using the AclAuthorizer Kafka plugin](https://strimzi.io/docs/operators/latest/configuring.html#con-securing-kafka-authorization-str)
  (2) 可以无限制访问 Kafka 的用户主体列表。 CN 是使用 TLS 身份验证时来自客户端证书的通用名称。
  (3) 指定listener的认证机制。
- 创建并更新Kafka资源
### Securing user access to Kafka
创建或者修改一个KafkaUser来表示一个客户端，确保认证/授权信息与Kafka的一致。下面是一个例子
- 创建KafkaUser资源
  ```yaml
  apiVersion: kafka.strimzi.io/v1beta2
  kind: KafkaUser
  metadata:
    name: my-user
    labels:
      strimzi.io/cluster: my-cluster
  spec:
    authentication: (1)
      type: tls
    authorization:
      type: simple (2)
      acls:
        - resource:
            type: topic
            name: my-topic
            patternType: literal
          operations:
            - Describe
            - Read
        - resource:
            type: group
            name: my-group
            patternType: literal
          operations:
            - Read
  ```
- 创建/更新KafkaUser

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
