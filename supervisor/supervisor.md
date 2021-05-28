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
开启一个监听TCP的http server，默认是不开启的，注意安全风险
- port 一个TCP的端口，supervisor监听的端口号，superctl会通过这个端口号使用XML-RPC与superd通信，为了监听所有的地址，使用:9001或者*：9001地址
- username
- password
>[inet_http_server]
port = 127.0.0.1:9001
username = user
password = 123
## [supervisord]
有关supervisord的全局设置
- logfile supervisord活动日志指定，可以用%(here)s表示supervisord.conf文件的目录，如果指定了/dev/stdout，那么需要禁用日志的切片功能，比如logfile_maxbytes=0
- logfile_maxbytes 一个日志文件最大大小，设置0表示无限大
- logfile_backups 设置日志文件的保留数量，如果设置0，不会保留历史日志
- loglevel 日志级别与命令行的功能一致，如果设置为debug模式，子进程的输出也会被记录；
- pidfile pid文件地址，%(here)s也可以用
- umask supoervisord进程的掩码
- nodaemon 进制后台运行
- silent 不输出日志
- minfs 可用的文件描述符的最小数量，默认是1024
- minprocs 可用的进程描述符的最小数量，默认是200，
- nocleanup 禁止在启动时清理AUTO模式的子进程的日志文件；
- childlogdir AUTO模式的子进程日志存放日志的地方
- user 切换用户处理事情
- directory 当supervisord后台运行时，切换到这个目录，可以使用%(here)s
- strip_ansi 剥离转义序列
- environment 一系列的key/value对形式KEY="val",KEY2="val2"，会放置到环境变量中，这个环境变量只能是子进程可以看到，superd自己没有改变，如果包含不是数字或者字母的字符，需要用双引号包含，使用%转义字符。
- identifier superd进程的标识符，用于RPC接口中，默认是supervisor;
例子
>[supervisord]
logfile = /tmp/supervisord.log
logfile_maxbytes = 50MB
logfile_backups=10
loglevel = info
pidfile = /tmp/supervisord.pid
nodaemon = false
minfds = 1024
minprocs = 200
umask = 022
user = chrism
identifier = supervisor
directory = /tmp
nocleanup = true
childlogdir = /tmp
strip_ansi = false
environment = KEY1="value1",KEY2="value2"
# [supervisorctl]
- serveurl, 访问superd使用的URL，比如http://localhost:9001, 对于UNIX socket来说是unix:///absolute/path/to/file.socket,默认是http://localhost:9001
- username username for authentication
- password 
- prompt 交互式shell的提示符,默认是supervisor
- history_file 记录历史命令的的文件，readline可以读取历史命令重复执行；
>[supervisorctl]
serverurl = unix:///tmp/supervisor.sock
username = chris
password = 123
prompt = mysupervisor
# [program:x]
配置文件不许包含program块，这样superd知道管理哪些程序，块的名字是program:name的形式，名字是用来标识进程的，以便通过名字管理进程，名字可以通过%{program_name}s字符串被引用，[program:x]代表一个单一的进程组，这个进程组的数量由numprocs与process_name控制，如果配置保持不变，则[program:x]表示的组是x，里面由一个单一的进程也叫做x，主要是为了兼容早起的版本。如果[program:foo]块配置numprocs=3，process_name=%(program_name)s_%(process_num)02d，foo这个进程组就会包含3个进程，分别名字是foo_00,foo_01,foo_02, 这样可以一个配置启动多个进程。
- command，程序启动时执行的命令，命令可以是绝对路径，也可以是相对路径，如果是相对的，就会使用PATH来搜索命令，程序可以接收参数，可以用双引号把参数包起来.
- process_name Python字符串，组成进程的名字，如果设置了numprocs，需要设置process_name, 字符串中可以包含的变量包括group_name，host_node_name，process_num，program_name与here（superd配置文件的目录），默认的名字是%{program_name}s
- numprocs 启动程序的多个实例，由numprocs命名，如果numprocs>1， process_name表达式必须包含%{process_num}s，默认值是1
- numprocs_start 用来定义进程的起始编号，默认是0；
- priority 程序启动与关闭的优先级，当批量操作时，这个有作用，优先级越低的越先启动，越晚关闭，默认值时999
- autostart 当=true时，supurd启动时自动启动程序，默认是true
- startsecs 程序启动后，多少秒之后，可以认定程序启动成功，STARING状态变成RUNNING状态，设置为0后，程序将保持STARTING状态，默认值是1；
- startretries 最大重试次数，之后会放入FATAL状态，默认值是3；
- autorestart 指定当进程存在且处于运行态时，是否自动重启一个进程，可以是false、unexpected、true这3个值，如果是false，进程不会自动重启，如果是unexpected,当进程的终止码不是exitcodes里面的值时则重启，如果时true，当进程终止就自动重启进程，默认值时unexpected。
- exitcodes 程序终止时期望的终止码，autorestart会用到，默认值是0；
- stopsignal 用来终止程序的信号，可以是TERM、HUP、INT、QUIT、KILL、USR1、USR2，默认值是TERM；
- stopwaitsecs 进程终止后，superd需要等待OS传递给自己SIGCHLD信号，如果超过时间，siperd会发送信号SIGKILL到终止的进程，默认值是10s；
- stopasgroup 如果设置为true，superd会发送终止信号到进程组，这意味着killasgroup=true，这对于处于debug模式的程序有帮助，后面没看懂，默认值是false；
- killasgroup 默认值是false
- user 指定运行程序的user，superd必须是以root运行的才可以选择用户，如果选择的用户不能切换，则程序运行失败；
- redirect_stderr 如果是true，则把process的stderr的日志输出到superd的stdout，默认是false;
- stdout_logfile stdout输出到日志，相当于重定向，如果stdout_logfile未设置或者被设置为AUTO，supervisor会自动选择一个文件位置，如果设置为NONE，则supervisor不会创建log文件，当superd重启时，AUTO模式的日志会被爱删除，可以使用变量默认值是AUTO
- stdout_logfile_maxbytes 日志文件的最大大小，之后切片，0代表无限大小，默认值是50MB;
- stdout_logfile_backups 日志文件保留的数量，如果设置为0，不保留历史日志，默认值是10;
- stdout_capture_maxbytes 不知道啥意思，设置为0关闭process capture mode，默认是0；
- stdout_events_enabled，如果=true，不知道啥意思;
- stdout_syslog 如果设置为true，stdout的值会被定向到syslog，默认值是False;
- stderr_logfile 与stdout的设置基本一致,默认值是AUTO；
- stderr_logfile_maxbytes；
- stderr_logfile_backups；
- stderr_capture_maxbytes;
- stderr_events_enabled;
- stderr_syslog;
- environment 一系列的键值对，形如KEY="val",KEY2="val2"，这个环境变量将会被插入到子进程使用的环境变量中，值可以包含字符串表达式；
- directory 在执行子进程前，临时切换到这个目录，chdir,默认是不切换；
- umask 进程的umask码,默认继承于superd
- serverurl 这个值会作为SUPERVISOR_SERVER_URL的值传递给子进程的环境变量中，进程可以与http server通信，如果提供了，语法与[supervisorctl]块内的serverurl相同，如果设置为AUTO或者未设置，superd会自动使用一个server url，优先使用unix domain socket，默认是AUTO
>[program:cat]
command=/bin/cat
process_name=%(program_name)s
numprocs=1
directory=/tmp
umask=022
priority=999
autostart=true
autorestart=unexpected
startsecs=10
startretries=3
exitcodes=0
stopsignal=TERM
stopwaitsecs=10
stopasgroup=false
killasgroup=false
user=chrism
redirect_stderr=false
stdout_logfile=/a/path
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=10
stdout_capture_maxbytes=1MB
stdout_events_enabled=false
stderr_logfile=/a/path
stderr_logfile_maxbytes=1MB
stderr_logfile_backups=10
stderr_capture_maxbytes=1MB
stderr_events_enabled=false
environment=A="1",B="2"
serverurl=AUTO
## [include]
files= files to include
- files 空格分隔的文件列表，文件可以是绝对路径或者相对路径，如果是相对路径，则相对的是配置文件supervisord.conf的路径，文件可以是一个模式* ？[] 等正则表达式。
>[include]
files = /an/absolute/filename.conf /an/absolute/*.conf foo.conf config??.conf
## [group:x]
