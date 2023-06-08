[TOC]
在这个入门指导中，你将会创建2个模块。第一个是一个lib，可以被其他的lib或者app导入，第二个是一个caller app。这个指南包含7个主题:
- 创建一个模块，这个模块有其他模块可以调用的函数;
- 从其他模块中调用代码，导入并使用你的新模块;
# Start a module that others can use
创建一个模块，这个模块包含多个相关的包与很多有用的函数集合。Go代码被分组到包中，包被分组到模块中。开发者在调用模块中的函数时会导入包，并在上线前测试。
- 创建一个目录
- 使用`go mod init`初始化一个模块，参数时模块的路径，如果你需要发布包，这个路径必须是一个可以通过Go工具下载的路径，通常是仓库的HTTP地址，关于如何给模块命名，参考[Managing dependencies](https://go.dev/doc/modules/managing-dependencies#naming_module)
  ```shell
  $ go mod init example.com/greetings
  go: creating new go.mod: module example.com/greetings
  ```
  这个命令创建了一个go.mod文件来跟踪你的程序的依赖。目前为止，你的模块只包含模块名与你的代码支持的Go版本，当你添加以来时，go.mod文件会列出你代码依赖的版本，你可以直接控制依赖模块的版本.
- 在模块中写代码

# Call your code from another module
- 像上面那样创建一个模块
- 写代码
- 将包的依赖替换成本地的，使用`go mod edit -replace`命令完成模块的远程下载到本地的重定向，比如下面的命令
  ```shell
  go mod edit -replace example.com/greetings=../greetings
  ```
  编辑完成后，可以得到的go.mod文件如下:
  >module example.com/hello
  go 1.16
  replace example.com/greetings => ../greetings

- 使用`go mod tidy`来同步依赖，之后go.mod文件的内容如下：
  >module example.com/hello
  >go 1.16
  >replace example.com/greetings => ../greetings
  >require example.com/greetings v0.0.0-00010101000000-000000000000

# Return and handler an error

# Return a random greeting

# Return greetings for multiple people

# Add a test

# Compile and install the application

# Conclusion
