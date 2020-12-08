# 基础信息
为了了解大部分的JDK工具，你需要先知道一些比较重要的基础信息。
## JDK与JRE文件夹结构
本节讲解JDK的目录与文件结构，JRE的结构与JDK目录中的jre目录一致，目录结构包含下面的主题：
- 样例（Demos and Samples）
- 开发文件与目录（Development Files and Directories）
- 额外的目录文件结构（Additional Files and Directories）
### 样例
样例代码是展示如何进行Java编程的，可以在[
http://www.oracle.com/technetwork/java/javase/downloads/index.html](
http://www.oracle.com/technetwork/java/javase/downloads/index.html)中下载到。
### 开发文件与目录
这部分讲解了大部分涉及到开发的目录与文件，还有一些包含了Java的源码与C的头文件。
jdk1.8.0
    --bin
        --java*
        --javac*
        --javap*
        --javah*
        --javadoc*
    --lib
        --tools.jar
        --dt.jar
    --jre
        --bin
            --java*
        --lib
            --applet
            --ext
                --jfxrt.jar
                --localdata.jar
            --fonts
            --security
            --sparc
                --server
                --client
            --rt.jar
            --charsets.jar
假设JDK软件安装在/jdk1.8.0目录下，下面是一些比较重要的目录
- /jdk1.8.0 JDK软件安装的跟目录，包含版权、证书与README文件、src.zip等；
- /jdk1.8.0/bin JDK包含的所有的可执行开发工具，PATH里面需要有这个目录；
- /jdk1.8.0/lib 开发工具使用到的文件，包含tools.jar，里面是一些JDK工具使用到的非核心类，也包括dt.jar，里面是一些设计的归档文件，用于通知交互开发环境，如何展示Java组件你的信息。
- /jdk1.8.0/jre JDK工具使用的JRE环境的跟目录，运行时环境是java平台的实现，也是java.home系统属性的值；
- /jdk1.8.0/jre/bin 与/jdk1.8.0/bin目录的内容基本一样，java启动器工具也就是应用启动器，这个目录不需要出现在PATH中；
- /jdk1.8.0/jre/lib JRE环境使用到的代码库、属性设置、与资源文件，比如：rt.jar包含启动类与Java平台核心API组成的类，charsets.jar包含字符转换类；
- /jdk1.8.0/jre/lib/ext java平台扩展类的安装路径，这个目录包括jfxrt.jar 包含JacaFX运行时库，与localedata.jar 包含java.text与java.util包的区域语言数据；
- /jdk1.8.0/jre/lib/security 包含用于安全管理的文件，包括安全策略java.policy与安全属性java.security文件；
- /jdk1.8.0/jre/lib//sparc 由JDK使用的.so文件；
- /jdk1.8.0/jre/lib/sparc/client 包含Java Hotspot虚拟机使用的.so文件；
- /jdk1.8.0/jre/lib/sparc/server 包含Java HotSpot虚拟机服务其使用的.so文件；
- /jdk1.8.0/jre/lib/applet Java归档文件，包含applet应用使用的支持类；
- /jdk1.8.0/jre/lib/fonts 包含平台使用的字体
### 额外的文件与目录
- /jdk1.8.0/src.zip 包含源代码的归档文件
- /jdk1.8.0/db 包含Java DB
- /jdk1.8.0/include C-语言头文件；
- /jdk1.8.0/man 包含JDK工具的用户手册

## 设置类路径
类路径是一种特殊的路径，JRE会在这些路径中搜索类与其他的资源文件；
本小节含有以下的主题：
- 概要
- 描述
- 


















