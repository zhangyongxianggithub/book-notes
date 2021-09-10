[TOC]
# 13 Caching
Spring框架提供了为应用添加缓存的功能，这种支持是透明的，侵入性比较低，在spring frame核心的基础上，缓存抽象会应用到方法上，减少方法的执行，尽量使用缓存中的可用的信息。Spring Boot自动配置了缓存的一些基础设置，但是这些基础设置需要注解@EnableCaching才能生效。
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
这个案例展示了使用缓存优化一个耗时比较高的借口的用法，在调用computePiDecimal前，缓存机制在piDecimals缓存中搜索匹配参数的结果，如果找到了这个参数，缓存中的内容会立即返回给调用者，没找到就会执行方法更新缓存返回结果。
你可以可以使用JSR-107标准，这里面也定义了一些缓存相关的类，但是最好不要混用。可能造成未知的行为。
如果你没有添加缓存相关的库，Spring Boot会自动配置一个内存map作为缓存提供者，当存储缓存时，提供者就会创建一个map，生产环境尽量不要使用内存map的形式，可以用来学习或者测试，