MVEL受到Java语法的影响，也有一些区别，MVEL的目标是座位一个表达式语言效率更高，还具有直接操作集合、数组、字符串匹配、正则表达式等的操作符。MVEL用来对使用Java语法的表达式求值。除了表达式语言，MVEL也可以作为一个模板语言提供配置或者字符串构造。wiki page: [https://en.wikipedia.org/wiki/MVEL.](https://en.wikipedia.org/wiki/MVEL.)
MVEL 2.x表达式包括:
- Property expressions
- Boolean expressions
- Method invocations
- Variable assignments
- Function definitions

# Basic Syntax
MVEL是一个基于Java语法的表达式语言，具有一些特殊的功能。与Java不同，MVEL是动态类型的或者类型是可选的。也就是可以不用指定类型。MVEL解析起可以下载并集成到任何产品中。库暴露了API。如果一个表达式传给库的接口，表达式被求值并返回求值的结果。MVEL表达式可以是一个简单的标识符也可以是复杂的具有方法调用与集合创建的布尔表达式。
## Simple Property Expression
