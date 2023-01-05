MySQL CDC 连接器允许从 MySQL 数据库读取快照数据和增量数据。本文描述了如何设置 MySQL CDC 连接器来对 MySQL 数据库运行 SQL 查询。
# 如何创建 MySQL CDC 表
```sql
-- 每 3 秒做一次 checkpoint，用于测试，生产配置建议5到10分钟                      
Flink SQL> SET 'execution.checkpointing.interval' = '3s';   

-- 在 Flink SQL中注册 MySQL 表 'orders'
Flink SQL> CREATE TABLE orders (
     order_id INT,
     order_date TIMESTAMP(0),
     customer_name STRING,
     price DECIMAL(10, 5),
     product_id INT,
     order_status BOOLEAN,
     PRIMARY KEY(order_id) NOT ENFORCED
     ) WITH (
     'connector' = 'mysql-cdc',
     'hostname' = 'localhost',
     'port' = '3306',
     'username' = 'root',
     'password' = '123456',
     'database-name' = 'mydb',
     'table-name' = 'orders');
  
-- 从订单表读取全量数据(快照)和增量数据(binlog)
Flink SQL> SELECT * FROM orders;
```