缓存(Cache)与缓冲区(Buffer)的比较：这2个术语都是用于数据交换的场合；但是却表示不同的含义；习惯上来说，缓冲区是快慢存储体之间数据交换的中间临时存储媒介；当快速存储体需要慢存储体的数据时或者快速存储体需要写数据到慢存储体中时，慢存储体需要查询，快速存储体就要等待，这影响了性能，缓冲区一次读取一大块数据而不是一条条的读取，这样，快速存储体可以及时读取到所需要的数据，一定情况下，减轻了性能的影响；一般都是一次存储慢媒介的一大块数据；数据只会在缓冲区内读取/写入一次；缓存按照定义来讲是隐藏起来的，外部都不知道使用了缓存；缓存起来的数据可以被多次读取，这样提高了性能。

在Spring应用中，缓存抽象是应用缓存到java方法上；通过缓存方法的结果，减少方法的执行次数；每次调用目标方法时，缓存抽象会检查给定参数的方法是否已经执行过并缓存了结果，如果有过，则直接取缓存；如果没有，再调用方法执行，并把结果缓存；对于IO密集型或者CPU密集型应用来说，只计算一次，结果是可以重复使用的。缓存逻辑的加入是透明的，开发什么都不用干。这种机制适用与那种结果只依赖方法参数的方法，就是给定的参数不变，返回的结果也是一直不变的情况。只能用于幂等的方法。缓存抽象也定义了其他缓存相关的操作，比如更新缓存内容，删除缓存内容等；当程序运行期间，方法返回的数据会发生改变时，这些操作就会非常必要。
缓存抽象也像Spring框架内的其他服务一样，只是提供了缓存定义没有提供实现；还是需要实际的存储媒介来存储缓存数据；这样，解放了程序员，不需要手动写缓存逻辑代码；缓存定义接口是`Cache`与`CacheManager`接口；Spring提供了几个缓存接口的实现：基于`ConcurrentMap`的缓存实现、`Ehcache2.x`、`Gemfire缓存`、`Caffeine`等。缓存定义并没有对多线程与多处理器环境做特殊的处理；这样的处理是由缓存接口实现决定的。
如果你使用的是多处理器环境（比如一个集群环境），你需要配置缓存存储器，依赖你的使用方式，要确保相同的数据在多个节点都缓存起来可用；如果一个节点的缓存改变了，你需要有一个缓存的传播机制，让其他节点的缓存跟随改变。缓存操作等价于get-if-not-found-then proceed and put-eventually这种代码块；缓存的读取操作是先判断有没有存春，没有则处理并存到缓存然后返回，这么多步骤是没有锁的，在多线程的环境中，可能会出现脏读等现象。使用Spring的缓存，开发者需要做2方面的事：
- 缓存声明，识别哪些方法需要被缓存以及他们的策略；
- 缓存配置，配置数据应该被缓存到哪里以及从哪里读取；