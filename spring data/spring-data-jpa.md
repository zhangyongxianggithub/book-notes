[TOC]
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
JPA模块支持手动以一个字符串的方式定义一个查询或者从方法名衍生。
- 查询查找策略，JPA支持2种查询方式，一种是直接执行SQL，一种是SQL通过方法名字衍生出来的SQL；衍生查询会使用很多谓词来处理方法的参数，这意味着如果参数里面出现了SQL的敏感词，会使用@EnableJpaRepositories里面的escapeCharacter转义。
- 声明查询，虽然通过方法名生成查询很方便，但是有些场景下也不好，比如，方法名解析不支持想用的一些SQL关键字比如regexp操作，或者生成的方法名太丑了，你可以使用命名查询或者使用@Query方式。
- 查询创建，通过方法名生成查询的例子在上面，下面是一个例子
```java
public interface UserRepository extends Repository<User, Long> {

  List<User> findByEmailAddressAndLastname(String emailAddress, String lastname);
}
```
我们使用JPA criteria API创建了一个查询，本质上，上面的代码会翻译成下面的查询`select u from User u where u.emailAddress = ?1 and u.lastname = ?2`,Spring Data JPA会做属性检查，并且遍历嵌套的属性，正如在[Property Expressions](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/#repositories.query-methods.query-property-expressions)章节。
我们使用JPA的规则创建了一个查询，但是本质上，使用的查询是
```sql
select u from User u where u.emailAddress = ?1 and u.lastname = ?2
```
下面的列表描述了JPA支持的SQL关键词翻译规则，参考文档上有，不写了。
- 使用JPA命名查询，使用@NamedQuery或者@NameNativeQuery，下面的例子都使用了<named-query/>或者@NamedQuery注解，这些查询必须以JPA查询语言的方式定义，当然，也可以使用<named-native-query/>或者@NamedNativeQuery注解，这些元素可以让你以native SQL的方式定义查询，但是这样做丧失了数据库平台无关性。@NamedQuery的例子
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
- 修改查询
- 引用查询提示
- configuring fetch- and loadgraphs

## 存储过程
## 规格
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
## QBE查询方式
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
## 事务
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
这个例子让对方法addRoleToAllUsers()方法的调用运行在一个事务里面（参与到一个已存在的事务或者没有事务就创建一个新的事务），repository的事务配置会被忽略，因为外层的事务配置才是真正使用的事务。需要注意的是，你必须声明`<tx:annotation-driven />`或者声明`@EnableTransactionManagement`来明确的让门面上的注解事务配置生效，这个例子假设你使用了组件扫描。
需要注意的是，从JPA视角来看，没有必要调用save方法，当时接口中也应该提供save方法，这是为了保证spring data提供的repository接口定义的一致性。
#### 事务查询方法
为了给查询添加事务特性，在你定义的repository接口上声明@Transactional，如下面的例子所示
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
通常，您希望将 readOnly 标志设置为 true，因为大多数查询方法只读取数据。 与此相反，deleteInactiveUsers() 使用 @Modifying 注释这会覆盖事务配置。 因此，该方法运行时，readOnly配置是false。
你可以在只读查询上使用事务，并通过设置readOnly=true来标记它们，但是，这么做并不能保证你不会触发一个变更查询（虽然有的数据哭拒绝在只读事务中执行insert或者update语句），但是readOnly标记可以作为一个提示传播到底层的JDBC驱动中，驱动程序可以用来做性能优化。此外spring对底层的JPA提供程序做了一些优化。比如：当与Hibernate一起使用时，当事务被配置为readOnly=true时，flush modo会被设置为NEVER，这会让Hibernate跳过脏检查（对大量的对象树的检索会带来明显的提升）
## Locking
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
## Auditing审计
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
## JPA Auditing
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
# 其他注意事项
## 在自定义的实现中使用JpaContext
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
## CDI Integration
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
