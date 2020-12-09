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
- JDK命令使用的类路径选项
- CLASSPATH环境变量
- 类路径通配符
- 类路径与包的名字的关系
### 基础概念（概要）
类与资源的搜索路径可以通过-classpath选项或者CLASSPATH环境变量的方式指定，-classpath命令行选项的方式的优先级更高，因为它可以对一个应用独立设置，不影响其他应用的类搜索路径。
sdkTool -classpath classpath1:classpath2…
setenv CLASSPATH classpath1:classpath2…
- skdTool 是命令行工具，比如java、javac、javadoc或者apt，工具列表[
http://docs.oracle.com/javase/8/docs/technotes/tools/index.html](http://docs.oracle.com/javase/8/docs/technotes/tools/index.html)
- classpath1:classpath2 jar、zip、或者class文件所在的路径，每个类路径都应该以一个文件名或者目录结尾，这依赖你的设置:
	- 对于包含class文件的JAR或者zip文件来说，类路径以文件名结尾；
	- 对于没有在包下面的class文件来说，类路径就是class文件所在的目录；
	- 对于在包下面的class文件来说，类路径是根包所在的目录；

多个类路径在windows平台上通过分号分割，在其他平台上通过冒号分隔，缺省的类路径是当前目录，如果设置了CLASSPATH环境变量或者-classpath命令行选项其中之一，都会覆盖默认的设置，所以，如果你想要在类路径中包含当前的目录，必须在类路径加上点号；不符合规则的类路径会被忽略（不是目录、不是归档文件、不是*通配符）
### 描述
JDK命令行工具与应用程序通过类路径查找Java平台或者扩展机制之外的第三方的类或者用户自定义的类，扩展机制在这里：[http://docs.oracle.com/javase/8/docs/technotes/guides/extensions/index.html](
http://docs.oracle.com/javase/8/docs/technotes/guides/extensions/index.html)
类路径中必须能够查找到你通过javac编译的class文件，缺省是当前的目录，可以方便的发现这些class。
JDK、JVM或者JDK的命令行工具通过搜索Java平台启动类路径、扩展类路径与classpath路径的顺序来查找类，关于详细的搜索策略，可以看下，关于类是如何找的的文档[http://docs.oracle.com/javase/8/docs/technotes/tools/findingclasses.html](http://docs.oracle.com/javase/8/docs/technotes/tools/findingclasses.html)大多数应用的基础类库都是使用扩展机制加载的，当你想要加载的一个类不在当前的目录/子目录也不在Java平台的扩展类加载路径时，你才需要设置类路径。
如果你更新了JDK的版本，你的启动设置中可能包含不在需要的CLASSPATH设置，你应该移除任何全局应用设置，比如classes.zip，一些使用JVM的第三方应用可能会更改你的CLASSPATH环境变量，如果不清除他们，他们就会遗留下来。
可以通过命令行选项-classpath或者-cp指定类路径，并且比如环境变量的方式优先级更高。
Class文件可以存到目录下或者归档文件中，java平台基础类存储在rt.jar文件中，关于归档文件的详细信息以及类搜索路径是如何工作的，可以看看类搜索路径与包名字的小节。
注意：
一些早期的JDK版本的缺省类搜索路径包含\<jdk-dir>/classes目录，这个目录中的类只是JDK软件使用的，而不是应用使用的；应用类应该放到JDK目录之外的其他目录中，这样，更新JDK时，不会把应用类class删掉而重新安装，为了兼容以前的JDK版本。
### JDK命令使用的类路径选项
大多数JDK命令都支持-classpath选项，用来覆盖默认的类路径与环境变量设置的类路径，比如java、jdb、javac、javah、jdeps等；
### CLASSPATH环境变量
设置环境变量：
> CLASSPATH = path1:path2:...
export CLASSPATH

清除这个设置：
>unset CLASSPATH
检查系统启动时，是否有设置CLASSPATH环境变量
### 路径通配符
类路径可以包含通配符*，通常与包含多个相同模式的jar文件的形式等价，比如/*就是指的包含目录下所有的jar文件，


















