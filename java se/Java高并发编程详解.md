# JMH
JMH是Java Micro Benchmark Harness的缩写，用于代码微基准测试，主要是用于了解代码的运行情况。
```java
public class ArrayListVSLinkedList {
    public static final String DUMMY_DATA = "DUMMY DATA";
    private static int MAX_CAPACITY = 1_000_000;
    private static int MAX_ITERATIONS = 10;
    private static void test(List<String> list) {
        for (int i = 0; i < MAX_CAPACITY; i++) {
            list.add(DUMMY_DATA);
        }
    }
    private static void testListPerf(Supplier<List<String>> listSupplier,
            int iterations) {
        for (int i = 0; i < iterations; i++) {
            final List<String> list = listSupplier.get();
            final Stopwatch stopwatch = Stopwatch.createStarted();
            test(list);
            System.out.println(stopwatch.stop().elapsed(TimeUnit.MILLISECONDS));
        }
    }
    public static void main(String[] args) {
        testListPerf(ArrayList::new, MAX_ITERATIONS);
        System.out.println(Strings.repeat("#", 100));
        testListPerf(LinkedList::new, MAX_ITERATIONS);
    }
}
```
这种测试不精确一个是StopWatch会影响还有JVM的优化以及其运行时的内存状态都有影响。严谨的测试需要使用JMH。使用JMH的方式
```java
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class ArrayListVSLinkedListWithJMH {
    public static final String DUMMY_DATA = "DUMMY DATA";
    private List<String> array;
    private List<String> linked;
    @Setup(Level.Iteration)
    public void setup() {
        this.array = new ArrayList<>();
        this.linked = new LinkedList<>();
    }
    @Benchmark
    public List<String> addArray() {
        this.array.add(DUMMY_DATA);
        return array;
    }
    @Benchmark
    public List<String> addLinked() {
        this.linked.add(DUMMY_DATA);
        return this.linked;
    }
    public static void main(String[] args) throws RunnerException {
        final Options options = new OptionsBuilder()
                .include(ArrayListVSLinkedListWithJMH.class.getSimpleName())
                .forks(1).measurementIterations(10).warmupIterations(10)
                .build();
        new Runner(options).run();
    }
}
```
## JMH的基本用法
- `@Benchmark`标记基准测试方法，类似Junit的`@Test`注解作用，如果没有任何方法被标注，则运行异常.
    ```java
    @BenchmarkMode(Mode.AverageTime)
    @OutputTimeUnit(TimeUnit.MICROSECONDS)
    @State(Scope.Thread)
    public class JMHExample02 {
        
        public void normalMethod() {
            
        }
        
        public static void main(String[] args) throws RunnerException {
            final Options opts = new OptionsBuilder()
                    .include(JMHExample02.class.getSimpleName()).forks(1)
                    .measurementIterations(10).warmupIterations(10).build();
            new Runner(opts).run();
        }
    }
    ```
  上面的类将会运行异常。
- warmup以及measurement，都是分批次执行基准测试方法的机制。warmup用于预热，就是使基准测试方法经过类优化JVM编译优化JIT优化之后处于最终运行的状态，从而获得真实性能数据。measurement是真正的度量操作，纳入统计。可以通过全局`Options`与全局注解设置批次，也可以在基准测试方法上添加注解设置批次。输出的信息参考文档
- 4大BenchmarkMode

# ExecutorService
## CompletableFuture
异步编程: 程序运算与应用程序的主线程在不同的线程上完成，程序运算的线程能够向主线程通知其进度/成功/失败的非阻塞编码方式。

