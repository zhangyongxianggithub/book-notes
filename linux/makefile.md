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
