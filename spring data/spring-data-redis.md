[TOC]
Spring Data Redis项目整合了key-value模式的数据存储开发与Spring概念；我们提供了一个高度抽象的Template接口类，这个Template用于发送与接受消息；你可能注意到了，它与JDBC有点类似。
# Learning Spring
Spring Data使用了Spring框架的核心功能，包括：
- IOC容器
- 类型转换系统
- 表达式语言
- JMX整合
- DAO异常体系。
虽然您不需要了解 Spring API，但了解它们背后的概念很重要。 至少，控制反转 (IoC) 背后的想法应该很熟悉，并且您应该熟悉您选择使用的任何 IoC 容器。

Redis支持的核心功能可以直接使用，无需调用Spring Container的IoC服务。 这很像 JdbcTemplate，它可以“独立”使用，无需 Spring 容器的任何其他服务。 要利用 Spring Data Redis 的所有功能，例如存储库支持，您需要配置库的某些部分以使用 Spring。

要了解有关 Spring 的更多信息，您可以参考详细解释 Spring 框架的综合文档。 有很多关于这个主题的文章、博客条目和书籍。 有关更多信息，请参阅 Spring 框架主页。

一般来说，这应该是想要尝试 Spring Data Redis 的开发人员的起点。
# 学习NoSQL与key-value存储
NoSQL 存储席卷了存储世界。 这是一个广阔的领域，有大量的解决方案、术语和模式（更糟糕的是，甚至术语本身也有多种含义）。 虽然有些原则是通用的，但在一定程度上熟悉Spring Data Redis支持的底层存储是至关重要的。熟悉这些底层存储的最佳方法是阅读他们的文档并遵循他们的示例。完成它们通常不会超过五到十分钟，如果您来自仅 RDMBS 的背景，很多时候这些练习可能会让您大开眼界。
## 尝试例子
你可以在[https://github.com/spring-projects/spring-data-keyvalue-examples](https://github.com/spring-projects/spring-data-keyvalue-examples)这个专门的Spring Data示例存储库中找到键值存储的各种示例。 对于Spring Data Redis，您应该特别注意retwisj 示例，这是一个构建在 Redis 之上的 Twitter 克隆，可以在本地运行或部署到云中。 有关更多信息，请参阅其文档，以下博客条目。
# 要求
Spring Data Redis 2.x的使用需要JDK 8.0或者以上的版本，Spring Framework 5.3.10版本及以上。至于key-value存储，Redis需要2.6.x版本及以上，Spring Data Redis的功能当前是在Redis 4.0版本以上测试的。
# 额外的帮助资源
学习一个新框架并不总是那么简单。 在本节中，我们尝试提供我们认为易于遵循的 Spring Data Redis 模块入门指南。 但是，如果您遇到问题或需要建议，请随时使用以下链接之一：
- 社区论坛：Stack Overflow的Spring Data板块是一个所有的Spring Data用户共享信息与帮助解决问题的地方，提问前需要注册;
- 专业的支持：专业的，源码级别的支持，需要确保问题的响应时间的情况下，可以去Pivotal Sftware公司的官网请求帮助，这是Spring与Spring Data的开发者公司。
# 开发工作
更多的Spring Data源码仓库的信息，构建与快照版本发布，可以看Spring Data的github主页。您可以通过 spring-data 或 spring-data-redis 与 Stack Overflow 上的开发人员进行交互，帮助使 Spring Data 最好地满足 Spring 社区的需求。如果您遇到错误或想提出改进建议（包括本文档），请在 Github 上登录。要及时了解 Spring 生态系统中的最新消息和公告，请订阅 Spring 社区门户。
# 版本变更
# 依赖
由于各个Spring Data模块的发布日期是不同的，它们中的大多数带有不同的主要和次要版本号。找到兼容版本的最简单方法是依赖我们提供的 Spring Data Release Train BOM，这个里面会把兼容的版本定义在一起，在 Maven 项目中，您将在 POM 的 <dependencyManagement /> 部分声明此依赖项，如下所示：
```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.data</groupId>
      <artifactId>spring-data-bom</artifactId>
      <version>2021.0.5</version>
      <scope>import</scope>
      <type>pom</type>
    </dependency>
  </dependencies>
</dependencyManagement>
```
当前的集中发布的版本是2021.0.5，train版本使用格式为YYYY.MINOR.MICRO格式的版本号，版本名字是${calver}格式的发布版本是GA发布版本与service版本，下面格式的版本是其他版本：${calver}-${modifier}，在这里，modifier可以是下面的值
- SNAPSHOT：当前的快照版本;
- M1, M2：里程碑版本;
- RC1, RC2：候选发布版本;
你可以在Spring Data的例子仓库中找到使用这个BOM的例子，使用这种方式，你可以在<dependencies/>模块的声明中声明任何的你需要的Spring Data模块，并且可以不带版本号。