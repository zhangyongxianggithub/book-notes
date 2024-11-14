# Overview 
在本文中，我们会学习在一段时间之后终止一个仍在运行的执行任务。我们研究了很多方案来解决这个问题，同时也会提醒一些误区。
# Using a Loop
想象一下，我们正在一个循环中处理一堆条目，例如电子商务应用程序中产品项目的一些详细信息，但可能没有必要完成所有项目。事实上，我们只想处理到某个时间，之后，我们想停止执行并显示列表到那时为止处理的内容。让我们看一个简单的例子:
```java
public class LoopExample {
    @SneakyThrows
    public static void main(final String[] args) {
        final long start = System.currentTimeMillis();
        final long end = start + 30 * 1000;
        while (System.currentTimeMillis() < end) {
            System.out.println(Thread.currentThread().getName());
            TimeUnit.SECONDS.sleep(1);
        }
    }
}
```
如果时间超过30秒，循环将会终止。这种方式的特点:
- 精确性较差: 循环的执行时间可能超过限制的时间，这受到每次迭代消耗的时间影响，如果每次迭代要7s，那么总的执行时间是35秒，
- 阻塞:  在主线程中处理不是歌好主意，因为它会阻塞很长时间，应该从主线程中解耦

基于中断的方式可以消除这些问题。
# 使用中断机制
这里我们使用一个线程来执行长时间运行任务。当超时时，主线程发送一个中断信号给工作线程。如果工作线程在执行，那么它会捕获到这个信号并终止执行。如果工作线程在超时之前完成，此时对工作线程没有影响。看下面的例子:
```java
class LongRunningTask implements Runnable {
    @Override
    public void run() {
        for (int i = 0; i < Long.MAX_VALUE; i++) {
            if(Thread.interrupted()) {
                return;
            }
        }
    }
}
```
这里，使用循环模拟一个长时间运行的任务，检查中断标志位很重要，因为并非所有操作都是可以中断的。我们需要在每次循环时检测这个标志位，确保线程最多一次迭代的延迟就可以终止执行。下面是3种发送中断信号的机制
## 使用一个Timer
我们可以创建一个`TimerTask`来在超时时中断工作者线程
```java
class TimeOutTask extends TimerTask {
    private Thread thread;
    private Timer timer;

    public TimeOutTask(Thread thread, Timer timer) {
        this.thread = thread;
        this.timer = timer;
    }

    @Override
    public void run() {
        if(thread != null && thread.isAlive()) {
            thread.interrupt();
            timer.cancel();
        }
    }
}
```
我们创建一个一个`TimerTask`，run方法执行时会中断工作者线程。`Timer`会在3秒延迟后触发`TimerTask`:
```java
Thread thread = new Thread(new LongRunningTask());
thread.start();

Timer timer = new Timer();
TimeOutTask timeOutTask = new TimeOutTask(thread, timer);
timer.schedule(timeOutTask, 3000);
```
## 使用Future#get()方法
```java
        final ExecutorService executor = Executors.newSingleThreadExecutor();
        final Future future = executor.submit(new LongRunningTask());
        try {
            future.get(7, TimeUnit.SECONDS);
            log.info("is done: {}", future.isDone());
        } catch (final TimeoutException e) {
            future.cancel(true);
            log.info("is done: {}, is cancel: {}, state: {}", future.isDone(),
                    future.isCancelled(), future.state());
        } catch (final Exception e) {
            e.printStackTrace();
        } finally {
            executor.shutdownNow();
        }
```
使用`ExecutorService`来提交工作者线程，并返回一个`Future`类型的实例，get方法将会阻塞主线程到规定的时间，超时后抛出`TimeoutException`异常。在捕获块，我们调用`Future`的cancel方法来中断工作者线程。这种方法的优势就是它使用pool来管理线程，Timer只使用一个单线程。
## 使用`ScheduledExecutorService`
也可以使用`ScheduledExecutorService`来中断任务，它是`ExecutorService`的实现类。还额外提供了几个用于处理调度执行的方法。它可以在给定的时间延迟之后执行一个给定的任务
```java
ScheduledExecutorService executor = Executors.newScheduledThreadPool(2);
Future future = executor.submit(new LongRunningTask());
Runnable cancelTask = () -> future.cancel(true);

executor.schedule(cancelTask, 3000, TimeUnit.MILLISECONDS);
executor.shutdown();
```
这里，我们创建一个可调度的线程池，上面的程序在提交调度3秒后执行给定的任务，这个给定的任务将会取消长运行时间任务。与前面的方式不同，我们并没有通过调用`Future.get`方法的方式阻塞主线程，因此，在所有上面的方法中，这是最好的一种方式。
# Is There a Guarantee
不能保证，任务执行一定在一个特定时间后终止，主要的原因是，并非所有的阻塞方法都是可以中断的，事实上，只有少数的定义良好的方法可以中断，所以，如果一个线程中断了，并且设置了中断标志位，只有在到达可中断的方法执行时才会触发中断。但是，我们可以在循环中每次读取后明确检查中断标志。这将提供合理的保证，以一定的延迟停止线程。但是，这并不能保证在严格的时间后停止线程，因为我们不知道读取操作需要多长时间。另一方面，Object类的wait方法是可中断的。因此，在设置中断标志后，wait方法中阻塞的线程将立即抛出`InterruptedException`。我们可以通过在其方法签名中查找`throws InterruptedException`来识别阻塞方法。一个重要的建议是避免使用已弃用的`Thread.stop()`方法。停止线程会导致它解锁它已锁定的所有监视器。这是因为ThreadDeath异常会沿堆栈向上传播。如果这些监视器之前保护的任何对象处于不一致状态，则这些不一致的对象将对其他线程可见。这可能导致难以检测和推理的任意行为。
# 中断设计
在前面的章节中，我们强调，使用可中断方法来尽可能的终止任务执行，因此，我们在设计代码时需要考虑这一期望。假如我们要执行一个长时间运行的任务。我们呢需要保证任务执行不要超过指定的时间，假如任务可以拆分成独立的步骤，我们需要为每个步骤创建类
```java
class Step {
    private static int MAX = Integer.MAX_VALUE/2;
    int number;

    public Step(int number) {
        this.number = number;
    }

    public void perform() throws InterruptedException {
        Random rnd = new Random();
        int target = rnd.nextInt(MAX);
        while (rnd.nextInt(MAX) != target) {
            if (Thread.interrupted()) {
                throw new InterruptedException();
            }
        }
    }
}
```
上面的步骤试图找到一个目标随机数，同时在每次循环都会检测中断标志位，如果设置了中断标志位，则抛出`InterruptedException`异常。让我们定义任务
```java
public class SteppedTask implements Runnable {
    private List<Step> steps;

    public SteppedTask(List<Step> steps) {
        this.steps = steps;
    }

    @Override
    public void run() {
        for (Step step : steps) {
            try {
                step.perform();
            } catch (InterruptedException e) {
                // handle interruption exception
                return;
            }
        }
    }
}
```
这里，`SteppedTask`有一个要执行的步骤列表。for循环执行每个步骤并处理`InterruptedException`以在发生时停止任务。最后，让我们看一个使用可中断任务的示例:
```java
List<Step> steps = Stream.of(
  new Step(1),
  new Step(2),
  new Step(3),
  new Step(4))
.collect(Collectors.toList());

Thread thread = new Thread(new SteppedTask(steps));
thread.start();

Timer timer = new Timer();
TimeOutTask timeOutTask = new TimeOutTask(thread, timer);
timer.schedule(timeOutTask, 10000);
```
首先，我们创建一个包含四个步骤的`SteppedTask`。其次，我们使用线程运行该任务。最后，我们使用计时器和超时任务在十秒后中断线程。通过这种设计，我们可以确保我们的长时间运行的任务可以在执行任何步骤时被中断。正如我们之前所见，缺点是不能保证它会在指定的准确时间停止，但肯定比不可中断的任务要好。


