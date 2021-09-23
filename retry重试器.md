# guava-retrying
这是什么？ guava-retrying 模块提供了一种通用方法，用于重试任意的java代码执行，可以在指定的情况下停止、重试并且可以处理代码中发生的异常，这些功能基于 Guava 的谓词匹配。

这是由 Jean-Baptiste Nizet (JB) 在这里发布的优秀 RetryerBuilder 代码的分支。 我添加了一个 Gradle 构建，用于将它推送到我的 Maven Central 的小角落，以便其他人可以轻松地将其拉入他们现有的项目中。 它还包括指数和斐波那契退避等待策略，这对于首选行为更良好的服务轮询的情况可能很有用。
maven
```xml
    <dependency>
      <groupId>com.github.rholder</groupId>
      <artifactId>guava-retrying</artifactId>
      <version>2.0.0</version>
    </dependency>
```
一个简单的例子
```java
Callable<Boolean> callable = new Callable<Boolean>() {
    public Boolean call() throws Exception {
        return true; // do something useful here
    }
};

Retryer<Boolean> retryer = RetryerBuilder.<Boolean>newBuilder()
        .retryIfResult(Predicates.<Boolean>isNull())
        .retryIfExceptionOfType(IOException.class)
        .retryIfRuntimeException()
        .withStopStrategy(StopStrategies.stopAfterAttempt(3))
        .build();
try {
    retryer.call(callable);
} catch (RetryException e) {
    e.printStackTrace();
} catch (ExecutionException e) {
    e.printStackTrace();
}

```
每当 callable 的结果为 null、抛出 IOException 或从 call() 方法抛出任何其他 RuntimeException 时，这将重试。 它会在尝试重试 3 次后停止并抛出包含有关上次失败尝试的信息的 RetryException。 如果有任何其他异常从 call() 方法中弹出，它会被包装并重新抛出为 ExecutionException异常。
下面的例子创建了一个永久重试的Retryer，每次失败后，增加指数级增长的时间间隔，最终达到最大重试间隔(指数退避算法)
```java
Retryer<Boolean> retryer = RetryerBuilder.<Boolean>newBuilder()
        .retryIfExceptionOfType(IOException.class)
        .retryIfRuntimeException()
        .withWaitStrategy(WaitStrategies.exponentialWait(100, 5, TimeUnit.MINUTES))
        .withStopStrategy(StopStrategies.neverStop())
        .build();
```
下面的例子创建一个斐波那契回退算法的重试器，每次失败后，增加一个斐波那契回退间隔，一直到最大的23分钟。
```java
Retryer<Boolean> retryer = RetryerBuilder.<Boolean>newBuilder()
        .retryIfExceptionOfType(IOException.class)
        .retryIfRuntimeException()
        .withWaitStrategy(WaitStrategies.fibonacciWait(100, 2, TimeUnit.MINUTES))
        .withStopStrategy(StopStrategies.neverStop())
        .build();
```
# spring retry
spring retry为Spring应用提供了声明式的重试支持，广发应用在Spring Batch、Spring Integration等组件中，也支持编程式的方式使用。
## 快速开始
下面的例子是一个声明的方式使用spring-retry的例子
```java
@Configuration
@EnableRetry
public class Application {

    @Bean
    public Service service() {
        return new Service();
    }

}

@Service
class Service {
    @Retryable(RemoteAccessException.class)
    public void service() {
        // ... do something
    }
    @Recover
    public void recover(RemoteAccessException e) {
       // ... panic
    }
}
```
这个例子声明，当调用service方法发生RemoteAccessException异常时，重试，并且重试达到最大次数后，调用recover方法恢复，在注解`@Retryable`中有非常多的属性，可以声明一些条件。
声明式的重试需要AOP支持。
## 非声明的方式
```java
RetryTemplate template = RetryTemplate.builder()
				.maxAttempts(3)
				.fixedBackoff(1000)
				.retryOn(RemoteAccessException.class)
				.build();

template.execute(ctx -> {
    // ... do something
});
```
## Features and API
这一节会讨论Spring Retry的特点并介绍如何使用它的API
### 使用Retry Template
为了让处理过程更具健壮性，失败处理是非常有效的，比如网络抖动或者DeadLockLoserException等异常，下一次的重试就非常可能成功了，为了让重试自动化，Spring Retry有重试策略（RetryOperations），重试策略接口如下：
```java
public interface RetryOperations {

    <T> T execute(RetryCallback<T> retryCallback) throws Exception;

    <T> T execute(RetryCallback<T> retryCallback, RecoveryCallback<T> recoveryCallback)
        throws Exception;

    <T> T execute(RetryCallback<T> retryCallback, RetryState retryState)
        throws Exception, ExhaustedRetryException;

    <T> T execute(RetryCallback<T> retryCallback, RecoveryCallback<T> recoveryCallback,
        RetryState retryState) throws Exception;

}
```
RetryCallback是一个简单的回调接口，里面可以写一些需要重试的逻辑处理过程
```java
public interface RetryCallback<T> {

    T doWithRetry(RetryContext context) throws Throwable;

}
```
当处理过程成功或者经过决策要停止，回调才会停止重试，回调策略接口中含有很多的重载的execute方法，用来处理所有重试都失败后的场景，RetryOperations的最简单的实现就是RetryTemplate类，下面的例子是使用的方法
```java
RetryTemplate template = new RetryTemplate();

TimeoutRetryPolicy policy = new TimeoutRetryPolicy();
policy.setTimeout(30000L);

template.setRetryPolicy(policy);

Foo result = template.execute(new RetryCallback<Foo>() {

    public Foo doWithRetry(RetryContext context) {
        // Do stuff that might fail, e.g. webservice operation
        return result;
    }

});
```
在1.3版本后，可以使用流式的方式创建RetryTemplate
```java
RetryTemplate.builder()
      .maxAttempts(10)
      .exponentialBackoff(100, 2, 10000)
      .retryOn(IOException.class)
      .traversingCauses()
      .build();

RetryTemplate.builder()
      .fixedBackoff(10)
      .withinMillis(3000)
      .build();

RetryTemplate.builder()
      .infiniteRetry()
      .retryOn(IOException.class)
      .uniformRandomBackoff(1000, 3000)
      .build();

```
### 使用RetryContext
RetryCallback接口的方法参数是RetryContext，很多回调都忽略上下文，如果有必要，你可以使用它存储一些迭代过程中的共享数据。当一个线程中，存在嵌套的retry的时候，RetryContext会有父上下文，父上下文用来在不同的execute调用间共享数据是非常有用的。
### 使用RecoveryCallback
当停止重试时，回调用RecoveryCallback接口，调用方式：
```java
Foo foo = template.execute(new RetryCallback<Foo>() {
    public Foo doWithRetry(RetryContext context) {
        // business logic here
    },
  new RecoveryCallback<Foo>() {
    Foo recover(RetryContext context) throws Exception {
          // recover logic here
    }
});

```
### Stateless Retry
最简单的重试方法就是使用一个循环，RetryContext会保存一些有关状态的上下文，但是这个上下文只是栈存储，而不是全局存储，因而，我们称这种重试是无状态重试，无状态重试与有状态重试的区别就是是否共享RetryPolicy的实现，在无状态重试中，回调只会在一个线程中执行。
### stateful Retry
当任务失败后，一个前面的事务性资源的变更往往就无效了，此时需要回滚这个事务性的资源，但是事务性资源往往不是简单的数据库的CRUD，也有可能是一个分布式系统中的远程调用，这个远程调用在远程可能做出了数据库的CRUD，在这种场景下，任务失败后马上抛出一个异常让事务回滚，是非常有意义的，这样后面可以开启一个新的事务。
在这样的场景下，stateless的retry不能满足我们的要求，因为重新抛出异常并且回滚，就回使得当前的执行离开RetryOperations.execute(),这会导致释放Retry的上下文，为了保留上下文场景，我们必须保存上下文数据以便后面的恢复，为了这个目的，Spring Retry提供了一个叫做RetryContextCache的存储策略，你可以注入到RetryTemplate中，RetryContextCache的默认实现是in-memory，使用一个简单的内存map，它有一个严格的上限，为了避免内存泄漏，它没有任何高级的缓存的特性（比如TTL），如果你需要这些特性，你可以执行注入一个定制化的具有这些功能的Map，对于集群环境，你可以实现RetryContextCache，自定义一些缓存的顺序等。
RetryOperations的部分指责是识别失败的执行（这个执行通常位于一个事务中），为了让这个变得容易些，Spring Retry提供了RetryState的抽象，这个抽象定义标识了执行的状态，通常作为execute重载方法的参数使用。
失败的操作可以通过RetryState识别出来，为了标识操作的状态，你可以提供一个RetryState类型的对象，这个对象携带一个唯一key，这个key是用来标识操作的，这个唯一的key可以作为RetryContextCache中的key。
*警告：需要定义key的Object.equals()与Object.hashCode()方法，最好的办法使用一个业务的key来标识操作，在JMS消息中，你可以使用小=消息的ID作为业务的key*
是否重试还是终止由RetryPolicy控制，可以设置最大次数或者最大时间等决策。
### Retry Policies
在一个RetryTemplate中，由RetryPolicy控制execute的重试或者终止策略，RetryPolicy也是一个RetryContext的工厂，RetryTemplate负责使用当前的policy来创建一个RetryContext，并且在每次重试执行时，传递到RetryCallback对象中，当重试失败时，RetryTemplate必须访问RetryPolicy判断怎么更新操作的状态（存储在RetryContext中），然后询问RetryPolicy是否执行重试，以及何时重试，如果不能重试了，policy也会负责设置最终的状态，但不处理异常，当没有recovery可用时，RetryTemplate会抛出原始的异常（stateful retry除外，它抛出RetryExhaustedException），你也可以给RetryTemplate设置一个标志，让它无条件的抛出原始的异常。
*tips: *