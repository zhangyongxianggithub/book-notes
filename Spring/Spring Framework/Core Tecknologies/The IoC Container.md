# 基于Java的容器配置
如何在源代码中使用注解来配置Spring容器
## 基本概念: @Bean与@Configuration
Spring Java配置支持中的核心是`@Configuration`注解的类与`@Bean`注解的方法。`@Bean`说明方法生成一个Spring IoC容器管理的Bean对象，如果你熟悉XML配置中的\<beans/>元素，那么`@Bean`注解与\<bean/>元素的角色与作用是一样的，你可以与在任何`@Component`注解的类中使用`@Bean`标注的方法，大多数情况下，它们用于`@Configuration`修饰的Bean中，`@Configuration`注解修饰类时表明这个类的主要目的是作为Bean的定义源，更多的，在`@Configuration`类内部，Bean依赖关系通过调用其他的`@Bean`方法的形式定义。最简单的定义如下:
```java
@Configuration
public class AppConfig {
	@Bean
	public MyServiceImpl myService() {
		return new MyServiceImpl();
	}
}
```
等价于下面的XML配置
```xml
<beans>
	<bean id="myService" class="com.acme.services.MyServiceImpl"/>
</beans>
```
在`@Configuration`类内部的`@Bean`方法间的本地调用与非本地调用的区别: 在通常的场景下，`@Bean`方法声明在`@Configuration`类的内部，这回确保配置类得到Spring IoC容器的完整处理，此时内部的方法调用会重定向到容器内部的生命周期管理，这会防止一个`@bean`方法被意外的使用regular的java方法调用的方式被调用。这一帮助减少一些隐晦的BUG。当`@Bean`方法不是在`@Configuation`类里面声明时或者使用了`@Configuration(proxyBeanMethods=false)`的方式定义，他们会被一种简单处理模式处理，在这样的场景下，`@Bean`方法实际上就是一个没有任何特殊运行时处理(也就是没有为它生成CGLib子类)的通用工厂方法机制，对此类方法的自定义Java调用不会被容器拦截，因此其行为就像常规方法调用一样，每次都会创建一个新的实例而不是复用已有的单例；因此，没有运行时代理的类上的`@Bean`方法根本不用于声明bean之间的依赖关系。相反，它们应该对包含方法的组件的字段进行操作，并且（可选）对工厂方法可能声明的参数进行操作，这些参数可能是接收的自动装配的Bean。因此，这样的`@Bean`方法永远不需要调用其他`@Bean`方法；每个这样的调用都可以通过工厂方法参数来表达。这里的积极副作用是，运行时不需要应用任何CGLIB 类化，从而减少了开销和占用空间。`@Bean`与`@Configuration`注解还会在后面的章节做深入讨论。根据包含类的类型不同，`@Bean`得到的处理也是不同的，在`@Configuration`类里面得到的处理最完全，`@Component`里面得到的处理少些，在普通的类里面定义的`@Bean`得到的处理最少；不像在`@Configuration`类中，简单处理模式的`@Bean`不能声明内部bean依赖；反而，他们可能会操作包含类的内部的状态，或者他们声明的参数；这样的`@Bean`方法不应该调用其他的`@Bean`方法；每一个这样的方法只是一个产生特定Bean引用的工厂；没有任何的特别的运行时语义；比较好的地方是，在运行时不会使用CGLIB的方式子类化，所以类的类型可以是final的，在多数的场景下，`@Bean`方法都是定义在`@Configuration`注解修饰的类中，确保Bean是被完整处理的，还可以参与到容器的生命周期的管理中；这阻止了`@Bean`方法可能会被后续的重复调用；帮助减少了一些隐藏BUG的出现。
## 使用`AnnotationConfigApplicationContext`初始化Spring IoC容器
`AnnotationConfigApplicationContext`是`ApplicationContext`的实现，能处理`@Configuration`、`@Component`、与JSR330注解修饰的类。
`@Configuration`注解修饰的类本身也会作为bean注册。对于`@Component`、JSR330注解修饰的类默认依赖具有`@Autowired`与`@Inject`注解修饰。与使用`ClassPathXmlApplicationContext`的方式类似，只不过输入从XNL文件变成了`@Configuration`注解类。使用`AnnotationConfigApplicationContext`完全不需要写任何的XML文件。下面是一个简单的例子:
```java
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(AppConfig.class);
	MyService myService = ctx.getBean(MyService.class);
	myService.doStuff();
}
```
也可以使用`@Component`注解类作为输入
```java
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(MyServiceImpl.class, Dependency1.class, Dependency2.class);
	MyService myService = ctx.getBean(MyService.class);
	myService.doStuff();
}
```
可以调用`register()`方法的方式构建容器，这种方式在以编程的方式构建容器的场景下非常有用，下面是使用的例子:
```java
public static void main(String[] args) {
	AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext();
	ctx.register(AppConfig.class, OtherConfig.class);
	ctx.register(AdditionalConfig.class);
	ctx.refresh();
	MyService myService = ctx.getBean(MyService.class);
	myService.doStuff();
}
```
在输入的`@Configuration`注解修饰类加上`@ComponentScan`注解，可以开启组件扫描。
```java
@Configuration
@ComponentScan(basePackages = "com.acme")// 开启组件扫描
public class AppConfig  {
}
```
有经验的Spring用户可能熟悉这个等价的XML配置方式使用`context:`命名空间
```xml
<beans>
	<context:component-scan base-package="com.acme"/>
</beans>
```
也可以直接调用`scan(String...)`方法开启组件扫描功能，如下面的例子所示:
```java
public static void main(String[] args) {
	AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext();
	ctx.scan("com.acme");
	ctx.refresh();
	MyService myService = ctx.getBean(MyService.class);
}
```
记住，`@Configuration`注解使用元注解`@Component`注释，所以他们也是组件扫描的候选者，在前面的例子中，假如`AppConfig`类在`com.acme`包下面，它会在调用`scan()`期间被选择注册，在`refresh()`方法后，它的所有的`@Bean`方法都会被处理并注册为Spring容器中的Bean。`AnnotationConfigApplicationContext`在web下的变体是`AnnotationConfigWebApplicationContext`；可以使用这个实现配置`ContextLoaderListener`、`servlet`、`listener`、Spring MVC的`DispatcherServlet`等。下面的`web.xml`片段配置了一个传统的Spring MVC web应用，注意`contextClass`参数的使用
```xml
<web-app>
	<!-- Configure ContextLoaderListener to use AnnotationConfigWebApplicationContext
		instead of the default XmlWebApplicationContext -->
	<context-param>
		<param-name>contextClass</param-name>
		<param-value>
			org.springframework.web.context.support.AnnotationConfigWebApplicationContext
		</param-value>
	</context-param>

	<!-- Configuration locations must consist of one or more comma- or space-delimited
		fully-qualified @Configuration classes. Fully-qualified packages may also be
		specified for component-scanning -->
	<context-param>
		<param-name>contextConfigLocation</param-name>
		<param-value>com.acme.AppConfig</param-value>
	</context-param>

	<!-- Bootstrap the root application context as usual using ContextLoaderListener -->
	<listener>
		<listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
	</listener>

	<!-- Declare a Spring MVC DispatcherServlet as usual -->
	<servlet>
		<servlet-name>dispatcher</servlet-name>
		<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
		<!-- Configure DispatcherServlet to use AnnotationConfigWebApplicationContext
			instead of the default XmlWebApplicationContext -->
		<init-param>
			<param-name>contextClass</param-name>
			<param-value>
				org.springframework.web.context.support.AnnotationConfigWebApplicationContext
			</param-value>
		</init-param>
		<!-- Again, config locations must consist of one or more comma- or space-delimited
			and fully-qualified @Configuration classes -->
		<init-param>
			<param-name>contextConfigLocation</param-name>
			<param-value>com.acme.web.MvcConfig</param-value>
		</init-param>
	</servlet>

	<!-- map all requests for /app/* to the dispatcher servlet -->
	<servlet-mapping>
		<servlet-name>dispatcher</servlet-name>
		<url-pattern>/app/*</url-pattern>
	</servlet-mapping>
</web-app>
```
如果想要完全通过编写代码的方式生成`WebApplicationContext`,而不需要注解，你可以使用`GenericWebApplicationContext`这个实现。
## @Bean注解的使用
`@Bean`用在方法上，类似XML中的`<bean>`元素，支持下面的属性
- init-method
- destroy-method
- autowiring
- name
  
`@Bean`为`ApplicationContext`声明一个Bean，你可以在`@Configuration`类与`@Component`类中使用`@Bean`；`@Bean`修饰的方法可以有任意个数的参数，返回的返回值类型就是注册的bean的类型，默认情况下bean的名字就是方法名，下面是一个例子
```java
@Configuration
public class AppConfig {
	@Bean
	public TransferServiceImpl transferService() {
		return new TransferServiceImpl();
	}
}
```
等价于下面的Spring XML配置
```xml
<beans>
	<bean id="transferService" class="com.acme.TransferServiceImpl"/>
</beans>
```
2个声明都声明一个叫做`transferService`的bean，类型是`TransferServiceImpl`，你也可以使用默认方法来定义bean，这样实现相关的接口就可以完成Bean配置。
```java
public interface BaseConfig {

	@Bean
	default TransferServiceImpl transferService() {
		return new TransferServiceImpl();
	}
}
// 没有这部分，bean能生效吗
@Configuration
public class AppConfig implements BaseConfig {

}
```
方法的返回类型也可以是接口或者抽象类
```java
@Configuration
public class AppConfig {
	@Bean
	public TransferService transferService() {
		return new TransferServiceImpl();
	}
}
```
但是，这会将高级类型预测的可见性限制为指定的接口类型(`TransferService`)。然后，只有在单例bean实例化后，容器才会知道完整类型(`TransferServiceImpl`)。Non-Lazy单例bean根据其声明顺序进行实例化，当另一个组件尝试通过未声明的类型进行匹配(例如 `@Autowired TransferServiceImpl`，它仅在`transferService`bean实例化后才会解析)您可能会看到不同的类型匹配结果。这个意思就是说，只有在`transferService`实例化后，容器才知道有`TransferServiceImpl`类型的bean，才能去注入，否则在Bean定义阶段是找不到相关定义的。如果你始终通过声明的服务接口引用您的类型，则`@Bean`返回类型可以安全地加入该设计决策。但是，对于实现多个接口的组件或由具体的实现类型引用的组件，声明尽可能返回具体类型更为安全(至少要与引用bean的注入点所需的类型一样具体)，也就是bean的声明类型要是引用注入类型本身或者子类。`@Bean`方法可以有任意个参数，这些参数都是生成Bean的依赖
```java
@Configuration
public class AppConfig {
	@Bean
	public TransferService transferService(AccountRepository accountRepository) {
		return new TransferServiceImpl(accountRepository);
	}
}
```
解析方式等价于构造函数依赖注入。`@Bean`定义的类支持生命周期回调接口，支持`@PostConstruct`与`@PreDestry`注解；也完全支持Spring的生命周期回调接口，支持实现了`InitializingBea`n、`DisposableBean`、`Lifecycle`接口的回调处理、支持任何的`*Aware`(`BeanFactoryAware`, `BeanNameAware`, `MessageSourceAware`, `ApplicationContextAware`等)接口的处理。也支持指定任意方法作为初始化与销毁的回调函数。如下:
```java
public class BeanOne {
	public void init() {
		// initialization logic
	}
}
public class BeanTwo {
	public void cleanup() {
		// destruction logic
	}
}
@Configuration
public class AppConfig {
	@Bean(initMethod = "init")
	public BeanOne beanOne() {
		return new BeanOne();
	}
	@Bean(destroyMethod = "cleanup")
	public BeanTwo beanTwo() {
		return new BeanTwo();
	}
}
```
默认情况下，如果Java配置中的Bean定义具有公开的`close()`或者`shutdown()`方法，那么则自动称为析构函数的回调。如果你不想要这样的函数称为生命周期回调。可以使用`@Bean(destroyMethod = "")`禁用回调功能，因为默认的模式是`inferred`，会自动注册回调。您可能希望默认对使用JNDI获取的资源禁用生命周期回调，因为其生命周期是在应用程序外部管理的。特别是，请确保始终对`DataSource`禁用Spring的生命周期回调，因为众所周知，这在Jakarta EE应用服务器上会带来问题。以下示例显示了如何防止`DataSource`的自动销毁回调：
```java
@Bean(destroyMethod = "")
public DataSource dataSource() throws NamingException {
	return (DataSource) jndiTemplate.lookup("MyDS");
}
```
也可以使用`@Scope`装饰你可以使用所有合法的scope，默认是`singleton`
```java
@Configuration
public class MyConfiguration {
	@Bean
	@Scope("prototype")
	public Encryptor encryptor() {
	}
}
```
Spring提供了一种通过[作用域代理](https://docs.spring.io/spring-framework/reference/core/beans/factory-scopes.html#beans-factory-scopes-other-injection)处理作用域依赖项的便捷方法。使用XML配置时，创建此类代理的最简单方法是`<aop:scoped-proxy/>`元素。使用`@Scope`注释在Java中配置bean时，可通过`proxyMode`属性提供相同的支持。默认值为`ScopedProxyMode.DEFAULT`，这通常表示不应创建任何作用域代理，除非在组件扫描指令级别配置了不同的默认值。您可以指定`ScopedProxyMode.TARGET_CLASS`、`ScopedProxyMode.INTERFACES`或 `ScopedProxyMode.NO`。如果将作用域代理从XML移植到`@Bean`，它类似于以下内容:
```java
// an HTTP Session-scoped bean exposed as a proxy
@Bean
@SessionScope
public UserPreferences userPreferences() {
	return new UserPreferences();
}
@Bean
public Service userService() {
	UserService service = new SimpleUserService();
	// a reference to the proxied userPreferences bean
	service.setUserPreferences(userPreferences());
	return service;
}
```
Bean的名字默认是方法名，通过`@Bean`的`name`属性改变bean的名字，如果name是一个数组，那么都是bean的别名
```java
@Configuration
public class AppConfig {
	@Bean("myThing")
	public Thing thing() {
		return new Thing();
	}
}
@Configuration
public class AppConfig {
	@Bean("myThing")
	public Thing thing() {
		return new Thing();
	}
}
```
有时，提供更详细的bean文本描述会很有帮助。当bean出于监控目的而expose(可能通过JMX)时，这尤其有用。要向`@Bean`添加描述，可以使用 `@Description`注释，如下例所示:
```java
@Configuration
public class AppConfig {
	@Bean
	@Description("Provides a basic example of a bean")
	public Thing thing() {
		return new Thing();
	}
}
```
## 使用@Configuration注解
`@Configuration`是一个类级别上的注解，用来表示这个对象是bean定义源。直接使用方法调用的方式表示Bean的依赖关系，这种调用表示依赖的行为仅限于@Bean方法是在Configuration里面定义的，定义在别的种类的文件中是没有这种表示的。
Lookup方法注入：主要用于单例Bean依赖多例bean的情况，需要在单例Bean里面设置一个获取单例Bean对象的抽象方法，

然后创建单例Bean

## 配置组合
@Import注解导入其他的@Configuration类配置；Bean如果依赖其他@Configuration类里面的bean的话，直接在bean定义的方法上加入其依赖的参数就可以，Spring会自动注入对应类型的Bean；

需要注意的是通过@Bean方式定义的BeanPostProcessor与BeanFactoryPostProcessor。他们通常都是定义为的静态方法@Bean；并不会出发所在的@Configuration类的实例化；另外@Configuration类上不能使用@Autowired与@Value注解，因为@Configuration类的初始化是非常早的。依赖的Bean或者value可能还没有初始化。使用@Lazy与@DependsOn注解指定初始化顺序。
有时候想根据系统的状态动态的开启或者关闭@Configuration类，或者某个独立的@Bean方法；一个常见的方式就是使用@Profile注解来动态的激活某些Bean；@Profile注解是通过@Conditional注解实现的，@Conditional注解命令，在一个@bean被注册前，需要使用指定的Condition接口的实现判断下，是否需要注册。Condition接口提供了matches(…)方法，返回true/false，下面的代码是@Profile的实现。

在@Configuration类上使用@ImportResource注解导入XML配置。在XML配置一个@Configuration类的Bean，就导入了注解配置的bean或者使用<context:component-scan/>开启组件扫描。
# 容器扩展点
通常来说，应用开发者不需要创建现有的`ApplicationContext`实现类的子类，Spring不想要开发者自己实现`ApplicationContext`接口的实现类的子类，因为Spring IoC容器可以通过插件的方式扩展，插件是一些特殊集成接口的实现类。下面的章节描述了这些插件集成接口。
## 通过BeanPostProcessor定制化Bean
`BeanPostProcessor`接口定义了一些回调方法，实现这个接口可以提供自己的Bean初始化逻辑、依赖注入解析逻辑等；如果你想要在Spring容器初始化、配置与实例化bean完成后实现一些自定义的逻辑，可以给容器配置多个自定义的`BeanPostProcessor`接口实现插件；实现`Ordered`接口可以控制执行顺序；`BeanPostProcessor`实例是作用于Bean实例上的，也就是说Spring IoC初始化一个Bean实例，然后`BeanPostProcessor`开始工作，当前容器的`BeanPostProcessor`只会操作当前容器的bean实例，特别是当容器存在层级体系时，这会非常有用。如果想要改变实际的bean definition（也就是定义bean的蓝图），你需要使用[BeanFactoryPostProcessor接口](https://docs.spring.io/spring-framework/reference/core/beans/factory-extension.html#beans-factory-extension-factory-postprocessors)来做。`BeanPostProcessor`接口包含2个回调方法，当向容器注册一个`BeanPostProcessor`作为post-processor后，对于容器创建的每个bean实例，容器分别在Bean的容器初始化方法(比如`InitializingBean.afterPropertiesSet()`或者任何的声明的init方法)执行前与Bean实例化生命周期方法回调完成后调用post-processor的回调方法；post-processor可以对bean实例对象做任何操作，甚至完全忽略bean的生命周期回调，`BeanPostProcessor`通常就是检查回调接口，或者使用代理包装Bean。一些Spring AOP的基础类就是使用`BeanPostProcessor`实现的，这是为了提供一些proxy-warpping的逻辑。`ApplicationContext`会自动检测配置元数据中实现了`BeanPostProcessor`接口的所有Bean，并把这些Bean注册到容器中以便在bean创建时使用，post-processors Bean的定义与其他bean的定义方式没有区别。注意，当在配置类上使用`@Bean`工厂方法声明`BeanPostProcessor`时，工厂方法的返回类型应该是实现类本身或者至少是`org.springframework.beans.factory.config.BeanPostProcessor`接口，明确表明该bean的是一个post-processor。 否则，`ApplicationContext`在完全创建之前无法按类型自动检测它。由于需要尽早实例化`BeanPostProcessor`以应用于上下文中其他bean的初始化，因此这种早期类型检测至关重要。编程的方式注册`BeanPostProcessor`的方式是使用`ConfigurableBeanFactory`的`addBeanPostProcessor`方法；通常发生在注册需要一些逻辑判断或者在多容器体系内拷贝post processor时。编程的方式注册的`BeanPostProcessor`实例不需要实现`Ordered`接口，因为不需要，执行的顺序就是注册的顺序，同时编程方式添加的`BeanPostProcessor`都比自动检测出来的`BeanPostProcessor`先得到处理。实现了`BeanPostProcessor`接口的类是特殊的类，会被Spring容器特殊的对待，所有的`BeanPostProcessor`实例以及`BeanPostProcessor`依赖的bean都会在启动阶段实例化，这个阶段是ApplicationContext特殊启动阶段的一部分内容。接下来，所有的`BeanPostProcessor`按顺序注册并应用到容器内的所有的Bean，因为AOP自动代理机制也是通过`BeanPostProcessor`实现的，所以 `BeanPostProcessor`实例和它们直接引用的bean都没有资格进行自动代理，因此没有将AOP编织到其中。对于这样的bean，你应该会看到这样的日志信息：`Bean someBean is not eligible for getting processed by all BeanPostProcessor interfaces (for example: not eligible for auto-proxying)`。如果您使用自动装配或`@Resource`(可能会退回到自动装配)将bean注入到您的`BeanPostProcessor`，则Spring在按照类型搜索bean时可能会访问所有符合类型的bean并实例化，可能其中有些bean不是当前`BeanPostProcessor`想要的，这会使这些Bean不能被自动代理处理或被其他`BeanPostProcessor`处理。例如，如果您有一个使用`@Resource`注解的依赖项，其中字段或setter名称与bean的声明名称不匹配并且没有使用name属性额外指定，此时Spring回退到按类型匹配，则Spring会访问当前类型的所有bean。
下面是一个编写、注册与使用`BeanPostProcessor`的例子，这是基本的用法，这个例子展示了一个自定义的`BeanPostProcessor`调用每个Bean的`toString()`方法并打印到控制台。
```java
package scripting;

import org.springframework.beans.factory.config.BeanPostProcessor;

public class InstantiationTracingBeanPostProcessor implements BeanPostProcessor {

	// simply return the instantiated bean as-is
	public Object postProcessBeforeInitialization(Object bean, String beanName) {
		return bean; // we could potentially return any object reference here...
	}

	public Object postProcessAfterInitialization(Object bean, String beanName) {
		System.out.println("Bean '" + beanName + "' created : " + bean.toString());
		return bean;
	}
}
```
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:lang="http://www.springframework.org/schema/lang"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
		https://www.springframework.org/schema/beans/spring-beans.xsd
		http://www.springframework.org/schema/lang
		https://www.springframework.org/schema/lang/spring-lang.xsd">

	<lang:groovy id="messenger"
			script-source="classpath:org/springframework/scripting/groovy/Messenger.groovy">
		<lang:property name="message" value="Fiona Apple Is Just So Dreamy."/>
	</lang:groovy>

	<!--
	when the above bean (messenger) is instantiated, this custom
	BeanPostProcessor implementation will output the fact to the system console
	-->
	<bean class="scripting.InstantiationTracingBeanPostProcessor"/>

</beans>
```
注意`InstantiationTracingBeanPostProcessor`是如何定义的，它没有名字只是一个Bean，下面的应用使用了上面的代码
```java
public final class Boot {
	public static void main(final String[] args) throws Exception {
		ApplicationContext ctx = new ClassPathXmlApplicationContext("scripting/beans.xml");
		Messenger messenger = ctx.getBean("messenger", Messenger.class);
		System.out.println(messenger);
	}
}
```
还有一个例子`AutowiredAnnotationBeanPostProcessor`，将回调接口/注解与自定义的`BeanPostProcessor`组合使用是扩展Spring IoC容器的最常用的方式，例子就是Spring的`AutowiredAnnotationBeanPostProcessor`，这个`BeanPostProcessor`跟随Spring版本发布，自动注入被注解的fields、setter方法或者任意的配置方法。
## 使用BeanFactoryPostProcessor自定义配置元数据
下一个扩展点就是`org.springframework.beans.factory.config.BeanFactoryPostProcessor`，这个接口的含义与`BeanPostProcessor`类似，只有一个不同点就是，`BeanFactoryPostProcessor`操作的是配置元数据，也就是说，Spring IoC容器让`BeanFactoryPostProcessor`读取配置元数据，使它可以在容器实例化任何Bean(不包括`BeanFactoryPostProcessor`)之前修改配置元数据，当然容器会首先实例化`BeanFactoryPostProcessor`。你可以配置多个`BeanFactoryPostProcessor`实例，可以通过`Ordered`接口来控制`BeanFactoryPostProcessor`的执行顺序。如果你要变更的是bean实例(也就是从配置元数据创建的对象)，你需要使用`BeanPostProcessor`，从技术上来讲，`BeanFactoryPostProcessor`也可以操作Bean实例，只需要调用`BeanFactory.getBean()`此时bean会实例化，这样做会使Bean过早的实例化，违反了标准的容器生命周期过程，这可能会造成副作用，比如绕过Bean的后处理。`BeanFactoryPostProcessor`也是容器的作用域，与`BeanPostProcessor`一样。当在`ApplicationContext`中声明了`BeanFactoryPostProcessor`后，它会自动运行，就是为了修改配置元数据，Spring包含了大量预定义的`BeanFactoryPostProcessor`，比如`PropertyOverrideConfigurer`或者`PropertySourcePlaceholderConfigurer`。你也可以使用自定义的`BeanFactoryPostProcessor`比如注册自定义的属性编辑器。`ApplicationContext`会自动检测所有实现`BeanFactoryPostProcessor`接口的Bean，并把这些Bean作为bean factory post-processors。与`BeanPostProcessor`一样，`BeanFactoryPostProcessor`通常不能配置成懒加载的。如果没有其他Bean引用一个`Bean(Factory)PostProcessor`，post-processor不会被实例化。因此post-processor的懒加载机制会被忽略。即使你在`<beans />`元素的声明中设置`default-lazy-init=true`，`Bean(Factory)PostProcessor`也是提前初始化的。
例子: `PropertySourcesPlaceholderConfigurer`
你可以使用`PropertySourcesPlaceholderConfigurer`将来自于Bean配置元数据中的属性值外化到一个文件中，通常文件是标准的Java`Properties`格式，这样做，可以让开发者部署应用时可以定制户环境相关的属性，比如database URL或者密码，不需要更改XML配置元数据文件。降低复杂性，使变更更简单。考虑下面的基于XML的配置元数据片段，DataSource带有一个占位符的值:
```xml
<bean class="org.springframework.context.support.PropertySourcesPlaceholderConfigurer">
	<property name="locations" value="classpath:com/something/jdbc.properties"/>
</bean>

<bean id="dataSource" class="org.apache.commons.dbcp.BasicDataSource" destroy-method="close">
	<property name="driverClassName" value="${jdbc.driverClassName}"/>
	<property name="url" value="${jdbc.url}"/>
	<property name="username" value="${jdbc.username}"/>
	<property name="password" value="${jdbc.password}"/>
</bean>
```
例子中表明属性配置为来自一个外部`Properties`文件，在运行时，一个`PropertySourcesPlaceholderConfigurer`对象应用到配置元数据。这个`BeanFactoryPostProcessor`会替换DataSource中的占位符属性，也就是`${property-name}`格式的占位符，支持Ant、log4j、JSP EL样式的占位符，属性来源文件的内容如下:
```Proeprties
jdbc.driverClassName=org.hsqldb.jdbcDriver
jdbc.url=jdbc:hsqldb:hsql://production:9002
jdbc.username=sa
jdbc.password=root
```
因此，`${jdbc.username}`在运行时会被替换为`'sa'`，其他与属性文件中的key相匹配的占位符也会被替换，你可以定制占位符的的前缀与后缀，Spring2.5引入了一个叫做`context`的命名空间，你可以用一个专门的配置元素配置属性占位符，你可以在`location`中指定一个或者多个逗号分隔的位置列表，如下所示:
```xml
<context:property-placeholder location="classpath:com/something/jdbc.properties"/>
```
`PropertySourcesPlaceholderConfigurer`不仅在您指定的属性文件中查找属性。默认情况下，如果在指定的属性文件中找不到属性，它会检查 Spring Environment和常规Java系统属性。一个应用只需要定义一次`PropertySourcesPlaceholderConfigurer`，除非多个都有不同的占位符前后缀，您可以使用`PropertySourcesPlaceholderConfigurer`替换类名，当您必须在运行时pick一个特定的实现类时会很有用。以下示例显示了如何执行此操作:
```xml
<bean class="org.springframework.beans.factory.config.PropertySourcesPlaceholderConfigurer">
	<property name="locations">
		<value>classpath:com/something/strategy.properties</value>
	</property>
	<property name="properties">
		<value>custom.strategy.class=com.something.DefaultStrategy</value>
	</property>
</bean>

<bean id="serviceStrategy" class="${custom.strategy.class}"/>
```
如果class不能在运行时解析为一个有效的class，bean在创建时就会解析失败，对于一个非懒加载的bean来说，这发生在`ApplicationContext`的`preInstantiateSingletons()`阶段。
第二个例子: `PropertyOverrideConfigurer`
`PropertyOverrideConfigurer`也是一个`BeanFactoryPostProcessor`，与`PropertySourcesPlaceholderConfigurer`类似，但与后者不同的是，bean属性值的原始定义可以有默认值或根本没有值。如果外部属性文件没有bean属性值的属性定义，则使用默认上下文定义。请注意，bean 定义不知道被覆盖，因此从XML定义文件中不能立即看出正在使用override configurer。如果有多个`PropertyOverrideConfigurer`实例为同一个bean属性定义不同的值，由于覆盖机制，最后一个会获胜。
属性配置的格式: `beanName.property=value`，下面是一个例子:
```proeprties
dataSource.driverClassName=com.mysql.jdbc.Driver
dataSource.url=jdbc:mysql:mydb
```
这个例子文件可以被一个容器定义，容器定义定义了一个叫做`dataSource`的bean，有`driver`与`url`2个属性，也支持级联属性名，只要路径中的每一个部件都不是null，一个例子`tom.fred.bob.sammy=123`，指定的覆盖的值都是字面量，而不是对bean的引用。
```xml
<context:property-override location="classpath:override.properties"/>
```
## 使用FactoryBean自定义初始化逻辑
你可以使用`FactoryBean`接口创建工厂Bean对象，`FactoryBean`接口是Spring IoC容器实例化逻辑的可插入点。 如果您有复杂的初始化代码，用Java代码更好地表达而不是(可能)冗长的XML，您可以创建自己的`FactoryBean`，在该类中编写复杂的初始化逻辑，然后将您的自定义`FactoryBean`插入容器。`FactoryBean<T>`接口提供了3个方法:
- `T getObject()`: 返回这个工厂创建的对象的实例，返回的实例可以是shared，这依赖于返回的是singleton还是prototypes
- `boolean isSingleton()`: 如果返回的是单例，则为true，否则是false，方法默认返回true
- `Class<?> getObjectType()`: `getObject`方法返回的对象的类型，如果预先不知道可以返回null

`FactoryBean`接口在Spring Framework中广泛的使用，Spring本身实现了大约50+个实现类，当你想要获取容器中的`FactoryBean`本身而不是它产生的Bean，调用`ApplicationContext`的`getBean()`方法传递的名字是&+bean的名字，所以假如一个id=myBean的`FactoryBean`，调用`getBean(myBean)`获取的是`FactoryBean`产生的对象，调用`getBean(&myBean)`获取的是`FactoryBean`本身。
