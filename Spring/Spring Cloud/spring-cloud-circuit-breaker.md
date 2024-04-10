Spring 断路器项目包含了Resilience4j与spring retry的实现，实现的API包含在Spring cloud Commons中，这些API的使用文档在Spring Cloud Commons文档中。
# 配置Resilience4J断路器
有2个starter包，一个是non-reactive的，一个是reactive的。你可以通过设置spring.cloud.circuitbreaker.resilience4j.enabled=false来禁用Resilience4J的自动配置。
如果想要为所有的断路器提供一个缺省的配置，只需要Customizer类型的bean，bean里面的方法会被传递一个Resilience4JCircuitBreakerFactory.configureDefault方法被用来提供一个缺省的配置。
```java
@Bean
public Customizer<Resilience4JCircuitBreakerFactory> defaultCustomizer() {
    return factory -> factory.configureDefault(id -> new Resilience4JConfigBuilder(id)
            .timeLimiterConfig(TimeLimiterConfig.custom().timeoutDuration(Duration.ofSeconds(4)).build())
            .circuitBreakerConfig(CircuitBreakerConfig.ofDefaults())
            .build());
}
```
