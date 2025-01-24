很多Spring开发者想要他们的App使用自动配置、组件扫描并且可能想要在主类上定义额外的配置。只需要一个`@SpringBootApplication`注解就可以了，它包含了:
- `@EnableAutoConfiguration`: 开启[Spring Boot的自动配置机制](https://docs.spring.io/spring-boot/reference/using/auto-configuration.html)
- `@ComponentScan`: 开启包上的`@Component`扫描，包有应用定义
- `@SpringBootConfiguration`: 开启上下文中额外bean的注册或者导入额外的配置类，是`@Configuration`类的一个替代者，可以帮助检测继承测试中的配置

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// Same as @SpringBootConfiguration @EnableAutoConfiguration @ComponentScan
@SpringBootApplication
public class MyApplication {

	public static void main(String[] args) {
		SpringApplication.run(MyApplication.class, args);
	}

}
```
`@SpringBootApplication`注解也提供了`@EnableAutoConfiguration`与`@ComponentScan`注解中的属性的别名。这些特定都是非强制性的，你可以只使用需要的机制的相关的注解，比如，你可能不想要组件扫描或者配置属性扫描
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.Import;

@SpringBootConfiguration(proxyBeanMethods = false)
@EnableAutoConfiguration
@Import({ SomeConfiguration.class, AnotherConfiguration.class })
public class MyApplication {

	public static void main(String[] args) {
		SpringApplication.run(MyApplication.class, args);
	}

}
```
在这个例子中，`MyApplication`就像任何其他Spring Boot应用程序一样，只是不会自动检测带有 `@Component`注解的类和带有`@ConfigurationProperties`注解的类，并且明确导入用户定义的 bean(参见`@Import`)。
