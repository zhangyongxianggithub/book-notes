SCK实现了Spring Cloud接口，允许开发者在K8S上构建运行Spring Cloud应用。当你想构建云原生应用时这个项目很有帮助，当然部署Spring Boot应用到k8s上不是必须这个组件，如果您正要开始学习如何在Kubernetes上运行Spring Boot应用程序，那么您只需一个基本的Spring Boot应用程序和Kubernetes本身就可以完成很多工作。要了解更多信息，您可以阅读有关Spring Boot参考文档中有关部署K8S的部分以及学习研讨会材料。特性:
- k8s感知;
- DiscoveryClient实现;
- 通过ConfigMaps配置的PropertySource对象;
- 通过Netflix Ribbon实现的客户端负载均衡;
最简单首要的步骤是包含Spring Cloud BOM，然后将`spring-cloud-starter-kubernetes-all`添加到应用程序的类路径中。如果您不想包含所有`Spring Cloud Kubernetes`功能，您可以为您想要的功能添加单独的starter。默认情况下，Spring Cloud Kubernetes将在检测到它在Kubernetes集群中运行时自动启用kubernetes配置文件。所以您可以创建一个K8s应用的属性配置这些属性只会应用到K8s环境。 一旦启动器在类路径上，应用程序应该像任何其他Spring Cloud应用程序一样运行。
