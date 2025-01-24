将应用打包成jar并且使用内嵌的HTTP服务器的的最大优势之一就是你可以在任何地方运行你的应用。该示例适用于调试Spring Boot应用程序。您不需要任何特殊的IDE插件或扩展。下面的选项适合在本地开发环境运行应用，对于生产环境部署，参考[Packaging Your Application for Production](https://docs.spring.io/spring-boot/reference/using/packaging-for-production.html)。这一部分只涉及jar-based打包，如果是war包，参考server与IDE文档。
# Running From an IDE
从IDE运行一个Spring Boot应用，当作普通的Java应用那样运行就可以。
# Running as a Packaged Application
如果使用Spring Boot的Maven或者Gradle插件来创建一个可执行的jar，可以使用`java -jar`来运行应用，如下面的例子所示:
```shell
$ java -jar target/myapplication-0.0.1-SNAPSHOT.jar
```
也可以开启远程debug模式，这样你可以将debugger贴上应用，如下面的启动命令所示:
```shell
$ java -agentlib:jdwp=server=y,transport=dt_socket,address=8000,suspend=n \
       -jar target/myapplication-0.0.1-SNAPSHOT.jar
```
# 使用Maven插件
Spring Boot Maven插件包含一个`run`目标，可以用来快速编译与运行你的应用。`$ mvn spring-boot:run`, 也可以使用`MAVEN_OPTS`操作系统环境变量，`export MAVEN_OPTS=-Xmx1024m`
# 使用Gradle插件
Spring Boot Gradle插件还包含一个`bootRun`任务，可用运行您的应用程序。每当您应用 `org.springframework.boot`和`java`插件时，都会添加`bootRun`任务，如以下示例所示：
```shell
gradle bootRun
```
# Hot Swapping
因为Spring Boot应用就是普通的Java应用，JVM的热交换也是开箱即用的。JVM热交换在它可以替换的字节码方面受到一定限制。对于更完整的解决方案，可以使用[JRebel](https://www.jrebel.com/products/jrebel)。spring-boot-devtools模块还支持快速应用程序重启。有关详细信息，请参阅操作指南中的[Hot Swapping](https://docs.spring.io/spring-boot/how-to/hotswapping.html)部分。