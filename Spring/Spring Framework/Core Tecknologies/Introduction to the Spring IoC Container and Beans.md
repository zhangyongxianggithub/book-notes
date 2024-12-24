欢迎来到Spring框架参考文档，可以阅读综述部分来大概了解下spring框架，综述部分包含了spring框架的历史、设计哲学以及碰到了问题应该去哪里反馈，还有一些开发spring应用的小诀窍；想要了解spring跟以前的版本有哪些不同，请移步github wiki。
参考文档被分成了以下几个部分：
1.Core：Ioc容器、事件、资源、i8n、验证、数据绑定、类型转换、Spring表达式、aop等内容；
2.Testing：Mock对象、测试框架、Spring MVC的测试方式、web测试客户端；
3.Data Access：事务、持久层支持、jdbc、对象关系映射、XML处理；
4.Web Servlet：Spring MVC、WebSocket、SockJS、STOMP消息；
5.Web Reactive：Spring WebFlux、WebClient、WebSocket；
6.Integration：远程调用、JMS、JCA、JMX、Email、Tasks、任务调度、缓存；
7.Languages：Kotlin、Groovy、动态语言。
第一部分Core
参考文档的这个部分包含了Spring Framework的核心技术点。最重要的技术就是Spring的IoC(Inversion of Control)，接下来是对AOP编程的全面的介绍。
1.1IoC容器
IoC，控制反转容器。
1.1.1Spring IoC容器与Beans概述
Spring IoC也叫做DI（dependency injection），用于管理Bean之间的依赖关系，这是一个过程，对象只通过构造函数参数、工厂方法的参数或者属性的方式定义依赖，其中属性的方式在创建完实例对象后，调用set方法设置。在Spring出现以前，对象自己直接调用构造函数控制自己的实例化并加入依赖的对象实例，但现在这个过程由容器控制，因此是反转的也就是IoC的概念，org.spring.framework.beans与org.spring.framework.context包是IoC容器的基础包；BeanFactory是IoC容器基本接口，提供了管理任意类型对象的高级配置机制，ApplicationContext是BeanFactory的子接口；相比于BeanFactory，它多了：
整合AOP特性；
Message资源处理（用于国际化）；
事件发布/订阅；
特定应用层上下文，比如用于web应用的WebApplicationContext。
BeanFactory提供了配置框架与容器的基本功能，ApplicationContext提供了更多的企业用到的功能，ApplicationContext是BeanFactory的超集，在本章中专门用于描述Spring IoC容器，有关使用BeanFactory而不是ApplicationContext的更多信息，请参阅BeanFactory API的章节。
Spring容器中的所有的对象都叫做Bean，一个bean就是由Spring IoC容器实例化、组装、管理的对象，这些Bean都通过Spring的配置元数据配置从而通过反射的方式生成。