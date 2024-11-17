# Installation
## Java
将相关的依赖放到CLASSPATH中
```shell
$ export CLASSPATH="/usr/local/lib/ST-4.3.4.jar:$CLASSPATH"
```
或者使用Maven
```xml
<dependency>
    <groupId>org.antlr</groupId>
    <artifactId>ST4</artifactId>
    <version>4.3.4</version>
</dependency>
```
一个helloworld
```java
import org.stringtemplate.v4.*;
public class Hello {
    public static void main(String[] args) {
        ST hello = new ST("Hello, <name>");
        hello.add("name", "World");
        System.out.println(hello.render());
    }
}
```
ST中包含模板组的概念。如果是一个组文件，使用`STGroup`的子类`STGroupFile`
```java
//load file name
STGroup g = new STGroupFile("test.stg");
```
就是在当前启动目录中寻找`test.stg`，如果没发现，就在CLASSPATH中寻找，也可以使用相对目录。下面是在子目录中寻找，如果没有就去CLASSPATH中去寻找
```java
// load relative file name
STGroup g = new STGroupFile("templates/test.stg");
```
也可以使用绝对路径
```java
// load fully qualified file name
STGroup g = new STGroupFile("/usr/local/share/templates/test.stg");
```
组文件类似把很多模板目录打包起来放到一个单一文件中，为了在一个目录加载所有以`.st`结尾文件的模板文件，使用`STGroupDir`
```java
// load relative directory of templates
STGroup g = new STGroupDir("templates");
```
如果在当前目录中没找到，则去CLASSSPATH中寻找，也可以使用绝对路径
```java
// load fully qualified directory of templates
STGroup g = new STGroupDir("/usr/local/share/templates");
```
文本模板组，就是把很多的模板文本打包到一个字符串文本中
```java
String g =
    "a(x) ::= <<foo>>\n"+
    "b() ::= <<bar>>\n";
STGroup group = new STGroupString(g);
ST st = group.getInstanceOf("a");
String expected = "foo";
String result = st.render();
assertEquals(expected, result);
```
**注意: URL/URI/Path中存在一些问题**: 确保参数是一个有效的文件名或者是一个有效的URL对象。比如
- foo.stg
- foo
- org/foo/templates/main.stg
- org/foo/templates
- /tmp/foo

不能是
```java
// BAD
STGroup modelSTG = new STGroupFile(url.getPath());
```
这会产生一个与jar包相关的文件路径`file:/somedirectory/AJARFILE.jar!/foo/main.stg`，这不是一个有效的文件系统标识符。
# Introduction
首先，为了学些ST的思想哲学体系，阅读论文[Enforcing Strict Model-View Separation in Template Engines](https://www.cs.usfca.edu/~parrt/papers/mvc.templates.pdf)，大多数的生成源代码或者其他文本输出的程序都是非结构化(不能获知整个文本的结构)的生成逻辑块。输出是通过print语句实现的，主要的原因是取法合适的工具与合适的形式。正确的形式主义是输出语法，因为您不是在生成随机字符——而是在用输出语言生成句子。这类似于使用语法来描述输入句子的结构。大多数程序员不会手动构建解析器，而是使用解析器生成器。同样，我们需要某种形式的反解析器生成器来生成文本。输出语法最方便的表现形式是模板引擎，例如StringTemplate。模板引擎只是一个使用模板输出文本的生成器，模板实际上只是带有洞的文档，您可以在其中粘贴名为属性的值。属性可以是程序对象(例如字符串或`VarSymbol`对象)、模板实例或包括其他序列的属性序列。模板引擎是用于生成结构化文本的领域特定语言。`StringTemplate`将模板分解为文本块和属性表达式，默认情况下，这些文本块和属性表达式括在尖括号中（但您可以使用任何单个字符的开始和结束分隔符）。`StringTemplate`忽略属性表达式之外的所有内容，将其视为要吐出的文本。要对模板求值并生成文本，我们使用方法调用来`render`它: `ST.render()`。比如，下面的文本有2个块，一个是普通文本，一个是引用name属性`Hello, <name>`。使用模板引擎是很简单的，下面是一个例子
```java
import org.stringtemplate.v4.*;
...
ST hello = new ST("Hello, <name>");
hello.add("name", "World");
System.out.println(hello.render());
```
>MVC模式: 按照MVC模式来说，模板输出视图，代码片段表示模型数据与控制器(负责从模型中拉取数据并注入属性到视图中)。`StringTemplate`不是一个系统、引擎、服务器。它是嵌入到应用中的一个组件库，只依赖`ANTLR`(负责解析模板语言)。
## 模板组
主要的类`ST`、`STGroupDir`、`STGroupFile`，你可以在代码中直接创建模板，也可以从一个目录或者一个文件中加载模板，组文件类似模板目录的zip/jar包形式。假如有2个模板`decl.st`与`init.st`在目录/tmp下
```st
// file /tmp/decl.st
decl(type, name, value) ::= "<type> <name><init(value)>;"

// file /tmp/init.st
init(v) ::= "<if(v)> = <v><endif>"
```
我们可以创建一个`STGroupDir`对象来加载这些模板，然后调用`getInstanceOf()`方法获得一个instance，使用`add()`方法注入属性
```java
STGroup group = new STGroupDir("/tmp");
ST st = group.getInstanceOf("decl");
st.add("type", "int");
st.add("name", "x");
st.add("value", 0);
String result = st.render(); // yields "int x = 0;"
```
如果你只需要模板文本内容不想要规范的模板定义，可以使用`STRawGroupDir`，那么`decl.st`文件的中的内容如下:
```
// file /tmp/decl.st
<type> <name><init(value)>;
```
对于界面设计者或者HTML人来说会更方便，这个例子展示了一些关键的语法与特性。模板定义非常类似函数定义。模板`decl`带有3个参数，但是只是直接使用其中2个，相比于直接扩展`value`参数，它invokes/include模板init,并将value作为参数传递过去。或者，模板init可以不提供任何参数，但由于动态作用域，它仍将看到属性value。这实际上意味着模板可以引用任何调用模板的属性。为了获得正确的间距，表达式`<name>`和`<init()>`之间不能有空格。如果我们不注入声明初始化(属性值)，我们不希望在名称和;之间留空格。仅当控制器代码注入值时，模板init才会输出`= <v>`，我们在这里执行此操作（0）。在本例中，我们注入了两个字符串和一个整数，但我们可以发送任何我们想要的对象；下面将详细介绍。有时将模板收集到一个称为组文件的单元中更方便。例如，我们可以将单独的模板.st文件中的定义收集到一个等效的.stg组文件中:
```stg
// file /tmp/test.stg
decl(type, name, value) ::= "<type> <name><init(value)>;"
init(v) ::= "<if(v)> = <v><endif>"
```
使用下面的代码加载模板
```java
STGroup group = new STGroupFile("/tmp/test.stg");
ST st = group.getInstanceOf("decl");
st.add("type", "int");
st.add("name", "x");
st.add("value", 0);
String result = st.render(); // yields "int x = 0;"
```
## 访问模型对象的属性
模板表达式可以访问模型对象的属性，比如，下面的`User`对象
```java
public static class User {
    public int id; // template can directly access via u.id
    private String name; // template can't access this
    public User(int id, String name) { this.id = id; this.name = name; }
    public boolean isManager() { return true; } // u.manager
    public boolean hasParkingSpot() { return true; } // u.parkingSpot
    public String getName() { return name; } // u.name
    public String toString() { return id+":"+name; } // u
}
```
我们可以注入`User`对象并且可以使用`.`来引用属性，比如`o.p`就解释为在`o`对象中查找`p`，遵循JavaBeans命名约定，`StringTemplate`首先查找方法`getP()`、`isP()`、`hasP()`。如果找不到，则寻找`p`字段
```java
ST st = new ST("<b>$u.id$</b>: $u.name$", '$', '$');
st.add("u", new User(999, "parrt"));
String result = st.render(); // "<b>999</b>: parrt"
```
StringTemplate使用`render()`方法渲染注入的所有的属性，并将属性输出为文本。在这个例子中，`$u$`将会输出`999:parrt`.
## 注入数据聚合属性
能够传入对象并访问其字段非常方便，但我们通常没有方便的对象来注入。创建一次性数据很麻烦，您必须定义一个新类才能关联两块数据。StringTemplate使在`add()`调用期间对数据进行分组变得容易。您可以将聚合属性名称与要聚合的数据一起传递给`add()`。属性名称的语法描述了属性。例如， 属性名称`a.{p1,p2,p3}`描述一个名为`a`的属性，该属性具有三个属性 p1、p2、p3。以下是一个例子:
```java
ST st = new ST("<items:{it|<it.id>: <it.lastName>, <it.firstName>\n}>");
st.addAggr("items.{ firstName ,lastName, id }", "Ter", "Parr", 99); // add() uses varargs
st.addAggr("items.{firstName, lastName ,id}", "Tom", "Burns", 34);
String expecting =
        "99: Parr, Ter\n"+
        "34: Burns, Tom\n"+
```
## 将模板应用到属性
让我们更仔细的看下`StringTemplate`如何呈现属性。它不区分单值与多值属性，比如，我们将值为parrt的name属性添加到模板，输出为parrt，如果调用2次add,分别添加值为parrt与tombu给name属性，输出为parrttombu，换句话说，多值属性会输出为字符串拼接的形式。要插入分隔符，我们可以使用分隔符选项：`<name;separator=",">`。在不更改我们注入的属性的情况下，该模板的输出为parrt,tombu。要更改每个元素发输出，我们需要对它们进行迭代。StringTemplate没有`foreach`语句。相反，我们将模板应用于属性。例如，下面的例子使用用方括号括住每个name的值，我们可以定义一个括号模板并将其应用于名称：
```st
test(name) ::= "<name:bracket()>" // apply bracket template to each name
bracket(x) ::= "[<x>]"            // surround parameter with square brackets
```
注入我们的name值的列表，输出`[parrt][tombu]`，StringTemplate认为应用模板的第一个参数就是要迭代的值，在这里就是x，也就是x表示name中的迭代值，因为name应用了`bracket()`。加上分隔符语法
```st
test(name) ::= "<name:bracket(); separator=\", \">"
bracket(x) ::= "[<x>]"
```
StringTemplate是动态类型的，因为它不关心元素的类型，除非我们访问属性。例如，我们可以传入`User`对象列表，`User(999,"parrt")`和`User(1000,"tombu")`，模板无需更改即可工作。StringTemplate将使用实现语言的toString评估函数来对`<x>`求值。我们得到的输出是`[999:parrt], [1000:tombu]`。有时，对于一次性模板或非常小的模板来说，创建单独的模板定义太费力了。在这些情况下，我们可以使用匿名模板（或子模板）。匿名模板是没有用花括号括起来的名称的模板。但它们可以像常规模板一样有参数。例如，我们可以按如下方式重做上述示例。
```st
test(name) ::= "<name:{x | [<x>]}; separator=\", \">"
```
`{x | [<x>]}`是`bracket()`的内联版本，参数名与模板内容实用`|`管道符来分割。StringTemplate将遍历任何可以合理地解释为元素集合的对象，例如数组、列表、字典以及在静态类型中满足可迭代或枚举接口的对象。
## 格式化用法
实用`ST.format()`
```java
int[] num =
    new int[] {3,9,20,2,1,4,6,32,5,6,77,888,2,1,6,32,5,6,77,
        4,9,20,2,1,4,63,9,20,2,1,4,6,32,5,6,77,6,32,5,6,77,
        3,9,20,2,1,4,6,32,5,6,77,888,1,6,32,5};
String t =
    ST.format(30, "int <%1>[] = { <%2; wrap, anchor, separator=\", \"> };", "a", num);
System.out.println(t);
```
# StringTemplate速查表

