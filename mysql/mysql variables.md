- max_allowed_packet,指的是一个数据包的最大的大小，或者由mysql_stmt_send_long_data()CAPI函数发送的参数或者任何生成的或者中间衍生的字符的最大大小。默认是64MB。


|Command-Line Format|System Variable|Scope|Dynamic|SET_VAR Hint Applies|Type|Default Value|Minimum Value|Maximum Value|Block Size|
|---|---|---|---|---|---|---|---|---|---|
|--max-allowed-packet=#|max_allowed_packet|Global,Session|Yes|No|Integer|67108864(64MB)|1024|1073741824|1024|
数据包的buffer会被初始化为net_buffer_length大小的bytes，但是需要时，可以增长到max_allowed_packet的大小。如果你在使用一些大的BLOB类型的或者长字符串类型的数据，你需要增加这个值，最好的不能小于你要使用的BLOB类型数据的最大值，上限值是1GB，这个值必须是1024的整数倍，不是整数倍的数会被舍入到整数倍的数。
当你改变这个值时，buffer size的最大大小也会改变，你也应该改变客户端的buffer size的大小；客户端的max_allowed_packet默认值通常是1GB，但是也有的客户端不是这个值，比如mysql是16mb，mysqldump是24mb。
session范围内的这个变量是只读的，客户端可以接收max_allowed_packet大小的数据包数据，但是服务端是按照当前的全局的max_allowed_packet设置大小发送数据包的，也就意味着如果全局的max_allowed_packet在连接后发生改变，它只能比session范围的max_allowed_packet设置小。
