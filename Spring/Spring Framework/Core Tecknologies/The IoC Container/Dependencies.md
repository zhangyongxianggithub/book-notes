一个传统的企业级应用不可能只有一个对象或者按照Spring方法只有一个Bean，即便最简单的应用也会有大量的对象还有之间的交互协作来提供用户需要的功能。下一节将介绍如何从定义多个独立的bean定义转变为一个完整实现的应用程序，这个应用中的对象互相协作实现功能目标。
# 依赖注入
依赖注入也叫做DI，就是定义了依赖的对象。有3种定义依赖的方式：构造函数参数、工厂方法参数与十六对象的成员属性。当创建Bean的时候容器注入需要的依赖。这个过程是Bean本身负责实例化依赖(直接通过依赖的构造函数或者Service Locator模式)的反转，也就是控制反转。使用DI思想编写的代码更整洁。解藕性更好。对象不需要自己寻找依赖，不需要知晓依赖的位置或者Class实现。因此，类更容易测试尤其是依赖是接口或者抽象类的情况。允许在单元测试中使用stub或者mock实现。
## Constructor-based Dependency Injection
容器调用class的对应参数的构造方法，每一个参数都代表一个依赖，这等同与调用相同参数的静态工厂方法，他们2个都会产生对象。下面的例子是一个使用构造函数注入的例子：
```java
public class SimpleMovieLister {

	// the SimpleMovieLister has a dependency on a MovieFinder
	private final MovieFinder movieFinder;

	// a constructor so that the Spring container can inject a MovieFinder
	public SimpleMovieLister(MovieFinder movieFinder) {
		this.movieFinder = movieFinder;
	}
	// business logic that actually uses the injected MovieFinder is omitted...
}
```
这个类没什么特别的，就是个POJO，不依赖容器相关的接口、类或者注解。
### 构造函数参数解析
构造函数参数匹配使用的是参数的类型。如果参数不存在可能的混淆，按照定义的参数顺序提供实例化需要参数。比如下面的类:
```java
package x.y;
public class ThingOne {
	public ThingOne(ThingTwo thingTwo, ThingThree thingThree) {
		// ...
	}
}
```
假设`ThingTwo`与`ThingThree`没有继承关系，则没有可能的混淆。那么下面的配置可以正常运行，你不需要明确指出`<constructor-arg/>`元素中的构造函数参数位置索引与参数类型
```xml
<beans>
	<bean id="beanOne" class="x.y.ThingOne">
		<constructor-arg ref="beanTwo"/>
		<constructor-arg ref="beanThree"/>
	</bean>

	<bean id="beanTwo" class="x.y.ThingTwo"/>

	<bean id="beanThree" class="x.y.ThingThree"/>
</beans>
```
当引用另外一个Bean时，它的类型是已知的，因此匹配得以执行。当使用简单类型时，比如`<value>true</value>`，Spring不能决定值的类型，所以不能根据类型匹配。考虑系main的类
```java
package examples;
public class ExampleBean {
	// Number of years to calculate the Ultimate Answer
	private final int years;
	// The Answer to Life, the Universe, and Everything
	private final String ultimateAnswer;
	public ExampleBean(int years, String ultimateAnswer) {
		this.years = years;
		this.ultimateAnswer = ultimateAnswer;
	}
}
```
在这个场景下，你可以通过`type`属性指定构造函数参数的类型来执行类型匹配，比如
```xml
<bean id="exampleBean" class="examples.ExampleBean">
	<constructor-arg type="int" value="7500000"/>
	<constructor-arg type="java.lang.String" value="42"/>
</bean>
```
也可以使用`index`属性明确指定构造函数参数位置索引比如:
```xml
<bean id="exampleBean" class="examples.ExampleBean">
	<constructor-arg index="0" value="7500000"/>
	<constructor-arg index="1" value="42"/>
</bean>
```
指定位置索引可以解决多个同类型参数的混淆的问题。位置索引是0-based。也可以使用构造函数参数名来匹配
```xml
<bean id="exampleBean" class="examples.ExampleBean">
	<constructor-arg name="years" value="7500000"/>
	<constructor-arg name="ultimateAnswer" value="42"/>
</bean>
```
使用参数名字的方式，编译时必须开启`-parameters`标志，因为字节码文件会丢失方法的参数名字信息，开启`-parameters`编译后则不会，Spring能从字节码中找到参数名。或者使用`@ConstructorProperties`注解指定参数名。
```java
package examples;
public class ExampleBean {
	// Fields omitted
	@ConstructorProperties({"years", "ultimateAnswer"})
	public ExampleBean(int years, String ultimateAnswer) {
		this.years = years;
		this.ultimateAnswer = ultimateAnswer;
	}
}
```
## 基于setter方法的依赖注入
这种方法是通过容器调用bean的setter方法来完成的，此时bean通常是使用无参的构造函数或者无参的静态工厂方法实例化出来的。下面的类是一个纯setter依赖注入的例子
```java
public class SimpleMovieLister {
	// the SimpleMovieLister has a dependency on the MovieFinder
	private MovieFinder movieFinder;
	// a setter method so that the Spring container can inject a MovieFinder
	public void setMovieFinder(MovieFinder movieFinder) {
		this.movieFinder = movieFinder;
	}
	// business logic that actually uses the injected MovieFinder is omitted...
}
```
`ApplicationContext`支持基于构造函数的依赖注入与基于setter方法的依赖注入，也支持2者混合。你可以配置`BeanDefinition`形式的依赖，与`PropertyEditor`实例组合使用，将属性从一种格式转换为另一种格式。但是大多数的Spring用户不会直接使用到这些类，它是一种编程式的方式不是声明式的方式，通常较少使用。常用的做法是XML配置、注解组件(`@Component`)、Java配置中的`@Configuration`与`@Bean`。这些源配置内部被转换成了BeanDefinition的实例并用来加载整个Spring IoC容器实例。2种DI方式可以混合使用，最佳实践是，必要依赖使用构造函数注入，可选依赖使用setter方法注入或者配置方法。在setter方法上使用`@Autowired`注解也会让属性称为必须依赖，使用构造函数注入加入参数校验更好。Spring团队提倡使用构造函数注入，因为可以让你拥有不可变对象的应用组件并且确保所有的必要的依赖都不是null。更多的，构造函数注入组件的使用者不论何时拿到的都是一个完全初始化好的对象。另一方面，构造函数参数太多也不好，意味着类可能具有太多的职责应该重构并进行合适的关注点分离。Setter注入应该主要用于可选依赖(已经具有河流的默认值的依赖)注入，然而，可能在每个使用依赖的地方都要做non-null检测，setter注入的好处是对象可以重配置或者在后面某个时刻重新注入。所以特别适用于通过JMX MBeans的管理。使用对特定类最有意义的DI方式。有时，在处理您没有源代码的第三方类时，就必须使用某种单一的方式了。例如，如果第三方类不公开任何setter方法，则构造函数注入可能是唯一可用的DI形式。
## 依赖解析过程
容器解析依赖的过程如下:
- `ApplicationContext`被初始化，使用的配置元数据，配置元数据可以是XML、Java代码或者注解
- 对于每个Bean，依赖使用属性、构造函数参数或者静态工厂方法参数表示，当创建Bean时这些依赖被提供给Bean
- 依赖是一个普通值的定义或者是对容器中其他Bean的引用
- 普通值的依赖会呗转换成依赖本身的类型，默认情况下Spring把字符串格式的值转换成内置类型，比如int、long、String、boolean等

Spring容器创建后会校验每个Bean的配置，直到Bean创建后才会设置Bean的属性。容器创建时，就会创建单例Bean或者设置为预初始化的Bean。Scope定义在[Bean Scopes](https://docs.spring.io/spring-framework/reference/core/beans/factory-scopes.html)。其他scope的bean都是第一次向容器请求的时候才初始化，一个Bean的初始化会造成很多Bean的实例化操作，形成一个依赖关系图。请注意，这些依赖项之间的解析不匹配可能会在稍后出现，即在第一次创建受影响的bean时。如果使用基于构造函数的依赖注入方式，可能会遇到循环依赖，此时Spring容器会抛出`BeanCurrentlyInCreationException`。一种可行的解决办法是编辑源代码并使用setter配置。开发者可以相信Spring会做出正确的决定，Spring会在容器加载阶段检测配置问题比如引用不存在的Bean或者循环依赖，也就是说，当创建对象失败或者创建对象的依赖失败时，Spring容器会在稍后抛出异常，比如，Bean因此缺少某些属性或者属性无效等抛出异常，这种配置问题的延迟性时`ApplicationContext`默认就预先实例化singleton Bean的原因。在实际需要这些bean之前，需要花费一些前期时间和内存来创建它们，因此您会在创建`ApplicationContext`时发现配置问题，而不是稍后发现。您仍然可以覆盖此默认行为，以便单例bean延迟初始化，而不是急切地预先实例化。如果不存在循环依赖，每个Bean在被注入前都会得到完整的配置，也就是说，如果A依赖B，那么B在A之前得到完整配置与实例化。
## 依赖注入的例子
下面的例子使用基于XML的配置元数据用于setter注入
```xml
<bean id="exampleBean" class="examples.ExampleBean">
	<!-- setter injection using the nested ref element -->
	<property name="beanOne">
		<ref bean="anotherExampleBean"/>
	</property>

	<!-- setter injection using the neater ref attribute -->
	<property name="beanTwo" ref="yetAnotherBean"/>
	<property name="integerProperty" value="1"/>
</bean>

<bean id="anotherExampleBean" class="examples.AnotherBean"/>
<bean id="yetAnotherBean" class="examples.YetAnotherBean"/>
```
下面是用到的类
```java
public class ExampleBean {

	private AnotherBean beanOne;

	private YetAnotherBean beanTwo;

	private int i;

	public void setBeanOne(AnotherBean beanOne) {
		this.beanOne = beanOne;
	}

	public void setBeanTwo(YetAnotherBean beanTwo) {
		this.beanTwo = beanTwo;
	}

	public void setIntegerProperty(int i) {
		this.i = i;
	}
}
```
在前面的例子中使用构造函数注入
```xml
<bean id="exampleBean" class="examples.ExampleBean">
	<!-- constructor injection using the nested ref element -->
	<constructor-arg>
		<ref bean="anotherExampleBean"/>
	</constructor-arg>

	<!-- constructor injection using the neater ref attribute -->
	<constructor-arg ref="yetAnotherBean"/>

	<constructor-arg type="int" value="1"/>
</bean>

<bean id="anotherExampleBean" class="examples.AnotherBean"/>
<bean id="yetAnotherBean" class="examples.YetAnotherBean"/>
```
相应的类
```java
public class ExampleBean {

	private AnotherBean beanOne;

	private YetAnotherBean beanTwo;

	private int i;

	public ExampleBean(
		AnotherBean anotherBean, YetAnotherBean yetAnotherBean, int i) {
		this.beanOne = anotherBean;
		this.beanTwo = yetAnotherBean;
		this.i = i;
	}
}
```
# 依赖配置的细节
正如前面章节提到的，Bean的属性或者构造函数的参数可以引用其他bean或者是内连的简单值。Spring的XML配置元数据支持子元素`<property/>`与`<constructor-arg/>`，可以用于依赖注入。
## 简单值注入
简单值就是基本类型与其包装类型，还包括`String`等。其中的value属性指定了值的可读表示形式。字符串的[conversion service](https://docs.spring.io/spring-framework/reference/core/validation/convert.html#core-convert-ConversionService-API)用来将这些值从字符串转换为属性或者参数的实际类型。下面是一个例子
```xml
<bean id="myDataSource" class="org.apache.commons.dbcp.BasicDataSource" destroy-method="close">
	<!-- results in a setDriverClassName(String) call -->
	<property name="driverClassName" value="com.mysql.jdbc.Driver"/>
	<property name="url" value="jdbc:mysql://localhost:3306/mydb"/>
	<property name="username" value="root"/>
	<property name="password" value="misterkaoli"/>
</bean>
```
还可以使用命名空间[p-namespace](https://docs.spring.io/spring-framework/reference/core/beans/dependencies/factory-properties-detailed.html#beans-p-namespace)的方式配置依赖：
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:p="http://www.springframework.org/schema/p"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
	https://www.springframework.org/schema/beans/spring-beans.xsd">

	<bean id="myDataSource" class="org.apache.commons.dbcp.BasicDataSource"
		destroy-method="close"
		p:driverClassName="com.mysql.jdbc.Driver"
		p:url="jdbc:mysql://localhost:3306/mydb"
		p:username="root"
		p:password="misterkaoli"/>
</beans>
```
这种方式更简洁，但是这种方式只有在运行时才能发现编写错误而不是设计时，建议使用IDE的自动补全与检查机制。如果配置的依赖是`java.util.Properties`类型的，可以直接使用以下方式配置：
```xml
<bean id="mappings"
	class="org.springframework.context.support.PropertySourcesPlaceholderConfigurer">

	<!-- typed as a java.util.Properties -->
	<property name="properties">
		<value>
			jdbc.driver.className=com.mysql.jdbc.Driver
			jdbc.url=jdbc:mysql://localhost:3306/mydb
		</value>
	</property>
</bean>
```
Spring容器使用JavaBeans `PropertyEditor`机制把`<value>`元素里面的文本转换为`java.util.Properties`，这个方式很便捷，是少数的几个Spring团队使用内嵌的`<value/>`而不是value属性的地方之一。
### idref元素
idref
引用bean可以使用`<idRef>`元素，并且这个元素比传统的设值注入的方式多了错误检测功能，可以用在`<constructor-arg/>`与`<property/>`元素中.
```xml
<bean id="theTargetBean" class="..."/>

<bean id="theClientBean" class="...">
	<property name="targetName">
		<idref bean="theTargetBean"/>
	</property>
</bean>
```
完全等价于下面的定义片段
```xml
<bean id="theTargetBean" class="..." />
<bean id="theClientBean" class="...">
	<property name="targetName" ref="theTargetBean"/>
</bean>
```
第一种形式比第二种更好，因为idref可以让容器在开发阶段就检测引用的Bean的存在性。第二种形式，没有校验，书写错误只能在运行阶段发现。如果`client`是一个prototype bean，那么发现错误的时间可能会更晚。
## 引用其他Bean(协作者)
ref元素是`<constructor-arg/>`与`<property/>`元素的最终元素，设置的值引用容器管理的其他Bean。引用的bean是要设置属性的bean的依赖，在设置属性之前会根据需要进行初始化。所有引用最终都是对另一个对象的引用。范围和验证取决于您是否通过 bean或parent属性指定另一个对象的ID或名称。通过`<ref/>`元素的bean属性指定目标Bean，可以是同一个容器内的任意Bean，也可以是parent容器的。bean属性的值可以是目标Bean的id或者名字。下面是一个例子
```xml
<ref bean="someBean"/>
```
通过parent属性指定目标bean会引用parent容器上的一个Bean，parent属性值可以是目标bean的id或者名字。下面是一个例子
```xml
<!-- in the parent context -->
<bean id="accountService" class="com.something.SimpleAccountService">
	<!-- insert dependencies as required here -->
</bean>
<!-- in the child (descendant) context, bean name is the same as the parent bean -->
<bean id="accountService"
	class="org.springframework.aop.framework.ProxyFactoryBean">
	<property name="target">
		<ref parent="accountService"/> <!-- notice how we refer to the parent bean -->
	</property>
	<!-- insert other configuration and dependencies as required here -->
</bean>
```
## 内部Bean
`<property/>`与`<constructor-arg/>`元素中的`<bean/>`定义了一个内部bean，如下面的例子所示:
```xml
<bean id="outer" class="...">
	<!-- instead of using a reference to a target bean, simply define the target bean inline -->
	<property name="target">
		<bean class="com.example.Person"> <!-- this is the inner bean -->
			<property name="name" value="Fiona Apple"/>
			<property name="age" value="25"/>
		</bean>
	</property>
</bean>
```
一个内部Bean定义不需要定义ID或者名字，即便指定了，容器也不会使用它作为标识符。容器也会忽略`scope`标志，因为内部Bean始终是匿名的并且只在外部Bean创建时创建。不能独立的访问内部Bean，也不能注入到别的bean中。作为一种特殊情况，可以从自定义scope接收销毁回调。例如，对于包含在单例bean中的一个request-scope内部bean。内部bean实例的创建与外部bean相关联，但销毁回调会被request scope的生命周期调用。这不是常见的情况。内部bean通常只是共享外部bean的scope。
## Collections
`<list/>`, `<set/>`, `<map/>`, `<props/>`设置Java集合属性的参数值，下面是一个例子
```xml
<bean id="moreComplexObject" class="example.ComplexObject">
	<!-- results in a setAdminEmails(java.util.Properties) call -->
	<property name="adminEmails">
		<props>
			<prop key="administrator">administrator@example.org</prop>
			<prop key="support">support@example.org</prop>
			<prop key="development">development@example.org</prop>
		</props>
	</property>
	<!-- results in a setSomeList(java.util.List) call -->
	<property name="someList">
		<list>
			<value>a list element followed by a reference</value>
			<ref bean="myDataSource" />
		</list>
	</property>
	<!-- results in a setSomeMap(java.util.Map) call -->
	<property name="someMap">
		<map>
			<entry key="an entry" value="just some string"/>
			<entry key="a ref" value-ref="myDataSource"/>
		</map>
	</property>
	<!-- results in a setSomeSet(java.util.Set) call -->
	<property name="someSet">
		<set>
			<value>just some string</value>
			<ref bean="myDataSource" />
		</set>
	</property>
</bean>
```
集合元素的Value可以嵌套其他bean或者引用对象或者其他集合等。也支持合并集合，开发者可以定义parent的`<list/>`, `<set/>`, `<map/>`, `<props/>`元素，然后定义child `<list/>`, `<set/>`, `<map/>`, `<props/>`元素并继承parent集合元素可以覆盖继承过来的值。child集合时2者的混合，下面是一个例子
```xml
<beans>
	<bean id="parent" abstract="true" class="example.ComplexObject">
		<property name="adminEmails">
			<props>
				<prop key="administrator">administrator@example.com</prop>
				<prop key="support">support@example.com</prop>
			</props>
		</property>
	</bean>
	<bean id="child" parent="parent">
		<property name="adminEmails">
			<!-- the merge is specified on the child collection definition -->
			<props merge="true">
				<prop key="sales">sales@example.com</prop>
				<prop key="support">support@example.co.uk</prop>
			</props>
		</property>
	</bean>
<beans>
```
注意上面`merge=true`属性的使用，当容器解析child bean并初始化时，实例有一个`adminEmails`集合，包含了child的`adminEmails`集合与parent的`adminEmails`集合的所有结果。不能合并不同的集合类型。Java支持泛型，你可以使用强类型集合，就是声明特定元素类型的集合。注入强类型集合时，Spring会自动将value转换为强类型的值的类型。
```java
public class SomeClass {

	private Map<String, Float> accounts;

	public void setAccounts(Map<String, Float> accounts) {
		this.accounts = accounts;
	}
}
```
```xml
<beans>
	<bean id="something" class="x.y.SomeClass">
		<property name="accounts">
			<map>
				<entry key="one" value="9.99"/>
				<entry key="two" value="2.75"/>
				<entry key="six" value="3.99"/>
			</map>
		</property>
	</bean>
</beans>
```
当`something`bean的`accounts`属性注入时，通过反射得知泛型属性的泛型类型信息，因此，Spring的类型转换识别到目标类型然后进行转换。
## Null and Empty String Values
Spring认为空参数就是空字符串，下面是一个例子
```xml
<bean class="ExampleBean">
	<property name="email" value=""/>
</bean>
```
前面的例子等价下面的Java代码
```java
exampleBean.setEmail("");
```
`<null/>`元素表示null值，下面是一个例子
```xml
<bean class="ExampleBean">
	<property name="email">
		<null/>
	</property>
</bean>
```
等价于下面的Java代码
```java
exampleBean.setEmail(null);
```
## 使用p命名空间完成XML快速配置
p-namespace让你可以用bean的元素属性来描述属性值与引用Bean等，而不是通过`<property/>`元素。Spring支持namespace的扩展配置格式，基于XML模式定义。本章讨论的Bean配置格式定义在XML模式文档中，然而，p-namespace没有定义在XSD文件中，存在Spring Core中。下面的例子展示了2个XML片段，2个效果一样，一个使用标准XML格式，一个使用p-namespace
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:p="http://www.springframework.org/schema/p"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
		https://www.springframework.org/schema/beans/spring-beans.xsd">

	<bean name="classic" class="com.example.ExampleBean">
		<property name="email" value="someone@somewhere.com"/>
	</bean>

	<bean name="p-namespace" class="com.example.ExampleBean"
		p:email="someone@somewhere.com"/>
</beans>
```
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:p="http://www.springframework.org/schema/p"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
		https://www.springframework.org/schema/beans/spring-beans.xsd">

	<bean name="john-classic" class="com.example.Person">
		<property name="name" value="John Doe"/>
		<property name="spouse" ref="jane"/>
	</bean>

	<bean name="john-modern"
		class="com.example.Person"
		p:name="John Doe"
		p:spouse-ref="jane"/>

	<bean name="jane" class="com.example.Person">
		<property name="name" value="Jane Doe"/>
	</bean>
</beans>
```
这个例子不仅包含p-namespace的常规用法，还使用特殊的格式声明属性引用。p-namespace的用法不像标准XML格式那么灵活，比如声明属性引用的方式与以ref结尾的属性会相冲突，标准形式不会，建议整个团队保持一个风格。
## 使用c命名空间完成XML快速配置
与前面的p-namespace类似，c-namespace从Spring3.1版本引入，可以快速的配置构造函数参数而不用使用`<constructor-arg>`元素。下面是一个例子
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:c="http://www.springframework.org/schema/c"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
		https://www.springframework.org/schema/beans/spring-beans.xsd">

	<bean id="beanTwo" class="x.y.ThingTwo"/>
	<bean id="beanThree" class="x.y.ThingThree"/>

	<!-- traditional declaration with optional argument names -->
	<bean id="beanOne" class="x.y.ThingOne">
		<constructor-arg name="thingTwo" ref="beanTwo"/>
		<constructor-arg name="thingThree" ref="beanThree"/>
		<constructor-arg name="email" value="something@somewhere.com"/>
	</bean>

	<!-- c-namespace declaration with argument names -->
	<bean id="beanOne" class="x.y.ThingOne" c:thingTwo-ref="beanTwo"
		c:thingThree-ref="beanThree" c:email="something@somewhere.com"/>

</beans>
```
`c:`命名空间与`p:`同样的转换规则，在极少数的场景下，构造函数参数名字是不可用的，可以降级到使用参数索引位置
```xml
<!-- c-namespace index declaration -->
<bean id="beanOne" class="x.y.ThingOne" c:_0-ref="beanTwo" c:_1-ref="beanThree"
	c:_2="something@somewhere.com"/>
```
根据XML语法，索引标志需要前导符号`_`，因为XML的属性名不能以数字开头。
## 符合的属性名
你可以是红多重属性名来设置Bean属性，只要路径中的组件不是null，考虑下面的定义
```xml
<bean id="something" class="things.ThingOne">
	<property name="fred.bob.sammy" value="123" />
</bean>
```
`something`bean有一个fred属性，里面又个bob属性，里面有个sammy属性。sammy属性最终被设置为123.
# 使用depends-on
如果一个Bean依赖另一个Bean，通常意味着一个Bean是另一个Bean的属性。通常是使用`<ref>`元素或者自动装配机制。但是有时候依赖关系不会这么直接，例子就是当需要触发类中的静态初始化器，比如数据库驱动注册，`depends-on`属性与`@DependsOn`注解可以明确的强制某些bean在当前Bean初始化前初始化。下面的例子使用`depends-on`属性表达了依赖一个bean
```xml
<bean id="beanOne" class="ExampleBean" depends-on="manager"/>
<bean id="manager" class="ManagerBean" />
```
如果是依赖多个Bean，提供逗号分隔的bean名字列表，逗号、空白字符或者冒号都是有效的分隔符。
```xml
<bean id="beanOne" class="ExampleBean" depends-on="manager,accountDao">
	<property name="manager" ref="manager" />
</bean>

<bean id="manager" class="ManagerBean" />
<bean id="accountDao" class="x.y.jdbc.JdbcAccountDao" />
```
仅在单例bean的情况下,`depends-on`属性可以指定初始化时依赖项也就指定了相应的销毁时依赖项。与给定bean定义depends-on关系的的bean会先被销毁，然后才会销毁给定bean本身。因此，`depends-on`还可以控制关​​闭顺序。
# Lazy-initialized Bean
默认情况下，`ApplicationContext`实现会在初始化过程中创建与配置所有的singleton Bean，通常，这种预初始化是想要的，因为在配置与环境中的错误可以可以立即发现，而不需要在几小时会或者几天后发现。如果你不想要这样，可以将singleton Bean设置为延迟加载，这样就不会提前实例化。将Bean设置为延迟加载后，Spring IoC容器会在第一次请求Bean的才去创建，而不是在启动时。延迟加载是通过`@Lazy`注解与`<bean/>`元素中的`lazy-init`属性实现的，如下面的例子所示:
```java
@Bean
@Lazy
ExpensiveToCreateBean lazy() {
	return new ExpensiveToCreateBean();
}
@Bean
AnotherBean notLazy() {
	return new AnotherBean();
}
```
当`ApplicationContext`加载前面的配置后，当`ApplicationContext`启动后，lazy bean不会在启动阶段初始化。然而，如果一个lazy bean如果是一个非lazy bean的依赖，那么lazy bean也会在启动阶段实例化，因为必须满足依赖。您还可以通过在带有`@Configuration`注解类上使用`@Lazy` 注解或在XML中使用`<beans/>`元素上的`default-lazy-init`属性来控制一组Bean的延迟初始化，如以下示例所示:
```java
@Configuration
@Lazy
public class LazyConfiguration {
	// No bean will be pre-instantiated...
}
```
# Autowiring Collaborators
Spring容器可以自动装配协作bean之间的关系。您可以让Spring通过检查`ApplicationContext`的内容自动为您的bean解析协作者(其他bean)。自动装配具有以下优点:
- 自动装配减少代码量，不需要指定属性或者构造函数参数的信息等；
- 自动装配可以根据对象的变化而更新配置，比如，如果你需要向类添加一个依赖，依赖能够自动满足不需要修改任何配置，因此自动装配在开发阶段是很有用的，并且当代码库变得更加稳定时，也可以直接切换到显式装配的选项。

当使用的是基于XML的配置元数据时，你可以通过`<bean>`的`autowire`属性来指定Bean的自动装配模式，有4种装配模式，可以为每个bean指定自动装配，从而可以选择要自动装配的bean。下表描述了四种自动装配模式：
|**Mode**|**Explanation**|
|:---|:---|
|`no`|缺省模式，不会自动装配，必须通过ref指定引用的bean，不建议在已经存在的比较大的系统中更改缺省的装配模式，因为明确的指定依赖关系可以让开发者对系统有更好的控制并且更清晰，因为从某种程度来说，它描述了系统的结构|
|`byName`|通过属性名装配，指定根据Bean内的属性名来装配，Spring容器寻找与属性相同名字的bean来装配，比如，如果一个Bean definition设置为根据名字装配，它包含一个master属性，Spring会寻找一个叫做master的bean definition，并使用它来设置属性|
|`byType`|根据属性的类型来装配并且在容器中正好存在一个属性类型的bean，如果此类型的bean存在多个，则抛出一个异常，表示你不能使用`byType`的方式装配Bean，如果没有匹配的Bean发现，则注入null|
|`constructor`|与`byType`类似，但是匹配的是构造函数参数的类型，如果没有相关类型的Bean存在，则抛出异常|

使用`byType`或者`constructor`的自动装配模式，可以装配数组与typed集合类型的依赖。在这种场景下，所有的容器中类型匹配的自动装配候选者都会注入来满足依赖关系。你可以装key的类型为String类型的配强类型的`Map`实例，其中Map的value包含匹配的类型的Bean实例，key则是Bean的名字。
## 自动装配的限制与缺点
在项目中只使用自动装配时效果最佳。如果多数情况下不使用自动装配，开发人员可能会对仅使用它来装配一个或两个bean定义感到困惑。下面是自动装配的限制与缺点:
- 明确的指定`property`与`constructor-arg`依赖会覆盖自动装配机制，自动装配也不能装配基本类型值，String、Class或者是这些类型的数组，这是设计带来的限制
- 自动装配比显式装配更模糊而去少明确性，虽然在前面的表格中提到过，Spring总是会仔细的处理混淆的情况，并且努力避免猜测的情况。Bean之间的关系不是那么明确的文档化描述。
- 对于一些需要从Spring容器生成文档的工具而言，可能无法使用到这些装配信息
- 容器中可能存在多个匹配类型的Bean，对于集合类型来说，这不是问题，对于单个值来说，这种混淆无法解析，此时就会抛出异常

在后面的场景中，你可以通过下面的方法解决
- 显式注入，禁止自动呢注入
- 设置Bean Definition的`autowire-candidate=false`禁止这个Bean的自动装配
- 设置某个Bean Definition的`primary=true`来设置Bean作为primary candidate
- 通过基于注解配置的方式实现更细粒度的控制
## 从自动装配中排除一个Bean
你可以从自动装配中排出一个Bean，在Spring的XML配置元数据方式中，将`<bean/>`元素的 `autowire-candidate`属性设置为`false`；使用`@Bean`注释时，该属性名为 `autowireCandidate`。容器使该特定bean定义对自动装配基础组件不可用，包括基于注解的注入点，例如`@Autowired`。`autowire-candidate`属性只会影响type-base的自动装配，不会影响基于名字的自动装配，基于名字的注入主要名字匹配就会注入一个Bean。你可以通过基于Bean名字的模式匹配来限定自动装配的候选者，`<beans/>`元素的`default-autowire-candidates`属性接受一个或者多个模式，比如，限定自动装配候选者为名字以`Repository`结尾的Bean，可以提供`*Repository`，提供多个模式时用逗号分隔，bean definition的`autowire-candidate`属性设置有更高的优先级。对于设置了这些属性的Bean，模式匹配规则不生效。这些技术对于您永远不想通过自动装配注入到其他bean中的bean非常有用。这并不意味着排除的bean本身不能使用自动装配进行配置。而是bean本身不是自动装配下装配其他bean的候选对象。从6.2版本开始，`@Bean`方法支持2个自动装配候选者的变体`autowireCandidate`与`defaultCandidate`，当使用qualifier的时候，标记为`defaultCandidate=false`的bean仅用于具有qualifier指示的注入点，这在比较严格的委托场景很有用，这些委托只在特定的场景下可注入，但不会影响其他地方相同类型的Bean的注入。这样的bean在普通注入场景不会注入，需要加上qualifier。相反，`autowireCandidate=false`的行为与上面解释的`autowire-candidate`属性完全相同：这样的bean永远不会通过类型注入。
# 方法注入
在大多数的应用场景下，容器内的bean都是单例的；当一个单例的bean需要依赖其他的单例Bean或者非单例bean需要依赖其他的非单例Bean时，开发者只需要在定义Bean时，把相关的依赖定义成property等；这时候，如果Bean的生命周期是不同的就会发生一定的问题，假设单例Bean A依赖多例Bean B，可能A的每个方法的调用都需要调用B的相关的逻辑；容器只会初始化一次A，并且只会在初始化时设置一次A的依赖，此时B在ABean中变成了单例，并没有在每个方法调用时都生成新的B。
上述问题的一种解决方案就是放弃控制反转，可以让Bean实现`ApplicatonContextAware`接口来让Bean持有容器，并通过调用容器的`getBean("B")`方法来每次获取新的B实例.如下面的代码:
```java
package fiona.apple;

// Spring-API imports
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;

/**
 * A class that uses a stateful Command-style class to perform
 * some processing.
 */
public class CommandManager implements ApplicationContextAware {

	private ApplicationContext applicationContext;

	public Object process(Map commandState) {
		// grab a new instance of the appropriate Command
		Command command = createCommand();
		// set the state on the (hopefully brand new) Command instance
		command.setState(commandState);
		return command.execute();
	}

	protected Command createCommand() {
		// notice the Spring API dependency!
		return this.applicationContext.getBean("command", Command.class);
	}

	public void setApplicationContext(
			ApplicationContext applicationContext) throws BeansException {
		this.applicationContext = applicationContext;
	}
}
```
上述的解决方案并不令人满意，因为它把业务代码与Spring框架的代码耦合在了一起；Method Injection，是Spring容器的高级特性，可以完美解决这种情况。
## Lookup Method injection
Lookup方法注入技术是一种容器覆写容器中Bean中方法的技术，这种lookup方法会返回容器内的其他的Bean作为lookup的结果；这种技术一般就是用于返回多例Bean；Spring框架是通过字节码生成器CGLIB来动态生成一个子类再通过子类覆写lookup方法来实现方法注入的，由于要动态生成子类，所以定义类不能是final的，同时需要覆写的方法不能是final的；单元测试情况，你需要自己实现类的子类，，并提供抽象方法的实现方法；Lookup方法的限制就是lookup方法Bean不能使用工厂方法的方式创建，尤其是不能通过`@Bean`的注解方式创建的Bean，因为在这种情况下，并不是容器负责生成的实例，因此，不能创建一个运行时子类。
上面代码可以改造为：
```java
package fiona.apple;

// no more Spring imports!

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
方法签名如下:
```
<public|protected> [abstract] <return-type> theMethodName(no-arguments);
```
如果方法时abstract的，动态生成的子类会实现方法，否则，动态子类会覆盖类中的具体实现方法，Lookup方法可以是abstract的也可以不是abstract的。考虑下面的例子
```xml
<!-- a stateful bean deployed as a prototype (non-singleton) -->
<bean id="myCommand" class="fiona.apple.AsyncCommand" scope="prototype">
	<!-- inject dependencies here as required -->
</bean>

<!-- commandManager uses myCommand prototype bean -->
<bean id="commandManager" class="fiona.apple.CommandManager">
	<lookup-method name="createCommand" bean="myCommand"/>
</bean>
```
`commandManager`Bean当需要一个`myCommand`类型的实例时就调用它自己的`createCommand()`方法，你需要将`myCommand`定义为多例Bean，如果定义成singleton了，每次返回的`myCommand`将会都是一个实例。另外在基于注解配置的组件模型中，开发者可以在lookup方法上加上注解`@Lookup`来声明。
```java
public abstract class CommandManager {

	public Object process(Object commandState) {
		Command command = createCommand();
		command.setState(commandState);
		return command.execute();
	}

	@Lookup("myCommand")
	protected abstract Command createCommand();
}
```
也可以省略名字
```java
public abstract class CommandManager {

	public Object process(Object commandState) {
		Command command = createCommand();
		command.setState(commandState);
		return command.execute();
	}

	@Lookup
	protected abstract Command createCommand();
}
```
通常来说，配置基于注解的lookup方法时需要类是实际的实现类，方法是普通的实现方法，这是为了与Spring的组件扫描规则相兼容，因为缺省情况下，Spring容器会忽略抽象类，但是，如果明确注册了抽象类为bean或者明确的通过imported的bean配置，则不会忽略抽象类。
还有获取不同生命周期Bean的方式是`ObjectFactory/Provider`注入，参考[Scoped Beans as Dependencies](https://docs.spring.io/spring-framework/reference/core/beans/factory-scopes.html#beans-factory-scopes-other-injection)，`ServiceLocatorFactoryBean`也是·很有用的。
## Arbitrary Method Replacement
一种使用较少的方法注入方案是方法替换，当你真的需要这个功能的时候再回来看也行。当使用XML配置时，可以使用`replaced=method`元素来替换方法；考虑下面的类，有一个`computeValue`方法。
```java
public class MyValueCalculator {

	public String computeValue(String input) {
		// some real code...
	}

	// some other methods...
}
```
实现了`org.springframework.beans.factory.support.MethodReplacer`接口的类提供了新的方法定义，如下面的例子所示:
```java
/**
 * meant to be used to override the existing computeValue(String)
 * implementation in MyValueCalculator
 */
public class ReplacementComputeValue implements MethodReplacer {

	public Object reimplement(Object o, Method m, Object[] args) throws Throwable {
		// get the input value, work with it, and return a computed result
		String input = (String) args[0];
		...
		return ...;
	}
}
```
定义方法替换如下:
```xml
<bean id="myValueCalculator" class="x.y.z.MyValueCalculator">
	<!-- arbitrary method replacement -->
	<replaced-method name="computeValue" replacer="replacementComputeValue">
		<arg-type>String</arg-type>
	</replaced-method>
</bean>

<bean id="replacementComputeValue" class="a.b.c.ReplacementComputeValue"/>
```
可以在`<replaced-method/>`元素中使用一个或者多个`<arg-type/>`元素注解表示方法签名，如果方法时重载的那么参数签名是需要的。
