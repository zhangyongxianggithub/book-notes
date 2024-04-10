JUEL是统一EL(JSP 2.1标准JSR-245)的实现，第一次在JEE5引入。
# Motivation
最初，EL是作为JSTL的一部分存在，然后进入了JSP2.0规范。现在作为JSP2.1规范的一部分。EL API被分离到`javax.el`包中。所有对核心JSP类依赖的部分都被移除了。也就是说，EL也可以在非JSP应用中使用。
# Features
JUEL提供了统一EL的轻量级的高效实现
- 高性能，解析表达式是最大的性能瓶颈。JUEL使用硬编码解析器比之前使用的生成式解析器快10倍。一旦构建好，表达式树会以更高的速度求值。
- 可插拔的Cache，即使JUEL解析器非常快，解析表达式仍然是代价非常高的。因此，最好只解析表达式一次。JUEL提供了默认的缓存机制。在大部分场景下足够满足要求了。JUEL也可以插入你自己实现的cache
- Small Footprint，JUEL是仔细设计过的库，代码量足够小，占用内存也比较小
- Method Invocations，支持方法调用比如`${foo.matches('[0-9]+')}`，方法被解析，然后使用EL的解析器机制调用。
- VarArg Call，JUEL支持Java5的可变参数，比如绑定函数`String.format(String, String...)`到`format`，这样`${format('Hey %s','Joe')}`就可以使用了
- Pluggable，JUEL作为一个EL实现可以通过SPI机制被自动检测到，使用JUEL不需要应用代码明确的饮用任何JUEL相关的实现代码
# Getting Started
JUEl包含下列的JAR文件
- juel-api-2.2.x.jar包含`javax.el`API类
- juel-impl-2.2.x.jar包含`de.odysseus.el`实现类
- juel-spi-2.2.x.jar包含`META-INF/service/javax.el.ExpressionFactory`service provider resource。如果在classpath你有多个EL表达式语言的实现并且想要强制`ExpressionFactory.newInstance()`选择JUEL实现

在应用中使用EL的方式：
- Factory and Context
  ```java
  // the ExpressionFactory implementation is de.odysseus.el.ExpressionFactoryImpl
  ExpressionFactory factory = new de.odysseus.el.ExpressionFactoryImpl();

  // package de.odysseus.el.util provides a ready-to-use subclass of ELContext
  de.odysseus.el.util.SimpleContext context = new de.odysseus.el.util.SimpleContext();
  ```
- Functions and Variables
  ```java
  // map function math:max(int, int) to java.lang.Math.max(int, int)
  context.setFunction("math", "max", Math.class.getMethod("max", int.class, int.class));

  // map variable foo to 0
  context.setVariable("foo", factory.createValueExpression(0, int.class));
  ```
- Parse and Evaluate
  ```java
  // parse our expression
  ValueExpression e = factory.createValueExpression(context, "${math:max(foo,bar)}", int.class);

  // set value for top-level property "bar" to 1
  factory.createValueExpression(context, "${bar}", int.class).setValue(context, 1);

  // get value for our expression
  System.out.println(e.getValue(context)); // --> 1
  ```
