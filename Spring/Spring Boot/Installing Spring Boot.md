可以使用传统的Java开发工具开发Spring Boot，也可以安装为命令行。需要Java17+，如果你是新手，可以先使用[Spring Boot CLI](https://docs.spring.io/spring-boot/installing.html#getting-started.installing.cli)，否则使用传统的Java开发方式。
# Installation Instructions for the Java Developer
你可以像任何的标准Java库一样使用Spring Boot。只需要在classpath下面放上合适的`spring-boot-*.jar`文件，Spring Boot不需要集成任何特定的工具，可以使用任何的IDE或者文本编辑器。同时一个Spring Boot应用也没什么特别的。可以像其他Java程序那样运行或者DebugSpring Boot应用。虽然可以copy Spring Boot jar包，但是还是建议你通过Maven等构建工具来管理依赖。
## Maven Installation
Maven 3.6.3+，依赖包的group id是`org.springframework.boot`，通常你的Maven的POM文件继承于`spring-boot-starter-parent`项目并声明一个或者多个[starters](https://docs.spring.io/spring-boot/reference/using/build-systems.html#using.build-systems.starters)，Spring Boot也提供了一个可选的[Maven plugin](https://docs.spring.io/spring-boot/maven-plugin/index.html)来创建可执行的jars。可以在[getting started](https://docs.spring.io/spring-boot/maven-plugin/getting-started.html)部分获取关于Spring Boot与Maven插件的更多信息。
## Gradle Installation
兼容7.x与8.x，如果没安装Gradle，需要先安装。Spring Boot的相关的依赖可以使用`org.springframework.boot`组来声明，通常会声明很多starters。Spring Boot也提供了[Gradle plugin](https://docs.spring.io/spring-boot/gradle-plugin/index.html)来简单的声明依赖并创建可执行的jars。Gradle Wrapper提供了更好的获取Gradle的方式。
# Installing the Spring Boot CLI
Spring Boot CLI是一个命令行工具，可以快速生成Spring项目原型，是哟哦那个Spring Boot不需要CLI，它只是一个快速的方式让你可以在没有IDE的情况下创建Spring应用。有很多安装方式。
```shell
$ brew tap spring-io/tap
$ brew install spring-boot
```

