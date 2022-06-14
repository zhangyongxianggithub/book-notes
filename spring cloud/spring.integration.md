这一节详细描述了兼容的java与Spring Framework版本，最低的的兼容的java版本是java SE8，Spring Framework 2.0 引入了对命名空间的支持，这简化了应用程序上下文的 XML 配置，并让 Spring Integration 提供广泛的命名空间支持。在本参考指南中，int 命名空间前缀用于 Spring Integration 的核心命名空间支持。 每个 Spring Integration 适配器类型（也称为模块）提供自己的命名空间，使用以下约定进行配置：以下示例显示正在使用的 int、int-event 和 int-stream 命名空间：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:int="http://www.springframework.org/schema/integration"
  xmlns:int-webflux="http://www.springframework.org/schema/integration/webflux"
  xmlns:int-stream="http://www.springframework.org/schema/integration/stream"
  xsi:schemaLocation="
   http://www.springframework.org/schema/beans
   https://www.springframework.org/schema/beans/spring-beans.xsd
   http://www.springframework.org/schema/integration
   https://www.springframework.org/schema/integration/spring-integration.xsd
   http://www.springframework.org/schema/integration/webflux
   https://www.springframework.org/schema/integration/webflux/spring-integration-webflux.xsd
   http://www.springframework.org/schema/integration/stream
   https://www.springframework.org/schema/integration/stream/spring-integration-stream.xsd">
…
</beans>
```
命名空间前缀可以自由选择。 您甚至可以选择根本不使用任何命名空间前缀。 因此，您应该应用最适合您的应用程序的约定。 但请注意，SpringSource Tool Suite™ (STS) 使用与本参考指南中相同的 Spring Integration 命名空间约定。