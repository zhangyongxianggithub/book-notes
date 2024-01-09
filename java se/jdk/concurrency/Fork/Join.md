`ForkJoinPool`的原理
- ForkJoinPool的每个工作线程都维护着一个工作队列（WorkQueue），这是一个双端队列（Deque），里面存放的对象是任务（ForkJoinTask）。每个工作线程在运行中产生新的任务（通常是因为调用了`fork()`）时，会放入工作队列的队尾，并且工作线程在处理自己的工作队列时，使用的是LIFO方式，也就是说每次从队尾取出任务来执行。
- 每个工作线程在处理自己的工作队列同时，会尝试窃取一个任务（或是来自于刚刚提交到pool的任务，或是来自于其他工作线程的工作队列），窃取的任务位于其他线程的工作队列的队首，也就是说工作线程在窃取其他工作线程的任务时，使用的是FIFO方式。
- 在遇到`join()`时，如果需要join的任务尚未完成，则会先处理其他任务，并等待其完成。
- 在既没有自己的任务，也没有可以窃取的任务时，进入休眠。

`ForkJoinPool`和`ThreadPoolExecutor`比较
- 都实现了`Executor`与`ExecutorService`接口
- `ForkJoinPool`的队列是无限的
- `ForkJoinPool`是分治算法处理任务的
- `ThreadPoolExecutor`无法使用分治算法类处理任务
- `ForkJoinPool`实现了工作窃取
