从4.1版本开始，Spring的缓存抽象完全支持JCache标准注解：`@CacheResult`、`@CachePut`、`@CacheRemov`e、`@CacheRemoveAll`、`@CacheDefaults`、`@CacheKey`、`@CacheValue`等；你可以直接使用这些注解，不需要做额外的操作。实现使用Spring了缓存抽象与提供的默认的`CacheResolver`与`KeyGenerator`。
# 功能概要
JCache注解与Spring缓存注解的对比
|Spring|JSR-107|说明|
|:---|:---|:---|
|`@Cacheable`|`@CacheResult`|差不多完全一样，`@CacheResult`可以缓存异常，并且可以不论方法是否缓存都强制方法的执行|
|`@CachePut`|`@CachePut`|Spring使用方法执行的结果更新缓存，JCache使用`@CacheValue`标注的参数更新缓存|
|`@CacheEvict`|`@CacheRemove`|差不多一样，`@CacheRemove`支持在异常发生条件下的移除|
|`@CacheEvict(allEntries=true)`|`@CacheRemoveAll`|与`@CacheRemove`的区别一样|
|`@CacheConfig`|@CacheDefaults|一样|

JCache也有`CacheResolver`的概念，与Spring的几本功能是一样的，但是JCache只支持配置一个缓存名字；默认情况，`CacheResolver`的简单实现就是根据注解中出现的缓存名字取底层的存储体中查找；如果缓存注解中没有指定使用的缓存，则会默认生成一个；`CacheResolver`可以通过`CacheResolverFactory`指定；如下：
```java
@CacheResult(cacheNames="books", cacheResolverFactory=MyCacheResolverFactory.class)
public Book findBook(ISBN isbn)
```
Key可以通过`CacheKeyGenerator`接口生成，与Spring的KeyGenerator接口的用途是一样的；默认的实现是用所有的方法的参数形成一个key；但是使用`@CacheKey`的情况除外；下面的2个例子是完全等价的。
```java
@Cacheable(cacheNames="books", key="#isbn")
public Book findBook(ISBN isbn, boolean checkWarehouse, boolean includeUsed)

@CacheResult(cacheName="books")
public Book findBook(@CacheKey ISBN isbn, boolean checkWarehouse, boolean includeUsed)
```
JCache可以管理注解的方法抛出的异常；可以阻止缓存的更新。它会缓存异常信息来防止方法的重复执行。
```java
@CacheResult(cacheName="books", exceptionCacheName="failures"
			cachedExceptions = InvalidIsbnNotFoundException.class)
public Book findBook(ISBN isbn)
```
# 开启JSR-107支持
