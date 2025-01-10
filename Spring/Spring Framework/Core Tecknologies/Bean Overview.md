Spring IoC容器管理一个或者多个Bean。Spring IoC容器通过配置元数据生成所有的bean后，容器会存储每个bean的定义，使用`BeanDefinition`对象表示，`BeanDefinition`包含以下的元数据：
- Bean的实现类class全限定类名，也就是Classpath下的路径名
- Bean行为配置元素，表示bean在容器内的状态，比如scope、生命周期回调方法等；
- Bean的依赖信息也就是对其他Bean的引用，这些引用也叫做协作者或者依赖
- 新创建对象时需要设置的其他配置设置，比如一个管理连接池的Bean中使用的pool的大小、连接数等信息

这些元数据会被翻译成组成`BeanDefinition`的一组属性，下面的表格描述了这些属性
|**Property**|**Explained in**|
|:---|:---|
|Class|[Instantiating Beans](https://docs.spring.io/spring-framework/reference/core/beans/definition.html#beans-factory-class)|
|Name|[Naming Beans](https://docs.spring.io/spring-framework/reference/core/beans/definition.html#beans-beanname)|
|Scope|[Bean Scopes](https://docs.spring.io/spring-framework/reference/core/beans/factory-scopes.html)|
|Constructor arguments|[Dependency Injection](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)|
|Properties|[Dependency Injection](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)|
|Autowiring mode|[Autowiring Collaborators](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-autowire.html)|
|Lazy initiallization mode|[Lazy-initialized Beans](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-lazy-init.html)|
|Initialization method|[Initialization Callbacks](https://docs.spring.io/spring-framework/reference/core/beans/factory-nature.html#beans-factory-lifecycle-initializingbean)|
|Destruction method|[Destruction Callbacks](https://docs.spring.io/spring-framework/reference/core/beans/factory-nature.html#beans-factory-lifecycle-disposablebean)|

除了管理通过配置元数据的方式生成bean外，容器外创建的对象也可以向容器注册，通过`ApplicationContext`的`getBeanFactory()`方法获取`BeanFactory`，返回的是`DefaultListableBeanFactory`实现，然后通过`DefaultListableBeanFactory`的`registerSingleton(…)`或者`registerBeanDefinition(..)`方法注册。但是大多数情况，应用只需要常规的配置元数据的方式定义的bean就可以了。需要尽早注册Bean元数据和手动提供的单例实例，以便容器在自动装配和其他自省步骤中正确引用它们。虽然在某种程度上支持覆盖现有元数据和现有单例实例，但官方不支持在运行时注册新bean，这可能导致并发访问异常、bean容器中的状态不一致等
# Overriding Beans
Bean覆盖发生在Bean使用已经存在的标识符注册的场景。Bean覆盖可能在未来的版本中废弃。想要禁用Bean覆盖，可以在`ApplicationContext` refresh之前设置它的`allowBeanDefinitionOverriding=false`，此时如果遇到bean覆盖会抛出异常。默认情况下，容器会在覆盖发生时打印`INFO`级别的日志，你可以据此调整你的配置。如果你使用Java配置，`@Bean`方法默认会覆盖扫描到的同样类型的Bean对象，这也就意味着容器会调用`@Bean`工厂方法而不是预先生命的bean class的构造函数。在测试场景使用覆盖bean是很方便的。
# 命名Bean
每个Bean都有一个或者多个标识符，这些标识符在容器内必须唯一，用于映射bean，通常bean只有一个标识符，如果需要多个，其他的标识符就是别名，XML配置元数据方式使用`id`或者`name`设置Bean的标识符，在Spring 3.1以前，id属性被定义为一个`xsd:ID`类型，所以包含的字符有限制，3.1版本后，定义为`xsd:string`类型，没有字符限制，id名字的唯一性是由容器保证的而不是XML解析器。如果bean需要别名，那么使用`name`属性指定，别名可以有多个，通过逗号、冒号或者其他空白字符分隔；如果不明确指定id或者name，那么容器会为Bean生成一个唯一的名字，当使用名字引用bean的时候，必须提供一个名字，通常使用[内部bean](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-properties-detailed.html#beans-inner-beans)或者[自动注入](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-autowire.html)时不用明确的指定bean的名字。Bean的命名约定使用标准的Java规范，也就是驼峰格式。当使用组件扫描时，Spring为未命名组件生成Bean的名字，只是将类名的首字母小写，如果连续的首字母都是大写，则保留原始格式。
## Aliasing a Bean outside the Bean Definition
在一个Bean定义本身中，你可以提供多个名字，有时候在Bean定义的地方定义所有名字还不够，可能某时候想要在别的地方定义别名，这在大型系统中很常见，配置通常会分散在不同的子系统中。每个子系统都有自己的Bean对象集合。在XML配置元数据中，你可以使用`<alias/>`实现这个功能。比如下面:
```xml
<alias name="fromName" alias="toName"/>
```
# 实例化Bean
Bean Definition本质上是是创建对象的配方，当向容器请求某个名字的Bean时，容器会寻找配方并根据配方中的配置元数据生成或者返回一个实例对象。如果你使用XML配置方式，`<bean>`标签里面的class属性就是要被实例化的对象类型，也是`BeanDrfinition`里面的`Class`属性，通常class是必须要要指定的，除非使用[实例工厂方法](https://docs.spring.io/spring-framework/reference/core/beans/definition.html#beans-factory-class-instance-factory-method)或者[Bean Defintion继承](https://docs.spring.io/spring-framework/reference/core/beans/child-bean-definitions.html)，你会在2种情况下使用到`BeanDefinition`的`Class`属性：
- 指定Bean的class类型，用于容器直接通过反射的方式调用构造函数生成实例的场景，等价于`new`操作符
- 指定包含一个`static`工厂方法class类型，这个工厂方法被调用来创建对象实例，在一些情况下，容器会调用静态工厂方法来生成实例。工厂方法返回的对象类型可以是工厂类本身或者是其他类型

如果想为嵌套类配置Bean，需要使用嵌套类的源名或者二进制名字。比如如果你在`com.example`包下有一个`SomeThing`类，这个类有一个静态的嵌套类`OtherThing`，嵌套类会使用`$`或者`.`分割，所以bean定义中的class属性会是`com.example.SomeThing$OtherThing`或者`com.example.SomeThing.OtherThing`。
## Instantiation with a Constructor
传统的使用构造方法生成Bean的方式不限任何类型，不需要任何特定的操作，只需要提供构造器即可；当您通过构造方法创建bean时，所有普通类都可以被Spring使用并兼容。也就是说，正在开发的类不需要实现任何特定的接口或以特定的方式进行编码。只需指定bean类就足够了。但是，根据使用的IoC类型，您可能需要一个默认(空)构造函数。Spring IoC容器几乎可以管理您希望它管理的任何类。它不仅限于管理真正的`JavaBean`。大多数Spring用户更喜欢只有默认(无参数)构造函数的`JavaBean`s, 这些`JavaBean`具有合适的`setter`和`getter`，其中的属性来自容器中的属性。您还可以在容器中管理更多奇特的非bean样式的类实例。例如，如果您需要使用绝对不符合JavaBean规范的传统连接池，那么Spring也可以管理它。使用XML配置元数据的方式
```xml
<bean id="exampleBean" class="examples.ExampleBean"/>
<bean name="anotherExample" class="examples.ExampleBeanTwo"/>
```
更多的关于提供参数给构造函数以及在对象创建后设置属性的机制，参考[Injecting Dependencies](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-collaborators.html)，如果只有有参数的构造函数，容器会在重载的构造函数中选择一个合适的构造函数，也就是说为了避免混淆，构造函数需要尽可能比较明确。
## 使用静态工厂方法实例化
当使用静态工厂方法的方式创建Bean时，class属性是一个包含静态工厂方法的类，factory-method属性指定工厂方法名，调用这个方法可以返回对象，后续与通过构造函数方式创建的对象处理过程相同。这种使用方式适用于处理遗留历史代码。下面的例子描述了通过工厂方法的方式创建bean，定义没有指定返回对象的类型，那么返回的对象的类型就是工厂方法所在的class类型。在这个例子中`createInstance()`方法必须是静态的。
```xml
<bean id="clientService"
	class="examples.ClientService"
	factory-method="createInstance"/>
```
```java
public class ClientService {
	private static ClientService clientService = new ClientService();
	private ClientService() {}

	public static ClientService createInstance() {
		return clientService;
	}
}
```
关于为工厂方法提供参数以及设置对象的属性的细节，可以参考[Dependencies and Configuration in Detail](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-properties-detailed.html)。如果工厂方法有参数，容易会在重载的工厂方法中选择一个最合适的，最好不要让工厂方法的参数等产生混淆，那么就会选择失败。
## 使用实例(对象)工厂方法实例化
与静态工厂方法实例化方式类似，实例工厂方法调用一个容器中已存在的bean的成员方法来创建新的bean，不要指定class属性，`factory-bean`属性指定工厂bean的名字，`factory-method`指定工厂方法：
```xml
<!-- the factory bean, which contains a method called createClientServiceInstance() -->
<bean id="serviceLocator" class="examples.DefaultServiceLocator">
	<!-- inject any dependencies required by this locator bean -->
</bean>

<!-- the bean to be created via the factory bean -->
<bean id="clientService"
	factory-bean="serviceLocator"
	factory-method="createClientServiceInstance"/>
```
类代码:
```java
public class DefaultServiceLocator {

	private static ClientService clientService = new ClientServiceImpl();

	public ClientService createClientServiceInstance() {
		return clientService;
	}
}
```
工厂类可以持有多个工厂方法，比如
```xml
<bean id="serviceLocator" class="examples.DefaultServiceLocator">
	<!-- inject any dependencies required by this locator bean -->
</bean>

<bean id="clientService"
	factory-bean="serviceLocator"
	factory-method="createClientServiceInstance"/>

<bean id="accountService"
	factory-bean="serviceLocator"
	factory-method="createAccountServiceInstance"/>
```
相应的类
```java
public class DefaultServiceLocator {

	private static ClientService clientService = new ClientServiceImpl();

	private static AccountService accountService = new AccountServiceImpl();

	public ClientService createClientServiceInstance() {
		return clientService;
	}

	public AccountService createAccountServiceInstance() {
		return accountService;
	}
}
```
工厂Bean本身可以被容器管理病通过DI来配置。在Spring文档中，`factory bean`指的是Spring容器中的一个bean，这个bean可以通过成员方法或者静态工厂方法创建对象，`FactoryBean`指的是Spring的`FactoryBean`接口的实现类。
## Determining a Bean's Runtime Type
确定特定bean的运行时类型并非易事。bean元数据定义中的class属性只是一个初始类引用，可能是声明的工厂方法所在的类或是`FactoryBean`实现类(可能会生成一个不同类型的Bean)，这2种情况都会生成任意类型的Bean，或者在使用实例工厂方法的情况下也会生成任意类型的Bean。此外，AOP代理可以用基于接口的代理方式包装一个bean实例，这会因此隐藏目标bean的真正的实际类型，只会暴露其接口类型。查找特定bean的实际运行时类型的推荐方法是`BeanFactory.getType`。这个方法将所有上述情况都考虑在内，并返回使用相同的Bean名称调用`BeanFactory.getBean`返回的对象的类型