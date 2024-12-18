Spring表达式语言简写为SpEL，功能强大，支持查询与操作运行中的对象，语法类似[Jakarta Expression Language](https://jakarta.ee/specifications/expression-language/)但是提供了额外的特性，支持方法调用与字符串模板等功能。也有其他好用的表达式语言，比如OGNL、MVEL、JBoss EL等；SpEL是专门为Spring产品族提供表达式语言支持的，语法主要以满足Spring项目需求为主；SpEL是专门用来进行表达式求值的，SpEL可以独立使用，不必一定要在Spring的环境里面，独立使用时，需要进行一些环境的初始化工作，比如创建Parser类对象等；在Spring环境中使用时是不必的；SpEL包含下列的功能：
- 字面表达式；
- Properties、array、lists、maps属性访问；
- 内联lists
- 内联maps
- 数组
- 布尔与关系运算符号；
- 正则表达式；
- 逻辑运算符
- 字符串运算符
- 数学运算符
- 赋值
- 类型表达式
- 方法调用；
- 调用构造方法；
- 变量
- Bean引用；
- 三元运算符；
- 变量；
- 用户定义函数；
- 模板表达式；
- 集合投影；
- 集合元素选择。

# Evaluation
这一部分主要讲述SpEL接口与表达式语言的基本的使用，更多的内容参考[Language Reference](https://docs.spring.io/spring-framework/reference/core/expressions/language-ref.html)章节；下面的代码是对一个简单的文本字符串进行求值；
```java
ExpressionParser parser = new SpelExpressionParser();
Expression exp = parser.parseExpression("'Hello World'"); 
String message = (String) exp.getValue();
```
SpEL相关的所有的类都定义在`org.springframework.expression`包与子包下；`ExpressionParser`接口负责解析表达式，在前面的例子中，表达式是一个使用单引号括起来的字符串，`Expression`负责对定义的表达式进行求值；当调用    `parser.parseExpression`与`exp.getValue`这2个方法时，可能会抛出`ParseException`与`EvaluationException`2种异常。
SpEL支持非常多的特性，比如方法调用、访问属性或者调用构造函数，下面的例子是一个方法调用的例子，我们调用字符串的concat方法:
```java
ExpressionParser parser = new SpelExpressionParser();
Expression exp = parser.parseExpression("'Hello World'.concat('!')"); 
String message = (String) exp.getValue();
```
也可以访问Java Bean的属性；可以通过点号操作符访问属性；
```java
ExpressionParser parser = new SpelExpressionParser();
// invokes 'getBytes()'
Expression exp = parser.parseExpression("'Hello World'.bytes"); 
byte[] bytes = (byte[]) exp.getValue();
```
SpEL支持使用点符号访问内嵌属性，比如prop1.prop2.prop3, 可以访问属性的setter方法。下面的例子展示了如何使用dot标记获取字符串的长度
```java
ExpressionParser parser = new SpelExpressionParser();
// invokes 'getBytes().length'
Expression exp = parser.parseExpression("'Hello World'.bytes.length"); 
int length = (Integer) exp.getValue();
```

也可以使用对象的构造方法构造对象:
```java
ExpressionParser parser = new SpelExpressionParser();
Expression exp = parser.parseExpression("new String('hello world').toUpperCase()"); 
String message = exp.getValue(String.class);
```
注意泛型方法`public <T> T getValue(Class<T> desiredResultType)`的使用，这个方法避免了需要转型的操作，如果表达式的求值结果不能转为T或则通过注册的类型转换器也无法转换，则抛出`EvaluationException`异常。SpEL表达式最常用的用法是在一个指定的对象上对表达式求值。这个对象也叫做root对象，下面的例子展示了如何获取`Inventor`类实例的`name`属性值以及如何在布尔表达式中引用`name`属性
```java
// Create and set a calendar
GregorianCalendar c = new GregorianCalendar();
c.set(1856, 7, 9);

// The constructor arguments are name, birthday, and nationality.
Inventor tesla = new Inventor("Nikola Tesla", c.getTime(), "Serbian");

ExpressionParser parser = new SpelExpressionParser();

Expression exp = parser.parseExpression("name"); // Parse name as an expression
String name = (String) exp.getValue(tesla);
// name == "Nikola Tesla"

exp = parser.parseExpression("name == 'Nikola Tesla'");
boolean result = exp.getValue(tesla, Boolean.class);
// result == true
```
## Understanding EvaluationContext
`EvaluationContext`接口是用来在计算表达式时解析属性、方法、field或者执行类型转换的，有2个接口实现：
- SimpleEvaluationContext，提供了基本的SpEL语言特性与配置选项的子集，适用于不需要SpEL语言语法全部特性的表达式，且表达式应受到有意义限制。数据绑定表达式和基于属性的过滤器都属于这种表达式
- StandardEvaluationContext，提供了全部的SpEL语言特性与配置选项支持，可以在这个上下文中指定默认的root对象或者配置求值相关的策略

`SimpleEvaluationContext`只支持SpEL语法的一部分，不支持Java类型引用、构造函数与bean引用等，它还要求开发者明确的指定表达式中属性与方法的支持级别，缺省情况下，`create()`静态工厂方法仅允许读取属性，你还可以通过builder来配置所需的确切的支持级别，针对下面的某一项或者某些组合。
- Custom PropertyAccessor only (no reflection)
- Data binding properties for read-only access
- Data binding properties for read and write
## 类型转换
缺省情况下，SpEL使用Spring环境中的`org.springframework.core.convert.ConversionService`进行类型转换；这个转换器服务包含了很多内置的类型转换器，也可以实现自定义的类型转换器。另外，它还可以识别泛型，也就是说，当在表达式中使用泛型类型时，SpEL会尝试进行转换以维护它遇到的任何对象的类型正确性。假设使用`setValue()`方法为一个`List<Boolean>`类型的属性赋值`List`，SpEL会识别到list的元素需要转换成`Boolean`，下面是一个例子:
```java
class Simple {
	public List<Boolean> booleanList = new ArrayList<>();
}

Simple simple = new Simple();
simple.booleanList.add(true);

EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();

// "false" is passed in here as a String. SpEL and the conversion service
// will recognize that it needs to be a Boolean and convert it accordingly.
parser.parseExpression("booleanList[0]").setValue(context, simple, "false");

// b is false
Boolean b = simple.booleanList.get(0);
```
## 解析器配置
可以受用解析器配置对象来配置SpEL表达式解析器: `org.springframework.expression.spel.SpelParserConfiguration`，配置对象可以控制某些表达式组件的行为，如果您对数组或集合进行索引并且指定索引处的元素为null，则SpEL可以自动创建该元素。当使用由属性引用链组成的表达式时，这非常有用。如果对数组或列表进行索引并指定超出数组或列表当前大小末尾的索引，SpEL可以自动增长数组或列表以容纳该索引。为了在指定索引处添加元素，SpEL将在设置指定值之前尝试使用元素类型的默认构造函数创建元素。如果元素类型没有默认构造函数，则null将被添加到数组或列表中。如果没有知道如何设置该值的内置或自定义转换器，则 null将保留在数组或列表中的指定索引处。以下示例演示了如何自动增长列表:
```java
class Demo {
	public List<String> list;
}

// Turn on:
// - auto null reference initialization
// - auto collection growing
SpelParserConfiguration config = new SpelParserConfiguration(true, true);

ExpressionParser parser = new SpelExpressionParser(config);

Expression expression = parser.parseExpression("list[3]");

Demo demo = new Demo();

Object o = expression.getValue(demo);

// demo.list will now be a real collection of 4 entries
// Each entry is a new empty String
```
缺省情况下，一个SpEL表达式不能超过10000个字符，这是可配置的，通过`maxExpressionLength`配置，如果你创建了一个`SpelExpressionParser`，你可以指定`maxExpressionLength`，如果你想要设置`ApplicationContext`中用于解析SpEL表达式的`SpelExpressionParser`的`maxExpressionLength`，你可以通过JVM系统属性或者名叫`spring.context.expression.maxLength`的系统属性来指定最大长度，具体参考[Supported Spring Properties](https://docs.spring.io/spring-framework/reference/appendix.html#appendix-spring-properties)
## SpEL编译
Spring提供了SpEL表达式基本的编译器，表达式是解释执行的，这种方式求值比较灵活但是不提供性能优化，在临时的表达式语言使用环境中使用是没问题的，但是集成到Spring环境中时，就需要考虑SpEL的性能；SpEL编译器就是为了解决这个问题。在求值时，编译器生成一个Java类，包含了运行时的表达式行为并使用这个类来式实现更快的表达式求值，由于缺少类型信息，编译器使用一个表达式解释执行时产生的类型信息来辅助编译。比如，Spring不指导表达式中引用的属性的类型，但是在第一次解释执行时，它就会知道，因此，如果表达式中的元素类型在不同的时间如果不一致，这种方式就会产生问题。因此，编译只适用于表达式中的元素类型信息不回发生变更的情况。考虑下面的基本表达式:
```java
someArray[0].someProperty.someOtherProperty < 0.1
```
由于前面的表达式涉及数组访问、一些属性取消引用和数值运算，因此性能提升非常明显。在运行 50,000次迭代的示例微基准测试中，使用解释器进行评估需要75毫秒，而使用表达式的编译版本只需要 3毫秒。
## Compiler Configuration
编译器默认情况下是不开的，你可以通过2种方式打开
- 使用parser配置
- 使用Spring属性(无法自定义parser的情况下，比如在SpringContext内部的使用)

编译器有3种运行模式，定义在`org.springframework.expression.spel.SpelCompilerMode`枚举中，它们是:
- `OFF`: 默认的模式，编译器关闭
- `IMMEDIATE`: 尽可能的编译表达式，通常是在第一次解释执行后，如果编译后的表达式运行失败，通常是因为元素类型改变，表达式求值的调用会接收到求值异常
- `MIXED`: 表达式可以在解释执行与编译执行之间切换，在解释执行几次后，切换到编译执行，如果编译执行出问题，表达式自动切换回解释执行，然后某个时间后生成新的编译形式并切换回编译执行

`IMMEDIATE`模式的存在是因为`MIXED`模式可能会导致具有副作用的表达式出现问题。如果编译表达式在部分成功后崩溃，则它可能已经做了一些影响系统状态的事情。如果发生这种情况，调用者可能不希望它以解释模式静默地重新运行，因为表达式的一部分可能会运行两次。在选择一个模式后，使用`SpelParserConfiguration`来配置解析器，下面是一个例子:
```java
SpelParserConfiguration config = new SpelParserConfiguration(SpelCompilerMode.IMMEDIATE,
		this.getClass().getClassLoader());
SpelExpressionParser parser = new SpelExpressionParser(config);
Expression expr = parser.parseExpression("payload");
MyMessage message = new MyMessage();
Object payload = expr.getValue(message);
```
当你指定编译模式时，也可以指定`Classloader`(null也是可以的)，编译后的表达式定义在提供的`ClassLoader`的子`Classloader`里面。如果指定了`Classloader`，需要确保它能加载到所有表达式中出现的类型。如果没有指定，则会使用一个默认的`Classloader`，通常是运行表达式的线程的Classloader。第二种方式是用来配置Spring组件内部的SpEL的，此时不能通过配置对象配置，在这种场景下，可以通过系统属性或者配置属性配置`spring.expression.compiler.mode`为`SpelCompilerMode`注解值。
## Compiler Limitations
Spring也不会对所有的表达式都编译，主要关注的是可能在性能比较重要的场景中使用的常见表达式，下面的表达式是不能被编译的
- 涉及到赋值的表达式
- 依赖conversion服务的表达式
- 使用自定义的resolvers或者accessor的表达式
- 使用重载运算符的表达式
- 使用数组构造语法的表达式
- 使用selection或者projection的表达式

# 在bean定义中使用表达式
在XML或者基于Java注解的bean定义方式中都可以使用表达式，使用的形式为`#{expression}`。
XML的配置方式如下所示：
```xml
<bean id="numberGuess" class="org.spring.samples.NumberGuess">
	<property name="randomNumber" value="#{ T(java.lang.Math).random() * 100.0 }"/>

	<!-- other properties -->
</bean>
```
应用上下文中的所有bean在SpEL中都是变量，变量名就是bean的名字，这包括Spring的标准Bean，比如用来访问运行环境的`environment`与`systemProperties`、`systemEnvironment`。下面是一个访问`systemProperties`的例子:
```xml
<bean id="taxCalculator" class="org.spring.samples.TaxCalculator">
	<property name="defaultLocale" value="#{ systemProperties['user.region'] }"/>
	<!-- other properties -->
</bean>
```
也可以访问其他的bean
```xml
<bean id="numberGuess" class="org.spring.samples.NumberGuess">
	<property name="randomNumber" value="#{ T(java.lang.Math).random() * 100.0 }"/>
	<!-- other properties -->
</bean>
<bean id="shapeGuess" class="org.spring.samples.ShapeGuess">
	<property name="initialShapeSeed" value="#{ numberGuess.randomNumber }"/>
	<!-- other properties -->
</bean>
```
在基于Java的配置方式中使用`@Value`的方式，可以放在field上、方法上或者方法与构造函数的参数上。下面的例子设置一个field的默认值
```java
public class FieldValueTestBean {

	@Value("#{ systemProperties['user.region'] }")
	private String defaultLocale;

	public void setDefaultLocale(String defaultLocale) {
		this.defaultLocale = defaultLocale;
	}

	public String getDefaultLocale() {
		return this.defaultLocale;
	}
}
```
下面的例子是使用setter方法的等价形式
```java
public class PropertyValueTestBean {

	private String defaultLocale;

	@Value("#{ systemProperties['user.region'] }")
	public void setDefaultLocale(String defaultLocale) {
		this.defaultLocale = defaultLocale;
	}

	public String getDefaultLocale() {
		return this.defaultLocale;
	}
}
```
自动注入的方法与构造函数也可以使用`@Value`注解，如下所示:
```java
public class SimpleMovieLister {

	private MovieFinder movieFinder;
	private String defaultLocale;

	@Autowired
	public void configure(MovieFinder movieFinder,
			@Value("#{ systemProperties['user.region'] }") String defaultLocale) {
		this.movieFinder = movieFinder;
		this.defaultLocale = defaultLocale;
	}

	// ...
}
public class MovieRecommender {

	private String defaultLocale;

	private CustomerPreferenceDao customerPreferenceDao;

	public MovieRecommender(CustomerPreferenceDao customerPreferenceDao,
			@Value("#{systemProperties['user.country']}") String defaultLocale) {
		this.customerPreferenceDao = customerPreferenceDao;
		this.defaultLocale = defaultLocale;
	}

	// ...
}
```
# 语言参考
## 简单文本表达式
简单文本里面支持的数据类型如下:
- String: 使用单引号活着双引号扩起来的字符串，字符串中出现的单引号字符需要转义，双单引号是转义前缀。
- Number: 支持负号、exponential notation、小数点、整数、16进制整数、实数
- Boolean: true/false
- Null: null

由于Spring表达式设计与实现的原因，数字始终是按照正数存储的，在求值计算时使用0-x表示-x。也就是说，不能表示Java中的最小负数。如果你要在表达式中使用类型的最小负数，有2种方式:
- 使用最小负数的常量表示，比如Integer.MIN_VALUE，表示成`T(Integer).MIN_VALUE`，需要一个`StandardEvaluationContext`
- -2^31, 只能用在`EvaluationContext`中

下面是简单的使用例子
```java
ExpressionParser parser = new SpelExpressionParser();

// evaluates to "Hello World"
String helloWorld = (String) parser.parseExpression("'Hello World'").getValue();

// evaluates to "Tony's Pizza"
String pizzaParlor = (String) parser.parseExpression("'Tony''s Pizza'").getValue();

double avogadrosNumber = (Double) parser.parseExpression("6.0221415E+23").getValue();

// evaluates to 2147483647
int maxValue = (Integer) parser.parseExpression("0x7FFFFFFF").getValue();

boolean trueValue = (Boolean) parser.parseExpression("true").getValue();

Object nullValue = parser.parseExpression("null").getValue();
```
## Properties、Arrays、Lists、Maps、Indexers
使用属性引用进行导航非常简单。使用点号表示内嵌的属性值。比如`Inventor`类对象
```java
int year = (Integer) parser.parseExpression("birthdate.year + 1900").getValue(context);
String city = (String) parser.parseExpression("placeOfBirth.city").getValue(context);
```
属性名的第一个字母是大小写不敏感的，因此上面的表达式可以写为`Birthdate.Year + 1900`与`PlaceOfBirth.City`，此外属性也能通过方法调用访问，比如`getPlaceOfBirth().getCity()`。数组与线性表的内容可以通过方括号获取如下所示:
```java
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();

// Inventions Array

// evaluates to "Induction motor"
String invention = parser.parseExpression("inventions[3]").getValue(
		context, tesla, String.class);

// Members List

// evaluates to "Nikola Tesla"
String name = parser.parseExpression("members[0].name").getValue(
		context, ieee, String.class);

// List and Array navigation
// evaluates to "Wireless communication"
String invention = parser.parseExpression("members[0].inventions[6]").getValue(
		context, ieee, String.class);
```
map的内容需要指定key
```java
// Officer's Dictionary

Inventor pupin = parser.parseExpression("officers['president']").getValue(
		societyContext, Inventor.class);

// evaluates to "Idvor"
String city = parser.parseExpression("officers['president'].placeOfBirth.city").getValue(
		societyContext, String.class);

// setting values
parser.parseExpression("officers['advisors'][0].placeOfBirth.country").setValue(
		societyContext, "Croatia");
```
## 内联lists && 内联map
使用{}表示内联list；内联Map也是同理；
```java
// evaluates to a Java list containing the four numbers
List numbers = (List) parser.parseExpression("{1,2,3,4}").getValue(context);

List listOfLists = (List) parser.parseExpression("{{'a','b'},{'x','y'}}").getValue(context);
```
`{}`表示一个空的数组，如果数组全部由常量组成，则数组本身就是常量的，计算结果也是常量，不会每次求值时产生新的数组。`{key:value}`表示map。
```java
// evaluates to a Java map containing the two entries
Map inventorInfo = (Map) parser.parseExpression("{name:'Nikola',dob:'10-July-1856'}").getValue(context);

Map mapOfMaps = (Map) parser.parseExpression("{name:{first:'Nikola',last:'Tesla'},dob:{day:10,month:'July',year:1856}}").getValue(context);
```
`{:}`本身表示一个空map，常量的理论与数组相同，key可以不用引号扩起来，如果有特殊字符比如.需要用引号扩起来。
## Array Construction
你可以使用java语法来构造数组。比如:
```java
int[] numbers1 = (int[]) parser.parseExpression("new int[4]").getValue(context);

// Array with initializer
int[] numbers2 = (int[]) parser.parseExpression("new int[] {1, 2, 3}").getValue(context);

// Multi dimensional array
int[][] numbers3 = (int[][]) parser.parseExpression("new int[4][5]").getValue(context);
```
构造多维数组的时候不能直接用字面量初始化。直接构造数组的表达式比如`new int[4]`或者`new int[]{1,2,3}`不能被编译。
## 方法
你可以使用Java编程语法来调用方法，你也可以调用字面量上的方法。变参也是支持的。下面是一个例子:
```java
// string literal, evaluates to "bc"
String bc = parser.parseExpression("'abc'.substring(1, 3)").getValue(String.class);

// evaluates to true
boolean isMember = parser.parseExpression("isMember('Mihajlo Pupin')").getValue(
		societyContext, Boolean.class);
```
## 操作符
Spring支持如下的操作符
- 关系操作符: 关系运算符使用通用的标记符号，可以比较数字类型与实现了`Comparable`接口的类型，下面是一个例子:
  ```java
	// evaluates to true
	boolean trueValue = parser.parseExpression("2 == 2").getValue(Boolean.class);

	// evaluates to false
	boolean falseValue = parser.parseExpression("2 < -5.0").getValue(Boolean.class);

	// evaluates to true
	boolean trueValue = parser.parseExpression("'black' < 'block'").getValue(Boolean.class);

	// uses CustomValue:::compareTo
	boolean trueValue = parser.parseExpression("new CustomValue(1) < new CustomValue(2)").getValue(Boolean.class);
  ```
  null值的大于与小于比较的规则，任何值都大于null。null表示nothing而不是0值。每个运算符都有简单的等价的文本表示，这是为了避免符号在特定的表达式中可能有别的含义
  - lt/<
  - gt/>
  - le/<=
  - ge/>=
  - eq/==
  - ne/!=
  
  文本运算符都是忽略大小写的。除此以外，SpEl还支持`between`、`instanceof`、基于正则表达式的`matches`运算符。下面是例子:
  ```java
	boolean result;

	// evaluates to true
	result = parser.parseExpression(
			"1 between {1, 5}").getValue(Boolean.class);

	// evaluates to false
	result = parser.parseExpression(
			"1 between {10, 15}").getValue(Boolean.class);

	// evaluates to true
	result = parser.parseExpression(
			"'elephant' between {'aardvark', 'zebra'}").getValue(Boolean.class);

	// evaluates to false
	result = parser.parseExpression(
			"'elephant' between {'aardvark', 'cobra'}").getValue(Boolean.class);

	// evaluates to true
	result = parser.parseExpression(
			"123 instanceof T(Integer)").getValue(Boolean.class);

	// evaluates to false
	result = parser.parseExpression(
			"'xyz' instanceof T(Integer)").getValue(Boolean.class);

	// evaluates to true
	result = parser.parseExpression(
			"'5.00' matches '^-?\\d+(\\.\\d{2})?$'").getValue(Boolean.class);

	// evaluates to false
	result = parser.parseExpression(
			"'5.0067' matches '^-?\\d+(\\.\\d{2})?$'").getValue(Boolean.class);
  ```
  `between`运算符的语法`<input> between {<range_begin>, <range_end>}`是`<input> >= <range_begin> && <input> <= <range_end>}`的快捷简写形式。需要注意基本类型，因为它们会被装箱成它们的包装类型，比如`1 instanceof T(int)`得到的是false，`1 instanceof T(Integer)`得到的是true
- 逻辑运算符: 支持下面的逻辑运算符
  - and(&&)
  - or(||)
  - not(!)
  
  文本运算符是忽略大小写的，下面是一个例子:
  ```java
	// -- AND --

	// evaluates to false
	boolean falseValue = parser.parseExpression("true and false").getValue(Boolean.class);

	// evaluates to true
	String expression = "isMember('Nikola Tesla') and isMember('Mihajlo Pupin')";
	boolean trueValue = parser.parseExpression(expression).getValue(societyContext, Boolean.class);

	// -- OR --

	// evaluates to true
	boolean trueValue = parser.parseExpression("true or false").getValue(Boolean.class);

	// evaluates to true
	String expression = "isMember('Nikola Tesla') or isMember('Albert Einstein')";
	boolean trueValue = parser.parseExpression(expression).getValue(societyContext, Boolean.class);

	// -- NOT --

	// evaluates to false
	boolean falseValue = parser.parseExpression("!true").getValue(Boolean.class);

	// -- AND and NOT --

	String expression = "isMember('Nikola Tesla') and !isMember('Mihajlo Pupin')";
	boolean falseValue = parser.parseExpression(expression).getValue(societyContext, Boolean.class);
  ```
- 字符串运算符: 支持下面的字符串运算符
  - concatenation(+)
  - subtraction(-)
  - repeat(*)
  
  ```java
	// -- Concatenation --
	// evaluates to "hello world"
	String helloWorld = parser.parseExpression("'hello' + ' ' + 'world'")
			.getValue(String.class);

	// -- Character Subtraction --

	// evaluates to 'a'
	char ch = parser.parseExpression("'d' - 3")
			.getValue(char.class);

	// -- Repeat --

	// evaluates to "abcabc"
	String repeated = parser.parseExpression("'abc' * 2")
			.getValue(String.class);
  ```
- 数学运算符: 支持下面的数字数学运算符，带有优先级
  - addition (+)
  - subtraction (-)
  - increment (++)
  - decrement (--)
  - multiplication (*)
  - division (/)
  - modulus (%)
  - exponential power (^)
  
  除法与取余运算符可以用`div`与`mod`表示，下面是例子
  ```java
	Inventor inventor = new Inventor();
	EvaluationContext context = SimpleEvaluationContext.forReadWriteDataBinding().build();

	// -- Addition --

	int two = parser.parseExpression("1 + 1").getValue(int.class);  // 2

	// -- Subtraction --

	int four = parser.parseExpression("1 - -3").getValue(int.class);  // 4

	double d = parser.parseExpression("1000.00 - 1e4").getValue(double.class);  // -9000

	// -- Increment --

	// The counter property in Inventor has an initial value of 0.

	// evaluates to 2; counter is now 1
	two = parser.parseExpression("counter++ + 2").getValue(context, inventor, int.class);

	// evaluates to 5; counter is now 2
	int five = parser.parseExpression("3 + ++counter").getValue(context, inventor, int.class);

	// -- Decrement --

	// The counter property in Inventor has a value of 2.

	// evaluates to 6; counter is now 1
	int six = parser.parseExpression("counter-- + 4").getValue(context, inventor, int.class);

	// evaluates to 5; counter is now 0
	five = parser.parseExpression("5 + --counter").getValue(context, inventor, int.class);

	// -- Multiplication --

	six = parser.parseExpression("-2 * -3").getValue(int.class);  // 6

	double twentyFour = parser.parseExpression("2.0 * 3e0 * 4").getValue(double.class);  // 24.0

	// -- Division --

	int minusTwo = parser.parseExpression("6 / -3").getValue(int.class);  // -2

	double one = parser.parseExpression("8.0 / 4e0 / 2").getValue(double.class);  // 1.0

	// -- Modulus --

	int three = parser.parseExpression("7 % 4").getValue(int.class);  // 3

	int oneInt = parser.parseExpression("8 / 5 % 2").getValue(int.class);  // 1

	// -- Exponential power --

	int maxInt = parser.parseExpression("(2^31) - 1").getValue(int.class);  // Integer.MAX_VALUE

	int minInt = parser.parseExpression("-2^31").getValue(int.class);  // Integer.MIN_VALUE

	// -- Operator precedence --

	int minusTwentyOne = parser.parseExpression("1+2-3*8").getValue(int.class);  // -21
  ```
- 赋值运算符: 设置一个属性值，使用赋值运算符(=)，可以通过表达式的`setValue`或者`getValue`实现，下面是例子:
  ```java
	Inventor inventor = new Inventor();
	EvaluationContext context = SimpleEvaluationContext.forReadWriteDataBinding().build();

	parser.parseExpression("name").setValue(context, inventor, "Aleksandar Seovic");

	// alternatively
	String aleks = parser.parseExpression(
			"name = 'Aleksandar Seovic'").getValue(context, inventor, String.class);
  ```
- 重载运算符: 缺省情况下，定义在SpEL的操作枚举中的数学运算符`ADD, SUBTRACT, DIVIDE, MULTIPLY, MODULUS, POWER`，支持简单的类型比如数字。通过提供`OperatorOverloader`重载，表达式语言可以让其他类型支持这些操作。比如，如果你要重载`ADD`操作符，使用+拼接2个list，可以这么实现:
  ```java
	pubic class ListConcatenation implements OperatorOverloader {

		@Override
		public boolean overridesOperation(Operation operation, Object left, Object right) {
			return (operation == Operation.ADD &&
					left instanceof List && right instanceof List);
		}

		@Override
		public Object operate(Operation operation, Object left, Object right) {
			if (operation == Operation.ADD &&
					left instanceof List list1 && right instanceof List list2) {

				List result = new ArrayList(list1);
				result.addAll(list2);
				return result;
			}
			throw new UnsupportedOperationException(
				"No overload for operation %s and operands [%s] and [%s]"
					.formatted(operation, left, right));
		}
	}
  ```
  然后我们将实现注册到`StandardEvaluationContext`中，我们可以对类似`{1, 2, 3} + {4, 5}`这样的表达式求值。
  ```java
	StandardEvaluationContext context = new StandardEvaluationContext();
	context.setOperatorOverloader(new ListConcatenation());

	// evaluates to a new list: [1, 2, 3, 4, 5]
	parser.parseExpression("{1, 2, 3} + {2 + 2, 5}").getValue(context, List.class);
  ```
  一个`OperatorOverloader`不能改变一个操作符的默认语义。使用重载操作符的表达式不能被编译。
## Types
你可以使用特殊的`T`操作符来指定一个`java.lang.Class`类型的实例。使用这个操作符来调用静态方法。`StandardEvaluationContext`使用一个`TypeLocator`来发现类型，`StandardTypeLocator`本身内置了对`java.lang`包的支持，也就是说当`T()`引用的是`java.lang`包里面的类型时是不需要使用全限定名的。但是其他类型的引用需要。下面是使用的例子:
```java
Class dateClass = parser.parseExpression("T(java.util.Date)").getValue(Class.class);
Class stringClass = parser.parseExpression("T(String)").getValue(Class.class);
boolean trueValue = parser.parseExpression(
		"T(java.math.RoundingMode).CEILING < T(java.math.RoundingMode).FLOOR")
		.getValue(Boolean.class);
```
如果你的应用或者框架有自己的`EvaluationContext`，你可能需要配置一个带有自己的`Classloader`的`StandardTypeLocator`来确保`SpEL`表达式解析器可以去加载类。
## Constructors
可以使用`new`操作符调用类的构造方法，构造方法需要类的全限定名，除了`java.lang`包下面的类。下面是一个例子:
```java
Inventor einstein = p.parseExpression(
		"new org.spring.samples.spel.inventor.Inventor('Albert Einstein', 'German')")
		.getValue(Inventor.class);

// create new Inventor instance within the add() method of List
p.parseExpression(
		"Members.add(new org.spring.samples.spel.inventor.Inventor(
			'Albert Einstein', 'German'))").getValue(societyContext);
```
## Variables
你可以在表达式中引用变量，语法`#variableName`，变量是使用`EvaluationContext`的`setVariable()`方法设置的。变量必须是字母、下划线或者$开头。当你向`EvaluationContext`中设置变量或者root context object，建议这些对象的类型都是`public`，否则，涉及具有非public类型的变量或根上下文对象的某些类型的SpEL表达式可能无法计算或编译。因为变量与`Function`共享上下文的同一个命名空间，需要确保2者名字不回冲突。
```java
Inventor tesla = new Inventor("Nikola Tesla", "Serbian");
EvaluationContext context = SimpleEvaluationContext.forReadWriteDataBinding().build();
context.setVariable("newName", "Mike Tesla");
parser.parseExpression("name = #newName").getValue(context, tesla);
System.out.println(tesla.getName());  // "Mike Tesla"
```
`#this`变量是内置的始终指向当前的求值上下文。`#root`也是内置的，引用root context obejct。`#this`会随着当前正在求值表达式的不同部分而不同，`#root`始终是相同的。
```java
// Create a list of prime integers.
List<Integer> primes = List.of(2, 3, 5, 7, 11, 13, 17);

// Create parser and set variable 'primes' as the list of integers.
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadWriteDataBinding().build();
context.setVariable("primes", primes);

// Select all prime numbers > 10 from the list (using selection ?{...}).
String expression = "#primes.?[#this > 10]";

// Evaluates to a list containing [11, 13, 17].
List<Integer> primesGreaterThanTen =
		parser.parseExpression(expression).getValue(context, List.class);
```
```java
// Create parser and evaluation context.
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadWriteDataBinding().build();

// Create an inventor to use as the root context object.
Inventor tesla = new Inventor("Nikola Tesla");
tesla.setInventions("Telephone repeater", "Tesla coil transformer");

// Iterate over all inventions of the Inventor referenced as the #root
// object, and generate a list of strings whose contents take the form
// "<inventor's name> invented the <invention>." (using projection !{...}).
String expression = "#root.inventions.![#root.name + ' invented the ' + #this + '.']";

// Evaluates to a list containing:
// "Nikola Tesla invented the Telephone repeater."
// "Nikola Tesla invented the Tesla coil transformer."
List<String> results = parser.parseExpression(expression)
		.getValue(context, tesla, List.class);
```
## Functions
你可以扩展SpEL，注册UDF。可以在表达式中调用，语法`#functionName(...)`，函数可以注册为`EvaluationContext`中的变量。`StandardEvaluationContext`也定义了`registerFunction(…​)`方法，可以注册函数为`java.lang.reflect.Method`或者`java.lang.invoke.MethodHandle`。下面是注册函数的例子
```java
Method method = ...;
EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();
context.setVariable("myFunction", method);
```
下面的例子
```java
public abstract class StringUtils {
	public static String reverseString(String input) {
		return new StringBuilder(input).reverse().toString();
	}
}
```
你可以使用前面的函数注册UDF并使用
```java
ExpressionParser parser = new SpelExpressionParser();

EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();
context.setVariable("reverseString",
		StringUtils.class.getMethod("reverseString", String.class));

// evaluates to "olleh"
String helloWorldReversed = parser.parseExpression(
		"#reverseString('hello')").getValue(context, String.class);
```
也可以通过`java.lang.invoke.MethodHandle`的方式注册函数，如果`MethodHandle`目标和参数在注册之前已完全绑定，则这可能会更有效； 但是，也支持部分绑定的handles。考虑方法`String#formatted(String, Object…​)`，根据模板与参数产生一个message。你可以将这个方法注册为一个`MethodHandle`，下面的例子:
```java
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();
MethodHandle mh = MethodHandles.lookup().findVirtual(String.class, "formatted",
		MethodType.methodType(String.class, Object[].class));
context.setVariable("message", mh);
// evaluates to "Simple message: <Hello World>"
String message = parser.parseExpression("#message('Simple message: <%s>', 'Hello World', 'ignored')")
		.getValue(context, String.class);
```
如上所述，还支持绑定`MethodHandle`并注册绑定的`MethodHandle`。如果目标和所有参数都被绑定，这会更高效。在这种情况下，SpEL表达式中不需要任何参数，如以下示例所示:
```java
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();

String template = "This is a %s message with %s words: <%s>";
Object varargs = new Object[] { "prerecorded", 3, "Oh Hello World!", "ignored" };
MethodHandle mh = MethodHandles.lookup().findVirtual(String.class, "formatted",
		MethodType.methodType(String.class, Object[].class))
		.bindTo(template)
		.bindTo(varargs); //here we have to provide arguments in a single array binding
context.setVariable("message", mh);

// evaluates to "This is a prerecorded message with 3 words: <Oh Hello World!>"
String message = parser.parseExpression("#message()")
		.getValue(context, String.class);
```
## Bean References
如果求值上下文配置了bean解析器。你可以在表达式中引用bean，使用`@`前缀符号。比如下面的代码:
```java
ExpressionParser parser = new SpelExpressionParser();
StandardEvaluationContext context = new StandardEvaluationContext();
context.setBeanResolver(new MyBeanResolver());

// This will end up calling resolve(context,"something") on MyBeanResolver during evaluation
Object bean = parser.parseExpression("@something").getValue(context);
```
如果要引用工厂bean本身，需要在bean的名字前面加上`&`符号
```java
ExpressionParser parser = new SpelExpressionParser();
StandardEvaluationContext context = new StandardEvaluationContext();
context.setBeanResolver(new MyBeanResolver());
// This will end up calling resolve(context,"&foo") on MyBeanResolver during evaluation
Object bean = parser.parseExpression("&foo").getValue(context);
```
## 三元操作符(If-Then-Else)
你可以使用三元操作符执行if-then-else条件逻辑。比如下面的
```java
String falseString = parser.parseExpression(
		"false ? 'trueExp' : 'falseExp'").getValue(String.class);
parser.parseExpression("name").setValue(societyContext, "IEEE");
societyContext.setVariable("queryName", "Nikola Tesla");

expression = "isMember(#queryName)? #queryName + ' is a member of the ' " +
		"+ Name + ' Society' : #queryName + ' is not a member of the ' + Name + ' Society'";

String queryResultString = parser.parseExpression(expression)
		.getValue(societyContext, String.class);
// queryResultString = "Nikola Tesla is a member of the IEEE Society"
```
## Elvis操作符
Elvis操作符是三目运算符的简写形式，用在Groovy语言中。三目运算符的语法通常需要一个变量重复2次。比如:
```java
String name = "Elvis Presley";
String displayName = (name != null ? name : "Unknown");
```
你可以使用Elvis运算符(得名于Elvis的发型)。
```java
ExpressionParser parser = new SpelExpressionParser();
String name = parser.parseExpression("name?:'Unknown'").getValue(new Inventor(), String.class);
System.out.println(name);  // 'Unknown'
```
SpEL的Elvis操作符除了检查null以外还会检查空字符串。
```java
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();

Inventor tesla = new Inventor("Nikola Tesla", "Serbian");
String name = parser.parseExpression("name?:'Elvis Presley'").getValue(context, tesla, String.class);
System.out.println(name);  // Nikola Tesla

tesla.setName("");
name = parser.parseExpression("name?:'Elvis Presley'").getValue(context, tesla, String.class);
System.out.println(name);  // Elvis Presley
```
你可以在表达式的默认值相关中使用Elvis操作符。

## 安全的导航操作符
安全导航操作符(?)是用来避免`NullPointerException`，来自于Groovy语言。通常来说，当你引用一个对象时，在访问对象的方法或者属性前需要验证对象是不是null，为了避免抛出异常或者null校验，安全导航操作符将会为null-safe操作返回null。下面的例子是如何使用安全导航操作符访问属性
```java
ExpressionParser parser = new SpelExpressionParser();
EvaluationContext context = SimpleEvaluationContext.forReadOnlyDataBinding().build();

Inventor tesla = new Inventor("Nikola Tesla", "Serbian");
tesla.setPlaceOfBirth(new PlaceOfBirth("Smiljan"));

// evaluates to "Smiljan"
String city = parser.parseExpression("placeOfBirth?.city") // 在非null的placeOfBirth属性上使用安全导航运算符
		.getValue(context, tesla, String.class);

tesla.setPlaceOfBirth(null);

// evaluates to null - does not throw NullPointerException
city = parser.parseExpression("placeOfBirth?.city") // 在null的placeOfBirth属性上使用安全导航运算符
		.getValue(context, tesla, String.class);
```
?也可以用于方法调用。Spring表达式语言支持集合选择与投影的安全导航
- null-safe selection: ?.?
- null-safe select first: ?.^
- null-safe select last: ?.$
- null-safe projection: ?.!

下面的例子展示了在集合选择中使用安全导航运算符
```java
ExpressionParser parser = new SpelExpressionParser();
IEEE society = new IEEE();
StandardEvaluationContext context = new StandardEvaluationContext(society);
String expression = "members?.?[nationality == 'Serbian']"; //members可能是null

// evaluates to [Inventor("Nikola Tesla")]
List<Inventor> list = (List<Inventor>) parser.parseExpression(expression)
		.getValue(context);

society.members = null;

// evaluates to null - does not throw a NullPointerException
list = (List<Inventor>) parser.parseExpression(expression)
		.getValue(context);
```
下面的例子展示了在集合选择中使用null-safe select first
```java
ExpressionParser parser = new SpelExpressionParser();
IEEE society = new IEEE();
StandardEvaluationContext context = new StandardEvaluationContext(society);
String expression =
	"members?.^[nationality == 'Serbian' || nationality == 'Idvor']"; 

// evaluates to Inventor("Nikola Tesla")
Inventor inventor = parser.parseExpression(expression)
		.getValue(context, Inventor.class);

society.members = null;

// evaluates to null - does not throw a NullPointerException
inventor = parser.parseExpression(expression)
		.getValue(context, Inventor.class);
```
下面的例子展示了在集合选择中使用null-safe select last
```java
ExpressionParser parser = new SpelExpressionParser();
IEEE society = new IEEE();
StandardEvaluationContext context = new StandardEvaluationContext(society);
String expression =
	"members?.$[nationality == 'Serbian' || nationality == 'Idvor']"; 

// evaluates to Inventor("Pupin")
Inventor inventor = parser.parseExpression(expression)
		.getValue(context, Inventor.class);

society.members = null;

// evaluates to null - does not throw a NullPointerException
inventor = parser.parseExpression(expression)
		.getValue(context, Inventor.class);
```
下面的例子展示了在集合投影中使用安全导航运算符
```java
ExpressionParser parser = new SpelExpressionParser();
IEEE society = new IEEE();
StandardEvaluationContext context = new StandardEvaluationContext(society);

// evaluates to ["Smiljan", "Idvor"]
List placesOfBirth = parser.parseExpression("members?.![placeOfBirth.city]") 
		.getValue(context, List.class);

society.members = null;

// evaluates to null - does not throw a NullPointerException
placesOfBirth = parser.parseExpression("members?.![placeOfBirth.city]") 
		.getValue(context, List.class);
```
正如本节开头所提到的，当安全导航运算符对于复合表达式中的特定null-safe操作计算结果为null时，复合表达式的其余部分仍将被计算。这意味着必须在整个复合表达式中应用安全导航运算符，以避免任何`NullPointerException`。给定表达式`#person?.address.city`，如果`#person`为 null，则安全导航运算符(?.)确保在尝试访问`#person`的地址属性时不会引发异常。但是，由于`#person?.address`的计算结果为null，因此在尝试访问null的`city`属性时将引发`NullPointerException`。为了解决这个问题，您可以在整个复合表达式中应用null-safe导航，如`#person?.address?.city`。如果`#person`或`#person?.address`计算结果为null，则该表达式将安全地计算为null。以下示例演示如何在复合表达式中结合使用集合上的null-safe select first运算符(?.^)和null-safe属性访问(?.)。如果`members`为null，则null-safe select first运算符(`members?.^[nationality == 'Serbian']`)的结果将为null，并且安全导航运算符(?.name)的额外使用可确保整个复合表达式的计算结果为null，而不是引发异常。
```java
ExpressionParser parser = new SpelExpressionParser();
IEEE society = new IEEE();
StandardEvaluationContext context = new StandardEvaluationContext(society);
String expression = "members?.^[nationality == 'Serbian']?.name"; 

// evaluates to "Nikola Tesla"
String name = parser.parseExpression(expression)
		.getValue(context, String.class);

society.members = null;

// evaluates to null - does not throw a NullPointerException
name = parser.parseExpression(expression)
		.getValue(context, String.class);
```
## 集合选择
选择是强大的表达式语言特性。可以将一个集合转换成另外一种集合。选择使用`.?[selectionExpression]`语法。它过滤集合并返回一个新的集合。包含了原来元素的一部分。比如下面的例子:
```java
List<Inventor> list = (List<Inventor>) parser.parseExpression(
		"members.?[nationality == 'Serbian']").getValue(societyContext);
```
选择支持数组或者实现了`java.lang.Iterable`与`java.util.Map`接口的实例。对于数组或者迭代来说，选择会作用于每个元素。对于map来说，选择作用于每个entry，entry的key与value可以在表达式中使用。下面是一个例子:
```java
Map newMap = parser.parseExpression("#map.?[value < 27]").getValue(Map.class);
```
除了返回所有选定的元素之外，您还可以仅检索第一个或最后一个元素。要获取与选择表达式匹配的第一个元素，语法为`.^[selectionExpression]`,要获取与选择表达式匹配的最后一个元素，语法为`.$[selectionExpression]`。
## 集合投影
投影让集合驱动子表达式的计算，结果是一个新集合。投影的语法是`.![projectionExpression]`。例如，假设我们有一个发明家列表，但想要他们出生的城市列表。实际上，我们希望评估发明人列表中每个条目的`placeOfBirth.city`。以下示例使用投影来执行此操作:
```java
// evaluates to ["Smiljan", "Idvor"]
List placesOfBirth = parser.parseExpression("members.![placeOfBirth.city]")
		.getValue(societyContext, List.class);
```
数组和任何实现`java.lang.Iterable`或`java.util.Map`的对象都支持投影。当使用map驱动投影时，将根据map中的每个条目(表示为Java Map.Entry)计算投影表达式。跨map投影的结果是一个列表，其中包含针对每个map条目的投影表达式的评估。
## 表达式模板
表达式模板允许在普通的文本中混合更多的求值块，形成一个文本模板；每个求值块都是通过特定的前缀与后缀包围的，定义求值块的前缀与后缀字符可以自由定义；缺省的是`#{}`分隔符。下面是一个例子：
```java
String randomPhrase = parser.parseExpression(
		"random number is #{T(java.lang.Math).random()}",
		new TemplateParserContext()).getValue(String.class);

// evaluates to "random number is 0.7038186818312008"

```
上面的例子中，表达式最终的结果是普通的文本random number is与`#{}`的求值结果拼接而成的，这个例子中，求值的结果是调用`random()`方法的结果，`parseExpression()`方法的第二个参数是`ParserContext`类型，`ParserContext`接口用来影响解析的过程，这是为了在解析过程中支持表达式模板的功能，TemplateParserContext的内容如下.
