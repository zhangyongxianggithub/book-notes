Spring提供的缓存注解声明
- `@Cacheable`: 触发缓存
- `@CacheEvict`: 触发缓存清除
- `@CachePut`: 触发缓存更新
- `@Caching`: 组合多个缓存操作在一个方法上
- `@CacheConfig`: 在类级别定义一些相同的缓存设置
# @Cacheable注解
正如名字表示的那样，`@Cacheable`表示方法的执行结果是可以被缓存的，也就是说同样的参数只有第一次执行，后续都会从缓存中取。注解里面可以定义一个名字表明缓存存储哪个缓存里面；这个缓存将与被注解的方法关联起来；也可以定义多个名字，那样每个名字对应的缓存中都会缓存一份数据。例子如下:
```java
@Cacheable("books")
public Book findBook(ISBN isbn) {...}
```
在上面的代码片段例子中，`findbook`方法与一个名叫books的缓存关联起来，每次方法被调用时，都会检查缓存里面的内容来查看方法是否之前执行过，这样就不必重复执行，在大多数的场景下，只需要一个缓存，注解里面也可以声明多个缓存；在这种情况下，在方法执行前，每个缓存都会被检查，只有在其中任意一个中检测到缓存方法的结果，这个缓存内容就会被返回(此时不包含缓存内容的cache会缓存内容)。下面是使用多个缓存的例子:
```java
@Cacheable({"books", "isbns"})
public Book findBook(ISBN isbn) {...}
```
## Default Key Generation
因为缓存本质是一种键值对存储结构；缓存方法执行都首先要被翻译成一个缓存的key去缓存中查找缓存或者写入缓存，缓存抽象定义使用一个简单的`KeyGnerattor`来生成key，生成key的算法如下:
- 如果没有参数，返回一个`SimpleKey.EMPTY`
- 如果只有一个参数，返回参数实例
- 如果是多个参数，返回一个包含了所有参数的SimpleKey

这种方式在大多数情况是没问题的，只要参数对象具有自然的key，并且实现了hashCode与equals方法，如果是特殊的情况，你可能需要改变key的生成策略。你只需要实现`org.springframework.cache.interceptor.KeyGenerator`接口就可以实现自定义的key生成算法。早期的版本的Spring使用的key生成策略是，根据参数的hashCode()方法而不是equals，这会造成key经常性的冲突，新的`SinmpleKeyGnerator`使用了更复杂的key生成方法。如果你想要使用以前的这种策略，是需要配置key生成器为`DefaultKeyGenerator`就可以了，或者自己创建一个基于Hash的key生成器。
## Custom Key Generation Declaration
因为缓存是通用的，缓存的目标方法可能有各种不同的方法签名，不能很容易的与缓存key完整匹配，特别是当方法有很多的参数，其中只有一部分参数适合缓存起来时，这就会很明显；考虑下面的例子:
```java
@Cacheable("books")
public Book findBook(ISBN isbn, boolean checkWarehouse, boolean includeUsed)
```
第一眼看过去，2个布尔参数影响book的查询。他们对于缓存来说没有用。方法的参数非常多，有的参数可以作为key，有的完全没有意义，对于这样的场景，可以通过`@Cacheable`的`key`属性指定通过哪些参数来生成key；key里面可以通过SpEL的方式来选择参数（或者参数内部的属性）或者执行某些参数操作，或者调用某些方法；这种方式是推荐的替换默认key生成方式的方式，因为随着代码增长，方法可能具有了不同的参数签名；缺省的key生成器可能对一些方法是有效的，但是一些方法可能就会因为签名变更的原因生成无意义的key，所以指定是一种好的策略。下面是使用了SpEL的一些例子:
```java
@Cacheable(cacheNames="books", key="#isbn")
public Book findBook(ISBN isbn, boolean checkWarehouse, boolean includeUsed)

@Cacheable(cacheNames="books", key="#isbn.rawNumber")
public Book findBook(ISBN isbn, boolean checkWarehouse, boolean includeUsed)

@Cacheable(cacheNames="books", key="T(someType).hash(#isbn)")
public Book findBook(ISBN isbn, boolean checkWarehouse, boolean includeUsed)
```
上面的例子展示了通过参数、参数的属性或者任意的静态方法调用生成key是多么的容易。如果负责生成key的算法具有普遍性，需要共享，那么可以自定义一个`KeyGenerator`实现的的bean，通过keyGenerator属性指定就可以。
```java
@Cacheable(cacheNames="books", keyGenerator="myKeyGenerator")
public Book findBook(ISBN isbn, boolean checkWarehouse, boolean includeUsed)
```
`@Cacheable`中的key与keyGenerator只能指定一个，2个是互斥的。同时指定会造成异常。
## Default Cache Resolution
缓存抽象使用一个简单的`CacheResolver`类型的对象来检索Cache信息；这些cache是由`CacheManager`对象配置的；实现`CacheResolver`接口来自定义`CacheResolver`。
## Custom Cache Resolution
默认的缓存解析方案使用的`CacheResolver`只能作用于一个CacheManager，没有复杂的解析逻辑，对于有着多个CacheManager的应用来说，缓存的方法可以声明自己要使用的CacheManager，例子:
```java
@Cacheable(cacheNames="books", cacheManager="anotherCacheManager") // 指定另一个cacheManager
public Book findBook(ISBN isbn) {...} 
```
你可以指定缓存方法使用的`CacheResolver`，可以代替默认的key生成算法，每次调用都会请求解析，resolver实现会根据运行时的参数解析使用哪些cache，下面的例子:
```java
@Cacheable(cacheResolver="runtimeCacheResolver")
public Book findBook(ISBN isbn) {...}
```
`@Cacheable`的`cacheManager`与`cacheResolver`参数是互斥的，只能指定一个。
## Synchronized Caching
在多线程环境下，缓存方法可能会被并发执行，而且可能参数还是一样的，默认情况下，缓存抽象没有对并发做任何处理，也没有加锁；这样，方法可能会执行多次，缓存没能生效，在并发期间没有使用上缓存；对于这样的场景，你可以使用sync属性，sync属性会指示下层的缓存提供者在缓存计算期间对缓存key加锁；这样，只有一个线程获得了锁并计算，其他线程被阻塞了，直到缓存更新，锁被释放，Sync属性用在并发情况下防止多次计算。下面的例子:
```java
@Cacheable(cacheNames="foos", sync=true)
public Foo executeExpensiveOperation(String id) {...}
```
这是一个可选的功能，你使用的缓存库可能并不支持，所有的由core框架提供的`CacheManager`实现都支持这个功能。  
## CompletableFuture与Reactive返回类型的缓存
从Spring 6.1版本开始，缓存注解开始支持`CompletableFuture`与`Reactive`返回类型的缓存，自动适配相应的缓存交互逻辑。对于`CompletableFuture`返回类型来说，由future产生的对象将会被缓存。查找缓存也会以`CompletableFuture`对象的形式返回。
```java
@Cacheable("books")
public CompletableFuture<Book> findBook(ISBN isbn) {...}
```
对于返回类型是Reactor的`Mono`与`Flux`类型的方法，由Reactive Streams publisher产生的对象将会在可用时被缓存。返回类型也是一样的
```java
@Cacheable("books")
public Mono<Book> findBook(ISBN isbn) {...}
@Cacheable("books")
public Flux<Book> findBooks(String author) {...}
```
响应式的返回类型也支持`sync`属性特性。只会计算一次。底层的缓存存储要支持基于`CompletableFuture`的检索，Spring提供的默认的`ConcurrentMapCacheManager`自动支持，`CaffeineCacheManager`也支持但是需要一个设置:
```java
@Bean
CacheManager cacheManager() {
	CaffeineCacheManager cacheManager = new CaffeineCacheManager();
	cacheManager.setCacheSpecification(...);
	cacheManager.setAsyncCacheMode(true);
	return cacheManager;
}
```
## Conditional Caching
Condition与unless属性。有时候方法返回的结果也不一定都适合缓存，有的情况下需要缓存，有的情况下不需要，对于这样条件的方式，condition属性提供了这样的功能，它使用一个SpEL表达式来计算真假值决定是否要缓存结果:
```java
@Cacheable(cacheNames="book", condition="#name.length() < 32")
public Book findBook(String name)
```
除此以外，你可以使用unless参数来阻止结果被缓存，与condition不同，unless是在方法执行完之后才执行判断的，也是condition根据参数判断是否执行方法，unless根据返回的结果判断是否缓存结果。下面是一个例子:
```java
@Cacheable(cacheNames="book", condition="#name.length() < 32", unless="#result.hardback")
public Book findBook(String name)
```
缓存抽象也支持Optional类型，如果有值则会缓存，如果没有值，会存储null，#result永远是引用的方法的返回的结果，不会引用包装类型也就是Optional，上面的例子可以改造如下:
```java
@Cacheable(cacheNames="book", condition="#name.length() < 32", unless="#result?.hardback")
public Optional<Book> findBook(String name)
```
## Available Caching SpEL Evaluation Context
缓存用到的SpEL表达式是在特定的context下求值的，除了可以直接使用内置的参数外，框架也提供了专门的跟缓存有关的元数据，比如参数名；每个SpEL表达式的计算都是在一个专门的上下文中，除了内置的参数，框架也提供了缓存的一些元数据，比如参数的名字，下面的表格列出来上下文中可以使用的内容。你可以在key/condition/unless中使用。
|Name|Location|Description|Example|
|:---|:---|:---|:---|
|methodName|Root Object|被调用的方法的名字|#root.methodName|
|method|Root object|被调用的方法|#root.method.name|
|target|Root object|被调用的方法所在对象|#root.target|
|targetClass|Root object|被调用的方法所在对象的类型|#root.targetClass|
|args|Root object|参数，是一个数组|#root.args[0]|
|caches|Root object|Cache名字|#root.caches[0].name|
|Argument name|Evaluation context|方法参数的名字，如果无法拿到名字（jvm没有开启debug选项），参数名字可以通过#a<#arg>指定，这里#arg这里表示参数的索引|#isbn,或者#a0,你也可以使用#p0或者#p<#arg>标记表示|
|Result|Evaluation context|方法调用的结果，只可以在unless中使用，cache put表达式、cache evict表达式中使用|#result|

6.8.2.2 @CachePut注解
在方法没有执行的情况下，更新缓存，方法执行的结果放到缓存中，方法是一直执行的，执行一次放一次；与@Cacheable里面的一些参数相同，用来更新缓存，下面是一个例子：

在同样的方法上使用@CachePut与@Cacheable是强烈不建议的，因为他们有着完全不同的行为。
6.8.2.3 @CacheEvict
缓存抽象不仅可以更新缓存，也可以执行缓存的清除，当需要移除过期的或者无用的数据时，非常有用，相比于@Cacheable、@CacheEvict定义为执行缓存的清除，标注的方法相当于一个触发器，@CacheEvict需要执行缓存清除支持的参数与@Cacheable的大部分相同，含义也一样；还支持一个额外的参数allEntries指定是否清除整个缓存；下面是一个清除整个缓存的例子：

当需要清除整个缓存区域时，此选项会派上用场。 不是逐出每个条目（这将花费很长时间，因为它效率低下），而是在一次操作中删除所有条目，如前面的示例所示。 请注意，框架会忽略此场景中指定的任何键，因为它不适用（整个缓存被逐出，而不仅仅是一个条目）。
您还可以使用 beforeInvocation 属性指示驱逐是应该在调用方法之后（默认值）还是之前发生。 前者提供与其余注解相同的语义：一旦方法成功完成，缓存上的操作（在本例中为驱逐）就会运行。 如果该方法未运行（因为它可能被缓存）或抛出异常，则不会发生驱逐。 后者 (beforeInvocation=true) 导致驱逐总是在调用方法之前发生。 这在驱逐不需要与方法结果相关联的情况下很有用。
Void返回值的方法可以使用@CacheEvict标注，因为清除的方法相当于一个触发器。这是与@Cacheable与@CachePut完全不同的。
6.8.2.4 Caching注解
有时候，方法上需要标注多个相同类型的注解比如多个@CachePut；这是因为每个涉及到的缓存以及key等都是不同的；@Caching让这种情况得以实现，下面是使用2个@CacheEvict的例子

6.8.2.5 @CacheConfig
到此为止，缓存操作提供了很多定制化的选项，你可以为每个方法设置这些选项；但是有的选项配置起来又多又麻烦；这些共同的选项可以放到class上共享，只用配置一次；下面是一个所有操作共享cache name设置的例子：

方法级别上的设置可以覆盖@CacheConfig指定的设置；所以设置分为一下3个优先级：
全局设置，CacheManager、KeyGenerator；
类级别的；
方法级别的。
6.8.2.6 开启Caching注解
需要注意的是，即使声明缓存注解不会自动触发它们的操作——就像 Spring 中的许多事情一样，该功能必须以声明方式启用（这意味着如果你怀疑缓存是罪魁祸首，你可以通过删除来禁用它 只有一个配置行而不是代码中的所有注释）。
为了启用缓存支持，需要在任意一个@Configuation配置类上加入@EnableCaching注解。注解上可以指定一些属性：
XML	Annotation	Default	Description
Cache-manager	CachingConfigurer	cacheManager	使用的cacheManager的名字，系统会默认使用次manager初始化一个CacheResolver，如果想要对cache进行更细粒度的管理，考虑定义cacheResolver
cache-resolver	CachingConfigurer	使用cacheManager的一个SimpleCacheResolver类型的对象	使用的CacheResolver的Bean名字。
key-generator	CachingConfigurer	SimpleKeyGenerator	自定义的key generator的名字
error-handler	CachingConfigurer	SimpleCacheErrorHandler	使用的缓存处理器的名字
Mode	Mode	proxy	默认模式（代理）通过使用 Spring 的 AOP 框架（遵循代理语义，如前所述，仅适用于通过代理传入的方法调用）处理带注释的 bean。 替代模式 (aspectj) 将受影响的类与 Spring 的 AspectJ 缓存方面编织在一起，修改目标类字节码以应用于任何类型的方法调用。 AspectJ 编织需要类路径中的 spring-aspects.jar 以及启用加载时编织（或编译时编织）。 （有关如何设置加载时编织的详细信息，请参阅 Spring 配置。）
proxy-target-class	proxyTargetClass	false	仅适用于代理模式。 控制为使用 @Cacheable 或 @CacheEvict 批注批注的类创建的缓存代理类型。 如果 proxy-target-class 属性设置为 true，则会创建基于类的代理。 如果 proxy-target-class 为 false 或省略该属性，则会创建标准的基于 JDK 接口的代理。 （有关不同代理类型的详细检查，请参阅代理机制。）
Order	order	Order.LOWEST_PRECEDENCE	定义应用于用@Cacheable 或@CacheEvict 注释的bean 的缓存建议的顺序。 （有关与 AOP 通知排序相关的规则的更多信息，请参阅 Advice Ordering。）没有指定的排序意味着 AOP 子系统决定了通知的顺序。
当您使用代理时，您应该仅将缓存注释应用于具有公共可见性的方法。 如果您使用这些注释对受保护的、私有的或包可见的方法进行注释，则不会引发错误，但带注释的方法不会显示配置的缓存设置。 如果您需要注释非公共方法，请考虑使用 AspectJ（请参阅本节的其余部分），因为它会更改字节码本身。
Spring建议你只注解实际实现类里面的方法，当然，你可以把主机诶放到哦接口的方法上，但是这种情况只有在基于接口的代理模式下才有效；一个事实是，java注解并不能从接口继承，这意味着，当你使用基于类的代理模式时（proxy-target-class=’true’），或者基于织入的切面模式（mode=’aspectj’）时，缓存配置是识别不到的，不能正确包含到一个caching代理里面。
6.8.2.7 使用自定义注解
自定义注解在基于代理的模式下可以完美运行，在使用aspectj模式时，需要做一些微小的工作。缓存抽象可以让你使用自己定义的注解，这样可以把重复的注解声明提取出来，节省代码量；上面说的注解都可以作为元注解。