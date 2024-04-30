MySQL的Command Line Client
# 执行sql文件
mysql客户端通常是交互式使用的，比如
>mysql db_name

也可以把SQL语句放到sql文件中，然后发给mysql客户端执行。比如:
> mysql db_name < text_file

如果文件中已经存在`USE db_name`语句，那么就没有必要在命令行上指定数据库名
> mysql < text_file

如果你已经进入mysql命令内，你可以使用`source`或者`\.`命令执行SQL脚本文件。
>mysql> source file_name
>mysql> \. file_name

如果你想要展示脚本执行的进度信息，可以在文件中插入类似下面的语句:
```sql
SELECT '<info_to_display>' AS ' ';
```
上面的语句将会输出`<info_to_display>`。使用`--verbose`选项将会在执行前打印要执行的语句。mysql命令行将会忽略UTF-8文件的BOM字符。BOM的出现并不能改变mysql命令行的默认字符集，你可以使用`--default-character-set=utf8mb4`参数改变。