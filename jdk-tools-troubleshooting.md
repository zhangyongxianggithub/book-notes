# jinfo
生成配置信息
## 语法
jinfo [option] pid
jinfo [option] executable core
jinfo [option] [servier-id] remote-hostname-or-ip
- option, 命令选项；
- pid，需要生成的配置信息的进程ID，进程ID必须是一个JVM进程，可以通过jps命令得到机器上的所有的JVM进程；
- executable，需要产生配置信息的可执行体；
- core，生成配置信息的core文件；
- remote-hostname-or-ip，远程调试服务器名字或者地址；
- servier-id，指定远程主机上多个远程调试服务器中的其中一个的唯一ID。
## 描述
jinfo命令主要的作用是输出JVM进程的配置信息，也可以输出core文件或者一个远程调试服务器JVM进程的配置信息，输出的配置新包括：java系统属性与JVM命令行属性；如果进程是一个64-bit JVM进程，需要指定-J-D64选项。
## 选项
- no-option，打印所有的命令行属性与系统属性,这里有VM Flags与VM arguments，不知道这2个有什么分别；
- -flag name，打印指定命令行标识的名字与值（这里的选项只能是VM Flags里面的属性）；
- -flag [+/-]name，启用/禁用 Boolean类型的命令行标识；
- -flag name=value，设置指定的命令行标识的值；
- -flags 打印传输给JVM进程的命令行标识；
- -sysprops，打印java系统属性；
- -h 打印帮助信息；
- --help 打印帮助信息。

# jhat
用于分析堆内存的命令
## 语法
jhat [options] heap-dump-file
- options，命令行选项；
- heap-dump-file，二进制堆的转储文件，对于一个包含多个堆转储的文件来说，可以在文件后面加上#<number>指定分析哪个堆；
## 描述
jhat命令分析堆转储文件，并启动一个web服务器，可以用浏览器查看堆内容，jhat命令支持OQL（object query language）查询语言，有点类似SQL，jhat命令会生成OQL帮助，在缺省端口下，路径是http://localhost:7000/oqlhelp

生成java堆转储文件的办法如下：
- 使用jmap -dump获取运行时的堆转储；
- 使用jconsole通过HotSpotDiagnosticMXBean获取堆转储；
- 当虚拟机指定了-XX:+HeapDumpOnOutOfMemoryError选项时，发生了OOM就会自动生成堆转储文件；
- 使用hprof命令；
## 选项
- -stack false｜true，是否开启追踪对象调用栈；
- -refs false|true，是否追踪对象的引用；
- -port port-number，指定jhat的http服务器的端口；
- -exclude exculde-file，排除文件，里面定义了需要排除调的对象成员；
- -baseline exclude-file，指定一个基线堆文件，用来比较，如果对象出现在2个堆中，则是旧对象，而如果没出现在基线堆中，则是新的对象；
- -debug int，设置debug级别，级别越高，输出的debug信息就越多；
- -version jhat版本；
- -h 显示帮助信息；
- -help，同-h；
- -Jflag，向运行jhat命令的JVM进程传入JVM选项标识，比如-J-Xmx512m 设置最大的堆大小是512MB。
# jmap
打印一个JVM进程/core文件/远程debug服务器的堆内存详情或者共享对象内存。
## 语法
jmap [options] (pid | executable core |pid [server-id@] remote-hostname-or-IP )
- options 命令行选项
- pid JVM进程ID；
- executable 产生core dump的java可执行体；
- core dump文件；
- remote-hostname-or-IP 远程服务器名字或者IP地址；
- server-id 用来标识远程机器上的多个debug server中的一个。
## 描述
jmap命令打印JVM进程/core file/远程debug服务器的共享对象内存映射与堆内存的详细内容，如果JVM进程是64bit的，需要指定-J-d64选项，比如jmap -J-d64 -heap pid
## 选项
- <no option> 没有任何的选项时，jmap打印共享对象内存映射，对每个共享对象来说，会打印起始地址，映射大小还是全路径等信息；
- -dump:[live,] format=b,file=filename 以hprof的格式打印堆到filename文件中，指定live时，只会打印存活的对象，查看对转储，使用jhat命令；
- -finalizerinfo 打印等待终止的对象的信息；
- -heap 打印堆的总体使用情况，包括使用的GC、配置等；
- -histo[:live] 打印堆的柱状图，打印每个class的对象数量、内存大小等，live只会打印存活的对象；
- -clstats 打印类加载器的统计信息；
- -F force 强制；
- -h 打印帮助信息；
- -help 同-h；
= -Jflag jmap运行的JVM用到的参数。


