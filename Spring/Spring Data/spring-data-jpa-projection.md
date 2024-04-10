翻译自一个博客[Spring Data JPA: Query Projections](https://thorben-janssen.com/spring-data-jpa-query-projections/)
在使用 Spring Data JPA 实现查询时，投影可能是您首先要考虑的事情之一。 这是因为投影定义了查询返回的实体属性和数据库列。 因此，选择正确的列对您的业务逻辑很重要。 同时，投影对于应用程序的性能和代码的可维护性也至关重要。 此外，您需要选择一种能够使开销尽可能低并以易于使用的结构提供数据的投影。
[TOC]
# Types of Projections Supported by Spring Data JPA
基于JPA的查询能力，Spring Data JPA为您提供了多种选项来实现投影，你可以根据自己的使用场景选择其中一种实现方式.
- 标量投影，标量投影由Object[\]组成，Object[]通常表示一列，可以返回多列, 此投影为读取操作提供了出色的性能，但很少使用。这是因为DTO投影提供了相同的好处，同时更易于使用;
- DTO投影，选择数据库的部分列，使用它们调用构造函数，返回多个unmanaged对象，如果你不需要改变实体的字段值，这是一个完美的投影方式;
- 实体投影，返回与数据库列一一对应的实体managed对象，如果想要实时跟踪实体的变更，实体投影是建议的方式。
Spring Data JPA的衍生与自定义查询均支持上述3种投影方式，Spring已经完成了很多模板代码的编写，另外，Spring对DTO投影的支持让你写代码变得方便容易，也支持动态投影。
# 标量投影
标量投影允许您选择业务逻辑所需的实体属性并排除其余部分。
```java
@Repository
public interface BookRepository extends JpaRepository<Book, Long> {
    @Query("SELECT b.id, b.title FROM Book b")
    List<Object[]> getIdAndTitle();   
}
```
这种查询结果很难使用。
# DTO投影
当使用DTO投影时，你需要告诉你的底层存储查询结果与与DTO（unmanaged对象）的映射关系，如上一篇文章所示，如果您不需要实时跟踪所选的数据，这种方式实体结果要好得多。而且，与标量投影相比，它们也非常易于使用。这是因为 DTO 对象是命名的并且是强类型的。
## JPA‘s DTOs
DTO可以表示返回结果，而且是高效的，强类型的；需要定义DTO类、包含的属性与相关的seter/geter方法，还有所有属性作为参数的构造方法。
```java
public class AuthorSummaryDTO {
     
    private String firstName;
    private String lastName;
     
    public AuthorSummaryDTO(String firstName, String lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
    }
     
    public String getFirstName() {
        return firstName;
    }
    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }
    public String getLastName() {
        return lastName;
    }
    public void setLastName(String lastName) {
        this.lastName = lastName;
    }
}
```
在JPA查询中通过构造函数表达式使用，它描述了对于构造函数的调用，构造函数表达式的定义如下
>new com.z.b.Constructor(parameters)

其中出现的构造函数必须是DTO类的全限定名.
```java
@Repository
public interface AuthorRepository extends CrudRepository<Author, Long> {
 
    @Query("SELECT new com.thorben.janssen.spring.jpa.projections.dto.AuthorSummaryDTO(a.firstName, a.lastName) FROM Author a WHERE a.firstName = :firstName")
    List<AuthorSummaryDTO> findByFirstName(String firstName);
}
```
正如你在代码片段中看到的，你可以在JPA的@Query注解中使用这种方式，你使用底层JPA实现会执行这个查询，查询会选择DTO中需要的列，然后执行构造函数调用。
## Spring Data’s Simplified DTOs
你可以在一个衍生查询中使用DTO投影，这不需要上面的构造函数表达式。只要DTO类有一个构造函数，且这个构造函数的参数名与实体类属性的名字一致，Spring会自动生成带有构造函数表达式的查询。
```java
@Repository
public interface AuthorRepository extends CrudRepository<Author, Long> {
 
    List<AuthorSummaryDTO> findByFirstName(String firstName);
}
```
这种方式查询定义更简单，而且也提供了良好的性能。
## DTOs as Interface
相比DTO类的方式，你也可以使用接口作为DTO投影，只要你的接口为你要选择的属性定义了get方法,get方法的定义必须与实体中的get方法的名字一样.
```java
public interface AuthorView {
    String getFirstName();
    String getLastName();
}
```
```java
@Repository
public interface AuthorRepository extends CrudRepository<Author, Long> {
     
    AuthorView  findViewByFirstName(String firstName);
}
```
使用接口作为投影方式时，Spring Data JPA会内部生成一个接口的class，也就是代理类。
如果投影接口将需要映射到其他实体（或者自定义接口方法）或使用SpEL，则情况会发生变化。
### 嵌套投影
为了能够在投影中包含与其他实体的关联，Spring Data JPA需要使用不同的方法。然后它选择底层实体并执行编程映射。
在下面的示例中，Author中定义了一个getBooks()方法，该方法返回Author所写的所有书籍的列表。您可以通过将方法 List<BookView> getBooks()添加到AuthorView接口来告诉Spring Data将书籍列表映射到BookView对象列表。
```java
public interface AuthorView {
 
    String getFirstName();
    String getLastName();
     
    List<BookView> getBooks();
     
    interface BookView {
         
        String getTitle();
    }
}
```
当你这么做时，Spring Data JPA将会获得entity实体，并再次触发一次查询，获得每个Author的所有的*Book*实体数据，这种方式需要n+1次IO查询，可能会造成严重的性能问题，你可以通过提供一个使用JOIN FETCH子句的子定义查询避免这种情况。
接下来，Spring Data使用Author实体对象来实例化AuthorView接口的内部实现，从性能的视角来看，这是错误的方式，你的查询查询了很多无用的列，而且，你的底层JPA实现需要管理所有的实体对象包括*Book*与*Author*，所以，这种投影方式的性能会比前面的DTO投影方式差很多。
### Using SpEL
也可以在接口定义中使用SpEL，通过SpEL，你可以自定义一些关于字段的计算活着组合分解之类的逻辑
```java
public interface BookSummary {
 
    @Value("#{target.title + '-' + target.author.firstName}")
    String getBookNameAndAuthorName();
}
```
在上面的例子中，Spring会拼接Book的title与firstName字段结果设置为bookNameAndAuthorName属性的值。
# Entity Projections
实体是广泛使用的投影方式，存储上下文管理所有Repo返回的对象，因此，对属性的变更都会持久存储到数据库中，你可以以懒加载的方式获取关联对象，这对于读操作会造成额外的性能消耗，但是对于写操作确是最佳的投影方式。
实体投影是最容易使用的。
```java
@Repository
public interface AuthorRepository extends CrudRepository<Author, Long> {
    @Query("select a from Author a left join fetch a.books")
    List<Author> getAuthorsAndBook();
}
```
# Dynamic Projections
repo方法添加范型Class参数，可以复用查询来完成不同的投影，这让你可以在业务代码中定义想要的返回类型。依据传入的实参Class类型，Spring Data JPA使用上面提到的机制的一种来定义投影方式并完成查询映射，比如，如果你提供的是DTO类，Spring Data JPA会生成一个带有构造函数表达式的查询。
# Conclusion
Spring Data JPA支持所有3种投影方式，实体的方式比较方便写操作，更多的，对于读操作（不涉及到实体变更的），你应该使用基于类的DTO投影方式。其他形式的投影方式最好避免使用，标量投影不方便使用，基于接口的DTO投影方式性能有问题，因为它们底层还会拉取实体。
