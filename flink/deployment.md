Flink是一种通用型的框架，支持多种部署场景。在下面，我们简短的解释了Flink集群的构建、目标以及可用的构建方案。如果你只想要在本地启动Flink，我们建议你构建一个Standalone Cluster.
# 概览
## 概览与参考架构
下面的图展示了Flink集群的架构，存在一个运行的client，它负责把Flink应用的代码转换成一个JobGraph并提交到JobManager。JobManager将JobGraph中的算子任务分发到TaskManagers，TaskManager是算子(比如source、information、sink)运行的地方。当部署Flink时，每一个组件有一些可用的选项，我们在表格中列出.
![building block](pic/deployment_overview.svg)
|Component|Purpose|Implementations|
|:---|:---|:---|
|Flink Client|将Flink应用编译为dataflow graph，后者会被提交到JobManager| <ul> <li>[Command Line Interface](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/cli/)</li><li>[REST Endpoint](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/ops/rest_api/)</li><li>[SQL c
lient](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/dev/table/sqlclient/)</li><li>[Python PEPL](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/repls/python_shell/)</li></ul>|
|JobManager|JobManager是Flink中的中央调度组件的名字，不同的资源提供者有不同的实现，这些实现在高可用、资源分配行为、支持的任务提交类型等方面都是不同的，任务提交的JobManager类型如下: <br><ul><li>**Application Mode**: 为每一个Flink应用创建一个单独的集群，Job的main方法在JobManager上执行，在一个应用中多次调用`execute/executeAsync`是支持的</li><li>**Session Mode**: 一个JobManager实例管理多个Job，这些Job都在一个集群上运行，并共享集群的TaskManagers</li><li>**Per-Job Mode**: 每一个Job对应一个集群，Job的main方法在集群创建前执行</li></ul>|<ul><li>[Standalone](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/resource-providers/standalone/)，这是标准模式，需要启动一个JVM进程，这种部署方式下可以人工设置部署的设置</li><li>[Kubernetes](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/resource-providers/native_kubernetes/)</li><li>[YARN](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/resource-providers/yarn/)</li></ul>|
|TaskManager|TaskManager是真正执行Flink任务的服务||
|*High Availability Service Provider*|Flink的JobManager可以以高可用的模式运行，并允许Flink从JobManager失败中恢复，为了更快的进行故障切换，可以启动多个备用的JobManager作为备份|<ul><li>[Zookeeper](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/ha/zookeeper_ha/)</li><li>[Kubernetes HA](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/ha/kubernetes_ha/)</li></ul>|
|*File Storage and Persistency*|对于检查点，Flink依赖外部存储系统|看[FileSystems](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/filesystems/overview/)|
|*Resource Provider*|Flink可以通过不同的资源提供者框架部署，比如Kubernetes或者YARN|可以看上面的[JobManager实现](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/overview/#jmimpls)|
|*Metrics Storage*|Flink组件报告内部指标，Flink Job也会报告额外的Job相关的指标|可以看[Metrics Reporter](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/metric_reporters/)|
|Application-level data sources and sinks|虽然应用程序级别的数据源和汇在技术上不是Flink集群组件部署的一部分，但在规划新的Flink生产部署时应该考虑它们。使用Flink托管常用数据可以带来显着的性能优势|可以看连接器相关的章节|

### 可重复使用资源的清理
一旦作业达到完成、失败或取消这样的全局终止状态，与作业关联的外部组件资源就会被清理。如果清理资源失败，Flink将尝试重试理。您可以配置使用的重试策略。达到最大重试次数但未成功将使作业处于脏状态。它的资源需要手动清理（有关更多详细信息，请参阅高可用性服务/JobResultStore部分）。重新启动同一个作业（即使用相同的作业ID）将导致清理重新启动，而无需再次运行该作业。目前清理`CompletedCheckpoints`时存在一个问题，这些问题在将它们包含在通常的 CompletedCheckpoint 管理中时未能被删除。 这些工件没有被可重复的清理所覆盖，即它们仍然必须手动删除。
## 部署模式
Flink可以用以下3种方式执行应用:
- Application Mode
- Per-Job Mode
- Session Mode
上面的模式的不同在于:
- 集群的生命生命周期与资源隔离程度是不同的;
- application的main方法在客户端执行还是在集群执行;
![deployment modes](pic/deployment_modes.svg)
1. Application Mode
   所有其他模式应用程序的main()方法都在客户端执行。这个过程包括下载应用程序的依赖项到本地，执行main()以提取Flink运行时可以理解的应用程序表示（即JobGraph）并将依赖项和JobGraph(s)发送到集群。这使得客户端需要较多的资源，比如它可能需要大量的网络带宽来下载依赖项并将二进制文件发送到集群，还需要执行main()的CPU周期。当多个用户使用同一个客户端时，这个问题会更加明显。基于此观察，*Application Mode*为每个提交的应用程序创建一个集群，但这一次，应用程序的main()方法在 JobManager上执行。为每个应用程序创建一个集群可以看作是创建一个会话集群，它只在特定应用程序的作业之间共享，并在应用程序完成时删除。使用这种架构，*Application Mode*提供与Per-Job模式相同的资源隔离和负载平衡保证，但是是在整个应用程序的粒度上。在JobManager上执行main()可以节省所需的CPU周期，还可以节省本地下载依赖项所需的带宽。此外，它允许更均匀地分散网络负载以下载集群中应用程序的依赖项，因为每个应用程序都有一个JobManager。在*Application Mode*中，main()是在集群上执行的，而不是在客户端上执行的，就像在其他模式中一样。这可能会对您的代码产生影响，例如，您使用 registerCachedFile()在环境中注册的任何路径都必须可由应用程序的JobManager访问。与Per-Job模式相比，*Application Mode*允许提交由多个作业组成的应用程序。作业执行的顺序不受部署模式的影响，但受启动作业的调用影响。使用阻塞的 execute()建立一个顺序，这将导致“下一个”作业的执行被推迟到“这个”作业完成。使用非阻塞的 executeAsync() 将导致“下一个”作业在“此”作业完成之前开始。*Application Mode*允许multi-execute()应用程序，但在这些情况下不支持高可用性。只有single-execute()应用程序支持应用程序模式下的高可用性。此外，当应用程序模式下多个正在运行的作业（例如使用 executeAsync() 提交）中的任何一个被取消时，所有作业都将停止并且JobManager将关闭。支持定期完成作业（通过关闭源）。
2. Per-Job Mode
   为了提供更好的资源隔离保证，Per-Job模式使用可用的资源提供者框架（例如YARN、Kubernetes）为每个提交的作业启动一个集群。该集群仅适用于该作业。作业完成后，集群将被拆除并清除任何挥之不去的资源（文件等）。这提供了更好的资源隔离，因为行为不端的作业只能关闭它自己的 TaskManager。此外，它将簿记的负载分散到多个 JobManager 上，因为每个作业都有一个。 由于这些原因，Per-Job 资源分配模型是许多生产原因的首选模式。
3. Session Mode
   会话模式假定一个已经在运行的集群并使用该集群的资源来执行任何提交的应用程序。 在同一（会话）集群中执行的应用程序竞争使用相同的资源。这样做的好处是您不必每个作业都启动一个完整的集群，这样的资源消耗太大了。但是，如果其中一个作业行为异常或关闭了TaskManager，那么在该TaskManager上运行的所有作业都将受到故障的影响。除了对导致故障的作业产生负面影响外，这意味着潜在的大规模恢复过程，所有重新启动的作业同时访问文件系统并使其对其他服务不可用。此外，让一个集群运行多个作业意味着JobManager的负载更大，JobManager负责记录集群中的所有作业。
4. Summary
   在*Session Mode*下，集群生命周期独立于集群上运行的任何作业的生命周期，并且资源在所有作业之间共享。Per-Job模式需要为每个提交的作业启动一个集群，但这提供了更好的隔离保证，因为资源不会在作业之间共享。在这种情况下，集群的生命周期与作业的生命周期绑定。最后，应用程序模式为每个应用程序创建一个会话集群，并在集群上执行应用程序的main()方法。
# Resource Providers
## Native Kubernetes
下面的章节描述如何部署原生的Flink到K8s上。
### Getting Started
#### Introduction
K8s是一个流行的容器编排系统，用于自动部署应用、扩缩容与应用管理。Flink原生部署可以让你直接部署Flink集群到k8s上，更多的，Flink on K8s可以动态的分配/回收TaskManager，因为它可以与K8s直接通信。
#### Preparation
要求:
- K8s>=1.9
- kubectl有操作对象的权限;
- 开启了k8s DNS;
- 带有创建/删除pods的RBAC权限的`default` service account。
#### Starting a Flink Session on K8s
一旦你的Kubernetes集群运行并且kubectl被配置为指向它，你可以以`Session Mode`启动一个Flink集群
```bash
# (1) Start Kubernetes session
$ ./bin/kubernetes-session.sh -Dkubernetes.cluster-id=my-first-flink-cluster

# (2) Submit example job
$ ./bin/flink run \
    --target kubernetes-session \
    -Dkubernetes.cluster-id=my-first-flink-cluster \
    ./examples/streaming/TopSpeedWindowing.jar

# (3) Stop Kubernetes session by deleting cluster deployment
$ kubectl delete deployment/my-first-flink-cluster
```
默认情况下，Flink的Web UI和REST端点暴露为ClusterIP类型的service。如需访问该service，请参阅访问Flink的Web UI获取说明。
### Deployment Modes
对与生产上的使用，我们建议以*Application Mode*的方式部署，因为这样的模式提供了更好的隔离性。
#### Application Mode
*Application Mode*模式需要用户的代码打包成Flink镜像，因为是代码执行是在镜像基础上的，*Application Mode*模式保证Flink组件在应用终止后可以得到合适的清理。Flink社区提供了基础Docker镜像，可以用来生成用户Flink应用镜像:
```Dockerfile
FROM flink
RUN mkdir -p $FLINK_HOME/usrlib
COPY /path/of/my-flink-job.jar $FLINK_HOME/usrlib/my-flink-job.jar
```
创建/发布镜像后，你可以用下面的命令开启一个应用集群:
```java
$ ./bin/flink run-application \
    --target kubernetes-application \
    -Dkubernetes.cluster-id=my-first-application-cluster \
    -Dkubernetes.container.image=custom-image-name \
    local:///opt/flink/usrlib/my-flink-job.jar
```
local是*Application Mode*模式下为转移支持的模式。
`kubernetes.cluster-id`选项指定集群的名字，必须是唯一的，如果你没有指定，那么Flink会自动生成一个随机的名字。`kubernetes.container.image`指定了pod使用的镜像。部署成功后，你可以查看：
```bash
# List running job on the cluster
$ ./bin/flink list --target kubernetes-application -Dkubernetes.cluster-id=my-first-application-cluster
# Cancel running job
$ ./bin/flink cancel --target kubernetes-application -Dkubernetes.cluster-id=my-first-application-cluster <jobId>
```
你可以通过设置bin/flink的执行参数来覆盖conf/flink-conf.yaml中的设置，比如-Dkey=value。
#### Per-Job Cluster Mode
Flink on K8s不支持这种方式
#### Session Mode
在本小节的开头，你已经看到如何以*Session Mode*的模式部署。这种方式可以以2种形式执行:
- detached modo(default): `kubenetes-session.sh`部署Flink集群到k8s上然后返回;
- attached mode(-Dexecution.attached=true): `kubenetes-session.sh`保持活跃状态允许输入命令来控制运行的Flink集群，比如，停止集群等操作。
为了重新链接上运行中的Flink集群，你可以使用cluster-id，如下:
```bash
$./bin/kubernetes-session.sh \
    -Dkubernetes.cluster-id=my-first-flink-cluster \
    -Dexecution.attached=true
```
为了停止Flink集群，你可以删除K8s上Flink集群对应的deployment或者执行下面的命令:
```bash
$ echo 'stop' | ./bin/kubernetes-session.sh \
    -Dkubernetes.cluster-id=my-first-flink-cluster \
    -Dexecution.attached=true
```
### Flink on k8s参考
1. Configuring Flink on Kubernetes
   kubernetes相关的配置选项列在[configuration page](https://nightlies.apache.org/flink/flink-docs-release-1.16/zh/docs/deployment/config/#kubernetes)Flink使用Fabric8 Kubernetes客户端与Kubernetes APIServer通信来创建/删除Kubernetes资源（例如 Deployment、Pod、ConfigMap、Service等），以及观察Pod和ConfigMap。除了上述Flink配置选项外，Fabric8 Kubernetes客户端的一些专门选项可以通过系统属性或环境变量进行配置。例如，用户可以使用以下Flink配置选项来设置并发最大请求数。
   ```properties
   containerized.master.env.KUBERNETES_MAX_CONCURRENT_REQUESTS: 200
   env.java.opts.jobmanager: "-Dkubernetes.max.concurrent.requests=200"
   ```
2. Accessing Flink's Web UI
   Flink的Web UI和REST端点可以通过`kubernetes.rest-service.exposed.type`配置选项以多种方式公开。
   - ClusterIP: 在集群内部IP上公开service。该服务只能在集群内访问。如果要访问JobManager UI或将作业提交到现有会话，则需要启动本地代理。然后，您可以使用localhost:8081将Flink 作业提交到会话或查看仪表板;
    ```bash
    kubectl port-forward service/<ServiceName> 8081
    ```
   - NodePort: 在每个节点IP的静态端口（NodePort）上公开服务。<NodeIP>:<NodePort>可用于访问JobManager服务;
   - LoadBalancer: 使用云提供商的负载均衡器向外部公开服务。由于云提供商和Kubernetes需要一些时间来准备负载均衡器，您可能会在客户端日志中获得一个NodePort JobManager Web界面。 您可以使用kubectl get services/<cluster-id>-rest 获取EXTERNAL-IP 并手动构建负载均衡器 JobManager Web 界面 http://<EXTERNAL-IP>:8081。
3. Logging
   Kubernetes集成将conf/log4j-console.properties和conf/logback-console.xml作为ConfigMap暴露给pod。对这些文件的更改将对新启动的集群可见。
   1. 访问日志
   默认情况下，JobManager和TaskManager会同时将日志输出到控制台和每个pod中的/opt/flink/log。STDOUT和STDERR输出只会被重定向到控制台。您可以通过以下方式访问它们`$ kubectl logs <pod名称>`如果pod正在运行，您还可以使用`kubectl exec -it <pod-name> -- bash`隧道进入并查看日志或调试进程;
   2. 访问TaskManagers的日志
   Flink会自动回收空闲的TaskManager，以免浪费资源。这种行为会使访问各个pod的日志变得更加困难。您可以通过配置 resourcemanager.taskmanager-timeout来增加空闲TaskManager释放的时间，以便您有更多时间检查日志文件。
   3. 动态更改日志级别
   如果您已将logger配置为自动检测配置更改，那么您可以通过更改相应的ConfigMap来动态调整日志级别（假设集群id为 my-first-flink-cluster）`$ kubectl edit cm flink-config-my-first-flink-cluster`
4. Using Plugins
   为了使用插件，您必须将它们复制到Flink JobManager/TaskManager pod中的正确位置。您可以使用内置插件，而无需安装卷或构建自定义Docker映像。例如，使用以下命令为您的Flink会话集群启用S3插件`$ ./bin/kubernetes-session.sh
    -Dcontainerized.master.env.ENABLE_BUILT_IN_PLUGINS=flink-s3-fs-hadoop-1.16.0.jar \
    -Dcontainerized.taskmanager.env.ENABLE_BUILT_IN_PLUGINS=flink-s3-fs-hadoop-1.16.0.jar`
5. Custom Docker Image
   如果你想使用自定义的Docker镜像，那么你可以通过配置选项`kubernetes.container.image`来指定它。Flink社区提供了丰富的Flink Docker镜像，可以作为一个很好的起点。了解如何自定义Flink的Docker镜像，了解如何启用插件、添加依赖项和其他选项;
6. Using Secrets
   Kubernetes Secrets是一个包含少量敏感数据的对象，例如密码、令牌或密钥。此类信息可能会以其他方式放入pod规范或镜像中。Flink on Kubernetes可以通过两种方式使用Secret：
   - 使用Secrets作为 pod 中的文件；
   - 使用Secrets作为环境变量；
   1. 将Secret用作Pod中的文件
   以下命令将在已启动的pod中的路径/path/to/secret下挂载秘密mysecret：`$ ./bin/kubernetes-session.sh -Dkubernetes.secrets=mysecret:/path/to/secret`然后可以在文件/path/to/secret/username和/path/to/secret/password中找到秘密mysecret的用户名和密码。有关更多详细信息，请参阅[Kubernetes官方文档](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod);
   2. 使用Secrets作为环境变量
   以下命令会将秘密mysecret公开为已启动pod中的环境变量：
   ```bash
    $./bin/kubernetes-session.sh -Dkubernetes.env.secretKeyRef=\
        env:SECRET_USERNAME,secret:mysecret,key:username;\
        env:SECRET_PASSWORD,secret:mysecret,key:password
   ```
   环境变量SECRET_USERNAME包含用户名，环境变量SECRET_PASSWORD包含秘密mysecret的密码。有关更多详细信息，请参阅 Kubernetes 官方文档。
7. High-Availability on Kubernetes
   对于Kubernetes上的高可用性，您可以使用现有的高可用性服务。将`kubernetes.jobmanager.replicas`的值配置为大于1以启动备用JobManager。这将有助于实现更快的恢复。请注意，启动备用JobManager时应启用高可用性。
8. Manual Resource Cleanup
   Flink使用[Kubernetes OwnerReference](https://kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/)清理所有集群组件。所有Flink创建的资源，包括ConfigMap、Service和Pod，都将 OwnerReference设置为deployment/<cluster-id>。当部署被删除时，所有相关资源将被自动删除`$ kubectl delete deployment/<cluster-id>`
9. Namespaces
   Kubernetes中的命名空间通过资源配额在多个用户之间划分集群资源。Flink on Kubernetes可以使用命名空间来启动Flink集群。命名空间可以通过kubernetes.namespace进行配置。
10. RBAC
    基于角色的访问控制是一种调节对资源访问权限的方法，这种方法是基于企业中用户的角色，用户可以给JobManager配置RBAC角色与service account来控制访问K8s的K8s API server。每一个命名空间都有一个default service account，然而，`default`service account没有权限创建/删除pods，用户需要更新`default` service account 的权限或者指定一个具有合适角色绑定的新的service account。`$ kubectl create clusterrolebinding flink-role-binding-default --clusterrole=edit --serviceaccount=default:default`，如果你不想要使用`default` service account，使用下面的命令来创建一个新的`flink-service-account` service account，并且设置角色绑定。然后使用配置选项`-Dkubernetes.service-account=flink-service-account`来让JobManager pod可以使用`flink-service-account`service account来创建/删除 TaskManager pods或者leader ConfigMaps，当然这也会允许TaskManager监视leader ConfigMaps来检索JobManager/ResourceManager的地址。
    ```bash
    $ kubectl create serviceaccount flink-service-account
    $ kubectl create clusterrolebinding flink-role-binding-flink --clusterrole=edit --serviceaccount=default:flink-service-account
    ```
    请参考官方文档中[RBAC授权](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)了解更多的信息。
11. Pod Template
    Flink允许用户通过template文件定义JobManager/TaskManager pod规范，这样可以支持一些Flink Kubernetes Config Options不直接支持的特性，使用kubernetes.pod-template-file指定一个包含pod定义的本地文件，它可以用来初始化JobManager/TaskManager，主要的容器的名字应该定义为`flink-main-container`，请参考