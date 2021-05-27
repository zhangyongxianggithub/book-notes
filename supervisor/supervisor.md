supervisor： 一个进程控制系统
supervisor是一个客户/服务端的系统允许用户监控或者控制类unix操作系统上的大量的进程。
它的作用与launchd、daemontools、runit等类似，但是不同的是，它必须要运行init进程或者以编号1的进程号运行。
# introduction
## overview
supervisor的优势：
- 方便，不需要写启动脚本，可以自动重启。
- 精确，因为是以子进程的方式启动的，所以堆进程得分状态可以实时的掌握；
- 委托，避免了一些权限问题；
- 进程组。
## features
- 简单，配置文件非常好学
- 中央化，很多进程的处理集中；
- 有效，
- 可拓展，
- 兼容性
- 久经考验
## supervisor组件
- supervisord，supervisor后台进程，负责启动子进程、响应客户端的命令、重启崩溃的进程，或者结束子进程，打印子进程输出到标准输出与标准输入，生成与处理事件，服务端进程使用配置文件配置，通常位于/etc/supervisord.conf.
- supervisorctl, 命令行客户端，它提供了supervisord访问的接口，这些接口包括很多处理子进程的处理操作，比如状态、停止或者启动子进程等。客户端通过一个UNIX domainsocket或者TCP与服务端通信。
- Web Server，与ctl功能一样的web接口。
# 安装
echo_supervisord_conf 打印一个例子到标准输出。supervisord -c supervisord.conf
-c 指定配置文件的位置。
# 运行Supervisor
## 添加一个进程
## 运行Supervisord
为了开启一个supervisord，直接运行这个命令就行，这个命令可以让supervisord直接变为后台进程并与终端断开。默认情况下，当前目录下会有一个supervisor.log日志文件记录启动过程，supervisord启动时会去一些指定的位置搜索配置文件，比如当前目录，如果配置文件或者程序集发生了变更，可以重新启动supervisord或者执行kill -HUP来重新加载文件，支持的命令行选项如下（也可以在配置文件中配置）
|unix风格|GNU linux风格|描述|
|:-|:-|:-|
|-c FILE|--configuration=FILE|配置文件地址|
|-n|--nodaemon|不以后台进程的方式运行|
|-s|--silent|不输出信息到标准输出|
|-h|--help|帮助|
|-u USER|--user=USER|UNIX的用户或者id|
|-m OCTAL|--umask=OCTAL|supervisord使用的8进制权限掩妈|
|-d PATH|--directory=PATH|在supervisord以后台的方式运行前，cd到这个目录|
|-l FILE|--logfile=FILE|supervisord的活动日志|
|-y BYTES|--logfile_maxbytes=BYTES|互动日志触发切片的最大单个日志文件大小，数字需要指定MB，KB，GB等单位|
|-z NUM|--logfile_backups=NUM|活动日志保留的备份数量|
|-e LEVEL|--loglevel=LEVEL|活动日志的日志级别，可用的日志级别trace, debug, info, warn, error, critical|
|-j FILE|--pidfile=FILE|supervisord写pid的文件名|
|-i STRING|--identifier=STRING|supervisord实例的字符串标识符|
|-q PATH|--childlogdir=PATH|auto模式的子进程写日志的目录|
|-k|--nocleanup|进制supervisord在启动时执行日志清理计划|
|-a NUM|--midfs=NUM|supervisord在启动时必须满足的最小的文件描述符的数量|
|-t|--strip_ansi|转义|
|-v|--version|版本|
||--profile_options=LIST|profiling列表，让supervisord运行在一个profiler下，输出的内容会添加这个标识|
||minprocs=NUM|supervisord使用的OS进程的最小数量|
## 运行supervisorctl
会出现一个shell，当supervisorctl有参数的时候，不会出现shell，比如supervisorctl stop all。
命令行参数如下：
|unix风格|GNU linux风格|描述|
|:-|:-|:-|
|-c|--configuration|配置文件路径，默认是/etc/supervisord.conf|
|-h|--help|帮助|
|-i|--interactive|开启一个交互式的shell|
|-s URL|--serverurl URL|supervisord监听的url|
|-u|--username|开启了认证时的username|
|-p|--password|开启了认证时的密码|
|-r|--history-file||

action [arguments]
actions是命令如tail、stop等
## supervisorctl Actions
- help 打印所有的actions
- help <action> 打印action的帮助信息
- add <name>[...] 激活进程/组在配置上的更新
- remove <name> [...] 从激活的配置中移除进程/组
- update 重载配置，根据配置add/remove进程，并且重启受影响的进程
- update all 重载配置，根据配置add/remove进程，并且重启受影响的进程
- update <gname> [...] 更新指定的组，并重启受影响的程序
- clear <name> 清理进程的日志文件
- clear <name> <name> 清理多个进程的日志文件
- clear all 清理所有进程的日志文件
- fg <process> 把一个进程变成前台进程，Ctrl+C终止前台进程
- pid获得supervisord的pid
- pid <name> 获得子进程的pid
- pid all 获得所有子进程的pid
- reload 重启远程的supervisord
- reread 重载后台进程的配置文件，但是不会重启进程
- restart <name> 重启一个进程（不会重新读取配置文件）
- restart <gname>:* c重启组内的所有的进程，不会重新读取配置文件
- restart <name> <name>
- signal 
- start <name> 开启进程
- start <gname>:* 启动一个组下的所有的进程
- start <name> <name> 开启一个或者多个进程
- start all 开启所有的进程
- status 获得所有进程的状态信息
- status <name> 一个进程的状态信息
- status <name> <name>
- stop <name> 停止一个进程
- stop <gname>:*
- stop <name> <name>
- stop all
- tail [-f] <name> [stdout|stderr] 输出最近的日志，-f跟踪最新的日志 -n ，输出最近日志的多少字节
## Signals
supervisord能接收到信号，并根据信号执行特定的处理。信号处理器
- SIGTERM 终止super及其子进程
- SIGINT 终止super及其子进程
- SIGQUIT 终止super及其子进程
- SIGHUP super会终止所有的进程，重载配置文件并重新启动所有的进程
## 运行时安全
# 配置文件
super的配置文件叫supervisord.conf，superd与superctl都会使用到这个配置文件，如果没有通过-c的方式指定配置文件，super将会在以下的位置寻找supervisord.conf, 第一次找到就停止:
- ../etc/supervisord.conf
- ../supervisord.conf
- ${CWD}/supervisord.conf
- ${CWD}/etc/supervisord.conf
- /etc/supervisord.conf
- /etc/supervisor/supervisord.conf
## 文件格式
是ini格式的文件，含有块[header]与块内的key/value对，value中可以使用操作系统环境变量，%{ENV_X}s的形式，比如
>[program:example]
command=/usr/bin/example --loglevel=%(ENV_LOGLEVEL)s

## [unix_http_server]块
配置监听UNIX domain socket的HTTP server的参数，如果没有这个块，就不会启动http server，常用于进程间的通信，允许的值如下：
- file 一个UNIX domain socket路径，supervisor会监听这个socket来获得http请求，superctl会使用XML-RPC的方式与supervisord通信；
- chmod 修改上面socket文件的权限，默认是0700
- chown 修改socket文件为指定的用户或者组，比如chrism或者chrism:wheel,默认的用户是启动superd的用户
- username http server需要认证时的username
- password 认证时的密码，{SHA}哈希编码后的密码

例子
>[unix_http_server]
file = /tmp/supervisor.sock
chmod = 0777
chown= nobody:nogroup
username = user
password = 123

## [inet_http_server]
