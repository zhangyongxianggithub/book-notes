# Baeldung的CompletableFuture指南
## introduction
这个指南是一个`CompletableFuture`类的功能与用例指导。从Java8开始使用。
## Java中的异步计算
异步计算很难推理。 通常，我们希望将任何计算视为一系列步骤，但在异步计算的情况下，表示为回调的操作往往要么分散在代码中，要么彼此深度嵌套。当需要处理其中一个步骤中可能发生的错误时，事情会变得更糟。`Future`接口是在Java5添加的，表示一个异步计算的结果。但是它没有任何方法组合各种计算或者处理可能发生的错误。Java8添加了`CompletableFuture`类，除了实现`Future`接口，它还实现了`CompletionStage`接口，该接口定义了异步计算步骤的契约，我们可以将其与其他步骤结合起来。`CompletableFuture`同时也是一个构建块和一个框架，具有大 50种不同的方法来composing、combining和执行异步计算步骤以及处理错误。如此庞大的API可能会让人不知所措，但这些API大多属于几个清晰且不同的用例。
## Using CompletableFuture as a Simple Future
首先，`CompletableFuture`类实现了`Future`接口，以便我们可以将其用作`Future`实现，但具有额外的完成逻辑。例如，我们可以使用无参数构造函数创建此类的实例来表示未来的某些结果，将其分发给使用者，并在将来的某个时间使用`complete()`方法完成它。消费者可以使用`get`方法来阻塞当前线程，直到提供该结果。在下面的示例中，我们有一个方法创建一个`CompletableFuture`实例，然后在另一个线程中进行一些计算并立即返回 Future。计算完成后，该方法通过将结果提供给`complete`方法来完成Future：
```java
public Future<String> calculateAsync() throws InterruptedException {
    CompletableFuture<String> completableFuture = new CompletableFuture<>();

    Executors.newCachedThreadPool().submit(() -> {
        Thread.sleep(500);
        completableFuture.complete("Hello");
        return null;
    });

    return completableFuture;
}
```
为了分拆计算，我们使用`Executor`API。这种创建和完成`CompletableFuture`的方法可以与任何并发机制或API一起使用，包括原始线程。请注意，`calculateAsync`方法返回一个`Future`实例。我们只需调用该方法，接收`Future`实例，并在准备好阻止结果时调用它的`get`方法。另外，观察`get`方法抛出一些已检查的异常，即`ExecutionException`（封装计算期间发生的异常）和`InterruptedException`（表示线程在活动之前或活动期间被中断的异常）：
```java
Future<String> completableFuture = calculateAsync();
String result = completableFuture.get();
assertEquals("Hello", result);
```
如果我们早就知道计算的结果，我们可以使用`completedFuture`方法直接设置计算结果，随后，`get`方法不会阻塞并立即返回:
```java
Future<String> completableFuture = 
  CompletableFuture.completedFuture("Hello");
// ...
String result = completableFuture.get();
assertEquals("Hello", result);
```
## 封装计算逻辑
上面的代码允许我们选择任何并发执行机制，但是如果我们想跳过这个样板文件并异步执行一些代码怎么办？静态方法`runAsync`和`SupplyAsync`允许我们相应地从`Runnable`和`Supplier`函数类型创建`CompletableFuture`实例。`Runnable`和`Supplier`是函数式接口，借助新的Java 8功能，允许将其实例作为lambda表达式传递。`Runnable`接口与线程中使用的旧接口相同，并且不允许返回值。`Supplier`接口是一个通用函数接口，具有单个方法，没有参数并返回参数化类型的值。这允许我们提供`Supplier`的实例作为lambda 表达式来执行计算并返回结果。它很简单:
```java
CompletableFuture<String> future
  = CompletableFuture.supplyAsync(() -> "Hello");

// ...

assertEquals("Hello", future.get());
```
## 处理异步计算的结果
处理异步计算的结果的最最常见的方式是传递到一个函数中，`thenApply`方法就是干这个的，它接受一个`Function`实例作为参数，使用它来处理结果，返回一个`Future`来存储函数返回的值
```java
CompletableFuture<String> completableFuture
  = CompletableFuture.supplyAsync(() -> "Hello");

CompletableFuture<String> future = completableFuture
  .thenApply(s -> s + " World");

assertEquals("Hello World", future.get());
```
如果我们不需要返回值，可以使用`Consumer`函数接口，它只消费不产生返回值。`CompletableFuture`中的`thenAccept`方法就是处理这种情况的
```java
CompletableFuture<String> completableFuture
  = CompletableFuture.supplyAsync(() -> "Hello");

CompletableFuture<Void> future = completableFuture
  .thenAccept(s -> System.out.println("Computation returned: " + s));

future.get();
```
最后，如果我们既不需要计算的值，也不想在链的末尾返回某个值，那么我们可以将`Runnable`lambda传递给`thenRun`方法。在下面的示例中，我们在调用`future.get()`后简单地在控制台中打印一行：
```java
CompletableFuture<String> completableFuture 
  = CompletableFuture.supplyAsync(() -> "Hello");
CompletableFuture<Void> future = completableFuture
  .thenRun(() -> System.out.println("Computation finished."));

future.get();
```
## Combining Futures
组合各种计算步骤，`CompletableFuture`最好的地方就是能够在一个计算步骤chain中组合各种`CompletableFuture`实例。这个chain后的结果也是一个`CompletableFuture`，允许再次chaining与combining，这种方式在函数式编程语言中是普遍存在的，通常被称作一元设计模式。在下面的例子中，我们使用`thenCompose`方法来顺序的chain2个`Future`，请注意，这个方法的是一个返回`CompletableFuture`实例的`Function`，函数的参数是前面计算步骤的结果
```java
CompletableFuture<String> completableFuture 
  = CompletableFuture.supplyAsync(() -> "Hello")
    .thenCompose(s -> CompletableFuture.supplyAsync(() -> s + " World"));

assertEquals("Hello World", completableFuture.get());
```
`thenCompose`方法与`thenApply`方法一起实现了一元设计模式的基本构建块。它们与`Stream`和`Optional`类的`map`和`flatMap`方法密切相关，这些方法在 Java 8 中也可用。这两个方法都接收一个`Function`并将其应用于计算结果，但`thenCompose (flatMap)`方法接收一个返回相同类型的另一个对象的函数。这种功能结构允许将这些类的实例组成为构建块。如果我们想要执行两个独立的`Future`并对其结果执行某些操作，我们可以使用`thenCombine`方法，该方法接受`Future`和带有两个参数的`Function`来处理这两个结果:
```java
CompletableFuture<String> completableFuture 
  = CompletableFuture.supplyAsync(() -> "Hello")
    .thenCombine(CompletableFuture.supplyAsync(
      () -> " World"), (s1, s2) -> s1 + s2));
assertEquals("Hello World", completableFuture.get());
```
一个更简单的情况是，当我们想要对两个`Future`的结果执行某些操作，但不需要将任何结果值传递到`Future`链上时。`thenAcceptBoth`方法可以提供帮助:
```java
CompletableFuture future = CompletableFuture.supplyAsync(() -> "Hello")
  .thenAcceptBoth(CompletableFuture.supplyAsync(() -> " World"),
    (s1, s2) -> System.out.println(s1 + s2));
```
## Difference Between thenApply() and thenCompose()
在我们前面的小节中，我们展示了`thenApply()`与`thenCompose()`API，2个API帮助chain不同的`CompletableFuture`调用，但是2个API的使用场景是不同的
- `thenApply()`: 我们可以使用这个方法来操作前一个调用的结果，然而，需要记住的关键点是返回类型是所有组合调用后的结果，所以这个方法用来转换`CompletableFuture`调用的结果`CompletableFuture<Integer> finalResult = compute().thenApply(s-> s + 1);`
- `thenCompose()`: `thenCompose()`方法与`thenApply()`方法类似，都返回一个新的`CompletionStage`，然而，`thenCompose()`使用前一个stage作为参数，它会flatten并返回一个Future
  ```java
    CompletableFuture<Integer> computeAnother(Integer i){
        return CompletableFuture.supplyAsync(() -> 10 + i);
    }
    CompletableFuture<Integer> finalResult = compute().thenCompose(this::computeAnother);
  ```
  所以如果想要chain多个`CompletableFuture`,使用这个方法
## Running Multiple Futures in Parallel
当我们想并行执行多个`Future`时，通常我们想等待他们全部执行完，然后处理他们的所有结果。`CompletableFuture.allOf `静态方法解决这个
```java
CompletableFuture<String> future1  
  = CompletableFuture.supplyAsync(() -> "Hello");
CompletableFuture<String> future2  
  = CompletableFuture.supplyAsync(() -> "Beautiful");
CompletableFuture<String> future3  
  = CompletableFuture.supplyAsync(() -> "World");

CompletableFuture<Void> combinedFuture 
  = CompletableFuture.allOf(future1, future2, future3);

// ...

combinedFuture.get();

assertTrue(future1.isDone());
assertTrue(future2.isDone());
assertTrue(future3.isDone());
```
`CompletableFuture.allOf()`的返回类型是一个`CompletableFuture<Void>`，这个方法的限制是不能返回所有`Future`的结果，我们必须人工去获取结果，幸运的是，`CompletableFuture.join()`与`Stream`API结合可以获取结果
```java
String combined = Stream.of(future1, future2, future3)
  .map(CompletableFuture::join)
  .collect(Collectors.joining(" "));

assertEquals("Hello Beautiful World", combined);
```
`CompletableFuture.join()`方法类似`get()`方法，但是它抛出未检查异常。
## hanlding Errors
对于异步计算步骤链中的错误处理，我们必须以类似的方式调整`throw/catch`习惯用法。`CompletableFuture`类允许我们在特殊的句柄方法中处理异常，而不是在语法块中捕获异常。此方法接收两个参数：计算结果(如果成功完成)和抛出的异常(如果某些计算步骤未正常完成)。在下面的示例中，当问候语的异步计算因未提供名称而出错时，我们使用handle方法提供默认值：
```java
String name = null;
CompletableFuture<String> completableFuture  
  =  CompletableFuture.supplyAsync(() -> {
      if (name == null) {
          throw new RuntimeException("Computation error!");
      }
      return "Hello, " + name;
  }).handle((s, t) -> s != null ? s : "Hello, Stranger!");

assertEquals("Hello, Stranger!", completableFuture.get());
```
作为替代方案，假设我们想要手动完成`Future`的值(如第一个示例中所示)，但也能够通过异常来完成它。`completeExceptionally()`方法就是为此目的而设计的。以下示例中的`completableFuture.get()`方法抛出`ExecutionExceptio`，其原因是`RuntimeException`:
```java
CompletableFuture<String> completableFuture = new CompletableFuture<>();
completableFuture.completeExceptionally(
  new RuntimeException("Calculation failed!"));
completableFuture.get(); // ExecutionException
```
在上面的例子中，我们可以使用`handle`方法异步处理异常，但是使用get方法，我们可以使用更典型的同步异常处理方法.
## Async Methods
`CompletableFuture`类中的Fluent API的大多数方法都有两个带有`Async`后缀的附加变体。这些方法通常用于在另一个线程中运行相应的执行步骤。没有Async后缀的方法使用调用线程运行下一个执行阶段。相比之下，不带`Executor`参数的Async方法使用Executor的通用fork/join pool实现运行一个步骤，只要并行度 > 1，即可通过`ForkJoinPool.commonPool()`访问该步骤。最后，带有`Executor`参数的Async方法 使用传递的执行器运行一个步骤。这是一个修改后的示例，它使用`Function`实例处理计算结果。唯一可见的区别是`thenApplyAsync`方法，但在底层，函数的应用程序被包装到`ForkJoinTask`实例中(有关fork/join框架的更多信息，请参阅文章“Java 中的 Fork/Join 框架指南”)。这使我们能够更多地并行计算并更有效地使用系统资源:
```java
CompletableFuture<String> completableFuture  
  = CompletableFuture.supplyAsync(() -> "Hello");

CompletableFuture<String> future = completableFuture
  .thenApplyAsync(s -> s + " World");

assertEquals("Hello World", future.get());
```
## JDK 9 CompletableFuture API
Java9在以下几个方面提升了`CompletableFuture`API:
- 添加了新的工厂方法
- 支持延迟与超时
- 改进了对子类化的支持

新增了一些实例API:
- `Executor defaultExecutor()`
- `CompletableFuture<U> newIncompleteFuture()`
- `CompletableFuture<T> copy()`
- `CompletionStage<T> minimalCompletionStage()`
- `CompletableFuture<T> completeAsync(Supplier<? extends T> supplier, Executor executor)`
- `CompletableFuture<T> completeAsync(Supplier<? extends T> supplier)`
- `CompletableFuture<T> orTimeout(long timeout, TimeUnit unit)`
- `CompletableFuture<T> completeOnTimeout(T value, long timeout, TimeUnit unit)`

一些静态工具方法
- `Executor delayedExecutor(long delay, TimeUnit unit, Executor executor)`
- `Executor delayedExecutor(long delay, TimeUnit unit)`
- `<U> CompletionStage<U> completedStage(U value)`
- `<U> CompletionStage<U> failedStage(Throwable ex)`
- `<U> CompletableFuture<U> failedFuture(Throwable ex)`

最终，为了解决超时的问题，Java 9引入了2个新的函数:
- `orTimeout()`
- `completeOnTimeout()`

具体的提升参考文档[Java 9 CompletableFuture API Improvements.](https://www.baeldung.com/java-9-completablefuture)
## Conclusion
# Java CompletableFuture Tutorial with Examples
Java8引入了很多的新特性与提升，比如lambda表达式、Streams、`CompletableFuture`等。下面简单讲述下`CompletableFuture`的详细解释。
## What's CompletableFuture
`CompletableFuture`用来做异步编程，异步编程就是在主应用线程另外一个线程中运行一个任务，这个任务是非阻塞的代码编写的，任务通知主线程它的进度、完成或者失败等事件。这样，主线程不需要阻塞等待任务的完成，它可以并行执行其他的任务。这种并行模式极大的提升了程序的性能。详细参考[Java Concurrency and Multithreading Basics](https://www.callicoder.com/java-concurrency-multithreading-basics/)
## Future vs CompletableFuture
`CompletableFuture`是Java的`Future`API的扩展，一个`Future`用来表示异步计算结果的引用。它提供了一个`isDone()`方法来检查计算是否完成，一个`get()`方法来检索计算的结果。[Callable and Future Tutorial](https://www.callicoder.com/java-callable-and-future-tutorial/)里面有更多的`Future`的介绍。`Future`API是向Java异步编程迈出的良好一步，但它缺乏一些重要且有用的功能
- 它不能手动结束: 假设您编写了一个函数来从远程API获取电子商务产品的最新价格。由于此API调用非常耗时，因此您在单独的线程中运行它并从函数返回`Future`现在，假设如果远程API服务已关闭，那么您希望通过产品的最后缓存价格手动完成`Future`,你能用`Future`做到这一点吗？不！
- 在不阻塞的情况下，您无法对`Future`的结果执行进一步的操作: `Future`不会通知您其完成。它提供了一个`get()`方法，该方法会阻塞直到结果可用。您无法将回调函数附加到`Future`并在`Future`的结果可用时自动调用它。
- 多个`Future`不能链接在一起: 有时您需要执行长时间运行的计算，并且当计算完成后，您需要将其结果发送到另一个长时间运行的计算，依此类推。您无法使用`Future`创建此类异步工作流程。
- 您不能将多个`Future`组合在一起: 假设您有10个不同的`Future`，您想要并行运行，然后在所有这些`Future`完成后运行某个函数。你不能用 `Future`来做到这一点
- 没有异常处理: 没有任何异常处理构造

有如此多的限制，这就是为什么开发了`CompletableFuture`，它能实现上面的所有限制。`CompletableFuture`接口继承`Future`与`CompletionStage`接口，提供了大量方便的方法来创建、chaining、combining多个`Future`，也支持异常处理。
## Creating a CompletableFuture
使用无参的构造函数来创建一个`CompletableFuture`，`CompletableFuture<String> completableFuture = new CompletableFuture<String>();`。这是您可以拥有的最简单的 `CompletableFuture`。所有想要获取此`CompletableFuture`结果的客户端都可以调用 `CompletableFuture.get()`方法`String result = completableFuture.get()`。`get()`方法会阻塞直到`Future`计算完成。使用`CompletableFuture.complete()`方法人工设置Future的完成值`completableFuture.complete("Future's Result")`。如果你想异步运行一些后台任务并且不想从任务中返回任何内容，那么你可以使用`CompletableFuture.runAsync()`方法。它接受一个`Runnable`对象并返回`CompletableFuture<Void>`。
```java
// Run a task specified by a Runnable Object asynchronously.
CompletableFuture<Void> future = CompletableFuture.runAsync(new Runnable() {
    @Override
    public void run() {
        // Simulate a long-running Job
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            throw new IllegalStateException(e);
        }
        System.out.println("I'll run in a separate thread than the main thread.");
    }
});

// Block and wait for the future to complete
future.get()
```
`Runnable`对象可以使用lambda表达式。
```java
// Using Lambda Expression
CompletableFuture<Void> future = CompletableFuture.runAsync(() -> {
    // Simulate a long-running Job   
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
        throw new IllegalStateException(e);
    }
    System.out.println("I'll run in a separate thread than the main thread.");
});
```
`CompletableFuture.runAsync()`对于不返回任何内容的任务很有用。但是如果您想从后台任务返回一些结果怎么办？好吧，`CompletableFuture.supplyAsync()`是你的伴侣。它接受一个`Supplier<T>`并返回`CompletableFuture<T>`，其中T是通过调用给定`Supplier`获得的值的类型。
```java
// Run a task specified by a Supplier object asynchronously
CompletableFuture<String> future = CompletableFuture.supplyAsync(new Supplier<String>() {
    @Override
    public String get() {
        try {
            TimeUnit.SECONDS.sleep(1);
        } catch (InterruptedException e) {
            throw new IllegalStateException(e);
        }
        return "Result of the asynchronous computation";
    }
});

// Block and get the result of the Future
String result = future.get();
System.out.println(result);
```
`Supply<T>`是一个简单的函数接口，代表结果的提供者。它有一个`get()`方法，您可以在其中编写后台任务并返回结果。再次，你可以使用Java 8的lambda表达式让上面的代码更加简洁
```java
// Using Lambda Expression
CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
        throw new IllegalStateException(e);
    }
    return "Result of the asynchronous computation";
});
```
### 关于Executor与Thread Pool
您可能想知道 - 嗯，我知道`runAsync()`和`SupplyAsync()`方法在单独的线程中执行其任务。 但是，我们从来没有创建过线程，对吗？
`CompletableFuture`使用来自于`ForkJoinPool.commonPool()`中的线程来执行任务。但是你可以创建一个Thread Pool，并作为参数传到`runAsync()`或者`supplyAsync()`方法，让它们使用来自你创建的线程池中的线程来执行任务。`CompletableFuture`API的所有方法都有2个变体，一个有`Executor`一个没有。
```java
// Variations of runAsync() and supplyAsync() methods
static CompletableFuture<Void>	runAsync(Runnable runnable)
static CompletableFuture<Void>	runAsync(Runnable runnable, Executor executor)
static <U> CompletableFuture<U>	supplyAsync(Supplier<U> supplier)
static <U> CompletableFuture<U>	supplyAsync(Supplier<U> supplier, Executor executor)
Executor executor = Executors.newFixedThreadPool(10);
CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
        throw new IllegalStateException(e);
    }
    return "Result of the asynchronous computation";
}, executor);
```
## Transforming and acting on a CompletableFuture
`CompletableFuture.get()`方法是阻塞的。它会等待`Future`完成并在完成后返回结果。但是，这不是我们想要的，对吗？为了构建异步系统，我们应该能够将回调附加到`CompletableFuture`，当`Future`完成时，它应该自动被调用。这样我们就不需要等待结果了，我们可以把`Future`完成后需要执行的逻辑写在我们的回调函数中。您可以使用`thenApply()`、`thenAccept()`和`thenRun()`方法将回调附加到`CompletableFuture`。
### `thenApply()`
当`CompletableFuture`计算完成时，您可以使用`thenApply()`方法来处理和转换结果。它接受`Function<T,R>`作为参数。`Function<T,R>`是一个简单的函数接口，表示接受T类型的参数并生成R类型的结果的函数
```java
// Create a CompletableFuture
CompletableFuture<String> whatsYourNameFuture = CompletableFuture.supplyAsync(() -> {
   try {
       TimeUnit.SECONDS.sleep(1);
   } catch (InterruptedException e) {
       throw new IllegalStateException(e);
   }
   return "Rajeev";
});
// Attach a callback to the Future using thenApply()
CompletableFuture<String> greetingFuture = whatsYourNameFuture.thenApply(name -> {
   return "Hello " + name;
});
// Block and get the result of the future.
System.out.println(greetingFuture.get()); // Hello Rajeev
```
您还可以通过附加一系列`thenApply()`回调方法来在`CompletableFuture`上编写一系列转换。一个`thenApply()`方法的结果将传递给该系列中的下一个方法
```java
CompletableFuture<String> welcomeText = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
       throw new IllegalStateException(e);
    }
    return "Rajeev";
}).thenApply(name -> {
    return "Hello " + name;
}).thenApply(greeting -> {
    return greeting + ", Welcome to the CalliCoder Blog";
});

System.out.println(welcomeText.get());
// Prints - Hello Rajeev, Welcome to the CalliCoder Blog
```
### `thenAccept()`与`thenRun()`
如果您不想从回调函数中返回任何内容，而只想在`Future`完成后运行一些代码，那么您可以使用`thenAccept()`和`thenRun()`方法。这些方法是消费者，通常用作回调链中的最后一个回调。`CompletableFuture.thenAccept()`接受`Consumer<T>`并返回`CompletableFuture<Void>`。它可以访问它所附加的`CompletableFuture`的结果。
```java
// thenAccept() example
CompletableFuture.supplyAsync(() -> {
	return ProductService.getProductDetail(productId);
}).thenAccept(product -> {
	System.out.println("Got product detail from remote service " + product.getName())
});
```
虽然`thenAccept()`可以访问它所附加的`CompletableFuture`的结果，但`thenRun()`甚至无法访问`Future`的结果。它需要一个`Runnable`并返回`CompletableFuture<Void>`。
```java
// thenRun() example
CompletableFuture.supplyAsync(() -> {
    // Run some computation  
}).thenRun(() -> {
    // Computation Finished.
});
```
### 关于异步回调方法
所有的回调方法都有2种异步变体
```java
// thenApply() variants
<U> CompletableFuture<U> thenApply(Function<? super T,? extends U> fn)
<U> CompletableFuture<U> thenApplyAsync(Function<? super T,? extends U> fn)
<U> CompletableFuture<U> thenApplyAsync(Function<? super T,? extends U> fn, Executor executor)
```
这些异步回调变体帮助你并行执行计算
```java
CompletableFuture.supplyAsync(() -> {
    try {
       TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
      throw new IllegalStateException(e);
    }
    return "Some Result"
}).thenApply(result -> {
    /* 
      Executed in the same thread where the supplyAsync() task is executed
      or in the main thread If the supplyAsync() task completes immediately (Remove sleep() call to verify)
    */
    return "Processed Result"
})
```
在上面这个例子中，`thenApply()`中的任务与`supplyAsync()`任务执行在同一个线程中或者在主线程中(`supplyAsync()`任务执行完的情况)。为了更好的控制执行回调任务的线程，使用异步回调回更好，异步回调在`ForkJoinPool.commonPool()`中的线程中执行或者自己定义的`Executor`
```java
CompletableFuture.supplyAsync(() -> {
    return "Some Result"
}).thenApplyAsync(result -> {
    // Executed in a different thread from ForkJoinPool.commonPool()
    return "Processed Result"
})
```
## Combining two CompletableFutures together
### Combine two dependent futures using thenCompose()
假设您想要从远程API服务获取用户的详细信息，一旦用户的详细信息可用，您想要从另一个服务获取他的信用评级。考虑`getUserDetail()`和`getCreditRating()`方法的以下实现:
```java
CompletableFuture<User> getUsersDetail(String userId) {
	return CompletableFuture.supplyAsync(() -> {
		return UserService.getUserDetails(userId);
	});	
}

CompletableFuture<Double> getCreditRating(User user) {
	return CompletableFuture.supplyAsync(() -> {
		return CreditRatingService.getCreditRating(user);
	});
}
```
如果使用`thenApply()`来实现想要的结果:
```java
CompletableFuture<CompletableFuture<Double>> result = getUserDetail(userId)
.thenApply(user -> getCreditRating(user));
```
在早期的例子中，`Supplier`函数传给`thenApply`回调会返回一个简单的值，但是在这个例子中，返回了一个`CompletableFuture`，因此，最终的结果是一个嵌套的`CompletableFuture`。如果你想要最终的结果是一个`top-level`的Future，请使用`thenCompose()`方法。
```java
CompletableFuture<Double> result = getUserDetail(userId)
.thenCompose(user -> getCreditRating(user));
```
所以，这里的经验法则是，如果你的回调函数返回一个`CompletableFuture`，你想要的是`CompletableFuture`链中的flattened结果。使用`thenCompose()`。
### Combine two independent futures using thenCombine()
`thenCompose()`用来combine2个相互依赖的`Future`。`thenCombine()`用来运行2个独立的`Future`s，并在他们都完成后运行一些逻辑。
```java
System.out.println("Retrieving weight.");
CompletableFuture<Double> weightInKgFuture = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
       throw new IllegalStateException(e);
    }
    return 65.0;
});

System.out.println("Retrieving height.");
CompletableFuture<Double> heightInCmFuture = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
       throw new IllegalStateException(e);
    }
    return 177.8;
});

System.out.println("Calculating BMI.");
CompletableFuture<Double> combinedFuture = weightInKgFuture
        .thenCombine(heightInCmFuture, (weightInKg, heightInCm) -> {
    Double heightInMeter = heightInCm/100;
    return weightInKg/(heightInMeter*heightInMeter);
});

System.out.println("Your BMI is - " + combinedFuture.get());
```
## Combining multiple CompletableFutures together
我们已经使用`thenCompose()`和`thenCombine()`将两个`CompletableFuture`组合在一起。现在，如果您想组合任意数量的 `CompletableFutures`该怎么办？那么，您可以使用以下方法来组合任意数量的`CompletableFutures`:
### CompletableFuture.allOf()
`CompletableFuture.allOf`用于以下场景: 您有一些独立的`Future`，您希望并行运行这些`Future`，并在所有`Future`完成后执行某些操作。假设您要下载某个网站100个不同网页的内容。您可以按顺序执行此操作，但这会花费很多时间。因此，您编写了一个函数，它接受网页链接并返回 `CompletableFuture`，即它异步下载网页内容
```java
CompletableFuture<String> downloadWebPage(String pageLink) {
	return CompletableFuture.supplyAsync(() -> {
		// Code to download and return the web page's content
	});
} 
```
现在所有的web页面都下载下来了，你想要计算页面中含有关键词`CompletableFuture`的数量，可以使用`CompletableFuture.allOf()`来实现。
```java
List<String> webPageLinks = Arrays.asList(...)	// A list of 100 web page links

// Download contents of all the web pages asynchronously
List<CompletableFuture<String>> pageContentFutures = webPageLinks.stream()
        .map(webPageLink -> downloadWebPage(webPageLink))
        .collect(Collectors.toList());


// Create a combined Future using allOf()
CompletableFuture<Void> allFutures = CompletableFuture.allOf(
        pageContentFutures.toArray(new CompletableFuture[pageContentFutures.size()])
);
```
`CompletableFuture.allOf()`的问题是它返回`CompletableFuture<Void>`，我们可以用别的方式获取所有的`Future`的结果
```java
// When all the Futures are completed, call `future.join()` to get their results and collect the results in a list -
CompletableFuture<List<String>> allPageContentsFuture = allFutures.thenApply(v -> {
   return pageContentFutures.stream()
           .map(pageContentFuture -> pageContentFuture.join())
           .collect(Collectors.toList());
});
```
花点时间来理解上面的代码片段，当所有的`Future`都执行完成了，我们才调用`future.join`，我们不是阻塞的，`join()`方法类似`get()`.
### CompletableFuture.anyOf()
`CompletableFuture.anyOf()`顾名思义，返回一个新的`CompletableFuture`，当任何给定的`CompletableFuture`完成时，它就会完成，并具有相同的结果。考虑以下示例:
```java
CompletableFuture<String> future1 = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(2);
    } catch (InterruptedException e) {
       throw new IllegalStateException(e);
    }
    return "Result of Future 1";
});

CompletableFuture<String> future2 = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(1);
    } catch (InterruptedException e) {
       throw new IllegalStateException(e);
    }
    return "Result of Future 2";
});

CompletableFuture<String> future3 = CompletableFuture.supplyAsync(() -> {
    try {
        TimeUnit.SECONDS.sleep(3);
    } catch (InterruptedException e) {
       throw new IllegalStateException(e);
    }
    return "Result of Future 3";
});

CompletableFuture<Object> anyOfFuture = CompletableFuture.anyOf(future1, future2, future3);

System.out.println(anyOfFuture.get()); // Result of Future 2
```
在上面的示例中，当三个`CompletableFuture`中的任何一个完成时`anyOfFuture`也完成。由于`future2`的睡眠时间最少，因此它将首先完成，最终结果将是`Future 2`的结果。`CompletableFuture.anyOf()`接受`Future`的可变参数并返回`CompletableFuture<Object>`。 `CompletableFuture.anyOf()`的问题是，如果您有返回不同类型结果的`CompletableFuture`，那么您将不知道最终`CompletableFuture`的类型。
## CompletableFuture Exception Handling
我们探索了如何创建`CompletableFuture`、转换它们以及组合多个`CompletableFuture`。现在让我们了解出现问题时该怎么办。让我们首先了解错误是如何在回调链中传播的。考虑以下`CompletableFuture`回调链:
```java
CompletableFuture.supplyAsync(() -> {
	// Code which might throw an exception
	return "Some result";
}).thenApply(result -> {
	return "processed result";
}).thenApply(result -> {
	return "result after further processing";
}).thenAccept(result -> {
	// do something with the final result
});
```
如果原始`SupplyAsync()`任务中发生错误，则不会调用任何`thenApply()`回调，并且`future`将解决发生的异常。如果第一个`thenApply()`回调中发生错误，则不会调用第二个和第三个回调，并且`future`将通过发生异常来解决，依此类推。
### Handle exceptions using exceptionally() callback
`exceptedly()`回调让您有机会从原始`Future`生成的错误中恢复。您可以在此处记录异常并返回默认值。
```java
Integer age = -1;

CompletableFuture<String> maturityFuture = CompletableFuture.supplyAsync(() -> {
    if(age < 0) {
        throw new IllegalArgumentException("Age can not be negative");
    }
    if(age > 18) {
        return "Adult";
    } else {
        return "Child";
    }
}).exceptionally(ex -> {
    System.out.println("Oops! We have an exception - " + ex.getMessage());
    return "Unknown!";
});

System.out.println("Maturity : " + maturityFuture.get()); 
```
请注意，如果处理一次，错误将不会在回调链中进一步传播。
### Handle exceptions using the generic handle() method
该API还提供了一个更通用的方法`handle()`来从异常中恢复。无论是否发生异常都会被调用。
```java
Integer age = -1;
CompletableFuture<String> maturityFuture = CompletableFuture.supplyAsync(() -> {
    if(age < 0) {
        throw new IllegalArgumentException("Age can not be negative");
    }
    if(age > 18) {
        return "Adult";
    } else {
        return "Child";
    }
}).handle((res, ex) -> {
    if(ex != null) {
        System.out.println("Oops! We have an exception - " + ex.getMessage());
        return "Unknown!";
    }
    return res;
});
System.out.println("Maturity : " + maturityFuture.get());
```
