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
这种测试不精确一个是StopWatch会影响还有JVM的优化以及其运行时的内存状态都有影响。严谨的测试需要使用JMH。