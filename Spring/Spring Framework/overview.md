Spring让创建Java企业应用更容易，提供了在企业环境中Java语言开发所需要的一切，也支持Groovy与Kotlin作为替代语言，可以依据应用的需要创建多种类型的架构，从Spring Framework 6.0开始，需要Java17+。Spring也支持很多应用场景。在大型企业中，应用通常已经存在很长时间，并且必须在JDK和应用服务器上运行，而这些服务器的升级周期不受开发人员的控制。其他应用可能通过单个jar运行，可能在云环境中运行。还有一些应用可能是不需要服务器的独立应用(例如批处理或集成工作负载）。Spring是开源的，有大量活跃的社区开发与修复问题，帮助了Spring的长远发展。
术语`Spring`在不同上下文中意味着不同的事物，可以表示Spring框架本身，随着发展，其他Spring项目也基于Spring框架构建出来，大多数情况下，当人们说Spring时，它表示的是所有的Spring项目，这个文档关注Spring框架本身。Spring框架分成多个模块，应用可以选择它们需要的模块，核心模块就是core container的几个模块，核心模块包括了配置模型与依赖注入机制，除此以外，Spring框架还为不同应用架构提供了支持，包括messaging、数据存储与事务与web。也包括基于Servlet的Spring MVC Web框架以及Spring WebFlux响应式Web框架。关于模块需要注意: Spring框架的jars允许发布为模块路径(Java的模块系统)，在模块应用中使用时，Spring框架定义了Automatic-Module-Name清单，清单定义了稳定的语言级别的模块名字(spring.core、spring.context等)，与jar包的artifact名字无关。jar包使用相同的命名模式，使用-而不是.做分割。比如spring-core与spring-context，Spring框架的jar在类路径上也是OK的。Spring在2003年发布，主要是解决早期的J2EE规范的复杂性问题。虽然有些人认为Java EE及其现代继任者Jakarta EE与Spring存在竞争，但实际上它们是互补的。Spring编程模型不包含Jakarta EE平台规范；相反，它与传统EE框架中精心挑选的单个规范集成：
- Servlet API(JSR 340)
- WebSocket API(JSR 356)
- Concurrency Utillities(JSR 236)
- JSON Binding API(JSR 367)
- Bean Validation(JSR 303)
- JPA(JSR 338)
- JMS(JSR 914)

Spring框架也支持依赖注入(JSR 330)与通用注解规范(JSR 250)，开发者可以使用这些规范也可以使用Spring框架提供的替代规范。最开始的javaee的规范都是`javax`包，现在是`jakarta`包。Spring Framework6.0版本开始，Spring支持升级到Jakarta EE 9 level(比如Servlet 5.0+、JPA3.0+)，基于`jarkarta`命名空间而不是传统的`javax`命名空间，















