Spring Boot 3.4.1 要求Java17+，兼容Java23，要求Spring Framework 6.2.1+。要求的构建工具，Maven 3.6.3+，Gradle 7.x+。
# Servlet Containers
|Name|Servlet Version|
|:---|:---|
|Tomcat 10.1 (10.1.25 or later)|6.0|
|Jetty 12.0|6.0|
|Undertow 2.3|6.0|
# GraalVM Native Images
可以使用GraalVM 22.3+将Spring Boot应用转换为Native Image。可以使用Gradle/Maven插件`native build tools`或者GraalVM提供的native-image工具创建Native Image，也可以使用native image Paketo buildpack创建。
|Name|Version|
|GraalVM Community|22.3|
|Native Build Tools|0.10.4|
