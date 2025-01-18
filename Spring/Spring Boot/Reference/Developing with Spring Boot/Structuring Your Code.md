Spring Boot不要求特定的代码布局，但是也有一些最佳实践。如果你想要一个基于领域的代码结构，参考[Spring Modulith](https://spring.io/projects/spring-modulith#overview)
# 使用`default`包
不建议使用默认包，并且应该避免。会造成`@ComponentScan`, `@ConfigurationPropertiesScan`, `@EntityScan`, `@SpringBootApplication`注解等无法正常工作。
我们建议你遵守Java的建议包命名约定，使用一个revered domain name。比如`com.example.project`。
# Locating the Main Application Class
我梦通常建议你把主类放在其他类之上的根包。注解`@SpringBootApplication`通常放在主类上，隐式的定义了要搜索的根包，比如你正在写一个JPA应用，`@SpringBootApplication`注解类用来搜索`@Entity`注解修饰的类。使用根包也让组件扫描只会作用你的项目。下面的列表表示一个典型的布局
```
com
 +- example
     +- myapplication
         +- MyApplication.java
         |
         +- customer
         |   +- Customer.java
         |   +- CustomerController.java
         |   +- CustomerService.java
         |   +- CustomerRepository.java
         |
         +- order
             +- Order.java
             +- OrderController.java
             +- OrderService.java
             +- OrderRepository.java
```
`MyApplication.java`文件声明了main方法以及`@SpringBootApplication`。代码如下:
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MyApplication {

	public static void main(String[] args) {
		SpringApplication.run(MyApplication.class, args);
	}

}
```
