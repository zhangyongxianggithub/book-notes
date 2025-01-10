这个章节描述了如何开发一个Hello World web应用。结识了Spring Boot的一些关键特性。你可以选择Maven或者Gradle作为构建系统。[spring.io](https://spring.io/)网址包含很多使用Spring Boot的[Getting starteds](https://spring.io/guides)，如果你想要解决一个特定的问题，可以先阅读这里。你可以通过[start.spring.io](https://start.spring.io/)节省一部分步骤。
# Prerequisites
在开始前，打开终端运行下面的命令确保安装的JDK符合版本要求
```shell
java -version
```
确保安装了Maven或者Gradle
```shell
mvn -v
gradle --version
```
# Setting Up the Project With Maven
首先创建一个Maven的`pom.xml`文件，它是一个配方，用来构建你的项目。
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>com.example</groupId>
	<artifactId>myproject</artifactId>
	<version>0.0.1-SNAPSHOT</version>

	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>3.4.1</version>
	</parent>

	<!-- Additional lines to be added here... -->
</project>
```
可以运行`mvn package`来测试，可以忽略下面的警告。
```
[WARNING] JAR will be empty - no content was marked for inclusion!
```
此时，你应该导入项目到你的IDE，现代的IDE内置支持Maven，为了简单方便，我们继续使用文本编辑器。
# Setting Up the Project With Gradle
首先创建一个Gradle的`build.gradle`文件。也是构建脚本。
```gradle
plugins {
	id 'java'
	id 'org.springframework.boot' version '3.4.1'
}

apply plugin: 'io.spring.dependency-management'

group = 'com.example'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = '17'

repositories {
	mavenCentral()
}

dependencies {
}
```
使用`gradle classes`来测试。
# 添加classpath依赖
Spring Boot提供了大量的starters，Starter提供了特定应用需要的必要依赖。
## Maven
大部分的Spring Boot应用使用`spring-boot-starter-parent`作为POM的parent部分，`spring-boot-starter-parent`是一个特殊的starter，提供了有用的Maven默认值，也提供了一个[dependency-management](https://docs.spring.io/spring-boot/reference/using/build-systems.html#using.build-systems.dependency-management)，可以省略依赖的版本。开发web应用需要添加`spring-boot-starter-web`依赖。在加入前，通过运行下面的命令来看下当前有哪些依赖:
```shell
mvn dependency:tree
```
这个命令打印了项目依赖的树形表示。可以看到`spring-boot-starter-parent`没有提供任何依赖。为了加入必要的依赖，在`pom.xml`文件中添加下面的声明
```xml
<dependencies>
	<dependency>
	<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-web</artifactId>
	</dependency>
</dependencies>
```
再次运行`mvn dependency:tree`可以看到有大量的额外依赖，包含Tomcat web服务器与Spring Boot本身
## Gradle
TODO
# 编写代码
默认情况下，Maven与Gradle都会编译`src/main/java`目录下的源代码。所以需要创建这个目录结构，并添加源代码文件`src/main/java/MyApplication.java`。
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
@SpringBootApplication
public class MyApplication {

	@RequestMapping("/")
	String home() {
		return "Hello World!";
	}

	public static void main(String[] args) {
		SpringApplication.run(MyApplication.class, args);
	}

}
```
虽然代码看起来不多，但是底层有很多代码在运行。
## The `@RestController` and `@RequestMapping` Annotations
类上的第一个注解是`@RestController`，是一个标准注解，为阅读代码的人与Spring提供了提示，表示这个类扮演者特定的角色。在这个例子中，我们的类是一个Web控制器，当处理输入的web请求时，Spring会用到它。`@RequestMapping`注解提供了路由信息，它告诉Spring所有路径为`/`的HTTP请求都应该映射到`home`方法，`@RestController`注解告诉Spring将结果直接返回给调用者。这2个注解都是Spring MVC的注解。
## `@SpringBootApplication`注解
类级别的注解。这个是元注解，组合了`@SpringBootConfiguration`, `@EnableAutoConfiguration`与`@ComponentScan`3个注解。`@EnableAutoConfiguration`命令Spring Boot根据你添加的依赖猜测你想要如何配置Spring项目。因为`spring-boot-starter-web`添加了Tomcat与Spring MVC。自动配置就会假设你正在开发web应用，并据此配置Spring。自动配置与starters一起使用，但是2个概念没有直接关系。您可以选择starters之外的jar依赖。Spring Boot仍会尽力自动配置您的应用程序。
## main方法
应用的最后一部分是main方法。这是一个Java应用程序入口点约定的标准方法。我们的main方法通过调用`run`将应用启动逻辑委托给Spring Boot的`SpringApplication`类。`SpringApplication`引导我们的应用程序、启动Spring、启动自动配置的Tomcat Web服务器。我们需要将 `MyApplication.class`作为参数传递给`run`方法，告诉 `SpringApplication`哪个是primary Spring组件。args 数组也会被传递以便使用到命令行参数。
# Running the Example
## Maven
此时，因为使用的`spring-boot-starter-parent`，所以有一个名为`run`的Maven目标，在项目根目录下输入`mvn spring-boot:run`，然后就有一堆应用的输出。输入`ctrl+c`来终止应用。
## Gradle
忽略
# Creating an Executable Jar
接下来创建一个完全自包含(某事物能够独立存在或运作，而无需外部的支持或依赖。)的可执行的jar文件，我们可以在生产环境中使用它。可执行的jar，也叫做uber jars或者fat jars。是一种归档文件，包含了所有编译后的classes以及所有的jar依赖。Java并没有提供在一个jar文件中内嵌其他jar文件的标准方式，这样制作自包含的应用时就会有问题。为了解决这个问题，很多开发者使用uber jar的方案。uber jar把所有的class包括依赖的class都打包到一个归档文件中。这种防范就是很难知道你的应用依赖了什么库。Spring Boot使用内嵌jar文件的方案。
## Maven
为了创建可执行的jar，需要添加`spring-boot-maven-plugin`插件。
```xml
<build>
	<plugins>
		<plugin>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-maven-plugin</artifactId>
		</plugin>
	</plugins>
</build>
```
`spring-boot-starter-parent`中已经包含了目标`repackage`的`<executions>`配置。如果你没有使用parent，你需要声明这个配置。参考[plugin文档](https://docs.spring.io/spring-boot/maven-plugin/getting-started.html)
运行`mvn package`来生成，在target目录下会看到`myproject-0.0.1-SNAPSHOT.jar`，大约18MB，如果你想要看里面的内容，使用`jar tvf target/myproject-0.0.1-SNAPSHOT.jar`，你也会看到一个名叫`myproject-0.0.1-SNAPSHOT.jar.original`的小文件，这是Maven创建的原始jar文件，然后就被Spring Boot repackage了。
## Gradle
忽略
