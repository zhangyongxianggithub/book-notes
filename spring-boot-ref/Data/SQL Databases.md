# JPA and Spring Data JPA
Java Persistence API是可以让你将对象与数据库映射起来的标准规范，`spring-boot-starter-data-jpa`依赖可以让你快速的开始开发，它提供了下面的关键依赖:
- Hibernate: 一个广受欢迎的JPA实现;
- Spring Data JPA: 帮助你实现基于JPA的仓库;
- Spring ORM: 来自于Spring Framework的核心ORM支持;
## Entity Classes
在以前，JPA的实体类都在persistence.xml文件中描述，Spring Boot也需要实体类，但是使用实体扫描机制代替了persistence.xml文件，缺省情况下，会扫描你的主配置类(类上有注解`@EnableAutoConfiguration`与`@SpringBootApplication`)下面的所有的包的实体类，任何带有注解`@Entity`、`@Embeddable`、`@MappedSuperclass`的类都会被认为是实体类，一个例子如下:
```java
@Entity
public class City implements Serializable {

    @Id
    @GeneratedValue
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String state;

    // ... additional members, often include @OneToMany mappings

    protected City() {
        // no-args constructor required by JPA spec
        // this one is protected since it should not be used directly
    }

    public City(String name, String state) {
        this.name = name;
        this.state = state;
    }

    public String getName() {
        return this.name;
    }

    public String getState() {
        return this.state;
    }
}
```
你可以使用@EntityScan注解改变实体类扫描的位置.
## Spring Data JPA Repositories
Spring Data JPA repositories是定义用来访问数据的接口，JPA查询会自动的从repo的方法名衍生，对于更复杂的查询，你可以使用@Query注解，repos通常继承于Repository与CrudRepository接口，如果你使用自动配置方式，它的扫描机制与实体类是类似的.下面是一个例子:
```java
public interface CityRepository extends Repository<City, Long> {

    Page<City> findAll(Pageable pageable);

    City findByNameAndStateAllIgnoringCase(String name, String state);

}
```
Spring Data JPA repositories支持3种启动模式：
- default
- deferred
- lazy
通过属性`spring.data.jpa.repositories.bootstrap-mode`设置，当使用deferred与lazy模式时，自动配置的`EntityManagerFactoryBuilder`会使用上下文中的AsyncTaskExecutor作为启动执行器，如果存在多个AsyncTaskExecutor，名字叫`applicationTaskExecutor`被使用。
## Spring Data Envers Repository
如果存在Spring Data Envers，JPA Repo会自动配置为支持传统的Envers查询，要使用Spring Data Envers，需要Repo继承`RevisionRepository`，如下:
```java
public interface CountryRepository extends RevisionRepository<Country, Long, Integer>, Repository<Country, Long> {
    Page<Country> findAll(Pageable pageable);
}
```
## Creating and Dropping JPA Databases
缺省情况下，JPA数据库只有在使用内存数据库(H2、HSQL、Derby)的情况下才会自动创建，当让你可以通过`spring.jpa.*`等属性配置JPA设置，如果支持自动创建数据库，可以设置如下属性:
```yaml
spring:
  jpa:
    hibernate.ddl-auto: "create-drop"
```
Hibernate自己的内部的用于控制这个行为的属性名是`hibernate.hbm2ddl.auto`，你可以设置Hibernate自己的属性，通过使用`spring.jpa.properties.*`，在将这些属性添加到EntityManager前，前缀会被去掉，下面是一个例子:
```yaml
spring:
  jpa:
    properties:
      hibernate:
        "globally_quoted_identifiers": "true"
```
缺省情况下，DDL会被推迟到ApplicationContext启动后执行，如果开启了Hibernate的自动配置，那么`spring.jpa.generate-ddl`就失效了；
## Open EntityManager in View
如果你运行在一个Web应用中，Spring Boot默认回注册一个OpenEntityManagerInViewInterceptor来应用`Open EntityManager in View`模式，如果你不想要这个行为吗，你可以设置`spring.jpa.open-in-view=false`
