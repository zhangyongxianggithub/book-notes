还有很多种缓存存储方案，都可以用于缓存抽象；为了使用它们，需要提供CacheManager与Cache接口的实现；因为并没有一些可以直接使用的标准的实现类；自己实现只是听起来有点难，实际来说，实现类只是一个简单的适配器，使用底层存储机制来实现缓存抽象定义的接口，大多数的CacheManager实现类都会使用org.springframework.cache.support包下面的一些工具类，比如AbstractCacheManager，这个抽象类实现了一些模板代码。我们希望，假以时日，库会提供这些底层存储于spring的整合。