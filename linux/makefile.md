makefile的规则:
```makefile
target ... : prerequisites ...
    recipe
    ...
    ...
```
- target, 可以是一个目标文件、可执行文件或者标签;
- prerequisites，生成该target依赖的文件和/或者target
- recipe，target要执行的命令，任一的shell命令

makefile里面主要包含5个东西:
- 显式规则，说明了如何生成一个或多个目标文件，由makefile的书写者明显指出要生成的文件、文件的依赖文件和生成的命令;
- 隐式规则，由于我们的make有自动推导的功能，所以隐式规则可以让我们比较简略地书写Makefile，这是由make所支持的;
- 变量的定义，都是字符串，类似c语言中的宏，当Makefile被执行时，其中的变量都会被扩展到相应的引用位置上
- 指令，
- 注释， 只有行注释，#表示注释

$(shell command)的方式获得shell命令执行的结果
# 书写规则
1. 伪目标，伪目标并不是一个文件，只是一个标签，因为不是文件，所以无法生成依赖关系以及决定它是否要执行。使用`.PHONY`表示。可以为伪目标指定所依赖的文件。伪目标同样可以作为默认目标，只要将其放在第一个。一个示例就是，如果你的Makefile需要一口气生成若干个可执行文件:
   ```makefile
    all : prog1 prog2 prog3
    .PHONY : all

    prog1 : prog1.o utils.o
        cc -o prog1 prog1.o utils.o

    prog2 : prog2.o
        cc -o prog2 prog2.o

    prog3 : prog3.o sort.o utils.o
        cc -o prog3 prog3.o sort.o utils.o
   ```
   
# 书写命令
规则中的命令就是操作系统shell中的命令，必须以tab开头，或者命令紧跟在规则的分号后面。make命令的默认shell是/bin/sh。
1. make会显示要执行的命令你，使用@字符放到命令前，则不会显示要执行难的命令，-n参数显示命令，但是不执行，-s参数禁止命令的显示
2. 依赖目标比当前的目标新时，规则的目标要被执行，如果在前面命令的基础上执行，则2个命令写在一行，用分号分隔，否则认为是2个全新的命令。make一般是使用环境变量SHELL中所定义的系统Shell来执行命令，默认情况下使用UNIX的标准Shell——/bin/sh来执行命令