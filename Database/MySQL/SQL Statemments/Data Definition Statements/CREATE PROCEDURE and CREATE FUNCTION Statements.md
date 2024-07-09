```sql
CREATE
    [DEFINER = user]
    PROCEDURE [IF NOT EXISTS] sp_name ([proc_parameter[,...]])
    [characteristic ...] routine_body

CREATE
    [DEFINER = user]
    FUNCTION [IF NOT EXISTS] sp_name ([func_parameter[,...]])
    RETURNS type
    [characteristic ...] routine_body

proc_parameter:
    [ IN | OUT | INOUT ] param_name type

func_parameter:
    param_name type

type:
    Any valid MySQL data type

characteristic: {
    COMMENT 'string'
  | LANGUAGE SQL
  | [NOT] DETERMINISTIC
  | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
  | SQL SECURITY { DEFINER | INVOKER }
}

routine_body:
    Valid SQL routine statement
```
上面的语句用于创建存储例程（存储过程或函数）。即，指定的例程为服务器所知。默认情况下，存储例程与默认数据库相关联。要将例程与给定数据库显式关联，请在创建时将名称指定为`db_name.sp_name`。`CREATE FUNCTION`也用来支持可加载函数功能，存储函数与可加载函数共享命名空间。有关描述服务器如何解释对不同类型函数的引用的规则，请参见第 9.2.5节[函数名称解析和解析](https://dev.mysql.com/doc/refman/8.0/en/function-resolution.html)使用`CALL`调用存储过程，调用存储函数是需要在某个表达式中使用它即可，表达式计算的时候函数返回一个值。`CREATE PROCEDURE`和`CREATE FUNCTION`需要`CREATE ROUTINE`权限。如果存在`DEFINER`子句，则所需的权限取决于用户值，如第25.6节“存储对象访问控制”中所述。如果启用了二进制日志记录，则`CREATE FUNCTION`可能需要`SUPER`权限，如第25.7节“存储程序二进制日志记录”中所述。默认情况下，MySQL自动将`ALTER ROUTINE`和`EXECUTE`权限授予例程创建者。可以通过禁用`automatic_sp_privileges`系统变量来更改此行为。请参阅第25.2.2“存储的例程和 MySQL特权”。`DEFINER`和`SQL SECURITY`子句指定在例程执行时检查访问权限时要使用的安全上下文，如本节后面所述。如果例程名称与内置SQL函数的名称相同，则会出现语法错误，除非您在定义例程或稍后调用它时在名称和后面的括号之间使用空格。因此，请避免将现有SQL函数的名称用于您自己的存储例程。IGNORE_SPACE SQL模式适用于内置函数，而不适用于存储的例程。无论是否启用了IGNORE_SPACE，在存储的例程名称之后总是允许有空格。如果已经存在了同名例程，`IF NOT EXISTS`可防止发生重复创建的错误。从MySQL 8.0.29开始，`CREATE FUNCTION`和`CREATE PROCEDURE` 都支持此选项。如果已存在同名的内置函数，则尝试使用`CREATE FUNCTION ... IF NOT EXISTS`创建存储函数也会成功但会显示一个警告-表明它与本机函数同名；这与在不指定`IF NOT EXISTS`的情况下执行相同的 `CREATE FUNCTION`语句的效果是一样的。如果已存在同名的可加载函数，则尝试使用`IF NOT EXISTS`创建存储函数会成功并出现警告。这与不指定`IF NOT EXISTS`相同。括号内的参数列表必须始终存在。如果没有参数，则应使用()的空参数列表。参数名称不区分大小写。默认情况下，每个参数都是一个IN参数。要另外指定参数，请在参数名称前使用关键字 OUT或INOUT。将参数指定为`IN`、`OUT`或`INOUT`仅对`PROCEDURE`有效。 对于`FUNCTION`，参数始终被视为IN 参数。IN参数将值传递给过程。该过程可能会修改该值，但调用者看不到该修改。 OUT参数将过程中的值传递回调用者。它在过程中的初始值为NULL，当过程返回时，它的值对调用者可见。INOUT参数由调用者初始化，可由过程修改，过程返回时调用者可以看到过程所做的任何更改。对于每个OUT或INOUT参数，在调用过程的CALL语句中传递一个用户定义的变量，以便在过程返回时获取其值。如果您从另一个存储过程或函数中调用该过程，您还可以将例程参数或局部例程变量作为OUT或 INOUT参数传递。如果从触发器中调用过程，还可以将`NEW.col_name`作为OUT或INOUT参数传递。有关未处理条件对过程参数的影响的信息，请参阅第13.6.7.8节条件处理和OUT或INOUT参数。例程中语句中不能引用例程参数；请参阅第25.8节对存储程序的限制。下面的例子展示了一个简单的存储过程，给定一个国家代码，计算该国家出现在世界数据库城市表中的城市数量。国家代码使用IN参数传递，城市计数使用OUT参数返回:
```sql
mysql> delimiter //

mysql> CREATE PROCEDURE citycount (IN country CHAR(3), OUT cities INT)
       BEGIN
         SELECT COUNT(*) INTO cities FROM world.city
         WHERE CountryCode = country;
       END//
Query OK, 0 rows affected (0.01 sec)

mysql> delimiter ;

mysql> CALL citycount('JPN', @cities); -- cities in Japan
Query OK, 1 row affected (0.00 sec)

mysql> SELECT @cities;
+---------+
| @cities |
+---------+
|     248 |
+---------+
1 row in set (0.00 sec)

mysql> CALL citycount('FRA', @cities); -- cities in France
Query OK, 1 row affected (0.00 sec)

mysql> SELECT @cities;
+---------+
| @cities |
+---------+
|      40 |
+---------+
1 row in set (0.00 sec)
```
上面的例子使用了mysql客户端分隔符命令将语句分隔符从;改为//，这样在定义存储过程中的;分隔符会直接传递到服务器而不是由mysql客户端本身解释。RETURNS子句只用于FUNCTION，它是强制性的。表示函数的返回类型，函数体必须一个包含`RETURN 值`语句。如果RETURN语句返回不同类型的值，则该值被强制转换为合适的类型。例如，如果一个函数在RETURNS子句中指定了一个ENUM或SET值，但RETURN语句返回一个整数，则从该函数返回的值是SET成员集的相应ENUM成员的字符串。以下示例函数接受一个参数，使用SQL函数执行操作并返回结果。在这种情况下，不需要使用分隔符，因为函数定义不包含;语句分隔符:
```sql
mysql> CREATE FUNCTION hello (s CHAR(20))
mysql> RETURNS CHAR(50) DETERMINISTIC
       RETURN CONCAT('Hello, ',s,'!');
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT hello('world');
+----------------+
| hello('world') |
+----------------+
| Hello, world!  |
+----------------+
1 row in set (0.00 sec)
```

