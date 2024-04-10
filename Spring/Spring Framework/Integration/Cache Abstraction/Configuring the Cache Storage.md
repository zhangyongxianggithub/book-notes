缓存抽象提供了几种缓存底层存储集成选项，为了使用它们，你需要声明一个合适的`CacheManager`（一个实体用来控制并管理`Cache`实例以及实现检索机制来提供存储）。
# JDK的ConcurrentMap Cache
基于JDK的Cache实现在`org.springframework.cache.concurrent`包下面，它可以让你使用`ConcurrentHashMap`作为Cache的底层存储，下面的例子配置了2个Caches:
```xml
<!-- simple cache manager -->
<bean id="cacheManager" class="org.springframework.cache.support.SimpleCacheManager">
	<property name="caches">
		<set>
			<bean class="org.springframework.cache.concurrent.ConcurrentMapCacheFactoryBean" p:name="default"/>
			<bean class="org.springframework.cache.concurrent.ConcurrentMapCacheFactoryBean" p:name="books"/>
		</set>
	</property>
</bean>
```
这个缓存管理器是使用`SimpleCacheManager`创建的，创建时内部包含了2个Cache实例；因为Cache是由应用程序创建的，所以也绑定了它的生命周期，这限制了缓存只能用于基本的功能使用或者是简单的应用；这种方式拓展性好，并且速度快，但是不能提供任何的管理、持久化能力或者清除功能。
# Ehcache-based缓存
Ehcache 3.x版本是完全兼容JSR-107定义的，不需要额外的支持；EhCache2.0的相关的实现在`org.springframework.cache.ehcache`子包下。

# Caffeine Cache
Caffeine是Guava Cache的java8版本；它的相关的实现在`org.springframework.cache.caffeine`包下，并且提供了Caffeine特性相关的支持。下面的例子是一个使用Caffeine的CacheManager，这个例子可以按需创建Cache:
```xml
<bean id="cacheManager"
		class="org.springframework.cache.caffeine.CaffeineCacheManager"/>
```
你也可以明确的指出要使用的Cache，此时不能按需创建Cache。比如:
```xml
<bean id="cacheManager" class="org.springframework.cache.caffeine.CaffeineCacheManager">
	<property name="cacheNames">
		<set>
			<value>default</value>
			<value>books</value>
		</set>
	</property>
</bean>
```
Caffeine CacheManager也支持自定义Caffeine与CacheLoader。
# GemFire缓存
GemFire是一个面向内存的，磁盘备份的的缓存，可以灵活的扩展，持续高可用，活跃的，具有副本机制的数据库(内置了模式匹配订阅通知)；想要得到更多的信息，可以看[Spring data GemFire](https://docs.spring.io/spring-gemfire/docs/current/reference/html/)的文档。
# JSR-107
Spring的缓存抽象也可以使用兼容JSR-107的缓存，实际就是一个代理，相关的实现在`org.springframework.cache.jcache`子包下，你需要首先声明一个合适的`CacheManager`下面是一个例子：
```xml
<bean id="cacheManager"
		class="org.springframework.cache.jcache.JCacheCacheManager"
		p:cache-manager-ref="jCacheManager"/>

<!-- JSR-107 cache manager setup  -->
<bean id="jCacheManager" .../>
```
# 没有底层存储的缓存
有时候，当切换环境或者做测试时，你想声明一个不需要实际发生底层缓存存储的`CacheManager`，但是这是不可能的，如果没有配置缓存存储，运行时就会抛出异常，在这种情况下，相比于移除缓存声明；你可以注入一个简单的dummy缓存，这个dummy缓存并不会实际存储，什么也不做；方法每次调用都会得到执行，下面是个例子:
```xml
<bean id="cacheManager" class="org.springframework.cache.support.CompositeCacheManager">
	<property name="cacheManagers">
		<list>
			<ref bean="jdkCache"/>
			<ref bean="gemfireCache"/>
		</list>
	</property>
	<property name="fallbackToNoOpCache" value="true"/>
</bean>
```
上面例子中的`CompositeCacheManager`包含有多个`CacheManager`实例；通过设置`fallbackToNoOpCache=true`，添加了一个no-op缓存，那些没有被定义的cache Manger处理的缓存定义都会被no-op缓存处理；也就是在jdkCache于gemfireCache中没有发现的缓存定义都会被no-op缓存处理，这个缓存啥也不干，每次目标方法调用时都会执行。
6.8.6 内置的一些不同的Cache存储器
还有很多种缓存存储，都可以用于缓存抽象；为了使用它们，需要提供CacheManager与Cache接口的实现；因为并没有一些可以直接使用的标准的实现类；自己实现只是听起来有点难，实际来说，实现类只是一个简单的适配器，使用底层存储机制来实现缓存抽象定义的接口，大多数的CacheManager实现类都会使用org.springframework.cache.support包下面的一些工具类，比如AbstractCacheManager，这个抽象类实现了一些模板代码。我们希望，假以时日，库会提供这些底层存储于spring的整合。