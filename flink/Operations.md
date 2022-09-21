# 指标
Flink提供了指标系统，可以收集指标并提供给外部的系统.
## 注册指标
你可以在任意的继承于`RichFunction`的用户函数中访问指标系统，这是通过调用`getRuntimeContext().getMetricGroup()`实现的，这个方法会返回一个`MetricGroup`对象，你可以在其上注册新的指标.
### 指标类型
Flink支持`Counters`、`Gauges`、`Histograms`、`Meters`4种指标
1. Counter
   用于计算数量，可以加减，例子如下:
   ```java
   public class MyMapper extends RichMapFunction<String, String> {
  private transient Counter counter;

  @Override
  public void open(Configuration config) {
    this.counter = getRuntimeContext()
      .getMetricGroup()
      .counter("myCounter");
  }

  @Override
  public String map(String value) throws Exception {
    this.counter.inc();
    return value;
  }
    }
   ```
   你也可以自定义Counter实现
   ```java
   public class MyMapper extends RichMapFunction<String, String> {
  private transient Counter counter;

  @Override
  public void open(Configuration config) {
    this.counter = getRuntimeContext()
      .getMetricGroup()
      .counter("myCustomCounter", new CustomCounter());
    }

    @Override
    public String map(String value) throws Exception {
    this.counter.inc();
    return value;
    }
    }
   ```
2. Gauge
   Gauge提供一个任意类型的值，为了使用Gauge，你必须首先创建一个实现`org.apache.flink.metrics.Gauge`接口的类，返回类型任意，没有严格的限制，使用的例子如下:
   ```java
   public class MyMapper extends RichMapFunction<String, String> {
  private transient int valueToExpose = 0;

  @Override
  public void open(Configuration config) {
    getRuntimeContext()
      .getMetricGroup()
      .gauge("MyGauge", new Gauge<Integer>() {
        @Override
        public Integer getValue() {
          return valueToExpose;
        }
      });
  }

  @Override
  public String map(String value) throws Exception {
    valueToExpose++;
    return value;
  }
    }
   ```

3. Histogram
   Histogram监测long值的分布，使用方式如下:
   ```java
   public class MyMapper extends RichMapFunction<Long, Long> {
  private transient Histogram histogram;

  @Override
  public void open(Configuration config) {
    this.histogram = getRuntimeContext()
      .getMetricGroup()
      .histogram("myHistogram", new MyHistogram());
  }

  @Override
  public Long map(Long value) throws Exception {
    this.histogram.update(value);
    return value;
  }
    }
   ```
   Flink没有为Histogram提供默认实现，但提供了一个Wrapper允许使用Codahale/DropWizard直方图。 要使用此包装器，请在 pom.xml 中添加以下依赖项:
   ```xml
   <dependency>
      <groupId>org.apache.flink</groupId>
      <artifactId>flink-metrics-dropwizard</artifactId>
      <version>1.17-SNAPSHOT</version>
    </dependency>
   ```
4. Meter
   Meter可以测量平均吞吐量，可以使用`markEvent()`表示出现某个事件，出现多个事件可以用`markEvent(long n)`表示，使用方式如下:
   ```java
   public class MyMapper extends RichMapFunction<Long, Long> {
  private transient Meter meter;

  @Override
  public void open(Configuration config) {
    this.meter = getRuntimeContext()
      .getMetricGroup()
      .meter("myMeter", new MyMeter());
  }

  @Override
  public Long map(Long value) throws Exception {
    this.meter.markEvent();
    return value;
  }
  }
   ```
## Scope
每个指标都分配有一个标识符和一组键值对，根据这些键值对报告指标。该标识符由3个部分组成：注册指标时的用户定义名称、可选的用户作用域和系统作用域。例如，如果A.B是系统作用域，C.D是用户作用域，E是名称，那么指标标准的标识符将为A.B.C.D.E。你可以通过在conf/flink-conf.yaml中设置`metrics.scope.delimiter`键来配置标识符使用的分隔符（默认是点号）。
1. 用户作用域
   您可以通过调用`MetricGroup#addGroup(String name)`、`MetricGroup#addGroup(int name)`或`MetricGroup#addGroup(String key, String value)`来定义用户作用域。 这些方法会影响`MetricGroup#getMetricIdentifier`和`MetricGroup#getScopeComponents`返回的内容。
   ```java
   counter = getRuntimeContext()
  .getMetricGroup()
  .addGroup("MyMetrics")
  .counter("myCounter");

    counter = getRuntimeContext()
  .getMetricGroup()
  .addGroup("MyMetricsKey", "MyMetricsValue")
  .counter("myCounter");
   ```
   