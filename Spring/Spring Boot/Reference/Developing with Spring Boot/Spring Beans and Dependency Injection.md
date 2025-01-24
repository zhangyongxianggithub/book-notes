可以无需任何额外的工作使用标准的Spring框架的技术来定义Bean与他们的依赖注入关系。建议使用构造函数注入依赖并且使用`@ComponentScan`来发现Bean。
如果你的代码结构式建议的形式。可以直接添加`@ComponentScan`注解，不需要任何参数，或者使用`@SpringBootApplication`注解，里面包含`@ComponentScan`注解。
所有你的应用组件将会自动注册为Spring的Bean。下面是一个例子:
```java
import org.springframework.stereotype.Service;

@Service
public class MyAccountService implements AccountService {

	private final RiskAssessor riskAssessor;

	public MyAccountService(RiskAssessor riskAssessor) {
		this.riskAssessor = riskAssessor;
	}
}
```
如果Bean有多个构造函数，可以将你想要Spring使用的构造函数用`@Autowired`修饰。
```java
@Service
public class MyAccountService implements AccountService {
	private final RiskAssessor riskAssessor;
	private final PrintStream out;
	@Autowired
	public MyAccountService(RiskAssessor riskAssessor) {
		this.riskAssessor = riskAssessor;
		this.out = System.out;
	}
	public MyAccountService(RiskAssessor riskAssessor, PrintStream out) {
		this.riskAssessor = riskAssessor;
		this.out = out;
	}
}
```
注意如何使用的构造函数注入，`riskAssessor`使用了`final`，表示后面它不能被变更。
