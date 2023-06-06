[TOC]
开发模块时，有一个标准的开发流程，可以开发一个稳定的可靠的，体验一致的模块。这个开发流程的步骤如下
# Common workflow steps
下面的步骤就是发布一个新的模块的步骤:
- Begin a module, 组织源代码，让开发者容易使用，让你容易维护。如果你对开发模块还比较陌生，请参考[Tutorial: Create a Go module](https://go.dev/doc/tutorial/create-module);
- write local client code，调用未发布的模块中的函数，在你发布一个模块前，对于是用传统的go get方式的依赖管理的项目是不能用的，这个阶段测试你的模块的最好的方式就是在本地的文件夹中测试，[Coding against an unpublished module](https://go.dev/doc/modules/release-workflow#unpublished)
- 当其他的开发者可以使用模块代码时，发布v0预发布版本作为alphas与betas版本，参考[Publishing pre-release versions](https://go.dev/doc/modules/release-workflow#pre-release)获得详细的信息;
- 发布一个v0版本，是不保证稳定的，但是用户可以使用，详细信息参考[Publishing the first version](https://go.dev/doc/modules/release-workflow#first-unstable)
- 在v0版本发布后，你可能会继续发布新的版本，这些新的版本可能包含bug fixes。