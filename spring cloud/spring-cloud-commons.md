Cloud Native(云原生)是一种应用程序开发风格，它鼓励在应用的持续交付与价值驱动方面采用简单的最佳实践。需要做的就是构建12-因素应用程序，具有2-因素的应用程序开发过程中始终与交付目标保持一致。比如，通过使用声明式编程、管理、监控的方式开发。Spring Cloud通过很多手段增强了这种开发风格；一个分布式系统中的所有组件的入门都必须是简单易用的。这些特性大部分都是Spring Boot实现的，这是Spring Cloud的基石。一些分布式相关的特性由Spring Cloud发布为2个lib：Spring Cloud Context与Spring Cloud Commons。Spring Cloud Context提供了一些实用工具以及与Spring Cloud应用的ApplicationContext（bootstrap context，encryption、refresh scope、environment endpoints）相关的一些特殊服务；Spring Cloud Commons包含了很多的抽象类定义，这些定义通常是Spring Cloud所有组件（比如Spring Cloud Netflix，Spring Cloud Consul）都会用到并且实现的类。
如果你正在使用Sun’s JDK并且出现了一个由“Illegal key size”造成的异常，你需要安装Java Cryptography Extension（JCE）Unlimited Strength Jurisdiction Policy Files. 将文件解压到/JDK/jre/lib/security目录下。Spring Cloud 在非限制性 Apache 2.0 许可下发布。 如果您想对文档的这一部分做出贡献或发现错误，您可以在 {docslink}[github] 上找到该项目的源代码和问题跟踪器。
# 1. Spring Cloud Context: Application Context Services
Spring Boot 对如何使用 Spring 构建应用程序有自己的看法。 例如，它由自己常规的公共配置文件的位置，也具有自己的用于管理与监控任务的端点（end point）。 Spring Cloud 建立在此之上，并添加了分布式系统中许多组件会使用或偶尔需要的一些特性。
## the Bootstrap Application Context
Spring Cloud应用通过创建一个bootstrap上下文开始运行，它是main上下文的父上下文；这个上下文负责加载外部来源的配置属性与对本地外部配置文件中的属性解码。bootstrap上下文与main上下文共享同一个Environment，Environment对任意的Spring应用来说都是默认的外部属性的来源，默认情况下，bootstrap属性（不是指的bootstrap.properties属性，是在bootstrap阶段加载的所有属性）具有更高的加载优先级，所以他们不能被本地配置属性覆盖。bootstrap上下文使用一个特殊的约定方式来定位外部配置属性源地址，与main上下文加载外部配置属性源的方式是不同的。bootstrap上下文不使用典型的application.yml，而是bootstrap.yml，这让用于boostrap与main上下文的外部配置区分开，下面的列表是一个例子
```yml
spring:
  application:
    name: foo
  cloud:
    config:
      uri: ${SPRING_CONFIG_URI:http://localhost:8888}
```
如果你的应用需要加载来自于远程服务器的应用外部配置，你需要在bootstrap.yml或者applicaiton.yml中设置spring.application.name属性，当spring.application.name属性被用来做应用上下文的ID时，你必须在bootstrap.yml中设置它。如果你想加载应用的特定的profile的配置，你可能还需要在你boostrap.yml中设置spring.profiles.active属性。你可以通过设置spring.cloud.bootstrap.enabled=false（比如系统属性）完全关闭boostrap处理过程。
## Application Context体系结构
如果你使用SpringApplication 或者 SpringApplicationBuilder 构建应用程序上下文，则bootstrap 上下文会以parent的身份被添加到当前应用的上下文中。 Spring的一个特性是子上下文会继承父上下文的属性源与profiles，因此应用上下文与相比于没有使用Spring Cloud Config创建的上下文相比，会包含一些额外的属性源（继承的），这些额外的属性源有：
- bootstrap，如果boostrap上下文中发现了任意的PropertySourceLocators对象并且对象所表示的属性源的属性不是空的，那么一个CompositePropertySource对象会以较高的优先级出现在当前应用上下文中，常见的情况下是来自于远程Spring Cloud Config Server的属性，可以参考[Customizing the Bootstrap Property Sources](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/index.html#customizing-bootstrap-property-sources)章节来自定义这种属性源的内容。
- applicationConfig:[classpath:bootstrap.yml] 或者与任何激活的profile相关的文件，如果你有一个bootstrap.yml或者.properties文件，文件里面的属性会被用来配置bootstrap上下文，然后以parent的身份被添加到子上下文环境中，他们比application.yml的优先级低，也比其他被添加到子上下文的属性源属性的优先级低；可以参考[Changing the Location of Bootstrap Properties](https://docs.spring.io/spring-cloud-commons/docs/current/reference/html/#customizing-bootstrap-properties)来自定义这些属性源的内容。
因为属性源的排序规则的原因，含有bootstrap单词相关的属性体具有更高的优先级，然而，这并不包括任何来自于bootstrap.yml中的任何的数据，它们的优先级更低，可以被用来设置默认值。你可以扩展上下文的层次结构，只需要对你创建的ApplicationContext设置parent上下文，比如，通过使用ApplicationContext接口的方法或者使用SpringApplicationBuilder的方便的方法（parent()、child()、sibling()）。bootstrap上下文是大部分的上下文的parent。体系结构中的每个上下文都有他自己的bootstrap属性源to avoid promoting values inadvertently from parents down to their descendants。如果有一个配置服务器，体系结构中的上下文都可以有不同的spring.application.name，因而可以有不同的远程属性源。普通的Spring Application上下文属性解析规则如下：从子上下文中的属性会覆盖父上下文中出现的属性。
## 1.3 改变Bootstrap属性的位置

