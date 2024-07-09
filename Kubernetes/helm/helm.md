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
- helm show values: 查看chart的可配置选项`helm show values bitnami/wordpress`,`helm install -f（--values） values.yaml bitnami/wordpress --generate-name`覆盖默认的配置项，也可以使用--set的命令行方式（会被保存到configmap中），优先级更高。`helm upgrade --reset-values`清楚set设置的值`--set name=value``--set outer.inner=value``--set name={a, b, c}``--set name=[],a=null``--set servers[0].port=80``--set servers[0].port=80,servers[0].host=example``--set name=value1\,value2`特殊字符需要转义。`--set nodeSelector."kubernetes\.io/role"=master`嵌套的层级尽可能少，因为set使用不方便。helm install支持的安装方式
  - chart包
  - chart目录
  - chart仓库
  - chart url地址
- helm upgrade: 升级版本，修改release配置，`helm upgrade -f panda.yaml happy-panda bitnami/wordpress`,只会执行自上次以来发生变更的内容，`helm get values happy-panda`查看values内容，`helm get`是一个查看Release非常有帮助的命令。
- helm rollback: `helm rollback [RELEASE] [REVISION]`回滚之前的版本，`helm history [RELEASE]`查看历史版本号
- helm uninstall: `helm uninstall happy-panda`，删除Release的所有记录，`helm uninstall --keep-history`保留历史记录，`helm list --uninstalled`会列出保留历史记录的Release。
- helm list: 列出所有的Release
- helm repo: `helm repo list`,`helm repo update`
- helm create deis-workflow: 快速创建chart
- helm lint: 验证格式
- helm package deis-workflow: 打包
- 

一些安装、升级、回滚时重要的命令参数:
- --timeout, 等待k8s命令执行的超时时间
- --wait，表示必须要等到所有的Pods都处于ready状态
