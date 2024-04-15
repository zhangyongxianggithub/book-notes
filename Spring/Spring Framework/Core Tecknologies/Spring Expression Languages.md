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
缺省情况下，SpEL使用Spring环境中的`org.springframework.core.convert.ConversionService`进行类型转换；这个转换器服务包含了很多内置的类型转换器，也可以实现自定义的类型转换器。另外，它还可以识别泛型，也就是说，当在表达式中使用泛型类型时，SpEL会尝试进行转换以维护它遇到的任何对象的类型正确性。
1.4.2.2 解析器配置
可以使用解析器配置对象配置SpEL解析器；SpelParserConfiguration；
1.4.2.3 SpEL编译
SpEL提供了极大的灵活性，但是求值计算的过程就没有考虑到性能，在一般的表达式语言使用环境中，使用是没问题的，但是集成到Spring环境中是，就需要考虑SpEL的性能；SpEL编译器就是为了解决这个问题；
1.4.3 在bean定义中使用表达式
在XML或者基于Java注解的bean定义方式中可以使用表达式，使用的形式为#{expression}。
XML的配置方式如下所示：


在基于Java的配置方式中使用@Value的方式。
1.4.4 语言参考
1.4.4.1 简单文本表达式
支持字符串、数字、布尔、与null等；
1.4.4.2 Properties、Arrays、Lists、Maps、Indexers
访问Object的属性，数组的属性或者Map的属性；大小写不敏感；
1.4.4.3 内联lists
使用{}表示内联list；内联Map也是同理；
1.4.4.5 数组构造器

1.4.4.6 方法

1.4.4.7 操作符
关系运算符都是支持的，但是注意任何值都比null大；支持instanceof判断对象类型，也支持matches进行正则表达式匹配；逻辑运算符and or not；数学运算符。
1.4.4.8 赋值
给对象里面的属性赋值可以使用setValue或者getValue都可以；
1.4.4.9 类型
T()操作符，相当于Class.forName，引入一个Class的实例；
1.4.4.10 构造方法
可以直接调用类的构造方法；必须是全路径的类；
1.4.4.11 变量
变量使用#name的形式引用，使用EvaluationContext的setVariable方法设置变量；比如：

#this始终指向当前的求值对象；#root变量指向root context对象；#this会根据求值表达式的变化而变化，root不会。
1.4.4.12 函数
函数保存在EvaluationContext中，定义函数的方法如下：

1.4.4.13 Bean引用
向EvaluationContext注入一个Bean解析器的时候，可以引用到Bean；例子如下：

为了能够引用到工厂bean1自身，工厂bean的引用形式是&foo。
1.4.4.14 结构表达式
三元操作符?:
1.4.4.16 安全的导航操作符
?
1.4.4.17 集合选择
.?[selectionExpression]
1.4.4.18 集合保护
1.4.4.19 表达式模板
表达式模板允许在普通的文本中混合更多的求值块，形成一个文本模板；每个求值块都是通过特定的前缀与后缀包围的，定义求值块的前缀与后缀字符可以自由定义；缺省的是#{}分隔符。下面是一个例子：

上面的例子中，表达式最终的结果是普通的文本’random number is ’与#{}的求值结果拼接而成的，这个例子中，求值的结果是调用random()方法的结果，parseExpression()方法的第二个参数是ParserContext类型，ParserContext接口用来影响解析的过程，这是为了在解析过程中支持表达式模板的功能，TemplateParserContext的内容如下：
