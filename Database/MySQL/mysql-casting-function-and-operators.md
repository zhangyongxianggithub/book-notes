# 12.3 在表达式赋值中的类型转换
当操作符操作不同类型的数据时，为了兼容的考虑，就会发生类型转换，这种转换是隐式进行的，比如当执行加法时，自动把string的数据转化为数字类型。
>mysql> SELECT 1+'1';
        -> 2
mysql> SELECT CONCAT(2,' test');
        -> '2 test'

# 12.11 类型转换函数与操作符
主要是3个操作符与函数：
- BINARY，把一个字符串转换为一个二进制字符串；CONVERT()函数可以通过USING子句转换数据的字符集编码，
  > CONVERT(expr USING transcoding_name)

  在MySQL中，transcoding_name就是字符集编码的名字，比如：
  > SELECT CONVERT('test' USING utf8mb4);
  SELECT CONVERT(_latin1'Muller' USING utf8mb4);
  INSERT INTO utf8mb4_table(utf8mb4_column)
    SELECT CONVERT(latin1_column USING utf8mb4) FROM latin1_table;

  字符串的字符集转换，使用的语法是CONVERT(expr, type)或者CAST(expr AS type) 这2者是等价的
  CONVERT(string, CHAR[(N)] CHARACTER SET charset_name)
  CAST(string AS CHAR[(N)] CHARACTER SET charset_name)
  例子如下：
  >SELECT CONVERT('test', CHAR CHARACTER SET utf8mb4);
  SELECT CAST('test' AS CHAR CHARACTER SET utf8mb4);

  



















 
- CAST(),把一个值转化为给定的类型；
- CONVERT(),把一个值转化为给定的类型,与CAST()函数的作用是相同的。
类型转化函数的作用就是对值的类型做转换。