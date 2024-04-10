# Name
java 启动一个Java应用
# Synopsis
为了启动一个class file:
```shell
java [options] mainclass [args ...]
```
为了启动一个JAR文件中的main class
```shell
java [options] -jar jarfile [args ...]
```
为了启动一个module中的main class
```shell
java [options] -m module[/mainclass] [args ...]
java [options] --module module[/mainclass] [args ...]
```
启动一个单文件程序
```shell
java [options] source-file [args ...]
```
- options, 可选的，命令行选项，通过空格分隔。
- mainclass, 要启动的类名，类名之后要传给主方法的参数
- -jar jarfile, 执行jar文件中的程序，jarfile是jar文件的名字，jar文件要包含一个清单文件，清单文件包含一行`Main-Class: classname`的信息，这个类定义了主方法，也就是你应用的启动点。当你使用了-jar参数，Jar文件要包含所有的用户类，并且其他类路径设置会被忽略。
- -m/--module module[/mainclass], 执行模块中的mainclass，可以只用模块本身的mainclass，也可以覆盖模块的mainclass
- source-file, 启动单文件程序，这个源文件包含main class，具体参考[Using Source-File Mode to Launch Single-File Source-Code Programs](https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html#using-source-file-mode-to-launch-single-file-source-code-programs)
- args ..., mainclass的参数

# Description
java命令启动一个Java应用。