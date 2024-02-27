[TOC]
# 14 Java模块化系统
Java的模块化系统诞生于Jigsaw项目，从Java9开始引入，演进了很多年，具有很大意义，本章只做简单的介绍。
## 模块化的驱动力: 软件的推理
2个设计模式:
- 关注点分离，separation of concern。将程序分解为一个个相互独立的特性。可以将这些特性划分到模块，一个例子开发结算应用，需要能解析各种格式的开销，能对结果进行分析，进而为顾客提供汇总报告。采用关注点分离，可以将文件的解析、分析以及报告划分到各个模块中，模块是内聚的，模块之间是松耦合的。关注点分离使各项工作可以独立开展，减少了组件的相互依赖，便于团队合作完成项目；利于推动组件重用，系统的整体维护性更好
- 信息隐藏，information hiding，尽量隐藏实现的细节。可以帮助减少局部变更对程序其他部分的影响，避免变更传递，

可以创建易于理解的软件。
## 为什么要设计Java模块化系统
## Java模块: 全局视图
模块在module-info.java中声明分为3个部分:
- module {module-name}，为模块声明一个名字
- requires {module names} 依赖的模块名
- exports {package names} 导出的包名
## 使用Java模块系统开发应用
创建一个例子应用
```java
module expense.application {}
```
执行下面的命令:
```shell
javac module-info.java com/exmaple/expenses/application/ExpensesApplication.java -d target
jar cvfe expenses-application.jar com.exmaple.expenses.application.ExpensesApplication -C target .
java --module-path expenses-application.jar --module expense.application/com.exmaple.expenses.application.ExpensesApplication
```
## 使用多个模块
exports的使用例子，其中都是包名而不是模块名，声明的包未公有类型，可以被其他模块访问和调用。默认情况下，模块内的所有包都是被封装的。
```java
module expenses.readers {
    exports com.example.expenses.readers;
    exports com.example.expenses.readers.file;
    exports com.example.expenses.readers.http;
}
```
requires的例子
```java
module expenses.readers {
    requires java.base;
    exports com.example.expenses.readers;
    exports com.example.expenses.readers.file;
    exports com.example.expenses.readers.http;
}
```
指定本地模块对其他模块的依赖。默认依赖java.base的平台模块。它包含了Java主要的包(net、io、util)。Oracle推荐模块的命名与包的命名类似。即互联网域名规范的逆序。
## 编译与打包
每一个模块都能单独编译。2个模块。
readers模块
```java
module expenses.readers {
    requires java.base;
    exports com.example.expenses.readers;
    exports com.example.expenses.readers.file;
    exports com.example.expenses.readers.http;
}
```
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <artifactId>expenses.readers</artifactId>
    <packaging>jar</packaging>
    <parent>
        <groupId>com.example</groupId>
        <artifactId>expenses</artifactId>
        <version>1.0</version>
    </parent>
</project>
```
application模块
```java
module expenses.application {
    requires expenses.readers;
    requires java.base;
}
```
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <artifactId>expenses.application</artifactId>
    <packaging>jar</packaging>
    <parent>
        <groupId>com.example</groupId>
        <artifactId>expenses</artifactId>
        <version>1.0</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>com.example</groupId>
            <artifactId>expenses.readers</artifactId>
            <version>1.0</version>
        </dependency>
    </dependencies>
</project>
```
启动命令
```shell
java --module-path  ./expenses.application/target/expenses.application-1.0.jar:./expenses.readers/target/expenses.readers-1.0.jar --module  expenses.application/com.example.expenses.application.ExpensesApplication
```
## 自动模块
使用第三方库的时候，在maven的pom中引入依赖，同时使用`requires jar name`来添加模块依赖。Java会将这个jar包转换为自动模块。模块路径不带module-info.jave文件的jar都会被转换为自动模块。自动模块默认导出所有的包。自动模块的名字根据Jar的名字自动创建，此时运行程序的代码:
```java
java --module-path  ./expenses.application/target/expenses.application-1.0.jar:./expenses.readers/target/expenses.readers-1.0.jar:./expenses.readers/target/lombok-1.18.30.jar --module  expenses.application/com.example.expenses.application.ExpensesApplication
```
## 模块声明及子句
- requires，设定此模块的依赖
- exports，将包声明为公有类型，默认所有包不导出
- requires的传递，`requires transitive com.iteratrlearning.core`
- exports to,
- open/opens, 使其他模块可以用反射的方式访问它所有的包。就是允许对模块进行反射访问。
- uses/provides

# CompletableFuture及反应式编程背后的概念
软件编写方式的变化:
- 多核带来并行处理，大任务拆小任务
- 软件的微服务化，小型化与分布式联网化

并发是一种编程属性（重叠的执行），在单核的机器上也可以执行，并行是同时执行时一种硬件属性
## 为支持并发而不断演进的Java
- 最开始的版本提供了锁(synchronized)、runnable与线程
- 2004，Java5引入了`java.util.concurrent`包，`ExecutorService`将任务提交与任务执行解耦，`Callable<T>`与`Future<T>`生成一个高度封装的`Runnable`与一个`Thread`变体。
- Java7引入了fork/join实现分而治之算法新增了`java.util.concurrent.RecursiveTask`
- Java8引入了流与流的并行处理与`CompletableFuture`
- Java9分布式异步编程

理念就是提供一种程序结构让相互独立的任务尽可能并发执行。
Java线程的问题
- java线程是操作系统线程，创建于销毁的代价很大(页表操作)
- 操作系统的线程数目是有限的
- 操作系统的线程于硬件的线程不是一回事，通常线程的最优数据等于硬件线程数目

线程池的优势
- 可以获取结果
- 任务的执行与任务的提交分离，这样任务的执行可以以与硬件最匹配的方式执行，无需手动处理，降低编程的负担
- 成本低，线程重复使用
- 关于任务的处理提供了更多的可配置功能

线程池的劣势
- 线程池有并发执行的上限
- 如果任务里面有阻塞或者事件等造成线程休眠，会降低线程池的并发性，其他任务得不到执行，避免提交可能阻塞的任务

## 同步/异步API
Java8的stream流并行的2个优势:
- 内部迭代代替外部迭代
- 不需要手动创建线程并管理线程，底层已经做好了

函数`int f(int x)`与`int g(int x)`都是同步API，物理上返回时执行结果也一同返回。
```java
        var x = 1337;
        int y = f(x);
        int z = g(x);
        System.out.println(y + z);
```
串行执行是2个方法之和，如果2个任务没有依赖关系。并发执行是2个中耗时最长的那个。有几种并发的方式
- 直接使用`Thread`类，并使用`join`来等待，缺点是需要开发人员显式的操纵所有的线程
- 使用`ExecutorService`线程池，缺点是需要手动多次调用submit来提交任务
- 异步API，就是在返回结果之前就返回函数执行，使用`Future`或者增强版`CompletableFuture`
- 异步API，就是在返回结果之前就返回函数执行，使用`java.util.concurrent.Flow`接口的响应式编程API

1. Future风格的API
   ```java
    final Future<Integer> yf = fAsync(x);
    final Future<Integer> zf = gAsync(x);
    System.out.println(yf.get() + zf.get());
   ```
   方法返回一个Future对象包含一个继续执行方法体中原始内容的任务并立刻返回。`get()`方法等待执行完毕。
2. 反应式风格的API
   核心思想是使用回调风格的编程。
   ```java
   public class CallbackStyleExample {
    public static void main(final String[] args) {
        final int x = 1337;
        final Result result = new Result();
        f(x, y -> {
            result.left = y;
            System.out.println(result.left + result.right);
        });
        f(x, z -> {
            result.right = z;
            System.out.println(result.left + result.right);
        });
        
    }
    
    private static class Result {
        private int left;
        private int right;
    }
    
    private static void f(final int x, final IntConsumer dealWithResult) {
        dealWithResult.accept(x * x);
    }
    
    private static void g(final int x, final IntConsumer dealWithResult) {
        dealWithResult.accept(x + x);
    }
    }

   ```
3. 有害的睡眠及其他阻塞式操作，任务在执行时占用系统资源，目标是让它们持续的处于运行状态，直到执行完毕释放资源，其中如果有阻塞操作，会阻塞整体任务的执行
4. 如果使用异步API进行异常处理，可以使用`CompletableFuture`的`get()`方法返回异常信息或者通过`exceptionally()`处理异常信息。对于反应式异步API，需要使用回调函数来处理异常。比如`void f(int x, Consumer<Integer> dealWithResult,Consumer<Throwable> dealWithException);`多个回调函数可以封装到一个接口中，回调接口中中每个方法调用称作消息或者事件。

## 线框-管道模型
使用图形表示并发系统就是线框-管道模型。
## 为并发而生的CompletableFuture和结合器
## 发布-订阅与反应式编程
Future是一个一次性对象，只能从头到尾执行一次。反应式编程可以执行多次，类似流处理，但是流处理只支持一个终端操作，而且不能拆分或者合并。反应式编程的接口是`java.util.concurrent.Flow`实现了发布订阅模型。反应式编程的3个重要的概念
- 订阅者可以订阅发布者
- 名为订阅的连接
- 消息或者事件，通过连接传输

订阅就类似管道的思想。
## 反应式系统和反应式编程
反应式系统是一个程序，可以在运行时调整以适应变化的需求，3大特性:
- 响应性: 不能因为正在替某人处理任务就延迟其他用户的查询请求，必须实时的对输入进行响应
- 韧性: 不能因为某个组件失效就无法提供服务，某个网络连接出现问题，不应该影响其他网络的查询服务，对无法响应组件的查询应该背重新路由到备用组件上
- 弹性: 系统呢可以调整以适应工作负荷的变化，持续高效的运行

反应式编程体现了消息驱动的思想。
## 小结
- 大量可能阻塞的任务使用线程池可能会有问题
- 方法异步化(完成他们的工作之前返回)能提升程序的并发度，其可以与用于循环结构的优化进行互补
- 使用线框-管道模型可以对异步系统进行可视化
- `CompletableFuture`与`Flow`都可以通过线框-管道图表示
- `CompletableFuture`类常用于一次性的异步计算，使用结合器可以组合多个异步计算，并且无需担心使用Future时的阻塞分险
- Flow API基于发布-订阅协议，与背压一起构成了Java反应式编程的基础
- 反应式编程可以帮助实现反应式系统