database是主要的容器，它包含表与日志文件，还有所有的schema。你可以备份一个数据库，与当前的数据来说，它们可以是完全不相关的。
schema类似数据库里面的文件夹，用来对对象做逻辑上的分组，使用schema可以非常方便的设置权限。
中文一般翻译为架构或者模式，翻译为文件夹更易懂，台湾翻译为纲要；是对象的集合。模式的好处：
- 允许多个用户使用一个数据库而不会干扰其他用户；
- 把数据库对象组织成逻辑组，让它们更便于管理；
- 对象的名字可以重复而不冲突。
# oracle的schema
Oracle为每个在数据库用户关联一个独立的schema，schema中包含scehma obejcts。也就是表等对象。
# sql server
默认架构DBO，
在 SQL Server 2000 中，数据库用户和架构是隐式同一。每个数据库用户都是与该用户同名的架构的所有者。对象的所有者在功能上与包含它的架构所有者相同。因而，SQL Server 2000 中的完全限定名称的“架构”也是数据库中的用户。

SQL Server 2005 中，架构独立于创建它们的数据库用户而存在。多个用户可以共享一个默认架构进行统一的名称解析。 删除数据库用户不需要重命名该用户架构所包含的对象。完全限定的对象名称现在包含四部分：server.database.schema.object。如果未定义DEFAULT_SCHEMA 选项设置和更改默认架构，则数据库用户将把 DBO 作为其默认架构。
# MySQL实现
在MySQL中 Scheme=Database
# PostgreSQL
一个数据库包含一个或多个命名的模式， 模式包含其它命名的对象，如表、数据类型、函数、操作符等。在不同的模式里使用同名的对象不会导致冲突。例如，schema1 和 schemaA 都可以包含叫做 mytable 的表。一个用户可以访问所连接的数据库中的任意模式中的对象，只要有这个权限。
# Apache Derby
，默认是对应于该用户名的一个schema