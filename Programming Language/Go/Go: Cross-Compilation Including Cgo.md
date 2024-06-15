- MUSL
- GNU toolchain
- static linking
- dynamic linking
- GLic编译器这些要搞定
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