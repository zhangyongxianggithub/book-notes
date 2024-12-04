# Validation
默认情况下，如果Bean Validation出现在classpath下面，`LocalValidatorFactoryBean`就会被注册为一个全局的Validator，可以校验`@Valid`与`@Validate`注解修饰的控制器方法参数。你可以定制这个Validator，比如:
```java
@Configuration
public class WebConfiguration implements WebMvcConfigurer {
	@Override
	public Validator getValidator() {
		Validator validator = new OptionalValidatorFactoryBean();
		// ...
		return validator;
	}
}
```
也可以注册局部的Validator，如下:
```java
@Controller
public class MyController {
	@InitBinder
	public void initBinder(WebDataBinder binder) {
		binder.addValidators(new FooValidator());
	}
}
```
