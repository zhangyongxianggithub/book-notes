启动一个图形化的控制台来监控或者管理Java应用
# 语法
```bash
jconsole [-interval=n] [-notile] [-plugin path] [-version] [connection ... ] [-Jinput_arguments]
```
```bash
jconsole -help
```
# Options
- -interval: 设置更新间隔，默认是4秒
- -notile: Doesn't tile the windows for two or more connections.
- -pluginpath *path*:设置jconsole的plugin所在的目录，插件目录必须包含一个`META-INF/services/com.sun.tools.jconsole.JConsolePlugin`配置文件，每行包含一个插件，插件就是一个实现`com.sun.tools.jconsole.JConsolePlugin`类的全限定名
- -version: 打印版本
- connection = pid | host:port | jmxURL:
  - pid: JVM进程ID，运行JVM进程的用户必须与运行jconsole的用户是一个
  - host:port: 
  - jmxUrl
- Jinput_arguments: jconsole本身的JVM参数
- -help/--help

# 描述
