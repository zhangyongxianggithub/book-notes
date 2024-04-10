Spring Boot应用可以使用Dockerfile容器化或者使用Cloud Native Buildpacks来创建兼容Docker的容器镜像。
# Efficicent Container Images
很容易将Spring Boot fat jar打包为docker镜像。但是，简单的在docker镜像中复制和运行fat jar有很多缺点。在不解压的情况下运行 fat jar时，总会有一定的开销，在容器化环境中，这会很明显。另一个问题是，将应用程序的代码及其所有依赖项放在 Docker 镜像的一层中并不是最佳选择。由于与升级您使用的Spring Boot版本相比，您重新编译代码的频率可能更高，因此通常最好将内容分开一些。如果将jar文件放在应用程序类之前的层中，Docker通常只需要更改最底层，就可以从其缓存中提取其他文件。
## Unpacking the Executable JAR
如果你正在运行容器中的应用，你可以使用可执行的jar，但是最佳的办法是将它们分为多个层，很多PaaS实现也会选择在运行前解压缩归档文件，比如，Cloud Foundry就是这么操作的，一种运行解压缩归档应用的方式是运行合适的launcher，比如下面:
```bash
$ jar -xf myapp.jar
$ java org.springframework.boot.loader.JarLauncher
```
这会比直接运行jar启动更快，它们的运行效果是相同的。一旦你unpack了jar文件，你还可以直接运行应用本身的main方法而不是JarLauncher来加快启动的过程。
```bash
$ jar -xf myapp.jar
$ java -cp BOOT-INF/classes:BOOT-INF/lib/* com.example.MyApplication
```
使用JarLauncher具有classpath顺序上的一些收益，因为jar包含一个classpath.idx文件，JarLauncher会使用这个文件。
## Layering Docker Images
为了更容易创建优化的Docker镜像，Spring Boot支持在jar中添加层索引文件。它提供了一个层列表以及应该包含在其中的jar部分。索引中的层列表根据层应添加到 Docker/OCI映像的顺序排序。开箱即用，支持以下层:
- dependencies;
- spring-boot-loader;
- snapshot-dependencies
- application, 应用本身的代码与资源
下面是一个layer.idx的例子:
```
- "dependencies":
  - BOOT-INF/lib/library1.jar
  - BOOT-INF/lib/library2.jar
- "spring-boot-loader":
  - org/springframework/boot/loader/JarLauncher.class
  - org/springframework/boot/loader/jar/JarEntry.class
- "snapshot-dependencies":
  - BOOT-INF/lib/library3-SNAPSHOT.jar
- "application":
  - META-INF/MANIFEST.MF
  - BOOT-INF/classes/a/b/C.class
```
这种分层旨在根据应用程序变更的概率来分离代码。库代码不太可能频繁更改，因此它被放置在自己的层中以允许工具重新使用缓存中的层。应用程序代码更有可能发生变化，因此它被隔离在一个单独的层中。Spring Boot还支持在layers.idx的帮助下对war文件进行分层。对于Maven，请参阅[打包分层jar或war部分](https://docs.spring.io/spring-boot/docs/3.0.0/maven-plugin/reference/htmlsingle/#repackage-layers)以获取有关将层索引添加到存档的更多详细信息。对于Gradle，请参阅[Gradle插件文档的打包分层jar或war部分](https://docs.spring.io/spring-boot/docs/3.0.0/gradle-plugin/reference/htmlsingle/#packaging-layered-archives)。
# Dockerfiles
虽然只需在Dockerfile中添加几行代码就可以将Spring Boot fat jar转换为docker镜像，但我们将使用分层功能来创建优化的docker镜像。当您创建包含层索引文件的jar时，spring-boot-jarmode-layertools jar将作为依赖项添加到您的jar。通过classpath中存在这个jar时，您可以在特殊模式下启动您的应用程序，该模式允许引导程序代码运行与您的应用程序完全不同的东西，例如，提取层的东西。以layertools模式启动你的jar文件:
```bash
java -Djarmode=layertools -jar my-app.jar
```
会得到下面的输出
```
Usage:
  java -Djarmode=layertools -jar my-app.jar

Available commands:
  list     List layers from the jar that can be extracted
  extract  Extracts layers from the jar for image creation
  help     Help about any command
```
`extract命令可以被用来分解应用成不同的层，下面是使用jarmode模式的Dockerfile
```
FROM eclipse-temurin:11-jre as builder
WORKDIR application
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract

FROM eclipse-temurin:11-jre
WORKDIR application
COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
```
假设上述Dockerfile位于当前目录中，您的docker镜像可以使用docker build构建，或者可以选择指定应用程序jar的路径，如以下示例所示:
```bash
$ docker build --build-arg JAR_FILE=path/to/myapp.jar .
```
这是一个多阶段的dockerfile, 构建器阶段提取稍后需要的目录。每个COPY命令都与jarmode提取的层相关。当然，不使用 jarmode 也可以编写 Dockerfile。 您可以使用 unzip 和 mv 的某种组合将内容移动到正确的层，但jarmode简化了这一点。
# Cloud Native Buildpacks
Dockerfiles只是构建docker镜像的一种方式。另一种构建docker镜像的方法是直接从您的Maven或Gradle插件，使用buildpacks。 如果您曾经使用过Cloud Foundry或Heroku等应用程序平台，那么您可能使用过buildpack。buildpack是平台的一部分，它将您的应用程序转换为平台可以实际运行的东西。例如，Cloud Foundry的 Java buildpack会注意到您正在推送一个.jar文件并自动添加一个相关的JRE。借助Cloud Native Buildpacks，您可以创建可在任何地方运行的Docker兼容镜像。 Spring Boot包括对Maven和Gradle的buildpack直接支持。这意味着您只需键入一个命令，即可获得一个可以在Docker deamon中运行的合适的镜像。
请参阅[有关如何将buildpacks与Maven和Gradle](https://docs.spring.io/spring-boot/docs/3.0.0/maven-plugin/reference/htmlsingle/#build-image)使用的插件文档。