# 前言
Spring data jpa实现了JPA（Java Persistence API），简化了数据库应用的开发工作。
# Spring Data如何工作
Spring data抽象的目标就是为各种各样的持久存储减少数据访问的模板代码。
## 核心概念
核心接口就是Repository，这个主要就是一个标记接口，细致化的CRUD要使用CrudRepository。
```java
public interface CrudRepository<T, ID> extends Repository<T, ID> {

  <S extends T> S save(S entity);      

  Optional<T> findById(ID primaryKey); 

  Iterable<T> findAll();               

  long count();                        

  void delete(T entity);               

  boolean existsById(ID primaryKey);   

  // … more functionality omitted.
}
```
## 定义查询方法
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
这一章主要讲解spring data jpa的特点，这建立在核心概念“仓库”上，你需要充分的理解这里讲述的基本概念。
## 引言
这一个节讲述jpa的基本动心
- XML配置，忽略
- 基于注解的配置，代码如下：
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
你必须创建一个LocalContainerEntityManagerFactoryBean，不要直接创建EntityManagerFactory，因为前面比后面自动加入了异常翻译机制。上面的配置类，使用呢HSQL作为数据库，然后设置了一个EntityManagerFactory，并使用Hibernate作为简单的持久化提供者，最后的基础组件是JpaTransactionManager，最后，例子使用@EnableJpaRepositories注解激活了JPA的仓库功能，如果没有指定包，默认是配置类所在的包。
- 引导模式，默认情况下，JPA仓库既是Spring管理的bean，它们是单例的声明周期并且初始化比较早。在启动过程中，它们就被EntityManager使用作为验证与元数据分析工作，Spring支持EntityManagerFactory的后台初始化，因为EntityManagerFactory的初始化比较耗时，为了让后台初始化有效，我们需要确保JPA仓库在比较后面初始化。Spring data 2.1版本后，你可以通过注解或者XML的方式配置BootstrapMode，可能的值如下：
    - DEFAULT，早期初始化，除非用@lazy指定，如果存在依赖，也会先初始化。
    - LAZY，所有的repo都是懒加载的，注入其他bean的都是懒加载的代理Bean，这意味着，如果只是作为一个field注入而没有用到repo的方法，repo就没有真正的初始化，repo只有在第一次使用时才会实例化并验证。
    - DEFERRED，模式与LAZY差不多，但是仓库在收到ContextRefreshEvent事件后会被初始化，所以，仓库会在应用启动前被验证。
- 建议，如果你的JPA启动不是异步的，那么用默认模式，如果是异步模式，那么用DEFERRED模式，因为JPA仓库实例化只会等待EntityManagerFactory设置完之后，它会确保在程序启动前，所有的仓库得到合理的初始化与验证，LAZY模式主要用于测试场景与本地开发的场景，只要你确定你的仓库是完美启动的，或者你只要测试仓库中的一个或者某个，不需要其他仓库实例化，这样可以节省启动的时间。
## 持久化实体
存储实体通过save()方法，底层用的EntityManager，如果实体是第一次存储，EntityManager会使用persist()方法，否则使用merge()方法。
判断实体是否是新的，有3种方法，可以看文档。
## 查询方法
- 查询查找策略，JPA支持2种查询方式，一种是直接执行SQL，一种是SQL通过方法名字衍生出来的SQL；衍生查询会使用很多谓词来处理方法的参数，这意味着如果参数里面出现了SQL的敏感词，会使用@EnableJpaRepositories里面的escapeCharacter转义。
- 声明查询，虽然通过方法名生成查询很方便，但是有些场景下也不好，比如，方法名解析不支持想用的一些SQL关键字比如regexp操作，或者生成的方法名太丑了，你可以使用命名查询或者使用@Query方式。
- 查询创建，通过方法名生成查询的例子在上面，下面是一个例子
```java
public interface UserRepository extends Repository<User, Long> {

  List<User> findByEmailAddressAndLastname(String emailAddress, String lastname);
}
```
我们使用JPA的规则创建了一个查询，但是本质上，使用的查询是
```sql
select u from User u where u.emailAddress = ?1 and u.lastname = ?2
```
下面的列表描述了JPA支持的SQL关键词翻译规则，参考文档上有，不写了。
- 使用JPA命名查询，使用@NamedQuery或者@NameNativeQuery，@NamedQuery的例子
```java
@Entity
@NamedQuery(name = "User.findByEmailAddress",
  query = "select u from User u where u.emailAddress = ?1")
public class User {
}
```
为了使用上面的命名查询
```java
public interface UserRepository extends JpaRepository<User, Long> {

  List<User> findByLastname(String lastname);

  User findByEmailAddress(String emailAddress);
}
```
这样接口种的findByEmailAddress方法就不会衍生SQL了，而是使用定义的命名查询。
- 使用@Query，优先级比@NamedQuery高
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.emailAddress = ?1")
  User findByEmailAddress(String emailAddress);
}
```
like的高级用法
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.firstname like %?1")
  List<User> findByFirstnameEndsWith(String firstname);
}
```
@Query中的nativeQuery标志可以标志语句是否是一个完全的SQL
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query(value = "SELECT * FROM USERS WHERE EMAIL_ADDRESS = ?1", nativeQuery = true)
  User findByEmailAddress(String emailAddress);
}
```
使用本地查询完成分页的功能（但是不支持分页）
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query(value = "SELECT * FROM USERS WHERE LASTNAME = ?1",
    countQuery = "SELECT count(*) FROM USERS WHERE LASTNAME = ?1",
    nativeQuery = true)
  Page<User> findByLastname(String lastname, Pageable pageable);
}
```
- 排序,必须提供PageRequest或者Sort参数，主要是只用里面的Order实例，Order里面的属性必须是domain中的属性，或者属性的别名。
@Query与Sort组合使用，可以在排序中使用函数，如下：
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.lastname like ?1%")
  List<User> findByAndSort(String lastname, Sort sort);

  @Query("select u.id, LENGTH(u.firstname) as fn_len from User u where u.lastname like ?1%")
  List<Object[]> findByAsArrayAndSort(String lastname, Sort sort);
}

repo.findByAndSort("lannister", Sort.by("firstname"));                
repo.findByAndSort("stark", Sort.by("LENGTH(firstname)"));            
repo.findByAndSort("targaryen", JpaSort.unsafe("LENGTH(firstname)")); 
repo.findByAsArrayAndSort("bolton", Sort.by("fn_len"));               
```
- 使用命名参数，默认使用基于位置的参数，也可以使用@Param注解给定参数的名字，如下：
```java
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findByLastnameOrFirstname(@Param("lastname") String lastname,
                                 @Param("firstname") String firstname);
}
```
如果你使用了java8的-parameters功能，可以不用使用@Param
- 使用SpEL表达式，
- 修改SQL，
# JPA仓库
## 投影
Spring Data查询方法通常会返回仓库管理的聚合根的一个或者多个实例，然而，有时候需要一句聚合根的某些特定的属性创建投影，Spring Data可以返回特定的聚合根的投影类型。比如如下的仓库与聚合根。
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
### 基于接口的投影
最简单的方式就是接口投影的方式，接口暴漏属性的访问器方法，如下：
```java
interface NamesOnly {
  String getFirstname();
  String getLastname();
}
```
需要注意的地方是没这里定义的属性访问器方法与聚合根中的属性访问器方法是完全相同的，定义的查询方法如下：
```java
interface PersonRepository extends Repository<Person, UUID> {

  Collection<NamesOnly> findByLastname(String lastname);
}
```
查询执行引擎在运行时会为每个条目创建接口的代理实例，对访问器的访问会被转发到目标对象上。投影是可以递归进行的，如果你想要包含Address的信息，可以创建一个Address接口的投影信息，如下：
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
方法调用是，目标实例的address属性被获取并且被包装到一个投影代理里面。投影接口的访问器方法与聚合根的属性访问器完全匹配的投影接口叫做封闭式投影，上面的例子就是封闭式投影。如果你使用封闭式投影，Spring Data可以优化查询执行，因为我们知道所有的属性都会被包装到投影接口代理中，更多的信息，可以看参考文档。
不匹配的叫做开放式投影，投影接口的访问器方法必须使用@Value注解标注，如下：
```java
interface NamesOnly {
  @Value("#{target.firstname + ' ' + target.lastname}")
  String getFullName();
  …
}
```
聚合根就是target变量，开放式投影不能使用查询优化。@Value中的表达式不要太复杂。你不太可能想要String的编程，对于简单的表达式，可以借助default方法的方式完成。
```java
interface NamesOnly {

  String getFirstname();
  String getLastname();

  default String getFullName() {
    return getFirstname().concat(" ").concat(getLastname());
  }
}
```
这种方式你只能选择投影接口暴漏出来的方法实现拼接逻辑，还有另外一种方法更灵活一些，在一个定义的SpringBean中实现拼接逻辑，然后通过SpEL表达式调用这段逻辑，如下：
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
需要注意SpEL是如何引用myBean并调用getFullName(...)方法的，投影接口的方法也可以有参数，并在表达式中使用，表达式中通过args[0,1,2]的方式引用
```java
interface NamesOnly {

  @Value("#{args[0] + ' ' + target.firstname + '!'}")
  String getSalutation(String prefix);
}
```
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
### 基于类的投影
另一种定义投影的方式是使用DTO，里面包含要被检索的属性，与投影接口的使用方法差不多，区别就是DTO方式不会产生代理，也不支持嵌套的投影，下面是DTO的例子
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

  // equals(…) and hashCode() implementations
}
```
可以使用Lombok的@Value避免模板代码的生成
### 动态投影
到目前为止，我们已经使用投影类型作为返回类型与返回集合的元素类型，然而，你可能想要实际运行时决定返回的类型（返回的是动态），为了使用动态投影，代码如下：
```java
interface PersonRepository extends Repository<Person, UUID> {

  <T> Collection<T> findByLastname(String lastname, Class<T> type);
}
```
这种方式，方法获取聚合根时会自动应用类型投影
```java
void someMethod(PersonRepository people) {

  Collection<Person> aggregates =
    people.findByLastname("Matthews", Person.class);

  Collection<NamesOnly> aggregates =
    people.findByLastname("Matthews", NamesOnly.class);
}
```