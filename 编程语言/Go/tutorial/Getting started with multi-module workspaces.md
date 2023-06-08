[TOC]
本指南介绍了Go中的多模块工作空间的基础知识。使用工作空间，也就是说你在同时写多个模块。在这个指南中，你将在一个共享的空间中创建2个模块，在这些模块中做出变更，并在build后看到变更后的结果。
# Prerequisites
- Go>=1.18
# Create a module for your code
- 先创建一个workspace目录
- 在创建一个hello目录，在hello目录创建一个模块，创建一个module`go mod init example.com/hello`,接下来在module
- 写代码;
  ```go
  package main
    import (
        "fmt"
        "golang.org/x/example/stringutil"
    )
    func main() {
    fmt.Println(stringutil.Reverse("Hello"))
    }
  ```
# Create the workspace
在这个步骤中，我们会创建一个go.work文件来描述带有模块的workspace，首先需要初始化workspace。
```shell
go work init ./hello    
```
这个命令会创建一个go.work文件，表示一个workspace，这个workspace包含了./hello文件夹中的模块。最后文件的内容如下:
```
go 1.20
use ./hello
```
go.work文件与go.mod的语法类似。use指令表示hello目录中的模块是主module。在workspace木哭瞎的任何子目录都将是active的。Go命令

