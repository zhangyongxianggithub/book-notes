[TOC]
# Workflow for using and managing dependencies
- 在pkg.go.dev上寻找有用的包
- 导入包
- 将外部包添加为依赖
- 更新或者降低依赖的版本

# Managing dependencies as modules
Go中依赖就是模块的形式
# Locating and importing useful packages
# Enabling dependency tracking in your code
# Naming a module
模块名就是模块路径，模块路径是导入路径的前缀，确保模块路径的唯一性。模块路径的形式:
><prefix>/<descriptive-text>
- prefix是模块的前缀，比如描述来源，可以是: 1. 仓库的地址；2. 一个属于你的名字
- 描述性的文字，通常是项目名，记住，包的名字描述了功能性，模块创建了包的命名空间
# Adding a dependency
如果你正在从一个已发布的模块中导入包，可以使用`go get`来添加模块。
# Getting a specific dependency version
你可以通过在`go get`命令中指定版本来获得特定版本的模块，也可以手动编辑指定。
# Discovering available updates

