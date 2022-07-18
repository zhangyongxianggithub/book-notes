自从Spring Boot第一个版本发布，就可以通过使用`@ConfigurationProperties`注解绑定属性到类，也可以通过很多种方式指定属性名，比如person.first-name、person.firstName、或者PERSON_FIRSTNAME都可以指定名字，我们称这种特性叫做relaxed binding。不幸的是，在Spring Boot1.x，relaxed binding有点太relaxed了，导致开发者常常搞不清楚绑定的具体规则是什么以及什么时候使用某种特殊的规则，我们还开始收到关于我们的1.x实现很难解决BUG的报告。例如，在Spring Boot 1.x中，无法将项目绑定到java.util.Set。所以从2.0版本开始，我们重构了绑定处理，我们添加了新的抽象，开发了新的绑定API，在这个博客文章中，我们会介绍新的类、接口，说明添加它们的目的，它们是干什么的，你如何使用它们.
## Property Sources
如果你已经使用了Spring一段时间，你应该对Environment抽象是比较熟悉的，这个接口是一个`ProeprtyResolver`接口，可以让你从一些底层的`PropertySource`实现中解析属性。Spring框架提供了一些通用的PropertySource的实现，比如系统属性源、命令行参数源、属性文件属性源等，Spring Boot自动配置了这些实现，这种配置适用大部分的应用，比如application.properties的属性源。
## Configuration Property Sources
相比与直接使用已经存在的PropertySource接口做属性绑定，Spring Boot 2.0引入了一个叫做ConfigurationPropertySource的新的接口，这个接口实现之前Binder中的relaxed binding规则，接口很简单，只有一个方法
```java
ConfigurationProperty getConfigurationProperty(ConfigurationPropertyName name);
```
还有一个变体`IterableConfigurationPropertySource`, 只不过参数变成了`Iterable<ConfigurationPropertyName>`，所以你可以发现一个source包含的批量的属性。你可以传递Environment参数到ConfigurationPropertySources中,
```java
Iterable<ConfigurationPropertySource> sources =
	ConfigurationPropertySources.get(environment);
```
如果您需要它，我们还提供了一个简单的 MapConfigurationPropertySource 实现。
## Configuration Property Names
事实证明，如果您将绑定限制在一个方向，则relaxed binding更容易实现。您应该始终使用规范形式访问属性，无论它们在底层Source中是如何表示的。`ConfigurationPropertyName`类强制执行这些规范的命名规则，这些规则基本上归结为“使用小写的 kebab-case 名称”。比如，你应该在代码中访问属性person.first-name。即使这个属性在底层的source是通过person.firstName或者PERSON_FIRSTNAME表示的。
## Origin Support
正是你期望的，ConfigurationProperty对象从ConfigurationPropertySource对象中返回，ConfigurationProperty包含实际的属性值，可能还包括一个可选的Origin字段。Origin是Spring Boot 2.0引入的一个新的接口，可以让你精确定位属性值加载的具体位置，有很多Origin的实现，最有用的可能是TextResourceOrigin实现类，这个类提供了加载的Resource的细节以及里面属性的行列号相关的内容。对于.properties或者.yml文件来说，我们写了自定义的加载器可以在加载这些文件的时候生成Origin，一些Spring Boot的特性都开始使用Origin的信息，比如Binder校验器校验绑定的属性，当校验异常时，错误显示了不能绑定的属性值与它的origin。
```
**************************
APPLICATION FAILED TO START
***************************

Description:

Binding to target org.springframework.boot.context.properties.bind.BindException: Failed to bind properties under 'person' to scratch.PersonProperties failed:

    Property: person.name
    Value: Joe
    Origin: class path resource [application.properties]:1:13
    Reason: length must be between 4 and 2147483647


Action:

Update your application's configuration
```
## Binder API
Binder类可以让你使用一个或者多个ConfigurationPropertySource来执行属性绑定，更准确的来说，Binder也会用到Bindable，然后返回BindResult.
一个Bindable必须是已经存在的bean、一个class或者是一个复杂的ResolvableType，比如List<Person>，这里是一些例子
```java
Bindable.ofInstance(existingBean);
Bindable.of(Integer.class);
Bindable.listOf(Person.class);
Bindable.of(resovableType);
```
Bindable is also used to carry annotation information, but you usually do not need to worry about that.
Binder没有直接返回绑定的对象而是返回一个叫做BindResult的对象，就像java8 中的Optional，一个BindResult表示的可能绑定或者没有绑定的结果。如果你想要获得没有绑定成功的对象，那么会抛出一个异常，我们提供了一个方法可以在没有绑定成功时，返回替代值还有通过map的方式转换为别的类型:
```java
var bound = binder.bind("person.date-of-birth",
	Bindable.of(LocalDate.class));

// Return LocalDate or throws if not bound
bound.get();

// Return a formatted date or "No DOB"
bound.map(dateFormatter::format).orElse("No DOB");

// Return LocalDate or throws a custom exception
bound.orElseThrow(NoDateOfBirthException::new);
```
大部分的ConfigurationPropertySource实现中属性值都是字符串，当Binder需要将属性值的字符串形式转换成绑定对象的属性的类型值的时候，会委托给Spring的COnversionService API完成，如果你想要定义值转换的方式，你可以使用格式化注解，比如@NumberFormat或者@DateFormat。Spring Boot 2.0也开发了新的注解与新的Converters，这些新的内容对绑定是非常有用的，比如，现在你可以把类似于4s的值转换为Duration，可以看org.springframework.boot.convert包下的内容。有时候，绑定时，你想要实现一些额外的逻辑，BindHander接口可以做到这一点，每一个BindHandler都有onStart、onSuccess、onFailure、onFinish的抽象方法，可以实现来覆盖默认的行为。Spring Boot提供了大量的handlers，主要是为了支持实现@ConfigurationProperties绑定实现，比如，ValidationBindHandler可以用来应用Validator校验到绑定对象上。
## @ConfigurationProperties
正如在博客开始那里提到的，@ConfigurationProperties是Spring Boot的早期功能，目前也是大部分人都倾向使用的执行绑定的方式
## Future Work
我们会继续开发Binder，后面的版本中，我们会开发不可变属性功能，以后属性绑定就要通过构造方法来做，不用提供Setter方法
```java
public class Person {

	private final String firstName;
	private final String lastName;
	private final LocalDateTime dateOfBirth;

	public Person(String firstName, String lastName,
			LocalDateTime dateOfBirth) {
		this.firstName = firstName;
		this.lastName = lastName;
		this.dateOfBirth = dateOfBirth;
	}

	// getters

}
```
