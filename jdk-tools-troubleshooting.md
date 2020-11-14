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
