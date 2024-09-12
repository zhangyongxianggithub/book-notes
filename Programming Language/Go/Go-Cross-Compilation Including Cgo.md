- MUSL
- GNU toolchain
- static linking
- dynamic linking [静态链接动态链接静态库共享库这些概念的详解](http://blog.champbay.com/2019/11/25/%e9%9d%99%e6%80%81%e9%93%be%e6%8e%a5%e5%8a%a8%e6%80%81%e9%93%be%e6%8e%a5%e9%9d%99%e6%80%81%e5%ba%93%e5%85%b1%e4%ba%ab%e5%ba%93%e8%bf%99%e4%ba%9b%e6%a6%82%e5%bf%b5%e7%9a%84%e8%af%a6%e8%a7%a3/)
- GLic编译器这些要搞定
- [Golang中的ldflags的作用](http://blog.champbay.com/2019/11/26/ldflags%E5%9C%A8golang%E7%BC%96%E8%AF%91%E4%B8%AD%E7%9A%842%E4%B8%AA%E4%BD%9C%E7%94%A8/)
# Introduction
从Go1.5版本开始，可以为不同的平台比如Windows、MacOS、Linux、Solaries与Android的交叉编译应用。交叉编译应用允许你在开发机上为不同的操作系统构建二进制可执行文件。本文解释了如何为Go应用(包含使用了CGO依赖的应用)交叉编译
# Supported Platforms
Go支持多个平台的交叉编译，下面列表是GO 1.22.2版本支持的GOOS与GOARCH的组合(使用`go tool dist list | column -c 35 | column -t`命令)
>aix/ppc64        linux/mips64le
android/386      linux/mipsle
android/amd64    linux/ppc64
android/arm      linux/ppc64le
android/arm64    linux/riscv64
darwin/amd64     linux/s390x
darwin/arm64     netbsd/386
dragonfly/amd64  netbsd/amd64
freebsd/386      netbsd/arm
freebsd/amd64    netbsd/arm64
freebsd/arm      openbsd/386
freebsd/arm64    openbsd/amd64
freebsd/riscv64  openbsd/arm
illumos/amd64    openbsd/arm64
ios/amd64        openbsd/ppc64
ios/arm64        plan9/386
js/wasm          plan9/amd64
linux/386        plan9/arm
linux/amd64      solaris/amd64
linux/arm        wasip1/wasm
linux/arm64      windows/386
linux/loong64    windows/amd64
linux/mips       windows/arm
linux/mips64     windows/arm64

# 交叉编译的例子
## Windows
```shell
# 32 bit
GOOS=windows GOARCH=386 go build
# 64 bit
GOOS=windows GOARCH=amd64 go build
# arm
GOOS=windows GOARCH=arm go build
# arm 64 bit
GOOS=windows GOARCH=arm64 go build
```
## macOS
```shell
# 64 bit
GOOS=darwin GOARCH=amd64 go build
# arm 64 bit
GOOS=darwin GOARCH=arm64 go build
```
## Linux
```shell
# 32 bit
GOOS=linux GOARCH=386 go build
# 64 bit
GOOS=linux GOARCH=amd64 go build
# arm
GOOS=linux GOARCH=arm go build
# arm 64 bit
GOOS=linux GOARCH=arm64 go build
```
# Cross-compile with Cgo
一些依赖，比如SQLite，需要CGO编译而不是纯Go编译。下面的例子覆盖了静态链接与动态链接2个场景
- **Static Linking**: 生成的二进制文件包含所有必要的依赖，不需要任何库在在目标系统上，用于创建self-contained 二进制文件，特别是在小型的镜像比如Alpine场景中使用
- **Dynamic Linking**: 静态链接意味着，二进制文件依赖一些共享库，这些共享库必须出现在目标系统中

## macOS to macOS
```shell
# 64 bit static
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 go build -ldflags="-extldflags=-static"
# 64 bit dynamic
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 go build 
# arm64 bit static
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 go build -ldflags="-extldflags=-static"
# arm64 bit dynamic
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 go build
```
## macOS to Linux
**MUSL**: 静态或者动态链接都可以，基于MUSL的系统有Alpine，安装musl gcc启用交叉编译。如果生成静态二进制文件，则文件可以在任何的linux发行版上运行，非静态的二进制文件只能运行在基于musl的操作系统中，比如Alpine。安装musl gcc
```shell
brew install filosottile/musl-cross/musl-cross
```
下面的命令会构建一个静态二进制文件，可以运行在任意的Linux发行版上，
```shell
# 64 bit static
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-linux-musl-gcc  CXX=x86_64-linux-musl-g++ go build -ldflags="-extldflags=-static"
# 64 bit dynamic
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-linux-musl-gcc  CXX=x86_64-linux-musl-g++ go build
# arm64 static
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=aarch64-linux-musl-gcc  CXX=aarch64-linux-musl-g++ go build -ldflags="-extldflags=-static"
# arm64 dynamic
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=aarch64-linux-musl-gcc  CXX=aarch64-linux-musl-g++ go build
```
**GNU**:动态链接更好优先
暗转GNU工具链
```shell
brew tap messense/macos-cross-toolchains
# x64 / x86
brew install  messense/macos-cross-toolchains/x86_64-unknown-linux-gnu
# arm64
brew install  messense/macos-cross-toolchains/aarch64-unknown-linux-gnu
```
使用GNU工具链build应用
```shell
# 64 bit static
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-linux-gnu-gcc  CXX=x86_64-linux-gnu-g++ go build -ldflags="-linkmode external -extldflags -static"
# 64 bit dynamic
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-linux-gnu-gcc  CXX=x86_64-linux-gnu-g++ go build
# arm64 static
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc  CXX=aarch64-linux-gnu-g++ go build -ldflags="-linkmode external -extldflags -static"
# arm64 dynamic
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc  CXX=aarch64-linux-gnu-g++ go build
```
## macOS to Windows
首先需要安装Windows编译器，比如`MinGW`
```shell
brew install mingw-w64
```
然后编译
```shell
# 32 bit
GOOS=windows GOARCH=386 CGO_ENABLED=1 CC="i686-w64-mingw32-gcc" go build
# 64 bit
GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC="x86_64-w64-mingw32-gcc" go build
```
1. [Go Cgo Environment Setup](https://github.com/go101/go101/wiki/CGO-Environment-Setup)
2. [Homebrew MUSL macOS Cross Toolchain](https://github.com/FiloSottile/homebrew-musl-cross)
3. [Homebrew GNU macOS Cross Toolchain](https://github.com/messense/homebrew-macos-cross-toolchains)
4. [Static and Dynamic Linking in Operating Systems](https://www.geeksforgeeks.org/static-and-dynamic-linking-in-operating-systems/)
5. [Stack Overflow: How to Statically Link a C Library in Go Using Cgo](https://stackoverflow.com/a/29522413)

# confluent-kafka-go的编译问题
- Go的版本>=1.21
- 运行`gofmt`与`go vet`
- 每行的字符数<=80

因为`github.com/confluentinc/confluent-kafka-go/v2/kafka`绑定了`librdkafka`的C库，必须启用CGO编译。然后保证C编译器存在。
通过Go的build标签(-tags)来支持不同的构建类型，这些标签需要在应用的build/get/install命令中指定
- 缺省情况下，将使用捆绑的平台相关的静态构建的librdkafka版本，在MacOS与基于glibc的linux发行版上是开箱即用的，比如Ubuntu与CentOS
- `-tags musl`, 当为基于musl的linux发行版构建时需要指定，比如Alpine，将会使用`the bundled static musl build of librdkafka.`
- `-tags dynamic`动态链接librdkafka.一个共享的librdkafka库必须先安装，可以通过(apt-get, yum, build from source等方式安装

