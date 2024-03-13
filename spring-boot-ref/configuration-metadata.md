# Generating Your Own Metadata by Using the  Annotation Processor
你可以使用`spring-boot-configuration-processor`jar来为`@ConfigurationProperties`标准的类生成你自己的配置元数据文件，jar包中包含一个Java注解处理器。当项目被编译时，Java注解处理器被调用。
## Configuring the Annotation Processor
为了使用处理器，需要添加依赖
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```
如果你正在使用`additional-spring-configuration-metadata.json`文件，需要配置`compileJava`依赖`processResources`任务
```grade
tasks.named('compileJava') {
    inputs.files(tasks.named('processResources'))
}
```
这个依赖保证党注解处理器在编译期间运行时，额外的metadata是可用的。如果你正在使用AspectJ。你需要保证注解处理器只运行一次。有几种方式实现它。使用Maven时，你可以明确的配置`maven-apt-plugin`，你也可以让AspectJ插件运行所有的处理并在`maven-compiler-plugin`配置中关闭注解处理，比如:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <proc>none</proc>
    </configuration>
</plugin>
```
如果您在项目中使用Lombok，则需要确保其注解处理器在`spring-boot-configuration-processor`之前运行。要使用Maven执行此操作，需要在Maven编译器插件的annotationProcessors按正确的顺序列出注解处理器。如果您不使用此属性，并且注解处理器由classpath上可用的依赖项选取，请确保在`spring-boot-configuration-processor`依赖项之前定义lombok依赖项。
## Metadata自动生成
处理器会选择`@ConfigurationProperties`标准的类与方法。如果类只有一个参数化的构造函数，则一个属性对应构造函数参数，除非该构造函数被`@Autowired`标注。如果该类有`@ConstructorBinding`显式标注的构造函数，则会为该构造函数的每个参数创建一个属性。否则，通过对标准 getter和setter的存在来发现属性，对于集合与map类型会进行特殊处理(即使仅存在getter，也会检测到)。注解处理器还支持使用`@Data`、`@Value`、`@Getter`和`@Setter`lombok注解。考虑以下示例：
```java
@ConfigurationProperties(prefix = "my.server")
public class MyServerProperties {
    /**
     * Name of the server.
     */
    private String name;
    /**
     * IP address to listen to.
     */
    private String ip = "127.0.0.1";
    /**
     * Port to listener to.
     */
    private int port = 9797;
    public String getName() {
        return this.name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getIp() {
        return this.ip;
    }
    public void setIp(String ip) {
        this.ip = ip;
    }
    public int getPort() {
        return this.port;
    }
    public void setPort(int port) {
        this.port = port;
    }
    // fold:off
```
暴露了2个属性，`my.server.name`没有默认值，`my.server.ip`与`my.server.port`对应的的默认值是127.0.0.1与9797。字段上的Javadoc用来生成`description`属性。注解处理器应用了大量的启发式方法来从源代码中解析默认值。默认值必须是固定值。具体的，不要时引用其他类的常量值，同时，注解处理器不能自动检测`Enum`与`Collection`的默认值。对于默认值不能检测的场景，需要人工提供metadata(additional-spring-configuration-metadata.json)，考虑下面的例子:
```java
@ConfigurationProperties(prefix = "my.messaging")
public class MyMessagingProperties {
    private List<String> addresses = new ArrayList<>(Arrays.asList("a", "b"));
    private ContainerType containerType = ContainerType.SIMPLE;
    public List<String> getAddresses() {
        return this.addresses;
    }
    public void setAddresses(List<String> addresses) {
        this.addresses = addresses;
    }
    public ContainerType getContainerType() {
        return this.containerType;
    }
    public void setContainerType(ContainerType containerType) {
        this.containerType = containerType;
    }
    public enum ContainerType {
        SIMPLE, DIRECT
    }
}
```
为了文档化属性的默认值，你应该添加下面的内容到模块的人工metadata(additional-spring-configuration-metadata.json):
```json
{"properties": [
    {
        "name": "my.messaging.addresses",
        "defaultValue": ["a", "b"]
    },
    {
        "name": "my.messaging.container-type",
        "defaultValue": "simple"
    }
]}
```
对于已存在的属性，只需要属性的`name`来文档化额外的metadata。注解处理器认为嵌套类为嵌套属性。如下面的例子:
```java
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "my.server")
public class MyServerProperties {

    private String name;

    private Host host;

    public String getName() {
        return this.name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Host getHost() {
        return this.host;
    }

    public void setHost(Host host) {
        this.host = host;
    }

    public static class Host {

        private String ip;

        private int port;

        public String getIp() {
            return this.ip;
        }

        public void setIp(String ip) {
            this.ip = ip;
        }

        public int getPort() {
            return this.port;
        }

        public void setPort(int port) {
            this.port = port;
        }

    }

}
```
这个例子为`my.server.name`,`my.server.host.ip`与`my.server.host.port`属性产生metadata信息。你可以用`@NestedConfigurationProperty`注解来表明一个类是嵌套的。
## 添加额外的Metadata
Spring Boot的配置文件处理非常灵活，通常情况下可能存在未绑定到`@ConfigurationProperties`bean的属性。您可能还需要调整现有key的某些属性。为了支持此类情况并让您提供自定义"hints"，注解处理器会自动将`META-INF/additional-spring-configuration-metadata.json`中的条目合并到主metadata文件中。如果您引用已自动检测到的属性，description、default value和deprecation信息将被覆盖。如果当前模块中未检测到手动属性声明，则将其添加为新属性。`additional-spring-configuration-metadata.json`文件的格式与常规 `spring-configuration-metadata.json`完全相同。附加属性文件是可选的。如果您没有任何附加属性，请不要添加该文件。

