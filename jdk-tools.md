# 记录下学习jdk工具的一些知识
## jps命令
jps工具的全称是Java Virtual Machine Process Status，中文名字就是Java虚拟机进程状态工具，
### 语法：
jps [options] [hostid]

### parameters
- options, 命令行选项；
- hostid,进程的唯一标识，可能是uri格式的，包含协议、端口号等；
### 描述
jps会以一种仪表话的形式列出目标系统上的jvm进程，只能列出它有权限访问的jvm进程；
如果没有指定hosid，则查找本地，如果指定，则会去目标系统上去寻找，目标系统必须运行一个jstatd进程才可以；
jps命令在仪表中会列出jvm进程的进程标识，lvmid，lvmid一般来说是操作系统里面的进程号，也会列出jvm进程的名字，这个名字通常是应用入口的Class的名字或者jar文件的文件；
jps使用java启动器来发现class名字以及传给main方法的参数，如果进程使用了自定义的java启动器，那么得到的名字与参数是UNKNOWN；
jps只会输出它可以访问的JVM进程的信息，可以访问哪些进程由运行的用户权限决定；
### OPTIONS
这些选项只是用来改变命令的输出，未来有可能移除；
- -q 隐藏进程名字与传入到main方法的参数，只显示jvm进程标识符；
- -m 显示传输给main方法的参数，对于内置的JVM来说，这里显示null；
- -l 输出class的包名或者jar文件的全路径名；
- -v 输出传递给JVM的参数；
- -V 输出通过flag文件（.hotspotrc文件或者通过-XX:Flags=\<filename>）的方式传递给JVM的参数;
- -Joption 传递参数给由jps调用的java启动器启动的JVM进程的参数，比如：-J-Xms48m 设置启动内存是48MB，-J标记是一种约定，在传递参数给内部的虚拟机引用程序的情况下；
### HOST IDENTIFIER
JVM进程标识符是一个字符串，语法类似于URI的语法：
[protocol:][[//]hostname][:port][/servername]
- protocol,通信协议，如果没有指定protocol与hostname，缺省的协议是本地，如果指定了hostname，那么缺省的协议是rmi；
- hostname,主机名或者IP地址；
- port,与远程服务器通信的端口号，如果使用的是本地协议，那么port会被忽略，如果使用的是RMI协议，那么端口号就是远程服务器上的rmiregistry的端口号，缺省的情况下是1099；
- servername,如果是本地，则忽略这个，如果是rmi协议，参数代表RMI远程对象的名字；
### OUTPUT FORMAT
jps的输出如下：
lvmid [[classname|JARfilename|Unknown][arg*][jvmarg*]]
所有的输出的字段都通过空白符隔开，需要注意的是，当arg包含内置的空白符的时候，可能导致整体的输出会有点混乱。
### EXAMPLES
这一节提供几个jps命令的例子
列出本地机器上的JVM进程：
![](附件/jps命令输出.png)
待-l参数会出现比较长的名字：
![](附件/jps命令输出-l.png)

# jstat
jstat的命令全称是Java Vitual Machine Statistics Monitoring Tool 中文名Java虚拟机概况监控工具。
## SYNOPSIS
jstat [generalOption|outputOptions vmid [interval [ s|ms ][count]]]
## PARAMETERS
- generalOption 一个单独的只出现一次的命令行选项 -help或者-options
- outputOptions 一个或者多个输出选项，包含一个单独的statOption，比如-t、-h、-J选项
- vmid 虚拟机进程标识符，可以是本地的也可以是远程的；
- interval[s|ms] 输出/采样间隔时间与单位；
- count 采样展示次数，缺省是无限的一直到虚拟机终止或者jstat终止，必须是一个正数；
## DESCRIPTION
jstat展示jvm进程的性能统计数据。
## VIRTUAL MACHINE IDENTUIFIER
vmid的语法与URI类似：
[protocol:][//]lvmid[@hostname][:port][/servername]
- protocol 没法判断是远程的时候，使用一种本地协议，如果vmid看起来是远程的，那么缺省是rmi；
- lvmid 本地的JVM进程标识符，用来在一个系统中唯一标识一个JVM进程，lvmid是必须提供的，一般来说就是每个操作系统中进程的进程号；
- hostname 主机名或者远程地址；
- port 端口号，如果使用的是RMI，缺省的port是1099；
- servername 如果是RMI，servername代表RMI远程对象的名字。
## OPTIONS
