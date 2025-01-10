[wiki](https://github.com/spring-projects/spring-boot/wiki)中有升级教程。找到你要升级的版本链接，参考升级，如果垮了版本要所有版本都要处理。当更新到一个新的版本时，一些属性可能移除或者重新命名了。Spring Boot提供了一种方式来分析你的应用的environment并在启动时打印分析的结果。并且会临时的在运行时为你迁移属性。添加下面的依赖开启这个机制
```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-properties-migrator</artifactId>
	<scope>runtime</scope>
</dependency>
```
比较晚加入environment的属性比如使用`@PropertySource`的方式加载的，不会进行处理。一旦完成迁移记住移除这个依赖。更新CLI，最好使用合适的包管理器命令比如`brew upgrade`。