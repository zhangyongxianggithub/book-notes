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
Bean本质上是定义是创建对象实例的配方，当向容器请求某个名字的Bean时，容器会寻找配方并根据配方的定义，生成或者返回一个实例对象。
<bean>标签里面的class属性就是BeanDrfinition里面的Class属性，指定了生成实例的类型，通常class是必须要要指定的，除非使用工厂方法或者Bean Defintion继承，你会在2种情况下使用到BeanDefinition的Class属性：
用于指定Bean类型，用于容器通过反射的方式调用构造函数生成实例，等价与new；
用于指定包含一个static工厂方法的类型，这个工厂方法被调用来创建对象实例，在一些情况下，容器会调用静态工厂方法来生成实例。工厂方法返回的对象的类型可以是工厂类本身或者是其他类。
如果想为嵌套类配置Bean，需要使用嵌套类的源名或者二进制名字，Class里面如果是静态嵌套类的话要使用$符号指定路径，例如，如果您在 com.example包中有一个名为SomeThing的类，并且此SomeThing类有一个名为OtherThing的静态嵌套类，则它们可以用美元符号 ($) 或点 (.) 分隔。所以 bean定义中class属性的值是com.example.SomeThing$OtherThing 或 com.example.SomeThing.OtherThing。
(1)Instantiation with a Constructor
传统的使用构造方法生成Bean的方式不限任何类型，不需要任何特定的操作，只需要提供构造器即可；当您通过构造方法创建bean时，所有普通类都可以被Spring使用并兼容。也就是说，正在开发的类不需要实现任何特定的接口或以特定的方式进行编码。只需指定bean类就足够了。但是，根据您用于该特定bean的IoC类型，您可能需要一个默认（空）构造函数。
Spring IoC容器几乎可以管理您希望它管理的任何类。 它不仅限于管理真正的 JavaBean。大多数 Spring 用户更喜欢只有默认（无参数）构造函数以及根据容器中的属性建模的适当的setter和getter的实际JavaBeans。您还可以在容器中拥有更多奇特的非bean样式类。例如，如果您需要使用绝对不符合 JavaBean规范的遗留连接池，那么Spring也可以管理它。
(2)使用静态工厂方法实例化
当使用静态工厂方法的方式定义Bean时，class制定了包含静态工厂方法的class类型，factory-method属性指定工厂方法名，调用这个方法可以返回对象，下面的例子描述了通过工厂方法的方式创建bean，定义没有指定返回对象的类型，那么返回的对象的类型就是工厂方法所在的class类型。

类代码如下：

(3)使用实例工厂方法实例化
与静态你工厂方法实例化类似，实例工厂方法调用一个容器中已存在的bean的成员方法来创建新的bean，不要指定class属性，factory-bean属性指定工厂bean的名字，factory-method指定工厂方法：

类代码：

在Spring文档中，factory bean指的是Spring容器中的一个bean，这个bean可以通过成员方法或者静态工厂方法创建对象，FactoryBean指的是Spring FactoryBean接口的实现类。
确定特定bean的运行时类型并非易事。bean元数据定义中的class属性只是一个初始类引用，可能是声明的工厂方法所在的类或是FactoryBean类，这2种情况都会生成任意类型的Bean，或者在使用实例工厂方法的情况下都没有设置class属性。此外，AOP代理可以用基于接口的代理方式包装一个bean实例，这会因此隐藏目标bean的真正的实际类型。
查找特定bean的实际运行时类型的推荐方法是 BeanFactory.getType 。这将所有上述情况都考虑在内，并返回 BeanFactory.getBean 调用将为相同的 bean名称返回的对象类型