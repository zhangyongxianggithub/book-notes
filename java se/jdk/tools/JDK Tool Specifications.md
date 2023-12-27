# jmap命令
## Name
打印指定进程的详细信息
## Synopsis
**Note**: 这个命令是实验性的，未来可能会被移除
jmap [options] *pid*

- options: 表示jmap的命令行选项
- pid: 要打印详细信息的进程ID，进程必须是一个Java进程，获取机器上运行中的Java进程使用`ps`命令或者如果JVM进程没有运行在单独的docker中的话，也可以使用`jps`命令

## Description
jmap命令打印指定的运行进程的详细信息。
**Note**: 这个命令在未来的JDK发布版本中可能会被移除。在Windows系统中，如果存在`dbgeng.dll`文件，则必须安装`Debugging Tools for Windows`来使用这些工具命令，PATH环境变量应该包含`jvm.dll`文件的路径
## Options for the jmap Command
- -clstats pid: 连接到一个运行的Java进程，打印Java堆的class loader的统计信息
- -finalizerinfo pid: 连接到一个运行的Java进程，打印等待终止对象的的信息
- -histo[:live] pid: 连接到一个运行的Java进程, 打印Java对象堆的直方图或者柱状图，如果指定来了live子选项，则只计算live的对象
- -dump:dump_options pid: 连接到一个运行的Java进程，转储Java堆，dump_options包括:
  - live: 只转储live的对象
  - format=b: 以hprof二进制格式转储Java堆
  - file=filename: 转储到的文件名
## Examples
```shell
jmap -dump:live,format=b,file=heap.bin
```