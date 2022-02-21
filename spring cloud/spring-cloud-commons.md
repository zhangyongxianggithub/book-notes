Cloud Native(云原生)是一种应用程序开发风格，它鼓励在应用的持续交付与价值驱动方面采用简单的最佳实践。需要做的就是构建12-因素应用程序，具有2-因素的应用程序开发过程中始终与交付目标保持一致。比如，通过使用声明式编程、管理、监控的方式开发。Spring Cloud通过很多手段增强了这种开发风格；一个分布式系统中的所有组件的入门都必须是简单易用的。这些特性大部分都是Spring Boot实现的，这是Spring Cloud的基石。一些分布式相关的特性由Spring Cloud发布为2个lib：Spring Cloud Context与Spring Cloud Commons。Spring Cloud Context提供了一些实用工具以及与Spring Cloud应用的ApplicationContext（bootstrap context，encryption、refresh scope、environment endpoints）相关的一些特殊服务；Spring Cloud Commons包含了很多的抽象类定义，这些定义通常是Spring Cloud所有组件（比如Spring Cloud Netflix，Spring Cloud Consul）都会用到并且实现的类。
如果你正在使用Sun’s JDK并且出现了一个由“Illegal key size”造成的异常，你需要安装Java Cryptography Extension（JCE）Unlimited Strength Jurisdiction Policy Files. 将文件解压到/JDK/jre/lib/security目录下。Spring Cloud 在非限制性 Apache 2.0 许可下发布。 如果您想对文档的这一部分做出贡献或发现错误，您可以在 {docslink}[github] 上找到该项目的源代码和问题跟踪器。
# 1. Spring Cloud Context: Application Context Services
Spring Boot 对如何使用 Spring 构建应用程序有自己的看法。 例如，它由自己常规的公共配置文件的位置，也具有自己的用于管理与监控的端点。 Spring Cloud 建立在此之上，并添加了分布式系统中许多组件会使用或偶尔需要的一些功能。
## the Bootstrap Application Context
Spring Cloud应用通过创建一个bootstrap上下文开始运行，它是main应用的父上下文；这个上下文负责还在外部来源的配置属性与本地外部配置文件中的属性（解码）。bootstrap上下文与main应用上下文，共享一个Environment，encironment对任意的Spring应用来说是外部属性的来源，默认情况下，bootstrap属性（不是bootstrap.properties属性，是在bootstrap阶段加载的所有属性）具有更高的加载优先级，所以他们不能被本地配置覆盖。bootstrap上下文使用一个特定的约定来定位外部配置地址，不是典型的application.yml，而是bootstrap.yml，这让用于boostrap与main上下文的外部配置区分开，下面的列表是一个例子
```yml
spring:
  application:
    name: foo
  cloud:
    config:
      uri: ${SPRING_CONFIG_URI:http://localhost:8888}
```
如果你的应用需要来自于远程服务器的应用心啊过关的外部配置，你需要再bootstrap.yml或者applicaiton.yml中设置spring.application.name属性，当spring.application.name属性被用来做应用上下文的ID时，你必须在bootstrap.yml中设置它。如果你想检索特定的profile的配置，你也应在你boostrap.yml中设置spring.profiles.active属性。你可以通过设置spring.cloud.bootstrap.enabled=false（比如系统属性）关闭boostrap处理过程。
## Application Context体系结构
如果你使用SpringApplication 或者 SpringApplicationBuilder 构建应用程序上下文，则Bootstrap 上下文会以parent的身份被添加到当前应用的上下文中。 Spring 的一个特性是子上下文会从其父上下文继承属性源和profiles，因此应用上下文，相比于没有使用Spring Cloud Config创建的上下文相比，包含一些额外的属性源，这些额外的属性源是：
- bootstrap，如果boostrap上下文中发现了任意的PropertySourceLocators对象，或者上下文中包含非空的属性，一个CompositePropertySource对象会以较高的优先级出现在当前应用的main上下文中，常见的情况下是来自于远程Spring Cloud Config Server的属性，可以看[Customizing the Bootstrap Property Sources](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/index.html#customizing-bootstrap-property-sources)章节来定制化这种属性源的内容。
- applicationConfig:[classpath:bootstrap.yml] 或者任何激活的profile相关的文件，如果你有一个bootstrap.yml或者.properties文件，文件里面的属性会被用来配置bootstrap上下文，然后当parent被设置，他们就会被添加到child的上下文中，他们比application.yml的优先级低。

因为属性源的排序规则的原因，bootstrap属性具有更高的优先级，然而，这并不包括任何来自于bootstrap.yml中的任何的数据，它们的优先级更低，可以被用来设置默认值。你可以