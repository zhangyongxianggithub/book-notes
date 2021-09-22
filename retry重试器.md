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