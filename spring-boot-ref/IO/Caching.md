[TOC]
# Caching
Spring框架提供了为应用添加缓存的功能，这种支持是透明的，侵入性比较低，在spring frame核心的基础上，缓存抽象会应用到方法上，减少方法的执行，尽量使用缓存中的可用的信息。Spring Boot自动配置了缓存的一些基础设置，但是这些基础设置需要注解`@EnableCaching`才能生效。
可以检查Spring框架中的相关的细节。
在一个应用中，添加缓存就是简单的在方法上放一个注解。
```java
@Component
public class MyMathService {

    @Cacheable("piDecimals")
    public int computePiDecimal(int precision) {
        ...
    }

}
```
这个案例展示了使用缓存优化一个耗时比较高的接口的用法，在调用computePiDecimal前，缓存机制在piDecimals缓存中搜索匹配参数的结果，如果找到了这个参数代表的key，缓存中key的内容会立即返回给调用者，没找到就会执行方法更新缓存返回结果。你可以可以使用JSR-107标准，这里面也定义了一些缓存相关的注解，但是最好不要混用。可能造成未知的行为。
如果你没有添加任何特定的缓存库，Spring Boot会自动配置一个内存map作为缓存提供者的简单`CacheManager`，当存储缓存时，提供者就会创建一个map代表缓存，生产环境尽量不要使用内存map的形式，可以用来学习或者测试，当你已经充分的学习了很多的缓存的提供者的使用后，需要做合适的配置；所有的缓存提供者都需要你明确的配置所用到的缓存，也可以提供一些默认缓存，在spring.cache.cache-names里面指定。
## 13.1 支持的换粗提供者
缓存抽象没有提供实际的缓存存储，需要提供者实现`Cache`与`CacheManager`来实现缓存存储；如果你还没定义一个`CacheManager`类型的bean或者一个名叫cacheResolver的`CacheResolver`类型的bean（看`CachingConfigurer`）;Spring Boot会按照以下顺序检测缓存提供者：
- Generic
- JCache
- EhCache2.x
- Hazelcast
- Infinispan
- Couchbase
- Redis
- Caffeine
- Cache2k
- Simple

也可以通过`spring.cache.type`指定缓存提供者，你可以使用`spring-boot-starter-cache`来快速的添加基本的缓存依赖，starter引入了spring-context-support包，如果你手动添加依赖，还必须包含spring-context-support包，这是为了使用JCache、EhCache、Caffeine的功能。
如果你使用的是Spring Boot自动配置的`CacheManager`，那么在他初始化前，你可以用自定义的`CacheManagerCustomizer`来调整`CacheManager`。下面的例子表示不允许缓存null值
```java
import org.springframework.boot.autoconfigure.cache.CacheManagerCustomizer;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
public class MyCacheManagerConfiguration {

    @Bean
    public CacheManagerCustomizer<ConcurrentMapCacheManager> cacheManagerCustomizer() {
        return (cacheManager) -> cacheManager.setAllowNullValues(false);
    }

}
```
在前面的例子中自动配置了`ConcurrentMapCacheManager`，如果你提供了自己的CacheManager或者选择了不同类型的自动配置的CacheManager，则Customizer不会被调用。
### 13.1.1 Generic
Generic Caching在context中包含Cache类型的bean时使用，一个包含所有Cache对象的GenericCacheManager会被创建。
### 13.1.2 JCache
### 13.1.7 Redis
如果Redis当前的classpath下，并且存在redis的客户端，那么会自动配置一个RedisCacheManager，可以通过spring.cache.cache-names属性在系统启动时就创建额外的缓存，cache属性可以通过spring.cache.redis.*配置，比如下面的例子创建了2个缓存cache1、cache2，ttl=10m
```yaml
spring:
  cache:
    cache-names: "cache1,cache2"
    redis:
      time-to-live: "10m"
```
默认情况下，会添加一个键前缀，这样，如果两个单独的缓存使用相同的键，Redis 不会有重叠的键，也不会返回无效值。 如果您创建自己的 RedisCacheManager，我们强烈建议您启用此设置。
如果你想要控制默认的配置行为，你可以提供一个RedisCacheConfiguration的bean。
如果对默认设置有更多的控制，你可以定义个RedisCacheManagerBuilderCustomizer的bean，下面的例子是使用customizer设置cache1与cache2的ttl
```java
import java.time.Duration;

import org.springframework.boot.autoconfigure.cache.RedisCacheManagerBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;

@Configuration(proxyBeanMethods = false)
public class MyRedisCacheManagerConfiguration {

    @Bean
    public RedisCacheManagerBuilderCustomizer myRedisCacheManagerBuilderCustomizer() {
        return (builder) -> builder
                .withCacheConfiguration("cache1", RedisCacheConfiguration
                        .defaultCacheConfig().entryTtl(Duration.ofSeconds(10)))
                .withCacheConfiguration("cache2", RedisCacheConfiguration
                        .defaultCacheConfig().entryTtl(Duration.ofMinutes(1)));

    }

}

```
### 13.1.8 Caffeine
Caffeine时Guava cache的java8版本，如果Classpath中有Caffeine，一个CafffeineCacheManager就会被创建，可以在启动时就创建缓存，这是通过spring.cache.cache-names属性实现的，可以通过下面的方式定制化（按照说明的顺序）
- 通过spring.cache.caffeine.spec属性设置
- 提供一个CaffeineSpec的bean
- 提供Caffeine类型的Bean
举例来说，下面的配置创建了cache1于cache2缓存，缓存最大存储500个数据，ttl=10m
```yaml
spring:
  cache:
    cache-names: "cache1,cache2"
    caffeine:
      spec: "maximumSize=500,expireAfterAccess=600s"
```
如果提供了一个CacheLoader类型的bean，它会自动在CaffeineCacheManager中使用的，因为·这个CacheLoader会被CaffeineCacheManager管理的所有的Cache使用，所以它必须被定义成CacheLoader\<Object,OBject>类型的，自动配置会忽略其他类型的CacheLoader bean。
### 13.1.9 Simple
如果没有任何提供者被发现，会使用ConcurrentHashMap作为一个简单的实现，如果没有别的缓存包在classpath中，这个就是默认的实现，默认情况下，caches是按需创建的，你可以通过设置cache-names属性来限定cache的数量；比如，如果你只需要cache1与cache2缓存，可以设置如下：
```yaml
spring:
  cache:
    cache-names: "cache1,cache2"
```
如果你这么做了，你的应用如果使用了没有在列表中的缓存时，在调用碰到这里时，它就会失败。
### 13.1.10 None
当使用`@EnableCaching`开启缓存时，就需要一个合适的缓存配置，如果你需要在特定的环境下禁止缓存的相关的功能，设置属性type=none，spring就会使用一个no-op的CacheManager
```yaml
spring:
  cache:
    type: "none"
```


