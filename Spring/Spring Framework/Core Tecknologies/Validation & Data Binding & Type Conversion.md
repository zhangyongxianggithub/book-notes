# Java Bean Validation
Spring提供了对Java Bean Validation API的支持。
## 概述
Bean校验提供了校验的一个通用的实现方式，校验的过程是通过元数据与约束声明的方式实现的，你需要给你的领域模型加上约束性的声明注解，在运行时，这些约束会被检查，有很多内置的约束，你可以定义你自己的约束条件。考虑下面的类：
```java
public class PersonForm {
	private String name;
	private int age;
}
```
可以声明如下的约束
```java
public class PersonForm {

	@NotNull
	@Size(max=64)
	private String name;

	@Min(0)
	private int age;
}
```
Bean Validation Validator基于声明的约束校验类的实例，可以参考[Bean Validation](https://beanvalidation.org/)获取更多的信息，参考[Hibernate Validator](https://hibernate.org/validator/)获取实现的信息。
## 配置一个Bean Validation Provider
将验证者作为Bean处理，也就是你可以在你需要校验的地方注入`jakarta.validation.ValidatorFactory`或者`jakarta.validation.Validator`，你可以使用`LocalValidatorFactoryBean`来配置一个Validator
```java
@Configuration
public class AppConfig {
	@Bean
	public LocalValidatorFactoryBean validator() {
		return new LocalValidatorFactoryBean();
	}
}
```
上面的基本配置已经开启了bean的校验，并且使用了缺省的初始化的方式初始化了bean校验的相关的类，一个Bean校验的提供者，比如Hibernate，必须出现在classpaath下面。
### 注入Jakarta Validator
`LocalValidatorFactoryBean`实现了`jakarta.validation.ValidatorFactory`与`jakarta.validation.Validator`接口，还有`org.springframework.validation.Validator`接口，你可以注入任何一个接口来校验实例，如果你想直接通过Bean Validation API的方式校验，可以选择注入`javax.validation.Validator`，如下:
```java
import jakarta.validation.Validator;
@Service
public class MyService {
	@Autowired
	private Validator validator;
}
```
### 注入Spring Validator
```java
import org.springframework.validation.Validator;
@Service
public class MyService {

	@Autowired
	private Validator validator;
}
```
使用`org.springframework.validation.Validator`时，`LocalValidatorFactoryBean`调用低层的`jakarta.validation.Validator`，将`ConstraintViolation`变成`FieldError`，并注册到`Errors`对象中。
### 配置自定义的约束
每个Bean校验约束都包含2个部分：
- 一个`@Constraint`注解声明了约束限制与配置的属性
- 一个`jakarta.validation.ConstraintValidator`接口的实现类，实现约束行为

为了把约束声明与约束实现关联起来，每个`@Constraint`注解都有一个`ConstraintValidator`接口实现的属性，在运行时，当遭遇到约束声明注解时，一个`ConstraintValidatorFactory`实例化相关的实现并校验领域对象。缺省情况下，`LocalValidatorFacrtoryBean`会配置一个`SpringConstraintValidatorFactory`这个是`ConstraintValidatorFactory`的spring实现，它会帮助初始化ConstraintValidator实现，主要是使用spring的编程思想，可以依赖注入。下面是例子：
```java
@Target({ElementType.METHOD, ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy=MyConstraintValidator.class)
public @interface MyConstraint {
}
import jakarta.validation.ConstraintValidator;
public class MyConstraintValidator implements ConstraintValidator {
	@Autowired;
	private Foo aDependency;

	// ...
}
```
## Spring-driven Method Validation
你可以整合Bean Validation方法校验特性到Spring上下文中，只需要定义一个`MethodValidationPostProcessor`的bean。
```java
@Configuration
public class ApplicationConfiguration {
	@Bean
	public static MethodValidationPostProcessor validationPostProcessor() {
		return new MethodValidationPostProcessor();
	}
}
```
为了执行Spring驱动的方法校验，所有的目标的类都必须使用`@Validate`注解标注，也可以声明使用的验证组，可以阅读这个类获得更多的Hibernate校验器的相关的细节。方法校验依赖AOP代理。基于接口的JDK动态代理或者CGLIB代理，Spring MVC与WebFlux都内置提供了方法校验，但是不是通过代理实现的。
### 方法校验异常
默认情况下，`jakarta.validation.ConstraintViolationException`会携带`jakarta.validation.Validator`返回的`ConstraintViolation`一起抛出，作为替代方案，你可以抛出携带`ConstraintViolation`的`MethodValidationException`异常，这样可以方便转换为`MessageSourceResolvable`类型的错误，如下的代码开启
```java
@Configuration
public class ApplicationConfiguration {
	@Bean
	public static MethodValidationPostProcessor validationPostProcessor() {
		MethodValidationPostProcessor processor = new MethodValidationPostProcessor();
		processor.setAdaptConstraintViolations(true);
		return processor;
	}
}
```
`MethodValidationException`包含`ParameterValidationResult`列表，通过方法参数来对错误分组，每个`ParameterValidationResult`暴露一个`MethodParameter`、参数值与一个`MessageSourceResolvable`错误列表，对于字段和属性上存在级联约束的`@Valid`方法参数，`ParameterValidationResult`是`ParameterErrors`，它实现了 `org.springframework.validation.Errors`，并将验证错误暴露为`FieldError`。
### 自定义校验错误
`MessageSourceResolvable`错误可以被转换成错误信息显示给用户，这是通过配置的`MessageSource`实现的，下面是一个例子
```java
record Person(@Size(min = 1, max = 10) String name) {
}
@Validated
public class MyService {
	void addStudent(@Valid Person person, @Max(2) int degrees) {
	}
}
```
`Person.name()`上的`ConstraintViolation`生成一个如下的`FieldError`:
- 错误代号`Size.person.name`、`Size.name`、`Size.java.lang.String`、`Size`
- 消息参数`name`、`10`、`1`,也就是字段名字与约束的属性
- 默认的消息`size must be between 1 and 10`

定制默认消息，你可以添加错误代号的属性与参数到`MessageSource`的绑定资源中，`name`参数名嘴也是可定制的，比如如下:
```
Size.person.name=Please, provide a {0} that is between {2} and {1} characters long
person.name=username
```
如果是方法参数的`ConstraintViolation`，则产生如下的`MessageSourceResolvable`
- 错误代号`Max.myService#addStudent.degrees`, `Max.degrees`, `Max.int`, `Max`
- 消息参数`degrees2`与`2`
- 默认的消息`must be less than or equal to 2`

### 额外的配置参数
默认的`LocalValidatorFactoryBean`配置足以满足大多数情况。各种Bean校验场景都有许多配置选项，从消息插值到遍历解析。有关这些选项的更多信息，请参阅 [LocalValidatorFactoryBean javadoc](https://docs.spring.io/spring-framework/docs/6.2.0/javadoc-api/org/springframework/validation/beanvalidation/LocalValidatorFactoryBean.html)
## 配置`DataBinder`
从spring 3开始，你可以给`DataBinder`实例配置一个`Validator`，一旦配置，你可以调用`binder.validate()`来校验，实际底层使用的是配置的`Validator`对象，所有的`Errors`都会自动被添加到binder的`BindingResult`中。下面是一个例子:
```java
Foo target = new Foo();
DataBinder binder = new DataBinder(target);
binder.setValidator(new FooValidator());

// bind to the target object
binder.bind(propertyValues);

// validate the target object
binder.validate();

// get BindingResult that includes any validation errors
BindingResult results = binder.getBindingResult();
```
你也可以为`DataBinder`配置多个`Validator`，通过`dataBinder.addValidators`与`dataBinder.replaceValidators`方法，当将全局配置的bean验证与在`DataBinder`实例上本地配置的`Spring Validator`相结合时，这很有用。