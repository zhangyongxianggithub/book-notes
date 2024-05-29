很容易把Spring Boot uber jar包打包到一个docker镜像中，然而，在docker镜像中拷贝并运行uber jar包也有一些不足。当运行一个完整的uber jar时会有一些固定的损耗，在容器环境下，这些损耗是需要注意的，另外的问题是把应用代码与它的依赖放在Docker镜像的一个层次中并不是最好的设计。因为应用代码会更频繁的编译，相比于依赖。最好是要他们分开。如果你把jar文件在应用代码类之前放置，Docker通常只需要变更最后一层，其他层只需要从缓存中获取。
# Layering Docker Images
为了更容易地创建最优化的Docker镜像，Spring Boot支持添加一个layer索引文件到jar包中。它包含一些信息，包括层的列表与每个层应该包含的jar包。索引中层的顺序就是添加到Docker/OCI镜像的顺序。开箱即用，支持下面的文件层:
- `dependencies`(也就是常规的发布版依赖)
- `spring-boot-loader`(在`org/springframework/boot/loader`下的所有类)
- `snapshot-dependencies`(快照版本依赖)
- `application`(应用代码类与资源)

下面是一个`layers.idx`文件的示例
```yaml
- "dependencies":
  - BOOT-INF/lib/library1.jar
  - BOOT-INF/lib/library2.jar
- "spring-boot-loader":
  - org/springframework/boot/loader/launch/JarLauncher.class
  - ... <other classes>
- "snapshot-dependencies":
  - BOOT-INF/lib/library3-SNAPSHOT.jar
- "application":
  - META-INF/MANIFEST.MF
  - BOOT-INF/classes/a/b/C.class
```
分层主要就是基于代码与库是否频繁变更来分的，库代码通常不会频繁变更，所以把它们放到单独的层来复用。应用代码会经常变更，所以应该放到单独的层中。Spring Boot也支持为war文件分层，对于Maven来说，参考[packaging layered jar or war section](https://docs.spring.io/spring-boot/maven-plugin/packaging.html#packaging.layers)获取关于向archive添加layer index的更多信息，对于Gradle来说，参考Gradle的插件文档[packaging layered jar or war section](https://docs.spring.io/spring-boot/gradle-plugin/packaging.html#packaging-executable.configuring.layered-archives)
# Dockerfiles
只需要在Dockerfile中简单的几行就可以把Spring Boot uber jar打包成docker镜像。我们会使用分层特性来创建一个最优的docker镜像。当你想要创建一个包含layers索引文件的jar时，需要将`spring-boot-jarmode-tools`jar作为依赖添加到uber jar中。当spring-boot-jarmode-tools出现在classpath中时，你可以以一种特殊的模式启动应用，这种特殊的模式允许启动类运行一些不是你的应用代码的代码，比如用于解析layers的代码。`tools`模式不能应用于包含启动脚本的可执行jar，此时，你需要禁止启动脚本。你可以通过`tools`jar模式来启动你的jar
```shell
$ java -Djarmode=tools -jar my-app.jar
```
输出如下:
```
Usage:
  java -Djarmode=tools -jar my-app.jar

Available commands:
  extract      Extract the contents from the jar
  list-layers  List layers from the jar that can be extracted
  help         Help about any command
```
`extract`命令可以用来生成应用的layers索引文件。下面是一个使用`jarmode`的Dockerfile的例子
```dockerfile
FROM bellsoft/liberica-runtime-container:jre-17-cds-slim-glibc as builder
WORKDIR /builder
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

FROM bellsoft/liberica-runtime-container:jre-17-cds-slim-glibc
WORKDIR /application
COPY --from=builder /builder/extracted/dependencies/ ./
COPY --from=builder /builder/extracted/spring-boot-loader/ ./
COPY --from=builder /builder/extracted/snapshot-dependencies/ ./
COPY --from=builder /builder/extracted/application/ ./
ENTRYPOINT ["java", "-jar", "application.jar"]
```
假设上面的Dockerfile在当前目录下，你的docker镜像可以通过`docker build .`来构建，或者你可以指定应用jar包所在的目录，比如下面的例子
```shell
$ docker build --build-arg JAR_FILE=path/to/myapp.jar .
```
这是一个多阶段dockerfile，builder阶段解析出后面阶段需要的目录，每一个`COPY`命令与jarmode解析出的layers有关。当然，无需使用 `jarmode`也可以编写Dockerfile。您可以结合使用`unzip`和`mv`命令将文件移动到正确的层，但是`jarmode`简化了这一过程。此外，`jarmode`创建的布局开箱即用，符合CDS(Continuous Delivery Service,持续交付服务)标准。