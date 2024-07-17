[TOC]
本指南介绍了Go中的多模块工作空间的基础知识。使用工作空间，也就是说你在同时写多个模块。在这个指南中，你将在一个共享的空间中创建2个模块，在这些模块中做出变更，并在build后看到变更后的结果。
# Prerequisites
- Go>=1.18
# 首先创建一个模块
- 先创建一个workspace目录
- 在创建一个hello目录，在hello目录创建一个模块`go mod init example.com/hello`,接下来在模块中写代码
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
# 创建工作空间
在这个步骤中，我们会创建一个`go.work`文件来描述带有模块的工作空间，首先需要初始化workspace。
```shell
go work init ./hello    
```
这个命令会创建一个`go.work`文件，表示一个工作空间，这个工作空间包含了./hello文件夹中的模块。最后文件的内容如下:
```
go 1.20
use ./hello
```
`go.work`文件与`go.mod`的语法类似。use指令表示hello目录中的模块在做构建时应该是一个主模块。在workspace目录下的任何子目录中的模块都将是active的。Go命令

# Workspaces
一个工作区是根模块的集合，工作区可以声明在`go.work`文件中，其中含有表示工作区中每个模块的模块目录的相对路径，当`go.work`不存在时，工作区是当前模块。大多数模块相关的go子命令也可以操作模块集合，`GOWORK`环境变量表示当前是否在工作区上下文中，如果`GOWORK=off`，命令位于单模块上下文中，如果是空或者没有提供，则命令会搜索当前的工作目录或者上级目录来寻找`go.work`文件，如果找到，命令作用与它定义的工作空间，如果没有，工作区将会包含工作所在的模块，如果`GOWORK`是一个`*.work`文件的路径，工作区模式就是启用的，任何其他值都是错误的，你可以使用`go env GOWORK`命令来确认命令正在使用哪个`go.work`文件，如果命令不在工作空间模式下，则`go env GOWORK`返回空。工作区由`go.work`文件定义，它是UTF-8编码的文本文件，`go.work`是面向行的，每一行表示一个指令
```
go 1.18

use ./my/first/thing
use ./my/second/thing

replace example.com/bad/thing v1.4.5 => example.com/good/thing v1.4.5
```
