打印一个JVM进程/core文件/远程debug服务器的堆内存详情或者共享对象内存。在新的JDK版本下，有所不同。
# 语法
**注意**: 这个命令是一个实验性的，未来可能会被移除
jmap [options] (pid | executable core |pid [server-id@] remote-hostname-or-IP )
- options 命令行选项
- pid JVM进程ID，获取Java进程，使用`ps`或`jps`命令
- executable 产生core dump的java可执行体；
- core dump文件；
- remote-hostname-or-IP 远程服务器名字或者IP地址；
- server-id 用来标识远程机器上的多个debug server中的一个。
# 描述
jmap命令打印JVM进程/core file/远程debug服务器的共享对象内存映射与堆内存的详细内容，如果JVM进程是64bit的，需要指定-J-d64选项，比如jmap -J-d64 -heap pid
# 选项
## 旧版本的
- \<no option> 没有任何的选项时，jmap打印共享对象内存映射，对每个共享对象来说，会打印起始地址，映射大小还是全路径等信息；
- -dump:[live,] format=b,file=filename 以hprof的格式打印堆到filename文件中，指定live时，只会打印存活的对象，查看对转储，使用jhat命令；
- -finalizerinfo 打印等待终止的对象的信息；
- -heap 打印堆的总体使用情况，包括使用的GC、配置等；
- -histo[:live] 打印堆的柱状图，打印每个class的对象数量、内存大小等，live只会打印存活的对象；
- -clstats 打印类加载器的统计信息；
- -F force 强制；
- -h 打印帮助信息；
- -help 同-h；
- -Jflag jmap运行的JVM用到的参数。
  
## 新版本的
- -clstats *pid*: 连接到一个运行中的进程，打印Java堆的class loader的统计信息
- -finalizerinfo *pid*: 连接到一个运行中的进程，打印等待finalization对象的信息
- -histo[:live] *pid*: 连接到一个运行中的进程，打印Java对象堆的柱状图，如果指定了live子选项，只计算live的对象
- -dump:*dump_options* *pid*: 连接到一个运行中的进程，dumps Java堆，dump_options包含的子选项包括:
  - live: 只dumplive的对象，如果没有指定，dump堆中的所有对象
  - format=b: 用hprof的二进制格式dump Java堆
  - file=filename, 将堆转储到filename指定的文件中
# example
```bash
jmap -dump:live,format=b,file=heap.hprof pid
```