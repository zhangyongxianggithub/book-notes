IoC容器
IoC，控制反转容器。主要包含的内容如下:
- [Introduction to the Spring IoC Container and Beans](https://docs.spring.io/spring-framework/reference/core/beans/introduction.html)
- [Container Overview](https://docs.spring.io/spring-framework/reference/core/beans/basics.html)
- [Bean Overview](https://docs.spring.io/spring-framework/reference/core/beans/definition.html)
- [Dependencies](https://docs.spring.io/spring-framework/reference/core/beans/dependencies.html)
- [Bean Scopes](https://docs.spring.io/spring-framework/reference/core/beans/factory-scopes.html)
- [Customizing the Nature of a Bean](https://docs.spring.io/spring-framework/reference/core/beans/factory-nature.html)
- [Bean Definition Inheritance](https://docs.spring.io/spring-framework/reference/core/beans/child-bean-definitions.html)
- [Container Extension Points](https://docs.spring.io/spring-framework/reference/core/beans/factory-extension.html)
- [Annotation-based Container Configuration](https://docs.spring.io/spring-framework/reference/core/beans/annotation-config.html)
- [Classpath Scanning and Managed Components](https://docs.spring.io/spring-framework/reference/core/beans/classpath-scanning.html)
- [Using JSR 330 Standard Annotations](https://docs.spring.io/spring-framework/reference/core/beans/standard-annotations.html)
- [Java-based Container Configuration](https://docs.spring.io/spring-framework/reference/core/beans/java.html)
- [Environment Abstraction](https://docs.spring.io/spring-framework/reference/core/beans/environment.html)
- [Registering a LoadTimeWeaver](https://docs.spring.io/spring-framework/reference/core/beans/context-load-time-weaver.html)
- [Additional Capabilities of the ApplicationContext](https://docs.spring.io/spring-framework/reference/core/beans/context-introduction.html)
- [The BeanFactory API](https://docs.spring.io/spring-framework/reference/core/beans/beanfactory.html)

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
## 使用`@Configuration`注解
`@Configuration`注解是一个类级别的注解，表示对象是bean定义的定义源。`@Configuration`注解类通过`@Bean`注解方法来声明bean，对`@Bean`注解修饰方法的调用定义了bean之间的依赖关系。下面是一个例子:
```java
@Configuration
public class AppConfig {
	@Bean
	public BeanOne beanOne() {
		return new BeanOne(beanTwo());
	}
	@Bean
	public BeanTwo beanTwo() {
		return new BeanTwo();
	}
}
```
在前面的例子中，`beanOne`依赖`beanTwo`，如前所述，lookup method injection是一项你很少用到的高级功能，用在单例bean依赖多例bean的场景，下面是一个例子:
```java
public abstract class CommandManager {
	public Object process(Object commandState) {
		// grab a new instance of the appropriate Command interface
		Command command = createCommand();
		// set the state on the (hopefully brand new) Command instance
		command.setState(commandState);
		return command.execute();
	}

	// okay... but where is the implementation of this method?
	protected abstract Command createCommand();
}
```
通过使用Java配置，你可以创建`CommandManager`的子类，其中抽象方法`createCommand()`被重写，可以查找新的`Command`对象。下面的例子
```java
@Bean
@Scope("prototype")
public AsyncCommand asyncCommand() {
	AsyncCommand command = new AsyncCommand();
	// inject dependencies here as required
	return command;
}

@Bean
public CommandManager commandManager() {
	// return new anonymous implementation of CommandManager with createCommand()
	// overridden to return a new prototype Command object
	return new CommandManager() {
		protected Command createCommand() {
			return asyncCommand();
		}
	}
}
```
考虑下面的例子，展示了`@Bean`注解方法被调用了2次:
```java
@Configuration
public class AppConfig {

	@Bean
	public ClientService clientService1() {
		ClientServiceImpl clientService = new ClientServiceImpl();
		clientService.setClientDao(clientDao());
		return clientService;
	}

	@Bean
	public ClientService clientService2() {
		ClientServiceImpl clientService = new ClientServiceImpl();
		clientService.setClientDao(clientDao());
		return clientService;
	}

	@Bean
	public ClientDao clientDao() {
		return new ClientDaoImpl();
	}
}
```
`clientDao()`方法被调用了2次，这个方法创建一个`ClientDaoImpl`类型的实例并返回，你可能希望每个service有一个自己的clientDao，这肯定会有问题: 在Spring中，实例化的bean默认是单例作用域的。这就是魔力所在，所有`@Configuration`类在启动时都使用`CGLIB`进行子类化。在子类中，子方法在调用父方法并创建新实例前会先检查容器中是否有任何缓存的bean。这个行为根据bean的scope的不同行为会不同，不需要将CGLIB添加到您的类路径，因为CGLIB类已重新打包在`org.springframework.cglib`包下，并直接包含在spring-core JAR中。由于CGLIB在启动时动态添加功能，因此存在一些限制。特别是，配置类不能是final的。但是，配置类上允许使用任何构造函数，包括使用`@Autowired`或单个非默认构造函数声明进行默认注入。如果您希望避免任何CGLIB施加的限制，请考虑在非`@Configuration`类上声明您的`@Bean`方法（例如，在普通的`@Component`类上），或者使用 `@Configuration(proxyBeanMethods = false)`注解修饰您的配置类。这样就不会拦截`@Bean`方法之间的跨方法调用，因此您必须完全依赖构造函数或方法级别的依赖注入。
## 基于Java的配置组合
Spring的基于Java的配置特性，你可以组合注解配置，降低配置的复杂性。Spring XML配置中的`<import/>`元素是帮助模块化配置的，`@Import`起到了同样的作用，它可以从其他的配置类中加载`@Bean`定义，如下面的例子所示:
```java
@Configuration
public class ConfigA {
	@Bean
	public A a() {
		return new A();
	}
}
@Configuration
@Import(ConfigA.class)
public class ConfigB {
	@Bean
	public B b() {
		return new B();
	}
}
```
现在相比与在初始化容器的时候指定2个配置类，只需要指定一个类就可以了
```java
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(ConfigB.class);
	// now both beans A and B will be available...
	A a = ctx.getBean(A.class);
	B b = ctx.getBean(B.class);
}
```
这种方式简化了容器初始化，从Spring Framework 4.2开始，`@Import`还支持引用常规组件类，类似于`AnnotationConfigApplicationContext.register`方法。如果您想通过使用一些配置类作为入口点来明确定义所有组件来避免组件扫描，这种方式就很有用。前面的例子有效但是过于简单，在大多数实际场景中，不同的配置类中的bean相互依赖，使用XML时，这不是个问题，因为不涉及编译器，您可以声明`ref="someBean"`并相信Spring在容器初始化期间会解决它。使用注解配置时，会面临Java编译器的一些限制，就是对其他Bean的引用必须是有效的java语法。幸运的是解决这个问题很简单，`@Bean`方法可以有任意数量的参数来描述依赖关系，考虑下面的类
```java
@Configuration
public class ServiceConfig {
	@Bean
	public TransferService transferService(AccountRepository accountRepository) {
		return new TransferServiceImpl(accountRepository);
	}
}
@Configuration
public class RepositoryConfig {
	@Bean
	public AccountRepository accountRepository(DataSource dataSource) {
		return new JdbcAccountRepository(dataSource);
	}
}
@Configuration
@Import({ServiceConfig.class, RepositoryConfig.class})
public class SystemTestConfig {
	@Bean
	public DataSource dataSource() {
		// return new DataSource
	}
}
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(SystemTestConfig.class);
	// everything wires up across configuration classes...
	TransferService transferService = ctx.getBean(TransferService.class);
	transferService.transfer(100.00, "A123", "C456");
}
```
还有另外一种方法可以实现相同的效果，请记住`@Configuration`类也是容器中的一个bean，也就是爷们也也可以使用`@Autowired`与`@Value`注解。确保以这种方式注入的依赖项仅是最简单的类型，`@Configuration`类在上下文初始化的早期就会被处理，强制以这种方式注入依赖项可能会导致意外的早期初始化。尽可能使用基于参数的注入，如上例所示。避免在配置类中的`@PostConstruct`方法中访问本地定义的bean。这实际上会导致循环引用，因为非静态`@Bean`方法在语义上需要完全初始化的配置类实例才能调用。如果不允许循环引用(例如，在 Spring Boot 2.6+中)，这可能会触发`BeanCurrentlyInCreationException`。此外，通过`@Bean`定义`BeanPostProcessor`和`BeanFactoryPostProcessor`时要特别小心。它们通常应声明为静态`@Bean`方法，而不是触发所在的配置类的实例化。否则，配置类中的`@Autowired`和`@Value`可能无法工作，因为有可能比 `AutowiredAnnotationBeanPostProcessor`更早地将配置类创建为bean实例。下面是一个例子
```java
@Configuration
public class ServiceConfig {
	@Autowired
	private AccountRepository accountRepository;
	@Bean
	public TransferService transferService() {
		return new TransferServiceImpl(accountRepository);
	}
}
@Configuration
public class RepositoryConfig {
	private final DataSource dataSource;
	public RepositoryConfig(DataSource dataSource) {
		this.dataSource = dataSource;
	}
	@Bean
	public AccountRepository accountRepository() {
		return new JdbcAccountRepository(dataSource);
	}
}
@Configuration
@Import({ServiceConfig.class, RepositoryConfig.class})
public class SystemTestConfig {
	@Bean
	public DataSource dataSource() {
		// return new DataSource
	}
}
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(SystemTestConfig.class);
	// everything wires up across configuration classes...
	TransferService transferService = ctx.getBean(TransferService.class);
	transferService.transfer(100.00, "A123", "C456");
}
```
在前面的场景中，使用`@Autowired`效果很好，并且提供了所需的模块化，但确定自动装配bean定义的确切声明位置仍然有些模糊。例如，作为查看`ServiceConfig`的开发人员，您如何确切知道`@Autowired AccountRepository bean`的声明位置？它在代码中并不明确，这可能很好。请记住，Spring Tools for Eclipse提供的工具可以呈现显示所有内容如何连接的图表，这可能就是您所需要的。此外，您的Java IDE可以轻松找到`AccountRepository`类型的所有声明和使用，并快速向您显示返回该类型的`@Bean`方法的位置。如果这种模糊性不可接受，并且您希望在IDE中从一个`@Configuration`类直接导航到另一个`@Configuration`类，请考虑自动装配配置类本身。以下示例显示了如何执行此操作:
```java
@Configuration
public class ServiceConfig {
	@Autowired
	private RepositoryConfig repositoryConfig;

	@Bean
	public TransferService transferService() {
		// navigate 'through' the config class to the @Bean method!
		return new TransferServiceImpl(repositoryConfig.accountRepository());
	}
}
```
在前面的情况下，`AccountRepository`的定义是完全明确的。但是，`ServiceConfig`现在与`RepositoryConfig`紧密耦合。这就是权衡。通过使用基于接口或基于抽象类的 	`@Configuration`类，可以在一定程度上缓解这种紧密耦合。请考虑以下示例:
```java
@Configuration
public class ServiceConfig {
	@Autowired
	private RepositoryConfig repositoryConfig;
	@Bean
	public TransferService transferService() {
		return new TransferServiceImpl(repositoryConfig.accountRepository());
	}
}
@Configuration
public interface RepositoryConfig {
	@Bean
	AccountRepository accountRepository();
}
@Configuration
public class DefaultRepositoryConfig implements RepositoryConfig {
	@Bean
	public AccountRepository accountRepository() {
		return new JdbcAccountRepository(...);
	}
}
@Configuration
@Import({ServiceConfig.class, DefaultRepositoryConfig.class})  // import the concrete config!
public class SystemTestConfig {
	@Bean
	public DataSource dataSource() {
		// return DataSource
	}
}
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(SystemTestConfig.class);
	TransferService transferService = ctx.getBean(TransferService.class);
	transferService.transfer(100.00, "A123", "C456");
}
```
现在`ServiceConfig`与具体的`DefaultRepositoryConfig`松散耦合，并且内置的IDE工具仍然有用：您可以轻松获取`RepositoryConfig`实现的类型层次结构。这样，浏览 `@Configuration`类及其依赖项与浏览基于接口的代码的通常过程没有什么不同。
### 影响单例Bean的启动过程
如果您想影响某些单例bean的启动创建顺序，请考虑将其中一些bean声明为`@Lazy`，以便在首次访问时创建，而不是在启动时创建。`@DependsOn`强制首先初始化某些其他bean，确保在当前bean之前创建指定的bean，超出后者的直接依赖关系所暗示的范围。从 6.2 开始，有一个后台初始化选项`@Bean(bootstrap=BACKGROUND)`允许单独挑选特定的bean进行后台初始化，在上下文启动时覆盖每个此类bean的整个bean创建步骤。具有非延迟注入点的依赖bean自动等待bean实例完成。所有常规后台初始化都被强制在上下文启动结束时完成。只有另外标记为 `@Lazy`的bean才允许稍后完成(直到第一次实际访问)。后台初始化通常与依赖bean中的`@Lazy`或`ObjectProvider`注入点一起使用。否则，当需要提前注入实际的后台初始化bean 实例时，主引导线程将被阻塞。这种并发启动形式适用于单个bean：如果此类bean依赖于其他 bean，则需要已经初始化它们，要么简单地通过更早声明，要么通过`@DependsOn`在受影响 bean的后台初始化触发之前在主引导线程中强制初始化。必须声明一个`Executor`类型的`bootstrapExecutor`bean来完成后台初始化，否则后台初始化标记会被忽略。
### Conditionally Include `@Configuration` Classes or `@Bean` Methods
根据某些任意系统状态有条件地启用或禁用完整的`@Configuration`类甚至单个`@Bean`方法通常很有用。一个常见示例是使用`@Profile`注解，仅在Spring环境中启用了特定配置文件时激活bean(有关详细信息，请参阅[Bean定义环境文件](https://docs.spring.io/spring-framework/reference/core/beans/environment.html#beans-definition-profiles))。`@Profile`注解实际上是通过使用更灵活的注解`@Conditional`来实现的。`@Conditional`注解指示在注册`@Bean`之前应咨询的特定`org.springframework.context.annotation.Condition`实现。`Condition`接口的实现提供了一个返回true或false的`matches(…​)`方法。例如，以下代码显示了用于 `@Profile`的实际`Condition`实现：
```java
@Override
public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
	// Read the @Profile annotation attributes
	MultiValueMap<String, Object> attrs = metadata.getAllAnnotationAttributes(Profile.class.getName());
	if (attrs != null) {
		for (Object value : attrs.get("value")) {
			if (context.getEnvironment().matchesProfiles((String[]) value)) {
				return true;
			}
		}
		return false;
	}
	return true;
}
```
### 组合Java配置与XML配置
Spring的`@Configuration`类支持并非旨在完全替代Spring XML。某些工具(如Spring XML命名空间)仍然是配置容器的理想方式。在XML方便或必要的情况下，您可以选择使用例如 `ClassPathXmlApplicationContext`的XML配置方式实例化容器，或者使用`AnnotationConfigApplicationContext`的Java配置方式并使用`@ImportResource`注解根据需要导入部分XML配置的方式初始化容器。XML初始化Spring容器可以以一种特别的方式包含`@Configuration`配置类。例如，在使用Spring XML的大型现有代码库中，根据需要创建`@Configuration`类并在现有XML文件中包含它们会更容易。在本节后面，我们将介绍在这种以XML为中心的情况下使用`@Configuration`类的选项。请记住，`@Configuration`类最终是容器中的bean定义。在本系列示例中，我们创建一个名为`AppConfig`的`@Configuration`类，并将其作为`<bean/>`定义包含在`system-test-config.xml`中。由于 	`<context:annotation-config/>`已打开，因此容器会识别`@Configuration`注释并正确处理`AppConfig`中声明的`@Bean`方法。以下示例展示`AppConfig`配置类：
```java
@Configuration
public class AppConfig {
	@Autowired
	private DataSource dataSource;
	@Bean
	public AccountRepository accountRepository() {
		return new JdbcAccountRepository(dataSource);
	}
	@Bean
	public TransferService transferService() {
		return new TransferServiceImpl(accountRepository());
	}
}
```
下面是文件`system-test-config.xml`的部分内容
```xml
<beans>
	<!-- enable processing of annotations such as @Autowired and @Configuration -->
	<context:annotation-config/>
	<context:property-placeholder location="classpath:/com/acme/jdbc.properties"/>
	<bean class="com.acme.AppConfig"/>

	<bean class="org.springframework.jdbc.datasource.DriverManagerDataSource">
		<property name="url" value="${jdbc.url}"/>
		<property name="username" value="${jdbc.username}"/>
		<property name="password" value="${jdbc.password}"/>
	</bean>
</beans>
```
下面的例子展示了可能的`jdbc.properties`
```properties
jdbc.url=jdbc:hsqldb:hsql://localhost/xdb
jdbc.username=sa
jdbc.password=
```
初始化代码如下:
```java
public static void main(String[] args) {
	ApplicationContext ctx = new ClassPathXmlApplicationContext("classpath:/com/acme/system-test-config.xml");
	TransferService transferService = ctx.getBean(TransferService.class);
	// ...
}
```
在`system-test-config.xml`文件中，`AppConfig` `<bean/>`未声明id属性。没有必要声明ID属性，因为没有其他bean会引用它，并且不太可能通过名称从容器中显式获取它。同样，`DataSource`bean只会根据类型自动装配，因此并不严格要求显式bean id。由于`@Configuration`是使用元注解`@Component`修饰的，因此带有`@Configuration`注解的类自动成为组件扫描的候选对象。使用与上例中描述的相同场景，我们可以重新定义`system-test-config.xml`以利用组件扫描。请注意，在这种情况下，我们不需要明确声明 `<context:annotation-config/>`，因为`<context:component-scan/>`启用了相同的功能。以下示例显示了修改后的`system-test-config.xml`文件:
```xml
<beans>
	<!-- picks up and registers AppConfig as a bean definition -->
	<context:component-scan base-package="com.acme"/>

	<context:property-placeholder location="classpath:/com/acme/jdbc.properties"/>

	<bean class="org.springframework.jdbc.datasource.DriverManagerDataSource">
		<property name="url" value="${jdbc.url}"/>
		<property name="username" value="${jdbc.username}"/>
		<property name="password" value="${jdbc.password}"/>
	</bean>
</beans>
```
在以`@Configuration`类为主要容器配置机制的应用中，可能仍需要使用至少一些XML。在这种情况下，您可以使用`@ImportResource`并仅定义所需的XML。这样做可以实现以Java为中心的容器配置方法，并将XML配置保持在最低限度。以下示例(包括配置类、定义bean的XML文件、属性文件和`main()`方法)显示了如何使用`@ImportResource`注解来实现根据需要使用 XML配置
```java
@Configuration
@ImportResource("classpath:/com/acme/properties-config.xml")
public class AppConfig {
	@Value("${jdbc.url}")
	private String url;
	@Value("${jdbc.username}")
	private String username;
	@Value("${jdbc.password}")
	private String password;
	@Bean
	public DataSource dataSource() {
		return new DriverManagerDataSource(url, username, password);
	}
	@Bean
	public AccountRepository accountRepository(DataSource dataSource) {
		return new JdbcAccountRepository(dataSource);
	}
	@Bean
	public TransferService transferService(AccountRepository accountRepository) {
		return new TransferServiceImpl(accountRepository);
	}
}
```
```xml
<beans>
	<context:property-placeholder location="classpath:/com/acme/jdbc.properties"/>
</beans>
```
```properties
jdbc.url=jdbc:hsqldb:hsql://localhost/xdb
jdbc.username=sa
jdbc.password=
```
```java
public static void main(String[] args) {
	ApplicationContext ctx = new AnnotationConfigApplicationContext(AppConfig.class);
	TransferService transferService = ctx.getBean(TransferService.class);
	// ...
}
```
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
