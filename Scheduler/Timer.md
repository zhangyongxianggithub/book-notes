# Timer
Timer/TimerTask时java.util包下面的类，用来在后台线程中调度任务执行，TimerTask是要执行的任务，Timer是调度器。
# 调度一个任务执行一次
## 在给定的延迟之后执行
```java
@Test
public void givenUsingTimer_whenSchedulingTaskOnce_thenCorrect() {
    TimerTask task = new TimerTask() {
        public void run() {
            System.out.println("Task performed on: " + new Date() + "n" +
              "Thread's name: " + Thread.currentThread().getName());
        }
    };
    Timer timer = new Timer("Timer");
    
    long delay = 1000L;
    timer.schedule(task, delay);
}
```
这会在给定的延迟之后执行任务
## 在给定的日期与时间执行
```java
List<String> oldDatabase = Arrays.asList("Harrison Ford", "Carrie Fisher", "Mark Hamill");
List<String> newDatabase = new ArrayList<>();

LocalDateTime twoSecondsLater = LocalDateTime.now().plusSeconds(2);
Date twoSecondsLaterAsDate = Date.from(twoSecondsLater.atZone(ZoneId.systemDefault()).toInstant());

new Timer().schedule(new DatabaseMigrationTask(oldDatabase, newDatabase), twoSecondsLaterAsDate);
```
# 调度一个重复执行的任务
现在我们已经介绍了如何安排任务的单次执行，让我们看看如何处理可重复的任务。再次，Timer类提供了多种可能性。我们可以设置重复以观察固定延迟或固定速率。固定延迟意味着执行将在上次执行开始后的一段时间后开始，即使它被延迟（因此本身被延迟）。假设我们想每两秒安排一次任务，第一次执行需要一秒，第二次执行需要两秒，但会延迟一秒。然后第三次执行从第五秒开始：
```
0s     1s    2s     3s           5s
|--T1--|
|-----2s-----|--1s--|-----T2-----|
|-----2s-----|--1s--|-----2s-----|--T3--|
```
另一方面，固定速率意味着每次执行都将遵守初始计划，无论前一次执行是否延迟。让我们重用前面的示例。使用固定速率，第二个任务将在三秒后启动（由于延迟），但第三个任务将在四秒后启动（遵守每两秒执行一次的初始计划）：
```
0s     1s    2s     3s    4s
|--T1--|       
|-----2s-----|--1s--|-----T2-----|
|-----2s-----|-----2s-----|--T3--|
```
既然我们已经介绍了这两个原则，让我们看看如何使用它们。要使用固定延迟调度`schedule()`方法还有两个重载，每个重载都带有一个额外的参数，以毫秒为单位说明周期。为什么要有两个重载？因为仍然有可能在某个时刻或一定延迟后启动任务。至于固定速率调度，我们有两个`scheduleAtFixedRate()`方法，它们也以毫秒为单位设置周期。同样，我们有一种方法可以在给定的日期和时间启动任务，另一种方法可以在给定的延迟后启动任务。还值得一提的是，如果任务执行时间超过周期，则会延迟整个执行链，无论我们使用固定延迟还是固定速率。
## With a Fixed Delay
现在让我们想象一下，我们想要实现一个新闻通讯系统，每周向我们的关注者发送一封电子邮件。在这种情况下，重复性任务似乎是理想的选择。因此，让我们每秒安排一次新闻通讯，这基本上是垃圾邮件，但我们可以开始，因为发送是假的。首先，我们将设计一个`NewsletterTask`：
```java
public class NewsletterTask extends TimerTask {
    @Override
    public void run() {
        System.out.println("Email sent at: "
          + LocalDateTime.ofInstant(Instant.ofEpochMilli(scheduledExecutionTime()), ZoneId.systemDefault()));
        Random random = new Random();
        int value = random.ints(1, 7)
                .findFirst()
                .getAsInt();
        System.out.println("The duration of sending the mail will took: " + value);
        try {
            TimeUnit.SECONDS.sleep(value);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
    }
}
```
每次执行时，任务都会打印其计划时间，我们使用`TimerTask#scheduledExecutionTime()`方法收集该时间。那么，如果我们想以固定延迟模式每秒安排此任务怎么办？我们必须使用前面提到的`schedule()`的重载版本：
```java
new Timer().schedule(new NewsletterTask(), 0, 1000);
Thread.sleep(20000);
```
## With a Fixed Rate
现在，如果我们要使用固定速率重复怎么办？那么我们必须使用`scheduledAtFixedRate()`方法:
```java
new Timer().scheduleAtFixedRate(new NewsletterTask(), 0, 1000);
Thread.sleep(20000);
```
# 取消Timer与TimerTask
取消有下面几种方式
## 在TimerTask运行时取消
```java
@Test
public void givenUsingTimer_whenCancelingTimerTask_thenCorrect()
  throws InterruptedException {
    TimerTask task = new TimerTask() {
        public void run() {
            System.out.println("Task performed on " + new Date());
            cancel();
        }
    };
    Timer timer = new Timer("Timer");
    timer.scheduleAtFixedRate(task, 1000L, 1000L);
    Thread.sleep(1000L * 2);
}
```
## 取消Timer
```java
@Test
public void givenUsingTimer_whenCancelingTimer_thenCorrect() 
  throws InterruptedException {
    TimerTask task = new TimerTask() {
        public void run() {
            System.out.println("Task performed on " + new Date());
        }
    };
    Timer timer = new Timer("Timer");
    
    timer.scheduleAtFixedRate(task, 1000L, 1000L);
    
    Thread.sleep(1000L * 2); 
    timer.cancel(); 
}
```
## 在run方法内终止线程
```java
@Test
public void givenUsingTimer_whenStoppingThread_thenTimerTaskIsCancelled() 
  throws InterruptedException {
    TimerTask task = new TimerTask() {
        public void run() {
            System.out.println("Task performed on " + new Date());
            // TODO: stop the thread here
        }
    };
    Timer timer = new Timer("Timer");
    
    timer.scheduleAtFixedRate(task, 1000L, 1000L);
    
    Thread.sleep(1000L * 2); 
}
```
# Timer vs ExecutorService
我们还可以充分利用`ExecutorService`来安排计时器任务，而不是使用计时器。以下是如何以指定间隔运行重复任务的简单示例:
```java
@Test
public void givenUsingExecutorService_whenSchedulingRepeatedTask_thenCorrect() 
  throws InterruptedException {
    TimerTask repeatedTask = new TimerTask() {
        public void run() {
            System.out.println("Task performed on " + new Date());
        }
    };
    ScheduledExecutorService executor = Executors.newSingleThreadScheduledExecutor();
    long delay  = 1000L;
    long period = 1000L;
    executor.scheduleAtFixedRate(repeatedTask, delay, period, TimeUnit.MILLISECONDS);
    Thread.sleep(delay + period * 3);
    executor.shutdown();
}
```
它们之间的区别:
- `Timer`对系统时钟的变化更敏感，`ScheduledThreadPoolExecutor`不是
- `Timer`只有一个执行线程，`ScheduledThreadPoolExecutor`的线程数量可配置
- `TimerTask`抛出的运行时异常会杀死线程，后续的调度任务不会得到执行，`ScheduledThreadPoolExecutor`不会

# Conclusion
