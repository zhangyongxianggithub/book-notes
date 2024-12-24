Spring让创建Java企业应用更容易，提供了在企业环境中Java语言开发所需要的一切，也支持Groovy与Kotlin作为替代语言，可以依据应用的需要创建多种类型的架构，从Spring Framework 6.0开始，需要Java17+。Spring也支持很多应用场景。在大型企业中，应用通常已经存在很长时间，并且必须在JDK和应用服务器上运行，而这些服务器的升级周期不受开发人员的控制。其他应用可能通过单个jar运行，可能在云环境中运行。还有一些应用可能是不需要服务器的独立应用(例如批处理或集成工作负载）。Spring是开源的，有大量活跃的社区开发与修复问题，帮助了Spring的长远发展。
术语`Spring`在不同上下文中意味着不同的事物，可以表示Spring框架本身，随着发展，其他Spring项目也基于Spring框架构建出来，大多数情况下，当人们说Spring时，它表示的是所有的Spring项目，这个文档关注Spring框架本身。Spring框架分成多个模块，应用可以选择它们需要的模块，核心模块就是core container的几个模块，核心模块包括了配置模型与依赖注入机制，除此以外，Spring框架还为不同应用架构提供了支持，包括messaging、数据存储与事务与web。也包括基于Servlet的Spring MVC Web框架以及Spring WebFlux响应式Web框架。关于模块需要注意: Spring框架的jars允许发布为模块路径(Java的模块系统)，在模块应用中使用时，Spring框架定义了Automatic-Module-Name清单，清单定义了稳定的语言级别的模块名字(spring.core、spring.context等)，与jar包的artifact名字无关。jar包使用相同的命名模式，使用-而不是.做分割。比如spring-core与spring-context，Spring框架的jar在类路径上也是OK的。Spring在2003年发布，主要是解决早期的J2EE规范的复杂性问题。虽然有些人认为Java EE及其现代继任者Jakarta EE与Spring存在竞争，但实际上它们是互补的。Spring编程模型不包含Jakarta EE平台规范；相反，它与传统EE框架中精心挑选的单个规范集成：
- Servlet API(JSR 340)
- WebSocket API(JSR 356)
- Concurrency Utillities(JSR 236)
- JSON Binding API(JSR 367)
- Bean Validation(JSR 303)
- JPA(JSR 338)
- JMS(JSR 914)

Spring框架也支持依赖注入(JSR 330)与通用注解规范(JSR 250)，开发者可以使用这些规范也可以使用Spring框架提供的替代规范。最开始的javaee的规范都是`javax`包，现在是`jakarta`包。Spring Framework6.0版本开始，Spring支持升级到Jakarta EE 9 level(比如Servlet 5.0+、JPA3.0+)，基于`jarkarta`命名空间而不是传统的`javax`命名空间，Spring最低支持EE 9，并且已经支持EE 10，因此 Spring准备为Jakarta EE API的进一步发展提供开箱即用的支持。Spring Framework 6.0与Tomcat 10.1、Jetty 11和Undertow 2.3等Web服务器完全兼容，还与Hibernate ORM 6.1完全兼容。随着时间的推移，Java/Jakarta EE在应用开发中的作用已经发生了变化。在J2EE和Spring的早期，应用程序部署到应用服务器。如今，在Spring Boot的帮助下，应用程序以DevOps和云的方式创建，其中嵌入了Servlet容器，并且更改起来很简单。从Spring Framework 5开始，WebFlux应用甚至不直接使用Servlet API，并且可以在非Servlet服务器(如Netty)上运行。Spring继续创新和发展。除了Spring Framework之外，还有其他项目，例如Spring Boot、Spring Security、Spring Data、Spring Cloud、Spring Batch等。重要的是要记住，每个项目都有自己的源代码存储库、问题跟踪器和发布节奏。请参阅[spring.io/projects](https://spring.io/projects)以获取 Spring 项目的完整列表。
# 设计哲学
当你学习一个框架时，不仅要知道它能做什么，更重要的是要知道它遵循的原则。以下是Spring Framework的指导原则:
- 在每个层面提供很多选择，Spring让你尽可能推迟设计决策，比如你可以通过配置切换持久存储的提供者，不需要变更代码。这个设计对于其他的基础设置与第三方API的集成也是如此
- 包容不同的观点，Spring具有灵活性，不会强制定义应该如何做事，它支持从不同的角度出发来解决应用需求
- 保持强大的向后兼容性，Spring的演进经过精心管理，版本之间几乎没有重大变化，Spring支持一系列精心选择的JDK版本和第三方库，以方便维护依赖于Spring的应用程序和库
- 关注API设计。Spring团队投入了大量心思和时间来设计直观且可跨多个版本和多年使用的API
- 为代码质量设定高标准，Spring框架非常重视有意义、最新且准确的javadoc。它是极少数可以声称代码结构清晰且包之间没有循环依赖关系的项目之一
# Feedback and Contributions
对于操作方法问题、诊断或调试问题，我们建议使用Stack Overflow。[单击此处](https://stackoverflow.com/questions/tagged/spring+or+spring-mvc+or+spring-aop+or+spring-jdbc+or+spring-r2dbc+or+spring-transactions+or+spring-annotations+or+spring-jms+or+spring-el+or+spring-test+or+spring+or+spring-orm+or+spring-jmx+or+spring-cache+or+spring-webflux+or+spring-rsocket?tab=Newest)查看Stack Overflow上建议使用的标签列表。如果您非常确定Spring Framework中存在问题或想要建议某个功能，请使用[GitHub Issues](https://github.com/spring-projects/spring-framework/issues)。如果您有解决方案或建议的修复方法，您可以在Github上提交pr。但是，请记住，对于除最琐碎的问题之外的所有问题，我们都希望在问题跟踪器中提交工单，在那里进行讨论并留下记录以供将来参考。有关更多详细信息，请参阅CONTRIBUTING顶级项目页面中的指南。
# Getting Started
如果你是新手，最好先从创建Spring Boot应用开始，它可以快速的创建一个生产级别的Spring应用，你可以使用[start.spring.io](https://start.spring.io/)来创建一个简单项目，按照[Getting Started guides](https://spring.io/guides)中的[ Getting Started Building a RESTful Web Service](https://spring.io/guides/gs/rest-service/)步骤来创建一个应用，这些指南不仅容易理解，而且都是以任务为中心，大部分都是基于Spring Boot。它们还涵盖了Spring产品组合中的其他项目，您在解决特定问题时可能需要使用这些项目。

参考文档被分成了以下几个部分：
- **Core**：IoC容器、事件、资源、i18n、验证、数据绑定、类型转换、Spring表达式、aop等内容；
- **Testing**：Mock对象、测试框架、Spring MVC的测试方式、web测试客户端；
- **Data Access**：事务、持久层支持、jdbc、对象关系映射、XML处理；
- **Web Servlet**：Spring MVC、WebSocket、SockJS、STOMP消息；
- **Web Reactive**：Spring WebFlux、WebClient、WebSocket；
- **Integration**：远程调用、JMS、JCA、JMX、Email、Tasks、任务调度、缓存；
- **Languages**：Kotlin、Groovy、动态语言。















