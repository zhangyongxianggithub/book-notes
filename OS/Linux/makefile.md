Makefile是给`make`命令使用的，用于描述构建的过程，Makefile文件由一系列规则构成，Makefile的规则:
```makefile
target ... : prerequisites ...
    recipe
    ...
    ...
```
- target(目标), 可以是一个目标文件、可执行文件或者标签(伪目标)，比如
  ```makefile
    clean:
        rm *.o
  ```
  这是一个伪目标，但是如果工作目录存在clean文件，那么make检测到文件已经存在，就不会执行操作，明确声明clean是伪目标可以避免这种情况
  ```makefile
    .PHONY: clean
    clean:
            rm *.o temp
  ```
  如果没有make时没有指定目标则默认会执行Makefile文件的第一个目标。
- prerequisites(前置条件)，生成该target依赖的文件或其他target，空格分隔
- (tab)recipe，target要执行的命令，任一的shell命令，目标就是生成目标文件，命令的前面的tab可以通过内置变量`.RECIPEPREFIX`决定，每行命令在一个单独的shell中执行，这些shell没有继承关系，如果要2个命令在一个shell中执行，可以写在一行并用;号分隔或者用连行符转义，
每条规则的2件事
- 构建目标的前置条件是什么
- 如何构建

Makefile里面主要包含5个东西:
- 显式规则，说明了如何生成一个或多个目标文件，由makefile的书写者明显指出要生成的文件、文件的依赖文件和生成的命令;
- 隐式规则，由于我们的make有自动推导的功能，所以隐式规则可以让我们比较简略地书写Makefile，这是由make所支持的;
- 变量的定义，都是字符串，类似c语言中的宏，当Makefile被执行时，其中的变量都会被扩展到相应的引用位置上`$()`，调用shell变量要使用2个$符号
- 指令，make会打印每个命令，然后执行，前置`@`符号可以关闭回声，通常在注释和纯显示的echo命令前面加上`@`
- 注释， 只有行注释，#表示注释
- 通配符，*、?、[...]，指定一组符合条件的文件名
- 

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
1. make会显示要执行的命令，使用@字符放到命令前，则不会显示要执行的命令，-n参数显示命令，但是不执行，-s参数禁止命令的显示
2. 依赖目标比当前的目标新时，规则的目标要被执行，如果在前面命令的基础上执行，则2个命令写在一行，用分号分隔，否则认为是2个全新的命令。make一般是使用环境变量SHELL中所定义的系统Shell来执行命令，默认情况下使用UNIX的标准Shell——/bin/sh来执行命令