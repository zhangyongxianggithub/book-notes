[TOC]
你可以收集相关的包到一个模块中，然后发布模块以便其他开发者使用。这个主题是关于开发/发布模块的总述。为了支持开发、发布与使用模块，你需要:
- 一个开发/发布模块的工作流程，并且使用版本号来标识版本。可以看[Workflow for developing and publishing modules](https://go.dev/doc/modules/developing#workflow)
- 设计实践，帮助模块的用户理解它或者使用一种稳定的方式升级版本，[Design and Development](https://go.dev/doc/modules/developing#design)
- 一个去中心化的系统，用于发布模块与检索代码。你可以发布到自己的仓库，详情[Decentralized publishing](https://go.dev/doc/modules/developing#decentralized)
- 包搜索引擎/文档浏览器，开发者可以发现你的模块。[Package Discovery](https://go.dev/doc/modules/developing#discovery)
- 一个包版本号规范，[Versioning](https://go.dev/doc/modules/developing#versioning)
- Go tools, 方便其他开发者管理依赖，包括[Managing Dependencies](https://go.dev/doc/modules/managing-dependencies)
# Workflow for developing and publishing modules
发布模块时，你需要使用一些约定，这样可以使模块更容易使用。下面的几个概要步骤详细描述在[Module release and versiong workflow](https://go.dev/doc/modules/release-workflow)。
- 设计实现包
- 提交代码到你的仓库
- 发布模块，让其他开发者可以发现你的模块
- 发布模块的版本号，使用版本号的规范。

# Design and development
如果你的模块中的函数或者包是一个整体，那么你的模块将会更容易发现与使用。当你设计模块的public API时，需要考虑其功能的集中与离散。设计与开发模块，需要考虑向后兼容性，这样永辉可以无损升级你的模块。你可以使用一些特定的技术手段来避免破坏向后兼容。更详细的信息可以参考[Keeping your modules compatible](https://blog.golang.org/module-compatibility)。在发布模块前，你可以使用replace指令来在本地文件系统中引用。这样调用正在开发中的包中的函数将会变得容易。具体信息可以参考[Module release and versiong workflow](https://go.dev/doc/modules/release-workflow#unpublished)使用未发布的模块编码。
# Decentralized publishing
在Go中，你可以把你的模块push到你自己的仓库中，并给代码打标签。Go工具可以直接从你的仓库中下载模块。使用模块路径，这是一个去掉schema的url。在代码中导入包后，开发者使用Go工具来下载模块代码。为了支持这种方式，你需要遵守一些规范与最佳实践来让Go工具检索你的模块的源代码。比如，Go工具使用模块的module path与模块版本号来定位模块的tag并下载模块。对于更多的信息参考[Managing module source](https://go.dev/doc/modules/managing-source)。对于发布模块的详细步骤[Publishing a module](https://go.dev/doc/modules/publishing)
# Package discovery
在你发布你的模块后，某些人使用Go工具拉取你的模块。你的模块在包搜索网址pkg.go.dev将会可见。开发者可以搜索site来发现并阅读模块文档，开始使用这个模块后，开发者从模块中导入包，然后运行go get来下载源代码。
# Versioning
当你升级你的模块的版本号时，你分配版本号，需要考虑版本兼容性。
