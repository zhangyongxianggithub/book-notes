[TOC]
# 前言
Spring data jpa实现了JPA（Java Persistence API），简化了数据库应用的开发工作。
## Project Metadata
- Version control: [https://github.com/spring-projects/spring-data-jpa](https://github.com/spring-projects/spring-data-jpa);
- Bugtracker: [https://github.com/spring-projects/spring-data-jpa/issues](https://github.com/spring-projects/spring-data-jpa/issues);
- Milestone repository: [https://repo.spring.io/milestone](https://repo.spring.io/milestone);
- Snapshot repository: [ https://repo.spring.io/snapshot]( https://repo.spring.io/snapshot)
# Upgrading Spring Data
如何升级SDJ，在项目的[wiki](https://github.com/spring-projects/spring-data-commons/wiki)中，点击[release notes section](https://github.com/spring-projects/spring-data-commons/wiki#release-notes)中的链接来查找你想要升级的版本。升级步骤总是在发布note的前面，如果你落后了多个release版本，请确保你知道中间版本更新的内容。
# Dependencies
由于Spring Data不同模块的创始时间不同，他们有不同的major/minor版本号。可以通过Spring Data Release Train BOM来获取所有兼容的Spring Data模块版本。在一个maven项目中，需要在<dependencyManagement/>中声明这个依赖。
```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.data</groupId>
      <artifactId>spring-data-bom</artifactId>
      <version>2023.0.2</version>
      <scope>import</scope>
      <type>pom</type>
    </dependency>
  </dependencies>
</dependencyManagement>
```
当前的release train版本是`2023.0.2`，train version使用模式为YYYY.MINOR.MICRO格式的日历版本号表示法。GA/service release使用普通的日历表示法版本号，类似`${calver}-${modifier}`这样的版本号格式是其他的版本的版本号。modifier可以是下面的符号:
- SNAPSHORT: 当前的snapshots
- M1、M2: Milestones版本
- RC1、RC2: Release candidates
你可以在[Spring Data examples repository](https://github.com/spring-projects/spring-data-examples/tree/main/bom)找到例子。你可以在<dependencies/>中声明你想要的Spring Data模块且不需要指定版本号。
```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.data</groupId>
    <artifactId>spring-data-jpa</artifactId>
  </dependency>
<dependencies>
```
## Dependency Management with Spring Boot
Spring Boot会为你选择最近一个版本的Spring Data模块。如果你想要升级一个更新的版本，可以通过属性`spring-data-bom.version`设置你想要使用的train版本，可以参考Spring Boot相关的文档。
## Spring Framework
Spring Data模块的当前版本需要Spring Framework 6.0.11+版本。
# Spring Data Repositories如何工作
Spring data抽象的目标就是为各种各样的持久存储减少数据访问的样本代码。本章解释了Spring Data Repositories的核心概念与接口。本章的内容来自Spring Data Commons。它使用JPA相关的配置与代码。如果你想要使用XML配置，你应该采用XML命名空间声明。
## 核心概念
核心接口抽象就是`Repository`，它接受2个范型参数，一个是domain class，一个是domain class中的标识符类型，这个主要就是一个标记接口，细致化的CRUD要使用`CrudRepository/ListCrudRepository`。
```java
public interface CrudRepository<T, ID> extends Repository<T, ID> {

  <S extends T> S save(S entity); // 保存给定的实体     

  Optional<T> findById(ID primaryKey); // 根据给定的ID返回实体

  Iterable<T> findAll(); // 返回所有的实体              

  long count(); // 返回实体的数量                       

  void delete(T entity); // 删除实体              

  boolean existsById(ID primaryKey); //给定id的实体是否已存在  

  // … more functionality omitted.
}
```
接口中的方法声明就是CRUD方法，`ListCrudRepository`与`CrudRepository`中的方法相同，只是返回`List`而不是`CrudRepository`中的`Iterable`。我们也提供特定持久化存储相关的抽象，必入`JpaRepository`或者`MongoRepository`，这些接口扩展自`CrudRepository`接口，暴露了存储相关的操作。除了`CrudRepository`接口，`PagingAndSortingRepository`抽象添加了额外的方法，提供了分页相关的能力。
```java
public interface PagingAndSortingRepository<T, ID>  {

  Iterable<T> findAll(Sort sort);

  Page<T> findAll(Pageable pageable);
}
```
```java
PagingAndSortingRepository<User, Long> repository = // … get access to a bean
Page<User> users = repository.findAll(PageRequest.of(1, 20));
```
除了分页之外，滚动还提供了更细粒度的访问来迭代较大结果集的块.除了查询方法之外，还可以使用计数查询和删除查询的查询派生。 以下列表显示了派生计数查询的接口定义：
```java
interface UserRepository extends CrudRepository<User, Long> {
  long countByLastname(String lastname);
}
```
下面的例子展示了一个派生删除查询的接口定义:
```java
interface UserRepository extends CrudRepository<User, Long> {
  long deleteByLastname(String lastname);
  List<User> removeByLastname(String lastname);
}
```
## 查询方法
声明查询需要4个步骤:
- 声明一个接口，继承自Repository
  ```java
  interface PersonRepository extends Repository<Person, Long> { … }
  ```
- 在接口内声明查询方法
  ```java
  interface PersonRepository extends Repository<Person, Long> {
    List<Person> findByLastname(String lastname);
  }
  ```
- 设置Spring让其创建接口的代理实现，可以通过JavaConfig/XML配置的方式实现
  ```java
  import org.springframework.data.….repository.config.EnableJpaRepositories;

  @EnableJpaRepositories
  class Config { … }
  ```
  JavaConfig的配置方式没有明确的指定一个包，默认使用注解类所在的包，如果要自定义扫描的包，使用`@EnableXXXXRepositories`注解的basePackage属性。
- 注入repository
  ```java
  class SomeClient {
    private final PersonRepository repository;
    SomeClient(PersonRepository repository) {
      this.repository = repository;
    }
    void doSomething() {
      List<Person> persons = repository.findByLastname("Matthews");
    }
  }
  ```
## Defining Repositories Interface
定义一个接口，先要继承自`Repository`，并且已经有了domain class还有ID。
### Fine-tuning Repository Definition
您可以通过多种方式开始使用repository接口。通常就是继承`CrudRepository`或者`ListCrudRepository`，如果你使用reactive  store，你可以继承`ReactiveCrudRepository`或者`RxJava3CrudRepository`，这依赖你正在使用哪个reactive framework。如果你使用Kotlin，你也可以继承`CoroutineCrudRepository`，它使用了Kotlin的协程。另外，你也可以继承`PagingAndSortingRepository, ReactiveSortingRepository, RxJava3SortingRepository, CoroutineSortingRepository`。如果你不想要继承Spring Data的接口，你可以使用`@RepositoryDefinition`注解到你自己的接口。如果你的应用中有很多相同方法集的repositories，你可以定义个父接口，父接口必须使用`@NoRepsitoryBean`注解，它会阻止Spring Data创建一个它的代理实例，因为这里没有domain class，所以创建会失败。下面是一个例子:
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
### Using Repositories with Multi Spring Data Modules
在应用程序中使用单独的Spring Data模块使事情变得简单，因为定义范围内的所有存储库接口都绑定到一个Spring Data模块。有时，应用程序需要使用多个Spring Data模块。在这种情况下，一个Repository定义必须区分持久性底层存储。当它在类路径上检测到多个repository工厂时，Spring Data会进入严格的repository配置模式。严格配置使用respository或domain类的详细信息来决定repository绑定到哪个Spring Data模块:
- 如果repository继承自模块特有的repository，它是一个考虑因素。
- 如果domain class被模块特有的注解指定，它也是一个因素，Spring Data模块接受第三方注解。或者自己的注解。

下面例子展示了使用模块特有特性接口的repository的例子:
```java
interface MyRepository extends JpaRepository<User, Long> { }

@NoRepositoryBean
interface MyBaseRepository<T, ID> extends JpaRepository<T, ID> { … }

interface UserRepository extends MyBaseRepository<User, Long> { … }
```
下面的例子使用范型接口的例子
```java
interface AmbiguousRepository extends Repository<User, Long> { … }

@NoRepositoryBean
interface MyBaseRepository<T, ID> extends CrudRepository<T, ID> { … }

interface AmbiguousUserRepository extends MyBaseRepository<User, Long> { … }
```
下面的例子展示了domain class注解的例子
```java
interface PersonRepository extends Repository<Person, Long> { … }

@Entity
class Person { … }

interface UserRepository extends Repository<User, Long> { … }

@Document
class User { … }
```
`PersonRepository`引用了`Person`，使用了JPA的`@Entity`注解，所以这个repo将会绑定到Spring Data JPA，UserRepository引用了User，使用了Spring Data MongoDB的`@Document`注解。下面是一个不好的例子:
```java
interface JpaPersonRepository extends Repository<Person, Long> { … }

interface MongoDBPersonRepository extends Repository<Person, Long> { … }

@Entity
@Document
class Person { … }
```
上面的例子中，domain class同时使用了JPA与Spring Data MongoDB，它定义了2个repo，一个是JPA使用的，一个是MongoDB使用的。Spring Data不能区分repo，这会导致未定义的行为。[Repository type details](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.multiple-modules.types)和[distinguishing domain class annotations](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.multiple-modules.annotations)是用来严格的repo配置来表示repo属于哪个Spring Data模块。在同一域类型上使用多个特定存储模块的注释是可以的，并且可以跨多种持久性技术重用域类型。但是，Spring Data将无法再确定repo绑定到哪一个模块。最终区分repo的方式是限定repo的base package，base package定义了扫描repo接口定义的开始点，下面定义是一个base package的例子:
```java
@EnableJpaRepositories(basePackages = "com.acme.repositories.jpa")
@EnableMongoRepositories(basePackages = "com.acme.repositories.mongo")
class Configuration { … }
```
## Defining Query Methods
repo代理有2种方法来从方法名派生出查询:
- 直接从方法名;
- 手动指定
可用的选项依赖底层使用存储中间件，然而，必须存在一个策略来决定查询如何生成。下一部分描述可用的选项
### Query Lookup Strategies
repo基础设施可以使用下面的策略来解析查询。使用XML配置方式，你可以在命名空间下通过query-lookup-strategy属性来配置策略。对于Java配置方式来说，你可以使用`@EnableJpaRepositories`注解的queryLookupStrategy属性来指定。特定的底层存储可能不支持某些策略:
- `CREATE`，尝试从方法名构建查询，具体的方法就是从方法名中移除特定的前缀并根据方法名剩余的内容解析查询，可以阅读相信的信息[Query Creation](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.query-methods.query-creation)
- `USE_DECLARED_QUERY`，尝试查找一个声明的查询，如果没找到抛出异常。查询可以通过注解定义或者其他的方式定义。具体的信息可以参考各个存储模块的详细内容，如果在启动启动阶段没有找到查询，则启动失败。
- `CREATE_IF_NOT_FOUND`，这是默认的策略，融合了上面2种策略，首先查找声明式查询，如果没有，基于方法名创建查询，这个策略是默认的策略，不需要显式的配置。可以通过方法名快速的定义查询，可以通过定义声明式查询来调整这些查询。
### Query Creation
查询构建机制是用来在实体上构建限制性的查询。下面的例子展示了如何构建查询:
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
解析查询方法名会将方法名分解成subject与predicate，第一部分定义了查询的subject(find..By..,exists...By)，第二部分构成了predicate，subject可以包含更多的表达式，find/By之间的任何的文本都被认为是可描述的字段，也可以是结果限定关键词比如Distinct，或者是First/Top关键词。附录中包含了全部的[subject关键词](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#appendix.query.method.subject)与[查询方法predicate关键词](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#appendix.query.method.predicate)第一个遇到的By是一个分割符，意味着criteria predicate的开始，你可以在实体属性上定义条件，并用And/Or拼接。解析方法的实际结果取决于您为其创建查询的持久性存储。然而，有一些一般性的事情需要注意:
- 表达式通常是属性遍历与可连接的运算符相结合。您可以使用AND和OR组合属性表达式。您还可以获得对属性表达式的运算符（例如Between、LessThan、GreaterThan和Like）的支持。支持的运算符可能因数据存储而异，因此请参阅参考文档的相应部分;
- 方法解析器支持IgnoreCase标志；
- 你可以使用OrderBy指定排序，为了支持动态排序，你可以参考[Paging, Iterating Large Results, Sorting](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.special-parameters)
### Property Expressions
属性表达式只能是实体的直接属性，在启动时就会检查属性是不是实体的属性，你也可以定义内嵌属性，下面的方法签名:
```java
List<Person> findByAddressZipCode(ZipCode zipCode);
```
Person下面的Address具有属性ZipCode，方法会查找属性名x.address.zipCode，解析算法解析AddressZipCode作为属性，并且检查实体是否具有给定的属性，如果算法成功就是使用这个属性，如果不成功，算法会根据驼峰格式从右向左分解为2个头尾字符串，试图寻找相关的属性，在我们的例子中，会被分解为AddressZip与Code，如果算法找到AddressZip，那么会按照这个递归的过程锅里尾字符串。如果没找到，切分点向左移动并继续寻找。虽然这个算法大部分情况下都是正确的，但是有时候可能选出错。为了解决可能出错的请款，你可以在方法名中加入_下划线手动指定切分点，类似如下:
```java
List<Person> findByAddress_ZipCode(ZipCode zipCode);
```
因为我们把下划线座位保留字符，所以我们建议你不要在属性名中使用下划线而是使用驼峰命名法。
### Paging，Iterating Large Results, Sorting
为了操作查询中的参数，需要定义方法参数。除此以外，SDJ可以识别特定的类型比如Pageable或者Sort，可以动态的支持分页或者排序。下面的例子展示了这些特性:
```java
Page<User> findByLastname(String lastname, Pageable pageable);
Slice<User> findByLastname(String lastname, Pageable pageable);
Window<User> findTop10ByLastname(String lastname, ScrollPosition position, Sort sort);
List<User> findByLastname(String lastname, Sort sort);
List<User> findByLastname(String lastname, Pageable pageable);
```
使用了Sort或者Pageable参数的方法不会接受null，如果你不分页或者不排序，使用`Sort.unsorted()`或者`Pageable.unpaged()`。
底层会计算总数与总页数，通过一个count查询计算。这可能比较耗时，你可以返回一个`Slice`，`Slice`只有是否有下一个slice的信息。从方法中可以返回的结果在文档的表中。可以定义多个排序字段
```java
Sort sort = Sort.by("firstname").ascending()
  .and(Sort.by("lastname").descending());
```
如果想用类型安全的方式定义排序表达式，
### 返回集合或者迭代器
集合类型除了返回标准的Iterable，List或者Set，也可以返回Streamable或者Vavr类型，
## Spring Data拓展
- querydsl，用于构造流式的类似SQL语句的查询，通过继承QuerydslPredicateExecutor接口来使用dsl，如下：
```java
public interface QuerydslPredicateExecutor<T> {

  Optional<T> findById(Predicate predicate);  

  Iterable<T> findAll(Predicate predicate);   

  long count(Predicate predicate);            

  boolean exists(Predicate predicate);        

  // … more functionality omitted.
}
```
- web支持，使用@EnableSpringDataWebSupport开启Spring data的web支持
```java
@Configuration
@EnableWebMvc
@EnableSpringDataWebSupport
class WebConfiguration {}
```

# 参考文档
这一章主要讲解spring data jpa的特点，这建立在核心概念Repository上，你需要充分的理解这里讲述的基本概念。
## 引言
这一个节讲述jpa配置的基本核心
- XML配置，忽略
- 基于注解的配置

Java配置方式的代码如下:
```java
@Configuration
@EnableJpaRepositories
@EnableTransactionManagement
class ApplicationConfig {

  @Bean
  public DataSource dataSource() {

    EmbeddedDatabaseBuilder builder = new EmbeddedDatabaseBuilder();
    return builder.setType(EmbeddedDatabaseType.HSQL).build();
  }

  @Bean
  public LocalContainerEntityManagerFactoryBean entityManagerFactory() {

    HibernateJpaVendorAdapter vendorAdapter = new HibernateJpaVendorAdapter();
    vendorAdapter.setGenerateDdl(true);

    LocalContainerEntityManagerFactoryBean factory = new LocalContainerEntityManagerFactoryBean();
    factory.setJpaVendorAdapter(vendorAdapter);
    factory.setPackagesToScan("com.acme.domain");
    factory.setDataSource(dataSource());
    return factory;
  }

  @Bean
  public PlatformTransactionManager transactionManager(EntityManagerFactory entityManagerFactory) {

    JpaTransactionManager txManager = new JpaTransactionManager();
    txManager.setEntityManagerFactory(entityManagerFactory);
    return txManager;
  }
}
```
你必须创建一个`LocalContainerEntityManagerFactoryBean`，不要直接创建`EntityManagerFactory`，因为前面比后面自动加入了异常翻译机制。上面的配置类，使用HSQL作为数据库，然后设置了一个`EntityManagerFactory`，并使用Hibernate作为简单的持久化中间件提供者，最后的基础组件是`JpaTransactionManager`，最后，例子使用`@EnableJpaRepositories`注解激活了JPA的仓库功能，它具有与XML配置方式相同的属性，如果没有配置base package，默认是配置类所在的包。
### 引导模式
默认情况下，JPA仓库既是Spring管理的bean，它们是单例的生命周期并且初始化比较早。在启动过程中，它们就被`EntityManager`使用用于验证与元数据分析工作，Spring框架支持`EntityManagerFactory`的后台初始化，因为`EntityManagerFactory`的初始化比较耗时，为了让后台初始化有效，我们需要确保JPA仓库尽可能晚的初始化。Spring data JPA 2.1版本后，你可以通过注解或者XML的方式配置BootstrapMode，可能的值如下：
- DEFAULT(默认的启动模式)，早期初始化，除非用@lazy指定，如果存在依赖，也会先初始化。
- LAZY，所有的repo都是懒加载的，注入其他bean的都是懒加载的代理Bean，这意味着，如果只是作为一个field注入而没有用到repo的方法，repo就没有真正的初始化，repo只有在第一次使用时才会实例化并验证。
- DEFERRED，模式与LAZY差不多，但是仓库在收到ContextRefreshEvent事件后会被初始化，所以，仓库会在应用启动前被验证。

### 建议
如果你的JPA启动不是异步的，那么用默认模式，如果是异步模式，那么用DEFERRED模式，因为JPA仓库实例化只会等待EntityManagerFactory设置完之后，它会确保在程序启动前，所有的仓库得到合理的初始化与验证，LAZY模式主要用于测试场景与本地开发的场景，只要你确定你的仓库是完美启动的，或者你只要测试仓库中的一个或者某个部分，不需要其他仓库实例化，这样可以节省启动的时间。
## 持久化实体
存储实体通过`save()`方法，底层用的`EntityManager`，如果实体是第一次存储，`EntityManager`会使用`persist()`方法，否则使用`merge()`方法。
### Entity State-detection Strategies
SDJ提供了3种策略来检测一个entity是不是新的:
- Version-Property and Id-Property inspection (default):先检测Version-Property，如果存在且为null，就认为实体是新的，然后检测ID属性，如果为null，就认为是新的实体，否则不是新的实体
- 实现`Persistable`: 实现`isNew()`方法来检测;
- 实现`EntityInformation`: 创建自定义的`JpaRepositoryFactory`bean，覆盖`getEntityInformation(…)`方法来实现

选项1不适合人工分配主键的情况，因为主键任何时候都不是空的，一种通用的做法是在基类中声明一个transient标志字段来表示是否是新的实体并使用JPA的生命周期回调方法来改变值:
```java
@MappedSuperclass
public abstract class AbstractEntity<ID> implements Persistable<ID> {

  @Transient
  private boolean isNew = true; // 声明一个标志，Transient表示不会被存储到数据库

  @Override
  public boolean isNew() {
    return isNew; // 实现了Persistable.isNew()接口，这样SDJ知道什么时候调用persist或者merge
  }

  @PrePersist // 声明一个回调方法，标识在调用save后就是一个已经存在的实体
  @PostLoad
  void markNotNew() {
    this.isNew = false;
  }

  // More code…
}
```
## 查询方法
JPA模块支持手动以一个字符串的方式定义一个查询或者从方法名衍生。
### Query Lookup Strategies
查询查找策略，JPA支持2种查询方式，一种是直接执行SQL，一种是SQL通过方法名字衍生出来的SQL，带有下面谓词的派生查询`IsStartingWith, StartingWith, StartsWith, IsEndingWith, EndingWith, EndsWith, IsNotContaining, NotContaining, NotContains, IsContaining, Containing, Contains`的方法中的参数会被转义处理，比如like中的通配符，会被转义，转义字符可以通过`@EnableJpaReposities`注解的escapeCharacter配置
### Declared Queries
虽然通过方法名生成查询很方便，但是有些场景下也不好，比如，方法名解析不支持想用的一些SQL关键字比如regexp操作，或者生成的方法名太丑了，你可以使用命名查询或者使用`@Query`方式。
### 查询创建
通过方法名生成查询的例子在上面，下面是一个例子
```java
public interface UserRepository extends Repository<User, Long> {

  List<User> findByEmailAddressAndLastname(String emailAddress, String lastname);
}
```
我们使用JPA criteria API创建了一个查询，本质上，上面的代码会翻译成下面的查询`select u from User u where u.emailAddress = ?1 and u.lastname = ?2`,Spring Data JPA会做属性检查，并且遍历嵌套的属性，正如在[Property Expressions](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.query-methods.query-property-expressions)章节。
下面的列表描述了JPA支持的SQL关键词翻译规则，参考文档上有，不写了。In/Not In支持任何Collection的子类作为参数，也支持数组与可变参数，DISTINCT比较难以处理，可能会产生非预期的结果，比如，`select distinct u from User u`相比`select distinct u.lastname from User u`会产生完全不同的结果，第一种情况，因为User.id必然不会相同，所以不会存在任何重复，第二个只是lastname，`countDistinctByLastname(String lastname)`也会产生非预期的结果，SDJ会翻译为`select count(distinct u.id) from User u where u.lastname = ?1`等同于`countByLastname(String lastname)`，使用distinct最好使用自定义查询并且使用投影来获取结果
### 使用JPA命名查询
```java
@Entity
@NamedQuery(name = "User.findByEmailAddress",
  query = "select u from User u where u.emailAddress = ?1")
public class User {
}
```
使用@NamedQuery或者@NameNativeQuery，下面的例子都使用了<named-query/>或者@NamedQuery注解，这些查询必须以JPA查询语言的方式定义，当然，也可以使用<named-native-query/>或者@NamedNativeQuery注解，这些元素可以让你以native SQL的方式定义查询，但是这样做丧失了数据库平台无关性。@NamedQuery的例子
```java
@Entity
@NamedQuery(name = "User.findByEmailAddress",
  query = "select u from User u where u.emailAddress = ?1")
public class User {
}
```
为了使用上面的命名查询，要在UserRepository接口中进行描述。
```java
public interface UserRepository extends JpaRepository<User, Long> {

  List<User> findByLastname(String lastname);

  User findByEmailAddress(String emailAddress);
}
```
Spring会尝试解析方法调用是否与命名查询相匹配，名字的匹配方式是domain classname.method name，当名字匹配时，接口中的findByEmailAddress方法就不会衍生SQL了，而是使用定义的命名查询。
### 使用@Query
优先级比@NamedQuery高,机制都一样。
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.emailAddress = ?1")
  User findByEmailAddress(String emailAddress);
}
```
#### 应用QueryRewriter
有时候，你可以在查询发送到`EntityManager`前重写查询，也就是你可以对最后的语句改写:
```java
public interface MyRepository extends JpaRepository<User, Long> {

		@Query(value = "select original_user_alias.* from SD_USER original_user_alias",
                nativeQuery = true,
				queryRewriter = MyQueryRewriter.class)
		List<User> findByNativeQuery(String param);

		@Query(value = "select original_user_alias from User original_user_alias",
                queryRewriter = MyQueryRewriter.class)
		List<User> findByNonNativeQuery(String param);
}
```
上面的例子展示了native sql与JPQL查询使用了相同的QueryRewriter，在这种场景下，SDJ会寻找这个类型的bean。
```java
public class MyQueryRewriter implements QueryRewriter {

     @Override
     public String rewrite(String query, Sort sort) {
         return query.replaceAll("original_user_alias", "rewritten_user_alias");
     }
}
```
你必须保证`QueryRewriter`注册到Application Context中的一个bean，要么使用`@Component`注解，要么使用`@Bean`。repo可以自己实现这个接口:
```java
public interface MyRepository extends JpaRepository<User, Long>, QueryRewriter {

		@Query(value = "select original_user_alias.* from SD_USER original_user_alias",
                nativeQuery = true,
				queryRewriter = MyRepository.class)
		List<User> findByNativeQuery(String param);

		@Query(value = "select original_user_alias from User original_user_alias",
                queryRewriter = MyRepository.class)
		List<User> findByNonNativeQuery(String param);

		@Override
		default String rewrite(String query, Sort sort) {
			return query.replaceAll("original_user_alias", "rewritten_user_alias");
		}
}
```

#### like的高级用法
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.firstname like %?1")
  List<User> findByFirstnameEndsWith(String firstname);
}
```
在这个例子中，LIKE标识符%会被识别到，查询会被翻译为一个有效的JPQL查询。
#### Native Queries
@Query中的nativeQuery标志可以标志语句是否是一个完全的SQL
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query(value = "SELECT * FROM USERS WHERE EMAIL_ADDRESS = ?1", nativeQuery = true)
  User findByEmailAddress(String emailAddress);
}
```
SDJ不支持native sql的动态排序，你可以声明native query来支持分页或者排序，使用本地查询完成分页的功能（但是不支持分页）
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query(value = "SELECT * FROM USERS WHERE LASTNAME = ?1",
    countQuery = "SELECT count(*) FROM USERS WHERE LASTNAME = ?1",
    nativeQuery = true)
  Page<User> findByLastname(String lastname, Pageable pageable);
}
```
### 排序
必须提供PageRequest或者Sort参数，主要是只用里面的Order实例，Order里面的属性必须是domain中的属性，或者属性的别名。
@Query与Sort组合使用，可以在排序中使用函数，默认情况下，SDJ会拒绝任何包含函数调用的Order，可以使用`JpaSort.unsafe`来添加坑的不安全的排序。如下：
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.lastname like ?1%")
  List<User> findByAndSort(String lastname, Sort sort);

  @Query("select u.id, LENGTH(u.firstname) as fn_len from User u where u.lastname like ?1%")
  List<Object[]> findByAsArrayAndSort(String lastname, Sort sort);
}

repo.findByAndSort("lannister", Sort.by("firstname")); // 有效的排序表达式               
repo.findByAndSort("stark", Sort.by("LENGTH(firstname)")); // 无效的排序表达式，包含函数调用，抛出异常           
repo.findByAndSort("targaryen", JpaSort.unsafe("LENGTH(firstname)")); // 有效的排序表达式，包含明确的unsafe order
repo.findByAsArrayAndSort("bolton", Sort.by("fn_len")); // 有效的排序表达式，包含别名函数              
```
### Scrolling Large Query Results
当遇到大数据集时，滚动可以有效的处理这种情况，不需要一次性把所有的结果都加入到内存中。你有多种办法来处理大量的查询结果。
- Paging
- Offset scrolling，这是比paging更轻量级的变体，因为不需要计算总数
- Keyset scrolling，加入索引机制的offset scrolling
  
参考[which method to use best](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.scrolling.guidance)，你可以在查询方法、QBE、Querydsl3种机制上使用Scroll API。直接定义查询的Scroll目前还不支持，使用存储过程查询方法也不支持scrolling
### 使用命名参数
默认使用基于位置的参数绑定，在重构时容易出错，为了解决这个问题，也可以使用@Param注解给定参数的名字并在查询中绑定，如下：
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findByLastnameOrFirstname(@Param("lastname") String lastname,
                                 @Param("firstname") String firstname);
}
```
如果你使用了java8的-parameters功能，可以不用使用@Param
### SpEL表达式
从Spring Data JPA 1.4版本开始，我们支持在@Query注解中手动定义的查询中使用有限的SpEL模板表达式，根据要执行的查询，这些表达式会在一个预定义的变量集合上解析，Spring Data JPA支持一个叫做`entityName`的变量，它的用法是
```sql
select x from #{#entityName} x
```
它会插入根据与给定的repo相关联的领域类型的`entityName`，entityName的解析方式：如果领域类型在`@Entity`注释上设置了name属性，则使用它。否则，使用领域类型的简单类名。下面的例子展示了在查询中使用`#{#entityName}`表达式的一种用例
```java
@Entity
public class User {
  @Id
  @GeneratedValue
  Long id;
  String lastname;
}
public interface UserRepository extends JpaRepository<User,Long> {
  @Query("select u from #{#entityName} u where u.lastname = ?1")
  List<User> findByLastname(String lastname);
}
```
entityName可以通过@Entity注解定义，orm.xml中的定义不支持SpEL表达式。当然，你可以直接在查询声明中使用User。但是，使用`#{#entityName}`变量可以让你不需要在@Query注解中的查询书写实际的实体名，避免实体名变更需要重新修改（比如，通过使用@Entity(name="MyUser")定义逻辑实体的名字）。
在查询中使用`#{#entityName}`表达式的另一个用例是当你想要定义一个通用的repo接口，这个通用的repo接口与具体的领域类型集合就是具体的repo接口。为了不在repo接口中重复定义相同逻辑的查询方法，你可以在通用的repo接口中@Query注解中的查询中使用`#{#entityName}`表达式，如下面的例子所示
```java
@MappedSuperclass
public abstract class AbstractMappedType {
  …
  String attribute
}
@Entity
public class ConcreteType extends AbstractMappedType { … }
@NoRepositoryBean
public interface MappedTypeRepository<T extends AbstractMappedType>
  extends Repository<T, Long> {
  @Query("select t from #{#entityName} t where t.attribute = ?1")
  List<T> findAllByAttribute(String attribute);
}
public interface ConcreteRepository
  extends MappedTypeRepository<ConcreteType> { … }
```
在上面的例子中，`MappedTypeRepository`接口是所有继承于`AbstractMappedType`的domain class的共同的父接口，它也定义了通用的`findAllByAttribye(…)`方法，可以在专门的repo接口上使用这个方法，如果你现在调用`ConcreteRepository`的`findAllByAttribye`方法，生成的查询是`select t from ConcreteType t where t.attribute = ?1`，SpEL表达式也可以用来处理方法参数，在这种SpEL表达式中，entity name不允许使用，但是可以使用方法的参数，可以通过参数的名字或者索引使用参数，如下面的例子所示
```java
@Query("select u from User u where u.firstname = ?1 and u.firstname=?#{[0]} and u.emailAddress = ?#{principal.emailAddress}")
List<User> findByFirstnameAndCurrentUserWithCustomQuery(String firstname);
```
对于like条件来说，开发者通常都会想要在一个字符串值的2边加上%通配符，这样可以通过SpEL表达式与%符号实现
```java
@Query("select u from User u where u.lastname like %:#{[0]}% and u.lastname like %:lastname%")
List<User> findByLastnameWithSpelExpression(@Param("lastname") String lastname);
```
当使用like条件时，like的值可能来自于不安全的输入，所以应该被转义处理防止它们包含一些通配符或者关键词，这样攻击者可能会访问到比正常情况下更多的数据；为了处理这种情况，在SpEL上下文中可以使用`escape(Strring)`方法，它在第一个参数中的所有_和%字符前面加上第二个参数指定的单个字符。在JPQL与SQL中，escape与like表达式相结合保证了绑定参数的简洁可用。如下面的例子:
```java
@Query("select u from User u where u.firstname like %?#{escape([0])}% escape ?#{escapeCharacter()}")
List<User> findContainingEscaped(String namePart);
```
当声明了上面repo的查询方法，那么`findContainingEscaped("Peter_”)`将会查询到`Peter_Parker`而不是`Peter Parker`，使用的转义字符可以通过`@EnableJpaRepositories`注解的`escapeCharacter`属性设置配置，请注意，`escape(String)`只在SpEL上下文中可用，只会转义SQL和JPQL标准通配符_和%。如果底层数据库或 JPA实现支持其他通配符，则这些通配符不会被转义。
### Other Methods
SDJ提供了很多种构建查询的方式，对于很复杂的查询，你可以:
- 使用`@Query`
- [自定义实现repo](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.custom-implementations)。
  - 直接与EntityManager交互，可以直接写HQL/JPQL/EQL/SQL或者使用Criteria API
  - 直接使用Spring Framework的JdbcTemplate
  - 使用任何第三方的数据库工具
- 创建存储过程或者函数，使用SDJ的`@StoredProcedure`注解或者直接调用函数

当你想要更多的控制查询的时候，这些策略可能很有效。
### Modifying Queries
所有前面的章节讲述了如何声明查询。你可以通过[Custom Implementations for Spring Data Repositories](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.custom-implementations)中介绍的自定义实现机制加入自定义的修改行为。如果修改只是简单的参数绑定，你还可以在查询方法上加入注解`@Modifying`，如下面所示:
```java
@Modifying
@Query("update User u set u.firstname = ?1 where u.lastname = ?2")
int setFixedFirstnameFor(String firstname, String lastname);
```
将查询设置为更新而不是检索，因为`EntityManager`可能在执行修改查询后可能包含过期的实体，我们并不会自动清空它，这个注解会丢弃掉所有`EntityManager`中的没有flush的是实体。如果你想要`EntityManager`可以自动清空，你可以设置`@Modifying`注解的`clearAutomatically=true`。`@Modifying`注解只能与`@Query`注解组合使用，不能用于派生查询或者自定义方法。
### Derived Delete Queries
SDJ支持派生删除操作，不需要明确的声明JPQL，如下所示:
```java
interface UserRepository extends Repository<User, Long> {
  void deleteByRoleId(long roleId);
  @Modifying
  @Query("delete from User u where u.role.id = ?1")
  void deleteInBulkByRoleId(long roleId);
}
```
看起来上面2种方法的效果一样，但是就运行的方式而言，2种方法区别很大，后面的方法声明一个JPQL，这意味着当前加载的User实例不会被调用生命周期的方法。为了调用声明周期方法，第一种会先执行一个查询，得到所有实体后再一个一个执行删除，然后其中会调用生命周期的方法。派生删除就是先查询出实体，然后调用`CrudRepository.delete(Iterable<User> users)`，
### 应用查询提示
为了给repo接口中声明的查询应用JPA查询提示，你可以使用@QueryHints注解，这个注解使用一个JPA`@QueryHint`注解数组与一个boolean类型标志，标志用于指定在分页查询时查询总数时否应用查询提示的标志，如下面的代码所示:
```java
public interface UserRepository extends Repository<User, Long> {

  @QueryHints(value = { @QueryHint(name = "name", value = "value")},
              forCounting = false)
  Page<User> findByLastname(String lastname, Pageable pageable);
}
```
### Adding Comments to Queries
有时候，你需要debug一个查询来查看数据库性能，但是具体的SQL与SDJ生成的最终SQL可能看起来不是很相似，为了能找到具体的SQL，你可以给查询添加注释，使用注解`@Meta`，代码如下:
```java
public interface RoleRepository extends JpaRepository<Role, Integer> {

	@Meta(comment = "find roles by name")
	List<Role> findByName(String name);

	@Override
	@Meta(comment = "find roles using QBE")
	<S extends Role> List<S> findAll(Example<S> example);

	@Meta(comment = "count roles for a given name")
	long countByName(String name);

	@Override
	@Meta(comment = "exists based on QBE")
	<S extends Role> boolean exists(Example<S> example);
}
```
JPQL/SQL日志都不是JPA中的标准，每个JPA实现提供者需要自定义日志配置。为了激活hibernate的query注释，你需要设置`hibernate.use_sql_comments=true`。
```java
@Bean
public Properties jpaProperties() {

	Properties properties = new Properties();
	properties.setProperty("hibernate.use_sql_comments", "true");
	return properties;
}
```
如果使用spring boot，你可以设置属性:
>spring.jpa.properties.hibernate.use_sql_comments=true

eclipselink的实现忽略了。这个可能需要更高的版本。
### Configuring Fetch-and LoadGraphs
### Projections
Spring Data查询方法通常会返回Repo管理的聚合根的一个或者多个实例，然而，有时候需要依据聚合根的某些特定的属性创建投影，Spring Data可以返回特定的聚合根的投影类型，这种类型是聚合根的特定部分的视图。比如如下的Repository与聚合根。
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
现在假设我们只想检索人员的name属性，怎么办呢？
#### 基于接口的投影
最简单的方式就是接口投影的方式，接口暴漏属性的访问器方法，如下：
```java
interface NamesOnly {
  String getFirstname();
  String getLastname();
}
```
需要注意的地方是这里定义的属性访问器方法与聚合根中的属性访问器方法是完全一样，定义的查询方法如下：
```java
interface PersonRepository extends Repository<Person, UUID> {

  Collection<NamesOnly> findByLastname(String lastname);
}
```
查询执行引擎在运行时会为每个条目创建接口的代理实例，对访问器的访问会被转发到目标对象上。在Repository中声明的方法如果覆盖基类接口中的方法（比如在CrudRepository、特定于存储的存储库接口或Simple…Repository接口中声明的方法）会导致对基本方法的调用，无论声明的返回类型如何。 确保使用兼容的返回类型，因为基方法不能用于投影。 一些存储模块支持 @Query 注释，将重写的基本方法转换为查询方法，然后可用于返回投影。投影是可以递归进行的，如果你想要包含Address的信息，可以创建一个Address接口的投影信息，如下：
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
方法调用时，目标实例的address属性被获取并且被包装到一个投影代理里面。投影接口的访问器方法与聚合根的属性访问器完全匹配的投影接口叫做封闭式投影接口，上面的例子就是封闭式投影。如果你使用封闭式投影，Spring Data可以优化查询执行，因为我们知道要查询的所有的属性，而且这些属性都会都会被包装到投影接口代理中，更多的信息，可以看参考文档。
不匹配的叫做开放式投影，投影接口的访问器方法必须使用`@Value`注解标注，如下：
```java
interface NamesOnly {
  @Value("#{target.firstname + ' ' + target.lastname}")
  String getFullName();
}
```
投影代理后面的聚合根就是`target`变量，开放式投影不能使用查询优化，因为SpEL表达式可能会使用聚合根中的任何属性。@Value中的表达式不要太复杂。你不太可能想要String的编程，对于简单的表达式，可以借助default方法的方式完成。
```java
interface NamesOnly {

  String getFirstname();
  String getLastname();

  default String getFullName() {
    return getFirstname().concat(" ").concat(getLastname());
  }
}
```
这种方式你只能选择投影接口暴漏出来的方法实现拼接逻辑，还有另外一种方法更灵活一些，定义一个Spring Bean实现自定义的逻辑，然后通过SpEL表达式调用这段逻辑，如下：
```java
@Component
class MyBean {

  String getFullName(Person person) {
  }
}
interface NamesOnly {
  @Value("#{@myBean.getFullName(target)}")
  String getFullName();
}
```
需要注意SpEL是如何引用myBean并调用`getFullName(...)`方法的，注意bean中方法的参数是聚合根实例。投影接口的方法上的SpEL表达式也可以使用方法参数，方法参数是一个名叫args的Object对象数组，表达式中通过args[0,1,2]的方式引用，下面是一个例子:
```java
interface NamesOnly {
  @Value("#{args[0] + ' ' + target.firstname + '!'}")
  String getSalutation(String prefix);
}
```
对于更复杂的表达式，你应该使用Spring Bean，并通过SpEL调用调用Bean的方法的形式操作。
投影接口里面的访问器方法可以返回null安全的数据，支持的null包装类型如下
- java.util.Optional
- com.google.common.base.Optional
- scala.Option
- io.varr.control.Option
如下：
```java
interface NamesOnly {
  Optional<String> getFirstname();
}
```
如果底层的投影值不是null，返回值的包装形式，如果是null返回空。
#### 基于类的投影(DTOs)
另一种定义投影的方式是使用DTO，里面包含要被检索的属性，与投影接口的使用方法差不多，区别就是DTO方式不会产生代理，也不支持嵌套的投影，如果底层存储通过限定要加载的字段的方式优化查询执行，要被加载的字段必须通过构造函数的参数名字定义，下面是投影DTO的例子
```java
class NamesOnly {

  private final String firstname, lastname;

  NamesOnly(String firstname, String lastname) {

    this.firstname = firstname;
    this.lastname = lastname;
  }

  String getFirstname() {
    return this.firstname;
  }

  String getLastname() {
    return this.lastname;
  }
}
```
```java
record NamesOnly(String firstname, String lastname) {
}
```
Java Records是理想的定义DTO的方式，因为符合值的语义。所有的字段都是private final的，并且自动创建`equals()\hashCode()\toString()`方法。也可以自定义DTO。可以使用Lombok的@Value避免模板代码的生成。基于类的投影使用通过JPQL表达式的构造函数表达式方式使用。比如`SELECT new com.example.NamesOnly(u.firstname, u.lastname) from User u`记住DTO的FQDN使用，投影不能用于native查询。
#### 动态投影
到目前为止，我们已经使用投影类型作为返回类型与返回集合的元素类型，然而，你可能想要实际运行时决定返回的类型（返回的类型是动态），为了使用动态投影，代码如下：
```java
interface PersonRepository extends Repository<Person, UUID> {
  <T> Collection<T> findByLastname(String lastname, Class<T> type);
}
```
这种方式，方法获取聚合根时会根据传递的Class决定是返回聚合根还是返回投影类型。
```java
void someMethod(PersonRepository people) {

  Collection<Person> aggregates =
    people.findByLastname("Matthews", Person.class);

  Collection<NamesOnly> aggregates =
    people.findByLastname("Matthews", NamesOnly.class);
}
```
```java
void someMethod(PersonRepository people) {

  Collection<Person> aggregates =
    people.findByLastname("Matthews", Person.class);

  Collection<NamesOnly> aggregates =
    people.findByLastname("Matthews", NamesOnly.class);
}
```
检查`Class`类型的查询参数是否符合动态投影参数的条件。如果查询的实际返回类型等于`Class`参数的泛型参数类型，则匹配的 `Class`参数不可用于查询或SpEL表达式中。 如果您想使用`Class`参数作为查询参数，请确保使用不同的泛型参数，例如Class<?>。
### 存储过程
### 规格
JPA2版本加入了谓词API的支持，你可以通过编程的方式构造查询条件，通过书写criteria，你可以定义一个领域模型的查询子句，Spring Data JPA采用了领域驱动的概念，为了支持规格描述，你的repository需要扩展`JpaSpecificationExecutor`接口，如下所示
```java
public interface CustomerRepository extends CrudRepository<Customer, Long>, JpaSpecificationExecutor<Customer> {
}
```
接口提供了很多的使用spec查询的方法，例如，`findAll`方法
```java
List<T> findAll(Specification<T> spec);
```
Specification接口定义如下：
```java
public interface Specification<T> {
  Predicate toPredicate(Root<T> root, CriteriaQuery<?> query,
            CriteriaBuilder builder);
}
```
Specification常用来做可扩展的谓词集合，这样不需要定义单独的查询方法
```java
public class CustomerSpecs {


  public static Specification<Customer> isLongTermCustomer() {
    return (root, query, builder) -> {
      LocalDate date = LocalDate.now().minusYears(2);
      return builder.lessThan(root.get(Customer_.createdAt), date);
    };
  }

  public static Specification<Customer> hasSalesOfMoreThan(MonetaryAmount value) {
    return (root, query, builder) -> {
      // build query here
    };
  }
}
```
上面的`Customer_`类型是一个元模型，是使用JPA元模型生成器生成的，所以，表达式`Customer_.createdAt`表示`Customer`有一个Date类型的createdAt属性，除此以外，还有表示业务逻辑的谓词断言创建的可执行的Specification，使用Specification可以执行查询，如下：
```java
List<Customer> customers = customerRepository.findAll(isLongTermCustomer());
```
为什么不为这个查询创建一个查询方法，使用单一的Specification确实看起来没有多大收益，但是当有多个Specification组合起来查询时，它能表示的条件是普通的查询无法实现的，看下面的例子：
```java
MonetaryAmount amount = new MonetaryAmount(200.0, Currencies.DOLLAR);
List<Customer> customers = customerRepository.findAll(
  isLongTermCustomer().or(hasSalesOfMoreThan(amount)));
```
### QBE查询方式
QBE是一个用户友好的查询方式，可以动态的创建查询，事实上，QBE查询方式对底层查询SQL来说，是透明的。QBE的API包含3个部分
- Probe:领域对象的实际实例；
- ExampleMatcher:特定字段的匹配规则，多个Example之间可以复用;
- Example: 一个包含Example与ExampleMatcher的Example，用来创建查询；
下面的场景适合使用QBE
- 在静态或者动态的限制下查询数据;
- 领域对象需要频繁的重构，为了防止对现有的查询产生冲击;
- 独立与底层数据存储的API。
QBE的限制
- 不支持嵌套类或者分组类的限制条件，比如`firstname = ?0 or (firstname = ?1 and lastname = ?2)`;
- 对string来说只支持starts/contains/ends/regex匹配，其他类型只支持精确匹配。
在使用QBE前，你需要又个领域对象，比如下面的
```java
public class Person {

  @Id
  private String id;
  private String firstname;
  private String lastname;
  private Address address;

  // … getters and setters omitted
}
```
上面的事例展示了一个简单的领域对象，你可以使用它创建一个Example，默认情况下，对于null的字段会被忽略，string执行精确匹配；QBE构造查询条件是通过是否null来判断的，如果是基本类型，不可能是null，所以是一直包含在查询条件中的，下面的例子展示了构造Example的例子
```java
Person person = new Person();                         
person.setFirstname("Dave");                          
Example<Person> example = Example.of(person);         
```
你可以通过ExampleMatcher来自定义匹配的规则，下面是一个例子:
```java
Person person = new Person();                          
person.setFirstname("Dave");                           

ExampleMatcher matcher = ExampleMatcher.matching()     
  .withIgnorePaths("lastname")                         
  .withIncludeNullValues()                             
  .withStringMatcher(StringMatcher.ENDING);            

Example<Person> example = Example.of(person, matcher); 
```
上面的例子是过程
- 创建一个领域对象实例
- 设置领域对象实例的属性
- 创建一个ExampleMatcher，匹配所有的设置的值，在这个阶段就可用了;
- 创建一个ExampleMatcher，忽略lastname属性;
- 创建一个ExampleMatcher，忽略lastname属性，包含所有的null值;
- 创建一个ExampleMatcher，忽略lastname属性,包含所有的null值,字符串执行后缀匹配;
- 创建一个使用上述领域对象与ExampleMatcher的Example.
默认情况下，ExampleMatcher会匹配probe中设置的所有的值，也就是and条件，如果你想执行or条件，使用ExampleMatcher.matchingAny();你可以单独指定属性的行为，比如firstname、lastname、或者其他内嵌的属性，你可以调整它的匹配选项、大小写敏感等。例子如下：
```java
ExampleMatcher matcher = ExampleMatcher.matching()
  .withMatcher("firstname", endsWith())
  .withMatcher("lastname", startsWith().ignoreCase());
}
```
还有一种配置匹配选项的方式是使用lambda，这种方式会使用回调的方式然实现者自定义匹配逻辑，你不需要定义Matcher对象，因为配置选项已经在配置实例里面，例子如下：
```java
ExampleMatcher matcher = ExampleMatcher.matching()
  .withMatcher("firstname", match -> match.endsWith())
  .withMatcher("firstname", match -> match.startsWith());
}
```
Example创建的查询使用混合起来的设置，默认的匹配设置可以设置在ExampleMatcher级别，单独属性的设置会设置到特定的属性路径上，ExampleMatcher级别上的设置会被属性路径的设置继承，除非明确指定匹配规则，则会使用属性自己的设置，下面的表格展示了不同呢ExampleMatcher的设置的作用域。
|Setting|Scope|
|:---:|:---:|
|null处理|ExampleMatcher|
|String匹配|ExampleMatcher或者属性|
|igoring properties|属性|
|Case Sensitivity|ExampleMatcher或者属性|
|Value Transformation|属性|
在Spring Data JPA中，你可以在普通的Repository中使用QBE，比如：
```java
public interface PersonRepository extends JpaRepository<Person, String> { … }

public class PersonService {

  @Autowired PersonRepository personRepository;

  public List<Person> findPeople(Person probe) {
    return personRepository.findAll(Example.of(probe));
  }
}
```
属性描述符可以是属性的名字，或者是属性的.号分隔名字。
下面的表格中是不同的StringMatcher选项，你可以使用它们，下面是一个在firstname上的例子
|Matching|Logical Result|
|:---|:---|
|DEFAULT(cs)|firstname=?0|
|DEFAULT(ci)|LOWER(firstname)=LOWER(?0)|
|EXACT(cs)|firstname=?0|
|EXACT(ci)|LOWER(firstname) = LOWER(?0)|
|STARTING (case-sensitive)|firstname like ?0 + '%'|
|STARTING (case-insensitive)|LOWER(firstname) like LOWER(?0) + '%'|
|ENDING (case-sensitive)|firstname like '%' + ?0|
|ENDING (case-insensitive)|LOWER(firstname) like '%' + LOWER(?0)|
|CONTAINING (case-sensitive)|firstname like '%' + ?0 + '%'|
|CONTAINING (case-insensitive)|LOWER(firstname) like '%' + LOWER(?0) + '%'|
### 事务
默认情况下，repository实例中继承于SimpleJpaRepository接口的CRUD方法都是事务性的，对于读操作来说，事务配置readOnly=true，其他的配置与只使用@Transactional的配置相同，这是为了可以使用事务的默认配置，由事事务repository片段支持的repository方法从实际片段方法继承事务属性。
如果你想要调整repo、中一个方法的事务配置，只需要重新声明方法的事务就可以了，比如
```java
public interface UserRepository extends CrudRepository<User, Long> {

  @Override
  @Transactional(timeout = 10)
  public List<User> findAll();

  // Further query method declarations
}
```
另外一种变更事务行为的方法是，使用门面模式或者使用service实现的方式，通常来说他们都是涵盖多个repository，这个事务的目的是为了那些不是单纯的crud的操作定义事务的边界，下面的例子是一个含有多个repo的门面模式的例子
```java
@Service
public class UserManagementImpl implements UserManagement {

  private final UserRepository userRepository;
  private final RoleRepository roleRepository;

  public UserManagementImpl(UserRepository userRepository,
    RoleRepository roleRepository) {
    this.userRepository = userRepository;
    this.roleRepository = roleRepository;
  }

  @Transactional
  public void addRoleToAllUsers(String roleName) {

    Role role = roleRepository.findByName(roleName);

    for (User user : userRepository.findAll()) {
      user.addRole(role);
      userRepository.save(user);
    }
  }
}
```
这个例子让对方法`addRoleToAllUsers()`方法的调用运行在一个事务里面（参与到一个已存在的事务或者没有事务就创建一个新的事务），repository的事务配置会被忽略，因为外层的事务配置才是真正使用的事务。需要注意的是，你必须声明`<tx:annotation-driven />`或者声明`@EnableTransactionManagement`来明确的让门面上的注解事务配置生效，这个例子假设你使用了组件扫描。
需要注意的是，从JPA视角来看，没有必要调用save方法，但是接口中也应该提供save方法，这是为了保证spring data提供的repository接口定义的一致性。
#### 事务查询方法
为了给查询添加事务特性，在你定义的repository接口上声明`@Transactional`，如下面的例子所示
```java
@Transactional(readOnly = true)
interface UserRepository extends JpaRepository<User, Long> {

  List<User> findByLastname(String lastname);

  @Modifying
  @Transactional
  @Query("delete from User u where u.active = false")
  void deleteInactiveUsers();
}

```
通常，您希望将 readOnly 标志设置为 true，因为大多数查询方法只读取数据。 与此相反，`deleteInactiveUsers()`使用 `@Modifying`注释这会覆盖事务配置。 因此，该方法运行时，readOnly配置是false。
你可以在只读查询上使用事务，并通过设置`readOnly=true`来标记它们，但是，这么做并不能保证你不会触发一个变更查询（虽然有的数据拒绝在只读事务中执行insert或者update语句），但是readOnly标记可以作为一个提示传播到底层的JDBC驱动中，驱动程序可以用来做性能优化。此外spring对底层的JPA提供程序做了一些优化。比如：当与Hibernate一起使用时，当事务被配置为`readOnly=true`时，flush modo会被设置为NEVER，这会让Hibernate跳过脏检查（对大量的对象树的检索会带来明显的提升）
### Locking
为了指定要使用的lock模式，你可以在查询方法上使用@Lock注解，如下面的代码所示
```java
interface UserRepository extends Repository<User, Long> {

  // Plain query method
  @Lock(LockModeType.READ)
  List<User> findByLastname(String lastname);
}
```
这个方法声明使得查询使用LockModeType=READ的方式执行查询，你可以可以在repository接口上声明lock或者在方法上声明，如下面的例子所示
```java
interface UserRepository extends Repository<User, Long> {

  // Redeclaration of a CRUD method
  @Lock(LockModeType.READ)
  List<User> findAll();
}

```
### Auditing审计
Spring Data 提供了成熟的审计支持，这些支持可以对entity的创建/变更保持透明的及时的跟踪。为了使用这些功能，你必须给你的实体类添加有关审计的元数据信息，可以使用注解的形式或者实现指定的接口。另外，审计功能需要一些注解配置或者XML配置才能开启，这些配置需要注册一些需要的基础组件。请参考配置案例中的store-specific章节。只需要跟踪创建/修改日期的应用不需要指定任何的AuditorAware。
1. 基于注解的审计元数据
我们提供了@CreatedBy、@LastModifiedBy来捕获创建与修改实体的用户，@CreatedDate、@LastModifiedDate用来捕获发生变更的时间。
```java
class Customer {

  @CreatedBy
  private User user;

  @CreatedDate
  private Instant createdDate;

  // … further properties omitted
}

```
正如你看到的，注解是有选择性的应用的，这依赖于你想要捕获信息的类型，捕获变更发生时间的注解可以使用在Joda-Time、DateTIme、传统的Date、Calendar、JDK8的日期时间类型、long或者Long类型的属性上。审核元数据不一定需要存在于根级别实体中，也可以添加到嵌入式实体中（取决于实际使用的存储），如下面的片段所示。、
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
2. 基于接口的审计元数据
如果您不想使用注解来定义审计元数据，您可以让您的entity类实现 Auditable 接口。 它暴漏了所有审计属性的 setter 方法。
3. AuditorAware
在使用@CreatedBy与@LastModifiedBy的场景，审计的基础组件需要以某种方式知晓当前登录的用户信息，为了达到这个目的，我们提供了AuditorAware<T> 服务提供者接口，你必须实现这个接口告诉基础组件当前登录的用户或者当前使用的系统等，泛型类型T必须是使用@CreatedBy或者@LastModifiedBy注解标注的属性的类型。
下面是接口实现的一个例子，这个例子使用了Spring Security的Authentication对象
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
上面的实现访问Spring Security框架提供的Authentication对象，并且会寻找自定义的UserDetails实例，这个实例是通过UserDetailsService接口实现提供的。
4. ReactiveAuditorAware
当使用reactive基础设施时，你可能想要使用上下文信息提供@CreatedBy或者@LastModifiedBy需要的信息。我们提供了ReactiveAuditorAware<T> SPI接口，你可以实现这个接口来告诉基础设施，当前登录的用户或者系统是谁。与上面的例子是一样的。
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
### JPA Auditing
1. 普通的Auditing配置
Spring Data JPA提供了entity监听器，这个监听器可以用来触发捕获审计信息的操作，首先，为了所有的实体都可以使用到这个entity监听器，你必须注册AuditingEntityListener在你的orm.xml文件中，如下所示
```xml
<persistence-unit-metadata>
  <persistence-unit-defaults>
    <entity-listeners>
      <entity-listener class="….data.jpa.domain.support.AuditingEntityListener" />
    </entity-listeners>
  </persistence-unit-defaults>
</persistence-unit-metadata>
```
如果只想在某个实体上应用`AuditingEntityListener`，可以使用@EntityListeners注解，如下所示
```java
@Entity
@EntityListeners(AuditingEntityListener.class)
public class MyEntity {

}
```
设计功能需要spring-aspects的支持。
orm.xml的方式非常容易修改变更，激活审计功能只需要添加Spring Data JPA的auditing空间元素到配置中，如下:
```xml
<jpa:auditing auditor-aware-ref="yourAuditorAwareBean" />
```
从spring Data JPA 1.5版本开始，你可以通过@EnableJpaAuditing注解开启审计，
```java
@Configuration
@EnableJpaAuditing
class Config {

  @Bean
  public AuditorAware<AuditableUser> auditorProvider() {
    return new AuditorAwareImpl();
  }
}
```
如果你的应用上下文中存在AuditorAware类型的bean，审计的基础组件会自动使用这个bean来决定当前登录的用户；如果你的ApplicationContext中有多个实现或者多个bean，你可以通过@EnableJpAAuditing的auditorAwareRef属性明确的指定选择使用的AuditorAware实例。
## 其他注意事项
### 在自定义的实现中使用JpaContext
当环境中有多个EntityManager类型的实例或者有自定义的repository实现时，你需要讲正确的EntityManager注入到repository的实现类中去；你也可以在@PersistenceContext注解中明确的指定EntityManager的名字，或者如果EntityManager是自动注入的，那么使用@Qualifier。从Spring Data JPA 1.9版本后，Spring Data JPA引入了一个叫做JpaContext的类，可以让你通过领域类来获得与其相关的EntityManager。我们假设一个领域类只会被应用中的一个EntityManager实例管理。下面的例子是如何在自定义的repository中使用JpaContext的方法。
```java
class UserRepositoryImpl implements UserRepositoryCustom {

  private final EntityManager em;

  @Autowired
  public UserRepositoryImpl(JpaContext context) {
    this.em = context.getEntityManagerByManagedType(User.class);
  }

  …
}

```
这种方式的优势就是：假如领域类型被重新分配到一个不同的存储单元，那么repository不需要修改它的存储单元引用。
### 合并持久性单元
Spring支持多种持久性单元。然而有时候，你想要模块化你的应用但是所有的模块还是运行在一个单一的持久性单元上，为了支持这个特性，Spring Data JPA提供了PersistenceUnitManager类的实现。可以自动的基于持久性单元的名字来合并持久性单元，如下面的例子所示
```java
<bean class="….LocalContainerEntityManagerFactoryBean">
  <property name="persistenceUnitManager">
    <bean class="….MergingPersistenceUnitManager" />
  </property>
</bean>
```
一个普通的JPA应用建立过程，需要所有注解映射的类都列在orm.xml文件中，对于XML映射文件也是同样的道理；Spring Data JPA提供了ClasspathScanningPersistenceUnitPostProcessor，使用这个类后，可以配置base package，并且可以配置映射的文件名模式，使用这个bean后，应用会扫描配置的package中使用注解@Entity与@MappedSuperclass注解的类，与文件名模式匹配的配置文件。post-processor的配置方式如下：
```xml
<bean class="….LocalContainerEntityManagerFactoryBean">
  <property name="persistenceUnitPostProcessors">
    <list>
      <bean class="org.springframework.data.jpa.support.ClasspathScanningPersistenceUnitPostProcessor">
        <constructor-arg value="com.acme.domain" />
        <property name="mappingFileNamePattern" value="**/*Mapping.xml" />
      </bean>
    </list>
  </property>
</bean>
```
### CDI Integration
Repository接口的实例通常都是由容器创建的，所以当使用Spring Data的时候，使用Spring也是非常合适的。Spring为创建bean实例提供了成熟的支持，就像在[Creating Repository Instances](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.create-instances)文档中所示。从1.1.0版本开始，Spring Data JPA提供了自定义的CDI扩展，允许在CDI环境中使用repository抽象定义。扩展是JAR包的一部分。
您现在可以通过为 EntityManagerFactory 和 EntityManager 实现 CDI 生产者来设置基础架构，如以下示例所示：
```java
class EntityManagerFactoryProducer {

  @Produces
  @ApplicationScoped
  public EntityManagerFactory createEntityManagerFactory() {
    return Persistence.createEntityManagerFactory("my-persistence-unit");
  }

  public void close(@Disposes EntityManagerFactory entityManagerFactory) {
    entityManagerFactory.close();
  }

  @Produces
  @RequestScoped
  public EntityManager createEntityManager(EntityManagerFactory entityManagerFactory) {
    return entityManagerFactory.createEntityManager();
  }

  public void close(@Disposes EntityManager entityManager) {
    entityManager.close();
  }
}
```
# 附录D: Repository查询返回类型（支持的查询返回类型）
下面的表格列出了Spring Data Repositories普遍支持的返回类型，但是，你可以参考特定存储的参考文档来了解明确支持的返回类型的列表，因为，这里列出的一些类型可能在某些存储上是不支持的。Geospatial类型（比如GeoResult、GeoResults、GeoPage）只有那些支持地理信息查询的数据存储才可用，一些存储模块可能定义了它们自己的包装类型。
|return type|描述|
|:---|:---|
|void|没有返回值|
|Primitives|java原始数据类型|
|Wrapper types|Java包装数据类型|
|T|一个独一无二的实体，查询方法最多只会返回一个记录，如果没有记录，返回null，超过1个返回记录会触发IncorrectResultSizeDataAccessException异常|
|Iterator<T>|一个迭代器|
|Collection<T>|一个集合容器|
|List<T>|一个列表|
|Optional<T>|一个Java8或者Guava的Optional对象，查询方法最多返回1条数据，没有数据返回Optional.empty(),超过1条数据会触发IncorrectResultSizeDataAccessException异常|
|Option<T>|一个Scala或者Vavr的Option类型，语法上与Java8的Optional差不多|
|Stream<T>|java8的stream类型|
|Streamable<T>|一个Iterable的扩展类型，具有很多stream接口的方法|
|实现Streamable接口的类型，含有一个Streamable参数的构造函数的类型，或者含有一个Streamable参数的静态方法的类型|这些类型，含有一个构造函数，或者有of、valueOf等工厂方法，它们都有一个Streamable的参数，可以参考[Returning Custom Streamable Wrapper Types](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.collections-and-iterables.streamable-wrapper)获得更多的细节|
|Vavr库的Seq、List、Map、Set|vavr的集合类型，可以参考[Support for Vavr Collections](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.collections-and-iterables.vavr)|
|Future<T>|一个Future，查询方法必须使用@Async注解并且必须开启了Spring异步执行方法的功能|
|CompletableFuture<T>|一个Java8的CompletableFuture，方法必须使用@Async注解并且必须开启了Spring异步执行方法的功能|
|ListenableFuture|一个org.springframework.util.concurrent.ListenableFuture类型的对象，查询方法必须使用@Async注解并且必须开启了Spring异步执行方法的功能|
|Slice<T>|一个特定大小的数据块包含是否还有更多的数据的一些信息，需要方法参数中有Pageable|
|Page<T>|一个带有额外新的Slice，比如结果的总数，需要方法参数中有Pageable|
|GeoResult<T>|带有额外信息的结果实体，比如位置的距离等|
|GeoResults<T>|GeoResult<T>结果的列表，含有一些额外的信息，比如平均距离等|
|GeoPage<T>|一个带有GeoResult<T>的Page，比如引用位置的平均距离等|
|Mono<T>|Reactor的Mono类型，表示0个或者1个元素，查询方法预定最多返回一个记录，如果没有记录，返回Mono.empty(),返回多于一条会触发IncorrectResultSizeDataAccessException异常|
|Flux<T>|Reactor的Flux类型，表示0或者多个元素，与Flowable类型类似，可以表示无限数量的元素|
|Single<T>|Rxjava的Single类型，使用呢reactive repository时表示一个元素，预期查询方法最多返回一条记录，如果没有记录返回，返回Mono.empty()，返回多于一条会触发IncorrectResultSizeDataAccessException异常|
|Maybe<T>|Rxjava的Maybe类型，使用reactive repository时表示0个或者1个元素，查询方法预定最多返回一个记录，如果没有记录，返回Mono.empty(),返回多于一条会触发IncorrectResultSizeDataAccessException异常|
|Flowable<T>|使用reactive repository可以使用Rxjava的Flowable类型表示0个或者多个元素，返回Flowable的查询可以表示无限数量的元素|
