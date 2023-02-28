Helm是K8s的包管理器，也就是软件管理器。
前置条件:
- 一个K8s集群，本地有一个kubectl.
- k8s安全配置
- 安装和配置Helm
具体k8s与helm的[对应版本](https://helm.sh/zh/docs/topics/version_skew/)
安装好helm之后，添加一个chart仓库
```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo bitnami # 可以看到仓库的charts列表
helm repo update              # 确定我们可以拿到最新的charts列表
helm install bitnami/mysql --generate-name # 安装chart
helm show chart bitnami/mysql # 了解chart的基本信息
helm show chart bitnami/mysql #chart的所有信息
helm list # 查看发布的chart
helm uninstall mysql-1612624192 # 卸载发布该命令会从Kubernetes卸载 mysql-1612624192， 它将删除和该版本相关的所有相关资源（service、deployment、 pod等等）甚至版本历史。
helm uninstall mysql-1612624192 --keep-history # 会保存历史版本，可以回滚helm rollback
helm status mysql-1612624192  # 发布的信息
```
每当您执行helm install的时候，都会创建一个新的发布版本。 所以一个chart在同一个集群里面可以被安装多次，每一个都可以被独立的管理和升级。
# 3大概念
- Chart代表Helm包。它包含Kubernetes内应用程序、工具或服务所需的所有资源定义。类似homebrew、apt等;
- Repository存放与共享charts的地方，
- Release，运行在k8s集群中的chart实例，可以安装多次，每次安装都是一个release，Helm 安装charts到Kubernetes集群中，每次安装都会创建一个新的release。你可以在Helm的chart repositories中寻找新的chart。

# 基本命令
- helm search: 查找Charts
  - helm search hub，从Artifact Hub中查找并列 helm charts。 Artifact Hub中存放了大量不同的仓库，比如`helm search hub wordpress`
  - helm search repo, 从你添加（使用helm repo add）到本地helm客户端中的仓库中进行查找。该命令基于本地数据进行搜索，无需连接互联网。比如`helm repo add brigade https://brigadecore.github.io/charts`,`helm search repo brigade`.
- helm install: 安装一个helm包，比如`helm install happy-panda bitnami/wordpress`，前面是Release的名字，也可以自动生成名字会按照资源的一个 固定的顺序安装。这个看官网。
- helm status: `helm status happy-panda`
- helm show values: 查看chart的可配置选项`helm show values bitnami/wordpress`,`helm install -f values.yaml bitnami/wordpress --generate-name`覆盖默认的配置项
- 
  

