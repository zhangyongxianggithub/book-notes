[TOC]
version=5.2.3
Spring Data for Elasticsearch是所有Spring Data项目的一部分。Spring Data项目致力于提供熟悉且一致的基于Spring的编程模型在此基础上保留存储特有的特性与能力。Spring Data Elasticsearch与es集成，Spring Data Elasticsearch的关键功能是代表ES Document的POJO中心模型与Repository风格的数据访问层。
- Clients: 不同HTTP Clients的连接与配置
- ElasticsearchTemplate与ReactiveElasticsearchTemplate: 帮助类，提供了ES索引操作与POJO之间的对象映射
- Object Mapping: 功能强大的注解驱动的对象映射器
- Entity Callbacks: save/update/delete的前后回调
- Data Repositories: 支持自定义查询的Repositories接口
- Join-Typs，Routing，Scripting: 集成特殊的ES特性

Spring Data Elasticsearch为ES数据库提供了repository支持，通过一致性的编程模型简化了开发。
- Versions: 版本兼容矩阵
- Clients: ES客户端配置
- Elasticsearch: Elasticsearch支持
- Repositories: Elasticsearch Repositories
- Migration: 迁移指南

# Versions
下面表格是Spring Data版本序列与其对应的Spring Data Elasticsearch版本使用ES与Spring版本
![版本](elasticsearch/versions.png)
# overview
SDE是Spring Data项目的其中一部分。Spring Data项目为所有的数据存储中间件提供类似与一致性的基于Spring的编程模型。同时也支持数据存储库特有的特性与能力。SDE项目提供了与ES的整合。SDE的关键能力是POJO中心模型。使用POJO中心模型完成与ES文档的交互。使方便的编写Repository风格的数据访问层。
## Features
- 支持Spring所有配置方式
- ElasticsearchTemplate提高了执行ES操作的效率。
- 丰富的对象映射机制
- 基于注解的mapping元数据
- 支持Repository接口，支持自定义finder方法
- CDI支持

# Preface
SDE项目应用Spring核心概念到ES的开发中。提供了:
- Templates提供了高抽象度的文档存储、搜索、排序与聚合计算
- Repositories提供了通过接口定义查询的能力

# Elasticsearch Support
Spring Data Elasticssearch包含了很多的特性
- 为不同的Elasticsearch提供Spring配置支持
- The ElasticsearchTemplate与 ReactiveElasticsearchTemplate帮助类提供了对象映射
- 异常翻译为Spring的Data Access异常体系
- 功能强大的对象映射功能
- 映射注解，支持元注解
- 基于Java的query、criteria与update DSLs
- 命令式与响应式Repository接口的自动实现，支持自定义查询方法

对于大多数面向数据的任务，你都可以使用`[Reactive]ElasticsearchTemplate`与`Repository`,他们都具有丰富的对象映射功能。
## Elasticsearch Clients
本章阐述ES Client实现的配置与使用。SDE在一个Elasticsearch client(由Elasticsearch client libraries提供)上操作，这个client连接了一个ES节点或者一个ES集群。虽然可以直接使用ES的client来与集群通信，但是使用SDE的应用通常使用更高的抽象层Elasticsearch Operations与Elasticsearch Repositories来与ES通信。
### Imperative Rest Client
为了使用命令式客户端，必须配置一个configuration bean如下:
```java
@Configuration
public class MyClientConfig extends ElasticsearchConfiguration {

	@Override
	public ClientConfiguration clientConfiguration() {
		return ClientConfiguration.builder() // builder方法的详细描述，参考https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/clients.html#elasticsearch.clients.configuration          
			.connectedTo("localhost:9200")
			.build();
	}
}
```
ElasticsearchConfiguration类可以做更多的配置，比如覆写`jsonMapper()`或者`transportOptions()`方法。下面的bean可以注入到其他的Spring组件中:
```java
@Autowired
ElasticsearchOperations operations;     // 一个ElasticsearchOperations实现

@Autowired
ElasticsearchClient elasticsearchClient; // 一个co.elastic.clients.elasticsearch.ElasticsearchClient实例

@Autowired
RestClient restClient;                   // Elasticsearch库中的底层RestClient

@Autowired
JsonpMapper jsonpMapper;                 // Elasticsearch Transport使用JsonMapper
```
基本上你只需要使用`ElasticsearchOperations`来与ES集群交互就可以。实际上，Repositories也是实际使用的这个实例。
### Reactive Rest Client
使用到响应式技术栈时，配置类是不同的
```java
@Configuration
public class MyClientConfig extends ReactiveElasticsearchConfiguration {

	@Override
	public ClientConfiguration clientConfiguration() {
		return ClientConfiguration.builder()           
			.connectedTo("localhost:9200")
			.build();
	}
}
```
`ReactiveElasticsearchConfiguration`可以通过方法覆写做更多的配置。下面的beans可以注入其他的Spring组件
```java
@Autowired
ReactiveElasticsearchOperations operations; //ReactiveElasticsearchOperations的实现

@Autowired
ReactiveElasticsearchClient elasticsearchClient;// org.springframework.data.elasticsearch.client.elc.ReactiveElasticsearchClient的实例，这是一个基于Elasticsearch客户端实现的响应式实现

@Autowired
RestClient restClient; // 同前面

@Autowired
JsonpMapper jsonpMapper; //同前面
```
基本上，你只需要使用`ReactiveElasticsearchOperations`来与ES集群交互。
### Client Configuration
客户端行为可以通过`ClientConfiguration`改变，可选的可以设置SSL、connect/socket超时、headers与其他的参数。
```java
HttpHeaders httpHeaders = new HttpHeaders();
httpHeaders.add("some-header", "on every request")// 定义默认的headers

ClientConfiguration clientConfiguration = ClientConfiguration.builder()
  .connectedTo("localhost:9200", "localhost:9291") // 提供集群地址
  .usingSsl()//开启ssl，这个方法存在重载的版本，可以传递SSLContext等
  .withProxy("localhost:8888") // 设置一个代理
  .withPathPrefix("ela")  // 设置一个路径前缀，当集群在反向代理后面时使用
  .withConnectTimeout(Duration.ofSeconds(5))//设置connection超时
  .withSocketTimeout(Duration.ofSeconds(3)) //设置socket超时
  .withDefaultHeaders(defaultHeaders) //设置headers
  .withBasicAuth(username, password)  // 添加basic认证
  .withHeaders(() -> {     // 一个Supplier<HttpHeaders>对象，每次请求被发送到es前调用，
    HttpHeaders headers = new HttpHeaders();
    headers.add("currentTime", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
    return headers;
  })
  .withClientConfigurer(     // 用来配置已创建的client，可以添加多次
    ElasticsearchClientConfigurationCallback.from(clientBuilder -> {
  	  // ...
      return clientBuilder;
  	}))
  . // ... other options
  .build();
```
Supplier<HttpHeaders>的方式运行动态添加headers，比如认证的JWT tokens等。
### Client configuration callbacks
`ClientConfiguration`类提供了很多参数来配置客户端，如果这些参数还不够，用户可以使用`withClientConfigurer(ClientConfigurationCallback<?>)`添加回调函数。提供下面2种回调
1. Configuration of the low level Elasticsearch RestClient
   此回调提供了`org.elasticsearch.client.RestClientBuilder`，可用于配置Elasticsearch RestClient:
   ```java
    ClientConfiguration.builder()
        .withClientConfigurer(ElasticsearchClients.ElasticsearchRestClientConfigurationCallback.from(restClientBuilder -> {
            // configure the Elasticsearch RestClient
            return restClientBuilder;
        }))
        .build();
   ```
2. Configuration of the HttpAsyncClient used by the low level Elasticsearch RestClient
   此回调提供`org.apache.http.impl.nio.client.HttpAsyncClientBuilder`来配置`RestClient`使用的`HttpCLient`。
   ```java
    ClientConfiguration.builder()
        .withClientConfigurer(ElasticsearchClients.ElasticsearchHttpClientConfigurationCallback.from(httpAsyncClientBuilder -> {
            // configure the HttpAsyncClient
            return httpAsyncClientBuilder;
        }))
        .build();
   ```
### Client Logging
为了查看发送到服务器或者从服务器的返回，传输层上的Request/Response日志级别需要调整，设置`tracer`包的日志级别为trace
```xml
<logger name="tracer" level="trace"/>
```
## Elasticsearch Object Mapping
SDE的对象映射指的的在领域实体的Java对象与ES中存储的JSON数据之间的互相映射。内部用来完成映射的类是`MappingElasticsearchConverter`。
### Meta Model Object Mapping
基于元模型的方式使用领域类型信息读写Elasticsearch。可以为特定领域类型映射注册`Converter`实例。
#### 映射注解
`MappingElasticsearchConverter`转换器使用元数据完成对象与doc之间的映射。元数据来自于注解的实体的属性。注解主要有:
- @Document: 应用在类的级别，表示这个类药映射到索引，最重要的属性如下:
  - indexName: 索引名字，可以包含一个SpEL模板表达式比如`log-#{T(java.time.LocalDate).now().toString()}`
  - createIndex: 开关，是否在repository启动阶段创建索引，默认创建
- @Id: field级别，标记field为id
- @Transient、@ReadOnlyProperty、@WriteOnlyProperty: 控制哪些字段是只读的或者只写的,具体参考[Controlling which properties are written to and read from Elasticsearch](https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/object-mapping.html#elasticsearch.mapping.meta-model.annotations.read-write)
- `@PersistenceConstructor`: 标记一个构造函数作为实例化对象时使用，构造函数的参数通过检索到的文档中的同名字段的值传递。
- `@Field`: 应用于field上，定义了field的属性，大多数的属性对应了es Mapping中的定义，下面的列表是不完整的，参考注解的JavaDoc:
  - name: Field的名字，出现在es的doc中，如果没有设置，则是field的名字
  - type: field的类型，可以是*ext, Keyword, Long, Integer, Short, Byte, Double, Float, Half_Float, Scaled_Float, Date, Date_Nanos, Boolean, Binary, Integer_Range, Float_Range, Long_Range, Double_Range, Date_Range, Ip_Range, Object, Nested, Ip, TokenCount, Percolator, Flattened, Search_As_You_Type*这些类型，可以参考官方文档，如果没有指定，默认是`FieldType.Auto`类型，也就是说这个es中不会存在这个属性的映射，当第一次存储数据时动态添加映射
  - format: 一个或者多个内置的date格式化，参考下一节[Date format mapping](https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/object-mapping.html#elasticsearch.mapping.meta-model.annotations.date-formats)
  - pattern: 一个或者多个自定义date格式化，参考下一节[Date format mapping](https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/object-mapping.html#elasticsearch.mapping.meta-model.annotations.date-formats)
  - store: 是否在es中存储field原本的值，默认是false
  - analyzer、searchAnalyzer、normalizer: 指定自定义的分析器与normalizer
- `@GeoPoint`: 标记一个field是`geo_point`数据类型，如果field的类型是`GeoPoint`这个注解可以忽略
- `@ValueConverter`: 定义一个类来转换属性类型，与注册的Spring的`Converter`不同，它只转换注解的属性不是领域类型的全部属性

mapping元数据基础逻辑定义在spring-data-commons项目中。
#### 控制哪些属性从es中读写
注解定义了属性的值是否要写入es或者从es中读取。
- `@Transient`: 这个注解的属性不会被映射为es中的字段。它的值不会被发送到es，从es中读出的文档中，这个属性也没有值
- `@ReadOnlyProperty`: 不会被写入到es，但是可以从es读出的doc中填充值
- `@WriteOnlyProperty`: 与`@ReadOnlyProperty`相反
#### Date format mapping
`TemporalAccessor`的子类型或者`java.util.Date`类型要注解为es的`FieldType.Date`类型或者自定义一个转换器。下面的段落描述了`FieldType.Date`的用法。`@Field`注解有2个属性定义了date格式化。可以参考[Elasticsearch Built In Formats](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-date-format.html#built-in-date-formats)与[Elasticsearch Custom Date Formats](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-date-format.html#custom-date-formats)。`format`属性用来定义至少一个预定义格式。如果没有定义，默认值是`_date_optional_time`与`epoch_millis`，pattern属性可以用来添加额外的自定义format格式。如果你只想要使用自定义日期格式，必须设置`format={}`。下面的表格展示了不同的属性下生成的mapping
|annotation|format string in elasticsearch mapping|
|:---|:---|
|`@Field(type=FieldType.Date)`|date_optional_time||epoch_millis|
|`@Field(type=FieldType.Date, format=DateFormat.basic_date)`|basic_date|
|`@Field(type=FieldType.Date, format={DateFormat.basic_date, DateFormat.basic_time})`|basic_date||basic_time|
|`@Field(type=FieldType.Date, pattern="dd.MM.uuuu")`|date_optional_time||epoch_millis||dd.MM.uuuu|
|`@Field(type=FieldType.Date, format={}, pattern="dd.MM.uuuu")`|dd.MM.uuuu|

如果你正在使用一个自定义的日期格式，你应该使用uuuu而不是yyyy来表示年，具体参考[change in Elasticsearch 7](https://www.elastic.co/guide/en/elasticsearch/reference/current/migrate-to-java-time.html#java-time-migration-incompatible-date-formats)
#### Range types
但一个field被定义为以下类型时`Integer_Range, Float_Range, Long_Range, Double_Range, Date_Range, Ip_Range`field必须是能够映射到es的range类型的一种类，比如:
```java
class SomePersonData {

    @Field(type = FieldType.Integer_Range)
    private ValidAge validAge;

    // getter and setter
}

class ValidAge {
    @Field(name="gte")
    private Integer from;

    @Field(name="lte")
    private Integer to;

    // getter and setter
}
```
SDE提供了`Range<T>`类
```java
class SomePersonData {

    @Field(type = FieldType.Integer_Range)
    private Range<Integer> validAge;

    // getter and setter
}
```
支持的参数类型有`Integer`, `Long`, `Float`, `Double`, `Date`与实现`TemporalAccessor`接口的类
#### Mapped field names
字段名可以是类的属性名或者`@Field`中指定的名字，或者也可以定义自定义的命名策略`FieldNamingStrategy`，如果es客户端配置为`SnakeCaseFieldNamingStrategy`策略，命名会被映射为下划线风格。`@Field`中指定的名字具有最高优先级。
#### Non-field-backed properties
通常实体中的属性就是es中映射的字段，在有一些场景下，一个属性值是计算出来的并且应该store到es。这种场景下`@Field`可以放到Getter方法上，方法也必须使用注解`@AccessType(AccessType.Type.PROPERTY)`，第三个需要的注解是`@WriteOnlyProperty`，例子如下:
```java
@Field(type = Keyword)
@WriteOnlyProperty
@AccessType(AccessType.Type.PROPERTY)
public String getProperty() {
	return "some value that is calculated here";
}
```
#### Other property annotations
- `@IndexedIndexName`: 可以在实体的`String`属性上设置此注解。该属性不会写入映射，也不会存储在Elasticsearch中，也不会从 Elasticsearch文档中读取其值。持久保存实体后，例如调用`ElasticsearchOperations.save(T entity)`，从该调用返回的实体将包含索引的名称。当索引名称由bean动态设置或写入写入别名时，这非常有用。将一些值放入此类属性中不会设置存储实体要存储的索引！

### Mapping Rules
映射使用发送到服务器的文档中嵌入的类型提示来允许通用类型映射。这些类型提示在文档中表示为`_class`属性，并为每个聚合根编写。
```
public class Person {              
  @Id String id;
  String firstname;
  String lastname;
}

Copied!
{
  "_class" : "com.example.Person", // 默认情况下，领域类型的class name就是类型暗示
  "id" : "cb7bef",
  "firstname" : "Sarah",
  "lastname" : "Connor"
}
```
使用`@TypeAlias`来自定义类型暗示。内嵌对象没有类型暗示，除非属性类型是`Object`。可以关系写类型暗示的功能，特别是使用的索引早就存在的情况下，里面可能没有类型映射并且映射类型设置为严格，此时写入类型暗示将会报错因为field不能动态的添加。类型暗示可以全局关闭，只需要在继承`AbstractElasticsearchConfiguration`的配置类中覆盖方法`writeTypeHints()`，可以关闭单一索引的类型暗示
```java
@Document(indexName = "index", writeTypeHint = WriteTypeHint.FALSE)
```
我们强烈建议不要禁用类型提示。仅在必要时才禁用。禁用类型提示可能会导致在多态数据的情况下无法从Elasticsearch正确检索文档，或者文档检索可能完全失败。

地理空间类型`Point&GeoPoint`会被转换为lat/lon对
```java
public class Address {
  String city, street;
  Point location;
}
{
  "city" : "Los Angeles",
  "street" : "2800 East Observatory Road",
  "location" : { "lat" : 34.118347, "lon" : -118.3026284 }
}
```
SDE通过提供`GeoJson`接口来支持几何徒行并且支持不同几何图形实现
```java
public class Address {

  String city, street;
  GeoJsonPoint location;
}
{
  "city": "Los Angeles",
  "street": "2800 East Observatory Road",
  "location": {
    "type": "Point",
    "coordinates": [-118.3026284, 34.118347]
  }
}
```
下面是`GeoJson`接口类型的实现
- `GeoJsonPoint`
- `GeoJsonMultiPoint`
- `GeoJsonLineString`
- `GeoJsonMultiLineString`
- `GeoJsonPolygon`
- `GeoJsonMultiPolygon`
- `GeoJsonGeometryCollection`

集合中的值都是相同的mapping规则
```java
public class Person {
  List<Person> friends;
}
{
  "friends" : [ { "firstname" : "Kyle", "lastname" : "Reese" } ]
}
```
对于Maps内的值，在类型提示和自定义转换方面应用与聚合根相同的映射规则。然而，Map键需要一个字符串才能由Elasticsearch处理。
```java
public class Person {

  // ...

  Map<String, Address> knownLocations;

}
{
  "knownLocations" : {
    "arrivedAt" : {
       "city" : "Los Angeles",
       "street" : "2800 East Observatory Road",
       "location" : { "lat" : 34.118347, "lon" : -118.3026284 }
     }
  }
}
```
### Custom Conversions
`ElasticsearchCustomConversions`允许注册特定类型的mapping规则。
```java
@Configuration
public class Config extends ElasticsearchConfiguration  {

	@NonNull
	@Override
	public ClientConfiguration clientConfiguration() {
		return ClientConfiguration.builder() //
				.connectedTo("localhost:9200") //
				.build();
	}

  @Bean
  @Override
  public ElasticsearchCustomConversions elasticsearchCustomConversions() {
    return new ElasticsearchCustomConversions(
      Arrays.asList(new AddressToMap(), new MapToAddress()));   // 注册转换器实现    
  }

  @WritingConverter                   // 用来把DomianType写到es时的转换器                              
  static class AddressToMap implements Converter<Address, Map<String, Object>> {

    @Override
    public Map<String, Object> convert(Address source) {

      LinkedHashMap<String, Object> target = new LinkedHashMap<>();
      target.put("ciudad", source.getCity());
      // ...

      return target;
    }
  }

  @ReadingConverter            // 从es中读取结果时的转换器                                     
  static class MapToAddress implements Converter<Map<String, Object>, Address> {

    @Override
    public Address convert(Map<String, Object> source) {

      // ...
      return address;
    }
  }
}
{
  "ciudad" : "Los Angeles",
  "calle" : "2800 East Observatory Road",
  "localidad" : { "lat" : 34.118347, "lon" : -118.3026284 }
}
```

## Elasticsearch Operations
SDE使用几个接口定义了索引上的操作。
- IndexOperations，定义了索引级别的行为，比如创建/删除索引;
- DocumentOperations，定义了基于id的存储、更新、检索文档的行为；
- SearchOperations，定义了查询搜索文档的行为;
- ElasticsearchOperations，将DocumentOperations与SearchOperations接口行为组合起来。

这些接口就类似ES API的结构分类。接口的实现提供:
- 索引管理功能;
- mapping读写功能
- 查询/criteria API
- 资源管理/异常处理

`IndexOperations`接口可以通过ElasticsearchOperations获取，比如`operations.indexOps(clazz)`，通过`IndexOperations`可以创建索引、设置mapping、存储模板或者设置别名等，索引的详细信息可以通过`@Setting`注解设置。参考[index setting](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearc.misc.index.settings)获得更多的信息。这些操作都不是自动操作的。需要用户手动处理。自动操作需要使用SDE的Repository，可以参考[Automatic creation of indices with the corresponding mapping](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.repositories.autocreation)。
### 例子
下面的例子展示了如何在Spring REST Controller中使用一个注入的ElasticsearchOperations对象。例子假设`Person`类具有注解`@Documents`，`@Id`等，可以参考[Mapping Annotation Overview](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.mapping.meta-model.annotations)
```java
@RestController
@RequestMapping("/")
public class TestController {

  private  ElasticsearchOperations elasticsearchOperations;

  public TestController(ElasticsearchOperations elasticsearchOperations) { // 构造器中注入
    this.elasticsearchOperations = elasticsearchOperations;
  }

  @PostMapping("/person")
  public String save(@RequestBody Person person) { // 存储文档，id是从返回的实体中读取的，因为原始对象中可能是空的，id是由es生成的                        
    Person savedEntity = elasticsearchOperations.save(person);
    return savedEntity.getId();
  }

  @GetMapping("/person/{id}")
  public Person findById(@PathVariable("id")  Long id) {//通过id检索文档                   
    Person person = elasticsearchOperations.get(id.toString(), Person.class);
    return person;
  }
}
```
### Search Result Types
当文档通过`DocumentOperations`接口的方法检索时，只会返回发现的文档。当通过`SearchOperations`接口的方法搜索时，每个实体会返回一些额外的信息，比如每个实体的score与sortValues。为了返回这些信息，每个实体都会wrapped到一个`SearchHit`对象中，这个对象包含了实体相关的额外信息。这些`SearchHit`对象自身在一个`SearchHits`对象中返回，这个对象包含了这个搜索相关的额外的信息，比如maxScore或者请求的聚合信息。下面时涉及到的类与接口
- `SearchHit<T>`包含的信息如下:
  - id
  - score
  - Sort Values
  - Highlight fields
  - inner hists，一个内嵌的SearchHits对象
  - 检索的实体类型T
- `SearchHits<T>`包含的信息如下:
  - Number of total hits
  - Total hits relation
  - Maximum score
  - A list of SearchHit<T> objects
  - Returned aggregations
  - Returned suggest results
- `SearchPage<T>`是一个Spring Data Page的实现，内部包含一个`SearchHits<T>`，可以通过repository方法用来分页访问
- `SearchScrollHits<T>`是由底层的滚动API返回的，它在`SearchHits<T>`的基础上额外增加了滚动id。
- `SearchHitsIterator<T>`是`SearchOperations`接口中的流式方法返回的迭代器。
- `ReactiveSearchHits`: ReactiveSearchOperations has methods returning a Mono<ReactiveSearchHits<T>>, this contains the same information as a SearchHits<T> object, but will provide the contained SearchHit<T> objects as a Flux<SearchHit<T>> and not as a list.
### Queries
`SearchOperations`与`ReactiveSearchOperations`接口中定义的几乎所有的方法都使用`Query`参数，这个参数定义了要执行的搜索查询。它是一个接口，SDE提供了3种实现:
#### CriteriaQuery
`CriteriaQuery`查询允许在你不需要了解ES查询语法的情况创建搜索查询。通过链式或者组合式的方式创建Criteria对象查询，这个对象指定了要搜索的文档必须满足的断言。组合断言的时候，AND会转换为ES的must查询，OR会转化为ES中的should查询。`Criteria`以及其用法可以通过下面的例子解释:
```java
Criteria criteria = new Criteria("price").is(42.0);
Query query = new CriteriaQuery(criteria);
```
条件可以组成链，这个链会转换为一个逻辑AND
```java
Criteria criteria = new Criteria("price").greaterThan(42.0).lessThan(34.0);
Query query = new CriteriaQuery(criteria);
```
当链式组合`Criteria`的时候，默认使用AND逻辑
```java
Criteria criteria = new Criteria("lastname").is("Miller")// 第一个断言
  .and("firstname").is("James") // and()创建了一个新的Criteria并把它链接到第一个                          
Query query = new CriteriaQuery(criteria);
```
如果想要创建nested查询，你需要使用子查询。假设需要查询lastname=Miller，并且firstname=jack或者John的所有人。
```java
Criteria miller = new Criteria("lastName").is("Miller") // 为last name创建第一个Criteria 
  .subCriteria(    // 使用AND连接一个subCriteria                                     
    new Criteria().or("firstName").is("John") //sub Criteria是一个or表达式           
      .or("firstName").is("Jack")                        
  );
Query query = new CriteriaQuery(criteria);
```
请参考`Criteria`类的API文档获得更多的操作信息。
#### StringQuery
这个类使用一个JSON字符串作为ES查询。下面的代码展示了一个搜索firstname=Jack的人的查询。
```java
Query query = new StringQuery("{ \"match\": { \"firstname\": { \"query\": \"Jack\" } } } ");
SearchHits<Person> searchHits = operations.search(query, Person.class);
```
如果你之前已经有了es查询，那么使用StringQuery是合适的。
#### NativeQuery
`NativeQuery`是使用复杂查询时候该使用的，或者是使用`Criteria`API无法表达的时候应该使用的。比如，当构建查询或者使用聚合查询的时候，它允许使用来自官方包的所有的`co.elastic.clients.elasticsearch._types.query_dsl.Query`实现，因此命名为native。下面的代码展示了如何通过一个给定的firstname搜索人并且对于发现的人，做一个terms聚合操作，计算lastnames的出现次数。
```java
Query query = NativeQuery.builder()
	.withAggregation("lastNames", Aggregation.of(a -> a
		.terms(ta -> ta.field("last-name").size(10))))
	.withQuery(q -> q
		.match(m -> m
			.field("firstName")
			.query(firstName)
		)
	)
	.withPageable(pageable)
	.build();

SearchHits<Person> searchHits = operations.search(query, Person.class);
```
这是query接口的特殊实现。
#### SearchTemplateQuery
这是`Query`接口的特殊实现，与一个保存的search template组合使用，可以参考[Search Template support](https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/misc.html#elasticsearch.misc.searchtemplates)获取详细的信息。
## Reactive Elasticsearch Operations
`ReactiveElasticsearchOperations`是一个网关，通过`ReactiveElasticsearchClient`执行各种high level命令。`ReactiveElasticsearchTemplate`是`ReactiveElasticsearchOperations`的默认实现。使用`ReactiveElasticsearchOperations`需要知晓底层实际使用的客户端。请参考[Reactive Rest Client](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.clients.reactiverestclient)获取更多详细的信息。`ReactiveElasticsearchOperations`让你可以存储、find与删除你的领域对象，并且可以把领域对象映射到ES中的文档。下面是一个例子:
```java
@Document(indexName = "marvel")
public class Person {

  private @Id String id;
  private String name;
  private int age;
  // Getter/Setter omitted...
}
ReactiveElasticsearchOperations operations;
operations.save(new Person("Bruce Banner", 42))// 插入一个person文档到marvel索引中，id是由es服务端生成，并放到返回的对象中                    
  .doOnNext(System.out::println)
  .flatMap(person -> operations.get(person.id, Person.class))//在marvel索引中通过id匹配查询Person      
  .doOnNext(System.out::println)
  .flatMap(person -> operations.delete(person))// 通过id删除Person                    
  .doOnNext(System.out::println)
  .flatMap(id -> operations.count(Person.class)) //计算文档总数                  
  .doOnNext(System.out::println)
  .subscribe();                                                    
```
上面在控制台输出如下的信息:
> Person(id=QjWCWWcBXiLAnp77ksfR, name=Bruce Banner, age=42)
> Person(id=QjWCWWcBXiLAnp77ksfR, name=Bruce Banner, age=42)
> QjWCWWcBXiLAnp77ksfR
> 0
## Entity Callbacks
Spring Data基础组件提供了在特定的方法调用发生前/后修改实体的钩子。这些被称为`EntityCallback`的东西提供了方便的回调风格的方式来检查或者修改实体。一个`EntityCallbacl`就类似一个一个特定的`ApplicationListener`，一些Spring Data模块也会发布存储相关的事件(比如`BeforeSaveEvent`)，事件处理器可以修改给定的实体。在一些场景下，比如数据是不可修改的类型，这些事件会发生问题。同时，事件发布依赖`ApplicationEventMulticaster`。如果配置了一个异步的`TaskExecutor`，可能会导致无法预料的后果，因为事件处理在另外一个线程中。实体回调是通过API类型区分的。也就是说同步的API只会识别同步的实体回调，响应式的API只会识别响应式的实体回调。实体回调API是在Spring Data Commons 2.2开始引入的。修改实体推荐这种方式。实体相关的
### 实现实体回调
`EntityCallback`与他的泛型类型参数所表示的领域类型直接相关。每一个Spring Data模块都预定义了一些`EntityCallback`接口涵盖实体的所有生命周期
```java
@FunctionalInterface
public interface BeforeSaveCallback<T> extends EntityCallback<T> {

	/**
	 * Entity callback method invoked before a domain object is saved.
	 * Can return either the same or a modified instance.
	 *
	 * @return the domain object to be persisted.
	 */
	// BeforeSaveCallback方法在实体被保存前调用，返回一个可能被修改的对象
	T onBeforeSave(T entity,// 保存前的实体
		String collection);// store相关的参数
}
```
```java
@FunctionalInterface
public interface ReactiveBeforeSaveCallback<T> extends EntityCallback<T> {

	/**
	 * Entity callback method invoked on subscription, before a domain object is saved.
	 * The returned Publisher can emit either the same or a modified instance.
	 *
	 * @return Publisher emitting the domain object to be persisted.
	 */
	// subscription上调用，在实体被保存前，发出一个可能修改的对象实例
	Publisher<T> onBeforeSave(T entity,
		String collection);
}
```
可选的实体回调参数由实现Spring Data的模块所定义，并从`EntityCallback.callback()`的调用站点推断。实现满足你需求的接口，比如下面的例子:
```java
class DefaultingEntityCallback implements BeforeSaveCallback<Person>, Ordered {

	@Override
	public Object onBeforeSave(Person entity, String collection) {//

		if(collection == "user") {
		    return // ...
		}

		return // ...
	}

	@Override
	public int getOrder() {// 实体回调的顺序，
		return 100;
	}
}
```
### Registering Entity Callbacks
`EntityCallback`beans需要注册到`ApplicationContext`中，然后就会被自动应用。大多数的API都实现了`ApplicationContextAware`接口因此可以访问`ApplicationContext`。下面的例子是注册的:
```java
@Order(1)//BeforeSaveCallback从`@Order`定义顺序
@Component
class First implements BeforeSaveCallback<Person> {

	@Override
	public Person onBeforeSave(Person person) {
		return // ...
	}
}

@Component
class DefaultingEntityCallback implements BeforeSaveCallback<Person>,
                                                           Ordered {// 从Ordered接口获得顺序

	@Override
	public Object onBeforeSave(Person entity, String collection) {
		// ...
	}

	@Override
	public int getOrder() {
		return 100;
	}
}

@Configuration
public class EntityCallbackConfiguration {
    // beforeSaveback使用了一个lambda表达式，默认是无序的并且会被最后调用。lambda表达式实现的回调不会暴露类型信息因此使用不可分配的实体调用这些回调会影响回调吞吐量。 使用类或枚举来启用回调 bean 的类型过滤。
    @Bean
    BeforeSaveCallback<Person> unorderedLambdaReceiverCallback() {
        return (BeforeSaveCallback<Person>) it -> // ...
    }
}

@Component
class UserCallbacks implements BeforeConvertCallback<User>,//在一个实现类中实现多个实体回调接口
                                        BeforeSaveCallback<User> {

	@Override
	public Person onBeforeConvert(User user) {
		return // ...
	}

	@Override
	public Person onBeforeSave(User user) {
		return // ...
	}
}
```
### Store specific EntityCallbacks
Spring Data Elasticsearch使用`EntityCallback`API来完成用户支持，支持的实体回调如下表
|Callback|Method|Description|Order|
|:---|:---|:---|:---|
|Reactive/BeforeConvertCallback|onBeforeConvert(T entity, IndexCoordinates index)|在一个领域对象被转换为一个`org.springframework.data.elasticsearch.core.document.Document`前调用|Ordered.LOWEST_PRECEDENCE|
|Reactive/AfterLoadCallback|onAfterLoad(Document document, Class<T> type, IndexCoordinates indexCoordinates)|es中的结果读取到`org.springframework.data.elasticsearch.core.document.Document`之后调用|Ordered.LOWEST_PRECEDENCE|
|Reactive/AfterConvertCallback|onAfterConvert(T entity, Document document, IndexCoordinates indexCoordinates)|`org.springframework.data.elasticsearch.core.document.Document`被转换为领域对象后调用|Ordered.LOWEST_PRECEDENCE|
|Reactive/AuditingEntityCallback|onBeforeConvert(Object entity, IndexCoordinates index)||100|
|Reactive/AfterSaveCallback|T onAfterSave(T entity, IndexCoordinates index)|一个领域对象被保存后调用|Ordered.LOWEST_PRECEDENCE|
## Elasticsearch Auditing
为了判断一个实体对象是否是新的，实体需要实现`Persistable<ID>`接口:
```java
package org.springframework.data.domain;
public interface Persistable<ID> {
    @Nullable
    ID getId();

    boolean isNew();
}
```
Id的存在并不能决定一个实体是否是新的，需要额外的信息，一种方式是使用创建实体时的用户信息来辅助决策，比如:
```java
@Document(indexName = "person")
public class Person implements Persistable<Long> {
    @Id private Long id;
    private String lastName;
    private String firstName;
    @CreatedDate
    @Field(type = FieldType.Date, format = DateFormat.basic_date_time)
    private Instant createdDate;
    @CreatedBy
    private String createdBy
    @Field(type = FieldType.Date, format = DateFormat.basic_date_time)
    @LastModifiedDate
    private Instant lastModifiedDate;
    @LastModifiedBy
    private String lastModifiedBy;

    public Long getId() {
        return id;
    }

    @Override
    public boolean isNew() {
        return id == null || (createdDate == null && createdBy == null);
    }
}
```
用户相关信息可以通过`AuditorAware`与`ReactiveAuditorAware`接口提供，在一个configuration类上注解`@EnableElasticsearchAuditing`来开启用户信息功能
```java
@Configuration
@EnableElasticsearchRepositories
@EnableElasticsearchAuditing
class MyConfiguration {
   // configuration code
}
```
```java
@Configuration
@EnableReactiveElasticsearchRepositories
@EnableReactiveElasticsearchAuditing
class MyConfiguration {
   // configuration code
}
```
如果应用中包含多个为不同领域类型准备的`AuditorAware`，你必须提供bean的名字到`@EnableElasticsearchAuditing`注解的`auditorAwareRef`参数上。
## Join-Type实现
SDE支持ES的join数据类型。对于一个使用父子关系的实体，必须有个类型`JoinField`的属性假设`Statement`实体，可能是一个question、answer、comment或者一个vote。
```java
@Document(indexName = "statements")
@Routing("routing")//这是一个路由信息
public class Statement {
    @Id
    private String id;

    @Field(type = FieldType.Text)
    private String text;

    @Field(type = FieldType.Keyword)
    private String routing;

    @JoinTypeRelations(
        relations =
            {
                @JoinTypeRelation(parent = "question", children = {"answer", "comment"}),
                @JoinTypeRelation(parent = "answer", children = "vote")
            }
    )
    private JoinField<String> relation;//一个question可能有answer或者comments，一个answer可能有votes，JoinField属性用于将关系的名称（问题、答案、评论或投票）与父ID组合起来。泛型类型必须与@Id注解的属性相同。

    private Statement() {
    }

    public static StatementBuilder builder() {
        return new StatementBuilder();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getRouting() {
        return routing;
    }

    public void setRouting(Routing routing) {
        this.routing = routing;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public JoinField<String> getRelation() {
        return relation;
    }

    public void setRelation(JoinField<String> relation) {
        this.relation = relation;
    }

    public static final class StatementBuilder {
        private String id;
        private String text;
        private String routing;
        private JoinField<String> relation;

        private StatementBuilder() {
        }

        public StatementBuilder withId(String id) {
            this.id = id;
            return this;
        }

        public StatementBuilder withRouting(String routing) {
            this.routing = routing;
            return this;
        }

        public StatementBuilder withText(String text) {
            this.text = text;
            return this;
        }

        public StatementBuilder withRelation(JoinField<String> relation) {
            this.relation = relation;
            return this;
        }

        public Statement build() {
            Statement statement = new Statement();
            statement.setId(id);
            statement.setRouting(routing);
            statement.setText(text);
            statement.setRelation(relation);
            return statement;
        }
    }
}
```
产生的mapping如下：
```json
{
  "statements": {
    "mappings": {
      "properties": {
        "_class": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "routing": {
          "type": "keyword"
        },
        "relation": {
          "type": "join",
          "eager_global_ordinals": true,
          "relations": {
            "question": [
              "answer",
              "comment"
            ],
            "answer": "vote"
          }
        },
        "text": {
          "type": "text"
        }
      }
    }
  }
}
```
下面是增删改查的代码:
```java
void init() {
    repository.deleteAll();

    Statement savedWeather = repository.save(
        Statement.builder()
            .withText("How is the weather?")
            .withRelation(new JoinField<>("question"))// 创建一个question
            .build());

    Statement sunnyAnswer = repository.save(
        Statement.builder()
            .withText("sunny")
            .withRelation(new JoinField<>("answer", savedWeather.getId()))// 第一个answer
            .build());

    repository.save(
        Statement.builder()
            .withText("rainy")
            .withRelation(new JoinField<>("answer", savedWeather.getId()))//第二个answer
            .build());

    repository.save(
        Statement.builder()
            .withText("I don't like the rain")
            .withRelation(new JoinField<>("comment", savedWeather.getId()))//comment
            .build());

    repository.save(
        Statement.builder()
            .withText("+1 for the sun")
            ,withRouting(savedWeather.getId())
            .withRelation(new JoinField<>("vote", sunnyAnswer.getId()))
            .build());
}
```
必须使用native query来检索数据，目前还不支持标准`Repository`的方式，也可以使用[自定义Repository实现](https://docs.spring.io/spring-data/elasticsearch/reference/repositories/custom-implementations.html)的方式.
```java
SearchHits<Statement> hasVotes() {

	Query query = NativeQuery.builder()
		.withQuery(co.elastic.clients.elasticsearch._types.query_dsl.Query.of(qb -> qb
			.hasChild(hc -> hc
				.queryName("vote")
				.query(matchAllQueryAsQuery())
				.scoreMode(ChildScoreMode.None)
			)))
		.build();

	return operations.search(query, Statement.class);
}
```
## Routing values
当Elasticsearch存储文档到一个有多个分片的索引时，基于文档的id来决定要存储的分片，有时候需要让一组文档保存到统一个分片上，比如`join`数据类型的具有相关关系的文档。为此，Elasticsearch提供了定义路由的可能性，该路由是用来计算分片的值，而不是id。
SDE支持通过入的方式定义路由
### Routing on join-types
当使用join数据类型时，SDE将会自动使用`JoinField`属性的parent属性值作为路由值。当父子关系之后一级时，这是正确的。如果深度高于1级，路由需要另外一种机制来决定。
### Custom routing values
为了定义一个实体的自定义路由值。SDE提供了`@Routing`注解
```java
@Document(indexName = "statements")
@Routing("routing")// 定义routing作为路由值
public class Statement {
    @Id
    private String id;
    @Field(type = FieldType.Text)
    private String text;
    @JoinTypeRelations(
        relations =
            {
                @JoinTypeRelation(parent = "question", children = {"answer", "comment"}),
                @JoinTypeRelation(parent = "answer", children = "vote")
            }
    )
    private JoinField<String> relation;
    @Nullable
    @Field(type = FieldType.Keyword)
    private String routing;//routing属性
    // getter/setter...
}
```
如果注解的路由定义是一个普通的字符串而不是一个SpEL表达式，它被解释为实体的一个属性，也可以使用SpEL表达式
```java
@Document(indexName = "statements")
@Routing("@myBean.getRouting(#entity)")
public class Statement{
    // all the needed stuff
}
```
在这个场景下，用户需要提供一个叫做myBean的bean，它有一个方法`String getRouting(Object)`通过#entity的方式引用实体对象，如果普通属性与SpEL不足以表达路由需求。可以提供了一个实现了`RoutingResolver`接口的类，可以在`Elasticsearch`对象中设置。
```java
RoutingResolver resolver = ...;
ElasticsearchOperations customOperations= operations.withRouting(resolver);
```
`withRouting()`方法返回原来的`ElasticsearchOperations`实例的copy，当在一个实体上定义了路由并保存到es时，检索或者删除操作也必须指定相同的值。对于不使用实体的方法，比如`get(ID)`或者`delete(ID)`可以使用`ElasticsearchOperations.withRouting(RoutingResolver)`方法
```java
String id = "someId";
String routing = "theRoutingValue";

// get an entity
Statement s = operations
                .withRouting(RoutingResolver.just(routing))
                .get(id, Statement.class);

// delete an entity
operations.withRouting(RoutingResolver.just(routing)).delete(id);
```
## 其他的ES操作支持
这个章节介绍`Repository`不支持的es操作的额外支持，建议把这些操作添加为自定义实现[Custom Repository Implementations](https://docs.spring.io/spring-data/elasticsearch/reference/repositories/custom-implementations.html)。
### Index settings
当使用SDE创建索引时，不同的索引设置可以通过`@Setting`注解定义。可以使用的参数如下:
- `useServerConfiguration`: 不发送任何的setting参数，由ES服务器配置决定他们
- `settingPath`: 引用一个json文件，文件中定义了相关的setting，文件必须是相对于classpath的。
- `shards`: 分片数量，默认是1
- `replicas`: 副本数量，默认是1
- `refreshIntervall`: 默认是1s
- `indexStoreType`: 默认是`fs`

也可以定义索引排序
```java
@Document(indexName = "entities")
@Setting(
  sortFields = { "secondField", "firstField" },//
  sortModes = { Setting.SortMode.max, Setting.SortMode.min },//
  sortOrders = { Setting.SortOrder.desc, Setting.SortOrder.asc },
  sortMissingValues = { Setting.SortMissing._last, Setting.SortMissing._first })
class Entity {
    @Nullable
    @Id private String id;

    @Nullable
    @Field(name = "first_field", type = FieldType.Keyword)
    private String firstField;

    @Nullable @Field(name = "second_field", type = FieldType.Keyword)
    private String secondField;

    // getter and setter...
}
```
### Inde Mapping
当SDE通过`IndexOperations.createMapping()`方法创建索引mapping，它会使用到前面讲述的注解，尤其是`@Field`注解，此外，也可以向类添加一个`@Mapping`注解，注解有如下的属性:
  - `mappingPath`: JSON格式的classpath资源，如果不是空的，将会认为是mapping，二期不会处理其他的mapping情况
  - `enabled`: 当设置为false，this flag is written to the mapping and no further processing is done.
  - `dateDetection`与`numericDetection`:  set the corresponding properties in the mapping when not set to DEFAULT.
  - `dynamicDateFormats`: 不是空的，定义了自动检测的date数据的日期格式
  - `runtimeFieldsPath`: 一个JSON格式的classpath资源，包含了所有的运行时fields的定义，比如:
     ```json
      {
        "day_of_week": {
          "type": "keyword",
          "script": {
            "source": "emit(doc['@timestamp'].value.dayOfWeekEnum.getDisplayName(TextStyle.FULL, Locale.ROOT))"
          }
        }
      }
     ```
### Filter Builder
Filter Builder提高查询速度
```java
private ElasticsearchOperations operations;

IndexCoordinates index = IndexCoordinates.of("sample-index");

Query query = NativeQuery.builder()
	.withQuery(q -> q
		.matchAll(ma -> ma))
	.withFilter( q -> q
		.bool(b -> b
			.must(m -> m
				.term(t -> t
					.field("id")
					.value(documentId))
			)))
	.build();

SearchHits<SampleEntity> sampleEntities = operations.search(query, SampleEntity.class, index);
```
### Using Scroll For Big Result Set
ES提供滚动式API以便以分块的形式获取大数据集的所有数据。SDE使用滚动式API实现了`<T> SearchHitsIterator<T> SearchOperations.searchForStream(Query query, Class<T> clazz, IndexCoordinates index)`方法。
```java
IndexCoordinates index = IndexCoordinates.of("sample-index");
Query searchQuery = NativeQuery.builder()
    .withQuery(q -> q
        .matchAll(ma -> ma))
    .withFields("message")
    .withPageable(PageRequest.of(0, 10))
    .build();
SearchHitsIterator<SampleEntity> stream = elasticsearchOperations.searchForStream(searchQuery, SampleEntity.class,
index);
List<SampleEntity> sampleEntities = new ArrayList<>();
while (stream.hasNext()) {
  sampleEntities.add(stream.next());
}
stream.close();
```
`SearchOperations`API并没有提供访问scroll id的方法，如果需要访问scroll id，可以使用`AbstractElasticsearchTemplate`的几个方法，这个类是不同的`ElasticsearchOperations`实现的基类。
```java
@Autowired ElasticsearchOperations operations;

AbstractElasticsearchTemplate template = (AbstractElasticsearchTemplate)operations;

IndexCoordinates index = IndexCoordinates.of("sample-index");

Query query = NativeQuery.builder()
    .withQuery(q -> q
        .matchAll(ma -> ma))
    .withFields("message")
    .withPageable(PageRequest.of(0, 10))
    .build();

SearchScrollHits<SampleEntity> scroll = template.searchScrollStart(1000, query, SampleEntity.class, index);

String scrollId = scroll.getScrollId();
List<SampleEntity> sampleEntities = new ArrayList<>();
while (scroll.hasSearchHits()) {
  sampleEntities.addAll(scroll.getSearchHits());
  scrollId = scroll.getScrollId();
  scroll = template.searchScrollContinue(scrollId, 1000, SampleEntity.class);
}
template.searchScrollClear(scrollId);
```
想要`Repository`方法使用scrollAPI，返回类型必须定义为`Stream`。然后，该方法的实现将使用`ElasticsearchTemplate`中的scroll方法。
```java
interface SampleEntityRepository extends Repository<SampleEntity, String> {

    Stream<SampleEntity> findBy();

}
```
### Sort options
除了[Paging and Sorting](https://docs.spring.io/spring-data/elasticsearch/reference/repositories/query-methods-details.html#repositories.paging-and-sorting)中描述的默认sort选项以外，SDE提供了继承`org.springframework.data.domain.Sort.Order`的`org.springframework.data.elasticsearch.core.query.Order`它提供了额外的排序参数。`org.springframework.data.elasticsearch.core.query.GeoDistanceOrder`提供了基于地理距离的排序。
### Runtime Fields
ES从7.12版本开始支持运行时field，SDE通过2种方式支持:
1. Runtime field definitions in the index mappings: 这是第一种方式，也就是几那个定义添加到index的mapping中，mapping必须是JSON文件的方式提供
   ```json
    {
      "day_of_week": {
        "type": "keyword",
        "script": {
          "source": "emit(doc['@timestamp'].value.dayOfWeekEnum.getDisplayName(TextStyle.FULL, Locale.ROOT))"
        }
      }
    }
   ```
   JSON文件必须出现在classpath中，然后在`@Mapping`注解中设置
   ```java
    @Document(indexName = "runtime-fields")
    @Mapping(runtimeFieldsPath = "/runtime-fields.json")
    public class RuntimeFieldEntity {
      // properties, getter, setter,...
    }
   ```
2. Runtime fields definitions set on a Query: 这种方式是把runtime fields定义添加到一个搜索查询。
   ```java
    @Document(indexName = "some_index_name")
    public class SomethingToBuy {

      private @Id @Nullable String id;
      @Nullable @Field(type = FieldType.Text) private String description;
      @Nullable @Field(type = FieldType.Double) private Double price;

      // getter and setter
    }
   ```
   以下查询使用一个运行时field，该field通过在价格上添加19%来计算PriceWithTax值，并在搜索查询中使用该值来查找PriceWithTax高于或等于给定值的所有实体:
   ```java
    RuntimeField runtimeField = new RuntimeField("priceWithTax", "double", "emit(doc['price'].value * 1.19)");
    Query query = new CriteriaQuery(new Criteria("priceWithTax").greaterThanEqual(16.5));
    query.addRuntimeField(runtimeField);

    SearchHits<SomethingToBuy> searchHits = operations.search(query, SomethingToBuy.class);
   ```
   每种query接口的实现都可以这么使用。
### Point In Time(PIT)API
`ElasticsearchOperations`支持ES的时刻API，下面的代码片段展示了如何使用这个API:
```java
ElasticsearchOperations operations; // autowired
Duration tenSeconds = Duration.ofSeconds(10);

String pit = operations.openPointInTime(IndexCoordinates.of("person"), tenSeconds);//创建一个point in time，a keep-alive duration and retrieve its id 

// create query for the pit
Query query1 = new CriteriaQueryBuilder(Criteria.where("lastName").is("Smith"))
    .withPointInTime(new Query.PointInTime(pit, tenSeconds))//把id输入到查询中，来搜索下一个keep-alive的value
    .build();
SearchHits<Person> searchHits1 = operations.search(query1, Person.class);
// do something with the data

// create 2nd query for the pit, use the id returned in the previous result
Query query2 = new CriteriaQueryBuilder(Criteria.where("lastName").is("Miller"))
    .withPointInTime(
        new Query.PointInTime(searchHits1.getPointInTimeId(), tenSeconds))//对于下一个查询，使用从前面搜索中返回的id
    .build();
SearchHits<Person> searchHits2 = operations.search(query2, Person.class);
// do something with the data

operations.closePointInTime(searchHits2.getPointInTimeId());//结束时，使用最后返回的id关闭point in time
```
### Search Template support
支持搜索模板，为了使用搜索模板，首先需要创建一个存储脚本。`ElasticsearchOperations`接口继承了`ScriptOperations`接口，所以提供脚本相关的功能。下面的例子假设一个`Person`实体，一个搜索模板脚本如下:
```java
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.script.Script;

operations.putScript(                            (1)使用putScript()方法来存储搜索模板脚本
  Script.builder()
    .withId("person-firstname")                  (2)脚本的名字或者ID
    .withLanguage("mustache")                    (3)搜索模板中的脚本语言必须是mustache语言
    .withSource("""                              (4)脚本source
      {
        "query": {
          "bool": {
            "must": [
              {
                "match": {
                  "firstName": "{{firstName}}"   (5)脚本中的搜索参数
                }
              }
            ]
          }
        },
        "from": "{{from}}",                      (6)分页参数
        "size": "{{size}}"                       (7)分页参数
      }
      """)
    .build()
);
```
为了在一个搜索查询中使用搜索模板，SDE提供了`Query`的实现`SearchTemplateQuery`类型，在下面的代码中，我们会在自定义`Repository`实现中添加搜索模板的调用。首先定义接口
```java
interface PersonCustomRepository {
	SearchPage<Person> findByFirstNameWithSearchTemplate(String firstName, Pageable pageable);
}
```
```java
public class PersonCustomRepositoryImpl implements PersonCustomRepository {

  private final ElasticsearchOperations operations;

  public PersonCustomRepositoryImpl(ElasticsearchOperations operations) {
    this.operations = operations;
  }

  @Override
  public SearchPage<Person> findByFirstNameWithSearchTemplate(String firstName, Pageable pageable) {

    var query = SearchTemplateQuery.builder()// 创建一个SearchTemplateQuery
      .withId("person-firstname")//提供搜索模板的ID
      .withParams(
        Map.of(//参数通过Map传递
          "firstName", firstName,
          "from", pageable.getOffset(),
          "size", pageable.getPageSize()
          )
      )
      .build();

    SearchHits<Person> searchHits = operations.search(query, Person.class);//执行搜索

    return SearchHitSupport.searchPageFor(searchHits, pageable);
  }
}
```
### Nested sort
SDE支持内嵌对象的排序。下面的例子来自于`org.springframework.data.elasticsearch.core.query.sort.NestedSortIntegrationTests`类，展示了如何定义内嵌排序
```java
var filter = StringQuery.builder("""
	{ "term": {"movies.actors.sex": "m"} }
	""").build();
var order = new org.springframework.data.elasticsearch.core.query.Order(Sort.Direction.DESC,
	"movies.actors.yearOfBirth")
	.withNested(
		Nested.builder("movies")
			.withNested(
				Nested.builder("movies.actors")
					.withFilter(filter)
					.build())
			.build());

var query = Query.findAll().addSort(Sort.by(order));
```
关于过滤查询，不能在这里使用`CriteriaQuery`，因为这个查询将会被转换为ES的内嵌查询，内嵌查询不能工作在filter上下文中，所以，只有`StringQuery`与`NativeQuery`可以在这里使用，当使用他们之一时，比如上面的term query，elasticsearch field会被使用到。
## Scripted and runtime fields
SDE支持脚本field与runtime field。关于这2个field的定义，可以参考es的官方文档https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting.html与https://www.elastic.co/guide/en/elasticsearch/reference/8.9/runtime.html。使用SDE，你可以:
- scripted fields: 基于结果文档计算出来的字段并被添加到返回的文档中
- runtime fields: 基于已存储的文档计算出来的结果，可以用在查询或者返回的搜索结果中

下面的代码片段将会展示你可以做的事情
在这些例子中使用的实体是`Person`，这个实体拥有`birthDate`与`age`属性，其中`birthDate`是固定的，`age`依赖查询发起的时间是动态计算出来的。
```java
@Document(indexName = "persons")
public record Person(
        @Id
        @Nullable
        String id,
        @Field(type = Text)
        String lastName,
        @Field(type = Text)
        String firstName,
        @Field(type = Keyword)
        String gender,
        @Field(type = Date, format = DateFormat.basic_date)
        LocalDate birthDate,
        @Nullable
        @ScriptedField Integer age                   // age属性是计算出来的并且在搜索的结果中
  ) {
    public Person(String id,String lastName, String firstName, String gender, String birthDate) {
        this(id,                                     // 一个方便的构造函数用来设置测试数据
            lastName,
            firstName,
            LocalDate.parse(birthDate, DateTimeFormatter.ISO_LOCAL_DATE),
            gender,
            null);
    }
}
```
`age`属性使用`@ScriptedField`修饰，这个字段不会写入到mapping中而是根据搜索结果计算出来的。
例子中使用的`Repository`
```java
public interface PersonRepository extends ElasticsearchRepository<Person, String> {

    SearchHits<Person> findAllBy(ScriptedField scriptedField);

    SearchHits<Person> findByGenderAndAgeLessThanEqual(String gender, Integer age, RuntimeField runtimeField);
}
```
service类注入了一个`Repository`和一个`ElasticsearchOperations`实例，以显示填充和使用`age`属性的多种方法。我们将代码分成不同的部分以将解释
```java
@Service
public class PersonService {
    private final ElasticsearchOperations operations;
    private final PersonRepository repository;

    public PersonService(ElasticsearchOperations operations, SaRPersonRepository repository) {
        this.operations = operations;
        this.repository = repository;
    }

    public void save() { (1)
        List<Person> persons = List.of(
                new Person("1", "Smith", "Mary", "f", "1987-05-03"),
                new Person("2", "Smith", "Joshua", "m", "1982-11-17"),
                new Person("3", "Smith", "Joanna", "f", "2018-03-27"),
                new Person("4", "Smith", "Alex", "m", "2020-08-01"),
                new Person("5", "McNeill", "Fiona", "f", "1989-04-07"),
                new Person("6", "McNeill", "Michael", "m", "1984-10-20"),
                new Person("7", "McNeill", "Geraldine", "f", "2020-03-02"),
                new Person("8", "McNeill", "Patrick", "m", "2022-07-04"));

        repository.saveAll(persons);
    }
```
下面的代码片段将展示如何使用脚本字段来计算并返回人员的年龄。脚本字段只能向返回的数据添加一些内容，年龄不能在查询中使用（请参阅运行时字段）。
```java
    public SearchHits<Person> findAllWithAge() {

        var scriptedField = ScriptedField.of("age",// 定义一个ScriptedField计算一个人的年龄
                ScriptData.of(b -> b
                        .withType(ScriptType.INLINE)
                        .withScript("""
                                Instant currentDate = Instant.ofEpochMilli(new Date().getTime());
                                Instant startDate = doc['birth-date'].value.toInstant();
                                return (ChronoUnit.DAYS.between(startDate, currentDate) / 365);
                                """)));

        // version 1: use a direct query
        var query = new StringQuery("""
                { "match_all": {} }
                """);
        query.addScriptedField(scriptedField);// 当使用`Query`时，添加脚本字段到query中，
        query.addSourceFilter(FetchSourceFilter.of(b -> b.withIncludes("*")));// 当添加一个脚本字段到一个Query中时，需要一个额外的source filter从文档中检索出字段

        var result1 = operations.search(query, Person.class);//获取数据

        // version 2: use the repository
        var result2 = repository.findAllBy(scriptedField);// 如果使用Repository，需要做的就只是将脚本字段作为参数传输

        return result1;
    }
```
使用运行时字段时，可以在查询本身中使用计算值。在以下代码中，它用于运行针对给定性别和最大年龄的人员的查询：
```java
    public SearchHits<Person> findWithGenderAndMaxAge(String gender, Integer maxAge) {
       // 定义了运行时字段，计算一个人的给定年龄
        var runtimeField = new RuntimeField("age", "long", """ 
                                Instant currentDate = Instant.ofEpochMilli(new Date().getTime());
                                Instant startDate = doc['birth-date'].value.toInstant();
                                emit (ChronoUnit.DAYS.between(startDate, currentDate) / 365);
                """);

        // variant 1 : use a direct query
        var query = CriteriaQuery.builder(Criteria
                        .where("gender").is(gender)
                        .and("age").lessThanEqual(maxAge))
                .withRuntimeFields(List.of(runtimeField))//当使用Query时，添加运行时字段
                .withFields("age")// 当添加一个脚本字段到Query时，额外的字段参数拥有计算的返回值
                .withSourceFilter(FetchSourceFilter.of(b -> b.withIncludes("*")))//当添加一个脚本字段到Query，需要一个额外的source filter来检索doc source中的field
                .build();

        var result1 = operations.search(query, Person.class);// 得到过滤后的字段

        // variant 2: use the repository，当使用Repository时，唯一需要做的就是添加运行时field到方法参数上
        var result2 = repository.findByGenderAndAgeLessThanEqual(gender, maxAge, runtimeField);

        return result1;
    }
}
```
除了在query中定义运行时fields，也可以在索引上定义，需要设置`@Mapping`注解上的`runtimeFieldsPath`属性指定一个JSON文件的地址，json文件中包含运行时字段的定义信息。
# Elasticsearch Repositories
本章包含了ES Repository实现的细节。` Repository`抽象的目标时减少实现各种底层存储的数据访问层的模板代码。
## Core concepts
Spring Data仓库抽象的核心接口是`Repository`，它的泛型参数是领域类与领域类的主键。这个接口主要是一个标记接口，用户获取领域类类型与帮助发现子接口。`CrudRepository`与`ListCrudRepository`接口提供了更好的CRUD功能
```java
public interface CrudRepository<T, ID> extends Repository<T, ID> {

  <S extends T> S save(S entity);// 保存给定的实体

  Optional<T> findById(ID primaryKey); //根据ID查询实体

  Iterable<T> findAll(); //返回所有的实体

  long count();// 返回实体的数量

  void delete(T entity);//删除实体

  boolean existsById(ID primaryKey);// 表示一个给定ID的实体是否存在
}
```
我们也提供了特定持久化技术相关的抽象，比如`JpaRepository`或者`MongoRepository`，这些接口扩展自`CrudRepository`并且暴露了底层吹久化技术的特定能力。除了`CrudRepository`，还有`PagingAndSortingRepository`与`ListPagingAndSortingRepository`提供了分页的方法。
```java
public interface PagingAndSortingRepository<T, ID>  {
  Iterable<T> findAll(Sort sort);
  Page<T> findAll(Pageable pageable);
}
```
扩展接口只存在具体的存储模块中，为了访问`User`的第二页，你需要做的如下:
```java
PagingAndSortingRepository<User, Long> repository = // … get access to a bean
Page<User> users = repository.findAll(PageRequest.of(1, 20));
```
`ListPagingAndSortingRepository`提供了等价的方法，但是返回`List`而`PagingAndSortingRepository`返回`Iterable`。除了查询方法，count/delete的派生也是支持的。下面是一个派生的count/delete查询的例子:
```java
interface UserRepository extends CrudRepository<User, Long> {
  long countByLastname(String lastname);
}
interface UserRepository extends CrudRepository<User, Long> {
  long deleteByLastname(String lastname);
  List<User> removeByLastname(String lastname);
}
```
### 实体状态检测策略
检测一个entity是否是新的
- 检测`@Id`属性，这个是默认的策略，缺省情况下，Spring Data检测实体的ID属性，如果ID属性是null或者0(原子类型)，实体就被认为是新的，否则认为是旧的
- `@Version`属性检测，如果存在这样的属性，并且为null或者0(原子类型)，实体就是新的，如果是其他值，实体是旧的，如果没有这种属性，Spring Data降级到ID属性的检测策略
- 实现`Persistable`接口，如果实体实现了`Persistable`接口，判断实体是否是新的通过接口的`isNew()`方法
- 提供自定义的`EntityInformation`实现，你可以自定义`EntityInformation`抽象，创建一个模块特定仓库工厂的子类并覆写`getEntityInformation(…)`方法中，这样仓库的实现就会使用到自定义的`EntityInformation`，必须注册模块特定仓库工厂的子类的自定义实现为bean，这个很少需要用到。
## Defining Repository Interface
为了定义一个repository接口，你首先需要定义一个与领域类相关的`Repository`接口，接口必须扩展自`Repository`且类型参数是领域类与其ID的类型，如果你想要暴露CRUD方法，你需要继承`CrudRepository`或者它的子接口。
### Fine-tuning Repository Definition
有几种方式来定义你的`Repository`接口。典型的方式是扩展`CrudRepository`接口。可以让你的接口具有CRUD的能力。从3.0版本开始，`ListCrudRepository`支持多条数据返回`List`而不是`Iterable`。如果你的存储是响应式的，你可以使用`ReactiveCrudRepository`或者`RxJava3CrudRepository`这依赖于你正在使用的响应式框架。如果你正在使用Kotlin，你可以使用`CoroutineCrudRepository`利用了Kotlin的协程。持此以外，你还可以扩展`PagingAndSortingRepository`, `ReactiveSortingRepository`, `RxJava3SortingRepository`, `CoroutineSortingRepository`支持通过`Sort`或者`Pageable`来指定排序或者分页。注意，在3.0版本后，不同的排序`Repository`不在互相继承，所以如果你需要2个排序方法，就需要指定多个`Repository`。如果你不想要扩展`Spring Data`接口，你可以使用`@RepositoryDefinition`标注你的`Repository`接口，扩展CRUD `Repository`接口会暴露一组完整的操作实体对象的方法。 如果您希望选择一些方法来暴露，将要暴露的方法从CRUD仓库复制到你的域仓库中。这样做时，您可以更改方法的返回类型。如果可能的话，Spring Data将遵循返回类型。例如，对于返回多个实体的方法，您可以选择`Iterable<T>`、`List<T>`、`Collection<T>`或`VAVR`列表。如果你的应用中多个`Repository`具有一些相同的方法集合，你可以将这些相同的方法抽取到一个父接口中，这个接口必须被`@NoRepositoryBean`标注，因为这个接口是泛型的，没有具体的领域类，这个注解可以告诉Spring Data不要实例化这个仓库。下面的例子展示了选择性的暴露一些CRUD方法
```java
@NoRepositoryBean
interface MyBaseRepository<T, ID> extends Repository<T, ID> {

  Optional<T> findById(ID id);

  <S extends T> S save(S entity);
}

interface UserRepository extends MyBaseRepository<User, Long> {
  User findByEmailAddress(EmailAddress emailAddress);
}
```
在前面的例子中，我们定义了一个通用的base接口，暴露了`findById(...)`与`save(...)`接口，这些方法会被路由到Spring Data提供的对应你选择的store的基本仓库实现中。比如，如果你使用JPA，那么实现就是`SimpleJpaRepository`，因为他们与`CrudRepository`中的方法签名相同。因此，`UserRepository`现在可以保存用户、通过ID查找单个用户，并触发查询以通过电子邮件地址查找用户。中间的仓库接口要使用`@NoRepositoryBean`标注。
### Using Repositories with Multiple Spring Data Modules
在应用中只使用一个Spring Data模块是非常简单的。因为所有的仓库接口都是该模块的。有时候，应用需要使用多个Spring Data模块，在这样的场景中，仓库定义必须根据其对应的持久化技术做区分。当应用在classpath中检测到多个仓库工厂时，Spring Data会进入严格的仓库配置模式，严格配置模式会使用仓库接口与领域类的细节信息来决定绑定哪个Spring Data模块。
- 如果仓库定义扩展自模块相关的接口，它会绑定到这个模块
- 如果领域类使用了模块内的注解，也是绑定到这个模块，Spring Data也接受第三方的注解，比如JPA的`@Entity`或者模块自己的注解比如Spring Data MongoDb与Spring Data Elasticsearch的`@Document`

下面的例子展示了一个使用了模块相关接口的仓库
```java
interface MyRepository extends JpaRepository<User, Long> { }

@NoRepositoryBean
interface MyBaseRepository<T, ID> extends JpaRepository<T, ID> { … }

interface UserRepository extends MyBaseRepository<User, Long> { … }
```
下面的例子展示了一个使用通用接口的仓库
```java
interface AmbiguousRepository extends Repository<User, Long> { … }

@NoRepositoryBean
interface MyBaseRepository<T, ID> extends CrudRepository<T, ID> { … }

interface AmbiguousUserRepository extends MyBaseRepository<User, Long> { … }
```
下面的例子是领域类的例子
```java
interface PersonRepository extends Repository<Person, Long> { … }
@Entity
class Person { … }
interface UserRepository extends Repository<User, Long> { … }
@Document
class User { … }
```
下面是一个错误示例
```java
interface JpaPersonRepository extends Repository<Person, Long> { … }
interface MongoDBPersonRepository extends Repository<Person, Long> { … }
@Entity
@Document
class Person { … }
```
[Repository type details](https://docs.spring.io/spring-data/elasticsearch/reference/repositories/definition.html#repositories.multiple-modules.types)与[领域类注解](https://docs.spring.io/spring-data/elasticsearch/reference/repositories/definition.html#repositories.multiple-modules.annotations)是用来在严格模式下判断属于哪个Spring Data模块，在同一域类型上使用多个特定持久性技术的注解是可能的，并且可以跨多种持久性技术重用域类型。但是，Spring Data将无法再确定用于绑定存储库的唯一模块。最后一个判断的方法是限定扫描仓库的范围，默认情况下，注解驱动的配置使用Configuration类所在的package作为base package，基于XML的配置需要强制配置这个属性。下面是一个注解驱动的配置base packages的例子:
```java
@EnableJpaRepositories(basePackages = "com.acme.repositories.jpa")
@EnableMongoRepositories(basePackages = "com.acme.repositories.mongo")
class Configuration { … }
```
## Elasticsearch Repositories
这个小节包含了Elasticsearch仓库信息的细节。
```java
@Document(indexName="books")
class Book {
    @Id
    private String id;
    @Field(type = FieldType.text)
    private String name;
    @Field(type = FieldType.text)
    private String summary;
    @Field(type = FieldType.Integer)
    private Integer price;
	// getter/setter ...
}
```
### 自动创建具有相应mapping的索引
`@Document`注解由一个`createIndex`的参数。如果参数设置为true，Spring Data Elasticsearch将会在启动Repository支持的阶段检查`@Document`定义的索引是否存在。如果不存在，将会创建索引与从实体类注解衍生出来的mapping，索引的细节可以通过`@Setting`注解设置，参考[Index settings](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearc.misc.index.settings)获取更多的信息。
### Annotations for repository methods
#### `@Highlight`
仓库方法上的`@Highlight`注解定义了高亮部分应该包含返回实体的哪些字段，为了搜索书的名字或者summary并让搜到的数据高亮，可以使用下面的仓库方法:
```java
interface BookRepository extends Repository<Book, String> {
    @Highlight(fields = {
        @HighlightField(name = "name"),
        @HighlightField(name = "summary")
    })
    SearchHits<Book> findByNameOrSummary(String text, String summary);
}
```
如上面的例子，可以定义多个高亮的字段，`@Highlight`与`@HighlightField`注解可以使用`@HighlightParameters`定制化修改，参考可配置选项的javadocs。在搜索结果中，高亮数据可以通过`SearchHit`类检索到。
#### `@SourceFilters`
不想返回实体的所有属性只要一部分。ES提供了source过滤功能来减少药传输的数据量。当使用`ElasticsearchOperations`与`Query`接口使，只需要在`Query`实现上设置一个source filter就可以。当使用带有`@SourceFilters`注解的仓库方法时
```java
interface BookRepository extends Repository<Book, String> {
    @SourceFilters(includes = "name")
    SearchHits<Book> findByName(String text);
}
```
在这个例子中，返回的`Book`对象的中除了name外的所有属性都是null。
### Annotation based configuration
SDE支持使用注解激活
```java
@Configuration
@EnableElasticsearchRepositories(// EnableElasticsearchRepositories注解激活了仓库支持，如果没有配置base package，使用配置类所在的package
  basePackages = "org.springframework.data.elasticsearch.repositories"
  )
static class Config {

  @Bean //提供一个名叫elasticsearchTemplate类型为elasticsearchTemplate的bean
  public ElasticsearchOperations elasticsearchTemplate() {
      // ...
  }
}

class ProductService {

  private ProductRepository repository;//注入

  public ProductService(ProductRepository repository) {
    this.repository = repository;
  }

  public Page<Product> findAvailableBookByName(String name, Pageable pageable) {
    return repository.findByAvailableTrueAndNameStartingWith(name, pageable);
  }
}
```
### Spring Namespace
SDE模块包含一个自定义命名空间与相关元素来完成仓库bean的定义与初始化一个`ElasticsearchServer`。使用`repositories`元素来寻找Spring Data的仓库
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:elasticsearch="http://www.springframework.org/schema/data/elasticsearch"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       https://www.springframework.org/schema/beans/spring-beans-3.1.xsd
       http://www.springframework.org/schema/data/elasticsearch
       https://www.springframework.org/schema/data/elasticsearch/spring-elasticsearch-1.0.xsd">

  <elasticsearch:repositories base-package="com.acme.repositories" />
</beans>
```
使用`Transport Client`与`Rest Client`元素注册一个`ElasticsearchServer`的实例对象
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:elasticsearch="http://www.springframework.org/schema/data/elasticsearch"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       https://www.springframework.org/schema/beans/spring-beans-3.1.xsd
       http://www.springframework.org/schema/data/elasticsearch
       https://www.springframework.org/schema/data/elasticsearch/spring-elasticsearch-1.0.xsd">
  <elasticsearch:transport-client id="client" cluster-nodes="localhost:9300,someip:9300" />
</beans>
```
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:elasticsearch="http://www.springframework.org/schema/data/elasticsearch"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       https://www.springframework.org/schema/beans/spring-beans-3.1.xsd
       http://www.springframework.org/schema/data/elasticsearch
       https://www.springframework.org/schema/data/elasticsearch/spring-elasticsearch-1.0.xsd">

  <elasticsearch:transport-client id="client" cluster-nodes="localhost:9300,someip:9300" />

</beans>
```
## Reactive Elasticsearch Repositories
响应式Elasticsearch仓库支持基于前面的仓库支持，使用了[ Reactive Elasticsearch Operations](https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/reactive-template.html)提供的操作，底层是由[Reactive REST Client](https://docs.spring.io/spring-data/elasticsearch/reference/elasticsearch/clients.html#elasticsearch.clients.reactiverestclient)执行的。SDE响应式仓库支持使用[Project Reactor]作为响应式库。主要使用3个接口
- `ReactiveRepository`
- `ReactiveCrudRepository`
- `ReactiveSortingRepository`
### Usage
为了使用`Repository`访问存储在ES中的领域对象，只需要为它们创建接口，首先定义领域类
```java
public class Person {

  @Id
  private String id;//id属性必须是String的
  private String firstname;
  private String lastname;
  private Address address;
  // … getters and setters omitted
}
```
```java
interface ReactivePersonRepository extends ReactiveSortingRepository<Person, String> {
// 方法查询给定lastname的所有人
  Flux<Person> findByFirstname(String firstname);                                   
// 方法等待Publisher的输入来绑定firstname参数值
  Flux<Person> findByFirstname(Publisher<String> firstname);                        
// 匹配firstname的所有人
  Flux<Person> findByFirstnameOrderByLastname(String firstname);                    
// 指定排序规则
  Flux<Person> findByFirstname(String firstname, Sort sort);                        
// 使用Pageable来分页
  Flux<Person> findByFirstname(String firstname, Pageable page);                    
// 使用And/Or关键词来创建criteria
  Mono<Person> findByFirstnameAndLastname(String firstname, String lastname);       
// 返回第一个匹配的人
  Mono<Person> findFirstByLastname(String lastname);                                
// 使用`@Query`注解执行查询
  @Query("{ \"bool\" : { \"must\" : { \"term\" : { \"lastname\" : \"?0\" } } } }")
  Flux<Person> findByLastname(String lastname);                                     
// 匹配firstname的总数
  Mono<Long> countByFirstname(String firstname)                                     
// 判断firstname的人是否存在
  Mono<Boolean> existsByFirstname(String firstname)                                 
// 删除所有firstname的人
  Mono<Long> deleteByFirstname(String firstname)                                    
}
```
### Configuration
对于Java配置来说，使用`@EnableReactiveElasticsearchRepositories`注解来启用相关的支持。如果没有配置base package。SDE扫描被注解的`@Confiuration`类所在的package。下面是一个例子:
```java
@Configuration
@EnableReactiveElasticsearchRepositories
public class Config extends AbstractReactiveElasticsearchConfiguration {
  @Override
  public ReactiveElasticsearchClient reactiveElasticsearchClient() {
    return ReactiveRestClients.create(ClientConfiguration.localhost());
  }
}
```
因为前面的仓库继承了`ReactiveSortingRepository`，具有所有的CRUD操作与排序访问的支持。使用的例子如下:
```java
public class PersonRepositoryTests {
  @Autowired ReactivePersonRepository repository;
  @Test
  public void sortsElementsCorrectly() {
    Flux<Person> persons = repository.findAll(Sort.by(new Order(ASC, "lastname")));
    // ...
  }
}
```
## Creating Repository Instances
这一小节主要讲述如何为预定义的仓库接口创建实例与bean定义
### Java Configuration
使用`@EnableElasticsearchRepositories`注解来激活仓库支持。一个简单的例子如下:
```java
@Configuration
@EnableJpaRepositories("com.acme.repositories")
class ApplicationConfiguration {
  @Bean
  EntityManagerFactory entityManagerFactory() {
    // …
  }
}
```
前面的例子使用JPA相关的注解，你可以根据你实际使用的底层存储调整。
### XML Configuration
每一个Spring Data模块都包括`repositories`元素，你可以定义一个base package，Spring会为你扫描，如下所示:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans:beans xmlns:beans="http://www.springframework.org/schema/beans"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns="http://www.springframework.org/schema/data/jpa"
  xsi:schemaLocation="http://www.springframework.org/schema/beans
    https://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/data/jpa
    https://www.springframework.org/schema/data/jpa/spring-jpa.xsd">

  <jpa:repositories base-package="com.acme.repositories" />

</beans:beans>
```
在前面的例子中，Spring被命令扫描`com.acme.repositories`与它的子包下的继承`Repository`的接口，对于发现的每个接口，SDE底层一个持久化的`FactoryBean`来创建合适的代理，代理管理查询方法的调用。bean的名字来自于接口名，所以`UserRepository`接口将会注册为`userRepository`，base package允许使用通配符，所以你可以定义package的模式。
### Using Filters
缺省情况下，底层基础设施会选择继承了`Repository`的子接口并为它们创建实例对象。然而，你可能想要细粒度的控制为哪些接口生成对象，为了做到这些，在仓库声明里面使用filter元素，语法完全等价于Spring components filters里面的元素，详情参考Spring官方文档。下面的是一个例子:
```java
@Configuration
@EnableElasticsearchRepositories(basePackages = "com.acme.repositories",
    includeFilters = { @Filter(type = FilterType.REGEX, pattern = ".*SomeRepository") },
    excludeFilters = { @Filter(type = FilterType.REGEX, pattern = ".*SomeOtherRepository") })
class ApplicationConfiguration {

  @Bean
  EntityManagerFactory entityManagerFactory() {
    // …
  }
}
```
前面的例子包含所有以`SomeRepository`结尾的接口，排除所有以`SomeOtherRepository`结尾的接口。
### Standalone Usage
你可以在Spring IoC容器外使用仓库基础设置，比如，在CDI环境中，你仍然需要一些基础的Spring库，但是你可以自己编写代码来生成仓库实例对象，Spring Data模块提供了`RepositoryFactory`来支持生成仓库，如下所示:
```java
RepositoryFactorySupport factory = … // Instantiate factory here
UserRepository repository = factory.getRepository(UserRepository.class);
```
## Defining Query Methods
仓库代理有2种方法来从方法名衍生查询
- 直接从方法名衍生查询
- 使用自定义query

SDE由策略决定如何生成实际的查询。
### Query Lookup Strategies
SDE使用下面的策略来解析查询。在XML配置下，你可以使用`query-lookup-strategy`来配置策略。对与Java配置，你可以使用`@EnableElasticsearchRepositories`注解的`queryLookupStrategy`属性来配置策略。
- `CREATE`: 尝试从方法名构造一个查询，最通用的方式是从方法名移除一些常见的前缀并解析剩余的名字，你可以在[Query Creation](Query Creation)获得更多的信息
- `USE_DECLARED_QUERY`: 尝试寻找一个声明式的查询，如果没有找到则抛出异常。查询可以是某处的注解来声明或者其他的方式
- `CREATE_IF_NOT_FOUND`: 这是默认的策略，融合了前面2种策略，首先使用`USE_DECLARED_QUERY`策略，如果没有找到，使用`CREATE`策略。
### Query Creation
SDE的查询构建机制对于构建领域类上的有限制的查询是非常有用的。下面是一些例子:
```java
interface PersonRepository extends Repository<Person, Long> {

  List<Person> findByEmailAddressAndLastname(EmailAddress emailAddress, String lastname);

  // Enables the distinct flag for the query
  List<Person> findDistinctPeopleByLastnameOrFirstname(String lastname, String firstname);
  List<Person> findPeopleDistinctByLastnameOrFirstname(String lastname, String firstname);

  // Enabling ignoring case for an individual property
  List<Person> findByLastnameIgnoreCase(String lastname);
  // Enabling ignoring case for all suitable properties
  List<Person> findByLastnameAndFirstnameAllIgnoreCase(String lastname, String firstname);

  // Enabling static ORDER BY for a query
  List<Person> findByLastnameOrderByFirstnameAsc(String lastname);
  List<Person> findByLastnameOrderByFirstnameDesc(String lastname);
}
```
解析查询方法名把分成subject/predicate2部分，第一部分(find...By,exists...By)定义了查询的主题，第二个部分形成了predicate，引入从句(主语)就可以包含更多的表达式，除非使用了限制结果的关键字之一(例如Distinct来设置查询中的唯一标志，或者Top/First来限制查询结果数)，否则在find(或其他引入关键字)和By之间的任何文本都被视为描述性的。附录部分包含了全部的查询方法subject关键词与查询方法predicate关键词。解析方法的实际的结果依赖底层的存储，有一些需要注意的是:
- 表达式通常是属性遍历与可连接的运算符相结合。可以使用`AND`和`OR`组合属性表达式。支持更多属性表达式的运算符(如Between、LessThan、GreaterThan和Like)等。支持的运算符可能因数据存储而异，因此请参阅参考文档的相应部分。
- 方法解析器支持为单个属性(例如，findByLastnameIgnoreCase(…))或支持忽略大小写的类型的所有属性(通常是`String`对象，例如，findByLastnameAndFirstnameAllIgnoreCase(…))设置`IgnoreCase`标志。是否支持忽略大小写可能因底层存储而异，因此请参阅参考文档中的相关部分以了解特定存储的查询方法
- 可以通过将`OrderBy`子句附加到引用属性的查询方法并提供排序方向(`Asc`或`Desc`)来应用静态排序。要创建支持动态排序的查询方法，请参阅[Paging, Iterating Large Results, Sorting & Limiting](https://docs.spring.io/spring-data/elasticsearch/reference/repositories/query-methods-details.html#)
### Property Expressions
属性表达式只能引用管理实体的直接属性，在查询构建时，你要确保属性是管理的领域类的属性，然而，你也可以定义内嵌属性的查询，如下面的例子所示:
```java
List<Person> findByAddressZipCode(ZipCode zipCode);
```
假设一个人有一个`Address`对象，`Address`对象有`ZipCode`对象，在这种场景下，方法会遍历x.address.zipCode属性，解析算法首先将整个部分`AddressZipCode`解释为一个完整的属性，并在领域类中查找(首字母小写)，如果算法成功，就是用查找到的属性，如果没有，算法按照驼峰格式从右向左切分属性名，形成一个head与一个tail，并寻找相应的属性，上面的例子会切分成`AddressZip`与`Code`，如果算法找到head对应的属性，接下来寻找tail从head处递归解析，如果第一次切分没有匹配，算法向左转移切分点并继续解析。虽然这在大多数场景下都是OK的，算法仍有可能选错，假设`Person`类有一个`addressZip`属性，算法在第一次切分时就会选择到这个属性，然后因为没找到属性code而失败。为了解决这种混淆，你可以使用`_`分隔符，手动指定切分点，方法名如下所示
```java
List<Person> findByAddress_ZipCode(ZipCode zipCode);
```
因为我们将下划线认为是一个保留字符，所以我们强烈建议遵守Java的命名约定，也就是尽量不在属性名中使用下划线，而是使用驼峰命名方式。
### Repository Methods Returning Collections or Iterables
返回多个结果的查询方法可以使用标准Java的`Iterable`、`List`、`Set`等类型，除此以外，也支持返回Spring Data的`Streamable`以及Vavr库的集合类型。请参考附录，里面包含了所有可能的查询方法返回类型
#### Using Streamable as Query Method Return Type
使用`Streamable`作为`Iterable`或者其他集合类型的替代，它提供了方便的方法来访问一个`Stream`并可以直接使用`filter()`与`map()`等
```java
interface PersonRepository extends Repository<Person, Long> {
  Streamable<Person> findByFirstnameContaining(String firstname);
  Streamable<Person> findByLastnameContaining(String lastname);
}

Streamable<Person> result = repository.findByFirstnameContaining("av")
  .and(repository.findByLastnameContaining("ea"));
```
#### Returning Custom Streamable Wrapper Types
为集合类型提供了专门的包装类型，这是一种常用的模式，用于为返回多个元素的查询结果提供API。通常的方案是，调用返回类集合类型的仓库方法并手动创建包装器类型的实例来使用这些类型。可以避免这个额外的步骤，因为Spring Data允许您使用这些包装器类型直接作为查询方法返回类型，但是必须满足以下条件:
- 类型必须实现`Streamable`
- 类型要么公开构造器要么具有命名为`of(Streamable)`或者`valueOf(Streamable)`的静态工厂方法。下面是一个例子

```java
class Product {//一个Product的实体类
  MonetaryAmount getPrice() { … }
}

@RequiredArgsConstructor(staticName = "of")
class Products implements Streamable<Product> {//一个Streamable<Product>的包装器类型，可以使用`Products.of(...)`构造，使用Lombok注解常见的工厂方法，标准的构造函数也是Ok的

  private final Streamable<Product> streamable;

  public MonetaryAmount getTotal() {//包装器类型公开了额外的API，计算`Streamable<Product>`上新的值
    return streamable.stream()
      .map(Priced::getPrice)
      .reduce(Money.of(0), MonetaryAmount::add);
  }


  @Override
  public Iterator<Product> iterator() {//实现了`Streamable`接口，并委托到底层实际的实现
    return streamable.iterator();
  }
}

interface ProductRepository implements Repository<Product, Long> {
  Products findAllByDescriptionContaining(String text);//查询方法返回类型可以直接使用包装器类型，你不需要返回`Streamable<Product>`
}
```
#### Support for Vavr Collections
Vavr是一个专门用于函数式编程的Java库，它里面包含了很多的自定义集合类型，你可以作为方法的返回类型，如下表所示
|Vavr collection type|Used Vavr implementation type|Valid Java source types|
|:---|:---|:---|
|`io.vavr.collection.Seq`|`io.vavr.collection.Seq`|`java.util.Iterable`|
|`io.vavr.collection.Set`|`io.vavr.collection.LinkedHashSet`|`java.util.Iterable`|
|`io.vavr.collection.Map`|`io.vavr.collection.LinkedHashMap`|`java.util.Map`|

你可以使用上表中的第一列的类型或者子类型作为返回类型，第二列作为返回类型的实现类型，这是与java本身的集合类型相对应的。另外，你可以声明`Traversable`类型，等价于`Iterable`类型，我们会从实际的返回值推导出实现类，也就是实际返回值是`java.util.List`会被调整成Vavr的`List`或者`Seq`，`java.util.Set`会被调整成`LinkedHashSet`.
### Streaming Query Results
可以使用Java8的`Stream`作为返回类型，例子:
```java
@Query("select u from User u")
Stream<User> findAllByCustomQueryAndStream();
Stream<User> readAllByFirstnameNotNull();
@Query("select u from User u")
Stream<User> streamAllPaged(Pageable pageable);
```
`Stream`底层包含了一些底层存储的资源，因此使用完毕后一定要close，你可以使用`Stream`的`close()`来关闭或者使用try-with-resources的方式关闭，如下所示
```java
try (Stream<User> stream = repository.findAllByCustomQueryAndStream()) {
  stream.forEach(…);
}
```
### Asynchronous Query Results
查询可以异步执行，这意味着，方法调用会立即返回，实际查询发生在Spring的`TaskExecutor`的线程中，异步查询不同于reactive查询，下面的例子是异步查询
```java
@Async/
Future<User> findByFirstname(String firstname);

@Async
CompletableFuture<User> findOneByFirstname(String firstname);
```
### Paging, Iterating Large Results, Sorting & Limiting
SDE会识别特定的方法参数类型，比如`Pageable`、`Sort`、`Limit`来动态的处理分页、排序、limit。下面的例子展示了这些特性
```java
Page<User> findByLastname(String lastname, Pageable pageable);

Slice<User> findByLastname(String lastname, Pageable pageable);

List<User> findByLastname(String lastname, Sort sort);

List<User> findByLastname(String lastname, Sort sort, Limit limit);

List<User> findByLastname(String lastname, Pageable pageable);
```
API认为这些特定参数都是非null的，不要传null，如果不想分页或者排序神马的，传`Sort.unsorted()`, `Pageable.unpaged()`,`Limit.unlimited()`。分页查询会返回`Page`接口的结果，里面有所有的元素数以及一共多少页，这是通过count查询实现的，因为这可能会比较耗时，你可以返回`Slice`,`Slice`含有是否有下一个`Slice`的信息，当遍历大的结果集的时候可能比较有用。`Pageable`也支持排序而`Sort`只支持排序，支持返回List，此时不需要构造Page，也不需要执行count查询来得到`Page`中的必要的信息。特定的参数在查询方法中最好只使用一次，一些参数直接可能是互斥的，比如下面的例子
```java
findBy…​(Pageable page, Sort sort) //Pageable already defines Sort
findBy…​(Pageable page, Limit limit)// Pageable already defines a limit.
```
`Top`关键字用来限定返回的结果数，可以与`Pageable`一起使用，top定义结果的最大总数，而`Pageable`可能会减少此数量。
#### Which Method is Appropriate?
Spring Data抽象根据查询方法的返回类型提供的值的选择性列在下面的表格中。你可以根据此了解应该使用哪种返回类型
|Method|Amount of Data Fetched|Query Structure|Constraints|
|:---|:---|:---|:---|
|`List<T>`|所有的结果|单一查询|查询结果可能耗尽内存，拉取所有结果是非常耗时的|
|`Streamable<T>`|所有结果|单一查询|查询结果可能耗尽内存，拉取所有结果是非常耗时的|
|`Stream<T>`|分块的，一条接一条|单一查询使用游标|使用完毕后必须关闭，避免资源泄漏|
|`Flux<T>`|分块的，一条接一条|单一查询使用游标|必须支持响应式|
|`Slice<T>`|Pageable.getPageSize() + 1 at Pageable.getOffset()|不知到在讲啥||
|`Page<T>`|Pageable.getPageSize() at Pageable.getOffset()||需要执行count查询|
#### Paging and Sorting
你可以使用属性名来定义简单的排序表达式，可以把多个表达式拼接到一起
```java
Sort sort = Sort.by("firstname").ascending()
  .and(Sort.by("lastname").descending());
```
类型安全的方式是使用属性的方法引用来定义排序表达式
```java
TypedSort<Person> person = Sort.sort(Person.class);

Sort sort = person.by(Person::getFirstname).ascending()
  .and(person.by(Person::getLastname).descending());
```
`TypedSort.by(…)`需要运行时代理使用`CGlib`，可能会到native image编译造成影响。如果你的底层存储支持`Querydsl`，你可以使用生成的metamodel类型类定义排序表达式:
```java
QSort sort = QSort.by(QPerson.firstname.asc())
  .and(QSort.by(QPerson.lastname.desc()));
```
#### Limiting Query Results
除了分页，可以使用专门的`Limit`参数来限定返回的结果数量。也可以使用`Top`或者`First`关键词，可以交换使用，但是不要与`Limit`参数混合使用，你可以在`Top`或者`First`后指定一个可选的数字值来指定要返回的最大数量，如果没有指定数量，默认返回1条，下面的例子展示了如何限定结果数量
```java
List<User> findByLastname(Limit limit);

User findFirstByOrderByLastnameAsc();

User findTopByOrderByAgeDesc();

Page<User> queryFirst10ByLastname(String lastname, Pageable pageable);

Slice<User> findTop3ByLastname(String lastname, Pageable pageable);

List<User> findFirst10ByLastname(String lastname, Sort sort);

List<User> findTop10ByLastname(String lastname, Pageable pageable);
```
支持`Distinct`，返回结果支持`Optional`
## Query methods
### Query Lookup Strategies
es模块支持构建所有基本的查询: string查询、native search查询、criteria查询或者方法名查询。从方法名派生查询有时实现不了或者方法名不可读。在这种情况下，你可以使用`@Query`注解查询，参考[Using @Query Annotation](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.query-methods.at-query)。
### Query创建
通常来说，查询创建机制描述在[Defining Query Methods](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#repositories.query-methods)里面所描述的，下面是一个例子，这个例子展示了ES查询方法是如何翻译为ES查询的:
```java
interface BookRepository extends Repository<Book, String> {
  List<Book> findByNameAndPrice(String name, Integer price);
}
```
上面的方法名将会翻译为下面的查询:
```json
{
    "query": {
        "bool" : {
            "must" : [
                { "query_string" : { "query" : "?", "fields" : [ "name" ] } },
                { "query_string" : { "query" : "?", "fields" : [ "price" ] } }
            ]
        }
    }
}
```
支持的关键字列表如下
|keyword|Sample|Elasticsearch Query String|
|:---|:---|:---|
|And|findByNameAndPrice|`{\n  "query": {\n    "bool": {\n      "must": [\n        { "query_string": { "query": "?", "fields": ["name"] } },\n        { "query_string": { "query": "?", "fields": ["price"] } }\n      ]\n    }\n  }\n}\n`|
|Or|findByNameOrPrice|`{\n  "query": {\n    "bool": {\n      "should": [\n        { "query_string": { "query": "?", "fields": ["name"] } },\n        { "query_string": { "query": "?", "fields": ["price"] } }\n      ]\n    }\n  }\n}\n`|
|Is|findByName|`{\n  "query": {\n    "bool": {\n      "must": [{ "query_string": { "query": "?", "fields": ["name"] } }]\n    }\n  }\n}\n`|
|Not|findByNameNot|`{\n  "query": {\n    "bool": {\n      "must_not": [{ "query_string": { "query": "?", "fields": ["name"] } }]\n    }\n  }\n}\n`|
|Between|findByPriceBetween|`{\n  "query": {\n    "bool": {\n      "must": [\n        {\n          "range": {\n            "price": {\n              "from": ?,\n              "to": ?,\n              "include_lower": true,\n              "include_upper": true\n            }\n          }\n        }\n      ]\n    }\n  }\n}\n`|
|LessThan|findByPriceLessThan|`{\n    "query": {\n        "bool": {\n            "must": [\n                {\n                    "range": {\n                        "price": {\n                            "from": null,\n                            "to": ?,\n                            "include_lower": true,\n                            "include_upper": false\n                        }\n                    }\n                }\n            ]\n        }\n    }\n}`|
|LessThanEqual|findByPriceLessThanEqual|`{\n    "query": {\n        "bool": {\n            "must": [\n                {\n                    "range": {\n                        "price": {\n                            "from": null,\n                            "to": ?,\n                            "include_lower": true,\n                            "include_upper": true\n                        }\n                    }\n                }\n            ]\n        }\n    }\n}`|
|GreaterThan|findByPriceGreaterThan|`{ "query" : {\n    "bool" : {\n    "must" : [\n    {"range" : {"price" : {"from" : ?, "to" : null, "include_lower" : false, "include_upper" : true } } }\n    ]\n    }\n    }}`|
|GreaterThanEqual|findByPriceGreaterThanEqual|`{ "query" : {\n    "bool" : {\n    "must" : [\n    {"range" : {"price" : {"from" : ?, "to" : null, "include_lower" : true, "include_upper" : true } } }\n    ]\n    }\n    }}`|
|In (when annotated as FieldType.Keyword)|findByNameIn(Collection<String>names)|`{ "query" : {\n    "bool" : {\n    "must" : [\n    {"bool" : {"must" : [\n    {"terms" : {"name" : ["?","?"]}}\n    ]\n    }\n    }\n    ]\n    }\n    }}`|
|In|findByNameIn(Collection<String>names)|`{ "query": {"bool": {"must": [{"query_string":{"query": "\"?\" \"?\"", "fields": ["name"]}}]}}}`|
|NotIn|findByNameNotIn(Collection<String>names)|`{\n  "query": {\n    "bool": {\n      "must": [\n        { "query_string": { "query": "NOT(\"?\" \"?\")", "fields": ["name"] } }\n      ]\n    }\n  }\n}\n`|
|OrderBy|findByAvailableTrueOrderByNameDesc|`{\n  "query": {\n    "bool": {\n      "must": [{ "query_string": { "query": "true", "fields": ["available"] } }]\n    }\n  },\n  "sort": [{ "name": { "order": "desc" } }]\n}\n`|
|Exists|findByNameExists|`{"query":{"bool":{"must":[{"exists":{"field":"name"}}]}}}`|

方法名的方式不支持Geo-shape查询，请使用`ElasticsearchOperations`的`CriteriaQuery`。
### Method return types
Repository方法可以返回下面的类型:
- `List<T>`
- `Stream<T>`
- `SearchHits<T>`
- `List<SearchHit<T>>`
- `Stream<SearchHit<T>>`
- `SearchPage<T>`

### Using @Query注解
在方法上声明查询，参数可以通过查询字符串中的占位符定义。占位符类似?0,?1,?2这种:
```java
interface BookRepository extends ElasticsearchRepository<Book, String> {
    @Query("{\"match\": {\"name\": {\"query\": \"?0\"}}}")
    Page<Book> findByName(String name,Pageable pageable);
}
```
注解参数中的字符串必须是一个有效的ES JSON查询。它将会作为query元素的值发送给ES。产生的查询例子如下:
```json
{
  "query": {
    "match": {
      "name": {
        "query": "John"
      }
    }
  }
}
```
集合参数的查询方法如下:
```java
@Query("{\"ids\": {\"values\": ?0 }}")
List<SampleEntity> getByIds(Collection<String> ids);
```
将会执行一个[IDs query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-ids-query.html)来返回IDs规定的所有文档:
```json
{
  "query": {
    "ids": {
      "values": ["id1", "id2", "id3"]
    }
  }
}
```
## Projections
Spring Data查询方法通常会返回仓库管理的聚合根的一个或者多个实例对象。有时想要创建聚合根的几个属性的投影。Spring Data允许返回专门的投影类型。考虑如下的例子:
```java
class Person {

  @Id UUID id;
  String firstname, lastname;
  Address address;

  static class Address {
    String zipCode, city, street;
  }
}

interface PersonRepository extends Repository<Person, UUID> {

  Collection<Person> findByLastname(String lastname);
}
```
现在想象我们只想要检索人的名字，怎么做呢
### Interface-based Projections
最简单的方式是声明接口，接口只暴露要读区的属性的访问方法，如下例子所示:
```java
interface NamesOnly {

  String getFirstname();
  String getLastname();
}
```
这里定义的属性要精确匹配聚合根中的属性，然后添加如下的查询方法：
```java
interface PersonRepository extends Repository<Person, UUID> {
  Collection<NamesOnly> findByLastname(String lastname);
}
```
查询执行引擎会在运行时为每一个返回的元素创建一个接口的代理实例，将对访问方法的调用转发到底层实际的对象。在`Repository`接口中声明的方法如果覆盖了基本内置方法，将只会调用基本内置方法而不管返回类型，确保使用兼容的返回类型，因为基方法不能用于投影。一些存储模块支持`@Query`注解，将重写的基本方法转换为查询方法，然后可用于返回投影。投影可以递归的使用，如果你想要包含一些`Address`的信息，创建一个接口，并返回它，如下面的例子所示:
```java
interface PersonSummary {

  String getFirstname();
  String getLastname();
  AddressSummary getAddress();

  interface AddressSummary {
    String getCity();
  }
}
```
在方法调用时，目标实例的`address`属性会被获取并被包含在一个投影代理中。
#### Closed Projecttions(封闭式投影)
一个投影接口，它的访问方法都匹配目标聚合根的属性，被认为是封闭式投影，下面的例子就是一个封闭式投影
```java
interface NamesOnly {

  String getFirstname();
  String getLastname();
}
```
如果你使用封闭式投影，Spring Data可以优化执行查询，因为我们知道需要生成投影代理的所需要的所有的属性。
#### Open Projections
投影代理中的访问方法也能用来计算新的值，这是通过`@Value`注解实现的，如下面的例子所示:
```java
interface NamesOnly {

  @Value("#{target.firstname + ' ' + target.lastname}")
  String getFullName();
  …
}
```
聚合根就是里面的target变量，使用了`@Value`的投影接口是开放式投影，Spring Data不能对开放式投影应用查询优化，因为SpEL表达式可以使用聚合根的任意属性。在`@Value`注解中的表达式不要太复杂，你应该避免用字符串变量编程，对于简单的表达式，你可以使用Java8的默认方法，如下面的例子所示:
```java
interface NamesOnly {

  String getFirstname();
  String getLastname();

  default String getFullName() {
    return getFirstname().concat(" ").concat(getLastname());
  }
}
```
还有一种方法就是在一个Spring Bean中实现逻辑并通过SpEl表达式调用，如下面的例子所示:
```java
@Component
class MyBean {

  String getFullName(Person person) {
    …
  }
}

interface NamesOnly {

  @Value("#{@myBean.getFullName(target)}")
  String getFullName();
  …
}
```
我们注意到，SpEL表达式引用了`myBean`然后调用了`getFullName(...)`方法，使用了投影背后的聚合根作为方法的参数，SpEL表达式求值支持的方法也可以使用方法参数，然后可以从表达式中引用这些参数。方法参数可通过名为args的对象数组获得。以下示例显示如何从args数组获取方法参数：
```java
interface NamesOnly {

  @Value("#{args[0] + ' ' + target.firstname + '!'}")
  String getSalutation(String prefix);
}
```
另外，对于复杂的表达式，你应该使用Spring Bean并让表达式调用方法。
#### Nullable Wrappers
投影接口中的Getters可以使用nullable wrappers来提升null-safety，目前支持的wrapper类型有:
- `java.util.Optional`
- `com.google.common.base.Optional`
- `scala.Option`
- `io.vavr.control.Option`

```java
interface NamesOnly {

  Optional<String> getFirstname();
}
```
### Class-based Projections (DTOs)
另外一种定义投影的方式使用值类型DTOs(data transfer objects)，它们持有需要检索的属性，使用的方式与接口投影的方式类似，但是不会产生代理也不能使用嵌套投影。如果底层存储要通过限制读取的field来优化查询执行，这些field要通过构造函数的参数来决定。下面是一个例子:
```java
record NamesOnly(String firstname, String lastname) {
}
```
Java Record适合用来定义DTO类型，因为它们遵守值类型语义。所有的fields都是`private final`的并且`equals(...)/hashCode(...)/toString()`方法都是自动创建的。另外·你可以使用任意类。
### Dynamic Projections
到此为止，我们已经使用投影类型作为返回类型或者集合的元素类型，然而，你可能想要早运行时要就是实际调用时决定使用哪种返回类型，为了应用动态投影，可以使用下面例子中的查询方法
```java
interface PersonRepository extends Repository<Person, UUID> {

  <T> Collection<T> findByLastname(String lastname, Class<T> type);
}
```
这样，方法可以返回聚合根或者投影类型
```java
void someMethod(PersonRepository people) {

  Collection<Person> aggregates =
    people.findByLastname("Matthews", Person.class);

  Collection<NamesOnly> aggregates =
    people.findByLastname("Matthews", NamesOnly.class);
}
```
`Class`类型的查询参数会被检查是否是动态动态投影参数，如果查询的返回类型等于`Class`参数定义的泛型参数类型。
## Custom Repository Implementations
Spring Data提供了多种选项来使用最少的带来来创建查询方法。如果这些不满足你的需求，你也可以为这些仓库方法提供你自己的实现。
### Customizing Individual Repositories
为了让仓库支持自定义功能，首先需要定义一个接口然后使用自定义实现实现这个接口
```java
interface CustomizedUserRepository {
  void someCustomMethod(User user);
}
class CustomizedUserRepositoryImpl implements CustomizedUserRepository {

  public void someCustomMethod(User user) {
    // Your custom implementation
  }
}
```
类名的最重要的部分时相比于接口，实现是接口名+Impl后缀。实现本身不依赖Spring Data，可以是普通的Spring Bean，因此，你可以使用标准的依赖注入行为。然后让你的仓库接口继承自定义接口，如下所示:
```java
interface UserRepository extends CrudRepository<User, Long>, CustomizedUserRepository {

  // Declare query methods here
}
```
扩展自定义接口的新接口组合了所有的操作，Spring Data仓库是通过使用多个原子仓库片段组合实现的。片段是base repository、functional aspects(例如QueryDsl)、自定义接口及其实现。每次将接口添加到仓库接口时，您都可以通过添加片段来增强组合。base respository和repository aspect实现由每个Spring Data模块提供。下面的例子展示了自定义接口与它们的实现
```java
interface HumanRepository {
  void someHumanMethod(User user);
}

class HumanRepositoryImpl implements HumanRepository {

  public void someHumanMethod(User user) {
    // Your custom implementation
  }
}

interface ContactRepository {

  void someContactMethod(User user);

  User anotherContactMethod(User user);
}

class ContactRepositoryImpl implements ContactRepository {

  public void someContactMethod(User user) {
    // Your custom implementation
  }

  public User anotherContactMethod(User user) {
    // Your custom implementation
  }
}
```
下面的例子展示了接口组合
```java
interface UserRepository extends CrudRepository<User, Long>, HumanRepository, ContactRepository {

  // Declare query methods here
}
```
仓库可能由多个自定义实现构成，这些自定义实现按照声明的顺序导入。自定义实现比base repository/repository aspect有更高的优先级，这样可以覆盖base repository/repository aspect的方法。自定义实现可以用在多个repository中，可以复用下面是一个例子
```java
interface CustomizedSave<T> {
  <S extends T> S save(S entity);
}

class CustomizedSaveImpl<T> implements CustomizedSave<T> {

  public <S extends T> S save(S entity) {
    // Your custom implementation
  }
}
interface UserRepository extends CrudRepository<User, Long>, CustomizedSave<User> {
}

interface PersonRepository extends CrudRepository<Person, Long>, CustomizedSave<Person> {
}
```
#### Configuration
仓库基础设施会尝试自动检测自定义实现，方法是在发现repository所在的package下面扫描类，自定义实现需要遵循命名约定，也就是后面有Impl后缀。
```java
@EnableElasticsearchRepositories(repositoryImplementationPostfix = "MyPostfix")
class Configuration { … }
```
## Publishing Events from Aggregate Roots
## Null Handling of Repository Methods
## CDI Integration
## Repository query keywords
## Repository query return types
# Old version
## Reactive Elasticsearch Repositories
Reactive Elasticsearch Repositories通过Reactive Elasticsearch Operations实现。SDE Reactive repo使用Project Reactor作为底层库。有3个可用的接口：
- ReactiveRepository
- ReactiveCrudRepository
- ReactiveSortingRepository
### Usage
```java
interface ReactivePersonRepository extends ReactiveSortingRepository<Person, String> {

  Flux<Person> findByFirstname(String firstname);//查询给定firstname的所有人                                 

  Flux<Person> findByFirstname(Publisher<String> firstname);// 通过Publisher的输入来查询人                        

  Flux<Person> findByFirstnameOrderByLastname(String firstname);                    

  Flux<Person> findByFirstname(String firstname, Sort sort);                        

  Flux<Person> findByFirstname(String firstname, Pageable page);                    

  Mono<Person> findByFirstnameAndLastname(String firstname, String lastname);       

  Mono<Person> findFirstByLastname(String lastname);                                

  @Query("{ \"bool\" : { \"must\" : { \"term\" : { \"lastname\" : \"?0\" } } } }")
  Flux<Person> findByLastname(String lastname);                                     

  Mono<Long> countByFirstname(String firstname)                                     

  Mono<Boolean> existsByFirstname(String firstname)                                 

  Mono<Long> deleteByFirstname(String firstname)                                    
}
```
### Configuration
对于Java配置，使用`@EnableReactiveElasticsearchRepositories`注解，如果没有配置base package，底层狂简扫描configuration class所在的包。下面的代码是个例子:
```java
@Configuration
@EnableReactiveElasticsearchRepositories
public class Config extends AbstractReactiveElasticsearchConfiguration {

  @Override
  public ReactiveElasticsearchClient reactiveElasticsearchClient() {
    return ReactiveRestClients.create(ClientConfiguration.localhost());
  }
}
```
因为前一个示例中的存储库扩展了ReactiveSortingRepository，所以所有CRUD操作以及对实体进行排序访问的方法都是可用的。使用存储库实例是一个将依赖注入到客户端的问题，如下面的例子所示:
```java
public class PersonRepositoryTests {

  @Autowired ReactivePersonRepository repository;

  @Test
  public void sortsElementsCorrectly() {

    Flux<Person> persons = repository.findAll(Sort.by(new Order(ASC, "lastname")));

    // ...
  }
}
```
## Annotations for repository methods
### @Highlight
`@Highlight`注解定义了返回的实体中，哪些fields应该高亮。下面是一个例子:
```java
interface BookRepository extends Repository<Book, String> {

    @Highlight(fields = {
        @HighlightField(name = "name"),
        @HighlightField(name = "summary")
    })
    SearchHits<Book> findByNameOrSummary(String text, String summary);
}
```
可以定义多个fields都是高亮的，可以通过`@HighlightParameters`注解来定制`@Highlight`与`@HighlightField`注解。在搜索结果中，highlight数据可以从SearchHit中检索。
### @SourceFilters
有时候用户不需要实体中所有的属性。只需要一个子集。ES提供了source过滤的能力来减少数据量。如果Query+`ElasticsearchOperations`可以很容易的通过设置source filter来实现，如果使用repository方法，可以使用这个注解:
```java
interface BookRepository extends Repository<Book, String> {
    @SourceFilters(includes = "name")
    SearchHits<Book> findByName(String text);
}
```
## 基于注解的配置
SDE repositories可以通过Java注解启动。
```java
@Configuration
@EnableElasticsearchRepositories(// 启动repository支持，如果没有配置base package，将会使用它放置的配置类所在的包
  basePackages = "org.springframework.data.elasticsearch.repositories"
  )
static class Config {

  @Bean
  public ElasticsearchOperations elasticsearchTemplate() {//
      // ...
  }
}

class ProductService {

  private ProductRepository repository;//注入

  public ProductService(ProductRepository repository) {
    this.repository = repository;
  }

  public Page<Product> findAvailableBookByName(String name, Pageable pageable) {
    return repository.findByAvailableTrueAndNameStartingWith(name, pageable);
  }
}
```
## Elasticsearch Repositories using CDI
SDE可以配置使用CDI功能。
```java
class ElasticsearchTemplateProducer {

  @Produces
  @ApplicationScoped
  public ElasticsearchOperations createElasticsearchTemplate() {
    // ...                               (1)
  }
}

class ProductService {

  private ProductRepository repository;  (2)
  public Page<Product> findAvailableBookByName(String name, Pageable pageable) {
    return repository.findByAvailableTrueAndNameStartingWith(name, pageable);
  }
  @Inject
  public void setRepository(ProductRepository repository) {
    this.repository = repository;
  }
}
```
# Auditing
## Basics
Spring Data提供了丰富的支持，可以透明地跟踪谁创建或更改了实体以及更改发生的时间。要从该功能中受益，您必须为实体类配备auditing元数据，这些元数据可以使用注解或实现接口来定义。此外，必须通过注解配置或XML配置来开启auditing以注册所需的基础架构组件。请参阅特定sotre部分的配置示例。仅跟踪创建和修改日期的应用程序不需要使其实体实现`AuditorAware`。
### Annotation-based Auditing Metadata
我们提供`@CreatedBy`和`@LastModifiedBy`来捕获创建或修改实体的用户，以及`@CreatedDate`和`@LastModifiedDate`来捕获更改发生的时间。
```java
class Customer {
  @CreatedBy
  private User user;

  @CreatedDate
  private Instant createdDate;

  // … further properties omitted
}
```
正如您所看到的，可以根据您想要捕获的信息有选择地应用注解。这些注解指示在发生更改时进行捕获，可用于JDK8日期和时间类型、long、Long以及旧版Java日期和日历的属性。auditing元数据不一定需要存在于根级实体中，也可以添加到嵌入式实体中（取决于使用的实际存储），如下面的代码片段所示。
```java
class Customer {
  private AuditMetadata auditingMetadata;
  // … further properties omitted
}
class AuditMetadata {
  @CreatedBy
  private User user;
  @CreatedDate
  private Instant createdDate;
}
```
### Interface-based Auditing Metadata
如果您不想使用注解来定义auditing元数据，您可以让您的域类实现`Auditable`接口。它公开了所有auditing属性的setter方法。
### AuditorAware
如果您使用`@CreatedBy`或`@LastModifiedB`，auditing基础设施需要以某种方式了解当前principal。为此，我们提供了一个`AuditorAware<T>`SPI接口，您必须实现该接口来告诉基础架构当前与应用程序交互的用户或系统是谁。泛型类型T定义了用`@CreatedBy`或`@LastModifiedBy`注释的属性必须是什么类型。
以下示例显示了使用Spring Security的Authentication对象的接口的实现:
```java
class SpringSecurityAuditorAware implements AuditorAware<User> {

  @Override
  public Optional<User> getCurrentAuditor() {

    return Optional.ofNullable(SecurityContextHolder.getContext())
            .map(SecurityContext::getAuthentication)
            .filter(Authentication::isAuthenticated)
            .map(Authentication::getPrincipal)
            .map(User.class::cast);
  }
}
```
该实现访问Spring Security提供的Authentication对象，并查找您在`UserDetailsService`实现中创建的自定义`UserDetails`实例。我们在这里假设您通过UserDetails实现公开域用户，但根据找到的身份验证，您也可以从任何地方查找它。
### ReactiveAuditorAware
使用reactive基础设施时，您可能希望利用上下文信息来提供`@CreatedBy`或`@LastModifiedBy`信息。我们提供了一个`ReactiveAuditorAware<T>`SPI接口，您必须实现该接口来告诉基础架构当前与应用程序交互的用户或系统是谁。泛型类型T定义了用`@CreatedBy`或`@LastModifiedBy`注释的属性必须是什么类型。以下示例显示了使用反应式Spring Security的Authentication对象的接口实现：
```java
class SpringSecurityAuditorAware implements ReactiveAuditorAware<User> {

  @Override
  public Mono<User> getCurrentAuditor() {

    return ReactiveSecurityContextHolder.getContext()
                .map(SecurityContext::getAuthentication)
                .filter(Authentication::isAuthenticated)
                .map(Authentication::getPrincipal)
                .map(User.class::cast);
  }
}
```
该实现访问Spring Security提供的Authentication对象，并查找您在`UserDetailsService`实现中创建的自定义`UserDetails`实例。 我们在这里假设您通过`UserDetails`实现公开域用户，但根据找到的身份验证，您也可以从任何地方查找它。
## Elasticsearch Auditing
### Preparing entities
为了使auditing代码能够确定实体实例是否是新的，该实体必须实现`Persistable<ID>`接口，其定义如下:
```java
package org.springframework.data.domain;
import org.springframework.lang.Nullable;
public interface Persistable<ID> {
    @Nullable
    ID getId();
    boolean isNew();
}
```
由于Id的存在不足以确定`Elasticsearch`中的实体是否是新实体，因此需要额外的信息。一种方法是使用与创建相关的auditing字段来做出此决定.Person实体可能如下所示，为简洁起见，省略getter和setter方法:
```java
@Document(indexName = "person")
public class Person implements Persistable<Long> {
    @Id private Long id;
    private String lastName;
    private String firstName;
    @CreatedDate
    @Field(type = FieldType.Date, format = DateFormat.basic_date_time)
    private Instant createdDate;
    @CreatedBy
    private String createdBy
    @Field(type = FieldType.Date, format = DateFormat.basic_date_time)
    @LastModifiedDate
    private Instant lastModifiedDate;
    @LastModifiedBy
    private String lastModifiedBy;

    public Long getId() {     //                                            (1)
        return id;
    }

    @Override
    public boolean isNew() {
        return id == null || (createdDate == null && createdBy == null);  (2)
    }
}
```
### Activating auditing
设置实体并提供`AuditorAware`或`ReactiveAuditorAware`, 必须通过在配置类上设置 `@EnableElasticsearchAuditing`来激活auditing：
```java
@Configuration
@EnableElasticsearchRepositories
@EnableElasticsearchAuditing
class MyConfiguration {
   // configuration code
}
@Configuration
@EnableReactiveElasticsearchRepositories
@EnableReactiveElasticsearchAuditing
class MyConfiguration {
   // configuration code
}
```
如果您的代码包含多个不同类型的AuditorAware bean，则必须提供该bean的名称，以用作 `@EnableElasticsearchAuditing`注释的`AuditorAwareRef`参数的参数。

