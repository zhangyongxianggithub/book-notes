主要是IoC原则的Spring实现，DI（dependency injection）是IoC的一种特殊的形式，在这种形式下对象定义了它们的依赖关系(就是需要共同工作的对象)，依赖关系只通过构造函数参数、工厂方法的参数或者属性的方式定义，其中属性的方式在创建完实例对象后，调用set方法设置。
在Spring出现以前，对象自己直接调用构造函数控制自己的实例化并加入依赖的对象实例，但现在IoC容器创建Bean时注入依赖，因此是反转的也就是IoC的概念。
`org.spring.framework.beans`与`org.spring.framework.context`包是IoC容器的基础包；
`BeanFactory`是IoC容器基本接口，提供了管理任意类型对象的高级配置机制，`ApplicationContext`是`BeanFactory`的子接口；相比于`BeanFactory`，它多了：
- 更容易整合AOP特性；
- Message资源处理（用于国际化）；
- 事件发布/订阅；
- 特定应用层上下文，比如用于web应用的`WebApplicationContext`

`BeanFactory`提供了配置框架与容器的基本功能，`ApplicationContext`提供了更多的企业用到的功能，`ApplicationContext`是`BeanFactory`的超集，
在本章中专门用于描述Spring IoC容器，有关使用`BeanFactory`而不是`ApplicationContext`的更多信息，请参阅[BeanFactory API](https://docs.spring.io/spring-framework/reference/core/beans/beanfactory.html)的章节。Spring容器中的所有的对象都叫做Bean，一个bean就是由Spring IoC容器实例化、组装、管理的对象，这些Bean都通过Spring的配置元数据配置从而通过反射的方式生成。