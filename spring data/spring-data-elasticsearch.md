[TOC]
version=5.1.2
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
# Elasticsearch Operations
SDE使用几个接口定义了索引上的操作。
- IndexOperations，定义了索引级别的行为，比如创建/删除索引;
- DocumentOperations，定义了基于id存储、更新、检索文档的行为；
- SearchOperations，定义了查询搜索文档的行为;
- ElasticsearchOperations，将DocumentOperations与SearchOperations接口行为组合起来。

这些接口就类似ES API的结构分类。接口的实现提供:
- 索引管理功能;
- mapping读写功能
- 查询/criteria API
- 资源管理/异常处理

IndexOperations接口可以通过ElasticsearchOperations获取，比如`operations.indexOps(clazz)`，通过IndexOperations可以创建索引、设置mapping或者存储模板等，索引的详细信息可以通过@Setting注解设置。参考[index setting](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearc.misc.index.settings)获得更多的信息。这些操作都不是自动操作的。需要用户手动处理。自动操作需要使用SDE的Repository，可以参考[Automatic creation of indices with the corresponding mapping](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.repositories.autocreation)。
## 例子
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
## Reactive ES Operations
`ReactiveElasticsearchOperations`是一个网关，通过`ReactiveElasticsearchClient`执行各种命令。`ReactiveElasticsearchTemplate`是`ReactiveElasticsearchOperations`的默认实现。使用`ReactiveElasticsearchOperations`需要知晓底层实际使用的客户端。请参考[Reactive Rest Client](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.clients.reactiverestclient)获取更多详细的信息。`ReactiveElasticsearchOperations`让你可以存储、find与删除你的领域对象，并且可以把领域对象映射到ES中的文档。下面是一个例子:
```java
@Document(indexName = "marvel")
public class Person {

  private @Id String id;
  private String name;
  private int age;
  // Getter/Setter omitted...
}

ReactiveElasticsearchOperations operations;

// ...

operations.save(new Person("Bruce Banner", 42))// 插入一个person文档到marvel索引中，id是由es生成的，并放到返回的对象中                    
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

## Search Result Types
当文档通过`DocumentOperations`接口的方法检索时，只会返回发现的文档。当通过`SearchOperations`接口的方法搜索时，可以使用每个实体的额外信息。比如每个实体的score与sortValues。为了返回这些信息，每个实体都会wrapped到一个`SearchHit`对象中，这个对象包含了实体相关的额外信息。这些`SearchHit`对象自身在一个`SearchHits`对象中返回，这个对象包含了这个搜索相关的额外的信息。比如maxScore或者请求的聚合信息。SearchHit<T>包含的信息如下:
- id
- score
- Sort Values
- Highlight fields
- inner hists，也是SearchHits对象
- 检索的实体类型T

SearchHits<T>包含的信息如下:
- Number of total hits
- Total hits relation
- Maximum score
- A list of SearchHit<T> objects
- Returned aggregations
- Returned suggest results

`SearchPage<T>`是一个Spring Data Page的实现，内部包含`SearchHits<T>`元素，可以通过repository方法用来分页的访问。`SearchScrollHits<T>`是由底层的滚动API返回的，它在`SearchHits<T>`的基础上额外增加了滚动id。`SearchHitsIterator<T>`是返回的迭代器。ReactiveSearchHits
ReactiveSearchOperations has methods returning a Mono<ReactiveSearchHits<T>>, this contains the same information as a SearchHits<T> object, but will provide the contained SearchHit<T> objects as a Flux<SearchHit<T>> and not as a list.
## Queries
`SearchOperations`与`ReactiveSearchOperations`接口中定义的几乎所有的方法都使用`Query参数`，这个参数定义了要执行的搜索的查询。它是一个接口，SDE提供了3种实现:
### CriteriaQuery
`CriteriaQuery`查询允许你不需要了解ES查询的语法。通过链式或者流式的方式创建Criteria对象，这个对象指定了要搜索的文档必须满足的断言。组合断言的时候，AND会转换为ES的must条件，OR会转化为ES中的should条件。`Criteria`以及用法可以通过下面的例子解释:
```java
Criteria criteria = new Criteria("price").is(42.0);
Query query = new CriteriaQuery(criteria);
```
条件可以组成链，这个链会转换为一个逻辑AND
```java
Criteria criteria = new Criteria("price").greaterThan(42.0).lessThan(34.0);
Query query = new CriteriaQuery(criteria);
```
```java
Criteria criteria = new Criteria("lastname").is("Miller")// 第一个断言
  .and("firstname").is("James")                           
Query query = new CriteriaQuery(criteria);
```
如果想要创建nested的查询，你需要使用子查询。假设需要查询lastname=Miller，并且firstname=jack或者John的所有人。
```java
Criteria miller = new Criteria("lastName").is("Miller") // 为last name创建第一个Criteria 
  .subCriteria(    // 使用AND连接一个subCriteria                                     
    new Criteria().or("firstName").is("John") //sub Criteria是一个or表达式           
      .or("firstName").is("Jack")                        
  );
Query query = new CriteriaQuery(criteria);
```
请参考`Criteria`类的API文档获得更多的操作信息。
### StringQuery
这个类使用一个JSON字符串的ES查询。下面的代码展示了一个搜索firstname=Jack的人。
```java
Query query = new StringQuery("{ \"match\": { \"firstname\": { \"query\": \"Jack\" } } } ");
SearchHits<Person> searchHits = operations.search(query, Person.class);
```
如果你之前已经有了es查询，那么使用StringQuery是合适的。
### NativeQuery
`NativeQuery`是使用复杂查询时候该使用的。或者是使用`Criteria`API无法表达的时候应该使用的。比如，当构建查询或者使用聚合的时候，它允许使用来自官方包的所有的`co.elastic.clients.elasticsearch._types.query_dsl.Query`实现，因此命名为native。下面的代码展示了如何如何通过一个给定的firstname搜索人并且对于发现的人，做一个terms聚合操作，计算lastnames的出现次数。
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
# Elasticsearch Repositories
本章包含了ES Repository实现的细节。
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
## 索引/mapping的自动创建
`@Document`注解由一个createIndex的参数。如果参数设置为true，SDE将会在启动Repository支持的阶段检查索引是否存在。如果不存在，将会创建索引与mapping，索引的细节可以通过`@Setting`注解设置，参考[Index settings](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearc.misc.index.settings)获取更多的信息。
## Query methods
### Query lookup strategies
es模块支持构建所有基本的查询: string查询、native search查询、criteria查询或者方法名查询。从方法名派生查询有时实现不了或者方法名不可读。在这种情况下，你可以使用`@Query`注解查询，参考[Using @Query Annotation](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#elasticsearch.query-methods.at-query)。
### Query创建
通常来说，查询创建机制就是[QueryMethod](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#repositories.query-methods)里面所描述的，下面是一个例子，这个例子展示了ES查询方法是如何翻译为ES查询的:
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
支持的关键字列表如下,集体列表的内容参考官方文档吧.
### Method return types
Repository方法可以返回下面的类型:
- List<T>
- Stream<T>
- SearchHits<T>
- List<SearchHit<T>>
- Stream<SearchHit<T>>
- SearchPage<T>

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
将会返回IDs规定的所有文档:
```json
{
  "query": {
    "ids": {
      "values": ["id1", "id2", "id3"]
    }
  }
}
```
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

