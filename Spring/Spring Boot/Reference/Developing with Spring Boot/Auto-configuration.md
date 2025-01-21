Spring Boot的自动配置会尝试基于你添加的Jar依赖自动配置你的应用。比如，如果`HSQLDB`在Classpath中，你不需要人工配置任何有关数据库连接的Bean。Spring Boot会自动配置一个内存数据库。你可以通过在`@Configuration`修饰类上添加`@EnableAutoConfiguration`或者`@SpringBootApplication`注解开启自动配置机制。您应该只添加一个 `@SpringBootApplication`或`@EnableAutoConfiguration`注解。我们通常建议您只将其中一个添加到主`@Configuration`类中。
# Gradually Replacing Auto-configuration
Auto-configuration是非侵入性的，在任何地方任何时间，你都可以定义自己的配置来替换Auto-configuration的某些部分。比如，如果你自己定义了`DataSource`Bean,默认的内嵌的数据库支持将会被替换。如果你需要了解当前生效的Auto-configuration以及为什么生效，启动应用的时候携带`--debug`开关，开启core logger的debug日志输出，将会输出匹配报告到控制台。
# Disabling Specific Auto-configuration Classes
如果不想要某些Auto-configuration生效，可以使用`@SpringBootApplication`的`exclude`属性来禁用，如下所示：
```java
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = { DataSourceAutoConfiguration.class })
public class MyApplication {

}
```
如果类不在classpath中，你可以使用`excludeName`属性指定类的全限定名，如果你使用的是注解`@EnableAutoConfiguration`，上面2个属性也是可用的。最终，你也可以使用`spring.autoconfigure.exclude`属性来排除多个多个Auto-configuration类。同时在注解与属性中定义都是可以的，虽然自动配置类是`public`的，但该类中唯一被视为公共API的地方是可用于禁用自动配置的类的名称。这些类的实际内容(例如嵌套配置类或声明的bean方法)仅供内部使用，我们不建议直接使用它们。
# Auto-configuration Packages
Auto-configuration包是各种自动配置功能在扫描类似entities和Spring Data repositories等内容时默认查找的根包。`@EnableAutoConfiguration`注解(直接修饰的或通过`@SpringBootApplication`间接修饰的)可以确定默认的自动配置包。可以使用 `@AutoConfigurationPackage`注解配置额外的包。