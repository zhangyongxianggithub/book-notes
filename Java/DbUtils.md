简化JDBC开发的小库。
# Setup
```xml
<dependency>
    <groupId>commons-dbutils</groupId>
    <artifactId>commons-dbutils</artifactId>
    <version>1.7</version>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <version>1.4.196</version>
</dependency>
```
建表语句
```sql
CREATE TABLE employee(
    id int NOT NULL PRIMARY KEY auto_increment,
    firstname varchar(255),
    lastname varchar(255),
    salary double,
    hireddate date,
);

CREATE TABLE email(
    id int NOT NULL PRIMARY KEY auto_increment,
    employeeid int,
    address varchar(255)
);

INSERT INTO employee (firstname,lastname,salary,hireddate)
  VALUES ('John', 'Doe', 10000.10, to_date('01-01-2001','dd-mm-yyyy'));
// ...
INSERT INTO email (employeeid,address)
  VALUES (1, 'john@baeldung.com');
// ...
```
在所有的测试前面加入连接数据库/关闭数据库
```java
public class DbUtilsUnitTest {
    private Connection connection;

    @Before
    public void setupDB() throws Exception {
        Class.forName("org.h2.Driver");
        String db
          = "jdbc:h2:mem:;INIT=runscript from 'classpath:/employees.sql'";
        connection = DriverManager.getConnection(db);
    }

    @After
    public void closeBD() {
        DbUtils.closeQuietly(connection);
    }
    // ...
}
```
POJO类
```java
public class Employee {
    private Integer id;
    private String firstName;
    private String lastName;
    private Double salary;
    private Date hiredDate;

    // standard constructors, getters, and setters
}

public class Email {
    private Integer id;
    private Integer employeeId;
    private String address;

    // standard constructors, getters, and setters
}
```
# Introduction
DbUtils提供了`QueryRunner`类作为大部分功能的主要入口点。这个类接受一个数据库连接、一个SQL语句以及一些可选的参数，这些参数会填充SQL中占位符。重载的方法还接受`ResultSetHandler`对象，负责将`ResultSet`转换成其他对象，库提供几个默认的实现。
# Querying Data
下面是一个简单的例子
```java
@Test
public void givenResultHandler_whenExecutingQuery_thenExpectedList()
  throws SQLException {
    MapListHandler beanListHandler = new MapListHandler();

    QueryRunner runner = new QueryRunner();
    List<Map<String, Object>> list
      = runner.query(connection, "SELECT * FROM employee", beanListHandler);

    assertEquals(list.size(), 5);
    assertEquals(list.get(0).get("firstname"), "John");
    assertEquals(list.get(4).get("firstname"), "Christian");
}
```
下面是使用`BeanListHandler`来将结果转换为POJO类
```java
@Test
public void givenResultHandler_whenExecutingQuery_thenEmployeeList()
  throws SQLException {
    // 注意这里字段名与属性名是忽略大小写的完全映射，如果数据库名有下划线则匹配不上
    BeanListHandler<Employee> beanListHandler
      = new BeanListHandler<>(Employee.class);

    QueryRunner runner = new QueryRunner();
    List<Employee> employeeList
      = runner.query(connection, "SELECT * FROM employee", beanListHandler);

    assertEquals(employeeList.size(), 5);
    assertEquals(employeeList.get(0).getFirstName(), "John");
    assertEquals(employeeList.get(4).getFirstName(), "Christian");
}
```
如果只是返回一条记录，可以使用`ScalarHandler`:
```java
@Test
public void givenResultHandler_whenExecutingQuery_thenExpectedScalar()
  throws SQLException {
    ScalarHandler<Long> scalarHandler = new ScalarHandler<>();

    QueryRunner runner = new QueryRunner();
    String query = "SELECT COUNT(*) FROM employee";
    long count
      = runner.query(connection, query, scalarHandler);
    assertEquals(count, 5);
}
```
对于`ResultSerHandler`的所有的实现，可以参考[ResultSetHandler documentation.](https://commons.apache.org/proper/commons-dbutils/apidocs/org/apache/commons/dbutils/ResultSetHandler.html)
也可以创建自定义的`ResultSetHandler`实现来控制返回的结果如何转换为对象。要么实现`ResultSetHandler`要么继承已有的实现
```java
public class EmployeeHandler extends BeanListHandler<Employee> {

    private Connection connection;

    public EmployeeHandler(Connection con) {
        super(Employee.class);
        this.connection = con;
    }

    @Override
    public List<Employee> handle(ResultSet rs) throws SQLException {
        List<Employee> employees = super.handle(rs);

        QueryRunner runner = new QueryRunner();
        BeanListHandler<Email> handler = new BeanListHandler<>(Email.class);
        String query = "SELECT * FROM email WHERE employeeid = ?";

        for (Employee employee : employees) {
            List<Email> emails
              = runner.query(connection, query, handler, employee.getId());
            employee.setEmails(emails);
        }
        return employees;
    }
}
```
表字段与类的属性默认是按照名字匹配的，并且忽略大小写。如果表字段存在下划线来分隔单词，则无法匹配。可以使用`RowProcessor`接口的实现来完成列名到类的成员的映射。
```java
public class EmployeeHandler extends BeanListHandler<Employee> {
    // ...
    public EmployeeHandler(Connection con) {
        super(Employee.class,
          new BasicRowProcessor(new BeanProcessor(getColumnsToFieldsMap())));
        // ...
    }
    public static Map<String, String> getColumnsToFieldsMap() {
        Map<String, String> columnsToFieldsMap = new HashMap<>();
        columnsToFieldsMap.put("FIRST_NAME", "firstName");
        columnsToFieldsMap.put("LAST_NAME", "lastName");
        columnsToFieldsMap.put("HIRED_DATE", "hiredDate");
        return columnsToFieldsMap;
    }
}
```
# 插入记录
`QueryRunner`类提供了两种在数据库中创建记录的方法。第一种方法是使用`update()`方法并传递SQL语句和可选的替换参数列表。该方法返回插入的记录数:
```java
@Test
public void whenInserting_thenInserted() throws SQLException {
    QueryRunner runner = new QueryRunner();
    String insertSQL
      = "INSERT INTO employee (firstname,lastname,salary, hireddate) "
        + "VALUES (?, ?, ?, ?)";

    int numRowsInserted
      = runner.update(
        connection, insertSQL, "Leia", "Kane", 60000.60, new Date());

    assertEquals(numRowsInserted, 1);
}
```
第二种方法是使用`insert()`方法，除了SQL语句与参数外，还需要一个`ResultSetHandler`来转换自动生成的主键。
```java
@Test
public void
  givenHandler_whenInserting_thenExpectedId() throws SQLException {
    ScalarHandler<Integer> scalarHandler = new ScalarHandler<>();

    QueryRunner runner = new QueryRunner();
    String insertSQL
      = "INSERT INTO employee (firstname,lastname,salary, hireddate) "
        + "VALUES (?, ?, ?, ?)";

    int newId
      = runner.insert(
        connection, insertSQL, scalarHandler,
        "Jenny", "Medici", 60000.60, new Date());

    assertEquals(newId, 6);
}
```
# 更新与删除
```java
@Test
public void givenSalary_whenUpdating_thenUpdated()
 throws SQLException {
    double salary = 35000;

    QueryRunner runner = new QueryRunner();
    String updateSQL
      = "UPDATE employee SET salary = salary * 1.1 WHERE salary <= ?";
    int numRowsUpdated = runner.update(connection, updateSQL, salary);

    assertEquals(numRowsUpdated, 3);
}
```
```java
@Test
public void whenDeletingRecord_thenDeleted() throws SQLException {
    QueryRunner runner = new QueryRunner();
    String deleteSQL = "DELETE FROM employee WHERE id = ?";
    int numRowsDeleted = runner.update(connection, deleteSQL, 3);

    assertEquals(numRowsDeleted, 1);
}
```
# 异步操作
`AsyncQueryRunner`提供异步操作，方法跟`QueryRunner`都是类似的，只是返回`Future`类型的实例
```java
@Test
public void
  givenAsyncRunner_whenExecutingQuery_thenExpectedList() throws Exception {
    AsyncQueryRunner runner
      = new AsyncQueryRunner(Executors.newCachedThreadPool());

    EmployeeHandler employeeHandler = new EmployeeHandler(connection);
    String query = "SELECT * FROM employee";
    Future<List<Employee>> future
      = runner.query(connection, query, employeeHandler);
    List<Employee> employeeList = future.get(10, TimeUnit.SECONDS);
    assertEquals(employeeList.size(), 5);
}
```
# 结论

