`org.springframework.context.ApplicationContext`接口表示Spring IoC容器，负责实例化、配置与组装beans。Spring容器通过读取配置元数据信息得到如何创建、配置与组装Bean的指令，配置元数据可以是注解的组件类、带有工厂方法的注解的配置类、外部XML或者Groovy脚本组成，元数据定义了组成应用的对象与这些对象之间的依赖关系。
Spring提供了几个`ApplicationContext`接口的实现类，比如单机版的应用可以使用`ClassPathXmlApplicationContext`与`FileSystemXmlApplicationContext`或者`AnnotationConfigApplicationContext`；
在大多数应用场景中，开发者不需要明确的实例化一个或者多个容器，只需要进行一定的声明，比如在Web应用场景中，只需要在web.xml文件中配置8行的Web应用描述XML就可以了，具体可以了解[Convenient ApplicationContext Instantiation for Web Applications](https://docs.spring.io/spring-framework/reference/core/beans/context-introduction.html#context-create)，在Spring Boot场景中，应用上下文基于通用约定隐式创建。下图展示了Spring如何工作的高层视角，你的应用类通过配置元数据组合起来，这样在`ApplicationContext`创建与初始化后，你拥有一个配置完整的可执行的系统与应用。
![Figure1. Spring IoC容器](./pic/container-magic.png)
# 配置元数据
如上图所示，Spring IoC容器消费配置元数据，这些配置元数据表示你作为开发者需要告诉Spring容器如何实例化、配置与组装对象的指令。配置元数据传统上是XML，也有基于注解的配置，Spring IoC容器本身已经与元数据的配置格式解藕了。所以可以支持多种元数据书写格式，Spring 2.5版本后开始支持基于Java注解的元数据格式，从Spring 3.0集成了Spring JavaConfig项目，所以也包含其提供的一些特性(比如可以使用Java的方式定义第三方包中类的bean)。现在多数开发者选择使用基于Java的配置方式创建Spring应用，分2种:
- 基于注解的配置方式: 使用应用组件类上的注解配置元数据来定义bean
- 基于Java的配置方式: 使用java配置类的方式将外部类定义为Bean，使用注解`@Configuation`、`@Bean`、`@Import`、`@DependsOn`等

Spring配置通常包含至少一个或者多个Bean definition，Java配置方案通常使用`@Configuation`修饰的配置类中的`@Bean`修饰的方法来生成Bean配置元数据，这些Bean定义就表示组成你应用的实际的对象。通常来说，你定义服务层对象、持久层对象比如repositories或者data access objects、展示层对象比如Web controllers、基础组件层对象比如一个JPA的`EntityManagerFactory`,JMS queue等，通常来说，开发者不在容器中配置细粒度的领域对象，因为通常是repositories与业务逻辑负责创建或者加载领域对象。
## XML as an External Configuration DSL
XML配置元数据方式使用`<bean>`元素配置bean，`<bean>`定义在一个`<beans>`元素中。
java配置方式是在@Configuration类中配置@Bean注解的方法来管理多个bean。下面的例子是一个XML配置元数据的基本结构:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
	https://www.springframework.org/schema/beans/spring-beans.xsd">
	<bean id="..." class="...">
		<!-- collaborators and configuration for this bean go here -->
	</bean>
<!--id属性标识bean定义，class属性定义了bean的类型，使用类的全限定名-->
	<bean id="..." class="...">
		<!-- collaborators and configuration for this bean go here -->
	</bean>
	<!-- more bean definitions go here -->
</beans>
```
`id`属性可以用来引用对象。为了实例化容器，XML配置元数据资源文件的路径需要提供给`ClassPathXmlApplicationContext`的构造函数，这样容器会从外部资源加载配置元数据，比如本地文件系统或者Java的Classpath等
```java
ApplicationContext context = new ClassPathXmlApplicationContext("services.xml", "daos.xml");
```
在你了解到Spring IoC容器后，你可能项了解Spring的`Resource`抽象模型，它抽象了一个行为，就是从任意URI语法定义的位置读取输入流，特别是`Resource`的位置用来构造`ApplicationContext`时也是使用的它。下面的例子展示了服务层对象配置元数据文件
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
		https://www.springframework.org/schema/beans/spring-beans.xsd">

	<!-- services -->

	<bean id="petStore" class="org.springframework.samples.jpetstore.services.PetStoreServiceImpl">
		<property name="accountDao" ref="accountDao"/>
		<property name="itemDao" ref="itemDao"/>
		<!-- additional collaborators and configuration for this bean go here -->
	</bean>

	<!-- more bean definitions for services go here -->

</beans>
```
下面的例子展示了dao层配置元数据文件`daos.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
		https://www.springframework.org/schema/beans/spring-beans.xsd">

	<bean id="accountDao"
		class="org.springframework.samples.jpetstore.dao.jpa.JpaAccountDao">
		<!-- additional collaborators and configuration for this bean go here -->
	</bean>

	<bean id="itemDao" class="org.springframework.samples.jpetstore.dao.jpa.JpaItemDao">
		<!-- additional collaborators and configuration for this bean go here -->
	</bean>

	<!-- more bean definitions for data access objects go here -->

</beans>
```
在前面的例子中，服务层包含`PetStoreServiceImpl`对象与2个dao层对象，其中`<property>`元素的`name`属性引用Bean中的属性名字，`ref`属性应用其他bean定义的名字，`ref`对`id`的引用表示了对象间的依赖关系。
## Composing XML-based Configuration Metadata
将bean definitions分布到多个XML文件中很有用。通常，每个XML配置文件表示架构中的一个逻辑层或者模块。你可以使用`ClassPathXmlApplicationContext`构造函数从XML片段中加载bean definitions。构造函数接受多个`Resource`位置，另外也可以使用多个`<import/>`元素加载其他文件的bean定义。下面是一个例子:
```xml
<beans>
	<import resource="services.xml"/>
	<import resource="resources/messageSource.xml"/>
	<import resource="/resources/themeSource.xml"/>
	<bean id="bean1" class="..."/>
	<bean id="bean2" class="..."/>
</beans>
```
在前面的章节中，从3个文件中加载bean definitions: `services.xml`、`messageSource.xml`、`themeSource.xml`。所有的位置路径都是`<import>`元素所在文件的相对路径，所以`services.xml`必须与导入其的文件在相同的目录下或者相同的classpath位置下。`messageSource.xml`与`themeSource.xml`必须在导入文件的`resources`目录下，所以前置的`/`会被忽略，也就是不支持绝对路径。但是，考虑到这些路径是相对的，最好不要使用斜线。根据Spring Schema，导入的文件内容(包括顶级`<beans/>`元素)必须是有效的XML bean定义。可以使用相对`../`路径引用父目录，但不建议这样做。这样做会访问当前应用之外的文件。特别是，不建议在`classpath:URL`中使用这种形式(例如`classpath:../services.xml`)，否则运行时解析过程会选择最近的的classpath root目录，然后查看其父目录。classpath配置更改可能会导致选择到不同的、不正确的目录。你可以使用完全限定的资源位置而不是相对路径。例如，`file:C:/config/services.xml`或`classpath:/config/services.xml`。但是，应用程序的配置将耦合到特定的绝对位置。通常最好为此类绝对位置保留间接路径，例如，通过在运行时根据JVM系统属性解析的`${…​}`占位符设置。命名空间本身提供了导入指令。
## The Groovy Bean Definition DSL
外部配置元数据也可以使用Spring Groovy Bean Definition DSL描述。来自Grails框架，通常，配置写在一个`.groovy`文件中
```groovy
beans {
	dataSource(BasicDataSource) {
		driverClassName = "org.hsqldb.jdbcDriver"
		url = "jdbc:hsqldb:mem:grailsDB"
		username = "sa"
		password = ""
		settings = [mynew:"setting"]
	}
	sessionFactory(SessionFactory) {
		dataSource = dataSource
	}
	myService(MyService) {
		nestedBean = { AnotherBean bean ->
			dataSource = dataSource
		}
	}
}
```
等价于XML配置方式甚至支持Spring XML配置空间。也可以通过一个`importBeans`指令导入XML配置

# 使用容器
`ApplicationContext`就是一个高级工厂接口，可以维护Bean的注册与他们的依赖，通过使用`T getBean(String name, Class<T> requiredType)`方法，可以检索所有的Bean。你可以通过`ApplicationContext`读取bean definitions病访问它们，如下所示:
```java
// create and configure beans
ApplicationContext context = new ClassPathXmlApplicationContext("services.xml", "daos.xml");

// retrieve configured instance
PetStoreService service = context.getBean("petStore", PetStoreService.class);

// use configured instance
List<String> userList = service.getUsernameList();
```
使用Groovy配置的初始化过程也是类似的，只是实现类不同
```java
ApplicationContext context = new GenericGroovyApplicationContext("services.groovy", "daos.groovy");
```
ApplicationContext有一个最灵活的实现者就是GenericApplicationContext，它内部组合了一个元数据reader delegates，可以读取任意格式的元数据格式文件，比如XML的或者Groovy的。。比如读取XML配置的`XmlBeanDefinitionReader`
```java
GenericApplicationContext context = new GenericApplicationContext();
new XmlBeanDefinitionReader(context).loadBeanDefinitions("services.xml", "daos.xml");
context.refresh();
```
也可以使用`GroovyBeanDefinitionReader`读取Groovy文件，如下面的例子所示
```java
GenericApplicationContext context = new GenericApplicationContext();
new GroovyBeanDefinitionReader(context).loadBeanDefinitions("services.groovy", "daos.groovy");
context.refresh();
```
你可以在同一个`ApplicationContext`混合使用这些reader，这样可以从不同的配置元数据源中读取配置信息。然后可以使用`getBean()`方法获取bean实例，`ApplicationContext`接口也有其他的变体方法来检索bean实例，通常不建议应用代码使用getBean方法，那会产生对对Spring API的依赖关系。



