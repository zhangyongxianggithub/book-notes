Vavr前身叫做javaslang，是一个java8+的函数库，provides persistent data types and functional control structures.
# introduction
## Functional Data Structures in java8 with Vavr
Java8的lambda表达式让我们可以创建完美的API，它们增强的java的表达式功能，Vavr通过lambda创建了很多机遇函数式编程的新特性，其中一个就是函数式的集合库，是替代java标准集合库的完美替代者。
## 函数式编程
在开始讲述一些最基本的数据结构前，这一节会帮助你了解下，创建Vavr与Java集合库的一些背景。
### 副作用
Java 应用程序通常有很多副作用。 它们使某种状态发生变异，也许是外部世界。 常见的副作用是更改对象或变量、打印到控制台、写入日志文件或数据库。 如果副作用以不受欢迎的方式影响我们程序的语义，则它们被认为是有害的。
例如，如果一个函数抛出一个异常并且这个异常被解释，它被认为是影响我们程序的副作用。 此外，异常就像非本地 goto 语句。 它们破坏了正常的控制流。 然而，现实世界的应用程序确实会产生副作用。
```java
int divide(int dividend, int divisor) {
    // throws if divisor is zero
    return dividend / divisor;
}
```
使用函数式的编程场景，我们更倾向把副作用（异常）压缩到一个Try中
```java
Try<Integer> divide(Integer dividend, Integer divisor) {
    return Try.of(() -> dividend / divisor);
}
```
这样，函数不会再抛出异常，我们通过Try让可能发生的失败暴漏出来。
### 引用透明度
对于一个函数，或者更普遍的表达式来说，引用透明指的是一个调用可以在不影响程序行为的情况下被它的值替换，简单来说，给出以下输入，输出是一致的
```java
// not referentially transparent
Math.random();

// referentially transparent
Math.max(1, 2);
```
如果函数中的所有的表达式都是引用透明的，那么这个函数被称为透明函数，由纯函数组成的应用程序虽然很可能在编译后才能工作，但是我们能够对此进行推理。 单元测试很容易编写，调试成为过去的遗物。