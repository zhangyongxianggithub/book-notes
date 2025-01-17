强烈建议使用一个支持依赖管理与支持下载Maven仓库组件的构建系统。建议使用Maven或者Gradle。使用老的构建系统也是可以的，比如Ant，但是支持度不够好。
# 依赖管理
每次Spring Boot发布都提供了支持的最佳依赖的列表。实际上，你不需要指定依赖的版本号，因为Spring Boot已经为你提供了，当你升级Spring Boot时，这些依赖也会相应升级。
最佳依赖的列表包含了所有的Spring模块与一些第三方模块。
每次的Spring Boot的发布都是基于一个Spring Framework的版本。最好不要任意指定Spring Framework的版本。
# Maven
使用Maven开发Spring Boot应用，参考Spring Boot的Maven插件
- [Reference](https://docs.spring.io/spring-boot/maven-plugin/index.html)
- [API](https://docs.spring.io/spring-boot/maven-plugin/api/java/index.html)
# Gradle
使用Gradle开发Spring Boot应用，参考Spring Boot的Gradle插件
- [Reference](https://docs.spring.io/spring-boot/gradle-plugin/index.html)
- [API](https://docs.spring.io/spring-boot/gradle-plugin/api/java/index.html)
# Ant
使用Apache Ant+Ivy构建Spring Boot项目，需要spring-boot-antlib来创建可执行的jars。声明依赖，创建`ivy.xml`文件
```xml
<ivy-module version="2.0">
	<info organisation="org.springframework.boot" module="spring-boot-sample-ant" />
	<configurations>
		<conf name="compile" description="everything needed to compile this module" />
		<conf name="runtime" extends="compile" description="everything needed to run this module" />
	</configurations>
	<dependencies>
		<dependency org="org.springframework.boot" name="spring-boot-starter"
			rev="${spring-boot.version}" conf="compile" />
	</dependencies>
</ivy-module>
```
创建`build.xml`文件类似
```xml
<project
	xmlns:ivy="antlib:org.apache.ivy.ant"
	xmlns:spring-boot="antlib:org.springframework.boot.ant"
	name="myapp" default="build">

	<property name="spring-boot.version" value="3.4.1" />

	<target name="resolve" description="--> retrieve dependencies with ivy">
		<ivy:retrieve pattern="lib/[conf]/[artifact]-[type]-[revision].[ext]" />
	</target>

	<target name="classpaths" depends="resolve">
		<path id="compile.classpath">
			<fileset dir="lib/compile" includes="*.jar" />
		</path>
	</target>

	<target name="init" depends="classpaths">
		<mkdir dir="build/classes" />
	</target>

	<target name="compile" depends="init" description="compile">
		<javac srcdir="src/main/java" destdir="build/classes" classpathref="compile.classpath" />
	</target>

	<target name="build" depends="compile">
		<spring-boot:exejar destfile="build/myapp.jar" classes="build/classes">
			<spring-boot:lib>
				<fileset dir="lib/runtime" />
			</spring-boot:lib>
		</spring-boot:exejar>
	</target>
</project>
```
# Starters
Starter本质是一个方便的依赖描述符，可以添加到你的应用中，可以一站式获取所有Spring功能与相关的技术无需搜索示例代码或者复制粘贴大量的依赖描述。
比如，如果你想要使用Spring的JPA用于访问数据，只需要在项目中包含`spring-boot-starter-data-jpa`依赖就行了，不需要添加别的依赖描述。
starter包含了项目需要的所有依赖，所有官方的starter都遵循一个相似的命名规范: `spring-boot-starter-*`，`*`表示应用的类型，这种命名结构有助于搜索starter。
很多IDE都集成了Maven，可以根据名字搜索依赖，在[Creating Your Own Starter](https://docs.spring.io/spring-boot/reference/features/developing-auto-configuration.html#features.developing-auto-configuration.custom-starter)
中解释过，第三方starter不要以`spring-boot`开头命名，因为是为官方包保留的，相反，三方包应该以`*-spring-boot-starter`的模式命名。
提供的官方starter
|**Name**|**Description**|
|:---|:---|
|spring-boot-starter|核心starter，包含自动配置支持，日志与YAML等内容|
|spring-boot-starter-activemq|用于使用ActiveMQ的JMS messaging|
|spring-boot-starter-amqp|使用Spring AMQP与Rabbit MQ|
|spring-boot-starter-aop|切面编程的Starter|
| spring-boot-starter-artemis                     | Starter for JMS messaging using Apache Artemis                                                                                       |
| spring-boot-starter-batch                       | Starter for using Spring Batch                                                                                                       |
| spring-boot-starter-cache                       | Starter for using Spring Framework’s caching support                                                                               |
| spring-boot-starter-data-cassandra              | Starter for using Cassandra distributed database and Spring Data Cassandra                                                           |
| spring-boot-starter-data-cassandra-reactive     | Starter for using Cassandra distributed database and Spring Data Cassandra Reactive                                                  |
| spring-boot-starter-data-couchbase              | Starter for using Couchbase document-oriented database and Spring Data Couchbase                                                     |
| spring-boot-starter-data-couchbase-reactive     | Starter for using Couchbase document-oriented database and Spring Data Couchbase Reactive                                            |
| spring-boot-starter-data-elasticsearch          | Starter for using Elasticsearch search and analytics engine and Spring Data Elasticsearch                                            |
| spring-boot-starter-data-jdbc                   | Starter for using Spring Data JDBC                                                                                                   |
| spring-boot-starter-data-jpa                    | Starter for using Spring Data JPA with Hibernate                                                                                     |
| spring-boot-starter-data-ldap                   | Starter for using Spring Data LDAP                                                                                                   |
| spring-boot-starter-data-mongodb                | Starter for using MongoDB document-oriented database and Spring Data MongoDB                                                         |
| spring-boot-starter-data-mongodb-reactive       | Starter for using MongoDB document-oriented database and Spring Data MongoDB Reactive                                                |
| spring-boot-starter-data-neo4j                  | Starter for using Neo4j graph database and Spring Data Neo4j                                                                         |
| spring-boot-starter-data-r2dbc                  | Starter for using Spring Data R2DBC                                                                                                  |
| spring-boot-starter-data-redis                  | Starter for using Redis key-value data store with Spring Data Redis and the Lettuce client                                           |
| spring-boot-starter-data-redis-reactive         | Starter for using Redis key-value data store with Spring Data Redis reactive and the Lettuce client                                  |
| spring-boot-starter-data-rest                   | Starter for exposing Spring Data repositories over REST using Spring Data REST and Spring MVC                                        |
| spring-boot-starter-freemarker                  | Starter for building MVC web applications using FreeMarker views                                                                     |
| spring-boot-starter-graphql                     | Starter for building GraphQL applications with Spring GraphQL                                                                        |
| spring-boot-starter-groovy-templates            | Starter for building MVC web applications using Groovy Templates views                                                               |
| spring-boot-starter-hateoas                     | Starter for building hypermedia-based RESTful web application with Spring MVC and Spring HATEOAS                                     |
| spring-boot-starter-integration                 | Starter for using Spring Integration                                                                                                 |
| spring-boot-starter-jdbc                        | Starter for using JDBC with the HikariCP connection pool                                                                             |
| spring-boot-starter-jersey                      | Starter for building RESTful web applications using JAX-RS and Jersey. An alternative to spring-boot-starter-web                     |
| spring-boot-starter-jooq                        | Starter for using jOOQ to access SQL databases with JDBC. An alternative to spring-boot-starter-data-jpa or spring-boot-starter-jdbc |
| spring-boot-starter-json                        | Starter for reading and writing json                                                                                                 |
| spring-boot-starter-mail                        | Starter for using Java Mail and Spring Framework’s email sending support                                                           |
| spring-boot-starter-mustache                    | Starter for building web applications using Mustache views                                                                           |
| spring-boot-starter-oauth2-authorization-server | Starter for using Spring Authorization Server features                                                                               |
| spring-boot-starter-oauth2-client               | Starter for using Spring Security’s OAuth2/OpenID Connect client features                                                          |
| spring-boot-starter-oauth2-resource-server      | Starter for using Spring Security’s OAuth2 resource server features                                                                |
| spring-boot-starter-pulsar                      | Starter for using Spring for Apache Pulsar                                                                                           |
| spring-boot-starter-pulsar-reactive             | Starter for using Spring for Apache Pulsar Reactive                                                                                  |
| spring-boot-starter-quartz                      | Starter for using the Quartz scheduler                                                                                               |
| spring-boot-starter-rsocket                     | Starter for building RSocket clients and servers                                                                                     |
| spring-boot-starter-security                    | Starter for using Spring Security                                                                                                    |
| spring-boot-starter-test                        | Starter for testing Spring Boot applications with libraries including JUnit Jupiter, Hamcrest and Mockito                            |
| spring-boot-starter-thymeleaf                   | Starter for building MVC web applications using Thymeleaf views                                                                      |
| spring-boot-starter-validation                  | Starter for using Java Bean Validation with Hibernate Validator                                                                      |
| spring-boot-starter-web                         | Starter for building web, including RESTful, applications using Spring MVC. Uses Tomcat as the default embedded container            |
| spring-boot-starter-web-services                | Starter for using Spring Web Services                                                                                                |
| spring-boot-starter-webflux                     | Starter for building WebFlux applications using Spring Framework’s Reactive Web support                                            |
| spring-boot-starter-websocket                   | Starter for building WebSocket applications using Spring Framework’s MVC WebSocket support                                         |
除了应用的starters，下面的starter也可以用来添加生产级别的starters。
|**Name**|**Description**|
|:---|:---|
|spring-boot-starter-actuator|提供了生产级别的特性，帮助监控与管理你的应用|
最后Spring Boot也包括下面的可以替换的starters
|**Name**|**Description**|
|:---|:---|
|spring-boot-starter-jetty|使用Jetty作为内嵌servlet容器，是tomcat的替代|
|spring-boot-starter-log4j2|使用log4j2记日志，是spring-boot-starter-logging的替代|
|spring-boot-starter-reactor-netty|使用Reactor Netty作为内嵌的reactive Http服务器|
|spring-boot-starter-tomcat|Starter for using Tomcat as the embedded servlet container. Default servlet container starter used by spring-boot-starter-web|
|spring-boot-starter-undertow|Starter for using Undertow as the embedded servlet container. An alternative to spring-boot-starter-tomcat|
关于如何替换，请参考[swapping web server](https://docs.spring.io/spring-boot/how-to/webserver.html#howto.webserver.use-another)与[logging system.](https://docs.spring.io/spring-boot/how-to/logging.html#howto.logging.log4j)。
关于社区贡献的starters，可以参考`spring-boot-starters`模块的[README file](https://github.com/spring-projects/spring-boot/tree/main/spring-boot-project/spring-boot-starters/README.adoc)