Jakarta Expression Language(EL: 之前叫Expression Language与Unified Expression Language)是一个特殊目的的编程语言。大部分用在JakartaEE的web应用中，主要嵌入在web页面中，并对表达式求值。Java EE Web技术规范的起草人与专家组在JSP2.1规范(JSR-245)中首次引入统一EL的概念。后续在Java EE 7中独立对EL起草了规范(JSR-341)。
# History
## Origin as JSTL
el起始于JSTL(JavaServer Pages Standard Tag Library)的一部分，最初叫做SPEL(Simplest Possible EXpression Language)，然后独立成Expression Language的概念。它是一个脚本语言，允许通过JSP访问Java对象内容。从JSP2.0开始，它主要用在JSP tag内来从JSP内分隔处Java代码。允许更方便的访问Java对象(比纯粹的Java代码)。
## JSP 2.0
几年过去了，EL逐渐演化，并包含了更高级的功能。并且被包含进了JSP2.0规范中。对于Web内容设计者来说，脚本更容易编写，因为不需要太多的Java语言知识或者需要很少的Java语言知识就可以编写。EL表达式从语义或者语法上类似JavaScript表达式
- 没有类型转换
- 类型转换是隐式完成的
- 单双引号是相同的
- `object.property`等价于`object['property']`

EL释放了程序员，编写者不需要知道如何访问对象内容的细节。`object.property`意味着`object.getProperty("property")`或者`object.getProperty`。
## EL 2.1
在JSP2.0的发展期间，JavaServer Faces(JSF)技术被发布出来，这项技术也需要el。但是JSP2.0规范中定义的EL不满足JSF的需求。最明显的限制是它的表达式是立即求值的，JSF组件不能调用服务端对象的方法。EL的更强大的版本被开发出来:
- 延迟表达式，不会立即求值
- 表达式可以设置值
- 方法表达式，可以调用方法

新的表达式语言满足了JSF的需求。但是新的JSF EL无法处理JSP的EL因为冲突于不兼容。于是需要一种统一的EL来协调处理这些EL。到了JSP2.1，JSP2.0中的EL于JSF1.1中的EL合并成一个统一的EL，EL2.1。
## EL 3.0
EL的3.0版本(统一的EL不在需求了)在JSR规范提案中开发出来，这是独立于JSP与JSF的JSR-341规范。添加了新的特性。新的EL等价于Java8的stream与lambda表达式。
## EL 4.0
4.0版本在2020-10-07发布，API从javax.el包移到了jakarta.el包。也是从Java EE转换为Jakarta EE的一部分。
