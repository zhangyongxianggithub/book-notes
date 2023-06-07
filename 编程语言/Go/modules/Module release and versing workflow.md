[TOC]
开发模块时，有一个标准的开发流程，可以开发一个稳定的可靠的，体验一致的模块。这个开发流程的步骤如下
# Common workflow steps
下面的步骤就是发布一个新的模块的步骤:
- Begin a module, 组织源代码，让开发者容易使用，让你容易维护。如果你对开发模块还比较陌生，请参考[Tutorial: Create a Go module](https://go.dev/doc/tutorial/create-module);
- write local client code，调用未发布的模块中的函数，在你发布一个模块前，对于是用传统的go get方式的依赖管理的项目是不能用的，这个阶段测试你的模块的最好的方式就是在本地的文件夹中测试，[Coding against an unpublished module](https://go.dev/doc/modules/release-workflow#unpublished)
- 当其他的开发者可以使用模块代码时，发布v0预发布版本作为alphas与betas版本，参考[Publishing pre-release versions](https://go.dev/doc/modules/release-workflow#pre-release)获得详细的信息;
- 发布一个v0版本，是不保证稳定的，但是用户可以使用，详细信息参考[Publishing the first version](https://go.dev/doc/modules/release-workflow#first-unstable)
- 在v0版本发布后，你可能会继续发布新的版本，这些新的版本可能包含bug fixes、模块的public API甚至是破坏性的变更，因为v0版本不保证稳定性与向后兼容性，你可以在这个版本做较大的变更,更多的信息可以参考[Publishing bug fixes](https://go.dev/doc/modules/release-workflow#bug-fixes)与[Publishing non-breaking API changes](https://go.dev/doc/modules/release-workflow#non-breaking)
- 当你做出了一个稳定的发布版本，发布一个预发布版本作为alphas/betas版本;
- 发布v1为第一个稳定版本，这是第一个能够确保一定稳定性的发布版本，更多的信息参考[Publishing the first stable version](https://go.dev/doc/modules/release-workflow#first-stable)
- 在v1版本，继续bug fix
- 如果避免不了做出破坏性变更，就发布一个新的major版本的模块，major版本更新，比如从v1.x.x到v2.x.x，对于你的模块使用者来说是一个破坏性的更新。

# Coding against an unpublished module
在开发模块时，还不能像普通的模块那样使用Go命令来添加依赖。当你的代码需要使用未发布的模块中的函数时，你需要引用本地文件系统中的模块拷贝。你可以引用本地的模块，这是在模块的go.mod中通过replace指令设置的，更多的信息，请参考[Requiring module code in a local directory](https://go.dev/doc/modules/managing-dependencies#local_directory)

# Publishing pre-release versions
你可以发布预发布版本，这样其他开发者就可以尝试模块的功能并提供反馈。预发布版本不保证稳定性。预发布版本号会被追加一个预发布标识符，更多的关于版本号的信息[Module version numbering](https://go.dev/doc/modules/version-numbers)，下面是2个例子:
- v0.2.1-beta.1
- v1.2.3-alpha

当使用预发布版本时，开发者需要明确的制定版本号，因为go命令优先加载稳定发布版，所以需要指定版本号。如下面的例子所示:
```shell
go get example.com/theirmodule@v1.2.3-alpha
```
通过在你的仓库给代码打tag的方式发布预发布版本，在tag中指定预发布标识符。更多的信息，参考[Publishing a module](https://go.dev/doc/modules/publishing)

# Publishing the first(unstable) version
发布预发布版本时，不稳定的发布版本的版本号类似v0.x.x，v0版本不保证稳定性与向后兼容，但是可以获得使用反馈，并且可以改善你的API，以便发布v1的稳定版。更多的信息参考[Module version numbering](https://go.dev/doc/modules/version-numbers)。发布模块参考[Publishing a module](https://go.dev/doc/modules/publishing)
# Publishing the first stable version
你的第一个发布版本的版本号类似v1.x.x，v1稳定版本具有如下特点:
- 当升级小版本时，不会破坏代码;
- 模块的public API不会较大变动
- 导出的类型不会被移除
- 任何对API的变更都是向后兼容的，并且会新增一个小版本号
- bug修复在一个小版本中或者在一个patch release版本中

# Publishing bug fixes
您可以发布一个版本，其中的更改仅限于错误修复。 这称为补丁版本。补丁版本仅包含较小的更改。特别是，它不包括对模块公共API的更改。使用代码的开发人员可以安全地升级到此版本，而无需更改他们的代码。注意: 你的补丁版本应该尽量不要升级任何模块自己的传递依赖超过一个补丁版本。否则，升级到你的模块补丁的人可能会意外地对他们使用的传递依赖项进行更具侵入性的更改。补丁版本会增加模块版本号的补丁部分。有关更多信息，请参阅模块版本编号。在以下示例中，v1.0.1是补丁版本。
旧版本：v1.0.0
新版本：v1.0.1
您通过在存储库中标记模块代码并增加标记中的补丁版本号来发布补丁版本。有关更多信息，请参阅发布模块。
# Publishing non-breaking API changes
您可以对模块的公共API进行非破坏性更改，并在次要版本中发布这些更改。此版本更改了API，但并未以破坏调用代码的方式进行更改。这可能包括更改模块自身的依赖项或添加新函数、方法、结构字段或类型。即使包含更改，这种版本也保证了调用模块函数的现有代码的向后兼容性和稳定性。次要版本会增加模块版本号的次要部分。

# Publishing breaking API changes
您可以通过发布主要版本号升级的新的版本发布来发布破坏向后兼容性的版本。主要版本发布不保证向后兼容性，通常是因为它包含对模块公共API的更改，这些更改会破坏使用模块先前版本的代码。鉴于主要版本升级可能对依赖模块的代码产生破坏性影响，您应该尽可能避免主要版本更新。有关主要版本更新的更多信息，请参阅[Developing a major version update](https://go.dev/doc/modules/major-version)。有关避免进行重大更改的策略，请参阅博客文章[Keeping your modules compatible](https://blog.golang.org/module-compatibility)。除了需要对模块的代码打tag外，主要版本升级还需要一些步骤:
- 在开发新的major版本代码前，创建一个分支来保存新版本的代码，[Managing module source](https://go.dev/doc/modules/managing-source)
- 在模块的go.mod文件中，升级模块的版本号
- TODO