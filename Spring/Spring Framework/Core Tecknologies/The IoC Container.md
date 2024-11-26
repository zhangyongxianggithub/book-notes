# 基于Java的容器配置
1.1.12.1 @Bean&@Configuration
@Bean说明方法生成一个Spring管理的Bean对象，@Configuration修饰类，表明这个类的主要目的是作为Bean定义的源文件管理，更多的，@Configuration类让内部的Bean依赖关系通过调用方法的形式得到实现。
当@Bean方法不是在@Configuation类里面声明时，他们会作为一个简化模式处理；根据包含类的类型不同，@Bean得到的处理也是不同的，在@Configuration类里面得到的处理，@Component里面得到的处理少些，在普通的类里面定义的@Bean得到的处理最少；不像在@Configuration类中，lite模式的@Bean不能声明内部bean依赖；反而，他们可能会操作包含类的内部的状态，或者他们声明的参数；这样的@Bean方法不应该调用其他的@Bean方法；每一个这样的方法只是一个产生特定Bean引用的工厂；没有任何的特别的运行时语义；比较好的地方时，在运行时不会使用CGLIB的方式子类化，所以类的类型可以不是final的，在多数的场景下，@Bean方法都是生命在@Configuration注解修饰的类中，确保Bean是full模式的，还可以参与到容器的生命周期的管理中；这阻止了@Bean方法可能会被后续的重复调用；帮助减少了一些隐藏BUG的出现。
1.1.12.2 使用AnnotationConfigApplicationContext初始化容器
AnnotationConfigApplicationContext能处理@Configuration、@Component、与JSR330注解修改的类。

可以调用register()方法的方式配置；

在输入的class类中@Configuration类加上@ComponentScan注解，可以开启组件扫描。也可以直接调用scan方法。
AnnotationConfigApplicationContext在web下的变体是AnnotationConfigWebApplicationContext；可以使用这个实现配置ContextLoaderListener、与servlet的参数。
1.1.12.3 @Bean注解的使用
@Bean为ApplicationContext声明一个Bean；常常使用在@Configuration类与@Component类中；@Bean修饰的方法可以有任意个数的参数；@Bean定义的类指出生命周期回调接口，支持@PostConstruct与@preDestry；支持实现了了InitializingBean、DisposableBean、Lifecycle接口的回调处理、支持任何的*Aware接口的处理。也支持指定的生命周期回调。也可以使用@Scope装饰；通过@Bean的name属性改变bean的名字，如果name是一个数组，那么都是bean的别名；使用@Description描述Bean的用途。
1.1.12.4 使用@Configuration注解
@Configuration是一个类级别上的注解，用来表示这个对象是bean定义的源。直接使用方法调用的方式表示Bean的依赖关系，这种调用表示依赖的行为仅限于@Bean方法是在Configuration里面定义的，定义在别的种类的文件中是没有这种表示的。
Lookup方法注入：主要用于单例Bean依赖多例bean的情况，需要在单例Bean里面设置一个获取单例Bean对象的抽象方法，

然后创建单例Bean

1.1.12.5 配置组合
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