简单强大的网络命令行工具，这个命令实际上是Netcat，用于在网络链接上发送/接收原生数据，通过TCP、UDP在网络中读写数据，它被设计为一个可靠的后端工具，功能十分强大，可以创建任意类型的网络。
具体的用途有：
- 端口扫描: 进行端口扫描，探测端口是否打开以及目标机器服务是否活着，支持多端口扫描;
- 简单的TCP代理
- 基于脚本的HTTP客户端与服务器
- 网络后台服务测试
## Syntax
> nc [-46bCDdhklnrStUuvZz] [-I length] [-i interval] [-O length] 
   [-P proxy_username] [-p source_port] [-q seconds] [-s source] 
   [-T toskeyword] [-V rtable] [-w timeout] [-X proxy_protocol] 
   [-x proxy_address[:port]] [destination] [port]

Options:
- -4 强制nc只使用IPv4地址;
- -6 强制nc只使用IPv6地址;
- -b 允许广播;
- -C 发送CRLF作为行的结束符;
- -D 在socket上开启debugging
- -d 不从stdin读取输入;
- -h 打印帮助信息;
- -I *length* 指定TCP接收buffer的大小;
- -i *interval* 指定延迟的时间间隔，可以时发送/接收文档行的之间间隔，也可以是连接多个端口时的时间间隔;
- -k 强制nc在当前的连接完成后仍然监听另一个连接;
- -l 用于指定nc应该监听一个输入连接，而不是初始化一个连接到远程host的连接，当与-p、-s、-z选项使用时会造成错误，另外，使用-w指定的任何超时都会被忽略;
- -n 不做DNS域名查找;
- -O *length* 指定TCP发送buffer的大小;
- -P *proxy_username* 指定要呈现给需要身份验证的代理服务器的用户名。 如果未指定用户名，则不尝试验证。 目前仅 HTTP CONNECT 代理支持代理身份验证;
- -p *source_port* 指定nc使用的端口;
- -q *seconds* 在stdin输入EOF后，等待指定的之间后结束，如果是负数，则无限等待;
- -r 指定应随机选择源端口或目标端口，而不是在一个范围内或按系统分配它们的顺序顺序选择;
- -S 开启RFC 2385 TCP MD5签名支持;
- -s source 指定用于发送数据包的接口的 IP。 对于 UNIX 域数据报套接字，指定要创建和使用的本地临时套接字文件，以便可以接收数据报。 将此选项与 -l 选项结合使用是错误的;
- -T *toskeyword* 改变IPv4的TOS值;
- -t 导致 nc 向 RFC 854 DO 和 WILL 请求发送 RFC 854 DON'T 和 WON'T 响应。 这使得使用 nc 编写 telnet 会话脚本成为可能;
- -U 指定要使用的UNIX-domain sockets
- -u 指定使用UDP而不是默认的TCP;
- -V *rtable* 设置要使用的路由表，默认是0;
- -v 输出更多的verbose信息;
- -w timeout 超时秒后无法建立或空闲超时的连接。 -w 标志对 -l 选项没有影响，即 nc 永远监听连接，无论有没有 -w 标志。 默认为无超时;
- -X *proxy_protocol* 请求 nc 在与代理服务器通信时应使用指定的协议。 支持的协议是“4”（SOCKS v.4）、“5”（SOCKS v.5）和“connect”（HTTPS 代理）。 如果未指定协议，则使用 SOCKS 版本 5;
- -x *proxy_address[:port]* 请求 nc 应使用 proxy_address 和端口处的代理连接到目标。 如果未指定端口，则使用代理协议的知名端口（SOCKS 为 1080，HTTPS 为 3128）;
- -Z DCCP模式;
- -z 指定 nc 应该只扫描监听守护进程，而不向它们发送任何数据。 将此选项与 -l 选项结合使用是错误的;

**destination**是一个IP地址活着hostname，通常来说，必须指定destination，除非使用-l选项，这时候使用localhost，对于UNIX-domain sockets，必须要指定destination，通常是要连接的socket path.
**port**是一个端口或者多个端口，指定范围端口的形式是nn-mm，通常来说，port也是必须要指定的.
