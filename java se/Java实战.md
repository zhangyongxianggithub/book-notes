# CompletableFuture及反应式编程背后的概念
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