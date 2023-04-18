Catalog提供了元数据信息，例如数据库、表、分区、视图以及数据库或其他外部系统中存储的函数和信息。数据处理最关键的方面之一是管理元数据。元数据可以是临时的，例如临时表、或者通过TableEnvironment注册的UDF，元数据也可以是持久化的，例如Hive Metastore中的元数据。Catalog提供了一个统一的API，用于管理元数据，并使其可以从Table API/SQL查询语句中来访问。
# Catalog类型
## GenericInMemoryCatalog
GenericInMemoryCatalog是基于内存实现的Catalog，所有的元数据只在session的生命周期内可用
## JdbcCatalog
JdbcCatalog使得用户可以将Flink通过JDBC协议连接到关系数据库。Postgre Catalog/MySQL Catalog是目前JDBC Catalog仅有的2种实现。参考[JdbcCatalog文档](https://nightlies.apache.org/flink/flink-docs-master/zh/docs/connectors/table/jdbc/)获取关于配置JDBC catalog的详细信息。
## HiveCatalog
HiveCatalog有2个用途: 
- 作为原生Flink元数据的持久化存储
- 作为读写现有Hive元数据的接口

Flink的Hive文档提供了有关设置HiveCatalog以及访问现有Hive元数据的详细信息。HiveMetastore以小写形式存储所有元数据对象名称。而GenericInMemoryCatalog区分大小写。
## 用户自定义Catalog
Catalog是可扩展的，用户可以通过实现Catalog接口来开发自定义Catalog。想要在SQL CLI中使用自定义Catalog，用户除了需要实现自定义的Catalog之外，还需要为这个Catalog实现对应的`CatalogFactory`接口。`CatalogFactory`定义了一组属性，用于SQL CLI启动时配置Catalog，这组属性集将传递给发现服务，在该服务中，服务会尝试将属性关联到`CatalogFactory`并初始化相应的Catalog实例。从Flink 1.16版本开始，TableEnvironment引入了一个用户类加载器，以在table程序、SQL Client、SQL Gateway中保持一致的类加载行为。这个类加载器会统一管理啊所有的用户jar包，包括通过ADD JAR或CREATE FUNCTION USING JAR添加的JAR资源。在用户自定义catalog中，应该将`Thread.currentThread().getContextClassLoader()`替换成该用户类加载器去加载类。否则，可能会发生`ClassNotFoundException`的异常。该用户类加载器可以通过`CatalogFactory.Context#getClassLoader`获得。
# 如何创建Flink表并将其注册到Catalog
## 使用SQL DDL
用户可以使用DDL通过Table API或者SQL Client在Catalog中创建表。
```java
TableEnvironment tableEnv = ...;

// Create a HiveCatalog 
Catalog catalog = new HiveCatalog("myhive", null, "<path_of_hive_conf>");

// Register the catalog
tableEnv.registerCatalog("myhive", catalog);

// Create a catalog database
tableEnv.executeSql("CREATE DATABASE mydb WITH (...)");

// Create a catalog table
tableEnv.executeSql("CREATE TABLE mytable (name STRING, age INT) WITH (...)");

tableEnv.listTables(); // should return the tables in current catalog and database.
```
```shell
// the catalog should have been registered via yaml file
Flink SQL> CREATE DATABASE mydb WITH (...);

Flink SQL> CREATE TABLE mytable (name STRING, age INT) WITH (...);

Flink SQL> SHOW TABLES;
mytable
```
更多详细信息，请参考[Flink SQL CREATE DDL](https://nightlies.apache.org/flink/flink-docs-master/zh/docs/dev/table/sql/create/)
## 使用Java/Scala
用户可以用编程的方式使用Java/Scala来创建Catalog表
```java
import org.apache.flink.table.api.*;
import org.apache.flink.table.catalog.*;
import org.apache.flink.table.catalog.hive.HiveCatalog;

TableEnvironment tableEnv = TableEnvironment.create(EnvironmentSettings.inStreamingMode());

// Create a HiveCatalog
Catalog catalog = new HiveCatalog("myhive", null, "<path_of_hive_conf>");

// Register the catalog
tableEnv.registerCatalog("myhive", catalog);

// Create a catalog database
catalog.createDatabase("mydb", new CatalogDatabaseImpl(...));

// Create a catalog table
final Schema schema = Schema.newBuilder()
    .column("name", DataTypes.STRING())
    .column("age", DataTypes.INT())
    .build();

tableEnv.createTable("myhive.mydb.mytable", TableDescriptor.forConnector("kafka")
    .schema(schema)
    // …
    .build());

List<String> tables = catalog.listTables("mydb"); // tables should contain "mytable"
```
# Catalog API
这里只列出了编程方式的Catalog API，用户可以使用SQL DDL实现许多相同的功能。关于DDL的详细信息请参考[SQL CREATE DDL](https://nightlies.apache.org/flink/flink-docs-master/zh/docs/dev/table/sql/create/)
## 数据库操作
```java
// create database
catalog.createDatabase("mydb", new CatalogDatabaseImpl(...), false);

// drop database
catalog.dropDatabase("mydb", false);

// alter database
catalog.alterDatabase("mydb", new CatalogDatabaseImpl(...), false);

// get database
catalog.getDatabase("mydb");

// check if a database exist
catalog.databaseExists("mydb");

// list databases in a catalog
catalog.listDatabases("mycatalog");
```
## 表操作
```java
// create table
catalog.createTable(new ObjectPath("mydb", "mytable"), new CatalogTableImpl(...), false);

// drop table
catalog.dropTable(new ObjectPath("mydb", "mytable"), false);

// alter table
catalog.alterTable(new ObjectPath("mydb", "mytable"), new CatalogTableImpl(...), false);

// rename table
catalog.renameTable(new ObjectPath("mydb", "mytable"), "my_new_table");

// get table
catalog.getTable("mytable");

// check if a table exist or not
catalog.tableExists("mytable");

// list tables in a database
catalog.listTables("mydb");
```
## 视图操作
```java
// create view
catalog.createTable(new ObjectPath("mydb", "myview"), new CatalogViewImpl(...), false);

// drop view
catalog.dropTable(new ObjectPath("mydb", "myview"), false);

// alter view
catalog.alterTable(new ObjectPath("mydb", "mytable"), new CatalogViewImpl(...), false);

// rename view
catalog.renameTable(new ObjectPath("mydb", "myview"), "my_new_view", false);

// get view
catalog.getTable("myview");

// check if a view exist or not
catalog.tableExists("mytable");

// list views in a database
catalog.listViews("mydb");
```
## 分区操作
```java
// create view
catalog.createPartition(
    new ObjectPath("mydb", "mytable"),
    new CatalogPartitionSpec(...),
    new CatalogPartitionImpl(...),
    false);

// drop partition
catalog.dropPartition(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...), false);

// alter partition
catalog.alterPartition(
    new ObjectPath("mydb", "mytable"),
    new CatalogPartitionSpec(...),
    new CatalogPartitionImpl(...),
    false);

// get partition
catalog.getPartition(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...));

// check if a partition exist or not
catalog.partitionExists(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...));

// list partitions of a table
catalog.listPartitions(new ObjectPath("mydb", "mytable"));

// list partitions of a table under a give partition spec
catalog.listPartitions(new ObjectPath("mydb", "mytable"), new CatalogPartitionSpec(...));

// list partitions of a table by expression filter
catalog.listPartitions(new ObjectPath("mydb", "mytable"), Arrays.asList(epr1, ...));
```
## 函数操作
```java
// create function
catalog.createFunction(new ObjectPath("mydb", "myfunc"), new CatalogFunctionImpl(...), false);

// drop function
catalog.dropFunction(new ObjectPath("mydb", "myfunc"), false);

// alter function
catalog.alterFunction(new ObjectPath("mydb", "myfunc"), new CatalogFunctionImpl(...), false);

// get function
catalog.getFunction("myfunc");

// check if a function exist or not
catalog.functionExists("myfunc");

// list functions in a database
catalog.listFunctions("mydb");
```
